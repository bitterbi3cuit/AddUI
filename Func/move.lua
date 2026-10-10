local _, ns = ...
ns.event("PLAYER_LOGIN", function()
	ns.tips("Allows some Blizzard frames to be moved")
	-- Hold Alt to move -- if (IsAltKeyDown()) then

	-- Initial bag position
	hooksecurefunc("UpdateContainerFrameAnchors", function()
		ContainerFrameCombinedBags:ClearAllPoints()
		ContainerFrameCombinedBags:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
	end)


	local function MakeMovable(frame)
		if not frame then return end
		frame:SetMovable(true)
		frame:HookScript("OnMouseDown", function() frame:StartMoving() end)
		frame:HookScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
	end

	local function SetMove(arg1, arg2)
		if arg2 then
			-- defer until the Blizzard addon that owns this frame has loaded
			EventUtil.ContinueOnAddOnLoaded(arg2, function() MakeMovable(_G[arg1]) end)
		else
			MakeMovable(_G[arg1])
		end
	end

	SetMove("CharacterFrame")               -- Character
	SetMove("FriendsFrame")                 -- Friends
	SetMove("SocialUIFrame")                -- Social (new 12.1 friends frame)
	SetMove("PVEFrame")                     -- Dungeon & PvP
	SetMove("ContainerFrameCombinedBags")   -- Bags
	SetMove("WorldMapFrame")                -- World map
	SetMove("GameMenuFrame")                -- Game menu
	SetMove("SettingsPanel")                -- Esc-menu settings panel
	SetMove("MerchantFrame")                -- Vendor
	SetMove("MailFrame")                    -- Mailbox
	SetMove("BankFrame")                    -- Bank
	SetMove("GuildBankFrame")               -- Guild bank
	SetMove("SpellBookFrame")               -- Spellbook
	SetMove("TabardFrame")                  -- Tabard
	SetMove("QuestFrame")                   -- Quest
	SetMove("ItemUpgradeFrame")             -- Item upgrade
	SetMove("CooldownViewerSettings")       -- Cooldown manager settings panel

	SetMove("MacroFrame", "Blizzard_MacroUI")                                -- Macros
	SetMove("ProfessionsFrame", "Blizzard_Professions")                      -- Crafting
	SetMove("CommunitiesFrame", "Blizzard_Communities")                      -- Guild
	SetMove("ClassTalentFrame", "Blizzard_ClassTalentUI")                    -- Talents
	SetMove("AuctionHouseFrame", "Blizzard_AuctionHouseUI")                  -- Auction house
	SetMove("ChallengesKeystoneFrame", "Blizzard_ChallengesUI")              -- Mythic+
	SetMove("PlayerSpellsFrame", "Blizzard_PlayerSpells")                    -- Spellbook (new)
	SetMove("ProfessionsCustomerOrdersFrame", "Blizzard_ProfessionsCustomerOrders") -- Crafting orders
	SetMove("ProfessionsBookFrame", "Blizzard_ProfessionsBook")              -- Profession book (K)
	SetMove("AchievementFrame", "Blizzard_AchievementUI")                    -- Achievements
	SetMove("CollectionsJournal", "Blizzard_Collections")                    -- Collections (mounts/pets)
	SetMove("EncounterJournal", "Blizzard_EncounterJournal")                 -- Adventure Guide
	SetMove("HousingDashboardFrame", "Blizzard_HousingDashboard")            -- Housing dashboard

	-- Pin the "listen" dialogue widget (component below the minimap) to the top
	-- centre of the screen; re-pin if the layout pass moves it back
	hooksecurefunc("ManageFramePositions", function()
		local f = UIWidgetBelowMinimapContainerFrame
		if f then f:ClearAllPoints(); f:SetPoint("TOP", UIParent, "TOP", 0, -5) end
	end)

	-- Add an "Open Crafting Orders" button to the K-key profession page
	EventUtil.ContinueOnAddOnLoaded("Blizzard_ProfessionsBook", function()
		if bookOpenPro then return end
		local bookOpenPro = CreateFrame("Button", "bookOpenPro", ProfessionsBookFrame.TitleContainer, "UIPanelButtonTemplate")
		bookOpenPro:SetSize(120, 22)
		bookOpenPro:SetText("Open Crafting Orders")
		bookOpenPro:SetPoint("LEFT", ProfessionsBookFrame.TitleContainer, "LEFT", 30, 0)
		bookOpenPro:SetScript("OnClick", function()
			if not ProfessionsCustomerOrdersFrame then
				C_AddOns.LoadAddOn("Blizzard_ProfessionsCustomerOrders")

				ProfessionsCustomerOrdersFrame:HookScript("OnKeyDown", function(self, key)
					if key == "ESCAPE" then
						ProfessionsCustomerOrdersFrame:Hide()
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(false)
					else
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(true)
					end
				end)
			end
			if ProfessionsCustomerOrdersFrame:IsShown() then
				ProfessionsCustomerOrdersFrame:Hide()
			else
				ProfessionsCustomerOrdersFrame:Show()
				ProfessionsCustomerOrdersFrame:ClearAllPoints()
				ProfessionsCustomerOrdersFrame:SetPoint("LEFT", UIParent, "CENTER", -35, 130)
			end
		end)
	end)

	-- Add an "Open Crafting Orders" button to the auction house page
	EventUtil.ContinueOnAddOnLoaded("Blizzard_AuctionHouseUI", function()
		if AuctionOpenPro then return end
		local AuctionOpenPro = CreateFrame("Button", "AuctionOpenPro", AuctionHouseFrame.TitleContainer, "UIPanelButtonTemplate")
		AuctionOpenPro:SetSize(120, 22)
		AuctionOpenPro:SetText("Open Crafting Orders")
		AuctionOpenPro:SetPoint("LEFT", AuctionHouseFrame.TitleContainer, "LEFT", 0, 0)
		AuctionOpenPro:SetScript("OnClick", function()
			if not ProfessionsCustomerOrdersFrame then
				C_AddOns.LoadAddOn("Blizzard_ProfessionsCustomerOrders")
				ProfessionsCustomerOrdersFrame:HookScript("OnKeyDown", function(self, key)
					if key == "ESCAPE" then
						ProfessionsCustomerOrdersFrame:Hide()
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(false)
					else
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(true)
					end
				end)
			end
			if ProfessionsCustomerOrdersFrame:IsShown() then
				ProfessionsCustomerOrdersFrame:Hide()
			else
				ProfessionsCustomerOrdersFrame:Show()
				ProfessionsCustomerOrdersFrame:ClearAllPoints()
				ProfessionsCustomerOrdersFrame:SetPoint("LEFT", UIParent, "CENTER", -35, 130)
			end
		end)
	end)

	ns.tips("Macro window resize")
	EventUtil.ContinueOnAddOnLoaded("Blizzard_MacroUI", function()
		-- Original 338 x 424 -> 440 x 561 (width +102, height +137)
		MacroFrame:SetWidth(338+102);
		MacroFrame:SetHeight(424+47+90);              -- grid +47 (4 rows), edit area +90

		-- Macro button grid: original 319 x 146, width +102, height +47, 6 -> 8 per row
		-- 4 rows tall = 5 + 4*36 + 3*13 + 5 = 193
		MacroFrame.MacroSelector:SetWidth(319+102);
		MacroFrame.MacroSelector:SetHeight(146+47);
		MacroFrame.MacroSelector:SetCustomStride(8);

		-- Everything below the grid shifts down by 47
		MacroHorizontalBarLeft:SetWidth(256+102);              -- divider (right end-piece follows)
		MacroHorizontalBarLeft:ClearAllPoints();
		MacroHorizontalBarLeft:SetPoint("TOPLEFT", 2, -210-47);
		MacroFrameSelectedMacroBackground:ClearAllPoints();    -- selected-macro icon frame
		MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", 5, -218-47);
		MacroFrameSelectedMacroName:SetWidth(256+102);         -- selected-macro name

		-- Edit area: originally 95 / 85, each +90 tall, shifted down 47
		MacroFrameTextBackground:SetWidth(322+102);
		MacroFrameTextBackground:SetHeight(95+90);
		MacroFrameTextBackground:ClearAllPoints();
		MacroFrameTextBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 6, -289-47);
		MacroFrameScrollFrame:SetWidth(286+102);               -- macro text scroll frame
		MacroFrameScrollFrame:SetHeight(85+90);
		MacroFrameText:SetWidth(286+102);                      -- macro text edit box
		MacroFrameText:SetHeight(85+90);
		MacroFrameTextButton:SetWidth(286+102);                -- macro text click layer
		MacroFrameTextButton:SetHeight(85+90);
	end)

end)
