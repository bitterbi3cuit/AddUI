local _, ns = ...
ns.UpdateText = [[
|cff3cff00## 20261010|r
* Updated version number to 20261010
* Fixed an issue where mouse-through on region text was not working

|cff3cff00## 20261009.1|r
* Updated version number to 20261009.1
* Region text mouse-through optimization: tooltips that require manual dismissal retain full mouse interaction; only auto-dismissing tooltips pass through
* Fixed an issue where, with region text mouse-through enabled, popups with built-in CLOSE buttons (such as the scoreboard) could not be closed

|cff3cff00## 20261009|r
* Updated version number to 20261009
* Renamed the Assassination DOT grid setting to "Monitor only mobs in combat," with a note that this includes mobs currently fighting
* Fixed an issue where the cancel-aura button, raid frame defensive cooldowns, and self-buff aura countdown numbers would occasionally display very large values
* Expanded the Assassination DOT grid display range: in addition to mobs you have threat on, mobs currently in combat are also shown; mobs that disappear and lose threat while your DOT is still active will no longer be missed
* Increased the default Assassination DOT grid cell size from 15 to 20 for better visibility

|cff3cff00## 20261008|r
* Updated version number to 20261008
* The damage meter sub-window snap relationship is now automatically restored after a UI reload or login, so you no longer need to re-drag and align it each time
* Right-click menu WCL link: for instanced content (5-man / M+), clicking it directly shows the current season rating and damage rankings

|cff3cff00## 20261007|r
* Updated version number to 20261007
* Optimized bottom info bar gold display: rapid gold changes during trades or mailing no longer repeatedly rebuild the tooltip and text; unified Warband bank label coloring
* Fixed an issue where the Shaman Nature's Guardian countdown and Thunderstrike icon still appeared when the talent was not learned, and did not restore after unlearning and relearning the talent
* Added Shroud of the Wisp potion stealth and Supernatural Antidote to the raid frame damage-reduction monitor

|cff3cff00## 20261006|r
* Updated version number to 20261006
* Added WCL and Raider.IO character page links to the right-click menu for target / party / raid / friends / chat / guild / community / premade group — clicking opens a copyable-URL window that auto-closes; copy character name now copies the full name with realm; NPC right-click can also copy the name; both links can be individually disabled in settings

|cff3cff00## 20261005.1|r
* Updated version number to 20261005.1
* Bottom-right info bar gold tooltip now includes a same-account multi-character gold overview, listing each character's gold in class color with Warband bank and total shown; amounts display gold only, no silver or copper
* Optimized settings panel internals: color swatch buttons no longer re-declare local variables on creation; added comments for the tab-building callback

|cff3cff00## 20261005|r
* Updated version number to 20261005
* Added an Assassination Rogue exclusive DOT grid: scans nearby enemy nameplates and turns a cell red when both Garrote and Rupture are applied; supports monitoring only the threat list and a minimum remaining time countdown

|cff3cff00## 20261003|r
* Updated version number to 20261003
* Damage meter sub-window now supports drag-to-snap: reference lines show the target position while dragging, and the window automatically aligns to the edge of the previous window on release
* Added Shroud of Concealment spell ID to the damage-reduction monitor list

|cff3cff00## 20260930|r
* Updated version number to 20260930
* Fixed an issue where the icon in the notification message was displayed incorrectly when the Rogue set a Misdirection macro target


]]
