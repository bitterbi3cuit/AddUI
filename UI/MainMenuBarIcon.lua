local addonName, ns = ...

-- ===========================================================================
-- Fixes: ADDON_ACTION_BLOCKED on MultiBar*Button*:SetScale()

local ACTIONBARS = {
	"MultiBarBottomLeft",
	"MultiBarBottomRight",
	"Action",
	"MultiBarLeft",
	"MultiBarRight",
	"MultiBar5",
	"MultiBar6",
	"MultiBar7",
}

local BUTTONS_PER_BAR  = 12
local BUTTON_SCALE     = 1.095
local MEDIA_PATH       = "Interface\\AddOns\\AddUI\\UI\\media\\"
local NORMAL_TEX       = MEDIA_PATH .. "normal"
local HIGHLIGHT_TEX    = MEDIA_PATH .. "highlight"
local HOTKEY_FONT_SIZE = 12

-- Third-party bar addons: if one is loaded, never touch the bars.
local EXCLUDED_ADDONS = { "Dominos", "Bartender4", "ElvUI", "BigFoot", "NDui" }

-- The old global string aliases no longer exist on modern clients.
local gsub = string.gsub

local function IsExcluded()
	for i = 1, #EXCLUDED_ADDONS do
		if C_AddOns.IsAddOnLoaded(EXCLUDED_ADDONS[i]) then
			return true
		end
	end
	return false
end

local function InCombat()
	return InCombatLockdown and InCombatLockdown() or false
end

-- Set when styling had to be postponed because of combat; consumed on regen.
local stylePendingCombat = false
-- Set while a styling pass is already queued for the next frame.
local styleQueued = false

-- ---------------------------------------------------------------------------
-- Styling (only ever reached from the deferred pass below)
-- ---------------------------------------------------------------------------

-- Hides the stock ExtraActionButton / ZoneAbilityFrame decoration.
local function StyleExtraButtons()
	if ExtraActionButton1 and ExtraActionButton1.style then
		ExtraActionButton1.style:Hide()
	end
	if ZoneAbilityFrame and ZoneAbilityFrame.Style then
		ZoneAbilityFrame.Style:Hide()
	end
end

-- Styles a single action button. Every setter is guarded, because the button
-- and its child regions are not guaranteed to exist on every client.
local function StyleActionButton(button)
	if not button then return end

	-- Protected function: legal here only because this runs outside combat and
	-- outside any secure call chain.
	if button.SetScale then
		pcall(button.SetScale, button, BUTTON_SCALE)
	end

	if button.SetNormalTexture then
		pcall(button.SetNormalTexture, button, NORMAL_TEX)
	end
	if button.SetHighlightTexture then
		pcall(button.SetHighlightTexture, button, HIGHLIGHT_TEX)
	end
	if button.SetCheckedTexture then
		pcall(button.SetCheckedTexture, button, HIGHLIGHT_TEX)
	end

	local highlight = button.HighlightTexture
	if highlight then
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT", button, 1.5, -1.5)
		highlight:SetPoint("BOTTOMRIGHT", button, -1.5, 1.5)
	end

	local checked = button.CheckedTexture
	if checked then
		checked:ClearAllPoints()
		checked:SetPoint("TOPLEFT", button, 1.5, -1.5)
		checked:SetPoint("BOTTOMRIGHT", button, -1.5, 1.5)
	end

	local normal = button.NormalTexture
	if normal then
		normal:ClearAllPoints()
		normal:SetPoint("TOPLEFT", button, 1, -1)
		normal:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	local icon = button.icon or button.Icon
	if icon then
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", button, 1, -1)
		icon:SetPoint("BOTTOMRIGHT", button, -1, 1)
		icon:SetTexCoord(.1, .9, .1, .9)
	end

	local cooldown = button.cooldown or button.Cooldown
	if cooldown then
		cooldown:ClearAllPoints()
		cooldown:SetPoint("TOPLEFT", button, 1, -1)
		cooldown:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	if button.HotKey then
		button.HotKey:SetFont(STANDARD_TEXT_FONT, HOTKEY_FONT_SIZE, "OUTLINE")
	end

	if button.Border then button.Border:SetTexture(nil) end
	if button.FloatingBG then button.FloatingBG:Hide() end
	if button.FlyoutBorder then button.FlyoutBorder:SetTexture(nil) end
	if button.FlyoutBorderShadow then button.FlyoutBorderShadow:SetTexture(nil) end
end

-- The real work. Runs on the next frame, never inside a secure call chain.
local function ApplyButtonStyles()
	if IsExcluded() then return end

	-- Protected calls are illegal in combat: remember it and retry at regen
	-- instead of letting Blizzard report a blocked action.
	if InCombat() then
		stylePendingCombat = true
		return
	end

	StyleExtraButtons()

	for b = 1, #ACTIONBARS do
		local barName = ACTIONBARS[b]
		for i = 1, BUTTONS_PER_BAR do
			StyleActionButton(_G[barName .. "Button" .. i])
		end
	end
end

-- ---------------------------------------------------------------------------
-- Deferred entry point
-- ---------------------------------------------------------------------------

local function RunDeferredStylePass()
	styleQueued = false

	if IsExcluded() then return end
	if AddUIDB and AddUIDB.mmb == false then return end

	ApplyButtonStyles()
end

-- PUBLIC. Safe to call from anywhere, including Blizzard's secure Edit Mode
-- exit chain: it never performs a protected call itself, it only schedules one.
function ns.StyleButton()
	if styleQueued then return end
	styleQueued = true

	-- One frame later the secure chain has finished, so SetScale is permitted.
	C_Timer.After(0, RunDeferredStylePass)
end

-- ---------------------------------------------------------------------------
-- Hotkey abbreviation logic (based on nMainbar\ActionButtonSkin.lua)
-- ---------------------------------------------------------------------------

local ActionBarActionButtonMixinHook_UpdateHotkeys = function(self)
	local hotkey = self and self.HotKey
	if not hotkey then return end

	local text = hotkey:GetText()
	if type(text) ~= "string" then return end

	text = gsub(text, "(s%-)", "s-")
	text = gsub(text, "(a%-)", "a-")
	text = gsub(text, "(c%-)", "c-")
	text = gsub(text, "(st%-)", "c-") -- German Control "Steuerung"

	for i = 1, 8 do
		local key = _G["KEY_BUTTON" .. i]
		if key then text = gsub(text, key, "M" .. i) end
	end

	for i = 0, 9 do
		local key = _G["KEY_NUMPAD" .. i]
		if key then text = gsub(text, key, "Nu" .. i) end
	end

	if KEY_NUMPADDECIMAL  then text = gsub(text, KEY_NUMPADDECIMAL,  "Nu.") end
	if KEY_NUMPADDIVIDE   then text = gsub(text, KEY_NUMPADDIVIDE,   "Nu/") end
	if KEY_NUMPADMINUS    then text = gsub(text, KEY_NUMPADMINUS,    "Nu-") end
	if KEY_NUMPADMULTIPLY then text = gsub(text, KEY_NUMPADMULTIPLY, "Nu*") end
	if KEY_NUMPADPLUS     then text = gsub(text, KEY_NUMPADPLUS,     "Nu+") end

	-- CAPSLOCK_KEY_TEXT is a table in some locales, so only use it as a pattern
	-- when it really is a string.
	if type(CAPSLOCK_KEY_TEXT) == "string" then
		text = gsub(text, CAPSLOCK_KEY_TEXT, "Cap")
	end

	if KEY_MOUSEWHEELUP   then text = gsub(text, KEY_MOUSEWHEELUP,   "M↑") end
	if KEY_MOUSEWHEELDOWN then text = gsub(text, KEY_MOUSEWHEELDOWN, "M↓") end
	if KEY_NUMLOCK        then text = gsub(text, KEY_NUMLOCK,        "NuL") end
	if KEY_PAGEUP         then text = gsub(text, KEY_PAGEUP,         "PU") end
	if KEY_PAGEDOWN       then text = gsub(text, KEY_PAGEDOWN,       "PD") end
	if KEY_SPACE          then text = gsub(text, KEY_SPACE,          "_") end
	if KEY_INSERT         then text = gsub(text, KEY_INSERT,         "Ins") end
	if KEY_HOME           then text = gsub(text, KEY_HOME,           "Hm") end
	if KEY_DELETE         then text = gsub(text, KEY_DELETE,         "Del") end

	hotkey:SetText(text)
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

-- Combat can end at any time, so this is registered at file scope.
ns.event("PLAYER_REGEN_ENABLED", function()
	if stylePendingCombat then
		stylePendingCombat = false
		ns.StyleButton()
	end
end)

ns.event("PLAYER_LOGIN", function()
	if IsExcluded() then return end
	if AddUIDB and AddUIDB.mmb == false then return end

	-- Apply button styling on initial login (deferred internally).
	ns.StyleButton()

	-- Re-apply styling when Edit Mode is exited. ns.StyleButton() handles the
	-- frame deferral, so the secure OnEditModeExit chain is never violated.
	if EditModeManagerFrame then
		EditModeManagerFrame:HookScript("OnHide", function()
			ns.StyleButton()
		end)
	end

	-- Hook global Mixin: newly created action bar buttons will also pick this up
	if ActionBarActionButtonMixin then
		pcall(hooksecurefunc, ActionBarActionButtonMixin, "UpdateHotkeys",
			ActionBarActionButtonMixinHook_UpdateHotkeys)
	end

	-- Iterate known action bar buttons and refresh hotkeys immediately.
	-- (Avoid EnumerateFrames on login -- too many frames causes "script ran too long")
	for _, barName in ipairs(ACTIONBARS) do
		for i = 1, BUTTONS_PER_BAR do
			local button = _G[barName .. "Button" .. i]
			if button then
				ActionBarActionButtonMixinHook_UpdateHotkeys(button)
				ns.hook(button, "UpdateHotkeys", ActionBarActionButtonMixinHook_UpdateHotkeys)
			end
		end
	end
end)
