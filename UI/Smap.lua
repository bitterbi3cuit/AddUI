local _,ns = ...
ns.event("PLAYER_ENTERING_WORLD", function()
if AddUIDB.smap ==  false  then return end

-- Hide some elements
MinimapBackdrop:Hide()	-- circular texture
MinimapCluster:SetScale(.8)	-- scale
Minimap:SetQuestBlobRingScalar(0)	-- quest tracking ring mesh
-- Fine-tune minimap position
Minimap:SetPoint("CENTER",MinimapCluster,"TOP", 15,-125)

-- Border texture
Minimap:SetMaskTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
function GetMinimapShape() return "SQUARE" end

local function CreateShadow(f)
	if f.shadow then return end
	--local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
	local shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
	shadow:SetFrameLevel(0)
	shadow:SetFrameStrata(f:GetFrameStrata())
	shadow:SetPoint("TOPLEFT", -1, 1)
	shadow:SetPoint("BOTTOMRIGHT", 1, -1)
	shadow:SetBackdrop({edgeFile = 'Interface\\Buttons\\WHITE8x8',edgeSize = 2})
	--shadow:SetBackdropBorderColor(color.r, color.g, color.b, 1)
	shadow:SetBackdropBorderColor(0, 0, 0, 1)
	f.shadow = shadow
	return shadow
end
CreateShadow(Minimap)

-- Clock
--LoadAddOn('Blizzard_TimeManager')
local clockFrame, clockTime = TimeManagerClockButton:GetRegions()
clockFrame:Show()
clockTime:Hide()
TimeManagerClockButton:ClearAllPoints()
TimeManagerClockButton:SetPoint("CENTER",Minimap,"BOTTOM",0,-2)
clockFrame:SetFont("fonts\\ARIALN.ttf", 17, "OUTLINE")


-- Addon compartment button
AddonCompartmentFrame:ClearAllPoints()
AddonCompartmentFrame:SetPoint("RIGHT",MinimapCluster.Tracking,"LEFT", -2,0)
AddonCompartmentFrame:SetFrameStrata("MEDIUM")
-- Instance difficulty frame

-- Instance challenge mode difficulty frame
local mc = MinimapCluster.InstanceDifficulty
mc:ClearAllPoints()
mc:SetPoint("TOPLEFT", MinimapCluster, 0, -25)
mc:SetScale(1)

-- Minimap expansion landing page button position and size
local function MinimapButtonE(self)
self:SetParent(Minimap)
self:ClearAllPoints()
self:SetSize(40,40)
self:SetPoint("TOPRIGHT", Minimap,"TOPRIGHT",  -5, -5)
end
MinimapButtonE(ExpansionLandingPageMinimapButton)
ExpansionLandingPageMinimapButton:HookScript("OnShow", MinimapButtonE)
ns.hook(ExpansionLandingPageMinimapButton, "UpdateIcon", MinimapButtonE)


-- NPCs that should not display a plane ID
local NoID={
--[]=true, --
[181059]=true,  -- Pocopoc: Type: Creature  NPCID: 181059
[25146]=true,   -- Pepe: Type: Creature     NPCID: 25146
[62821]=true,   -- Arcanist Featherhat: Type: Creature     NPCID: 62821
[62822]=true,   -- Cousin Slowhand: Type: Creature     NPCID: 62822
[142666]=true,  -- Collector Winta: Type: Creature     NPCID: 142666
[142668]=true,  -- Merchant Maku: Type: Creature     NPCID: 142668

}
local idframe = CreateFrame("Frame","mapid",UIParent)
idframe:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
idframe:RegisterEvent("ZONE_CHANGED_NEW_AREA")
idframe:SetFrameStrata("BACKGROUND")
local weimian = idframe:CreateFontString(nil, "ARTWORK")
weimian:SetFont("fonts\\ARIALN.ttf", 11, "OUTLINE") 
weimian:SetPoint("RIGHT",MinimapCluster.BorderTop,"RIGHT",0,1)
idframe:SetScript("OnEvent", function(self,event,aaaa)
if event == "UPDATE_MOUSEOVER_UNIT" then
	if issecretvalue(UnitGUID("mouseover")) then return end
    local guid = UnitGUID("mouseover")
	if not guid then return end
    local types, _, _, _, zoneID, unitID = strsplit("-", guid)
	local ids = tonumber(unitID)
	if types == "Pet" then return end;
	if zoneID == nil then return end;
    if NoID[ids] then return end;
	weimian:SetText("zone: "..zoneID)
elseif event == "ZONE_CHANGED_NEW_AREA" then
	weimian:SetText("")
end
		
end)

-- World map coordinate input https://bbs.nga.cn/read.php?tid=24183736&_fp=3
-- Input coordinates to mark a position
local WayPointPositionButton = CreateFrame("Button", "WayPointPositionButton", WorldMapFrame.BorderFrame.TitleContainer, "UIPanelButtonTemplate")
WayPointPositionButton:SetWidth(50)
WayPointPositionButton:SetHeight(18)
-- WayPointPositionButton.Font = WayPointPositionButton:CreateFontString(nil,nil)
-- WayPointPositionButton.Font:SetFont("Fonts\\ZYKai_T.ttf",12)
-- WayPointPositionButton:SetFontString(WayPointPositionButton.Font)
WayPointPositionButton:SetText("Locate")
WayPointPositionButton:SetPoint("LEFT", WorldMapFrame.BorderFrame.Tutorial, "RIGHT", -20, 1)
WayPointPositionButton:SetScript("OnShow", function() WayPointContainer:Close() end)

-- Set the waypoint destination
function WayPointPositionButton:SetWayPoint(desX, desY)
    local currentViewMapID = WorldMapFrame:GetMapID()
    if C_Map.CanSetUserWaypointOnMap(currentViewMapID) then
        local point = UiMapPoint.CreateFromCoordinates(currentViewMapID, desX / 100, desY / 100)
        C_Map.SetUserWaypoint(point)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true);
    else
        print("|cFFFF0000Cannot mark on the current map!|r")
    end
end

-- Locate button click handler
function WayPointPositionButton.OnClick(button, down)
    local currentViewMapID = WorldMapFrame:GetMapID()
    if not C_Map.CanSetUserWaypointOnMap(currentViewMapID) then
        print("|cFFFF0000Cannot mark on the current map!|r")
        return
    end
    C_Map.ClearUserWaypoint()
    C_SuperTrack.SetSuperTrackedUserWaypoint(false);
    if WayPointContainer then
        if WayPointContainer:IsShown() then
            local xl = WayPointContainer.CoordX:GetText():len()
            local yl = WayPointContainer.CoordY:GetText():len()
            if xl ~= 0 and yl ~= 0 then
                local x = WayPointContainer.CoordX:GetNumber()
                local y = WayPointContainer.CoordY:GetNumber()
                WayPointPositionButton:SetWayPoint(x, y)
            end
            WayPointContainer:Close()
        else
            WayPointContainer:Show()
            WayPointContainer.CoordX:SetFocus()
        end
    end
end
WayPointPositionButton:SetScript("OnClick", WayPointPositionButton.OnClick)

local WayPointContainer = CreateFrame("Frame", "WayPointContainer", WorldMapFrame)
WayPointContainer:SetFrameStrata("DIALOG")
WayPointContainer:SetPoint("BOTTOM", WayPointPositionButton, "TOP", 0, 5)
WayPointContainer:SetWidth(100)
WayPointContainer:SetHeight(25)

function WayPointContainer:Close()
    WayPointContainer.CoordX:SetText("")
    WayPointContainer.CoordX:ClearFocus()
    WayPointContainer.CoordY:SetText("")
    WayPointContainer.CoordY:ClearFocus()
    WayPointContainer:Hide()
end

-- Tab key: cycle focus between coordinate fields
local function OnCoordTabPressed(editBox)
    if editBox == WayPointContainer.CoordX then
        WayPointContainer.CoordX:ClearFocus()
        WayPointContainer.CoordY:SetFocus()
    else
        WayPointContainer.CoordY:ClearFocus()
        WayPointContainer.CoordX:SetFocus()
    end
end

-- Enter key: confirm coordinate input
local function OnCoordEnterPressed(editBox)
    if editBox == WayPointContainer.CoordX then
        if editBox:GetText():len() ~= 0 then
            WayPointContainer.CoordX:ClearFocus()
            WayPointContainer.CoordY:SetFocus()
        end
    else
        if WayPointContainer.CoordX:GetText():len() ~= 0 and
            WayPointContainer.CoordY:GetText():len() ~= 0 then
            local x = WayPointContainer.CoordX:GetNumber()
            local y = WayPointContainer.CoordY:GetNumber()
            WayPointPositionButton:SetWayPoint(x, y)
            WayPointContainer:Close()
        elseif WayPointContainer.CoordY:GetText():len() ~= 0 and
            WayPointContainer.CoordX:GetText():len() == 0 then
            WayPointContainer.CoordY:ClearFocus()
            WayPointContainer.CoordX:SetFocus()
        end
    end
end

WayPointContainer.CoordY = CreateFrame("EditBox", "WayPointCoordY", WayPointContainer, "InputBoxTemplate")
WayPointContainer.CoordY:SetAutoFocus(false)
WayPointContainer.CoordY:SetSize(30, 20)
WayPointContainer.CoordY:SetNumeric(true)
WayPointContainer.CoordY:SetMaxLetters(2)
WayPointContainer.CoordY:SetPoint("LEFT", WayPointContainer, "CENTER", 75, -25)
WayPointContainer.CoordY:SetScript("OnTabPressed", OnCoordTabPressed)
WayPointContainer.CoordY:SetScript("OnEnterPressed", OnCoordEnterPressed)

WayPointContainer.CoordX = CreateFrame("EditBox", "WayPointCoordX", WayPointContainer, "InputBoxTemplate")
WayPointContainer.CoordX:SetAutoFocus(false)
WayPointContainer.CoordX:SetSize(30, 20)
WayPointContainer.CoordX:SetNumeric(true)
WayPointContainer.CoordX:SetMaxLetters(2)
WayPointContainer.CoordX:SetPoint("RIGHT", WayPointContainer, "CENTER", 65, -25)
WayPointContainer.CoordX:SetScript("OnTabPressed", OnCoordTabPressed)
WayPointContainer.CoordX:SetScript("OnEnterPressed", OnCoordEnterPressed)

WayPointContainer:Hide()

end)
