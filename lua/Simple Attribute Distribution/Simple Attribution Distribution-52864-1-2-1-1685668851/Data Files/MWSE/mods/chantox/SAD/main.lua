require("chantox.SAD.mcm")
local log = require("chantox.SAD.log")
local menu = require("chantox.SAD.menu")
local health = require("chantox.SAD.health")
local display = require("chantox.SAD.display")

local currLevel = 1
local attributes = {}
local function update(params)
    if not params then
        params = {}
    end

    currLevel = tes3.player.object.level

    attributes[1] = tes3.mobilePlayer.strength.current
    attributes[6] = tes3.mobilePlayer.endurance.current

    health.update(params)
    display.update()
end

local nextLevel = 1
local function onLoaded()
    nextLevel = tes3.player.object.level
	update()
end

---@param e preLevelUpEventData
local function onPreLevelUp(e)
    nextLevel = e.level
end

---Replace the vanilla levelup menu with our own
---@param e uiActivatedEventData
local function onMenuLevelUp(e)
    if (not e.newlyCreated) or (not e.element) then
        return
    end
    menu.build(e.element, nextLevel)
end

---Check if an update is needed, then apply it
local function onEnterFrame()
    if not tes3.player then
        return
    end

    local mp = tes3.mobilePlayer
    if mp.health.current <= 0 then
        return
    end

    local leveled = tes3.player.object.level ~= currLevel
    if (mp.strength.current == attributes[1] and
        mp.endurance.current == attributes[6] and
        not leveled) then
        return
    end

    local params = {}
    if leveled then
        params.heal = true
    end
    update(params)
end

local function onInitialized()
    event.register(tes3.event.loaded, onLoaded)
    event.register(tes3.event.preLevelUp, onPreLevelUp)
    event.register(tes3.event.uiActivated, onMenuLevelUp, {filter = "MenuLevelUp"})
    event.register(tes3.event.enterFrame, onEnterFrame)

    log:info("Initialized.")
end
event.register(tes3.event.initialized, onInitialized)
