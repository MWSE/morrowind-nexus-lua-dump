require("SedrynTyros.ORLL.mcm")
local log = require("SedrynTyros.ORLL.log")
local health = require("SedrynTyros.ORLL.health")
local menu = require("SedrynTyros.ORLL.menu")
local display = require("SedrynTyros.ORLL.display")

local currLevel = 1
local nextLevel = 1

local function onLoaded()
    nextLevel = tes3.player.object.level
end

local function onPreLevelUp(e)
    nextLevel = e.level
end

local function onMenuLevelUp(e)
    if not e.newlyCreated or not e.element then return end
    menu.build(e.element, nextLevel)
end

local function onInitialized()
    event.register(tes3.event.loaded, onLoaded)
    event.register(tes3.event.preLevelUp, onPreLevelUp)
    event.register(tes3.event.uiActivated, onMenuLevelUp, { filter = "MenuLevelUp" })
    log:info("Initialized.")
end
event.register(tes3.event.initialized, onInitialized)

