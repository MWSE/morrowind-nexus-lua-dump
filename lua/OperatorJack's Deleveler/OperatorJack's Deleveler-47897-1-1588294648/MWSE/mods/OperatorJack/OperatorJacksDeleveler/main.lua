local config = require("OperatorJack.OperatorJacksDeleveler.config")

event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\OperatorJack\\OperatorJacksDeleveler\\mcm.lua")
end)

--debug level: 0 - disabled, 1 - only list name, 2 - contents of each list
local debug = 0

local function initialized()
	local lists = {  }
	if (config.levcEnabled == true) then
		table.insert(lists, tes3.objectType.leveledCreature)
	end
	if (config.leviEnabled == true) then
		table.insert(lists, tes3.objectType.leveledItem)
	end
    	for leveledList in tes3.iterateObjects(lists) do
			if debug >= 1 then  mwse.log("List: %s", leveledList) end
        for _, node in pairs(leveledList.list) do
            if debug == 2 then mwse.log("--- Node: Obj: %s, Level: %s", node.object, node.levelRequired) end

            node.levelRequired = 1

            if debug == 2 then mwse.log("--- Updated Node: Obj: %s, Level: %s", node.object, node.levelRequired) end
        end
    end
	mwse.log("[OperatorJack's Develer: INFO] Lists deleveled")
end

event.register("initialized", initialized, {priority = -10000})