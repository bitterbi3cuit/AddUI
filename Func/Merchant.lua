local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.mh ==  true  then
-- Automatically sell junk (grey items)
ns.event("MERCHANT_SHOW", function() 
	local p,N,c,n=0
		for b=0,4 do
		    for s=1,C_Container.GetContainerNumSlots (b) do
			    n=C_Container.GetContainerItemLink(b,s)--https://warcraft.wiki.gg/wiki/UI_escape_sequences 
                    if n and string.find(n,"|cnIQ0") then--9d9d9d--Q0 grey 123456---https://warcraft.wiki.gg/wiki/Enum.ItemQuality
					    N={C_Item.GetItemInfo(n)} 
                        c=C_Item.GetItemCount(n)
						p= p+(N[11]*c)
						C_Container.UseContainerItem(b,s)
					end
			end
		end 
		--C_MerchantFrame.SellAllJunkItems()
    if p ~= 0 then
	    print("|cff44CCFFJunk sold: |r"..C_CurrencyInfo.GetCoinText(p))
	end
end)
end

-- One-click NPC sell button for equipment
-- Equipment to exclude from selling
local nosell = {
	[63352] = true,-- Cloak of Coordination
	[63206] = true,-- Cape of Coordination
	[65360] = true,-- Cloak of Cooperation
	[63353] = true,-- Horde Cloak of Coordination
	[63207] = true,-- Horde Cape of Coordination
	[65274] = true,-- Horde Cloak of Cooperation
	[152094]= true,-- Taeshalach
	[103678]= true,-- Teleport to Timeless Isle
}

StaticPopupDialogs.MerchantFrame_Sell = {
    text = "About to auto-sell\nSell equipment below which item level?",  -- Prompt text
    button1 = "Confirm",       -- Confirm button
    button2 = "Cancel",        -- Cancel button
    timeout = 0,               -- Do not auto-close
    whileDead = true,          -- Usable while dead
    hideOnEscape = true,       -- Close on ESC
    hasEditBox = true,         -- Include an input box
	OnShow = function(self)
		self.EditBox:SetScript("OnEscapePressed", function(EditBox)
            self:Hide()  -- Close the window immediately
        end)
    end,
    OnAccept = function(self)  -- Callback after clicking Confirm
        local BoxLevel = tonumber(self.EditBox:GetText())
		local N,c,n
		for b=0,4 do
			for s = 1,C_Container.GetContainerNumSlots(b) do
				n = C_Container.GetContainerItemLink(b,s) 
				if n then
					local level =  C_Item.GetDetailedItemLevelInfo(n)
					N={C_Item.GetItemInfo(n)}
					local itemID = tonumber(string.match(n, "item:(%d+)")) or 1
					if BoxLevel and level and BoxLevel > level and level > 1 and (N[6] == ARMOR or N[6] == WEAPON) and not nosell[itemID] and not string.find(n,"|cnIQ5") then
						C_Container.UseContainerItem(b,s)
					end
				end
			end
		end
    end,
}
local Sell = CreateFrame("Button", "AddUISell", MerchantFrame.NineSlice, "UIPanelButtonTemplate")
Sell:SetText("Sell")
Sell:SetWidth(55)
Sell:SetHeight(22)
Sell:SetPoint("TOPLEFT", 57, 0)
Sell:SetScript("OnClick", function()
	StaticPopup_Show("MerchantFrame_Sell")
end)

-- Fast looting (fastest: grab everything the instant LOOT_READY fires)
-- Approach inspired by Plumber (author Peterodox) Modules/LootUI/FastLoot.lua
if AddUIDB.sq == true then
	local slotProcessed, retryPending
	local function LootAll()
		for i = 1, GetNumLootItems() do
			if LootSlotHasItem(i) and not (slotProcessed and slotProcessed[i]) then
				slotProcessed = slotProcessed or {}
				slotProcessed[i] = true
				LootSlot(i)
			end
		end
	end

	ns.event("LOOT_READY", function()
		LootAll()
	end)
	ns.event("LOOT_CLOSED", function()
		slotProcessed, retryPending = nil, nil
	end)
	ns.event("LOOT_SLOT_CLEARED", function(_, slot)
		if slotProcessed then slotProcessed[slot] = true end
	end)
	ns.event("LOOT_SLOT_CHANGED", function(_, slot)
		if not slotProcessed or retryPending then return end
		slotProcessed[slot] = false
		retryPending = true
		C_Timer.After(0.4, function()
			retryPending = nil
			LootAll()
		end)
	end)
end

end)
