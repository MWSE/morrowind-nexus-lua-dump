local common = require("OperatorJack.MagickaExpanded.common")

-- Initialize any script overrides that are set within the framework.
require("OperatorJack.MagickaExpanded.classes.scriptOverrides")
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\lib\\OperatorJack\\MagickaExpanded\\mcm.lua")
end)

local this = {}

this.info = function(message)
	common.info(message)
end
this.debug = function(message)
	common.debug(message)
end
this.error = function(message)
	common.error(message)
end

this.getActiveSpells = function()
	return common.spells
end

this.alchemy = require("OperatorJack.MagickaExpanded.classes.alchemy")

this.spells = require("OperatorJack.MagickaExpanded.classes.spells")

this.enchantments = require("OperatorJack.MagickaExpanded.classes.enchantments")

this.effects =  require("OperatorJack.MagickaExpanded.classes.effects")

this.tomes = require("OperatorJack.MagickaExpanded.classes.tomes")

this.grimoires = require("OperatorJack.MagickaExpanded.classes.grimoires")

this.functions =  require("OperatorJack.MagickaExpanded.classes.functions")

--[[
	Description: Registers all magic effects, spells, tomes, and grimoires that
	are created through the Magicka Expanded framework.
]]
local function onLoaded()
	event.trigger("MagickaExpanded:Register")
	this.info("Magicka Expanded Framework Save Game Initialized")
end
event.register("loaded", onLoaded)

local function onInit()
	this.tomes.registerEvent()
	this.grimoires.registerEvent()
	this.info("Magicka Expanded Framework Initialized")
end
event.register("initialized", onInit)

--[[
	Fix being able to drop some bound items.
]]
local msgYouCannotDropSummonedItems -- set in initialized()

local function itemDropped(e)
	if common.boundItemsByObject[e.reference.id] then
		timer.start({
			type = timer.real,
			duration = 0.01,
			callback = function()
				tes3.player:activate(e.reference)
				tes3.messageBox(msgYouCannotDropSummonedItems)
			end
		})
	end
end

local function onInitBoundItemFix()
	local sBarterDialog12 = tes3.findGMST(tes3.gmst.sBarterDialog12)
	msgYouCannotDropSummonedItems = sBarterDialog12.value
	event.register('itemDropped', itemDropped)
end
event.register('initialized', onInitBoundItemFix)

return this