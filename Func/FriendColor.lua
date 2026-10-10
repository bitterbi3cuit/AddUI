local _,_,_,mygame = GetBuildInfo()
local _,ns = ...
if SocialUIFrame then
	ns.tips("Re-layout the friends list card")
	ns.hook(FriendsListSocialCardMixin, "Initialize", function(self, node)
		self:SetHeight(35)

		-- Re-arrange the text: line 1 = FriendName + Name, line 2 = Level Class Location
		self.FriendName:SetPoint("TOPLEFT", self.TextHolder, "TOPLEFT", 5, 8)
		self.Name:ClearAllPoints()
		self.Name:SetPoint("BOTTOMLEFT", self.FriendName, "BOTTOMRIGHT", 4, 0)
		self.Name:SetPoint("BOTTOM", self.FriendName)
		self.Name:SetWidth(0)
		self.Name:SetFontObject(self.FriendName:GetFontObject())
		self.StateDisplay:ClearAllPoints()
		self.StateDisplay:SetPoint("BOTTOMLEFT", self.Name, "BOTTOMRIGHT", -2, -1)

		self.Level:Hide()
		self.Class:Hide()

		self.Location:ClearAllPoints()
		self.Location:SetPoint("TOPLEFT", self.FriendName, "BOTTOMLEFT", 0, -2)

		-- Level, Class and realm all use the Location color (FRIENDS_GRAY_COLOR)
		local gameAccountInfo = self.elementData and self.elementData.accountInfo and self.elementData.accountInfo.gameAccountInfo
		if gameAccountInfo then
			local parts = {}
			if gameAccountInfo.areaName then tinsert(parts, gameAccountInfo.areaName) end
			if gameAccountInfo.realmDisplayName then tinsert(parts, gameAccountInfo.realmDisplayName) end
			if gameAccountInfo.characterLevel then tinsert(parts, gameAccountInfo.characterLevel) end
			if #parts > 0 then
				self.Location:SetText(FRIENDS_GRAY_COLOR:WrapTextInColorCode(table.concat(parts, " ")))
			end
		end

		-- Change Name to the class color
		if gameAccountInfo and gameAccountInfo.characterName and gameAccountInfo.classFilename and gameAccountInfo.classFilename ~= "" then
			local color = GetClassColorObj(gameAccountInfo.classFilename)
			if color then
				self.Name:SetText(color:WrapTextInColorCode(gameAccountInfo.characterName))
			end
		end
	end)

	-- Turn green when an invite is possible, otherwise restore the default
	ns.hook(FriendsListSocialCardPartyButtonMixin, "RefreshIcon", function(btn)
		if btn:IsEnabled() and not btn.isInGroup then
			btn.ActionIcon:SetVertexColor(0,1,0)
		else
			btn.ActionIcon:SetVertexColor(1,1,1)
		end
	end)

	-- Halve the card spacing; works together with SetHeight(35) for the compact layout
	local view = SocialUIFrame and SocialUIFrame.FriendsList
	if view and view.GetTemplateExtent then
		local orig = view.GetTemplateExtent
		view.GetTemplateExtent = function(self, template)
			local extent = orig(self, template)
			if template == "FriendsListSocialCardTemplate" then
				return extent / 2
			end
			return extent
		end
	end

	ns.tips("Hide the friends list Battle.net ID; show it on click")
	local tagFrame = SocialUIFrame.BattleNetBar and SocialUIFrame.BattleNetBar.ControlsContainer and SocialUIFrame.BattleNetBar.ControlsContainer.PersonalBattleTagDisplay
	if tagFrame and tagFrame.ShowBestDisplayTextAndButton then
		local hidden = true

		local cover = CreateFrame("Button", nil, tagFrame)
		cover:SetAllPoints()
		cover:RegisterForClicks("AnyUp")
		cover:SetScript("OnClick", function()
			hidden = not hidden
			tagFrame.DisplayText:SetShown(not hidden)
			tagFrame.CopyBattleTagToClipboardButton:SetShown(not hidden)
		end)

		-- Hide initially
		tagFrame.DisplayText:Hide()
		tagFrame.CopyBattleTagToClipboardButton:Hide()

		-- Hook Blizzard's show method, and re-hide depending on the hidden state
		-- Blizzard re-shows it via RefreshElementVisibility -> ShowBestDisplayTextAndButton
		-- in events such as BN_CONNECTED / PLAYER_ENTERING_WORLD / FRAMES_LOADED
		local origShow = tagFrame.ShowBestDisplayTextAndButton
		tagFrame.ShowBestDisplayTextAndButton = function(self)
			origShow(self)
			if hidden then
				self.DisplayText:Hide()
				self.CopyBattleTagToClipboardButton:Hide()
			end
		end
	end
end

-- Can be deleted once 12.1 goes live (superseded by SocialUI)
-- Hide the friends list Battle.net ID; show it on click
local HideBattleIDclick = true
local HideBattleID = CreateFrame("Button", "HideBattleID", FriendsFrameBattlenetFrame);
HideBattleID:SetAllPoints(FriendsFrameBattlenetFrame); 
HideBattleID:RegisterForClicks("AnyUp");
HideBattleID:SetScript("OnClick", function() 
	if FriendsFrameBattlenetFrame.Tag:IsShown() then
		HideBattleIDclick = true
		FriendsFrameBattlenetFrame.Tag:Hide()
	else
		HideBattleIDclick = nil
		FriendsFrameBattlenetFrame.Tag:Show()
	end
end)
FriendsFrameBattlenetFrame.Tag:HookScript("OnShow", function(self)
	if HideBattleIDclick then
		self:Hide()
	end
end)

-- Can be deleted once 12.1 goes live (superseded by SocialUI)
ns.hook("FriendsFrame_UpdateFriendButton", function(friendbutton)
	if not FriendsListFrame or not FriendsListFrame:IsShown() then return end
	if not friendbutton.id then return end
	if friendbutton.buttonType == 3 then return end
	local info = C_BattleNet.GetFriendAccountInfo(friendbutton.id)
	if not info then return end
	local accountInfo = info.gameAccountInfo
	local areaName = accountInfo.areaName					-- area name
	local realmDisplayName = accountInfo.realmDisplayName	-- realm
	local characterName = accountInfo.characterName			-- character name
	local bnname = Ambiguate(info.battleTag,"short")		-- Battle.net name
	local level = accountInfo.characterLevel				-- level
	--local factionName = accountInfo.factionName			-- faction
	local gamename = accountInfo.wowProjectID				-- game id: 1 = retail, 11 = WotLK
	local rich = accountInfo.richPresence					-- rich presence returns game version - area - realm
	local timerunningSeasonID = accountInfo.timerunningSeasonID	-- season ID, used for Remix servers

	-- Title bar (index RAID_CLASS_COLORS directly with the class filename, no iteration needed)
	local classFilename = accountInfo.classFilename
	local class = characterName and classFilename and RAID_CLASS_COLORS[classFilename]
	if class then
		friendbutton.name:SetText(format("%s|c%s (%s)|r    ", bnname, class.colorStr, characterName))
	end

	-- Info bar (re-set on every update so Blizzard's default text doesn't overwrite it)
	local infoText
	if realmDisplayName and areaName and gamename == 1 then
		if timerunningSeasonID then	-- if on a season server
			infoText = format("|A:timerunning-glues-icon:12:12:0:0|a%s-%s-%s", areaName, realmDisplayName, level)
		else
			infoText = format("%s-%s-%s", areaName, realmDisplayName, level)
		end
	elseif areaName and gamename == 14 then
		local _,fwq = strsplit("-",rich)	-- Classic servers only need the realm name
		infoText = realmDisplayName and format("CTM-%s-%s-%s", areaName, realmDisplayName, level)
			or (fwq and format("CTM-%s-%s-%s", areaName, fwq, level) or nil)
	elseif areaName and gamename == 11 then
		local _,fwq = strsplit("-",rich)	-- Classic servers only need the realm name
		infoText = realmDisplayName and format("WLK-%s-%s-%s", areaName, realmDisplayName, level)
			or (fwq and format("WLK-%s-%s-%s", areaName, fwq, level) or nil)
	elseif areaName and gamename == 2 then
		local _,fwq = strsplit("-",rich)	-- Classic servers only need the realm name
		infoText = realmDisplayName and format("(Classic 60)-%s-%s-%s", areaName, realmDisplayName, level)
			or (fwq and format("(Classic 60)-%s-%s-%s", areaName, fwq, level) or nil)
	end
	if infoText then
		friendbutton.info:SetText(infoText)
	end
	-- Compare game versions
	if mygame > 90000 then
		if not gamename or gamename == 1 then
			friendbutton.name:SetAlpha(1)
			friendbutton.info:SetAlpha(1)
		else
			friendbutton.name:SetAlpha(.4)
			friendbutton.info:SetAlpha(.4)
		end
	end
end)
