### ToDo's

- Add a way to 'test' filters and triggers

- Check into being able to swap work order sorting in the window from high to low
Add a button on the main window with a v^ type symbol to swap sorting order

- Create Enchants.lua's for each flavor of wow and localizations, modify .toc's to load proper version of enchants
Might be better to seperate localizations from general stuff (chat channels and messages) and enchants so that only enchant localizations need to be updated in each file
1. Way to do this: Use Craftables functions that gather mat names/spell names/etc and create a function that gathers and formats the 'CombinedEnchants' table in english once, create a function that pulls and populates the PELocalizations table for their current language, if language changes it can repopulate the new language that way, might be able to make ENCH9999 into ENCH13049 (spellid) as a way to link all tables again
2. Manually have to create the 'Convertables' table still most likely, we will see
3. ProEnchantersItemCacheTable needs all Enchanting Reagents
4. Tables to Replace: ProEnchantersItemCacheTable -> ProEnchantersTables.ItemCache, CombinedEnchants -> ProEnchantersTables.CombinedEnchants, PEConvertablesName, PEConvertablesId, PEenchantingLocales["Enchants"] = {	["ENCH100106"] = { ["Chinese"] = "附魔护腕

### ToDo's that need testing

### Done ToDo's

- Add ability to pause invites

- Add Alt flavors and .tocs
Vanilla, TBC, Wrath, Cata, Retail - done, need MoP?

- Fix the manual invite - no welcome msg whisper functions
Make a table where it records if a player was invited by the addon or manually
If not in table -> no welcome message if enabled
Need to change current table from an indexed player name to a name = typeofinvite, include customerinvite as a type, return on the CheckAddonInvite and if its a whisperinvite do not send the party invite/party invite failed messages

- Ignore Temporary Function
Add Temporary Add-on Ignore function, maybe an "Ignore for this session" type function
Add button to pop up for inviting the player with Add-on Ignore function
Add context menu Ignore for this session
Add Ignore for this session to other places like /pe *name* command or maybe even the addon window itself beside the 'target' button, clicking on -the button again could remove from temporary ignore
Addon start -> Set table as []
Temporary function -> When clicked, add player to a table with the recorded system time
Temporary function -> When clicked and player exists, remove from table
Chat_msg_system checks -> Add a check to go against the temporary ignore list -> search table for player, if found compare current time to saved -time -> ignore invite if criteria met
Add a way to check for players who are temporarily ignored, either a new window or just a /pe command printout
Add a /pe clear temporary ignore list command to avoid having to reload ui or relaunch client to wipe it clean
Add an option in settings to change the saved time, time in minutes maybe? Set to 0 to disable the ability to temporarily ignore or to keep -temporary ignore until new session?

- Add Minimap Setting Toggle in options
Self
