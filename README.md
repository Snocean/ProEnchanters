# ProEnchanters

Enchanting Assistance Add-On for players running enchanting services for other players.

If you find any issues feel free to join https://discord.gg/9CMhszeJfu and send a message in support.

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
