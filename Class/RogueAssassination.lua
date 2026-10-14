local _, ns = ...

-- ══════════════════════════════════════════════════════════════
-- Assassination Rogue (Assassination spec) exclusive:
-- Dual-DOT monitoring grid for nearby enemy nameplates.
-- At login, 8 cols × 5 rows = 40 cells are built and pooled;
-- grab one when needed.
-- Master switch is read once at login; "combat-only filter",
-- "cell size", and "minimum timer" can be changed live in settings.
-- Only active on Assassination spec (instant on spec swap).
-- Default: only tracks enemies on your threat list OR in combat.
-- Nameplates fill left-to-right in order of appearance; wraps
-- every 8 (compact, no gaps).
-- Cell: white background; Garrote (703) + Rupture (1943) both
-- present → turns red (nested container implements AND logic).
-- A third container in the center shows the remaining time of
-- whichever DOT expires first (countdown only, no sweep; toggleable).
-- ══════════════════════════════════════════════════════════════

ns.event("PLAYER_LOGIN", function()
	-- Skip if not a Rogue
	local _, class = UnitClass("player")
	if class ~= "ROGUE" then return end

	local COLS, ROWS = 8, 5
	local GAP = 2
	local TOTAL = COLS * ROWS

	local ASSASSINATION = 259 -- Assassination spec ID (Outlaw 260 / Subtlety 261)

	-- The aura-container template is loaded on demand; make sure it exists
	if not DoesTemplateExist("CustomAuraContainerTemplate") then
		local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
		if type(load) == "function" then pcall(load, "Blizzard_AuraContainer") end
	end

	local function Clamp(v, lo, hi)
		if v < lo then return lo end
		if v > hi then return hi end
		return v
	end

	-- Returns true when the player is currently on Assassination spec
	local function IsAssassination()
		local specIndex = C_SpecializationInfo.GetSpecialization()
		if not specIndex or specIndex == 0 then return false end
		return C_SpecializationInfo.GetSpecializationInfo(specIndex) == ASSASSINATION
	end

	-- ═══════ Read settings (master switch once at login; rest live) ═══════

	local db = ns.DB or AddUIDB
	local ENABLED      = not (db and db.rogueDotGrid          == false)
	local THREAT_ONLY  = not (db and db.rogueDotGridThreatOnly == false)
	local TIMER_ON     = not (db and db.rogueDotGridTimer      == false)
	local CELL         = Clamp(tonumber(db and db.rogueDotGridCell) or 20, 8, 30)

	-- Countdown font size scales with cell size
	local function TextH() return math.max(9, math.floor(CELL * 0.9)) end

	local function IsOn()
		return ENABLED and IsAssassination()
	end

	-- ═══════ Outer frame ═══════

	local grid = CreateFrame("Frame", "ADURogueDotGrid", UIParent)
	grid:SetSize(COLS * CELL + (COLS - 1) * GAP, ROWS * CELL + (ROWS - 1) * GAP)
	grid:SetPoint("CENTER", UIParent, "CENTER", 0, -350)
	ns.AddEdit(grid, "AssassinationDOT") -- drag position in edit mode

	local pool     = {}  -- idle cells
	local inUse    = {}  -- unit -> cell
	local allCells = {}  -- all cells (iterated when resizing)
	local order    = {}  -- ordered display list (determines cell position)

	-- Build the aura containers for one cell
	local function BuildContainers(cell)
		-- Outer container: Garrote (renders nothing itself; acts as "Garrote present" gate)
		-- ⚠️ Must use AddAuraGroup: buttons are created by the container in a secure
		--    deferred context so it works in restricted environments (combat/instance/M+).
		--    AddAuraSlot creates AuraButtons immediately — tainted code hits "forbidden"
		--    in restricted environments.
		local outer = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
		outer:SetAllPoints(cell)
		outer:AddAuraGroup("garrote", "HARMFUL|PLAYER", {
			maxFrameCount = 1,
			candidateFilters = { includeSpellIDs = {[703] = true} },
			initializeFrame = function(btn)
				btn:SetSize(1, 1) -- button size doesn't matter; overlay texture anchors to cell
				btn:EnableMouse(false)

				-- Inner container: Rupture. Parent = outer button, so it only
				-- renders when the outer button is shown → both DOTs needed for red.
				local inner = CreateFrame("AuraContainer", nil, btn, "CustomAuraContainerTemplate")
				inner:SetAllPoints(cell)
				inner:EnableMouse(false)
				inner:AddAuraGroup("rupture", "HARMFUL|PLAYER", {
					maxFrameCount = 1,
					candidateFilters = { includeSpellIDs = {[1943] = true} },
					initializeFrame = function(btn2)
						btn2:SetSize(1, 1)
						btn2:EnableMouse(false)
						local tex = btn2:CreateTexture(nil, "OVERLAY")
						tex:SetAllPoints(cell) -- anchored to cell; visibility driven by button
						tex:SetColorTexture(1, 0, 0, 1) -- red
					end,
				})
				-- initializeFrame runs deferred; outer may or may not have a unit yet
				local unit = outer:GetUnit()
				if unit then inner:SetUnit(unit) end
				cell.inner = inner
			end,
		})
		cell.outer = outer

		-- Timer container in the cell center: shows remaining time of the DOT
		-- expiring soonest. maxFrameCount = 1 + sort by expiration ascending
		-- → the surviving frame is whichever DOT has the smallest remaining time.
		local timer = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
		timer:SetAllPoints(cell)
		timer:SetFrameLevel(cell:GetFrameLevel() + 10) -- countdown must sit above red overlay
		timer:AddAuraGroup("minDot", "HARMFUL|PLAYER", {
			maxFrameCount = 1,
			sortMethod = AuraContainerSortMethod.ExpirationOnly,
			candidateFilters = { includeSpellIDs = {[703] = true, [1943] = true} },
			initializeFrame = function(btn)
				btn:EnableMouse(false)
				-- Countdown only: strip the sweep, dark tint, edge, and bling; keep numbers
				local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
				cd:ClearAllPoints() -- template sets AllPoints by default; clear it first
				cd:SetAllPoints(cell) -- fill the entire cell; numbers auto-center
				cd:SetDrawSwipe(false)
				cd:SetDrawEdge(false)
				cd:SetDrawBling(false)
				cd:SetHideCountdownNumbers(false)
				local num = cd:GetCountdownFontString()
				num:SetFont(STANDARD_TEXT_FONT, TextH())
				num:SetTextColor(0, 1, 0) -- white cell background → use black text
				btn:SetDurationCooldown(cd)
				cell.timerNum = num
			end,
		})
		cell.timer = timer
	end

	-- Build all 40 cells at login and put them in the pool.
	-- (grid must be visible at this point for containers to register;
	--  hide each cell after building and show on demand.)
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

	-- Timer toggle: only attach the timer container to a unit when the timer
	-- is enabled. Disabling the container stops all rendering.
	-- SetUnit must be called while the cell is visible for the container to register.
	local function UpdateTimer(cell)
		if TIMER_ON and cell.unit then
			cell.timer:SetUnit(cell.unit)
			cell.timer:SetEnabled(true)
		else
			cell.timer:SetEnabled(false)
		end
	end

	-- Check out a cell for a nameplate unit
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

	-- Return a cell to the pool
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

	-- Position cells in display order (wraps every 8); cells whose index
	-- hasn't changed are not repositioned.
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

	-- Should this unit be shown? Default: only "relevant" enemies —
	-- those on your threat list OR in combat themselves.
	-- (Some enemies are in combat but not on your threat list: e.g. after
	-- vanish clears threat, or a target just pulled by a teammate. Your
	-- DOTs can still be running on them.)
	local function ShouldShow(unit)
		if not THREAT_ONLY then return true end
		local threat = UnitThreatSituation("player", unit) -- nil if not on threat list
		if not ns.MM(threat) and (threat or -1) >= 0 then return true end
		return UnitAffectingCombat(unit) -- also accept enemies in combat without threat
	end

	-- Rebuild the display list: preserve existing order, remove units that
	-- no longer qualify, append newly qualifying units at the end.
	local function Refresh()
		if not IsOn() then return end

		local valid, seen = {}, {}
		for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
			local uf   = nameplate.UnitFrame --[[@as any]]
			local unit = uf and uf.displayedUnit --[[@as UnitToken]]
			if unit and not seen[unit] and ShouldShow(unit) then
				seen[unit] = true
				valid[#valid + 1] = unit
			end
		end

		-- Remove units that vanished or left the threat list
		for i = #order, 1, -1 do
			local unit = order[i]
			if not seen[unit] then
				table.remove(order, i)
				local cell = inUse[unit]
				if cell then Release(cell) end
			end
		end

		-- Append newly visible units (queue if pool is exhausted)
		for _, unit in ipairs(valid) do
			if #order >= TOTAL then break end
			if not inUse[unit] then
				order[#order + 1] = unit
				Acquire(unit)
			end
		end

		Layout()
	end

	-- Nameplate / threat events fire in bursts; coalesce to one update per frame
	local pending = false
	local function QueueRefresh()
		if pending then return end
		pending = true
		C_Timer.After(0, function()
			pending = false
			Refresh()
		end)
	end

	-- Apply the on/off state: called at login, spec change, and world entry
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

	-- Live settings update: combat-only filter / timer toggle / cell size
	ns.RogueDotGridRefresh = function()
		local cfg = ns.DB or AddUIDB
		THREAT_ONLY = not (cfg and cfg.rogueDotGridThreatOnly == false)

		local timerOn = not (cfg and cfg.rogueDotGridTimer == false)
		if timerOn ~= TIMER_ON then
			TIMER_ON = timerOn
			for _, cell in ipairs(allCells) do
				if cell.unit then UpdateTimer(cell) end -- toggle timer on active cells immediately
			end
		end

		local size = Clamp(tonumber(cfg and cfg.rogueDotGridCell) or 20, 8, 30)
		if size ~= CELL then
			CELL = size
			grid:SetSize(COLS * CELL + (COLS - 1) * GAP, ROWS * CELL + (ROWS - 1) * GAP)
			for _, cell in ipairs(allCells) do
				cell:SetSize(CELL, CELL)
				cell.index = nil -- size changed; recalculate all positions
				if cell.timerNum then
					cell.timerNum:SetFont(STANDARD_TEXT_FONT, TextH())
				end
			end
		end

		Refresh() -- rescan after any filter or size change
	end

	ns.event("PLAYER_SPECIALIZATION_CHANGED",        Apply) -- spec swap
	ns.event("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", Apply) -- active spec changed
	ns.event("NAME_PLATE_UNIT_ADDED",    QueueRefresh)
	ns.event("NAME_PLATE_UNIT_REMOVED",  QueueRefresh)
	ns.event("UNIT_THREAT_LIST_UPDATE",  QueueRefresh) -- threat gained / lost
	ns.event("PLAYER_ENTERING_WORLD",    Apply)

	Apply()
end)
