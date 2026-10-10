local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if not AddUIDB.chatm then return end

-- Partly modified from an NGA thread: http://bbs.ngacn.cc/read.php?tid=9706946

-- Configure chat frame tabs ------------------------------------

local function GetChatFrame(cname)
	local index = 0
	for i = 1, NUM_CHAT_WINDOWS do
		local name = GetChatWindowInfo(i)
		if name == cname then
			index = i
			break
		end
	end
	return _G['ChatFrame' .. index]
end

local function ChatAddWindow(name)
	FCF_OpenNewWindow(name)
	FCF_DockUpdate();
	local chatFrame = GetChatFrame(name)
	ChatFrame_RemoveAllChannels(chatFrame)
	ChatFrame_RemoveAllMessageGroups(chatFrame)
	if name == "综合" then
		JoinChannelByName("大脚世界频道")
		-- AddChatWindowChannel(chatFrame, "大脚世界频道")
		ChatFrame_AddMessageGroup(chatFrame, "WHISPER")
	end
	if name == "聊天" then
		ChatFrame_AddMessageGroup(chatFrame, "SAY")-- Say
		ChatFrame_AddMessageGroup(chatFrame, "YELL")-- Yell
		ChatFrame_AddMessageGroup(chatFrame, "EMOTE")-- Emote
		ChatFrame_AddMessageGroup(chatFrame, "GUILD")-- Guild
		ChatFrame_AddMessageGroup(chatFrame, "OFFICER")-- Officer
		ChatFrame_AddMessageGroup(chatFrame, "GUILD_ACHIEVEMENT")-- Guild announcement
		ChatFrame_AddMessageGroup(chatFrame, "ACHIEVEMENT")-- Achievement announcement
		ChatFrame_AddMessageGroup(chatFrame, "WHISPER")-- Whisper
		ChatFrame_AddMessageGroup(chatFrame, "BN_WHISPER")-- Battle.net whisper
		ChatFrame_AddMessageGroup(chatFrame, "PARTY")-- Party
		ChatFrame_AddMessageGroup(chatFrame, "PARTY_LEADER")-- Party leader
		ChatFrame_AddMessageGroup(chatFrame, "RAID")-- Raid
		ChatFrame_AddMessageGroup(chatFrame, "RAID_LEADER")-- Raid leader
		ChatFrame_AddMessageGroup(chatFrame, "RAID_WARNING")-- Raid warning
		ChatFrame_AddMessageGroup(chatFrame, "INSTANCE_CHAT")-- Instance chat
		ChatFrame_AddMessageGroup(chatFrame, "INSTANCE_CHAT_LEADER")-- Instance leader

		--ChatFrame_AddMessageGroup(chatFrame, "COMBAT_XP_GAIN")-- Experience
		--ChatFrame_AddMessageGroup(chatFrame, "COMBAT_GUILD_XP_GAIN")-- Guild experience
		ChatFrame_AddMessageGroup(chatFrame, "COMBAT_HONOR_GAIN")-- Honor
		ChatFrame_AddMessageGroup(chatFrame, "COMBAT_FACTION_CHANGE")-- Reputation
		ChatFrame_AddMessageGroup(chatFrame, "SKILL")-- Skill up
		ChatFrame_AddMessageGroup(chatFrame, "LOOT")-- Item loot
		ChatFrame_AddMessageGroup(chatFrame, "CURRENCY")-- Currency
		ChatFrame_AddMessageGroup(chatFrame, "MONEY")-- Money loot
		--ChatFrame_AddMessageGroup(chatFrame, "TRADESKILLS")-- Tradeskills
		ChatFrame_AddMessageGroup(chatFrame, "OPENING")-- Opening
		ChatFrame_AddMessageGroup(chatFrame, "PET_INFO")-- Pet info
		ChatFrame_AddMessageGroup(chatFrame, "COMBAT_MISC_INFO")-- Misc info

		ChatFrame_AddMessageGroup(chatFrame, "BG_HORDE")-- Battleground Horde
		ChatFrame_AddMessageGroup(chatFrame, "BG_ALLIANCE")-- Battleground Alliance
		ChatFrame_AddMessageGroup(chatFrame, "BG_NEUTRAL")-- Battleground Neutral

		ChatFrame_AddMessageGroup(chatFrame, "SYSTEM")-- System
		ChatFrame_AddMessageGroup(chatFrame, "ERRORS")-- Errors
		ChatFrame_AddMessageGroup(chatFrame, "IGNORED")-- Ignored
		ChatFrame_AddMessageGroup(chatFrame, "TARGETICONS")-- Target icons
		ChatFrame_AddMessageGroup(chatFrame, "BN_INLINE_TOAST_ALERT")-- Battle.net toast
		--ChatFrame_AddMessageGroup(chatFrame, "PET_BATTLE_COMBAT_LOG")-- Pet battle
		--ChatFrame_AddMessageGroup(chatFrame, "PET_BATTLE_INFO")-- Pet battle info

		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_SAY")-- Monster say
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_EMOTE")-- Monster emote
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_YELL")-- Monster yell
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_WHISPER")-- Monster whisper
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_BOSS_EMOTE")-- Boss lines
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_BOSS_WHISPER")-- Boss whisper

	end
	if name == "密语" then
		ChatFrame_AddMessageGroup(chatFrame, "WHISPER")
		ChatFrame_AddMessageGroup(chatFrame, "BN_WHISPER")
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_PARTY")
	end
end
--AddChatWindowChannel
local function Chat()
	FCF_ResetChatWindows()
	ChatAddWindow("聊天")
	ChatAddWindow("密语")
	SetCVar("whisperMode","inline")

	for k,v in pairs(CHAT_CONFIG_CHAT_LEFT) do
		SetChatColorNameByClass(v.type, true)
	end
	for k,v in pairs({GetChannelList()}) do
		local id = tonumber(v)
		if id then
			SetChatColorNameByClass("CHANNEL"..id, true)
		end
	end

	--DEFAULT_CHAT_FRAME:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 0, 50);
	--DEFAULT_CHAT_FRAME:SetSize(400, 200)
	-- Class-colored chat messages
	for k,v in pairs(CHAT_CONFIG_CHAT_LEFT) do
		SetChatColorNameByClass(v.type, true)
	end
	for k,v in pairs({GetChannelList()}) do
		local id = tonumber(v)
		if id then
			SetChatColorNameByClass("CHANNEL"..id, true)
		end
	end
	SetCVar("remoteTextToSpeech",0)	-- Speak for me in voice chat
end
SLASH_CHAT1 = "/chat"		-- Type the command to run it
SlashCmdList["CHAT"] = function (msg, editbox)
	if msg == "" then Chat()end
end

-- Show item/equipment details when hovering over the chat frame
---------------------------------------------------------------------------------------- 
--   Based on tekKompare(by Tekkub) 
---------------------------------------------------------------------------------------- 
local orig1, orig2, GameTooltip = {}, {}, GameTooltip 
local linktypes = {item = true, enchant = true, spell = true, quest = true, unit = true, talent = true, achievement = true, glyph = true, instancelock = true, currency = true} 

local function OnHyperlinkEnter(frame, link, ...)
	if not link then return end
	local linktype = link:match("^([^:]+)")
	if linktype and linktype == "battlepet" then
		GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT", 250, 0)
		GameTooltip:Show()
		local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", link)
		BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed))
	elseif linktype and linktypes[linktype] then
		GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT", 250, 0)
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end

	if orig1[frame] then return orig1[frame](frame, link, ...) end
end

local function OnHyperlinkLeave(frame, link, ...)
	--local linktype = link:match("^([^:]+)")
	--if linktype and linktype == "battlepet" then
	BattlePetTooltip:Hide()
	--elseif linktype and linktypes[linktype] then
	GameTooltip:Hide()
	--end

	if orig1[frame] then return orig1[frame](frame, link, ...) end
end

for i = 1, NUM_CHAT_WINDOWS do
	local frame = _G["ChatFrame"..i]
	orig1[frame] = frame:GetScript("OnHyperlinkEnter")
	frame:HookScript("OnHyperlinkEnter", OnHyperlinkEnter)

	orig2[frame] = frame:GetScript("OnHyperlinkLeave")
	frame:HookScript("OnHyperlinkLeave", OnHyperlinkLeave)
end

-- Tab coloring ------------------------------------------------------------------------------------------------
local Fane = CreateFrame("Frame")
local inherit = GameFontNormalSmall
local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

local function updateFS(self, inc, flags, ...)
	local fstring = self:GetFontString()
	local font, fontSize = inherit:GetFont()
	if inc then
		fstring:SetFont(font, fontSize + 1, flags)
	else
		fstring:SetFont(font, fontSize, flags)
	end
	if (...) then
		fstring:SetTextColor(...)
	end
end

local function OnEnter(self)
	updateFS(self, nil, "OUTLINE", color.r, color.g, color.b)  -- Mouseover color
end

local function OnLeave(self)
	local id = self:GetID()
	local emphasis = _G["ChatFrame" .. id .. "TabFlash"]:IsShown()
	if _G["ChatFrame" .. id] == SELECTED_CHAT_FRAME then
		updateFS(self, false, nil, color.r, color.g, color.b)  -- Selected = class color
	else
		updateFS(self, emphasis, nil, 1, 1, 1)                  -- emphasis controls bold
	end
end

local function faneifyTab(frame, sel)
	local i = frame:GetID()
	if not frame.Fane then
		frame.HighlightLeft:SetTexture(nil)
		frame.ActiveLeft:SetTexture(nil)
		frame.Left:SetTexture(nil)
		frame.HighlightRight:SetTexture(nil)
		frame.ActiveRight:SetTexture(nil)
		frame.Right:SetTexture(nil)
		frame.Middle:SetTexture(nil)
		frame.HighlightMiddle:SetTexture(nil)
		frame.ActiveMiddle:SetTexture(nil)

		frame:HookScript("OnEnter", OnEnter)
		frame:HookScript("OnLeave", OnLeave)
		frame:SetAlpha(1)
		frame.Fane = true
	end
	-- We can't trust sel. :(
	if i == SELECTED_CHAT_FRAME:GetID() then
		updateFS(frame, nil, nil, color.r, color.g, color.b)
	else
		updateFS(frame, nil, nil, 1, 1, 1)
	end
end

ns.hook("FCF_StartAlertFlash", function(frame)
	local tab = _G["ChatFrame" .. frame:GetID() .. "Tab"]
	updateFS(tab, true, nil, color.r, color.g, color.b)
end)

ns.hook("FCFTab_UpdateColors", faneifyTab)

for i = 1, 7 do
	faneifyTab(_G["ChatFrame" .. i .. "Tab"])
end

function Fane:ADDON_LOADED(event, addon)
	if addon == "Blizzard_CombatLog" then
		self:UnregisterEvent(event)
		self[event] = nil
		return CombatLogQuickButtonFrame_Custom:SetAlpha(0.4)
	end
end

Fane:RegisterEvent("ADDON_LOADED")
Fane:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

end)
