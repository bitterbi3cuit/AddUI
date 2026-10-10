local _, ns = ...
-- Self-buff monitoring spell list defaults {[spellID]=boolean} (true=enabled, false=disabled; merged into AddUIDB on ADDON_LOADED)
ns.Defaults.SelfBuffAuraList = {
    --[1263768] = true,   --Lightbulwark Core
    --[1236616] = true,   --Holy Potential
    --[1236994] = true,   --Holy Reckless Potion
}
ns.tips("Self-buff aura container: monitors BUFFs in the list, drag to reposition in Edit Mode, right-click in Edit Mode to open the list")
-- ══════════════════════════════════════════════════════════════
-- Default table (user can add/remove): [spellID] = "spellName"
-- Merge rule: spells not in the user table are added automatically (enabled by default);
--             spells already in the user table but disabled are left unchanged.
-- ══════════════════════════════════════════════════════════════
ns.DefaultSelfBuffAuraList = {
	-- 12345,
}
local function MergeDefaults()
	AddUIDB.SelfBuffAuraList = AddUIDB.SelfBuffAuraList or {}
	for _, id in ipairs(ns.DefaultSelfBuffAuraList) do
		if AddUIDB.SelfBuffAuraList[id] == nil then
			AddUIDB.SelfBuffAuraList[id] = true
		end
	end
end
-- ════════════════════════ Spell Name Resolution ════════════════════════
local function GetSpellDisplayName(spellId)
	if not spellId then return nil end
	local spellName = C_Spell.GetSpellName(spellId)
	if spellName and spellName ~= "" then return spellName end
	local spellInfo = C_Spell.GetSpellInfo(spellId)
	if spellInfo and spellInfo.name and spellInfo.name ~= "" then
		return spellInfo.name
	end
	return nil
end
local function NormalizeSpellId(text)
	if not text then return nil end
	local spellId = tonumber(text)
	if spellId then return spellId end
	local resolvedId = C_Spell.GetSpellIDForSpellIdentifier(text)
	if resolvedId and resolvedId > 0 then return resolvedId end
	return nil
end
-- ════════════════════════ Aura Container ════════════════════════
local container
-- Build filter set from "enabled" spells in the list
local function GetEnabledSpellIDs()
	local include = {}
	for id, enabled in pairs(AddUIDB.SelfBuffAuraList or {}) do
		if enabled ~= false then
			include[id] = true
		end
	end
	return include
end
-- Called when the list changes: updates the container to filter by the latest enabled set
function ns.UpdateSelfBuffAuraFilters()
	if container then
		container:SetAuraGroupCandidateFilters("selfBuff", { includeSpellIDs = GetEnabledSpellIDs() })
	end
end
ns.event("PLAYER_LOGIN", function()
	MergeDefaults()
	-- Outer holder frame (sized for aura container buttons), handles Edit Mode drag
	local holder = CreateFrame("Frame", "ADUISelfBuffAuraFrame", UIParent, "BackdropTemplate")
	holder:SetSize(285, 45)
	holder:SetPoint("CENTER", 0, -100)
	holder:Show()
	-- Disable mouse and propagate clicks outside Edit Mode: holder has no background and is always
	-- visible, preventing invisible blocking of underlying UI / right-click camera
	holder:EnableMouse(false)
	pcall(holder.SetPropagateMouseClicks, holder, true)
	container = CreateFrame("AuraContainer", "ADUISelfBuffAura", holder, "CustomAuraContainerTemplate")
	container:SetPoint("CENTER", holder, "CENTER", 0, 0)
	container:SetUnit("player")
	-- Fully disable mouse and propagate clicks outside Edit Mode: empty container no longer
	-- intercepts clicks, mouse passes through (does not affect right-click camera or underlying drag).
	-- Edit Mode dragging uses the holder frame; the container itself never needs mouse input, so it stays disabled.
	container:EnableMouse(false) -- full mouse pass-through, does not block clicks
	container:AddAuraGroup("selfBuff", "HELPFUL|PLAYER", {
		maxFrameCount = 10,
		sortMethod = AuraContainerSortMethod.Expiration, -- sort by expiration time
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(auraButton)
			local size = 40
			auraButton:SetSize(size, size)
			auraButton:EnableMouse(false) -- full mouse pass-through, does not block clicks
			local icon = auraButton:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints(auraButton)
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			auraButton:SetIcon(icon)
			local cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
			cooldown:SetAllPoints(auraButton)
			cooldown:SetDrawBling(false)
			cooldown:SetDrawEdge(false)
			cooldown:SetReverse(true) -- reverse cooldown animation direction
			auraButton:SetDurationCooldown(cooldown)
			-- Cooldown countdown font size is proportional to aura size (same as RaidFrameDefense).
			-- Use GetCountdownFontString() to get the countdown FontString; do not use GetRegions()[1]
			-- (the first item may be the cooldown's built-in texture, which is silently skipped).
			local cdText = cooldown:GetCountdownFontString()
			if cdText then
				cdText:SetFont(STANDARD_TEXT_FONT, size/1.8, "OUTLINE")
			end
			-- Stack count: separate overlay frame (above cooldown level, not hidden with cooldown)
			local overlay = CreateFrame("Frame", nil, auraButton)
			overlay:SetAllPoints(auraButton)
			overlay:SetFrameLevel(auraButton:GetFrameLevel() + 2)
			local count = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			count:SetPoint("BOTTOMRIGHT", auraButton, 3, -3)
			count:SetVertexColor(1, 1, 1)
			count:SetFont(STANDARD_TEXT_FONT, size/2, "OUTLINE")
			auraButton:SetApplicationCount(count, {})
		end,
		candidateFilters = {
			includeSpellIDs = GetEnabledSpellIDs(),
		},
	})
	container:Show()
	-- Edit Mode drag position (drag the holder), center=true auto-centers horizontally on entering Edit Mode
	ns.AddEdit(holder, "Self-Buff right-click to add", true)
	-- Right-click in Edit Mode to open the spell list
	holder:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" and EditModeManagerFrame and EditModeManagerFrame:IsShown() then
			ns.OpenSelfBuffAuraList()
		end
	end)
	-- Edit Mode preview: Blizzard makes AuraContainer use a fake data source (sample BUFFs) for preview.
	-- But our includeSpellIDs filter removes these fake BUFFs → preview shows nothing.
	-- So temporarily remove the includeSpellIDs filter in Edit Mode so the fake data preview is visible; restore on exit.
	local function SetEditModeFilter(editing)
		if not container then return end
		if editing then
			container:SetAuraGroupCandidateFilters("selfBuff", {})
		else
			container:SetAuraGroupCandidateFilters("selfBuff", { includeSpellIDs = GetEnabledSpellIDs() })
		end
	end
	if EditModeManagerFrame then
		EditModeManagerFrame:HookScript("OnShow", function() SetEditModeFilter(true) end)
		EditModeManagerFrame:HookScript("OnHide", function() SetEditModeFilter(false) end)
	end
	-- CooldownViewer settings title bar button: opens the self-buff monitoring spell list
	if CooldownViewerSettings and CooldownViewerSettings.TitleContainer and not CooldownViewerSettings.SelfBuffButton then
		CooldownViewerSettings.SelfBuffButton = CreateFrame("Button", nil, CooldownViewerSettings.TitleContainer, "UIPanelButtonTemplate")
		CooldownViewerSettings.SelfBuffButton:SetSize(100, 22)
		CooldownViewerSettings.SelfBuffButton:SetPoint("LEFT", CooldownViewerSettings.TitleContainer, "LEFT", 10, 0)
		CooldownViewerSettings.SelfBuffButton:SetText("Self-Buff")
		CooldownViewerSettings.SelfBuffButton:SetScript("OnClick", function()
			ns.OpenSelfBuffAuraList()
		end)
		CooldownViewerSettings.SelfBuffButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText("Open self-buff monitoring spell list", 1, 1, 1, 1)
			GameTooltip:Show()
		end)
		CooldownViewerSettings.SelfBuffButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end)
-- ════════════════════════ Spell List Window ════════════════════════
local function BuildRows()
	local rows = {}
	for spellId in pairs(AddUIDB.SelfBuffAuraList or {}) do
		rows[#rows + 1] = spellId
	end
	table.sort(rows, function(a, b) return tonumber(a) < tonumber(b) end)
	return rows
end
local function MatchSearch(spellId, searchText)
	if not searchText or searchText == "" then return true end
	local spellName = GetSpellDisplayName(spellId) or ""
	local spellIdText = tostring(spellId)
	local needle = string.lower(searchText)
	return string.find(string.lower(spellIdText), needle, 1, true)
		or string.find(string.lower(spellName), needle, 1, true)
end
local function EnsureListWindow()
	if _G.ADUISelfBuffAuraList then return _G.ADUISelfBuffAuraList end
	local frame = CreateFrame("Frame", "ADUISelfBuffAuraList", UIParent, "BackdropTemplate")
	frame:SetSize(460, 420)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame:Hide()
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.08, 0.08, 0.08, 1)
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", 0, -8)
	title:SetText("Self-Buff List")
	-- Top-left: toggle to show spell IDs in tooltips (state driven by CVar; clicking is temporary, not persistent)
	local spellIDCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	spellIDCheck:SetPoint("TOPLEFT", 8, -4)
	spellIDCheck:SetSize(30, 30)
	local function RefreshSpellIDCheck()
		spellIDCheck:SetChecked(GetCVar("tooltipShowAuraSpellIDs") == "1")
	end
	RefreshSpellIDCheck()
	-- Sync checkbox when CVar changes externally (e.g. via another panel or macro)
	CVarCallbackRegistry:RegisterCallback("tooltipShowAuraSpellIDs", RefreshSpellIDCheck)
	spellIDCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText("|cffFFFFFFShow spell ID in tooltips|r", 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	spellIDCheck:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	spellIDCheck:SetScript("OnClick", function()
		-- Write CVar on click to control "show spell ID in tooltip"
		C_CVar.SetCVar("tooltipShowAuraSpellIDs", spellIDCheck:GetChecked() and "1" or "0")
	end)
	-- Label to the right of the checkbox
	local spellIDLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	spellIDLabel:SetPoint("LEFT", spellIDCheck, "RIGHT", 2, 0)
	spellIDLabel:SetText("Show Spell ID")
	-- Hint text: below the title, above the input box
	local tip = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tip:SetPoint("TOPLEFT", 10, -30)
	tip:SetText("Enter a spell ID to add, drag in Edit Mode to reposition")
	local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	searchBox:SetSize(240, 24)
	searchBox:SetPoint("TOPLEFT", 16, -44)
	searchBox:SetAutoFocus(false)
	searchBox:SetTextInsets(8, 8, 4, 4)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText("")
		self:GetParent():RefreshList()
	end)
	searchBox:SetScript("OnEnterPressed", function(self)
		local spellId = NormalizeSpellId(self:GetText())
		if spellId then
			local spellName = GetSpellDisplayName(spellId)
			if spellName then
				AddUIDB.SelfBuffAuraList[spellId] = true
				self:SetText("")
				self:GetParent():RefreshList()
				ns.UpdateSelfBuffAuraFilters()
				return
			end
		end
		self:ClearFocus()
		self:GetParent():RefreshList()
	end)
	searchBox:SetScript("OnTextChanged", function(self)
		self:GetParent():RefreshList()
	end)
	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(80, 24)
	addButton:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
	addButton:SetText(ADD)
	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", 2, 2)
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 16, -78)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)
	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)
	local headerID = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerID:SetPoint("TOPLEFT", 20, 0)
	headerID:SetText("ID")
	headerID:SetWidth(60)
	headerID:SetJustifyH("LEFT")
	local headerName = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerName:SetPoint("TOPLEFT", 95, 0)
	headerName:SetText(SPELLS .. NAME)
	headerName:SetWidth(130)
	headerName:SetJustifyH("LEFT")
	local headerEnable = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerEnable:SetPoint("TOPLEFT", 250, 0)
	headerEnable:SetText(ENABLE)
	headerEnable:SetWidth(55)
	headerEnable:SetJustifyH("LEFT")
	local headerAction = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAction:SetPoint("TOPLEFT", 340, 0)
	headerAction:SetText(DELETE)
	headerAction:SetWidth(60)
	headerAction:SetJustifyH("LEFT")
	frame.rows = {}
	frame.searchBox = searchBox
	frame.scrollFrame = scrollFrame
	frame.content = content
	local function ClearRows()
		for _, row in ipairs(frame.rows) do
			row:Hide()
			row:SetParent(nil)
		end
		wipe(frame.rows)
	end
	function frame:RefreshList()
		ClearRows()
		local searchText = self.searchBox:GetText()
		local lastRow
		for _, spellId in ipairs(BuildRows()) do
			if MatchSearch(spellId, searchText) then
				local row = CreateFrame("Frame", nil, self.content)
				row:SetSize(400, 24)
				if lastRow then
					row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -4)
				else
					row:SetPoint("TOPLEFT", 0, -24)
				end
				local bg = row:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints(row)
				bg:SetColorTexture(0.5, 0.5, 0.5, 1)
				local function SetRowHighlighted(highlighted)
					if highlighted then
						bg:SetColorTexture(0.75, 0.75, 0.75, 1)
					else
						bg:SetColorTexture(0.5, 0.5, 0.5, 1)
					end
				end
				local idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				idText:SetPoint("LEFT", 20, 0)
				idText:SetWidth(60)
				idText:SetJustifyH("LEFT")
				idText:SetText(tostring(spellId))
				local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				nameText:SetPoint("LEFT", 95, 0)
				nameText:SetWidth(140)
				nameText:SetJustifyH("LEFT")
				nameText:SetText(GetSpellDisplayName(spellId) or UNKNOWN)
				local enabled = AddUIDB.SelfBuffAuraList[spellId]
				local enableCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
				enableCheck:SetPoint("LEFT", 252, 0)
				enableCheck:SetSize(24, 24)
				enableCheck:SetChecked(enabled ~= false)
				enableCheck:SetScript("OnClick", function(self)
					AddUIDB.SelfBuffAuraList[spellId] = self:GetChecked()
					ns.UpdateSelfBuffAuraFilters()
				end)
				enableCheck:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				enableCheck:SetScript("OnLeave", function() SetRowHighlighted(false) end)
				local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				deleteButton:SetSize(55, 20)
				deleteButton:SetPoint("LEFT", 335, 0)
				deleteButton:SetText(DELETE)
				deleteButton:SetScript("OnClick", function()
					AddUIDB.SelfBuffAuraList[spellId] = nil
					frame:RefreshList()
					ns.UpdateSelfBuffAuraFilters()
				end)
				deleteButton:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				deleteButton:SetScript("OnLeave", function() SetRowHighlighted(false) end)
				frame.rows[#frame.rows + 1] = row
				lastRow = row
			end
		end
		if lastRow then
			self.content:SetHeight(24 + (#frame.rows * 28))
		else
			self.content:SetHeight(48)
		end
	end
	addButton:SetScript("OnClick", function()
		local input = searchBox:GetText()
		local spellId = NormalizeSpellId(input)
		if not spellId then
			print("Self-Buff List: " .. UNKNOWN .. SPELLS)
			return
		end
		local spellName = GetSpellDisplayName(spellId)
		if not spellName then
			print("Self-Buff List: " .. UNKNOWN .. SPELLS)
			return
		end
		AddUIDB.SelfBuffAuraList[spellId] = true
		searchBox:SetText("")
		frame:RefreshList()
		ns.UpdateSelfBuffAuraFilters()
	end)
	frame:SetScript("OnShow", function(self)
		self:RefreshList()
		RefreshSpellIDCheck() -- restore checkbox from CVar on reopen (temporary toggle is not persistent)
	end)
	frame:RefreshList()
	_G.ADUISelfBuffAuraList = frame
	return frame
end
function ns.OpenSelfBuffAuraList()
	local frame = EnsureListWindow()
	frame:Show()
	frame:Raise()
end
