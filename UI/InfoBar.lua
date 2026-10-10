local addonName,ns = ...

-- Create text (originally ns.AddText, defined outside this file)
local function AddText(frame,size)
	local text = frame:CreateFontString(nil, "ARTWORK")
	text:SetFont(STANDARD_TEXT_FONT, size, 'OUTLINE')
	return text
end

ns.event("PLAYER_LOGIN", function()
if not AddUIDB.dimi then return end
-- Gold
local gold = CreateFrame("Frame", nil, UIParent)
gold:SetFrameLevel(50)
gold:SetPoint("BOTTOMRIGHT",UIParent,-10,0)
local goldText = gold:CreateFontString(nil, "ARTWORK")
goldText:SetFont(STANDARD_TEXT_FONT, 13, 'OUTLINE')
goldText:SetPoint("RIGHT", gold, "RIGHT", 0, 0)

-- Durability
local durable = AddText(UIParent,13)
durable:SetPoint("BOTTOMRIGHT",UIParent,-120,0)

-- FPS
local fps = AddText(UIParent,13)
fps:SetPoint("BOTTOMRIGHT",UIParent,-240,0)

----------- Gold----------
local GoldIcon = "\124TInterface\\MoneyFrame\\UI-GoldIcon:0:0:1:0\124t"
local Profit	= 0
local Spent		= 0
local OldMoney	= 0

local function formatMoney(money)
	-- Keep gold only; discard silver and copper (do not round)
	return BreakUpLargeNumbers(floor(math.abs(money) / 10000))..GoldIcon
end

local function formatTextMoney(money)
	-- Keep gold only; discard silver and copper (do not round)
	return floor(money / 10000).."|cffffd700"..GOLD_AMOUNT_SYMBOL
end

----------- Gold tracking (one group per Battle.net account, recorded per character)----------
-- 保存结构：AddUIDB.GoldTracker = {
--   ["Battle.net ID"] = {
--     ["CharacterName-Realm"] = { n = character name, g = copper, c = class },
--     warband = Warband Bank copper,
--   },
-- }
local GOLD_MIN = 100 * 10000 -- Hide characters with less than 100 gold
local charsCache -- Hovered character-list cache; invalidated when character gold changes

-- Color character names by class
local function ClassNameText(name, class)
	local color = class and C_ClassColor.GetClassColor(class)
	if color then return color:WrapTextInColorCode(name) end
	return name
end

local function GetGoldTrack()
	local db = AddUIDB.GoldTracker
	if type(db) ~= "table" then db = {} AddUIDB.GoldTracker = db end
	return db
end

-- Current Battle.net ID (e.g. Name#1234); use 'unknown' as a fallback when unavailable
local function GetAccountTag()
	return select(2, BNGetInfo()) or "unknown"
end

-- Character group for the current Battle.net account
local function GetAccountGroup()
	local db = GetGoldTrack()
	local tag = GetAccountTag()
	if type(db[tag]) ~= "table" then db[tag] = {} end
	return db[tag]
end

local function GetCharKey()
	return format("%s-%s", UnitFullName("player"), GetNormalizedRealmName() or GetRealmName())
end

-- Save the current character's gold
local function SaveCharMoney()
	local name, class = UnitName("player"), select(2, UnitClass("player"))
	if not name then return end
	GetAccountGroup()[GetCharKey()] = { n = name, g = GetMoney(), c = class }
	charsCache = nil
end

-- Warband Bank gold: read live; use the DB cache if unavailable (stored in the current Battle.net account group)
local function GetWarbandMoney()
	local group = GetAccountGroup()
	local ok, money = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
	if ok and type(money) == "number" and not ns.MM(money) then
		local canRead = money > 0
		if not canRead then
			local ok2, canView = pcall(C_Bank.CanViewBank, Enum.BankType.Account)
			canRead = ok2 and canView
		end
		if canRead then
			group.warband = money
			return money
		end
	end
	local cached = group.warband
	if type(cached) == "number" then return cached end
	return 0
end

-- Gold for characters on the current Battle.net account (current character always first; hide others below 100 gold, then sort by gold descending)
-- The group's 'warband' entry is a number, not a table, so the type check below naturally skips it
-- Cache results in charsCache; rebuild only when character gold changes to avoid iterating and sorting on every hover
local function GetChars()
	if charsCache then return charsCache end
	local list = {}
	local curKey = GetCharKey()
	for key, entry in pairs(GetAccountGroup()) do
		local g = type(entry) == "table" and entry.g
		if type(g) == "number" and (key == curKey or g >= GOLD_MIN) then
			list[#list + 1] = { n = entry.n or key, g = g, c = entry.c, cur = key == curKey }
		end
	end
	table.sort(list, function(a, b)
		if a.cur ~= b.cur then return a.cur == true end
		return a.g > b.g
	end)
	charsCache = list
	return list
end

SaveCharMoney()
ns.event("PLAYER_MONEY", SaveCharMoney)
ns.event("PLAYER_ENTERING_WORLD", SaveCharMoney)
ns.event("ACCOUNT_MONEY", function() GetWarbandMoney() end)

local lastMoneyText -- Previously displayed gold text; skip layout updates when unchanged
local function OnMoneyEvent(event)
	if event == "PLAYER_ENTERING_WORLD" then
		OldMoney = GetMoney()
	end
	local NewMoney = GetMoney()
	local Change = NewMoney-OldMoney -- Positive if we gain money
	
	if OldMoney > NewMoney then		-- Lost Money
		Spent = Spent - Change
	else							-- Gained Moeny
		Profit = Profit + Change
	end
	-- Do not measure the width again if the gold text has not changed
	local txt = formatTextMoney(NewMoney)
	if txt ~= lastMoneyText then
		lastMoneyText = txt
		goldText:SetText(txt)
		local w = goldText:GetStringWidth()
		if w and w > 0 then
			gold:SetWidth(w + 4)
			gold:SetHeight(goldText:GetStringHeight() + 2)
		end
	end
	OldMoney = NewMoney
end

-- Attach the tooltip script to the Frame (FontString mouse events may be unreliable); set it only once;
-- Tooltip content reads the current Profit / Spent values, so the script does not need to be reset whenever gold changes
gold:SetScript("OnEnter", function()
	GameTooltip:SetOwner(gold, "ANCHOR_TOP", 0, 6);
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOM", gold, "TOP", 0, 1)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(CURRENCY,0,.6,1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("This session: ",.6,.8,1)
	GameTooltip:AddDoubleLine("Earned:", formatMoney(Profit), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine("Spent:", formatMoney(Spent), 1, 1, 1, 1, 1, 1)
	if Profit < Spent then
		GameTooltip:AddDoubleLine("Loss:", formatMoney(Profit-Spent), 1, 0, 0, 1, 1, 1)
	elseif (Profit-Spent)>0 then
		GameTooltip:AddDoubleLine("Profit:", formatMoney(Profit-Spent), 0, 1, 0, 1, 1, 1)
	end
	local chars = GetChars()
	local warband = GetWarbandMoney()
	local total = warband
	GameTooltip:AddLine(" ")
	for _, c in ipairs(chars) do
		GameTooltip:AddDoubleLine(ClassNameText(c.n, c.c), formatMoney(c.g), 1, 1, 1, 1, 1, 1)
		total = total + c.g
	end
	GameTooltip:AddDoubleLine("Warband Bank:", formatMoney(warband), .6, .8, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine("Total:", formatMoney(total), 0, .8, 0, 0, 1, 0)
	GameTooltip:Show()
end)
gold:SetScript("OnLeave", function() GameTooltip:Hide() end)

ns.event("PLAYER_MONEY", OnMoneyEvent)
ns.event("SEND_MAIL_MONEY_CHANGED", OnMoneyEvent)
ns.event("SEND_MAIL_COD_CHANGED", OnMoneyEvent)
ns.event("PLAYER_TRADE_MONEY", OnMoneyEvent)
ns.event("TRADE_MONEY_CHANGED", OnMoneyEvent)
ns.event("PLAYER_ENTERING_WORLD", OnMoneyEvent)

----------- Durability----------
local gradient = function(perc)
	perc = perc > 1 and 1 or perc < 0 and 0 or perc -- Stay between 0-1
	local seg, relperc = math.modf(perc*2)
	local r1,g1,b1,r2,g2,b2 = select(seg*3+1,1,0,0,1,1,0,0,1,0,0,0,0) -- R -> Y -> G
	local r,g,b = r1+(r2-r1)*relperc,g1+(g2-g1)*relperc,b1+(b2-b1)*relperc
	return format("|cff%02x%02x%02x",r*255,g*255,b*255),r,g,b
end
-- Durability slots (promoted to an outer-scope variable shared by event handling and tooltips)
local localSlots = {
	[1] = {1, "Head", 1000},
	[2] = {3, "Shoulders", 1000},
	[3] = {5, "Chest", 1000},
	[4] = {6, "Waist", 1000},
	[5] = {9, "Wrists", 1000},
	[6] = {10, "Hands", 1000},
	[7] = {7, "Legs", 1000},
	[8] = {8, "Feet", 1000},
	[9] = {16, "Main Hand", 1000},
	[10] = {17, "Off Hand", 1000},
	[11] = {18, "Ranged", 1000}
}
-- Tooltip (set once during initialization)
durable:SetScript("OnEnter", function()
	local total, equipped = GetAverageItemLevel()
	GameTooltip:SetOwner(durable, "ANCHOR_TOP", 0, 6);
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOM", durable, "TOP", 0, 1)
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine(DURABILITY,format("%s: %d/%d", STAT_AVERAGE_ITEM_LEVEL, equipped, total),0,.6,1,0,.6,1)
	GameTooltip:AddLine(" ")
	for i = 1, 11 do
		if localSlots[i][3] ~= 1000 then
			local green = localSlots[i][3]*2
			local red = 1 - green
			GameTooltip:AddDoubleLine(localSlots[i][2], floor(localSlots[i][3]*100).."%", 1, 1, 1, red + 1, green, 0)
		end
	end
	GameTooltip:AddDoubleLine(" ","--------------",1,1,1,0.5,0.5,0.5)
	GameTooltip:Show()
end)
durable:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function OnDurabilityEvent(event)
	local Total = 0
	local current, max
	for i = 1, 11 do
		if GetInventoryItemLink("player", localSlots[i][1]) ~= nil then
			current, max = GetInventoryItemDurability(localSlots[i][1])
			if current then 
				localSlots[i][3] = current/max
				Total = Total + 1
			end
		end
	end
	table.sort(localSlots, function(a, b) return a[3] < b[3] end)
	
	if Total > 0 then
		durable:SetText(format(gsub("[color]%d|r%%".." Durability","%[color%]",(gradient(floor(localSlots[1][3]*100)/100))), floor(localSlots[1][3]*100)))
	end
end

ns.event("UPDATE_INVENTORY_DURABILITY", OnDurabilityEvent)
ns.event("MERCHANT_SHOW", OnDurabilityEvent)
ns.event("PLAYER_ENTERING_WORLD", OnDurabilityEvent)

----- FPS
local function colorlatency(latency)
	if latency < 300 then
		return "|cff0CD809"..latency
	elseif (latency >= 300 and latency < 500) then
		return "|cffE8DA0F"..latency
	else
		return "|cffD80909"..latency
	end
end

C_Timer.NewTicker(1, function()
	local _, _, latencyHome, latencyWorld = GetNetStats()
	local lat = math.max(latencyHome, latencyWorld)
	local fpscolor
	if floor(GetFramerate()) >= 30 then
		fpscolor = "|cff0CD809"
	elseif (floor(GetFramerate()) > 15 and floor(GetFramerate()) < 30) then
		fpscolor = "|cffE8DA0F"
	else
		fpscolor = "|cffD80909"
	end
	fps:SetText(fpscolor..floor(GetFramerate()).."|r".." Fps "..colorlatency(lat).."|r".."Ms")
end)

--Add memory usage to the FPS tooltip
local function formatTotal(Total)
	if Total >= 1024 then
		return format("%.1fmb", Total / 1024)
	else
		return format("%dkb", Total)
	end
end

local function GetAllAddonsMemory()
    local memoryUsage = 0
	UpdateAddOnMemoryUsage()
    for i = 1, C_AddOns.GetNumAddOns() do
        local usage = GetAddOnMemoryUsage(i)
		memoryUsage = memoryUsage + usage
    end
    return memoryUsage
end
local MemoryTabel = {}
fps:SetScript("OnLeave", function() GameTooltip:Hide() end)
fps:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(fps, "ANCHOR_TOP", 0, 6);
	GameTooltip:AddDoubleLine("Total memory usage:",formatTotal(GetAllAddonsMemory()),.6,.8,1,1,1,1)
	GameTooltip:AddLine(" ")
	for i = 1, C_AddOns.GetNumAddOns() do
		local Mem = GetAddOnMemoryUsage(i)
		MemoryTabel[i] = { select(2, C_AddOns.GetAddOnInfo(i)), Mem, C_AddOns.IsAddOnLoaded(i) }
	end
	table.sort(MemoryTabel, function(a, b)
		if a and b then
			return a[2] > b[2]
		end
		return false
	end)
	for i = 1, #MemoryTabel  do
		if MemoryTabel[i][3] then
			local color = MemoryTabel[i][2] <= 102.4 and {0,1} -- 0 - 100
			or MemoryTabel[i][2] <= 512 and {0.75,1} -- 100 - 512
			or MemoryTabel[i][2] <= 1024 and {1,1} -- 512 - 1mb
			or MemoryTabel[i][2] <= 2560 and {1,0.75} -- 1mb - 2.5mb
			or MemoryTabel[i][2] <= 5120 and {1,0.5} -- 2.5mb - 5mb
			or {1,0.1} -- 5mb +
			GameTooltip:AddDoubleLine(MemoryTabel[i][1], formatTotal(MemoryTabel[i][2]), 1, 1, 1, color[1], color[2], 0)						
		end
    end
	GameTooltip:Show()
end)
fps:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" then
		local before = collectgarbage("count")
		collectgarbage("collect")
		print(format("|cff66C6FF%s:|r %s","Freed memory",formatTotal(before - collectgarbage("count"))))
		self:GetScript("OnEnter")(self)
	end
end)

end)