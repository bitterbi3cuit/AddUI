local addonName,ns = ...

local function CanStyleButtons()
	if AddUIDB.mmb == false then return false end
	if C_AddOns.IsAddOnLoaded("Dominos") then return false end
	if C_AddOns.IsAddOnLoaded("Bartender4") then return false end
	if C_AddOns.IsAddOnLoaded("ElvUI") then return false end
	if C_AddOns.IsAddOnLoaded("BigFoot") then return false end
	if C_AddOns.IsAddOnLoaded("NDui") then return false end
	return true
end

local function StyleButton(button)
	local buttonName = button:GetName()
	local normalTexture = _G[buttonName.."NormalTexture"]
	local icon = _G[buttonName.."Icon"]
	local cooldown = _G[buttonName.."Cooldown"]
	local hotkey = _G[buttonName.."HotKey"]
	if not (button.HighlightTexture and button.CheckedTexture and normalTexture and icon and cooldown and hotkey) then return end

	-- SetScale is a protected function; skip it during combat or secure execution
	if not InCombatLockdown() then
		button:SetScale(1.095)
	end

	button:SetNormalTexture("Interface\\AddOns\\AddUI\\UI\\media\\normal")
	button:SetHighlightTexture("Interface\\AddOns\\AddUI\\UI\\media\\highlight") -- Mouseover highlight
	button.HighlightTexture:SetPoint("TOPLEFT", button, 1.5, -1.5)
	button.HighlightTexture:SetPoint("BOTTOMRIGHT", button, -1.5, 1.5)

	button:SetCheckedTexture("Interface\\AddOns\\AddUI\\UI\\media\\highlight") -- Casting texture
	button.CheckedTexture:SetPoint("TOPLEFT", button, 1.5, -1.5)
	button.CheckedTexture:SetPoint("BOTTOMRIGHT", button, -1.5, 1.5)

	--button:SetPushedTexture("Interface\\AddOns\\AddUI\\UI\\media\\highlight") -- Pushed texture

	normalTexture:SetPoint("TOPLEFT", button, 1, -1)
	normalTexture:SetPoint("BOTTOMRIGHT", button, -1, 1)
	icon:SetPoint("TOPLEFT", button, 1, -1)
	icon:SetPoint("BOTTOMRIGHT", button, -1, 1)
	icon:SetTexCoord(.1, .9, .1, .9)

	cooldown:SetPoint("TOPLEFT", button, 1, -1)
	cooldown:SetPoint("BOTTOMRIGHT", button, -1, 1)

	if ExtraActionButton1.style then ExtraActionButton1.style:Hide() end
	if ZoneAbilityFrame.Style then ZoneAbilityFrame.Style:Hide() end
	if _G[buttonName.."Border"] then _G[buttonName.."Border"]:SetTexture(nil) end
	if _G[buttonName.."FloatingBG"] then _G[buttonName.."FloatingBG"]:Hide() end
	if _G[buttonName.."FlyoutBorder"] then _G[buttonName.."FlyoutBorder"]:SetTexture(nil) end
	if _G[buttonName.."FlyoutBorderShadow"] then _G[buttonName.."FlyoutBorderShadow"]:SetTexture(nil) end

	hotkey:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
end

function ns.StyleButton(button)
	if not CanStyleButtons() then return end
	if button then
		StyleButton(button)
		return
	end
	ActionBarButtonEventsFrame:ForEachFrame(StyleButton)
end

local function HookButton(button)
	if button.UpdateButtonArt then
		ns.hook(button, "UpdateButtonArt", function(self)
			ns.StyleButton(self)
		end)
	end
end

ActionBarButtonEventsFrame:ForEachFrame(HookButton)
ns.hook(ActionBarButtonEventsFrame, "RegisterFrame", function(_, button)
	HookButton(button)
	ns.StyleButton(button)
end)

ns.event("PLAYER_ENTERING_WORLD", function()
	ns.StyleButton()
	C_Timer.After(5, function()
		if InCombatLockdown() then return end
		ns.StyleButton()
	end)
end)

-- Defer styling until the next frame so we run outside Blizzard's secure
-- SetAttribute execution path, which would taint SetScale otherwise.
ns.hook(EditModeManagerFrame, "ExitEditMode", function()
	C_Timer.After(0, function()
		if InCombatLockdown() then return end
		ns.StyleButton()
	end)
end)

-- Hotkey modifications adapted from nMainbar\ActionButtonSkin.lua
local ActionBarActionButtonMixinHook_UpdateHotkeys = function(self, actionButtonType)
    local hotkey = self.HotKey
    local text = hotkey:GetText()

    text = gsub(text, "(s%-)", "s-")
    text = gsub(text, "(a%-)", "a-")
    text = gsub(text, "(c%-)", "c-")
    text = gsub(text, "(st%-)", "c-") -- German Control "Steuerung"

    for i = 1, 8 do
        text = gsub(text, _G["KEY_BUTTON"..i], "M"..i)
    end

    for i = 0, 9 do
        text = gsub(text, _G["KEY_NUMPAD"..i], "Nu"..i)
    end

    text = gsub(text, KEY_NUMPADDECIMAL, "Nu.")
    text = gsub(text, KEY_NUMPADDIVIDE, "Nu/")
    text = gsub(text, KEY_NUMPADMINUS, "Nu-")
    text = gsub(text, KEY_NUMPADMULTIPLY, "Nu*")
    text = gsub(text, KEY_NUMPADPLUS, "Nu+")

	text = gsub(text, CAPSLOCK_KEY_TEXT, "Cap")

    text = gsub(text, KEY_MOUSEWHEELUP, "M↑")
    text = gsub(text, KEY_MOUSEWHEELDOWN, "M↓")
    text = gsub(text, KEY_NUMLOCK, "NuL")
    text = gsub(text, KEY_PAGEUP, "PU")
    text = gsub(text, KEY_PAGEDOWN, "PD")
    text = gsub(text, KEY_SPACE, "_")
    text = gsub(text, KEY_INSERT, "Ins")
    text = gsub(text, KEY_HOME, "Hm")
    text = gsub(text, KEY_DELETE, "Del")

    hotkey:SetText(text)
end
-- Force Hotkey Update
ns.event("PLAYER_LOGIN", function(event)
	if not CanStyleButtons() then return end
	-- Hook global Mixin: action bar buttons created dynamically after login will also be updated automatically
	pcall(hooksecurefunc, ActionBarActionButtonMixin, "UpdateHotkeys", ActionBarActionButtonMixinHook_UpdateHotkeys)

	-- Iterate over known action bar buttons and immediately refresh hotkeys
	-- (avoid using EnumerateFrames to iterate all UI frames; too many frames at login can cause "script ran too long")
	ActionBarButtonEventsFrame:ForEachFrame(function(button)
		ActionBarActionButtonMixinHook_UpdateHotkeys(button) -- immediately refresh hotkeys
		ns.hook(button, "UpdateHotkeys", ActionBarActionButtonMixinHook_UpdateHotkeys) -- also applies to future key binding changes
	end)
end)
