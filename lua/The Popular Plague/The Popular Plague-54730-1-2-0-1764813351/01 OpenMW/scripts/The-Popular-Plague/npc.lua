local self = require("openmw.self")
local types = require("openmw.types")
local animation = require("openmw.animation")
local interfaces = require("openmw.interfaces")

local function isBeast()
    local npc = types.NPC.records[self.recordId]
    local race = types.NPC.races.records[npc.race]
    return race.isBeast
end

local function isDiseased()
    local activeSpells = types.Actor.activeSpells(self)
    return activeSpells:isSpellActive("md24_greatnewdisease")
end

local function isCombatActive()
    local activePackage = interfaces.AI.getActivePackage()
    return (activePackage ~= nil) and (activePackage.target ~= nil)
end

local function startDancing()
    if isDiseased() -- Note: commented out for easy testing
        and not isBeast()
        and not isCombatActive()
    then
        animation.playBlended(self, "bellydance", { priority = animation.PRIORITY.Scripted })
    end
end

local function isDancing()
    animation.isPlaying(self, "bellydance")
end

local function stopDancing()
    animation.cancel(self, "bellydance")
end

local function blowKiss()
    -- local player = nearby.players[1]
    -- local dir = (player.position - self.position)
    -- local angle = math.atan2(dir.x, dir.y)
    -- local rotation = util.transform.rotateZ(angle)
    -- self:teleport(self.cell, self.position, rotation)
    animation.playBlended(self, "blowkiss", { priority = animation.PRIORITY.Scripted })
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            -- Cancel dancing when combat is started.
            if isDancing() and isCombatActive() then
                stopDancing()
            end
        end,
        onActive = function()
            -- Start dancing (if applicable) after a 2s delay.
            if isDiseased() then
                startDancing()
            end
        end,
    },
    eventHandlers = {
        md24_start_dancing = startDancing,
        md24_stop_dancing = stopDancing,
        md24_anim_blow = blowKiss,
    },
}
