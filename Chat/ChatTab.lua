local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if not AddUIDB.chatb then return end

--JoinChannelByName("LookingForGroup")
local chatFrame = SELECTED_DOCK_FRAME
COLORSCHEME_BORDER = { 0.3,0.3,0.3,1 }

local chat = CreateFrame("Frame","chat",UIParent)
chat:SetWidth(23)
chat:SetHeight(23)
chat:SetPoint("BOTTOMLEFT",ChatFrame1,0,-50)

-- Shared helper function for creating the buttons
local offset = 0
local function CreateChatButton(name, text, color, onClick, offX)
	if offX then
		offset = offset + offX
	end
	local btn = CreateFrame("Button", name, chat)
	btn:SetWidth(25)
	btn:SetHeight(25)
	btn:SetPoint("TOPLEFT", chat, "TOPLEFT", offset*30, 0)
	offset = offset + 1
	btn:RegisterForClicks("AnyUp")
	btn:SetScript("OnClick", onClick)
	
	btn.text = btn:CreateFontString(nil, "OVERLAY")
	btn.text:SetFont("fonts\\ARIALN.ttf", 15, "OUTLINE")
	btn.text:SetJustifyH("CENTER")
	btn.text:SetWidth(30)
	btn.text:SetHeight(25)
	btn.text:SetText(text)
	btn.text:SetPoint("CENTER", 0, 0)
	btn.text:SetTextColor(color[1], color[2], color[3])
	return btn
end

-- Say
local Say = CreateChatButton("ChannelSay", "S", {1, 1, 1},
	function() ChatFrame_OpenChat("/s ", chatFrame) end)

-- Yell
local Yell = CreateChatButton("ChannelYell", "Y", {255/255, 64/255, 64/255},
	function() ChatFrame_OpenChat("/y ", chatFrame) end)

-- Party
local Party = CreateChatButton("ChannelParty", "P", {170/255, 170/255, 255/255},
	function() ChatFrame_OpenChat("/p ", chatFrame) end)

-- Guild
local Guild = CreateChatButton("ChannelGuild", "G", {64/255, 255/255, 64/255},
	function() ChatFrame_OpenChat("/g ", chatFrame) end)

-- Raid
local Raid = CreateChatButton("ChannelRaid", "R", {255/255, 127/255, 0},
	function() ChatFrame_OpenChat("/raid ", chatFrame) end)

-- Dungeon
local BG = CreateChatButton("Channel_03", "D", {255/255, 127/255, 0},
	function() ChatFrame_OpenChat("/bg ", chatFrame) end)

-- General channel
local General = CreateChatButton("Channel_01", "g", {210/255, 180/255, 140/255},
	function()
		local jiaoyi = GetChannelName("General")
		if jiaoyi == 0 then print("You are not in the General channel") return end
		ChatFrame_OpenChat("/"..jiaoyi.." ", chatFrame)
	end)

-- Trade channel
local Trade = CreateChatButton("Channel_02", "T", {255/255, 130/255, 130/255},
	function()
		local jiaoyi = GetChannelName("Trade")
		if jiaoyi == 0 then print("You are not in the Trade channel - join it in a major city") return end
		ChatFrame_OpenChat("/"..jiaoyi.." ", chatFrame)
	end)


-- BigFoot world channel
local World = CreateChatButton("Channel_05", "W", {200/255, 255/255, 150/255},
	function(self, button)
	if button == "RightButton" then
		local _, channelName = GetChannelName("BigFoot World")
		if not channelName then
			JoinPermanentChannel("BigFoot World", nil, 1, 1)
			print("|cff00d200Joined the BigFoot World channel|r, right-click >|cffC8FF96World|r< to join/leave")
		else
			LeaveChannelByName("BigFoot World")
			print("|cffd20000Left the BigFoot World channel|r")
		end
	else
		local channel, channelName = GetChannelName("BigFoot World")
		if not channelName then
			JoinPermanentChannel("BigFoot World", nil, 1, 1)
			C_Timer.After(0.3, function()
				local ch = GetChannelName("BigFoot World")
				ChatFrame_OpenChat("/"..ch.." ", chatFrame)
			end)
		else
			ChatFrame_OpenChat("/"..channel.." ", chatFrame)
		end
	end
end)

-- Report button
local report = CreateChatButton(nil, "inf", {255/255, 255/255, 0/255},
	function()
	local S_C = UnitStat("player", 1)
	local AG_C = UnitStat("player", 2)
	local IN_C = UnitStat("player", 4)
	local stat1 = "iLvl:" .. format("%.1F", select(2, GetAverageItemLevel())) .. "/" .. format("%.1F", select(1, GetAverageItemLevel()))
	local stat2 = "Class:" .. UnitClass("player")
	local stat3 = "Spec:" .. select(2, GetSpecializationInfo(GetSpecialization()))
	local stat4 = ""
	if S_C > AG_C and S_C > IN_C then
		stat4 = "Strength:" .. S_C
	elseif AG_C > S_C and AG_C > IN_C then
		stat4 = "Agility:" .. AG_C
	elseif IN_C > S_C and IN_C > AG_C then
		stat4 = "Intellect:" .. IN_C
	end
	
	local line = stat1 .. " " .. stat2 .. " " .. stat3 .. " " .. stat4 .. 
		" Crit:" .. format("%.2F%%", GetSpellCritChance(2)) ..
		" Haste:" .. format("%.2F%%", GetHaste()) ..
		" Mastery:" .. format("%.2F%%", select(1, GetMasteryEffect())) ..
		" Versatility:" .. format("%.2F%%", GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE))
	ChatFrame_OpenChat(line, chatFrame)
end)


-- Roll button
local roll = CreateFrame("Button", "rollMacro", chat)
roll:SetWidth(23)
roll:SetHeight(23)
roll:SetPoint("TOPRIGHT", chat, "TOPRIGHT", 300, -1)
roll:RegisterForClicks("AnyUp")
roll:SetScript("OnClick", function() RandomRoll(1, 100) end)
roll.texture = roll:CreateTexture("Button", nil, frame)
roll.texture:SetWidth(23)
roll.texture:SetHeight(23)
roll.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
roll.texture:SetPoint("CENTER", 0, 0)

-- Ready check button
local ChatReady = CreateFrame("Button", "ChatReady", chat)
ChatReady:SetWidth(33)
ChatReady:SetHeight(33)
ChatReady:SetPoint("TOPRIGHT", chat, "TOPRIGHT", 338, 6)
ChatReady:RegisterForClicks("AnyUp")
ChatReady:SetScript("OnClick", function(self, button)
	if button == "RightButton" then
		if C_PartyInfo and C_PartyInfo.DoCountdown then
			C_PartyInfo.DoCountdown(10)
		end
	else
		DoReadyCheck()
	end
end)
ChatReady:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cff00FF00Left-click: ready check|r |cffFFFF00Right-click: countdown|r",1,1,1)
	GameTooltip:Show()
end)
ChatReady:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
ChatReady.texture = ChatReady:CreateTexture("Button", nil, frame)
ChatReady.texture:SetWidth(30)
ChatReady.texture:SetHeight(30)
ChatReady.texture:SetAtlas(READY_CHECK_READY_TEXTURE_RAID)
ChatReady.texture:SetPoint("CENTER", 0, 0)

-- Combat log on/off
if not AddUIDB.lotbnt then return end
local logbtn = CreateChatButton("Channel_02", "Log",
	LoggingCombat() and {0,1,0} or (not AddUIDB.AutoLog and {0.5, 0.5, 0.5} or {1,0,0}),
	function(self, button)
		local logtrue = LoggingCombat()
		if IsShiftKeyDown() then
			if AddUIDB.AutoLog then
				AddUIDB.AutoLog = false
				print("|cffd20000Mythic+ auto combat logging disabled|r")
				ns.AATEXT("|cffd20000Mythic+ auto combat logging disabled|r")
			else
				AddUIDB.AutoLog = true
				print("|cff00d200Mythic+ auto combat logging enabled|r")
				ns.AATEXT("|cff00d200Mythic+ auto combat logging enabled|r")
			end
		else
			if logtrue then
				logtrue = false
				LoggingCombat(false)
				print("|cffd20000Combat log stopped|r")
				ns.AATEXT("|cffd20000Combat log stopped|r")
			else
				logtrue = true
				LoggingCombat(true)
				print("|cff00d200Combat log started|r")
				ns.AATEXT("|cff00d200Combat log started|r")
			end
		end
		local color = logtrue and {0,1,0} or (not AddUIDB.AutoLog and {0.5, 0.5, 0.5} or {1,0,0})
		self.text:SetTextColor(unpack(color))
	end,2.2)
	logbtn:RegisterEvent("PLAYER_ENTERING_WORLD")
	logbtn:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	logbtn:RegisterEvent("CHALLENGE_MODE_START")
	logbtn:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	logbtn:SetScript("OnEvent", function(self, event)
		if not AddUIDB.AutoLog then return end
		if not LoggingCombat() and (event == "CHALLENGE_MODE_START" or C_ChallengeMode.IsChallengeModeActive()) then
			LoggingCombat(true)
			self.text:SetTextColor(0,1,0)
			print("|cff00d200Combat log started|r")
			ns.AATEXT("|cff00d200Combat log started|r")
			logbtn.Timer = nil
		end
		if event == "CHALLENGE_MODE_COMPLETED" or not IsInInstance() then
			if logbtn.Timer then return end
			logbtn.Timer = C_Timer.NewTicker(10, function()
				if not LoggingCombat() then return end
				LoggingCombat(false)
				self.text:SetTextColor(1,0,0)
				print("|cffd20000Combat log stopped|r")
				ns.AATEXT("|cffd20000Combat log stopped|r")
				logbtn.Timer = nil
			end, 1)
		end
	end)
	logbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
		local MText = AddUIDB.AutoLog and "|cff00FF00enabled|r" or "|cffd20000disabled|r"
		GameTooltip:SetText("|cff00FF00Combat log toggle|r (click to switch)\n|cffFFFF00Mythic+ auto-start:|r " .. MText .. " (hold Shift to toggle)",1,1,1)
		GameTooltip:Show()
	end)
	logbtn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)



end)
