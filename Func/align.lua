local _,ns = ...

SetCVar("overrideArchive", 0) -- Anti-censorship (CN realms)  1: on      0: off
--[Reload commands]
ns.tips("Reload shortcut: /rl or /aa")
SlashCmdList["RELOADUI"] = function() ReloadUI() end
SLASH_RELOADUI1 = "/rl"
SLASH_RELOADUI2 = "/aa"


ns.tips("Pin the countdown so the key frame cannot cover it")
ns.event('START_TIMER', function()
	if InCombatLockdown() then return end
	if not TimerTrackerTimer1 then return end
	TimerTrackerTimer1:SetFrameStrata("TOOLTIP")
end)
ns.tips("Pin the ready check so the key frame cannot cover it")
ns.event('READY_CHECK', function()
	if InCombatLockdown() then return end
	if not ReadyCheckFrame then return end
	ReadyCheckFrame:SetFrameStrata("TOOLTIP")
end)

ns.tips("Mouse passthrough on zone toasts (they get in the way when picking targets after a key opens)")
-- Toast content frames are created dynamically (pooled), so mouse must be disabled recursively
-- on the main frame and on every generated toast.
-- Two categories must keep the mouse, otherwise sticky popups cannot be closed:
-- 1. Buttons: the big CLOSE at the bottom (a fixed child of the main frame with no
--    hideAutomatically, so it is only identifiable by its button type), the scoreboard CLOSE,
--    and the scene toast that expands on click.
-- 2. Any toast with hideAutomatically = false (whole subtree): a pooled instance that was
--    disabled does not restore itself when shown again, so keep its interactive children alive too.
local function SetToastMousePassthrough(frame)
	if not frame then return end
	if frame == EventToastManagerFrame.HideButton then return end
	if frame.hideAutomatically == false then return end
	frame:EnableMouse(false)
	for i = 1, frame:GetNumChildren() do
		SetToastMousePassthrough(select(i, frame:GetChildren()))
	end
end
if EventToastManagerFrame then
	SetToastMousePassthrough(EventToastManagerFrame)
	hooksecurefunc(EventToastManagerFrame, "DisplayToast", function(self)
		SetToastMousePassthrough(self)
	end)
end


ns.tips("Chat profanity filter override")
local function ApplyFilterOverride()
--ConsoleExec("portal TW")
ConsoleExec("profanityFilter 0")
end
ns.event("ADDON_LOADED", ApplyFilterOverride)

-- 9.1 cross-realm friends cannot group: https://bbs.nga.cn/read.php?&tid=27432996
local pre = C_BattleNet.GetFriendGameAccountInfo
C_BattleNet.GetFriendGameAccountInfo = function(...)
	local gameAccountInfo = pre(...)
	if gameAccountInfo then gameAccountInfo.isInCurrentRegion = true end
	return gameAccountInfo;
end

ns.tips("Relay reset announcements")
ns.event('CHAT_MSG_SYSTEM', function(event, msg)
	if ns.MM(msg) then return end
	if (msg:lower():match("无法重置") or msg:lower():match("已被重置")) and IsInGroup() and UnitIsGroupLeader("player") then
		C_ChatInfo.SendChatMessage(msg,'PARTY')
	end
end)

-- Ready check sound
ns.event('READY_CHECK', function()
	PlaySoundFile(567478, "Master")
	--PlaySoundFile("Interface\\AddOns\\AddUI\\Func\\call\\AreYouReady.mp3", "Master")
end)

ns.tips("/cd or /cd 10 to start a countdown, /cdd to stop")
-- Countdown /cd defaults to 10 seconds
SlashCmdList["COUNTDOWN"] = function(msg)
	local num1 = gsub(msg, "(%s*)(%d+)", "%2");
	local number = tonumber(num1);
	if not number then number = 10 end
	if(number and number <= MAX_COUNTDOWN_SECONDS) then
		C_PartyInfo.DoCountdown(number);
	end
end
-- Stop countdown
SlashCmdList["COUNTDOWNSTOP"] = function()
	C_PartyInfo.DoCountdown(0);
end
SLASH_COUNTDOWNSTOP1 = "/cdd"

ns.tips("Add a Great Vault button to the dungeon page")
local clear
if PVEFrame and PVEFrame.NineSlice then
	clear = CreateFrame("Button", "AddUISaveButton", PVEFrame.NineSlice, "UIPanelButtonTemplate")
	clear:SetText("Great Vault")
	clear:SetWidth(110)
	clear:SetHeight(22)
	clear:SetPoint("TOPLEFT", 57, 0)
	clear:SetScript("OnClick", function()
		if (WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown()) then
			HideUIPanel(WeeklyRewardsFrame);
		else
			C_AddOns.LoadAddOn("Blizzard_WeeklyRewards"); WeeklyRewardsFrame:Show()
		end
	end)
end

ns.tips("Add a leave-party button to the character sheet")
local CHLP
if PaperDollItemsFrame then
	CHLP = CreateFrame("Button", "AddUICharLeaveParty", PaperDollItemsFrame, "UIPanelButtonTemplate")
	CHLP:SetText("Leave")
	CHLP:SetWidth(50)
	CHLP:SetHeight(22)
	CHLP:SetPoint("BOTTOMLEFT", 7, 9)
	CHLP:SetScript("OnClick", function()
		if IsInGroup() then
			UIErrorsFrame:AddExternalWarningMessage(ERR_LEFT_GROUP_YOU)
		end
		C_PartyInfo.LeaveParty()
	end)
end

ns.tips("Add a leave-party button to the dungeon page")
local LFGLP
if PVEFrame then
	LFGLP = CreateFrame("Button", "AddUIPVELeaveParty", PVEFrame, "UIPanelButtonTemplate")
	LFGLP:SetText("Leave")
	LFGLP:SetWidth(50)
	LFGLP:SetHeight(22)
	LFGLP:SetPoint("BOTTOMLEFT", 10, 10)
	LFGLP:SetScript("OnClick", function()
		if IsInGroup() then
			UIErrorsFrame:AddExternalWarningMessage(ERR_LEFT_GROUP_YOU)
		end
		C_PartyInfo.LeaveParty()
	end)
end

ns.tips("Auto-fill the DELETE confirmation")-- exwind
local DELETE_STR = DELETE_ITEM_CONFIRM_STRING or "DELETE"
local deletePopups = {
    DELETE_GOOD_ITEM        = true,
    DELETE_GOOD_QUEST_ITEM  = true,
    DELETE_QUEST_ITEM       = true,
}
local function FillDeleteText(dialog)
    local editBox = dialog and dialog.GetEditBox and dialog:GetEditBox()
    if editBox then
        editBox:SetText(DELETE_STR)
    end
end

ns.hook("StaticPopup_Show", function(which, text, text_arg2, data)
	if deletePopups[which] then
		C_Timer.After(0, function()
				FillDeleteText(StaticPopup_FindVisible(which, text))
		end)
	end
end)

-- Hide the center group-loot frame; it swallows mouse clicks
if GroupLootContainer then GroupLootContainer:Hide() end

-- Always show the alternate power bar value
ns.hook("UnitPowerBarAlt_SetUp", function(self)
	if not self.statusFrame then return end
	local statusFrame = self.statusFrame
	if statusFrame.enabled then
		statusFrame:Show()
		statusFrame.Hide = statusFrame.Show
	end
end)

--[Grid overlay alignment helper]
SLASH_EA1 = "/ab"

local f

SlashCmdList["EA"] = function()
	if f then
		f:Hide()
		f = nil
	else
		f = CreateFrame('Frame', nil, UIParent)
		f:SetAllPoints(UIParent)
		local w = GetScreenWidth() / 64
		local h = GetScreenHeight() / 36
		for i = 0, 64 do
			local t = f:CreateTexture(nil, 'BACKGROUND')
			if i == 32 then
				t:SetColorTexture(1, 0, 0, 0.5)
			else
				t:SetColorTexture(0, 0, 0, 0.5)
			end
			t:SetPoint('TOPLEFT', f, 'TOPLEFT', i * w - 1, 0)
			t:SetPoint('BOTTOMRIGHT', f, 'BOTTOMLEFT', i * w + 1, 0)
		end
		for i = 0, 36 do
			local t = f:CreateTexture(nil, 'BACKGROUND')
			if i == 18 then
				t:SetColorTexture(1, 0, 0, 0.5)
			else
				t:SetColorTexture(0, 0, 0, 0.5)
			end
			t:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -i * h + 1)
			t:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT', 0, -i * h - 1)
		end
	end
end

-- Pre-create error text: http://bbs.ngacn.cc/read.php?&tid=12561149&pid=245895632&to=1
if GetLocale() == "zhCN" then
StaticPopupDialogs["LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS"] = {
text = "Your group is full for this activity and will be removed from the listing.",
button1 = OKAY,
timeout = 0,
whileDead = 1,
preferredIndex = 3
}
end
-- Community UI error -- provided by eke
GuildControlUIRankSettingsFrameRosterLabel = CreateFrame("Frame")
GuildControlUIRankSettingsFrameRosterLabel:Hide()
ns.tips("Hide the built-in talking-head NPC dialog")
-- TalkingHeadUI ships with Blizzard_FrameXML and is always loaded, so just drop its events
if TalkingHeadFrame then
	TalkingHeadFrame:UnregisterAllEvents()
end


ns.tips("Auto repair (guild repair preferred)")
local sessionGuildRepair = 0                                  -- guild repair already used this session
ns.event("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloading)
	if isInitialLogin or isReloading then
		sessionGuildRepair = 0
	end
	if IsInGuild() then
		QueryGuildBankTab(1)
		local cost = GetRepairAllCost()                      -- total repair cost
		local gbwm = GetGuildBankWithdrawMoney()             -- guild bank daily withdrawal cap
		local gbk = GetGuildBankMoney()                      -- guild bank total gold
		local canGuildRepair = CanGuildBankRepair()          -- whether guild repair is permitted
	end
end)
ns.event("MERCHANT_SHOW", function()
	if CanMerchantRepair() then
		local cost = GetRepairAllCost()                      -- total repair cost
		local gbwm = GetGuildBankWithdrawMoney()             -- guild bank daily cap (fixed, does not decrease)
		local gbk = GetGuildBankMoney()                      -- guild bank total gold
		local canGuildRepair = CanGuildBankRepair()          -- whether guild repair is permitted
		local money = GetMoney()                             -- player's current gold
		if cost > 0 then
			-- Prefer guild repair
			if IsInGuild() and canGuildRepair then
				QueryGuildBankTab(1)                         -- make sure guild bank data is current
				local dailyRemaining = math.max(0, gbwm - sessionGuildRepair)
				-- gbk may be 0 (data not loaded on first login); ignore the bank balance then, honor only the daily cap
				local guildMoney = gbk > 0 and math.min(dailyRemaining, gbk) or dailyRemaining
				if guildMoney >= cost then
					RepairAllItems(true)
					PlaySound("7994")
					sessionGuildRepair = sessionGuildRepair + cost
					print("|cff00FFFFRepaired using guild funds: |r"..C_CurrencyInfo.GetCoinTextureString(cost))
					local newGbk = GetGuildBankMoney()
					local newDailyRemaining = math.max(0, gbwm - sessionGuildRepair)
					local remaining = newGbk > 0 and math.min(newGbk, newDailyRemaining) or newDailyRemaining
					print("Guild repair remaining: ".. C_CurrencyInfo.GetCoinTextureString(remaining))
					return
				end
			end
			-- Guild repair unavailable: pay for it yourself
			if money > cost then
				PlaySound("7994")
				RepairAllItems()
				local reason
				if not IsInGuild() then
					reason = "not in a guild"
				elseif not canGuildRepair then
					reason = "no permission"
				elseif gbk > 0 and gbk < cost then
					reason = "insufficient guild bank funds"
				else
					reason = "guild daily repair allowance exhausted"
				end
				print("|cffFF9900Guild repair not used: |r"..reason)
				print("|cffFF0000Paid out of pocket: |r"..C_CurrencyInfo.GetCoinTextureString(cost))
			else
				print("|cff99CCFF".."Not enough gold to repair.".."|r")
			end
		end
	end
end)
