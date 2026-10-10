local _,ns = ...
local statTimer
ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.stat then return end
	
	local StatSheet = CreateFrame("Frame", "StatSheet", UIParent)
	StatSheet:SetSize(160, 115)
	StatSheet:SetPoint("BOTTOMRIGHT", MainActionBar, "BOTTOMLEFT", -3, -3)
	ns.AddEdit(StatSheet)
	
	local Y = 0
	local scale = 15
	local StatList = {}
	local function CreateText(text1,text2,color)
		local Text1 = StatSheet:CreateFontString("Text", "OVERLAY")
		Text1:SetFont("fonts\\ARIALN.ttf", scale, "OUTLINE")
		Text1:SetText(text1..":")
		Text1:SetPoint("TOPLEFT", 0, (-scale-2) * Y)
		Text1:SetTextColor(unpack(color))
		local Text2 = StatSheet:CreateFontString("Text", "OVERLAY")
		Text2:SetFont("fonts\\ARIALN.ttf", scale, "OUTLINE")
		Text2:SetText(text2)
		Text2:SetPoint("TOPRIGHT", 0, (-scale-2) * Y)
		Text2:SetTextColor(unpack(color))
		Y = Y + 1
		StatList[text2] = Text2
	end
	
	if statTimer then return end
	statTimer = C_Timer.NewTicker(0.3, function()
		if StatList["Primary Stat"] then
			local _, _, _, _, _, primaryStat = GetSpecializationInfo(GetSpecialization())
			primaryStat = primaryStat or 1
			local strength = UnitStat("player", primaryStat)
			StatList["Primary Stat"]:SetText(format("%d", strength))
		else
			CreateText("Primary Stat","Primary Stat",{1, 0, 1})
		end
		local _,itemlevel = GetAverageItemLevel()
		if StatList["Item Level"] then
			StatList["Item Level"]:SetText(format("%.1f", itemlevel))
		else
			CreateText("Item Level","Item Level",{0, 1, 1})
		end
		
		if StatList[STAT_CRITICAL_STRIKE] then
			StatList[STAT_CRITICAL_STRIKE]:SetText(format("%.2f%%", GetSpellCritChance()))
		else
			CreateText(STAT_CRITICAL_STRIKE,STAT_CRITICAL_STRIKE,{1, 0.5, 0})
		end
		
		if StatList[STAT_HASTE] then
			StatList[STAT_HASTE]:SetText(format("%.2f%%",GetHaste()))
		else
			CreateText(STAT_HASTE,STAT_HASTE,{0,1,0})
		end
		
		if StatList[STAT_MASTERY] then
			StatList[STAT_MASTERY]:SetText(format("%.2f%%", GetMasteryEffect()))
		else
			CreateText(STAT_MASTERY,STAT_MASTERY,{0, 0.5, 1})
		end
		
		if StatList[STAT_VERSATILITY] then
			StatList[STAT_VERSATILITY]:SetText(format("%.2f%%", GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)))
		else
			CreateText(STAT_VERSATILITY,STAT_VERSATILITY,{1, 1, 0})
		end
	end)
end)
