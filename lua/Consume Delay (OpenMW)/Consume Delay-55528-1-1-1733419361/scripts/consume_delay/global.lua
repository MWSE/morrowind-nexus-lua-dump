local core = require("openmw.core")
local types = require("openmw.types")
local Actor = types.Actor
local util = require("openmw.util")
--local world = require('openmw.world')

local records = {} -- records of the potions and ingredients moved

-- a position in the "toddtest" cell (arrival of the "coc" command):
local position = util.vector3(2176, 3648, -191)

local function onSave()
    return {
		R = records,
    }
end

local function onLoad(data)
	if data then
		records = data.R
	end
end

return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave,
    },
	eventHandlers = {
		-- function to move potions & ingredients from player to the todd cell
		CD_Move = function(e)
			for i, potion in pairs(e.potions) do
				potion:teleport("toddtest", position)
				table.insert(records, potion)
			end
			for i, ingredient in pairs(e.ingredients) do
				ingredient:teleport("toddtest", position)
				table.insert(records, ingredient)
			end
		end,
		
		-- function to move back potions & ingredients to the player inventory
		CD_MoveBack = function(e)
			for i, item in pairs(records) do
				item:moveInto(Actor.inventory(e.player))
			end
			records = {} -- the move back is done, no more potions & ingredients moved
		end,
	},
}
