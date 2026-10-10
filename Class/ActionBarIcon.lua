local _,ns = ...
 
-- Shaman: after casting 470057, the 51505 button icon changes to 1259491; restored after casting 51505
local _, cls = UnitClass("player")
if cls == "SHAMAN" then
	ns.event("PLAYER_LOGIN", function()
		if not (AddUIDB and AddUIDB.shamanIconSwap) then return end
 
		local BUFF_ID = 1259491      -- the icon (spell) to swap to - Purifying Flame
		local BAR_SPELL_ID = 51505   -- the button spell whose icon is replaced - Lava Burst
		local TRIGGER_ID = 470057    -- casting this triggers the icon swap - Galvanic Blaze
		local ICON_FILE = C_Spell.GetSpellTexture(BUFF_ID)
		local ACTIONBARS = {"Action","MultiBarBottomLeft","MultiBarBottomRight","MultiBarLeft","MultiBarRight","MultiBar5","MultiBar6","MultiBar7"}
 
		-- Loop through the action bars to find the button bound to the given spell
		local function FindActionButton(spellID)
			for _, bar in ipairs(ACTIONBARS) do
				for i = 1, 12 do
					local btn = _G[bar.."Button"..i]
					local action = btn and btn.action
					if action then
						local _, id = GetActionInfo(action)
						if id == spellID then return btn end
					end
				end
			end
		end
 
		local targetBtn
		local swapped = false
 
		-- Set the button icon to the given texture (trim the black border)
		local function SetIcon(btn, texture)
			local icon = btn and (btn.Icon or btn.icon)
			if icon then
				icon:SetTexture(texture)
				icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			end
		end
 
		-- Restore the button's original icon
		local function RestoreIcon(btn)
			local icon = btn and (btn.Icon or btn.icon)
			if icon and btn.action then
				icon:SetTexture(C_ActionBar.GetActionTexture(btn.action))
				icon:SetTexCoord(0, 1, 0, 1)
			end
		end
 
		-- On entering world: find the button and hook it; keep the icon per state on refresh
		ns.event("PLAYER_ENTERING_WORLD", function()
			targetBtn = FindActionButton(BAR_SPELL_ID)
			if not targetBtn then
				print("Could not find spell "..BAR_SPELL_ID.." on the action bars "..(C_Spell.GetSpellName(BAR_SPELL_ID) or ""))
				return
			end
			pcall(hooksecurefunc, targetBtn, "Update", function(self)
				if swapped then SetIcon(self, ICON_FILE) end
			end)
		end)
 
		-- Casting 470057 swaps the icon; casting 51505 restores it
		ns.event("UNIT_SPELLCAST_SUCCEEDED", function(event, unit, _, spellID)
			if unit ~= "player" then return end
			if spellID == TRIGGER_ID then
				swapped = true
				if targetBtn then SetIcon(targetBtn, ICON_FILE) end
			elseif spellID == BAR_SPELL_ID and swapped then
				swapped = false
				if targetBtn then RestoreIcon(targetBtn) end
			end
		end)
	end)
end
