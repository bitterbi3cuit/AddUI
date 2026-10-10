local _, ns = ...

-- ══════════════════════════════════════════════════════════════
-- Assassination Rogue only: dual-DOT tracking grid on nearby enemy nameplates
-- At login, all 8 columns x 5 rows = 40 cells are created and put into a pool; grab one when needed
-- Master toggle is read once at login; "only units in combat", "cell size", "minimum remaining-time countdown" are live-editable in settings
-- Only enabled in the Assassination spec (spec swaps apply instantly); by default only "on your threat list or in combat" units count
-- Nameplates fill left-to-right in appearance order, wrapping after 8 (compact layout, no holes)
-- Cell: white background; Garrote (703) + Rupture (1943) both present -> turns red (nested containers implement the AND)
-- A container is hung in the middle of each cell showing the remaining time of whichever of the two DOTs expires first (countdown only, no swipe; toggleable)
-- ══════════════════════════════════════════════════════════════

ns.event("PLAYER_LOGIN", function()
	-- don't build for non-rogues
	local _, class = UnitClass("player")
	if class ~= "ROGUE" then return end

	local COLS, ROWS = 8, 5
	local GAP = 2
	local TOTAL = COLS * ROWS

	local ASSASSINATION = 259 -- Assassination spec ID (Outlaw 260 / Subtlety 261)

	-- the aura container template loads on demand; make sure it's there first
	if not DoesTemplateExist("CustomAuraContainerTemplate") then
		local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
		if type(load) == "function" then pcall(load, "Blizzard_AuraContainer") end
	end

	local function Clamp(v, lo, hi)
		if v < lo then return lo end
		if v > hi then return hi end
		return v
	end

	-- is the current spec Assassination
	local function IsAssassination()
		local specIndex = C_SpecializationInfo.GetSpecialization()
		if not specIndex or specIndex == 0 then return false end
		return C_SpecializationInfo.GetSpecializationInfo(specIndex) == ASSASSINATION
	end

	-- ═══════ read settings (master toggle read once at login; the rest are live-editable) ═══════

	local db = ns.DB or AddUIDB
	local ENABLED = not (db and db.rogueDotGrid == false)
	local THREAT_ONLY = not (db and db.rogueDotGridThreatOnly == false)
	local TIMER_ON = not (db and db.rogueDotGridTimer == false)
	local CELL = Clamp(tonumber(db and db.rogueDotGridCell) or 20, 8, 30)

	-- countdown text in the cell: font size scales with the cell
	local function TextH() return math.max(9, math.floor(CELL * 0.9)) end

	local function IsOn()
		return ENABLED and IsAssassination()
	end

	-- ═══════ outer frame ═══════

	local grid = CreateFrame("Frame", "ADURogueDotGrid", UIParent)
	grid:SetSize(COLS * CELL + (COLS - 1) * GAP, ROWS * CELL + (ROWS - 1) * GAP)
	grid:SetPoint("CENTER", UIParent, "CENTER", 0, -350)
	ns.AddEdit(grid, "Assassination DOT") -- drag position in edit mode

	local pool = {}     -- free cells
	local inUse = {}    -- unit -> cell
	local allCells = {} -- all cells (iterated when the size changes)
	local order = {}    -- ordered display list (decides where a cell is placed)

	-- build the containers for one cell
	local function BuildContainers(cell)
		-- outer container: Garrote (draws nothing itself, just acts as an "is Garrote up" switch)
		local outer = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
		outer:SetAllPoints(cell)
		outer:AddAuraSlot("garrote", "HARMFUL|PLAYER", {
			candidateFilters = { includeSpellIDs = {[703] = true} },
			initializeFrame = function(btn)
				btn:SetSize(CELL, CELL)
				btn:EnableMouse(false)
				-- the slot's anchor must be set here: initializeFrame is an untainted context,
				-- calling SetPoint on an AuraButton from outside (tainted) is blocked
				btn:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)

				-- inner container: Rupture. Parent = the outer button, so it doesn't render while the
				-- outer button is hidden -> red only when both are present
				local inner = CreateFrame("AuraContainer", nil, btn, "CustomAuraContainerTemplate")
				inner:SetAllPoints(cell)
				inner:SetEnabled(false) -- it defaults to true; disable then re-enable to trigger one event registration
				local innerSlot = inner:AddAuraSlot("rupture", "HARMFUL|PLAYER", {
					candidateFilters = { includeSpellIDs = {[1943] = true} },
					initializeFrame = function(btn2)
						btn2:EnableMouse(false)
						local tex = btn2:CreateTexture(nil, "OVERLAY")
						tex:SetAllPoints(cell) -- anchored to the cell: visibility is driven by the button, position doesn't depend on button size
						tex:SetColorTexture(1, 0, 0, 1) -- red
					end,
				})
				innerSlot:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
				inner:SetEnabled(true)
				cell.inner = inner
			end,
		})
		cell.outer = outer

		-- the countdown container inside the cell: shows only the remaining time of the DOT that expires first
		-- maxFrameCount = 1 + ascending expiration -> the one left is the DOT with the smallest remaining time
		local timer = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
		timer:SetAllPoints(cell)
		timer:SetFrameLevel(cell:GetFrameLevel() + 10) -- the countdown must sit above the red background (the red texture is several layers higher than the cell)
		timer:AddAuraGroup("minDot", "HARMFUL|PLAYER", {
			maxFrameCount = 1,
			sortMethod = AuraContainerSortMethod.ExpirationOnly,
			candidateFilters = { includeSpellIDs = {[703] = true, [1943] = true} },
			initializeFrame = function(btn)
				btn:EnableMouse(false)
				-- countdown only: strip the swipe / darkening / edge / bling from the cooldown frame, keep the numbers
				local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
				cd:ClearAllPoints() -- the template ships with setAllPoints, clear it first
				cd:SetAllPoints(cell) -- cover the whole cell, the countdown centers itself automatically
				cd:SetDrawSwipe(false)
				cd:SetDrawEdge(false)
				cd:SetDrawBling(false)
				cd:SetHideCountdownNumbers(false)
				local num = cd:GetCountdownFontString()
				num:SetFont(STANDARD_TEXT_FONT, TextH())
				num:SetTextColor(0, 1, 0) -- the cell is white, use black text
				btn:SetDurationCooldown(cd)
				cell.timerNum = num
			end,
		})
		cell.timer = timer
	end

	-- build all 40 cells at login and drop them into the pool
	-- (the grid is visible at this point so the containers can register; hide them afterwards and show on demand)
	for _ = 1, TOTAL do
		local cell = CreateFrame("Frame", nil, grid)
		cell:SetSize(CELL, CELL)

		local white = cell:CreateTexture(nil, "BACKGROUND")
		white:SetAllPoints(cell)
		white:SetColorTexture(1, 1, 1, 1) -- white background

		BuildContainers(cell)
		cell:Hide()

		allCells[#allCells + 1] = cell
		pool[#pool + 1] = cell
	end

	-- countdown toggle: only attach the countdown container to the unit when enabled (disabling renders nothing)
	-- the cell must be visible for SetUnit, otherwise the container can't register
	local function UpdateTimer(cell)
		if TIMER_ON and cell.unit then
			cell.timer:SetUnit(cell.unit)
			cell.timer:SetEnabled(true)
		else
			cell.timer:SetEnabled(false)
		end
	end

	-- take a cell for a nameplate
	local function Acquire(unit)
		local cell = table.remove(pool)
		if not cell then return end

		cell.unit = unit
		inUse[unit] = cell

		cell:Show()
		cell.outer:SetUnit(unit)
		cell.outer:SetEnabled(true)
		if cell.inner then cell.inner:SetUnit(unit) end
		UpdateTimer(cell)
	end

	-- return a cell
	local function Release(cell)
		if cell.unit then
			inUse[cell.unit] = nil
			cell.unit = nil
		end
		cell:Hide()
		cell.outer:SetEnabled(false)
		cell.timer:SetEnabled(false)
		pool[#pool + 1] = cell
	end

	-- lay out cells in display order (wrap after 8); cells whose index hasn't changed stay put
	local function Layout()
		for index, unit in ipairs(order) do
			local cell = inUse[unit]
			if cell and cell.index ~= index then
				cell.index = index
				local col = (index - 1) % COLS
				local row = math.floor((index - 1) / COLS)
				cell:ClearAllPoints()
				cell:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (CELL + GAP), -row * (CELL + GAP))
			end
		end
	end

	-- should this unit be shown: by default only "relevant" units -- on your threat list, or itself in combat
	-- (some units are in combat without being on your threat list: threat clears after Vanish/stealth, a teammate just pulled, etc. -- your DOT is still on them)
	local function ShouldShow(unit)
		if not THREAT_ONLY then return true end
		local threat = UnitThreatSituation("player", unit) -- not on the threat list -> nil
		if not ns.MM(threat) and (threat or -1) >= 0 then return true end
		return UnitAffectingCombat(unit) -- also count units that are in combat but you have no threat on
	end

	-- realign the display list: keep the existing order, drop units that fell out, append new ones at the end
	local function Refresh()
		if not IsOn() then return end

		local valid, seen = {}, {}
		for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
			local uf = nameplate.UnitFrame --[[@as any]]
			local unit = uf and uf.displayedUnit --[[@as UnitToken]]
			if unit and not seen[unit] and ShouldShow(unit) then
				seen[unit] = true
				valid[#valid + 1] = unit
			end
		end

		-- remove units that disappeared / fell off the threat list
		for i = #order, 1, -1 do
			local unit = order[i]
			if not seen[unit] then
				table.remove(order, i)
				local cell = inUse[unit]
				if cell then Release(cell) end
			end
		end

		-- append newly appeared units (ones past the cell count just queue up, unshown)
		for _, unit in ipairs(valid) do
			if #order >= TOTAL then break end
			if not inUse[unit] then
				order[#order + 1] = unit
				Acquire(unit)
			end
		end

		Layout()
	end

	-- nameplate / threat churn is heavy, batch it into a single computation on the next frame
	local pending = false
	local function QueueRefresh()
		if pending then return end
		pending = true
		C_Timer.After(0, function()
			pending = false
			Refresh()
		end)
	end

	-- apply the toggle: called on login, spec change, and entering the world
	local function Apply()
		if not IsOn() then
			for i = #order, 1, -1 do
				local unit = table.remove(order, i)
				local cell = inUse[unit]
				if cell then Release(cell) end
			end
			grid:Hide()
			return
		end

		grid:Show()
		Refresh()
	end

	-- settings take effect live: only units in combat / minimum remaining-time countdown / cell size
	ns.RogueDotGridRefresh = function()
		local cfg = ns.DB or AddUIDB
		THREAT_ONLY = not (cfg and cfg.rogueDotGridThreatOnly == false)

		local timerOn = not (cfg and cfg.rogueDotGridTimer == false)
		if timerOn ~= TIMER_ON then
			TIMER_ON = timerOn
			for _, cell in ipairs(allCells) do
				if cell.unit then UpdateTimer(cell) end -- cells in use toggle their countdown immediately
			end
		end

		local size = Clamp(tonumber(cfg and cfg.rogueDotGridCell) or 20, 8, 30)
		if size ~= CELL then
			CELL = size
			grid:SetSize(COLS * CELL + (COLS - 1) * GAP, ROWS * CELL + (ROWS - 1) * GAP)
			for _, cell in ipairs(allCells) do
				cell:SetSize(CELL, CELL)
				cell.index = nil -- size changed, recompute every position
				if cell.timerNum then
					cell.timerNum:SetFont(STANDARD_TEXT_FONT, TextH())
				end
			end
		end

		Refresh() -- rescan: both the filters and the size changed, so realign everything
	end

	ns.event("PLAYER_SPECIALIZATION_CHANGED", Apply)        -- spec change
	ns.event("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", Apply) -- spec change (active specialization changed)
	ns.event("NAME_PLATE_UNIT_ADDED", QueueRefresh)
	ns.event("NAME_PLATE_UNIT_REMOVED", QueueRefresh)
	ns.event("UNIT_THREAT_LIST_UPDATE", QueueRefresh) -- entering/leaving the threat list
	ns.event("PLAYER_ENTERING_WORLD", Apply)

	Apply()
end)
