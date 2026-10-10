local _, ns = ...
local londingcolor = RAID_CLASS_COLORS
ns.tips("Automatically sets up Misdirection/Tricks of the Trade macros (requires an existing macro named \"Tricks\" or \"Misdirection\")")

local WD = {}
WD.InCombat = false

function WD:UpdateMacroTarget()
	if IsInRaid() then
		for i = 1, 40 do
			if UnitGroupRolesAssigned("raid"..i) == "TANK" then
				WD.NewName = UnitName("raid"..i)
				WD.Lclass, WD.NewClass = UnitClass("raid"..i)
				break;
			end
		end
	elseif IsInGroup() then
		for i = 1, 4 do
			if UnitGroupRolesAssigned("party"..i) == "TANK" then
				WD.NewName = UnitName("party"..i)
				WD.Lclass, WD.NewClass = UnitClass("raid"..i)
				break;
			end
		end
	end

	if WD.NewName == WD.OldName then return end

	local ClassColor = RAID_CLASS_COLORS[WD.NewClass] and RAID_CLASS_COLORS[WD.NewClass].colorStr or "ffFFFFFF"
	local _, playerclass = UnitClass("player")
	if WD.NewName and GetMacroInfo("Misdirection") and playerclass == "HUNTER" then
		EditMacro("Misdirection", nil, nil, "#showtooltip\n/cast [@target,help,exists][@"..WD.NewName..",exists][@pet][]Misdirection")
		UIErrorsFrame:AddExternalWarningMessage("Misdirection target set:  "..WD.NewName)
		ns.AATEXT("Misdirection macro target changed to:  |T132180:30|t|c"..ClassColor..WD.NewName.."|r")
		print("|cffFF0000Misdirection macro target changed to:   |r|T132180:30|t|c"..ClassColor..WD.NewName.."|r")
		WD.OldName = WD.NewName
	end
	if WD.NewName and GetMacroInfo("Tricks") and playerclass == "ROGUE" then
		EditMacro("Tricks", nil, nil, "#showtooltip\n/cast [@target,help,exists][@"..WD.NewName..",exists][]Tricks of the Trade")
		UIErrorsFrame:AddExternalWarningMessage("Tricks target set:  "..WD.NewName)
		ns.AATEXT("Tricks macro target changed to:  |T236283:30|t|c"..ClassColor..WD.NewName.."|r")
		print("|cffFF0000Tricks macro target changed to:   |r|T236283:30|t|c"..ClassColor..WD.NewName.."|r")
		WD.OldName = WD.NewName
	end
end

local function OnWDEvent(event)
	if event == 'GROUP_ROSTER_UPDATE' or event == 'PLAYER_ENTERING_WORLD' then
		if InCombatLockdown() then
			WD.InCombat = true
		else
			WD:UpdateMacroTarget()
		end
	elseif event == 'PLAYER_REGEN_ENABLED' then
		if WD.InCombat then
			WD:UpdateMacroTarget()
			WD.InCombat = false
		end
	end
end

ns.event('GROUP_ROSTER_UPDATE', OnWDEvent)
ns.event('PLAYER_ENTERING_WORLD', OnWDEvent)
ns.event('PLAYER_REGEN_ENABLED', OnWDEvent)
