local _, ns = ...
ns.UpdateText = [[
|cff3cff00## 20261015|r
* Updated version and added support for 12.1.5
* Adapted to the appearance of the new action bar buttons and added compatibility for missing controls
* Adapted to the new action bar button animation style
* Adapted to the new action bar range indicators and macro text display
* Adjusted the width of the online-status dropdown in the friends list
* Fixed Shaman ability icons not refreshing after action bar initialization

|cff3cff00## 20261014|r
* Updated version number to 20261014
* When not the group leader, hide the "Your group is forming" cover over the premade-group application list, allowing applicants to be managed directly with right-click

|cff3cff00## 20261013.1|r
* Updated version number to 20261013.1
* Fixed right-click whisper and copy-name menus not appearing in the premade-group application list when not the leader or an assistant
* Fixed the Assassination Rogue DoT grid failing to initialize or display when logging in or reloading in restricted environments such as instances and Mythic+

|cff3cff00## 20261013|r
* Updated version number to 20261013
* Added Dwarf Stoneform and Mage Alter Time to the raid-frame damage-reduction monitor, and removed a false positive for shields distributed by Mass Barrier
* Added target markers and interrupted-spell icons to interrupt records; the Edit Mode preview now shows these as well
* Fixed the tank's name appearing white in parties (5-player dungeons and Mythic+) for the automatic macro-target setting for Misdirection/Tricks of the Trade

|cff3cff00## 20261010|r
* Updated version number to 20261010
* Fixed mouse clicks passing through area text incorrectly

|cff3cff00## 20261009.1|r
* Updated version number to 20261009.1
* Improved mouse click-through for area text: prompts that must be closed manually retain full mouse interaction; only prompts that disappear automatically allow clicks to pass through
* Fixed popups with built-in CLOSE buttons, such as the scoreboard, being impossible to close when area text allowed clicks to pass through

|cff3cff00## 20261009|r
* Updated version number to 20261009
* Renamed the Assassination DoT grid setting to "Only monitor enemies in combat" and clarified that it includes enemies currently in combat
* Fixed countdown numbers occasionally becoming abnormally large on cancel-aura buttons, raid-frame defensive abilities, and personal buff auras
* Expanded the Assassination DoT grid's display range: it now also shows enemies in combat, not just enemies you have threat on; prevents DoTs from disappearing when an enemy vanishes and clears threat while your DoT is still active
* Increased the Assassination DoT grid's default cell size from 15 to 20 for better visibility

|cff3cff00## 20261008|r
* Updated version number to 20261008
* Damage-meter window snapping is now restored automatically after reloading the UI or logging in, so you don't need to reposition it each time
* Right-click menu WCL links: opening an instance activity (5-player dungeon/Mythic+) now directly displays the current season's score and damage rankings

|cff3cff00## 20261007|r
* Updated version number to 20261007
* Improved gold display in the bottom information bar: frequent gold changes during trading or mailing no longer repeatedly rebuild the tooltip and text; also standardized Warband bank tab colors
* Fixed Shaman Nature's Guardian countdown and Thunderous Paws icon showing when the talents were not learned, and failing to return after switching talents, removing the talent, then learning it again
* Added the invisible effect of the Potion of Tranquilizing Winds and the Unnatural Anti-Venom to the raid-frame damage-reduction monitor

|cff3cff00## 20261006|r
* Updated version number to 20261006
* Added WCL and Raider.IO character-page links to the right-click menus for targets, parties, raids, friends, chat, guilds, communities, and premade groups. Links open in a window with a copyable address and close automatically; copying a character name now copies the full name with realm, and NPC names can also be copied by right-clicking. Each link can be disabled separately in settings


]]
