local _,ns = ...

local _, cls = UnitClass("player")

-- Mage: Arcane Surge countdown alert (Settings - Class toggle mageCountdown)
if cls == "MAGE" then
	ns.event("PLAYER_LOGIN", function()
		if not (AddUIDB and AddUIDB.mageCountdown) then return end
		EventRegistry:RegisterFrameEventAndCallback("UNIT_SPELLCAST_SUCCEEDED",function(_,unit,_,spellID)
			if unit ~= "player" then return end
			if spellID ~= 365350 then return end
			if not C_SpellBook.IsSpellKnown(449619) then return end
			local s = C_SpellBook.IsSpellKnown(449412) and 17.4 or 15
			C_Timer.After(s-4.1, function()
				if UnitIsDead("player") then return end
				PlaySoundFile("Interface\\AddOns\\AddUI\\UI\\media\\568154.mp3", "Master")
			end)
		end)
	end)
-- Shaman: ability countdown alert (Settings - Class toggle shamanCountdown)
elseif cls == "SHAMAN" then
	ns.event("PLAYER_LOGIN", function()
		if not (AddUIDB and AddUIDB.shamanCountdown) then return end
		EventRegistry:RegisterFrameEventAndCallback("UNIT_SPELLCAST_SUCCEEDED",function(_,unit,_,spellID)
			if unit ~= "player" then return end
			if spellID ~= 114050 then return end
			local s = 15
			C_Timer.After(s-4.1, function()
				if UnitIsDead("player") then return end
				PlaySoundFile("Interface\\AddOns\\AddUI\\UI\\media\\568154.mp3", "Master")
			end)
		end)
	end)
end

-- Alter Time
local ALTER_TIME       = 342245   -- cast Alter Time
local ALTER_TIME_ENDS  = 342247   -- Alter Time ends

-- The aura name is read from the client at runtime instead of being hardcoded, so the
-- cancel macro matches on every locale (enUS "Alter Time", zhCN "操控时间", deDE "Zeitverschiebung", ...)
local function GetAlterTimeName()
	if C_Spell and C_Spell.GetSpellName then
		local name = C_Spell.GetSpellName(ALTER_TIME)
		if name then return name end
	end
	if GetSpellInfo then
		local name = GetSpellInfo(ALTER_TIME)
		if name then return name end
	end
	return "Alter Time"
end

local button

-- The spell-alert animation is delegated to Blizzard's ActionButtonSpellAlertManager:
-- on the first ShowAlert it creates the template frame automatically and plays
local function HideAura()
	if not button then return end
	button.text:Hide()
	button.text:SetText("")
	button.T:Hide()
	button.T:SetTexture(nil)
	button.Cooldown:SetCooldown(0, 0)
	if ActionButtonSpellAlertManager then
		ActionButtonSpellAlertManager:HideAlert(button)
	end
end

local function ShowAura()
	if not button then return end
	button.text:Show()
	button.text:SetText(string.format("%d%%", UnitHealthPercent("player", true, CurveConstants.ScaleTo100)))
	button.T:Show()
	button.T:SetTexture(985088)
	button.Cooldown:SetCooldown(GetTime(), 10)
	if ActionButtonSpellAlertManager then
		ActionButtonSpellAlertManager:ShowAlert(button)
	end
	PlaySoundFile("Interface\\AddOns\\AddUI\\UI\\media\\342247.mp3", "Master")
end

local function CreateFrames()
	if button then return end
	-- secure attributes can only be set out of combat; retried from PLAYER_REGEN_ENABLED below
	if InCombatLockdown() then return end

	-- main frame
	local f = CreateFrame("Frame", "ADDUIcancelAuraButton", UIParent)
	f:SetSize(60, 60)
	f:SetPoint("TOP", UIParent, "TOP", 300, -10)
	ns.AddEdit(f, "Cancel\nAlter Time")
	button = f

	-- background
	f.Background = f:CreateTexture(nil, "BACKGROUND")
	f.Background:SetTexture(130937)
	f.Background:SetAllPoints(f)
	f.Background:SetColorTexture(0, 0, 0, 0)

	-- hover tooltip text
	f.tiptext = f:CreateFontString(nil, "BACKGROUND")
	f.tiptext:SetFont(SystemFont_Outline_Small:GetFont(), 20, "OUTLINE")
	f.tiptext:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.tiptext:SetText("Cancel\nAlter Time")
	f.tiptext:SetTextColor(0.5, 0.5, 0.5)
	f.tiptext:Hide()

	-- secure cancel button
	local btn = CreateFrame("CheckButton", "ADcancelAuraButton", f, "SecureActionButtonTemplate")
	btn:SetAttribute("type", "macro")
	btn:SetAttribute("macrotext", "/cancelaura " .. GetAlterTimeName())
	btn:SetAllPoints(f)
	btn:RegisterForClicks("AnyDown", "AnyUp")
	btn:SetScript("OnEnter", function()
		f.Background:SetColorTexture(0, 0, 0, .5)
		f.tiptext:Show()
	end)
	btn:SetScript("OnLeave", function()
		f.Background:SetColorTexture(0, 0, 0, 0)
		f.tiptext:Hide()
	end)
	btn:HookScript("OnClick", HideAura)  -- keep the template's secure OnClick to run the cancel macro, then hide the button

	-- the child button covers the parent frame and intercepts dragging -> in edit mode let the child respond to drags too
	local function ToggleChildDrag()
		if InCombatLockdown() then return end
		local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
		if inEditMode then
			btn:RegisterForDrag("LeftButton")
			btn:SetScript("OnDragStart", function()
				f:StartMoving()
			end)
			btn:SetScript("OnDragStop", function()
				f:StopMovingOrSizing()
				if not AddUIDB then AddUIDB = {} end
				local left, bottom = f:GetLeft(), f:GetBottom()
				AddUIDB["ADDUIcancelAuraButton_Edit"] = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left, bottom}
			end)
		else
			btn:RegisterForDrag()
			btn:SetScript("OnDragStart", nil)
			btn:SetScript("OnDragStop", nil)
		end
	end
	if EditModeManagerFrame then
		EditModeManagerFrame:HookScript("OnShow", ToggleChildDrag)
		EditModeManagerFrame:HookScript("OnHide", ToggleChildDrag)
	end
	ToggleChildDrag()

	-- Alter Time icon
	f.T = f:CreateTexture()
	f.T:SetAllPoints(f)
	f.T:SetTexture(985088)
	f.T:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.T:Hide()

	-- health percentage
	f.text = f:CreateFontString(nil)
	f.text:SetFont(SystemFont_Outline_Small:GetFont(), 30, "OUTLINE")
	f.text:SetPoint("TOP", f, "BOTTOM", 0, 0)
	f.text:Hide()

	-- cooldown (10-second sweep)
	f.Cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
	f.Cooldown:SetAllPoints(f.T)
	f.Cooldown:SetHideCountdownNumbers(false)
	f.Cooldown:SetUseCircularEdge(true)
	f.Cooldown:SetReverse(true)
	f.Cooldown:SetScript("OnCooldownDone", function()
		HideAura()
	end)
	-- use GetCountdownFontString() to get the countdown FontString, not GetRegions()[1]
	-- (the first entry may be the cooldown's own texture and would be skipped silently)
	local cdText = f.Cooldown:GetCountdownFontString()
	if cdText then
		cdText:SetFont(STANDARD_TEXT_FONT, 30, "OUTLINE")
	end
end

local function OnCancelAuraEvent(event, unit, _, spellId)
	if not (AddUIDB and AddUIDB.cancelAuraBtn) then return end
	if event == "PLAYER_ENTERING_WORLD" then
		CreateFrames()
		return
	end
	if unit ~= "player" then return end

	if spellId == ALTER_TIME then          -- cast Alter Time -> show
		ShowAura()
	elseif spellId == ALTER_TIME_ENDS then -- Alter Time ends -> hide
		HideAura()
	end
end

if cls == "MAGE" then
	ns.event('PLAYER_ENTERING_WORLD', OnCancelAuraEvent)
	ns.event('UNIT_SPELLCAST_SUCCEEDED', OnCancelAuraEvent)
	-- if PLAYER_ENTERING_WORLD fired while in combat, finish the setup once combat ends
	ns.event('PLAYER_REGEN_ENABLED', CreateFrames)
end
