return {
   interfaceName = "consolecommands_data",
   interface = {
     version = 1,
     objectTypes = {
 {Description="Adds an item to the selected actor. Accepts an item ID, or if an item name is specified; adds the first item found with that name. If no actor is selected; adds to the player inv. Optional number parameter for count.",Command_Name="additem",},
 {Description="Adds the specified spell to the player or selected actor.",Command_Name="addspell",},
 {Description="Removes ownership data from all nearby containers and doors.",Command_Name="clearallowners",},
 {Description="Removes ownership data from the selected object.",Command_Name="clearowner",},
 {Description="Teleports the player to the cell specified after coc. No quotations are needed. Partial strings are acceptable; the first matching cell will be picked. If you’ve used findcell recently; the indexes in the results there can be used here.",Command_Name="coc",},
 {Description="Disables the selected object.",Command_Name="disable",},
 {Description="Causes Actor to drop all their items and equipment at their feet",Command_Name="dropall",},
 {Description="Enables the selected object.",Command_Name="enable",},
 {Description="Quickly exits lua mode.",Command_Name="ex",},
 {Description="Applies a massive feather effect on the player. Removes it if already applied.",Command_Name="feather",},
 {Description="Searches the world for all objects with the given record ID; including inventories. Tells you their location; ID; and index.",Command_Name="find",},
 {Description="Lists all cells that match the specified string. Will also list their index; that index can be used with coc.",Command_Name="findcell",},
 {Description="Toggles player levitation ability.",Command_Name="fly",},
 {Description="Reimplementation of vanilla command. Takes axis as param.",Command_Name="getpos",},
 {Description="Kills the selected object; if it is a creature or NPC.",Command_Name="kill",},
 {Description="Kills all loaded actors; other than the player.",Command_Name="killall",},
 {Description="Kills all loaded creatures.",Command_Name="killcreas",},
 {Description="Moves the selected object; or the player; to the first instance of the specified recordId.",Command_Name="moveto",},
 {Description="Moves the selected object; or the player; to specified object; can take either the ID or the index(indicated with #). Requires the item be found with find beforehand.",Command_Name="movetoid",},
 {Description="Places an object at the selected object.",Command_Name="placeatme",},
 {Description="Places an object at the player. No count; rotation; or distance parameters",Command_Name="placeatpc",},
 {Description="Places an object where the player is looking.",Command_Name="placeattarget",},
 {Description="Gives every spell to the player.(Not powers or abilities)",Command_Name="psb",},
 {Description="Removes all objects with the specified ID postfix; -1 will remove any object added ingame; 1 will remove anything from morrowind.esm; if all is specified; it will remove every single object in the game.",Command_Name="purge",},
 {Description="Reloaded lua while in lua mode. Will not work if the ESC screen is open.",Command_Name="Reloadlua;rlua",},
 {Description="Resurrects the selected actor; without resetting their inventory.Will resurrect the player if they are dead; as long as the death animation has not finished.",Command_Name="resurrect",},
 {Description="Create a merchant with all items of the specified type. Accepts Apparatus; Armor; Book; Clothing; Ingredient; Light; Lockpick; Misc; Potion; Probe; Repair; weapon. If type is “item”; you will get a container with every item in the game. This will cause significant lag. Items with scripts attached are ommited.",Command_Name="seeall",},
 {Description="Selects the first instance with the specified recordId. Cell scan; so may take a long time the first time you run it.",Command_Name="Select;prid",},
 {Description="Removes a selected object permently.",Command_Name="setdelete",},
 {Description="Reimplementation of vanilla command. Takes axis and value as params.",Command_Name="setpos",},
 {Description="Shows all objects in the player’s cell that are disabled.",Command_Name="showdisabled",},
 {Description="Takes all the items in the selected container or actor; and gives them to the player.",Command_Name="takeall",},
 {Description="Toggles player collision.",Command_Name="tcl",},
 {Description="Toggles engine TGM mode.",Command_Name="tgm",},
 {Description="Removes lock from selected object. For now; removes the container or door and replaces it with an identical container or door with no lock. Will teleport the player to the door’s destination for selected door if it is a teleport door.",Command_Name="unlock",},
 {Description="Runs the above command on all loaded doors and containers.",Command_Name="unlockall",},
 {Description="Sets the current game hour to the specified hour - sethour 12 will set the time to noon.",Command_Name="sethour"},
 {Description="Plays the specified sound, by string. If number is specified, will play the sound at that index in the stored sounds.",Command_Name="playsound"},
 {Description="Finds sounds that contain the specified string. If nothing is specified, all valid sounds are listed.",Command_Name="findsound"}
 }
   }
 }