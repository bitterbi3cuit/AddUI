local _,ns = ...
-- --by:简繁,伤害统计始终简化数值
local NumberData = {
	config = CreateAbbreviateConfig({
		{
			breakpoint = 1e10,  -- 10B+, e.g. 12B
			abbreviation = "B",
			significandDivisor = 1e9,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e9,   -- 1B+, e.g. 1.2B
			abbreviation = "B",
			significandDivisor = 1e8,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e7,   -- 10M+, e.g. 12M
			abbreviation = "M",
			significandDivisor = 1e6,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e6,   -- 1M+, e.g. 1.2M
			abbreviation = "M",
			significandDivisor = 1e5,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e4,   -- 10k+, e.g. 12k
			abbreviation = "k",
			significandDivisor = 1e3,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e3,   -- 1k+, e.g. 1.2k
			abbreviation = "k",
			significandDivisor = 1e2,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1,
			abbreviation = "",
			significandDivisor = 1,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
	}),
}
local function GetMainValue(entry)
	if entry.valuePerSecond ~= nil and entry:ShowsValuePerSecondAsPrimary() then
		return entry.valuePerSecond;
	end

	if entry.value ~= nil then
		return entry.value;
	end

	return 0;
end
local function GetParentheticalValue(entry)
	if entry.value ~= nil and entry:ShowsValuePerSecondAsPrimary() then
		return entry.value;
	end

	if entry.valuePerSecond ~= nil then
		return entry.valuePerSecond;
	end

	return 0;
end

local function GetEntryValueText(value, parentheticalValue)
	if parentheticalValue ~= nil then
		return DAMAGE_METER_ENTRY_FORMAT_COMPACT:format(AbbreviateNumbers(value,NumberData), AbbreviateNumbers(parentheticalValue,NumberData));
	else
		return DAMAGE_METER_ENTRY_FORMAT_MINIMAL:format(AbbreviateNumbers(value,NumberData));
	end
end
local numberDisplayTypeFormatters =
{
	[Enum.DamageMeterNumbers.Minimal] = function(entry) return GetEntryValueText(GetMainValue(entry)); end,
	[Enum.DamageMeterNumbers.Compact] = function(entry) return GetEntryValueText(GetMainValue(entry), GetParentheticalValue(entry)); end,
}
local function GetValueText(self)
	return numberDisplayTypeFormatters[self:GetNumberDisplayType()](self);
end
ns.hook(DamageMeterEntryMixin, "Init", function(self)
	if not AddUIDB.valueda then return end
	if self.MYHOOK then return end
	self.MYHOOK = true
	ns.hook(self, "UpdateValue", function(bar)
		if bar:GetNumberDisplayType() == Enum.DamageMeterNumbers.Complete then
			return
		end
		local success, text = pcall(GetValueText, bar)
		if success and text then
			bar:GetValue():SetText(text);
		end
	end)
end)
