# ProEnchanters

Enchanting Assistance Add-On for players running enchanting services for other players.

If you find any issues feel free to join https://discord.gg/9CMhszeJfu and send a message in support.

## Update 10.6.5 Beta
- **Potential Fix** Issue where sometimes when a player puts an item into the trade window the trade window enchant buttons do not sort based on the 'slot' of the item in the window.
- The add-on (on Vanilla wow) will attempt to cache all equipable enchantable items into a new table that the trade window buttons will now use as a reference to avoid the issue where sometimes the trade window buttons won't sort to the proper slot. On first load you will get a message saying x amount of items need to cache. This should complete in about 30 seconds and the next time you launch wow/reload wow the message should not display anymore. If that message DOES display each time you load, please let me know.
- When you go to open and use the trade buttons if you get a message saying to do a "/pe cacheitems" please do so once, your game might freeze for a few seconds while it attempts to recache all the items but this may help get the remainder of the items cached if the initial cache did not work. So far in my testing I have not had to do a "/pe cacheitems".


## Update 10.6.3
- Pushing Message log function to release since it seems to be working without issue with all my testing, if you notice anything weird please let me know on discord
- Enabled the ability to have a "+" in your triggers again, you must add a % infront of the + to tell the addon to treat the + like plain text. 
- Example +4 str    // will trigger on +4 str, 4 str
- Example: %+4 str  // will trigger on +4 str, not on 4 str

## Update 10.6.2 - Beta
- Debugging option 66 added to test Trade button loading

## Update 10.6 - Beta
- **New** Message Log button
- Allows you to view a message history of hopefully relevant information. Logs messages from Say/Yell (if the player triggered an invite previously or is in the party), all Party(including yourself), all Raid (including yourself), and all received whispers. Also logs messages that triggered an invite popup/auto invite.
- You can open the message log via a player name to view all messages sent by that player after logging has started. If the player name in the customer focus box doesn't exist or is blank it will load the entire history that's available.
- Msg history is cleared on add-on load so doing a /reload or porting to another city or relaunching the game will wipe the chat history. I can consider changing this, just don't want to make it a cluttered mess for people.
- Closing a work order/All work orders clears the messages that were attached to the player in the open work orders. 
- The Refresh button on the message log window can be used if you changed the focused customer and want to view the new focused customers logs or if you clear the focused customer you can hit refresh to show all logs again
- Cleanse Logs will clear all logs not currently tied to an open work order (all invited from messages and your own party/raid messages included)
- If you run into an issue where you start getting errors try doing a "/pe msglogclear", this will wipe all the message log tables clean but you won't have to do a /reload this way at least

## Update 10.5
- **Changed** Added new pattern searching options to the 'Triggers' as well
- **New** Added Tooltips to the Filters and Triggers section that can give some helpful ideas of what a filter or trigger would do depending on new pattern searches.
- **Changed** Logic behind Item caching has been overhauled - the add-on will now try to cache the items based on the main windows enchanting/crafting display. IF you have Enchants showing it will try to cache all the reagents for enchanting, if you switch to crafting mode and go to Cooking it will try to cache all the reagents for Cooking, etc
- **Changed** The 'Filter' edit box between Enchanting mode and Crafting mode should keep it's text between switches.

## Update 10.4.3 - Beta
- **Changed** Filters encased in brackets can be preceeded or followed by words and wildcards as well (t*b[uc] would filter out 'thunder bluff to uc', 'tb -> uc' etc)

## Update 10.4.2 - Beta
- **New** Filters can now be encased in brackets ( example: [word] ) to make the search for that filter more specific when ruling out messages from potential customers. This helps with short filters like city abbreviations (sw, if, uc, org).
- You can also use '*' wildcards within the brackets to match all before, after, or between
- **Example** [sw] would now filter the following:
"lf sw enchanter"
"lf enchanter and port if->sw"
"lf enchanter and port if -> sw"
"sw -> if port and enchanter please"
"lf enchanter in sw."
"lf -->sw<-- enchanter"
- but not:
"lf swell enchant"
"lf enchanter named oswald"
"lfsw enchanter" (it's vulnerable to customers typos! argg!)
- **Example** [storm*wind] would now filter the following:
"lf enchanter in stormwind"
"lf enchanter in storm wind"
"lf enchanter in storm      wind"
"lf enchanter in storm------wind"
"lf enchanter in storm of the mighty wind"
- **New** Filters can also use *some* LUA pattern matching for those who are comfortable doing so, if a filter word contains "%", "^", or "$" it will enable that filter to use all LUA pattern matching with magic characters for advanced usage [99% of users will not find a use for this and I am considering disabling it entirely to avoid issues]
- **Example** storm%s+wind would now filter the following:
"lf enchanter in storm wind"
"lf enchanter in storm            wind"
- https://www.lua.org/manual/5.3/manual.html#6.4.1 for pattern infromation options
- This also means if you do **NOT** want to use pattern matching but want to filter out a specific message like %2 it must be set to %%2 instead as the first "%" tells the add-on to treat the second portion "%2" as plain text, if you enter only "%2" as a filter it will throw an error.
- 10.4.2 - fixed invites not being sent out

## Update 10.3.6 - Beta
- **Changed** Optimized trigger/filter logic some more, filters are now checked once per message instead of for each trigger word checked, also /pedebug 1/2/3 are all different options for printing out some logic results to the main window for troubleshooting (more info on that in discord)

## Update 10.3.5 - Beta
- **Fixed** 'Now trading with' message should be sent when trading players while 'work while closed' is toggled on
- **Changed** Trigger words no longer require a "+" sign to catch words like "+7 agi", setting your trigger as "7 agi" is enough
- **Changed** Order of trigger words should no longer matter again

## Update 10.3.3 & 10.3.4
- **Fixed** Potential customers getting filtered out if their name contained any of the filtered words (if players name was Thanos and a filter was set as 'no' it would filter out Thanos as if the full name Thanos was entered in the filters list)
- **Changed** Small optimizations done to potential customer logic

## Update 10.3.2
- **Fixed** Trim server name check box not reflecting the saved variable

## Update 10.3.1
- **Fixed** Sound options panel scroll bars overlapping slightly with the next set of buttons

## Update 10.3
- 10.2 update included in release version
- **Fixed** - Fitler edit box not clearing when 'Finish All Work Orders' is pushed
- **Changed** - Settings button logic updated, should toggle the Options frame open and close rather than only having the 'Close' button in the options frame as a way to close it and should handle all sub option frames at the same time
- **New** Filters/Triggers window now has a testing section where you can enter in a test player name and a test message and check to see if the add-on would accept or refuse the message as a potential customer

## Update 10.2
- **Potential Fix** for LUA errors when trade window opens and the WoW client has not cached the material item links yet

## Update 10.1
- **New** Cataclysm Support
- This only has limited tested currently by myself in Cata (I only have a level 1 character for very preliminary testing), please let me know in discord if you run into any issues during usage.
- The changes made for Cata should not have changed anything too much for the Vanilla flavours of WoW and I tested as much as I could myself but I was not able to complete actual enchants for players as part of the testing, if you run into issues while actually doing enchants or crafts please revert to the previous version for now.
- **10.1** Sync should work again

## Update 9.4.2
- **Updated** Potential customer logic updated to hopefully not randomly miss potential customers
- **Changed** /pedebug 1 will now print out the pass/fail text for when a potential customer is found, this can be used to troubleshoot your triggers and filters

## Update 9.4.1
- **Fixed** Work orders not populating to the top of the main window when previous ones were closed with the 'Finish All Work Orders' button

## Update 9.4
- **New** Craftables can be added/removed to favorites to display them in the list first, new way of handling favorites is just having the favorite icon act as the button (considering changing the main enchanting buttons to operate the same but I don't want to clutter the buttons)
- **New** Context menu now contains a "Focus Player" button that sets the player to your focused customer box, a lot of functions in the add-on require a players name to be in that box however you might not always want to create a work order for them so this is a solution for those situations
- **New** Option for the Pop Up invite box to set the 'Invite' button to only send the whisper "hey enchanter here" message and not actually invite the player

## Update 9.3.1
- **Fixed** Localizations for Craftables button mat linking (previously only worked on english)
- **Fixed** 'Info' icon showing and overlapping on Enchanting buttons when the enchant is un-synced
- **Changed** Logic behind Shift+Click to link mats of Craftable now uses same logic as the main Enchanting buttons (Check if Whisper Mats, if so -> Whisper/ If Not, Check if current focused customer is party member, if so -> party msg/ If Not, check if there IS a focused customer and if there is -> whisper/ else send message to party)
- **Removed** Alt + Left Click: Attempt to whisper
- **Added** Shift + Ctrl + Left Click: Attempts to whisper a message to the current focused customer with the Craftables name and required reagents

## Update 9.3
- **Changed** Craftbles buttons when sending party message/whisper for required reagents should now send as item links
- **New** If you have the Quantity box set to a number higher than one, the required reagents sent to the party will reflect this quantity set (quantity 1: 1x bolt of linen = 2x linen cloth // quantity 5: 5x bolt of linen = 10x linen cloth)
- **New** Info hover on main Enchanting window to display the enchants tooltip (must have tooltips enabled)
- **Changed** Logic behind sending the initial customer contact messages updated, should now only send the success/failed invite messages once, issue where failed to invite message sometimes doesn't send still needs to be investigated

## Update 9.2
- **Changed** Craftables Buttons can now be clicked with modifiers to perform new actions.
- Left Click: Sets the craftable to the craft button with the currently entered amount in the quantity box
- Shift+Left Click: Attempts to send a message to party (or whisper if you have forced whisper mats on) with the Craftables name and required reagents in plain text format
- Alt + Left Click: Attempts to whisper a message to the current focused customer with the Craftables name and required reagents in plain text format
- Right Click: Set the quantity to the maximum available and update the Craft button
- Shift + Right Click: Add +1 to the quantity box and update the Craft button
- Ctrl + Right Click: Remove -1 from the quantity box and update the Craft button
- Alt + Right Click: Set Quantity box to 1 and update the Craft button

## Update 9.1
- **New** Crafting Mode added, enabled by a checkbox above the Enchants on the right hand side of the main window.

## Update 9.0 Beta
- **New** Crafting Mode added, enabled by a checkbox above the Enchants on the right hand side of the main window.
- You *must* set the crafting amount first if you are doing more than 1 of the same craftable item before hitting the Craftable item button and then finally hitting the Craft button.
- Filters and options to come still to narrow down your craftable items and make it easier to navigate.
- There will most likely be some buttons where the text expands outside of the buttons bounds, I have not looked at optimizing this stuff yet but do plan on doing so at some point.

## Update 8.9.9
- **New** AFK Enchanting Mode (no this isnt a botting mode)
- You can now toggle '/peafkmode' which will alter your sound settings to be as optimal as possible for getting alerted to potential customers while you're alt tabbed or doing other things
- This sets all volume sliders to 0 except the Master Volume slider and it enables Sound In Background so that you'll get the alerts while alt tabbed
- If you do '/peafkmode' by itself it will set the master volume to 100 percent, you can also do a number after the command to choose a specific master volume like '/peafkmode 77' will set the master volume to 77 (for those that 100 is too loud for)
- Doing '/peafkmode' again will toggle it off and restore your sound settings to what they were before you enabled the afkmode
- **Changed** Added the line "|" symbol to the default filtered list as it looks like formating advertisements with | as a seperator has become more popular(example: Enchants: 6 agi gloves | 4 all stats | etc )
- This will only get added to new add-on installations, if you already have the addon installed I suggest adding the | yourself to the filters

## Update 8.9.7 and 8.9.8
- **Fixed** Bug fixes revolving around the new addon invited functionality, testing showed no issues anymore but if you find any LUA errors please let me know in the discord
- **Changed** Whisper invite keywords (when the customer whispers you 'inv') should no longer send the initial whisper contact message when the invite is sent or if the invite fails to send due to them being in a party

## Update 8.9.5 and 8.9.6
- **New and Changed** Added a 'Pause Invites' checkbox to the main window and the minimap button, this disables the invite pop ups/auto invites being sent out for potential customers, it does not stop whisper 'inv' messages. Modified the checkboxes on the main window to be smaller, shortened the text displayed by the checkboxes and added a tooltip when hovering the checkboxes to make it clear what each box is.
- **Changed** When a player is invited by the add-on and it fails and then the player whispers you an "inv" to join after the fact the add-on should not replace the 'invited by message' in the workorder with the 'inv' line anymore
- **Fixed** Players not being properly removed from the Temp Ignore and Filtered Words tables upon reloads doing the clear command.
- **Changed** The Party/Raid join welcome message can be set to send regardless of if the addon sent the invite or not. The Initial whisper sent for when a player would be invited to the party or if the invite fails is now only sent if the addon sent the message.

## Update 8.9.3 Beta and 8.9.4
- **Changed** Minimap button text for Auto Invite and Work While Closed will now update without having to re-hover the minimap button
- **New** Setting option for Hiding/Showing the minimap button (no longer have to do /pe minimap as the only way to get it back)
- **New** Work While Closed checkbox on the main window for ease of access
- **New** Ability to add players to a temporary ignore list for the current session -> Right click context menu or by '/peignore name', also a temp ignore button is now available on the pop-up if you are not using auto invites. Any action that reloads the addon like /reload or moving between zones that cause a loading screen will wipe the temporary ignore list. Can also use '/pe cleartempignores'
- **Changed** The way the add-on handles Add-on based invites versus manual invites has been changed to be more reliable for sending messages properly if you have the "Don't send messages on manual invites" setting turned on.

## Update 8.9.2
- **Fixed** Added check for raid assistant to new Party/Raid join welcome message so that it does not get sent if you are a raid assistant.

## Update 8.9.1
- **Changed** Party/Raid join welcome message will now only send if you are the party or raid leader (let me know if this is not working properly for raid, should be working for party but did not test for raid)
- **Fixed** On new add-on launches there was an issue with UI Color table creation

## Update 8.8
- **Fixed** UI colors when add-on is loaded for the first time were setting the wrong "Settings" background color causing UI navigation to be harder since things were the same color. The scroll bar color was also set to the same so I've brightened the scroll bar slightly so it stands out more to make it more apparent that you can scroll. Added a check when the add-on is launched to see if the Settings background or scroll bar color is set to "22" for the first value which was the wrong default and if so will set those to the proper defaults. Note - if you use a custom color setup and by some small chance use 22 as the first value for those two fields it will reset those colors, you can change it to either 21 or 23 to avoid this.

## Update 8.7
- **Fixed** Dependency issues (finally)
- **Fixed** Cleaned up Addon Load events to not spam the chat window on game launch
- **New** Added .toc files for TBC/Wrath/Cata/Retail, please note that although the addon will load on those flavors of wow the recipes are still vanilla based at the moment so beyond using the addon for auto inviting a lot of things will probably fail if you attempt to use it for actual enchanting.

## Update 8.6
- **Fixed** Blood of Heroes and Purple Lotus not being recognized by the addon should be fixed, if not please let me know

## Update 8.5.1
- **New** Phase 7 Enchants added for SoD
- **Potential Fix** Library issue with the addon not recognizing the LibSharedMedia library *should* be fixed, untested
- **Fixed** Greater Spellpower bracers changed to 16 (previously was wrongly showing as 12)

## Update 8.4
- **Changeed** Tooltips are now enabled by default for fresh installs and there is a message when tooltips are enabled and the add-on is first loaded for turning them off and usage.

## Update 8.3
- **Fixed** Max character limit set to 20 for customer name box (previously if you filled the text in a large amount like 50+ and hit an enchant button it would crash the client)

## Update 8.2
- **New** Checkbox to disable sending the 'Welcome Message' when a player joins the party from a manual invite. If you have players joining very quickly from the addon invites while manually inviting someone it may act a little funky and send the welcome message still but slightly out of place. Un-tested change, please let me know if there are any issues.

## Update 8.0.1
- **Changed** Default tip message now displays as g, s, c (example: 123g, 456s, 789c) instead your game clients language of Gold, Silver, Copper. This is more a change for those who use non-english versions of WoW and currently have their tip responses formatting as "12 Or, 10 Argent" etc. There is now a checkbox that lets you toggle this as well, by default it is on but by turning it off it will go back to the previous formatting of "Gold, Silver, Copper" in your game clients language. Fixed the tip showing a comma when its not neccesary

## Update 7.9
- **Changed** Added DropDown library to avoid taint with LFG blizzard function, re-enabled drop downs for filter section of enchants as well as raid icon selection

## Update 7.8
- **New** Added a new option to send the Party/Raid Join Welcome Message to the customer as a whisper instead of the party chat for instances when you have 5-6 players joining in a short time period and the chat gets spammed

## Update 7.7.1
- **New** Added a "recently whispered" control to party invites (successful and failed), this will avoid re-whispering the same player within a three minute period when enabled. Enabled by default, new setting in options to disable. This does not stop sending the invite, only the whisper.
- **New** Warning for potential whisper spamming. If you send more than 60 whispers through the invite feature in 5 minutes the add-on will alert you the next time you go to send another whisper. This is an average of 1 whisper per 5 seconds. Can disable this warning in settings.
- **Fixed 7.7.1** New settings options were overlapping, this should be fixed

## Update 7.6
- **New** Added World and Services as channels the add-on can watch for potential customers (This is un-tested, please let me know if there are any errors)

## Update 7.5
- **Changed** Re-ordered Enchants so that the new SoD recipes are considered the highest level enchants so that their buttons get sorted more intuitively
- With this change it will most likely break all your favorited enchants and you will have to re-add your favorites, sorry! This should be a one time thing as I have accounted for the need to add more enchants at later SoD versions or even iterations of classic, there are around 1000 available spots to add new enchants without causing another re-ordering

## Update 7.4
- **Fix** Included AceAddon libraries so that the addon runs standalone on fresh WoW clients, previously addon would only work if you had an addon that was also installed which also used the AceAddon libraries (most addons use this)

## Update 7.3.1
- **Ducktape Fix** Removed drop down menus (Sort by and Raid Icon selector) to avoid taint issues with SoD LFG until new UI drop down menus (Most likely ACE based) can be added

## Update 7.3
- **New** Season 6 of SoD recipes added

## Update 7.2.1
- **Small Fix** Added checkbox in settings to trim server name when sending an invite to a player, hopefully to work around any weird invite issues.

## Update 7.1 and 7.2
- **Added** Fixed and streamlined tooltips - thanks @Cynsible

## Update 7.0
- **Added** Context menus for all right clicks (chat, nameplates, self, etc) - thanks @Cynsible
- **Fixed** AutoInvite checkbox in settings not syncing with minimap toggle (should be fixed)
- **Modify** Changed tooltips for the Enchants window to hopefully change while hovering instead of having to re-hover

## Update 6.9.1
- **Fixed** Abiltiy to toggle auto invite on/off from minimap button
- **Fixed** Option to enable/disable "Escape closes main window", also attempted to make it no longer require a reload (not sure if this worked or not)
- **Modified** Formatting for tooltips to be less obnoxious and massive

## Update 6.9 (nice)
- **Added** Ability to toggle Auto Invite on/off from minimap button with Shift+Left Click
- **Added** Option to enable/disable "Escape closes main window" now in settings, requires a reload when toggled
- **Work in progress** Started work on adding tooltips, there is a checkbox within the main settings to enable/disable tooltips, disabled by default for now

## Update 6.8
- **Fixed (Hopefully)** Minimap button SHOULD NOW BE ABLE TO BE HIDDEN
- **Modified** When the add-on attempts to open a new work order while one is already created and it displays a yellow message in the chat it should now check if it has sent this warning already or not and if it has then it will not repeat the warning. This is untested.
- **New** Dangerous command "/peclearhistory" which will nuke the ProEnchantersTradeHistory table where all of the data of past trades are stored. You must do "/peclearhistory yes" to proceed, "/peclearhistory" by itself will only show a warning about the command.

## Update 6.7.5 and 6.7.6
- **New** Registered Minimap button through Ace3.0 so that it should interact better with other add-ons that manage minimap buttons
- **Fixed** Minimap button should now be able to be hidden with "/pe minimap" again as well as ctrl+left click on the icon

## Update 6.7.4
- **Fixed** Spell Power and Heal Power not working due to BLIZZARD ADDING A DOUBLE SPACE ON THEIR SIDE THANKS BLIZZARD THAT WAS HOURS WASTED ( FIX YOUR SHIT )
- **Fixed** Debug level not working between separated LUA files, debug level is now a savedvariable that should reset to 0 on UI reloads

## Update 6.7.1 and 6.7.2 and 6.7.3
- **New** Added a SavedVariable for the minimap button to persist between sessions
- **Fixed** grammar issue and debug printout issues

## Update 6.7
- **New** Ability to hide/show the minimap button by ctrl+leftclicking the button (hide only)
- **Fixed(Potentially)** Spell power Weapon and Heal power Weapon enchants not displaying the finished enchant within work orders
- **New** Can now "shift+control" click on Enchants within the enchants add-on window to force whisper to your current active work order instead of only having shift+click for linking and the add-on auto determining whether to whisper or not
- **Changed** Debug levels changed from 1/2/3 to 7/8/9 for the defaults for major debugging, free'd up 1-6 as a way to add temporary debugging specific things without having to enable the other more major debugging options at the same time

## Update 6.6.3.2
- **New** Ability to hide/show the minimap button with '/pe minimap' or by ctrl+leftclicking the button (hide only)

## Update 6.6.3.1
- **Modified** Context menus to fit WoW's new menu format instead of the old way it was handled. Untested, need community feedback for if it works or not.
- **Disabled Chat Context menu** it was causing the addon to fail to load it looks like.

## Update 6.6.2.1
- **Temporary Removal** Context menu "Create work order" had to be removed as WoW no longer allows 'hooksecurefunction' to add context menu items, added notes to the LUA section at line 339 about it but no fix yet

## Update 6.6.2

- **Changed:** When frames are minimized and get hidden, they will be maximized when unhidden.
- **Bugfix:** fixed an issue where the minimize function would not properly work when the work order frame was hidden minimized and shown again.

## Update 6.6.1

- **Changed:** added a reset button for the gold history display.
- **Bugfix** fixed an issue where the Enchants frame would not minimize properly.
- **Bugfix** fixed an issue where the Use All Mats button would not work properly. Due to variables moved to another file.

## Update 6.5.22

- **New:** Added a minimap button to open the main window (left click). You can right-click to toggle the "Work While Closed" option and Shift+Right click to reset the frame position and size.
- **Changed:** Little tweaks to how variables storage and sorting (Filter) work.

## Update 6.5.21

- **Added:** Law of Nature shield enchant for SoD phase 4.

## Update 6.5.1 & 6.5.2

- **Changed:** Version update for new WoW interface and added new supporters to credits.

## Update 6.5

- **New:** Ability to add a delay to Sent Invites and Sent Invite Messages, defaults are 0 so they are instant still.
- **Changed:** Essence conversion buttons now hide during the time-out period to be more intuitive that you cannot spam it when the essences are getting converted in the inventory and will re-show once the conversion finishes or fails (1.2 seconds).

## Update 6.4

- **Potentially Fixed:** When minimizing/maximizing the main window it should no longer nudge slightly based on mouse cursor's location. If you have any issues with this feature please let me know.

## Update 6.3

- **New:** Filters section above the Enchants now have a drop-down to sort by different types (Default sorts in a similar way to the default WoW Enchanting Crafting window which is level-based).
- **New:** Sound on trade start (disabled by default).
- **New:** Ability to enable/disable each specific sound type (Party join, Potential Customer, New Trade) in the sounds settings.

## Update 6.2

- **New:** **Favorite Enchants**. You can now add an enchant to the favorites list by Right Clicking on the enchant in the right-hand window. The favorited enchants will always appear at the top of the list.
- **Changed:** Modified size of the enchants window slightly by increasing horizontal size (extra 50 pixels), changed enchant button names to display as 2 lines instead of 3 to save space.

## Update 6.1

- **New:** Sound window for setting custom sounds. Available sounds are now loaded from the Share Media Library that common add-ons use (weakaura's as an example).
- **New:** Added 28 more sounds to choose from for Orc, Human, Druid, Dwarf, Trolls, Tauren, and a cyberpunk alert.

## Update 6.0

- **New:** Settings drop-down for selecting which custom sound plays, currently limited to the sounds added to Pro Enchanters but will look at adding all sounds in the shared media library in the future.

## Update 5.9

- **New:** Custom sound now plays when a player joins your party, this can be disabled through a new setting in the main settings area.
- **New:** Custom sound is registered to the Shared Media library most add-ons use and the sounds can be found as "Orc Work work" and "Orc I can do that" in other add-ons such as weakauras.
- **Fixed (hopefully):** Error where sometimes when a player would trade you the text in the trade window display would cause lua errors.

## Update 5.8

- **New:** Buttons for converting Essence's added, they will populate if the player has traded you an essence of that type. Please note this new feature is not well tested and if spam click it, it may act in unintended ways.

## Update 5.7

- **New:** Target button added to main window, targets whoever the current focused customer is.

## Update 5.6

- **Changed:** Added a "received" amount to the Mats Missing buttons so that players can see how many they've sent when you link them if they're still missing mats.
- **Changed:** Customer Name Button in text window below trade frame will now force open a work order and refresh the buttons to display if you are trading someone without the addon open.

## Update 5.5

- **Fixed:** Issue where the Checkbox for "Use All Mats" could cause a loading issue forcing no enchant buttons to show.

## Update 5.4

- **New:** Button in the trade window to announce all missing mats based on mats already traded and currently being offered in trade.
- **Changed:** !commands now work in party/raid/guild chat.
- **Updated:** Supporters list updated.

## Update 5.3

- **Changed:** The trade window text display that displays mats needed versus mats received now updates in real-time as mats are added to the trade window so you can tell before the trade finishes if they have put up the correct mats for the trade.
- **New:** Added slash command "/pe goldreset" this resets your current session's gold traded display back to 0.
- **Fixed:** Small visual issues where text in the add-on would not display until a /reload is done.

## Update 5.2

- **New:** Trade history now persists through sessions.
- **New:** Options area now includes a setting for picking which emote to use when thanking a customer, you can set it to blank or an invalid emote to disable.

## Update 5.1

- **New:** Custom Request button below the Enchants window. This button allows you to type a custom request into the work order for tracking purposes (may be useful for those one-off requests that are not enchanting related or to keep track of other info). You can ctrl+click the custom request's text to remove the custom request or you can shift+click it to send a message to the player to refresh their memory of what they had asked for.
- **Changed:** Localization for all WoW client languages for the potential customer alerts, invite messages, and welcome messages should all be working now, if you find any that do not work please let me know!

## Update 5.0

- **New:** There is now a running gold log that persists through sessions. You can access this gold log by hitting the Gold Traded display on the main window (this is now a button).
- **Added:** More localization to work towards enabling the Automessages.
- **Fixed again:** Localization issue with French for Dismantle enchant (myself and another have confirmed it's working now, this should be good... haha).

## Update 4.9.1

- **Fixed:** Localization issue with French for Dismantle enchant.

## Update 4.9

- **Changed:** The trade window enchant buttons will now immediately cast the enchant on the item in the tradeslot7 and will also accept the replace enchant button immediately, you no longer need to hover the item in this frame and click on it and then click on the accept popup if there is an overwrite.
- **Fixed (hopefully):** Localization issues with French and Spanish for using the enchants and syncing enchants.
- **Changed:** /pe reset will now also reset the main window's size in case it gets stuck in an infinitely scaled size.

## Update 4.8

- **Added:** Localization for the potential customer alerts for searching channels, previously if a message sent a chat in the "Trade - City" channel it would not trigger for French/German/etc as the channel names change based on language, it should now work regardless of the language of the local WoW client.
- **Added:** Ability to import/export your !command lists.
- **Updated:** Supporters list.

## Update 4.7

- **Changed:** How buttons are created in the trade screen to try and optimize when players are trading items to avoid frame skipping.
- **Fixed:** The All Req's button not allowing you to remove all enchants.

## Update 4.6

- **Changed:** Thank emote to only happy when there is a thank you message attached, clearing the thank you message from the settings will now also disable the emote.
- **Modified:** Color settings and separated many elements' colors into their own categories for more customization, also added an opacity changer for changing fields that have an opacity.
- **Added:** Ability to more finely select the channels you want to get potential customer alerts from.
