local events = require("Clone.scripts.CloningAvatar.events")
local commonUtil = require("Clone.scripts.CloningAvatar.common.commonUtil")
local command = include("JosephMcKean.commands.interop")
local cloneRoomManager = require("Clone.scripts.CloningAvatar.CloneRoomManager")
--local skill = require("Clone.scripts.CloningAvatar.common.skill")
local dataManager = require("Clone.scripts.CloningAvatar.common.dataManager")
local settings = require("Clone.scripts.CloningAvatar.mwse.settings")

local function keyDown(e)
    for key, value in pairs(tes3.scanCode) do
        if value == e.keyCode then
            events.onKeyPress(key)
        end
    end
end
local function activate(e)
    local check = events.onActivate(e.target, e.activator)
    if check == false then
        
        return false
    end
end
local function death(e)
    if e.reference.id == tes3.player.id then
        events.onPlayerDeath(e.reference)
    end
end
local function soundObjectPlayCallback(e)
    --  return false
end
local function cellChangedCallback(e)

  events.cellChanged(e.cell)
    
end

local function journalCallback(e)
    events.onQuestUpdate(e.topic.id,e.index )
end
event.register(tes3.event.journal, journalCallback)
event.register(tes3.event.cellChanged, cellChangedCallback)
event.register(tes3.event.soundObjectPlay, soundObjectPlayCallback)
local function onDamage(e)
    if e.reference.id == tes3.player.id then
        if commonUtil.playerIsInClone() then
            if e.mobile.health.current - math.abs(e.damage) <= 1 then
                commonUtil.showMessage("Killed")
                e.damage = 0
                e.mobile.health.current = 1000
                events.onPlayerDeath()
                return false
            end
        end
    end
end
event.register(tes3.event["keyDown"], keyDown)
event.register(tes3.event["activate"], activate)
event.register(tes3.event["death"], death)
event.register(tes3.event.loaded, events.onInit)
event.register(tes3.event["damage"], onDamage, { priority = -100 })
if command then
    command.registerCommands({
        {
            name = "clonetp",
            description = "TP to clone area",
            callback = function(argv)
                events.onConsoleCommand("clonetp")
            end,
        },
    })
end
