local I = require("openmw.interfaces")


I.Settings.registerPage {
     key = "SettingsDebugMode",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug -  Main",
     description = "SettingsDebugMode"
}
I.Settings.registerPage {
     key = "SettingsDebugModePC",
     l10n = "SettingsDebugModePC",
     name = "ZackUtils Debug - Auto",
     description = "The settings on this page allow you to automatically run commands in given contexts."
}
I.Settings.registerGroup {
     key = "SettingsDebugModePCG",
     page = "SettingsDebugModePC",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug - Global Context Settings",
     description = "Each line below will be ran as a command when the console enters global context.",
     permanentStorage = true,
     settings = {

          {
               key = "runLine1",
               renderer = "textLine",
               name = "Line to run for Player 1",
               description = "Automatically run this command when switching to Global",
               default = ""
          },
          {
               key = "runLine2",
               renderer = "textLine",
               name = "Line to run for Player 2",
               description = "Automatically run this command when switching to Global",
               default = ""
          },
          {
               key = "runLine3",
               renderer = "textLine",
               name = "Line to run for Player 3",
               description = "Automatically run this command when switching to Global",
               default = ""
          },
          {
               key = "runLine4",
               renderer = "textLine",
               name = "Line to run for Player 4",
               description = "Automatically run this command when switching to Global",
               default = ""
          },
          {
               key = "runLine5",
               renderer = "textLine",
               name = "Line to run for Player 5",
               description = "Automatically run this command when switching to Global",
               default = ""
          },
          {
               key = "runLine6",
               renderer = "textLine",
               name = "Line to run for Player 6",
               description = "Automatically run this command when switching to Global",
               default = ""
          },
     },

}
I.Settings.registerGroup {
     key = "SettingsDebugModePCStartEq",
     page = "SettingsDebugModePC",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug - Game Start Items",
     description =
     "Items listed here will be provided to the player when games are started. If you would like multiple counts of the item, add a , and a number after the ID. If these items are detected as equipment, they will automatically be equipped.",
     permanentStorage = true,
     settings = {

          {
               key = "ItemID1",
               renderer = "textLine",
               name = "Item 1",
               description = "This item will be provided when the game starts",
               default = ""
          },
          {
               key = "ItemID2",
               renderer = "textLine",
               name = "Item 2",
               description = "This item will be provided when the game starts",
               default = ""
          },
          {
               key = "ItemID3",
               renderer = "textLine",
               name = "Item 3",
               description = "This item will be provided when the game starts",
               default = ""
          },
          {
               key = "ItemID4",
               renderer = "textLine",
               name = "Item 4",
               description = "This item will be provided when the game starts",
               default = ""
          },
          {
               key = "ItemID5",
               renderer = "textLine",
               name = "Item 5",
               description = "This item will be provided when the game starts",
               default = ""
          },
          {
               key = "ItemID6",
               renderer = "textLine",
               name = "Item 6",
               description = "This item will be provided when the game starts",
               default = ""
          },
     },

}
I.Settings.registerGroup {
     key = "SettingsDebugModePCStart",
     page = "SettingsDebugModePC",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug - Game Start Commands",
     description = "These commands are ran in player context when the game starts.",
     permanentStorage = true,
     settings = {

          {
               key = "runLine1",
               renderer = "textLine",
               name = "Line 1",
               description = "Automatically run this command when starting the game",
               default = ""
          },
          {
               key = "runLine2",
               renderer = "textLine",
               name = "Line 2",
               description = "Automatically run this command when starting the game",
               default = ""
          },
          {
               key = "runLine3",
               renderer = "textLine",
               name = "Line 3",
               description = "Automatically run this command when starting the game",
               default = ""
          },
          {
               key = "runLine4",
               renderer = "textLine",
               name = "Line 4",
               description = "Automatically run this command when starting the game",
               default = ""
          },
          {
               key = "runLine5",
               renderer = "textLine",
               name = "Line 5",
               description = "Automatically run this command when starting the game",
               default = ""
          },
          {
               key = "runLine6",
               renderer = "textLine",
               name = "Line 6",
               description = "Automatically run this command when starting the game",
               default = ""
          },
     },

}
I.Settings.registerGroup {
     key = "SettingsDebugModePCHotKeys",
     page = "SettingsDebugModePC",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug - Keybound Commands",
     description =
     "The commands listed here will be ran when you press the given letter or number. Enter the letter or number you want to bind, then a ',' followed by the command you'd like to run",
     permanentStorage = true,
     settings = {

          {
               key = "runLine1",
               renderer = "textLine",
               name = "Keybound command 1",
               description = "Automatically run this command when the given key is pressed.",
               default = "p,coc balmora"
          },
          {
               key = "runLine2",
               renderer = "textLine",
               name = "Keybound command 2",
               description = "Automatically run this command when the given key is pressed.",
               default = ""
          },
          {
               key = "runLine3",
               renderer = "textLine",
               name = "Keybound command 3",
               description = "Automatically run this command when the given key is pressed.",
               default = ""
          },
          {
               key = "runLine4",
               renderer = "textLine",
               name = "Keybound command 4",
               description = "Automatically run this command when the given key is pressed.",
               default = ""
          },
          {
               key = "runLine5",
               renderer = "textLine",
               name = "Keybound command 5",
               description = "Automatically run this command when the given key is pressed.",
               default = ""
          },
          {
               key = "runLine6",
               renderer = "textLine",
               name = "Keybound command 6",
               description = "Automatically run this command when the given key is pressed.",
               default = ""
          },
     },

}
I.Settings.registerGroup {
     key = "SettingsDebugModePC",
     page = "SettingsDebugModePC",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug - Player Context Settings",
     description = "Each line below will be ran as a command when the console enters player context.",
     permanentStorage = true,
     settings = {

          {
               key = "runLine1",
               renderer = "textLine",
               name = "Line to run for Player 1",
               description = "Automatically run this command when switching to player",
               default = ""
          },
          {
               key = "runLine2",
               renderer = "textLine",
               name = "Line to run for Player 2",
               description = "Automatically run this command when switching to player",
               default = ""
          },
          {
               key = "runLine3",
               renderer = "textLine",
               name = "Line to run for Player 3",
               description = "Automatically run this command when switching to player",
               default = ""
          },
          {
               key = "runLine4",
               renderer = "textLine",
               name = "Line to run for Player 4",
               description = "Automatically run this command when switching to player",
               default = ""
          },
          {
               key = "runLine5",
               renderer = "textLine",
               name = "Line to run for Player 5",
               description = "Automatically run this command when switching to player",
               default = ""
          },
          {
               key = "runLine6",
               renderer = "textLine",
               name = "Line to run for Player 6",
               description = "Automatically run this command when switching to player",
               default = ""
          },
     },

}
I.Settings.registerGroup {
     key = "SettingsDebugMode",
     page = "SettingsDebugMode",
     l10n = "SettingsDebugMode",
     name = "ZackUtils Debug - Main",
     description = "My Group Description",
     permanentStorage = true,
     settings = { {
          key = "defaultContext",
          renderer = "select",
          l10n = "XXXX",
          name = "Default Context",
          default = "MWScript",
          argument = {
               disabled = false,
               l10n = "XXXX",
               items = { "MWScript", "Player", "Global" },
          },
     },
          {
               key = "EnableSafeguard",
               renderer = "checkbox",
               name = "Enable Safeguard",
               description =
               "When turned on, potentially destructive commands will be prevented from running when a non-testing game is detected.",
               default = true
          },
          {
               key = "EnableMusic",
               renderer = "checkbox",
               name = "Enable Music",
               description =
               "When turned off, music will be prevented from playing.",
               default = true
          },
          {
               key = "CheckForTruetypeFonts",
               renderer = "checkbox",
               name = "Enable Truetype",
               description =
               "When turned on, you will recieve a message on loading if truetype fonts are not used.",
               default = true
          },
          {
               key = "EnableSupermanMode",
               renderer = "checkbox",
               name = "Enable Superman Controls",
               description =
               "When turned on, you will be able to enter superman mode and fly around with the keys WSAD, and KLIM",
               default = false
          },
          {
               key = "ShowFPSBox",
               renderer = "checkbox",
               name = "Show FPS Box",
               description =
               "When turned on, there's a box showing benchmark data.",
               default = false
          },
          {
               key = "KillHostileActors",
               renderer = "checkbox",
               name = "Automatically disable AI on Actors Hostile to the Player",
               description= "This can be useful if you need to do testing, but don't want to be bothered by rats in the wild.",
               default = false
          },

          {
               key = "DisableNPCs",
               renderer = "checkbox",
               name = "Disable Actors",
               description = "If true, all Actors(NPCs and Creatures) will be disabled on sight.",
               default = false
          },
          {
               key = "UnlockActivate",
               renderer = "checkbox",
               name = "Unlock Objects On Activate",
               description = "If true, locked or trapped containers and doors will unlock when you activate them.",
               default = false
          },

          {
               key = "DisableOwnership",
               renderer = "checkbox",
               name = "Disable Object Ownership",
               description =
               "If true, all items and containers will be set to be unowned when their cell is loaded. This will break shops.",
               default = false
          },
          {
               key = "DisableActorAI",
               renderer = "checkbox",
               name = "Disable Actor AI",
               description = "If true, all Actors will have their AI disabled.",
               default = "false"
          },
     }
}
