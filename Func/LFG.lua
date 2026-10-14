local _,ns = ...
ns.event("PLAYER_ENTERING_WORLD", function()
    if not AddUIDB.lfgkg then return end
    if C_AddOns.IsAddOnLoaded("MeetingStone") then return end
    --Configure PGF (Premade Groups Filter)
    if C_AddOns.IsAddOnLoaded("PremadeGroupsFilter") then
	if UsePGFButtonText then 
		UsePGFButton:ClearAllPoints()
		UsePGFButton:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "LEFT", -62, 0)
		UsePGFButton:SetPoint("TOP", LFGListFrame.SearchPanel.RefreshButton, "TOP", 0, -3)
	end
	if PremadeGroupsFilterSettings then
		PremadeGroupsFilterSettings.ratingInfo = false	--Leader rating
		PremadeGroupsFilterSettings.classBar = false	--Class color bar
		PremadeGroupsFilterSettings.leaderCrown = false	--Show leader crown
		PremadeGroupsFilterSettings.oneClickSignUp = false	--Click to apply
	end
	--Patch 12.1: Blizzard changed the refresh button and search box sizes; restore the previous layout
	if LFGListFrame.SearchPanel.RefreshButton then
		LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints()
		LFGListFrame.SearchPanel.RefreshButton:SetPoint("LEFT", LFGListFrame.SearchPanel.CategoryName, "RIGHT", 15, 1)
		LFGListFrame.SearchPanel.SearchBox:ClearAllPoints()
		LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.CategoryName, "BOTTOMLEFT", 4, -7)
		LFGListFrame.SearchPanel.SearchBox:SetPoint("RIGHT", LFGListFrame.SearchPanel.FilterButton, "LEFT", -2, 0)
	end
end

--[[Fix the GetPlaystyleString error in Premade Groups Filter
https://github.com/0xbs/premade-groups-filter/issues/64
function LFMPlus_GetPlaystyleString(playstyle,activityInfo)
  if activityInfo and playstyle ~= (0 or nil) and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown then
    local typeStr
    if activityInfo.isMythicPlusActivity then
      typeStr = "GROUP_FINDER_PVE_PLAYSTYLE"
    elseif activityInfo.isRatedPvpActivity then
      typeStr = "GROUP_FINDER_PVP_PLAYSTYLE"
    elseif activityInfo.isCurrentRaidActivity then
      typeStr = "GROUP_FINDER_PVE_RAID_PLAYSTYLE"
    elseif activityInfo.isMythicActivity then
      typeStr = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"
    end
    return typeStr and _G[typeStr .. tostring(playstyle)] or nil
  else
    return nil
  end
end

C_LFGList.GetPlaystyleString = function(playstyle,activityInfo)
  return LFMPlus_GetPlaystyleString(playstyle, activityInfo)
end]]
--Double-click to apply
local function HookApplicationClick()
	if LFGListFrame.SearchPanel.SignUpButton:IsEnabled() then
		LFGListFrame.SearchPanel.SignUpButton:Click()
	end
	if (not IsAltKeyDown()) and LFGListApplicationDialog:IsShown() and LFGListApplicationDialog.SignUpButton:IsEnabled() then
		LFGListApplicationDialog.SignUpButton:Click()
	end
end
ns.hook("LFGListSearchEntry_OnLoad", function(self)
	self:HookScript("OnDoubleClick", HookApplicationClick)
	LFGListFrame.SearchPanel.FilterButton.ResetButton:SetPoint("TOPLEFT",LFGListFrame.SearchPanel.FilterButton,"BOTTOMRIGHT",-20,2)
end)

--Score shown on the search page
ns.hook("LFGListSearchEntry_Update", function(self)
	if not PVEFrame:IsShown() then return end
    local resultID = self.resultID
	if not resultID or not C_LFGList.HasSearchResultInfo(resultID) then
		return;
	end
	
    local resultInfo = C_LFGList.GetSearchResultInfo(resultID)
    local leaderName = resultInfo.leaderName
	self.ActivityName:SetScale(.9)
	self.ActivityName:SetWidth(200)
    self.leaderMPlusRating = resultInfo.leaderOverallDungeonScore
	if not self.leaderMPlusRating then return end
	local scoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(self.leaderMPlusRating) or HIGHLIGHT_FONT_COLOR
	if not self.score then--Score
		self.score = self:CreateFontString(nil, "ARTWORK")
		self.score:SetFont(STANDARD_TEXT_FONT, 15, 'OUTLINE')
	end
	if self.score then
		self.score:SetText(self.leaderMPlusRating)
		if resultInfo.isDelisted then
			self.score:SetTextColor(0.5,0.5,0.5)
		else
			self.score:SetTextColor(scoreColor.r, scoreColor.g, scoreColor.b)
		end
	end

	if self.Playstyle then
		self.Playstyle:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		if resultInfo.isDelisted then
			self.Playstyle:SetTextColor(0.3,0.3,0.3)
		else
		self.Playstyle:SetTextColor(0,1,0)
		end
	end
	if not self.infotext then--Comment
		self.infotext = self:CreateFontString(nil, "ARTWORK")
		self.infotext:SetFont(STANDARD_TEXT_FONT, 13, 'OUTLINE')
		self.infotext:SetPoint("BOTTOMLEFT", self.Playstyle, "BOTTOMRIGHT", 0, 3)
	end
	if self.infotext then
		self.infotext:SetText(resultInfo.comment)
		if resultInfo.isDelisted then
			self.infotext:SetTextColor(0.3,0.3,0.3)
		else
			self.infotext:SetTextColor(0.9,0.9,0.9)
		end
	end
	if not self.Name then return end
	if (LFGListFrame.CategorySelection.selectedCategory == 2) then
		self.score:SetPoint("LEFT", self, "CENTER", 15, 0)
		self.score:Show() 
	elseif (LFGListFrame.CategorySelection.selectedCategory == 3) then
		self.score:SetPoint("LEFT", self, "CENTER", 0, 0)
		self.score:Show() 
	elseif (LFGListFrame.CategorySelection.selectedCategory == 6) then
		self.score:SetPoint("LEFT", self, "CENTER", 0, 0)
		self.score:Show() 
	else
		self.score:Hide()
    end
end)

-- Preserve search contents (LFGList.lua)
function LFGListSearchPanel_Clear(self)
    -- C_LFGList.ClearSearchResults();    -- intentionally skipped: preserve results
    -- C_LFGList.ClearSearchTextFields(); -- intentionally skipped: preserve search text
    self.selectedResult = nil;
    -- Guard: GetSearchResults() returns nil before the first search, which causes
    -- LFGListSearchPanel_UpdateResults to pass nil to pairs() → LUA_WARNING spam.
    if C_LFGList.GetSearchResults() ~= nil then
        LFGListSearchPanel_UpdateResultList(self);
    end
end

--Preserve the application note (LFGList.lua)
function LFGListApplicationDialog_Show(self, resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	--if ( searchResultInfo.activityID ~= self.activityID ) then
		--C_LFGList.ClearApplicationTextFields();
	--end

	self.resultID = resultID;
	self.activityID = searchResultInfo.activityID;
	LFGListApplicationDialog_UpdateRoles(self);
	StaticPopupSpecial_Show(self);
end
--Applicant list
ns.hook("LFGListApplicationViewer_UpdateApplicantMember", function(self, appID, memberIdx, status, pendingStatus)
	self:SetHeight(13)
	local info = C_LFGList.GetApplicantInfo(appID)
	
	if not self.infotext then--Comment
		self.infotext = self:CreateFontString(nil, "ARTWORK")
		self.infotext:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
		self.infotext:SetTextColor(0.9,0.9,0.9)
		self.infotext:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 5, 0)
	end
	if self.infotext then
		self.infotext:SetText(info.comment)
		if info.applicationStatus ~= "applied" and info.applicationStatus ~= "invited" and info.applicationStatus ~= "inviteaccepted" then
			self.infotext:SetTextColor(0.3,0.3,0.3)
		end
	end
end)

--Show the "Browse Groups" button even when not the leader
ns.hook("LFGListApplicationViewer_UpdateInfo", function(self)
	LFGListFrame.ApplicationViewer.BrowseGroupsButton:Show()
end)
--Change the Browse Groups button into a return-to-main-menu button
LFGListFrame.ApplicationViewer.BrowseGroupsButton:SetScript("OnClick", function()
	LFGListFrame_SetActivePanel(LFGListFrame,LFGListFrame.CategorySelection)
end)


--非队长/助理时，暴雪用 UnempoweredCover（enableMouse、frameLevel 15）盖住申请列表，右键全被它吃掉
--empowered = 队长 或 助理（LFGListUtil_IsEntryEmpowered，LFGList.lua:4216；SetShown 见 :1837）
--整个隐藏该遮罩（不再显示「你的队伍正在组建中。」）→ 右键穿透到申请者条目
--（密语 + 复制角色名/WCL/Raider.IO，菜单见 Func/WCL.lua）
ns.hook("LFGListApplicationViewer_UpdateAvailability", function(self)
	if self.UnempoweredCover then self.UnempoweredCover:Hide() end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
f:SetScript("OnEvent", function(self, event, resultid, status, prevstatus, title)
	if not resultid or status ~= "inviteaccepted" then return end
	local info = C_LFGList.GetSearchResultInfo(resultid)
	if not info or not info.activityIDs or #info.activityIDs == 0 then return end
	local activityID = info.activityIDs[1]
	local name = C_LFGList.GetActivityFullName(activityID) or "Unknown activity"
	local msg = "Joined: " .. name .. " " .. (title or "")
	print("|cffb044a2ADDUI|r " .. msg.." "..info.leaderName)
	ns.AATEXT(msg)
end)

end)
