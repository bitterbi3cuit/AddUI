local _, ns = ...

-- ============================================================================
-- Shaman : Nature's Guardian (31616) 30s countdown + Thunder Claw (378076)
-- Locale-independent: every ability is referenced by spell ID, no localized
-- names anywhere. The only user-visible string is the Edit Mode label below.
-- Save as UTF-8 WITHOUT BOM, LF line endings.
-- ============================================================================

-- The class check runs inside PLAYER_LOGIN on purpose: UnitClass("player") can
-- still return nil at file-load time, which would silently disable the module.
ns.event("PLAYER_LOGIN", function()
	local _, cls = UnitClass("player")
	if cls ~= "SHAMAN" then return end
	if not (AddUIDB and AddUIDB.shamanGuardianCountdown) then return end

	local SpellID          = 31616  -- Nature's Guardian, trigger aura
	local DURATION         = 30     -- countdown length drawn for it
	local GUARDIAN_ID      = 30884  -- talent that gates the icon
	local MONITOR_ID       = 378076 -- Thunder Claw, displayed
	local KNOWN_ID         = 378075 -- Thunder Claw, learned-check
	local MONITOR_DURATION = 20     -- Thunder Claw cooldown

	local monitor -- forward declaration: AnchorToSelf resizes it later

	-- Reads the Edit Mode party-frame height (slider value, no render offset).
	-- Guarded so a not-yet-initialized EditModeManagerFrame cannot kill the addon.
	local function GetSize()
		local height = 36
		if EditModeManagerFrame and EditModeManagerFrame.GetRaidFrameHeight then
			height = EditModeManagerFrame:GetRaidFrameHeight(
				Enum.EditModeUnitFrameSystemIndices.Party, 36) or 36
		end
		return height / 1.8
	end

	-- holder is a pure anchoring container with no appearance of its own; the
	-- icons hang off it, so hiding the Nature's Guardian icon never affects
	-- Thunder Claw. Its parent starts as UIParent and is re-parented by
	-- AnchorToSelf (raid -> anchor, party -> party frame).
	local holder = CreateFrame("Frame", "AddUIClassShamanCountdown", UIParent)
	holder:SetSize(GetSize(), GetSize())

	-- Nature's Guardian icon (only shown while talent 30884 is known)
	local frame = CreateFrame("Frame", "AddUIClassShamanGuardianIcon", holder,
		"CooldownViewerBuffIconItemTemplate")
	frame:SetAllPoints(holder)

	-- Draggable anchor frame (UIParent). In a raid Nature's Guardian anchors
	-- here; size 40x40.
	local anchor = CreateFrame("Frame", "AddUIClassShamanAnchor", UIParent)
	anchor:SetSize(40, 40)
	anchor:SetPoint("LEFT", UIParent, "LEFT", 100, 0)
	ns.AddEdit(anchor, "Nature's Guardian") -- registered exactly once

	-- The party frame that is *you*, or nil when you are not in a party.
	-- Returning nil instead of member 1 is what makes the open-world fallback
	-- to `anchor` below actually reachable.
	local function FindSelfMember()
		if not CompactPartyFrame then return nil end
		for i = 1, 5 do
			local member = _G["CompactPartyFrameMember"..i]
			if member and member.unit == "player" then
				return member
			end
		end
		return nil
	end

	-- Re-anchors on every roster / zone change and re-reads the size, so Edit
	-- Mode changes apply without a /reload.
	local function AnchorToSelf()
		local size = GetSize()
		local target, tsize
		if IsInRaid() then
			target, tsize = anchor, 40
		else
			target = FindSelfMember()
			if target then
				tsize = size
			else
				target, tsize = anchor, 40 -- open world, no party
			end
		end

		holder:SetParent(target) -- parent follows the anchor target
		holder:ClearAllPoints()
		if IsInRaid() then
			-- raid: centred on the draggable frame
			holder:SetPoint("CENTER", target, "CENTER", 0, 0)
		else
			-- party / open world: to the left of the target
			holder:SetPoint("TOPRIGHT", target, "TOPLEFT", -1, 0)
		end
		holder:SetSize(tsize, tsize)

		frame.Cooldown:GetCountdownFontString():SetFont(
			STANDARD_TEXT_FONT, tsize*0.5, "OUTLINE")
		if frame.SAA then frame.SAA:SetSize(tsize * 1.4, tsize * 1.4) end
		if monitor then
			monitor:SetSize(tsize, tsize)
			monitor.Cooldown:GetCountdownFontString():SetFont(
				STANDARD_TEXT_FONT, tsize*0.4, "OUTLINE")
		end
	end

	ns.event("GROUP_ROSTER_UPDATE", AnchorToSelf)
	ns.event("PLAYER_ENTERING_WORLD", AnchorToSelf)

	local size = GetSize() -- initial layout only

	frame.DebuffBorder = nil -- drop the debuff border
	frame.Icon:SetTexture(136060) -- C_Spell.GetSpellTexture(SpellID)
	frame.Cooldown:SetReverse(false)
	frame.Cooldown:SetCountdownAbbrevThreshold(600)
	frame.Cooldown:GetCountdownFontString():SetFont(
		STANDARD_TEXT_FONT, size*0.5, "OUTLINE")

	-- flash on trigger
	frame.SAA = CreateFrame("Frame", nil, frame, "ActionButtonSpellAlertTemplate")
	frame.SAA:SetSize(size * 1.4, size * 1.4)
	frame.SAA:SetPoint("CENTER", frame, "CENTER", 0, 0)
	-- cyan-blue
	if frame.SAA.ProcStartFlipbook then frame.SAA.ProcStartFlipbook:SetVertexColor(0, 0.8, 1) end
	if frame.SAA.ProcLoopFlipbook then frame.SAA.ProcLoopFlipbook:SetVertexColor(0, 0.8, 1) end
	if frame.SAA.ProcAltGlow then frame.SAA.ProcAltGlow:SetVertexColor(0, 0.8, 1) end
	frame.SAA:Hide()

	-- Only the newest trigger owns the 5s animation window: previously an
	-- overlapping trigger had its flash cut short by the earlier timer.
	local flashGen = 0
	local function PlayFlash()
		if not frame.SAA then return end
		flashGen = flashGen + 1
		local gen = flashGen
		frame.SAA:Show()
		if frame.SAA.ProcStartAnim then frame.SAA.ProcStartAnim:Play() end
		C_Timer.After(5, function()
			if gen ~= flashGen then return end -- superseded by a newer trigger
			if frame.SAA then
				if frame.SAA.ProcStartAnim then frame.SAA.ProcStartAnim:Stop() end
				frame.SAA:Hide()
			end
		end)
	end

	-- the icon is shown only while the Nature's Guardian talent (30884) is known
	local function UpdateGuardianVisible()
		local known = C_SpellBook.IsSpellKnown(GUARDIAN_ID)
		frame:SetShown(known)
		if not known and frame.SAA then frame.SAA:Hide() end
	end
	-- talent/spec swaps are synchronous and the spellbook has not refreshed yet
	-- in that frame (IsSpellKnown still reads the old value), so re-check after
	local function GuardianTalentChanged()
		UpdateGuardianVisible()
		C_Timer.After(0.1, UpdateGuardianVisible)
	end
	ns.event("PLAYER_SPECIALIZATION_CHANGED", GuardianTalentChanged)
	ns.event("TRAIT_CONFIG_UPDATED", GuardianTalentChanged)
	UpdateGuardianVisible()

	ns.event("SPELL_UPDATE_COOLDOWN", function(event, spellID)
		if spellID ~= SpellID then return end
		frame.Cooldown:SetCooldown(GetTime(), DURATION)
		frame.Icon:SetDesaturated(true) -- desaturated after the trigger
		PlayFlash()
	end)

	-- clear the desaturation when the cooldown ends (stays shown, never hidden)
	frame.Cooldown:SetScript("OnCooldownDone", function()
		frame.Icon:SetDesaturated(false)
	end)

	-- Thunder Claw: monitors icon 378076 to the left of Nature's Guardian
	-- (learned-check via 378075, 20s cooldown). Parented to holder so it is
	-- independent of the Nature's Guardian icon's visibility.
	local function UpdateMonitor()
		local known = (AddUIDB and AddUIDB.shamanThunderClaw)
			and C_SpellBook.IsSpellKnown(KNOWN_ID)
		if not known then
			if monitor then monitor:Hide() end
			return
		end
		if not monitor then
			monitor = CreateFrame("Frame", "AddUIClassShamanMonitorIcon", holder,
				"CooldownViewerBuffIconItemTemplate")
			monitor:SetSize(GetSize(), GetSize())
			monitor:SetPoint("RIGHT", holder, "LEFT", 0, 0)
			monitor.DebuffBorder = nil -- drop the debuff border
			monitor.Icon:SetTexture(C_Spell.GetSpellTexture(MONITOR_ID))
			monitor.Cooldown:SetReverse(false)
			monitor.Cooldown:SetCountdownAbbrevThreshold(600)
			monitor.Cooldown:GetCountdownFontString():SetFont(
				STANDARD_TEXT_FONT, GetSize()*0.4, "OUTLINE")
			-- desaturated while on cooldown, restored when it ends
			monitor.Cooldown:SetScript("OnCooldownDone", function()
				monitor.Icon:SetDesaturated(false)
			end)
			ns.event("SPELL_UPDATE_COOLDOWN", function(event, spellID)
				if spellID ~= MONITOR_ID then return end
				monitor.Cooldown:SetCooldown(GetTime(), MONITOR_DURATION)
				monitor.Icon:SetDesaturated(true)
			end)
		end
		monitor:Show() -- must Show even when already created: re-learning restores it
	end
	-- same 0.1s re-check as above
	local function MonitorTalentChanged()
		UpdateMonitor()
		C_Timer.After(0.1, UpdateMonitor)
	end
	ns.event("PLAYER_SPECIALIZATION_CHANGED", MonitorTalentChanged)
	ns.event("TRAIT_CONFIG_UPDATED", MonitorTalentChanged)
	UpdateMonitor()
end)
