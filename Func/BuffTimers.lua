local _,ns = ...

SetCVar("buffDurations", 1)	-- show buff durations; some addons turn this off

ns.tips("Show seconds for buffs and debuffs under 10 minutes")
local function Bufftime(seconds)
if type(seconds) ~="number" then return end 
if seconds > 86400 then 
	return format("%dd", seconds/86400)
elseif seconds > 6000 then 
	return format("%d h", seconds/3600+1)
elseif seconds > 3600 then 
	return format("%d m", seconds/60)
elseif seconds > 600 then 
	return format("%d m", seconds/60)
elseif seconds > 60 then 
	return format("%d:%.2d", seconds/60, seconds%60)
else 
	return format("%d s", seconds)
end
end

local function MyBuffTime(self,timeLeft)
	if timeLeft > 600 or timeLeft < 60 then return end
	self.Duration:SetFormattedText(format("%d:%.2d", timeLeft/60, timeLeft%60))
end

local function BuffTimeNA(aura)
	if aura.buttonInfo.expirationTime ~= 0 then return end
	aura.duration:SetText("|cff00ff00N/A|r")
	aura.duration:Show()
end
local frames = {buffFrame, debuffFrame}
for i = 1, #frames do
	for _, button in ipairs(frames[i].auraFrames) do
		if button then
			hooksecurefunc(button, "OnUpdate", MyBuffTime)
		end
		if button then
			hooksecurefunc(button, "UpdateDuration", MyBuffTime)
		end
	end
end

ns.tips("Show current and highest item level on the equipment pane")
ns.hook('PaperDollFrame_SetItemLevel', function(self, unit) 
   if (unit ~= 'player') then return end 

   local total, equip = GetAverageItemLevel() 
   if (total > 0) then total = string.format('%.1f', total) end 
   if (equip > 0) then equip = string.format('%.1f', equip) end 

   local ilvl = equip 
   if (equip < total) then 
      ilvl = equip .. ' / ' .. total 
   end
   
   local total2,equip2 = GetAverageItemLevel() 
   if (total2 > 0) then total2 = string.format('%.3f', total2) end 
   if (equip2 > 0) then equip2 = string.format('%.3f', equip2) end
   local ilvl2 = equip2
   if (equip2 < total2) then 
      ilvl2 = equip2 .. ' / ' .. total2
   end 

   -- local ilvlLine = _G[self:GetName() .. 'StatText'] 
   CharacterStatsPane.ItemLevelFrame.Value:SetText(ilvl) 

   self.tooltip =  "|cffffffff".. STAT_AVERAGE_ITEM_LEVEL .. ' ' .. ilvl2 
end)

ns.tips("Show movement speed on the character pane")

-- As of 12.0.5 movement speed became a secret value and cannot be used in arithmetic.
-- Use a standalone display (do not insert into Blizzard's stat rows, to avoid polluting their refresh loop):
--   Create separate text at the bottom-right of the character pane background, using AbbreviateNumbers to display the percentage with secret-value compatibility.
-- Number formatting simplified from https://bbs.nga.cn/read.php?tid=46650149
local SPEED_FORMAT_OPTIONS = {
    breakpointData = {
        {
            breakpoint = 0,
            abbreviation = "%",
            significandDivisor = 0.06999,
            fractionDivisor = 1,
            abbreviationIsGlobal = false,
        },
    },
}

-- Standalone movement-speed text, anchored to the bottom-right of the character pane background (bottom-left corner aligned to the background's bottom-right corner)
-- Note: CharacterFrame.Background is a texture (BACKGROUND layer); text created on it would be covered,
-- so it is created on the top-level CharacterFrame with a raised draw layer.
-- Must be hooked only after PLAYER_LOGIN (once all Blizzard UI has loaded), otherwise hooksecurefunc cannot find the function.
-- Standalone display approach (active): does not pollute Blizzard's refresh loop, and cannot error under any circumstance
-- Note: inserting a stat row into PAPERDOLL_STATCATEGORIES would, in the 12.0.5 secret-value era, pollute
--       the PaperDollFrame_UpdateStats refresh loop and cause errors, hence a standalone Frame is used.
ns.event("PLAYER_LOGIN", function()
    if not (AddUIDB and AddUIDB.movspeed) then return end
    if not PaperDollFrame or not CharacterFrame or not CharacterFrame.Background then return end
    local frame = CreateFrame("Frame", nil, PaperDollFrame)
    frame:SetFrameStrata("HIGH")
    frame:SetSize(1, 1)
    frame:SetPoint("BOTTOMLEFT", CharacterFrame.Background, "BOTTOMRIGHT", -108, 8)

    local speedtext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    speedtext:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    speedtext:SetTextColor(1, 1, 1, 1)

    local runSpeed, flightSpeed, swimSpeed  -- cache, for tooltip use (secret values)

    -- Mouse-over tooltip: show run/flight/swim speed (the function of Blizzard's original MovementSpeed_OnEnter)
    -- Speed is a secret value; %d arithmetic cannot be used on it, so AbbreviateNumbers is needed for compatibility
    -- Note: FormatSpeed / BuildTooltipLines must be defined before UpdateSpeedText,
    --       otherwise references to them inside UpdateSpeedText would be global nil (Lua lexical scoping)
    local function FormatSpeed(formatString, secretSpeed)
        -- The localized format string is like "Run Speed: %d%%"; replace %d%% with %s, then pass in a string containing %
        return format(formatString:gsub("%%d%%%%", "%%s"), AbbreviateNumbers(secretSpeed, SPEED_FORMAT_OPTIONS))
    end

    local function BuildTooltipLines()
        GameTooltip:ClearLines()
        GameTooltip:AddLine(format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED).." "..AbbreviateNumbers(runSpeed, SPEED_FORMAT_OPTIONS))
        GameTooltip:AddLine(FormatSpeed(STAT_MOVEMENT_GROUND_TOOLTIP, runSpeed))
        GameTooltip:AddLine(FormatSpeed(STAT_MOVEMENT_FLIGHT_TOOLTIP, flightSpeed))
        GameTooltip:AddLine(FormatSpeed(STAT_MOVEMENT_SWIM_TOOLTIP, swimSpeed))
    end

    local function UpdateSpeedText()
        local _, run, flight, swim = GetUnitSpeed("player")
        runSpeed, flightSpeed, swimSpeed = run, flight, swim
        local speed = run
        if IsSwimming("player") then
            speed = swim
        elseif IsFlying("player") then
            speed = flight
        end
        speedtext:SetText(format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED).." "..AbbreviateNumbers(speed, SPEED_FORMAT_OPTIONS))
        -- While the tooltip is displayed, refresh its contents in sync, for live updates
        if GameTooltip:IsOwned(frame) then
            BuildTooltipLines()
        end
    end

    local function OnEnter()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT",-20,15)
        BuildTooltipLines()
        GameTooltip:Show()
    end

    local function OnLeave()
        GameTooltip:Hide()
    end
    speedtext:SetScript("OnEnter", OnEnter)
    speedtext:SetScript("OnLeave", OnLeave)

    -- Blizzard's original attaches OnUpdate to the stat row to call MovementSpeed_OnUpdate every frame for live refresh,
    -- rather than relying on the SPEED_UPDATE event (which only fires when the "speed stat value" changes, not on mounting/dismounting).
    -- frame is a child of CharacterFrame: while the pane is open, OnUpdate updates every frame;
    -- when the pane closes, frame is hidden along with it and OnUpdate stops automatically, so no performance is wasted.
    frame:SetScript("OnUpdate", UpdateSpeedText)
    CharacterFrame:HookScript("OnShow", UpdateSpeedText)
end)
