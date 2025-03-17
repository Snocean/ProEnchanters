### ToDo

# Add Minimap Setting Toggle in options - Done
Self

# Ignore Temporary Function - Done
-Add Temporary Add-on Ignore function, maybe an "Ignore for this session" type function
-Add button to pop up for inviting the player with Add-on Ignore function
-Add context menu Ignore for this session
-Add Ignore for this session to other places like /pe *name* command or maybe even the addon window itself beside the 'target' button, clicking on -the button again could remove from temporary ignore
-Addon start -> Set table as []
-Temporary function -> When clicked, add player to a table with the recorded system time
-Temporary function -> When clicked and player exists, remove from table
-Chat_msg_system checks -> Add a check to go against the temporary ignore list -> search table for player, if found compare current time to saved -time -> ignore invite if criteria met
-Add a way to check for players who are temporarily ignored, either a new window or just a /pe command printout
-Add a /pe clear temporary ignore list command to avoid having to reload ui or relaunch client to wipe it clean
-Add an option in settings to change the saved time, time in minutes maybe? Set to 0 to disable the ability to temporarily ignore or to keep -temporary ignore until new session?

# Check into being able to swap work order sorting in the window from high to low
Add a button on the main window with a v^ type symbol to swap sorting order

# Fix the manual invite - no welcome msg whisper functions - done
Make a table where it records if a player was invited by the addon or manually
If not in table -> no welcome message if enabled
Need to change current table from an indexed player name to a name = typeofinvite, include customerinvite as a type, return on the CheckAddonInvite and if its a whisperinvite do not send the party invite/party invite failed messages

# Add Alt flavors and .tocs - done
Vanilla, TBC, Wrath, Cata, Retail - done, need MoP?

# Add to Enchants.lua a tag for flavor of wow
Add ability to change enchants loaded into addon based on flavor of wow
Maybe create new helper/enchants.lua files for each flavor of wow to keep things separate, can set which ones to load in toc and keep all tables named the same

# Add ability to pause invites - done