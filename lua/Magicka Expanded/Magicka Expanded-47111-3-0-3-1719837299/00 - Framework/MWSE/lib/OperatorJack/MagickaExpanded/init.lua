local common = require("OperatorJack.MagickaExpanded.common")
local log = require("OperatorJack.MagickaExpanded.utils.logger")

event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\lib\\OperatorJack\\MagickaExpanded\\mcm.lua")
end)

---@class MagickaExpanded
local this = {}

this.info = function(message) log:info(message) end
this.debug = function(message) log:debug(message) end
this.error = function(message) log:error(message) end

this.getActiveSpells = function() return common.spells end

this.alchemy = require("OperatorJack.MagickaExpanded.classes.alchemy")

this.spells = require("OperatorJack.MagickaExpanded.classes.spells")

this.enchantments = require("OperatorJack.MagickaExpanded.classes.enchantments")

this.effects = require("OperatorJack.MagickaExpanded.effects")

this.tomes = require("OperatorJack.MagickaExpanded.classes.tomes")

this.grimoires = require("OperatorJack.MagickaExpanded.classes.grimoires")

this.distribution = require("OperatorJack.MagickaExpanded.classes.distribution")

this.functions = require("OperatorJack.MagickaExpanded.utils.functions")

this.vfx = require("OperatorJack.MagickaExpanded.vfx")

this.data = require("OperatorJack.MagickaExpanded.data")

this.log = log

--[[
	Registers all magic effects, spells, tomes, and grimoires that
	are created through the Magicka Expanded framework.
]]
local function onLoaded()
    event.trigger("MagickaExpanded:Register")
    log:info("Magicka Expanded Framework Save Game Initialized")
end
event.register(tes3.event.loaded, onLoaded)

local function onInit()
    this.tomes.registerEvent()
    this.grimoires.registerEvent()
    this.distribution.registerEvent();
    log:info("Magicka Expanded Framework Initialized")
end
event.register(tes3.event.initialized, onInit)

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
    event.register(tes3.event.itemDropped, itemDropped)
end
event.register(tes3.event.initialized, onInitBoundItemFix)

return this
