# ProEncahters

Enchanting Assistance Add-On for players running enchanting services for other players.

If you find any issues feel free to join https://discord.gg/9CMhszeJfu and send a message in support.

## Update 6.5.21
-Added: Law of Nature shield enchant for SoD phase 4

## Update 6.5.1 & 6.5.2
-Changed: Version update for new wow interface and added new supporters to credits

## Update 6.5
-New: Ability to add a delay to Sent Invites and Sent Invite Messages, defaults are 0 so they are instant still.
-Changed: Essence conversion buttons now hide during the time-out period to be more intuitive that you cannot spam it when the essences are getting converted in the inventory and will re-show once the conversion finishes or fails (1.2 seconds)

## Update 6.4
-Potentially Fixed: When minimizing/maximizing the main window it should no longer nudge slightly based on mouse cursors location. If you have any issues with this feature please let me know.

## Update 6.3
-New: Filters section above the Enchants now have a drop down to sort by different types (Default sorts in a similar way to the default WoW Enchanting Crafting window which is level based)
-New: Sound on trade start (disabled by default)
-New: Ability to enable/disable each specific sound type (Party join, Potential Customer, New Trade) in the sounds settings.

## Update 6.2
-New: **Favorite Enchants**, You can now add an enchant to the favorites list by Right Clicking on the enchant in the right hand window. The favorited enchants will always appear at the top of the list.
-Changed: Modified size of the enchants window slightly by increasing horizontal size (extra 50 pixels), changed enchant button names to display as 2 lines instead of 3 to save space

## Update 6.1
-New: Sound window for setting custom sounds. Available sounds are now loaded from the Share Media Library that common add-ons use (weakaura's as an example)
-New: Added 28 more sounds to choose from for Orc, Human, Druid, Dwarf, Trolls, Tauren, and a cyberpunk alert

## Update 6.0
-New: Settings drop down for selecting which custom sound plays, currently limited to the sounds added to Pro Enchanters but will look at adding all sounds in the shared media library in the future

## Update 5.9
-New: Custom sound now plays when a player joins your party, this can be disabled through a new setting in the main settings area.
-New: Custom sound is registered to the Shared Media library most add-ons use and the sounds can be found as "Orc Work work" and "Orc I can do that" in other add-ons such as weakauras.
-Fixed (hopefully): Error where sometimes when a player would trade you the text in the trade window display would cause lua errors.

## Update 5.8
-New: Buttons for converting Essence's added, they will populate if the player has traded you an essence of that type. Please note this new feature is not well tested and if spam click it, it may act in unintended ways.

## Update 5.7
-New: Target button added to main window, targets whoever the current focused customer is

## Update 5.6
-Changed: Added a "received" amount to the Mats Missing buttons so that players can see how many they've sent when you link them if they're still missing mats.
-Changed: Customer Name Button in text window below trade frame will now force open a work order and refresh the buttons to display if you are trading someone without the addon open

## Update 5.5
-Fixed: Issue where the Checkbox for "Use All Mats" could cause a loading issue forcing no enchant buttons to show.

## Update 5.4
-New: Button in the trade window to announce all missing mats based on mats already traded and currently being offered in trade
-Changed: !commands now work in party/raid/guild chat
-Updated: Supporters list updated

## Update 5.3
-Changed: The trade window text display that displayes mats needed verse mats received now updates in real time as mats are added to the trade window so you can tell before the trade finishes if they have put up the correct mats for the trade
-New: Added slash command "/pe goldreset" this resets your current sessions gold traded display back to 0
-Fixed: Small visual issues where text in the add-on would not display until a /reload is done

## Update 5.2
-New: Trade history now persists through sessions
-New: Options area now includes a setting for picking which emote to use when thanking a customer, you can set it to blank or an invalid emote to disable

## Update 5.1
-New: Custom Request button below the Enchants window. This button allows you to type a custom request into the work order for tracking purposes (may be useful for those one off requests that are not enchanting related or to keep track of other info)
You can ctrl+click the custom requests text to remove the custom request or you can shift+click it to send a message to the player to refresh their memory of what they had asked for.
-Changed: Localization for all WoW client languages for the potential customer alerts, invite messages, and welcome messages should all be working now, if you find any that do not work please let me know!

## Update 5.0
-New: There is now a running gold log that persists through sessions. You can access this gold log by hitting the Gold Traded display on the main window (this is now a button)
-Added more localization to work towards enabling the Automessages
-Fixed again: Localization issue with French for Dismantle enchant (myself and another have confirmed it's working now, this should be good... haha)


## Update 4.9.1
-Fixed: Localization issue with French for Dismantle enchant

## Update 4.9
-Changed: The trade window enchant buttons will now immediately cast the enchant on the item in the tradeslot7 and will also accept the replace enchant button immediately, you no longer need to hover the item in this frame and click on it and then click on the accept popup if there is an overwrite.
-Fixed(hopefully): Localization issues with french and spanish for using the enchants and syncing enchants
-Changed: /pe reset will now also reset the main windows size incase it gets stuck in an infinitely scaled size

## Update 4.8
-Added localization for the potential customer alerts for searching channels, previously if a message sent a chat in the "Trade - City" channel it would not trigger for french/german/etc as the channel names change based on language, it should not work regardless of the language of the local wow client
-Added ability to import/export your !command lists
-Updated supporters list

## Update 4.7
-Changed how buttons are created in the trade screen to try and optimize when players are trading items to avoid frame skipping
-Fixed the All Req's button not allowing you to remove all enchants

## Update 4.6
-Changed Thank emote to only happy when there is a thank you message attached, clearing the thank you message from the settings will now also disable the emote
-Modified color settings and separated many elements colors into their own categories for more customization, also added an opacity changer for changing fields that have an opacity
-Added ability to more finely select the channels you want to get potential customer alerts from
