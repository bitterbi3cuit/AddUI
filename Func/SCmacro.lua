--Author: 简繁
local _,ns = ...

local ADCVAR,ADCVARCOPY

ns.event('CVAR_UPDATE', function(event, msg, a)
	if not ADCVAR then return end
	local _,defcvar = C_CVar.GetCVarInfo(msg)
	print(msg,a,"Default value:",defcvar) -- Print the specific changed CVar
	if not ADCVARCOPY then return end
	local text = 'SetCVar("'..msg..'", '..a..')'
	ChatFrame_OpenChat(text, SELECTED_DOCK_FRAME)
end)
SlashCmdList["PRINTCVAR"] = function(msg)
	ADCVAR = not ADCVAR
	if msg ~= "" and ADCVAR then
		ADCVARCOPY = ADCVAR
		print("|cff3cff00CVar printing and copying enabled")
	elseif ADCVAR then
		print("|cff3cff00CVar printing enabled")
	else
		ADCVARCOPY = ADCVAR
		print("|cffff5900CVar printing disabled")
	end
end
SLASH_PRINTCVAR1 = "/adc"

-- UI Automation
-- SCV: Backup original value + set CVar (only backs up on first call; add new entries here only)
local function SCV(name, value)
	if not AddUIDB.MYCVAR then AddUIDB.MYCVAR = {} end
	if AddUIDB.MYCVAR[name] == nil then
		AddUIDB.MYCVAR[name] = GetCVar(name)
	end
	C_CVar.SetCVar(name, value)
end
-- SCVS: Backup original value + set Settings (same as above)
local function SCVS(name, value)
	if not AddUIDB.MYCVAR then AddUIDB.MYCVAR = {} end
	if AddUIDB.MYCVAR[name] == nil then
		AddUIDB.MYCVAR[name] = tostring(Settings.GetValue(name))
	end
	Settings.SetValue(name, value)
end

local function uiconfig()

	-- Restore defaults
	-- InterfaceOptionsFrame_SetAllToDefaults()

-- General
SCV("UnitNamePlayerPVPTitle", 1)	-- Title
SCV("UnitNamePlayerGuild",1)		-- Guild name
SCV("UnitNameGuildTitle", 1)		-- Guild rank
SCV("chatStyle","im")				-- Chat style - instant messaging style: "classic", "im"
if AddUIDB.MYCVAR["C_Container.SetSortBagsRightToLeft"] == nil then AddUIDB.MYCVAR["C_Container.SetSortBagsRightToLeft"] = C_Container.GetSortBagsRightToLeft() end
C_Container.SetSortBagsRightToLeft(true)	-- Sort bags left-to-right; change to false for right-to-left
if AddUIDB.MYCVAR["C_Container.SetInsertItemsLeftToRight"] == nil then AddUIDB.MYCVAR["C_Container.SetInsertItemsLeftToRight"] = C_Container.GetInsertItemsLeftToRight() end
C_Container.SetInsertItemsLeftToRight(true)	-- New items go to the rightmost bag; change to false for leftmost
SCV("floatingCombatTextCombatDamageDirectionalScale_v2", 0) -- Damage numbers shown above health bar; change number 0-9
SCV("WorldTextScale_v2", 2)								-- Combat damage font size
SCV("floatingCombatTextCombatDamage_v2", 1)				-- Show damage numbers
SCV("floatingCombatTextCombatHealing_v2", 1)			-- Show healing numbers
SCV("enableFloatingCombatText",  0)						-- Scrolling combat text
SCV("floatingCombatTextFloatMode",  1)					-- Scroll direction
SCV("floatingCombatTextAuras", 0)  						-- Auras
SCV("floatingCombatTextComboPoints", 0) 				-- Combo points
SCV("floatingCombatTextEnergyGains", 0) 				-- Resource gains (mana, rage, energy, chi — different from combo points)
SCV("floatingCombatTextPeriodicEnergyGains", 0)   		-- Periodic energy gains
SCV("floatingCombatTextHonorGains", 1)   				-- Honorable kills
SCV("floatingCombatTextRepChanges", 0)   				-- Reputation changes
SCV("floatingCombatTextPetMeleeDamage", 1)   			-- Auto attacks
SCV("floatingCombatTextPetSpellDamage", 1)  			-- Abilities
SCV("floatingCombatTextCombatHealingAbsorbTarget", 1)	-- Shield/armor applied to target
SCV("floatingCombatTextCombatHealingAbsorbSelf", 1) 	-- Shield/armor applied to self
SCV("floatingCombatTextCombatDamageAllAutos", 1) 	  	-- Show all white damage
SCV("floatingCombatTextDodgeParryMiss", 1)   			-- Dodge/Parry/Miss
SCV("floatingCombatTextDamageReduction", 1)  			-- Damage reduction/resistance
SCV("floatingCombatTextCombatLogPeriodicSpells", 1) 	-- Periodic damage
SCV("floatingCombatTextReactives", 1)   				-- Spell alerts
SCV("floatingCombatTextSpellMechanics", 0)				-- Show crowd control effects on target (e.g. Entrap(xxxx-xxxx), silence, slow)
SCV("floatingCombatTextSpellMechanicsOther", 0)  		-- Show crowd control effects on other players
SCV("floatingCombatTextCombatState", 0)   				-- Enter/leave combat text notification
SCV("floatingCombatTextLowManaHealth", 0)   			-- Low MP/HP text notification
SCV("floatingCombatTextFriendlyHealers", 0)   			-- Friendly healer names

SCV("xpBarText", 1) -- Experience bar
SCV("statusText",1) -- Status text

-- Clock
	SCV("timeMgrAlarmEnabled",0) -- Disable clock alarm
	SCV("timeMgrUseMilitaryTime",1)	-- 24-hour mode
	SCV("timeMgrUseLocalTime",1)	-- Use local time

-- Controls
	SCV("deselectOnClick",0) -- Target lock
	SCV("autoDismountFlying",1) -- Auto dismount from flying
	SCV("autoClearAFK",1) -- Auto clear AFK status
	SCV("interactOnLeftClick",1) -- Left-click to interact
	SCV("lootUnderMouse",1) -- Open loot window at mouse position
	SCV("autoLootDefault",1) -- Auto loot
	SCV("combinedBags",1)	-- Combined bags
	-- Camera
	SCV("cameraWaterCollision",0) -- Water collision
	SCV("cameraSmoothStyle",0) -- Camera follow mode
	SCV("SoftTargetInteract",3) -- Enable interact key

-- Interface
	-- Display
	SCV("hideAdventureJournalAlerts","none")	-- Hide adventure guide alerts
	SCV("showTutorials",0)
	SCV("statusText",1) -- Status text
	SCV("statusTextDisplay","NUMERIC") -- Portrait status text format: "NUMERIC" value, "PERCENT" percentage, "BOTH" both
	SCV("chatBubbles",1)		-- Chat bubbles
	SCV("chatBubblesParty",1)	-- Party chat bubbles
	SCV("chatBubblesRaid",1)	-- Raid chat bubbles
	-- Raid frame configuration
	SCV("useCompactPartyFrames",1) -- Use raid-style party frames
	SCV("raidFramesDisplayPowerBars",1)		-- Show power bars
	SCV("raidFramesDisplayOnlyHealerPowerBars",0)	-- Show only healer power bars
	SCV("raidFramesDisplayIncomingHeals",1)		-- Incoming heals
	SCV("raidFramesDisplayAggroHighlight",1)	-- Highlight aggro target
	SCV("raidFramesDisplayClassColor",1)		-- Class colors
	SCV("raidOptionDisplayPets",0)				-- Show pets
	SCV("raidOptionDisplayMainTankAndAssist",0)	-- Main tank and main assist
	SCV("raidFramesDisplayDebuffs",1)			-- Show debuffs
	SCV("raidFramesDisplayLargerRoleSpecificDebuffs",1) -- Enlarge role-specific debuffs
	SCV("raidFramesDisplayOnlyDispellableDebuffs",0)	-- Show only dispellable debuffs
	SCV("raidFramesDisplayBigDefensive",1)		-- Center important defensive cooldowns
	SCV("raidFramesDispellndicatorType",2)		-- Dispellable debuff indicator type
	SCV("raidFramesDispellndicatorOverlay",0)	-- Dispellable debuff indicator color
	SCV("raidFramesHealthText","none")			-- Health text
	SCV("pvpFramesDisplayPowerBars",1)				-- Arena enemy frame power bars
	SCV("pvpFramesDisplayOnlyHealerPowerBars",0)	-- Arena enemy frame: show only healer power bars
	SCV("pvpFramesDisplayClassColor",1)				-- Arena enemy frame class colors

-- Action bars
	-- SHOW_MULTI_ACTIONBAR_1="1" -- Bottom-left action bar
	-- SHOW_MULTI_ACTIONBAR_2="0" -- Bottom-right action bar
	-- SHOW_MULTI_ACTIONBAR_3="1" -- Right side, right action bar
	-- SHOW_MULTI_ACTIONBAR_4="1" -- Right side, left action bar
	-- Show action bars 2-5
	-- local bar1, bar2, bar3, bar4, _, _, _ = GetActionBarToggles()
	-- if (not bar1 or not bar2 or not bar3 or not bar4) then
		-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_1", true)
		SCVS("PROXY_SHOW_ACTIONBAR_2", true)
		SCVS("PROXY_SHOW_ACTIONBAR_3", false)
		SCVS("PROXY_SHOW_ACTIONBAR_4", true)
		SCVS("PROXY_SHOW_ACTIONBAR_5", true)
		SCVS("PROXY_SHOW_ACTIONBAR_6", false)
		SCVS("PROXY_SHOW_ACTIONBAR_7", false)
		SCVS("PROXY_SHOW_ACTIONBAR_8", false)
	-- end
	-- Refresh action bars
	-- MultiActionBar_Update()
	-- StatusTrackingBarManager:UpdateBarTicks()
	-- EventRegistry:TriggerEvent("ActionBarShownSettingUpdated")

	SCV("lockActionBars",1)			-- Lock action bars
	SCV("alwaysShowActionBars",1)	-- Always show action bars
	SCV("countdownForCooldowns",1)	-- Show cooldown countdown

-- Combat
	SCV("nameplateShowSelf",1) -- Show personal resource display
	SCV("nameplateResourceOnTarget",0) -- Show player resource on enemy target
	SCV("showTargetOfTarget",1) -- Target of target
	SCV("doNotFlashLowHealthWarning",1) -- Don't flash screen at low health
	SCV("lossOfControl",1) -- Loss of control alerts
	SCV("enableFloatingCombatText",  0)	-- Scrolling combat text
	SCV("enableMouseoverCast", 1) -- Mouseover casting
	SCV("autoSelfCast",1) -- Auto self-cast

-- Social
	SCV("profanityFilter",0) -- Profanity filter
	SCV("spamFilter",0) -- Spam filter
	SCV("guildMemberNotify",0) -- Guild member notifications
	SCV("showToastBroadcast",1) -- Broadcast updates
	SCV("showToastWindow",0) -- Show toast window
	SCV("showTimestamps","none") -- Chat timestamps
	SCV("whisperMode","inline")	-- New whisper mode

-- Pings
	SCV("enablePings",1) -- Enable pings

-- Game Enhancements
	SCV("combatWarningsEnabled",1)				-- Boss alerts
	SCV("encounterWarningsEnabled",1)			-- Text alerts
	SCV("encounterTimelineEnabled",1)			-- Boss timeline
	SCV("encounterTimelinelocnographyEnabled",1)-- Spell assist icons
	SCV("cooldownViewerEnabled",1)				-- Cooldown tracker
	SCV("externalDefensivesEnabled",1)			-- External defensive cooldowns
	SCV("damageMeterEnabled", 1)				-- Damage meter
	SCV("spellDiminishPVPEnemiesEnabled",1)		-- Diminishing returns tracker

-- Nameplates
	SCV("UnitNameOwn",1) -- My own name
	SCV("UnitNameFriendlySpecialNPCName", 0)
	SCV("UnitNameHostleNPC", 0)
	SCV("UnitNameInteractiveNPC", 0)
	SCV("UnitNameNPC", 1)
	SCV("ShowQuestUnitCircles", 1)
	SCV("UnitNameNonCombatCreatureName",1) -- Critters and companions
	SCV("UnitNameFriendlyPlayerName",1) -- Friendly player names
	SCV("UnitNameFriendlyMinionName",0) -- Friendly player minion names
	SCV("UnitNameEnemyPlayerName",1) -- Enemy player names
	SCV("UnitNameEnemyMinionName",1) -- Enemy player minion names
	SCV("nameplateShowFriends",0) -- Friendly player health bars
	SCV("nameplateShowFriendlyMinions",0) -- Friendly player minion health bars
	SCV("nameplateShowEnemies",1) -- Enemy player health bars
	SCV("nameplateShowEnemyMinions",1) -- Enemy player minion health bars
	SCV("nameplateShowEnemyMinus",1) -- Enemy player trivial health bars
	SCV("nameplateShowAll",1) -- Show all nameplates
	SCV("nameplateShowFriendlyNpcs",1) -- Friendly NPC nameplates
	SCV("nameplateShowOffscreen",1) -- Off-screen nameplates
	SCV("nameplateInfoDisplay","D") -- Nameplate info display
	SCV("nameplateCastBarDisplay","O") -- Cast bar display
	SCV("nameplateThreatDisplay","B") -- Threat display
	SCV("nameplateEnemyNpcAuraDisplay","G") -- Enemy NPC debuff display
	SCV("nameplateEnemyPlayerAuraDisplay","G") -- Enemy player debuff display
	SCV("nameplateFriendlyPlayerAuraDisplay","G") -- Friendly player debuff display
	SCV("nameplateSimplifiedTypes","") -- Simplified nameplates

	-- NamePlateDriverFrame:UpdateNamePlateOptions()

-- Miscellaneous
	SCV("WorldTextMinSize",12)				-- Name font size
	SCV("CameraKeepCharacterCentered",0)	-- Dynamic camera centering
	SCV("CameraReduceUnexpectedMovement",1)	-- Reduce unexpected camera movement
	SCV("ShakeStrengthCamera",0)			-- Camera shake
	SCV("ShakeStrengthUI",0)				-- UI shake
	SCV("empowerTapControls",1)				-- Empowered spell tap controls
	SCV("spellActivationOverlayOpacity",0.6) -- Spell alert overlay opacity

-- Color blind mode
	SCV("colorblindMode",0)

-- Accessibility
	SCV("speechToText",0)		-- Speech to text
	SCV("textToSpeech",0)		-- Text to speech
	SCV("remoteTextToSpeech",0)	-- Speak for me in voice chat

-- Mounts
	SCV("motionSicknessLandscapeDarkening",0)		-- Motion sickness darkening
	SCV("DisableAdvancedFlyingFullScreenEffects",1)	-- Dynamic flying fullscreen effects
	SCV("DisableAdvancedFlyingVelocityVFX",1)		-- Dynamic flying velocity effects
	SCV("advFlyPitchControl",3)						-- Pitch control
	SCV("advFlyPitchControlGroundDebounce",1)		-- Pitch input debounce

-- System
-- Graphics
	SCV("useUiScale", 1)	-- Enable UI scaling
	SCV("uiScale", 0.75)	-- UI scale
	SCV("cameraFov", 90)	-- Camera field of view

-- Audio
	SCV("Sound_MasterVolume", 0.3)		-- Master volume
	SCV("Sound_MusicVolume", 0)			-- Music
	SCV("Sound_SFXVolume", 0.25)		-- Sound effects
	SCV("Sound_AmbienceVolume", 0.1)	-- Ambient sounds
	SCV("Sound_DialogVolume", 0.5)		-- Dialog
	SCV("Sound_EnableErrorSpeech", 0)	-- Error speech
	SCV("Sound_EnableSoundWhenGameIsInBG", 1) -- Play sound when game is in background

print("|cff00BFFFAddUI:|r UI configuration applied. Use /sdold to restore previous settings.")
end
-- SetCVar("",)

-- UI automation commands
SlashCmdList["UICONFIGG"] = function() uiconfig() end
SLASH_UICONFIGG1 = "/sd"
SLASH_UICONFIGG2 = "/sdd"

-- Restore CVars from backup
local function restoreCVar()
	if not AddUIDB.MYCVAR or not next(AddUIDB.MYCVAR) then
		print("|cffff5900No saved CVar backup found")
		return
	end
	local count = 0
	for name, value in pairs(AddUIDB.MYCVAR) do
		if name:find("^PROXY_") then
			-- Settings value — convert back to boolean
			local boolVal = value == "true" or value == "1"
			Settings.SetValue(name, boolVal)
		elseif name:find("^C_Container") then
			-- C_Container method call
			local method = name:match("%.([^.]+)$")
			if method and C_Container[method] then
				C_Container[method](value)
			end
		else
			C_CVar.SetCVar(name, value)
		end
		count = count + 1
	end
	print("|cff00BFFFAddUI:|r Restored "..count.." CVar settings")
end
SlashCmdList["RESTORECVAR"] = function() restoreCVar() end
SLASH_RESTORECVAR1 = "/sdold"

-- Select edit mode layout 3
SlashCmdList["EDITMODE"] = function()
	EditModeManagerFrame:SelectLayout(3)
end
SLASH_EDITMODE1 = "/ed"
SLASH_EDITMODE2 = "/edd"

-- Reset default keybindings
local function Bindings()
	LoadBindings(DEFAULT_BINDINGS)
	SaveBindings(1)
	-- Set a few specific defaults
	SetBinding("F12","REPLY")
	SetBinding("F11","REPLY2")
	SetBinding("F9","TOGGLEAUTORUN")
	SetBinding("A","STRAFELEFT")
	SetBinding("D","STRAFERIGHT")
end

-- Delete all macros
local function UIcfg()
	for i = 1,9999 do
		local t=10000-i
		DeleteMacro(t) -- Delete all macros
	end
end

-- Delete macros and reset keybindings dialog
StaticPopupDialogs.SC_MACRO = {
	text = "Are you sure you want to delete all macros and reset default keybindings?",
	button1 = ACCEPT,
	button2 = CANCEL,
	-- Function calls
	OnAccept = function() Bindings(); UIcfg() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = true,
	preferredIndex = 5,
}
-- Slash commands
SLASH_SCMACRO1 = "/sc"
SLASH_SCMACRO2 = "/SC"
SlashCmdList["SCMACRO"] = function()
	StaticPopup_Show("SC_MACRO")
end

-- Delete macros only dialog
StaticPopupDialogs.SH_MACROO = {
	text = "Are you sure you want to delete all macros?",
	button1 = ACCEPT,
	button2 = CANCEL,
	-- Function calls
	OnAccept = function() UIcfg() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = true,
	preferredIndex = 5,
}
-- Slash commands
SLASH_SHMACROO1 = "/sh"
SLASH_SHMACROO2 = "/SH"
SlashCmdList["SHMACROO"] = function()
	StaticPopup_Show("SH_MACROO")
end
