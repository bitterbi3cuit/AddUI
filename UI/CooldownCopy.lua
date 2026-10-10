local _,ns = ...

ns.event("PLAYER_ENTERING_WORLD", function()
	AddUIDB.CooldownDate = AddUIDB.CooldownDate or {}
	-------------------------------
	CooldownViewerSettings:HookScript("OnShow", function(self)
		self.LayoutDropdown:SetWidth(150)
	end)
	ns.hook(CooldownViewerSettings, "SetupLayoutManagerDropdown", function(self)
		self.LayoutDropdown:SetWidth(150)
	end)
	-------------------------------
	local CLM = CooldownViewerSettings:GetLayoutManager() --main layout manager
	-------------------------------
	local function UseDate(string)
		local ClassName = UnitClass("player")
		if string.match(string,ClassName) then--The layout name must contain the class name
			local CreatOK,CreatRet = pcall(function() 
				return CLM:CreateLayoutsFromSerializedData(AddUIDB.CooldownDate[string])--Create the layout
			end)
			if CreatOK then
				local strID = CreatRet and CreatRet[1]
				local tag = CLM:GetLayout(strID)--Get the layout object
				local CanRet = CLM:CanActivateLayout(tag) --Check whether the layout can be applied
				--local ClassAndSpecTag = CooldownManagerLayout_GetClassAndSpecTag(tag)--Get the class and specialization tag
				--local loyoutName = CooldownViewerUtil.GetClassAndSpecTagText(ClassAndSpecTag)--Get the class and specialization tag文本
				local UsedText = CanRet and "Applied" or "Cannot be applied to the current specialization"
				CooldownManagerLayout_SetName(tag, string)
				if CanRet then
					securecall(function()
						CooldownViewerSettings:SetActiveLayoutByID(strID)
					end)
				end
				print("|cff00ff00Imported:  |cff00ffff"..UsedText.."|r "..string.."|r")
			else
				print("|cffff0000Failed to load Cooldown Manager: |r"..CreatRet)
			end
		else
			print("|cffff0000Load failed: the string does not belong to this class: "..string.."|r")
		end
	end
	-------------------------------
	local function DeleteAll()
		CLM:ResetToDefaults()
		print("|cffff0000Cooldown Manager has been reset to the default configuration|r")
	end
	-------------------------------
	local function AddDate()
		local UsetdID = CLM:GetActiveLayoutID()
		if not UsetdID then 
			print("|cffff0000The starter layout cannot be saved. Switch to another layout first.|r")
			return  --Exclude the starter layout
		end
		local StrOK,StrRet = pcall(function() --Serialize the layout
			return CooldownViewerSettings:GetLayoutManager():GetSerializer():SerializeLayouts(UsetdID)
		end)
		if StrOK and StrRet then
			local CalendarTime = C_DateAndTime.GetCurrentCalendarTime() --Get the current date
			local nowTime = CalendarTime.year.."."..CalendarTime.month.."."..CalendarTime.monthDay--.."-"..CalendarTime.hour..":"..CalendarTime.minute
			local _,SpecName = C_SpecializationInfo.GetSpecializationInfo(GetSpecialization()) --Get the current specialization
			local dateName = SpecName.. " " .. nowTime .." "..UnitClass("player").." " ..UnitName("player")  --Combine into a save name
			if AddUIDB.CooldownDate[dateName] then
				print("|cffff0000Already exists|cff00ffffa saved layout with the same name|r:  "..dateName.."|r")
			else
				AddUIDB.CooldownDate[dateName] = StrRet
				print("|cff00ff00Saved:  "..dateName.."|r")
			end
		else
			print("|cffff0000Failed to save Cooldown Manager layout: could not get the current layout string|r"..StrRet)
		end
	end
	-------------------------------
	if not CooldownViewerSettings.MyDateDropdown then
		CooldownViewerSettings.MyDateDropdown = CreateFrame("DropdownButton", nil, CooldownViewerSettings, "WowStyle1DropdownTemplate")
		CooldownViewerSettings.MyDateDropdown:SetPoint("BOTTOMRIGHT",CooldownViewerSettings.NineSlice.BottomEdge,"BOTTOMRIGHT" ,-60, 4)
		CooldownViewerSettings.MyDateDropdown:SetWidth(80)
		CooldownViewerSettings.MyDateDropdown.Text1 = CooldownViewerSettings.MyDateDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		CooldownViewerSettings.MyDateDropdown.Text1:SetText("Layouts")
		CooldownViewerSettings.MyDateDropdown.Text1:SetVertexColor(1,1,1,1)
		CooldownViewerSettings.MyDateDropdown.Text1:SetPoint("CENTER", CooldownViewerSettings.MyDateDropdown, "CENTER", -8, 0)
		CooldownViewerSettings.MyDateDropdown.Text1:Show()
		local function IsSelected()
		end
		local function SetSelected(value)--Return the selected string
			UseDate(value)
		end
		CooldownViewerSettings.MyDateDropdown:SetupMenu(function(dropdown, rootDescription)
			for layoutID, layoutInfo in pairs(AddUIDB.CooldownDate) do
				local ClassName = UnitClass("player")
				local text = layoutID
				if not string.match(layoutID,ClassName) then
					text = "|cff808080"..layoutID.."|r"
				end
				local layoutButton = rootDescription:CreateRadio(text, IsSelected, SetSelected, layoutID)
				layoutButton:DeactivateSubmenu();
				layoutButton:AddInitializer(function(button, description, menu)
					local deleteLayoutButton = MenuTemplates.AttachAutoHideCancelButton(button);
					MenuTemplates.SetUtilityButtonLockedEnabledState(deleteLayoutButton, true);
					MenuTemplates.SetUtilityButtonTooltipText(deleteLayoutButton, COOLDOWN_VIEWER_SETTINGS_DELETE_LAYOUT);
					MenuTemplates.SetUtilityButtonAnchor(deleteLayoutButton, MenuVariants.CancelButtonAnchor, true);
					MenuTemplates.SetUtilityButtonClickHandler(deleteLayoutButton, function()
						AddUIDB.CooldownDate[layoutID] = nil  -- Delete by key
						dropdown:GenerateMenu()	--Refresh the menu
						print("|cffff0000Deleted: " .. layoutID)
					end);
				end);
			end
		end)
	end
	-------------------------------
	if not CooldownViewerSettings.SetDateButton then
		CooldownViewerSettings.SetDateButton = CreateFrame("Button", nil, CooldownViewerSettings,"UIPanelButtonTemplate")
		CooldownViewerSettings.SetDateButton:SetWidth(60)
		CooldownViewerSettings.SetDateButton:SetPoint("BOTTOM", -8, 4)
		CooldownViewerSettings.SetDateButton:Show()
		CooldownViewerSettings.SetDateButton.Text = CooldownViewerSettings.SetDateButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		CooldownViewerSettings.SetDateButton.Text:SetPoint("CENTER", CooldownViewerSettings.SetDateButton, "CENTER", 0, 0)
		CooldownViewerSettings.SetDateButton.Text:SetText("Save")
		CooldownViewerSettings.SetDateButton:SetScript("OnClick", function()
			if IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() then
				DeleteAll()
			else
				AddDate()
			end
		end)
		CooldownViewerSettings.SetDateButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText("|cff00ff00Click to save to the local layouts on the right|r\n|cffff0000Ctrl+Shift+Alt-click to delete|cff00ffffleft|rall layouts|r",1,1,1)
			GameTooltip:Show()
		end)
		CooldownViewerSettings.SetDateButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

end)