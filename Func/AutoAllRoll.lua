local _,ns = ...

-- 0 pass, 1 need, 2 greed, 3 disenchant, 4 transmog
-- Create the main frame
local RollItems = {}
local rollFrame = CreateFrame("Frame", "AllRollFrame", UIParent, "BasicFrameTemplate")
rollFrame:SetSize(200, 75)
rollFrame:SetPoint("CENTER",0,50)
rollFrame:SetFrameStrata("FULLSCREEN_DIALOG")
rollFrame:SetMovable(true)
rollFrame:EnableMouse(true)
rollFrame:SetClampedToScreen(true)
rollFrame.title = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rollFrame.title:SetPoint("CENTER", rollFrame.TitleBg, "CENTER", 0, 0)
rollFrame.title:SetText("One-Click Roll Selector")
rollFrame:Hide()
-- Clear stale roll IDs whenever the panel is dismissed by any means
rollFrame:SetScript("OnHide", function()
	RollItems = {}
end)

-- Register events
ns.event("START_LOOT_ROLL", function(event,arg1, arg2)
	if not AddUIDB.autoloot then return end
	for _, id in ipairs(RollItems) do
		if id == arg1 then return end          -- ignore duplicate announcements
	end
	table.insert(RollItems, arg1)
	rollFrame:Show()
end)

-- Bind-confirm: without this the confirm popup still needs a manual click
ns.event("CONFIRM_LOOT_ROLL", function(event, rollID, rollType)
	ConfirmLootRoll(rollID, rollType)
	if StaticPopup1Button1 then StaticPopup1Button1:Click() end
end)

-- Disenchant-confirm
ns.event("CONFIRM_DISENCHANT_ROLL", function(event, rollID, rollType)
	ConfirmDisenchantRoll(rollID, rollType)
	if StaticPopup1Button1 then StaticPopup1Button1:Click() end
end)

-- Need button
local needIcon = rollFrame:CreateTexture(nil, "ARTWORK")
needIcon:SetSize(40, 40)
needIcon:SetPoint("LEFT", rollFrame, "LEFT", 15, -12)
needIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
local needIconbutton = CreateFrame("Button", nil,rollFrame)
needIconbutton:SetAllPoints(needIcon)
needIconbutton:RegisterForClicks("AnyUp");
needIconbutton:SetScript("OnClick", function()
	for _, value in ipairs(RollItems) do
		RollOnLoot(value,1)                    -- Need only
	end
	rollFrame:Hide()
	RollItems = {}
end)
needIconbutton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cff00FF00"..ALL..NEED.."|r",1,1,1,1)
	GameTooltip:Show()
end)
needIconbutton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
-- Greed button
local greedIcon = rollFrame:CreateTexture(nil, "ARTWORK")
greedIcon:SetSize(40, 40)
greedIcon:SetPoint("CENTER", rollFrame, "CENTER", 0, -15)
greedIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
local greedIconbutton = CreateFrame("Button", nil,rollFrame)
greedIconbutton:SetAllPoints(greedIcon)
greedIconbutton:RegisterForClicks("AnyUp");
greedIconbutton:SetScript("OnClick", function()
    for _, value in ipairs(RollItems) do
		RollOnLoot(value,2)                    -- Greed only
	end
	rollFrame:Hide()
	RollItems = {}
end)
greedIconbutton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cff00FFFF"..ALL..GREED.."|r",1,1,1,1)
	GameTooltip:Show()
end)
greedIconbutton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
-- Pass button
local passIcon = rollFrame:CreateTexture(nil, "ARTWORK")
passIcon:SetSize(35, 35)
passIcon:SetPoint("RIGHT", rollFrame, "RIGHT", -15, -9)
passIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
local passIconbutton = CreateFrame("Button", nil,rollFrame)
passIconbutton:SetAllPoints(passIcon)
passIconbutton:RegisterForClicks("AnyUp");
passIconbutton:SetScript("OnClick", function()
    for _, value in ipairs(RollItems) do
		RollOnLoot(value,0)                    -- Pass only
	end
	rollFrame:Hide()
	RollItems = {}
end)
passIconbutton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cffFFFFFF"..ALL..PASS.."|r",1,1,1,1)
	GameTooltip:Show()
end)
passIconbutton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
