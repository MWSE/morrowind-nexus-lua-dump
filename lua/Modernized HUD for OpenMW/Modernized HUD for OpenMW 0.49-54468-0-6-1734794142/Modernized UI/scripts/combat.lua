local AI = require("openmw.interfaces").AI
local Actor = require("openmw.types").Actor
local types = require("openmw.types")
local NPC = require("openmw.types").NPC
local Creature = require("openmw.types").Creature
local self = require("openmw.self")
local nearby = require('openmw.nearby')
local API = require('openmw.core').API_REVISION
local isOpenMW49 = API >= 59

local lastHealth = 0
local hasStoppedTargetingPlayer = true
local hasBeenKilled = false
local hasBeenTargeted = false

local health = Actor.stats.dynamic.health(self)
local level = Actor.stats.level(self).current
local player
local class, name
local id = self.object.id
local numeric_part = id:match("0x([%da-fA-F]+)")
id = tonumber(numeric_part, 16)

if NPC.objectIsInstance(self) then
    name = NPC.record(self).name
    class = NPC.record(self).class
else 
    name = Creature.record(self).name
    class = nil
end



local function isDead(actor)
    if isOpenMW49 then
        return Actor.isDead(actor)
    else
        return Actor.stats.dynamic.health(actor).current <= 0
    end
end

local function onUpdate()
    if player == nil then
        if isOpenMW49 then 
            player = nearby.players[1]
        elseif player == nil then
            local actors = nearby.actors
            for i = 1, #actors do
                if types.Player.objectIsInstance(actors[i]) then
                    player = actors[i]
                    break
                end
            end
        end
    end

    local package = AI.getActivePackage()
    if package == nil then return end

    local damage = lastHealth - health.current
    local isPlayerTarget = false
    local targets = AI.getTargets("Combat")
    local pursueTargets = AI.getTargets("Pursue")
    for i = 1, #pursueTargets do
        table.insert(targets, pursueTargets[i])
    end
    for i = 1, #targets do
        if targets[i] == player then
            isPlayerTarget = true
            break
        end
    end

    if isPlayerTarget and not isDead(self) and hasStoppedTargetingPlayer and (package.type == "Combat" or package.type == "Pursue") and package.sideWithTarget == false then -- Initial event
        player:sendEvent('SendCombatData', { 
            self = self,
            object = self.object,
            id = id,
            health = health.current, 
            maxHealth = health.base, 
            name = name, 
            level = level, 
            class = class, 
            stoppedTargeting = false,
            hasBeenHealed = false,
            debug = "Initial targeting.",
        })
    end

    if isPlayerTarget and (package.type == "Combat" or package.type == "Pursue") and package.sideWithTarget == false then
        hasStoppedTargetingPlayer = false
        if isDead(self) and hasBeenKilled == false then  -- I am dead and targeting the player.
            player:sendEvent('SendCombatData', { 
                self = self,
                object = self.object,
                id = id,
                health = 0, 
                maxHealth = health.base, 
                name = name, 
                level = level, 
                class = class, 
                stoppedTargeting = true,
                hasBeenHealed = false,
                debug = name .. " was killed and was targeting the player."
            })
            hasBeenKilled = true
        elseif damage > 0 then -- I have been damaged while targeting the player and when alive.
            player:sendEvent('SendCombatData', { 
                self = self,
                object = self.object,
                id = id,
                health = health.current, 
                maxHealth = health.base, 
                name = name, 
                level = level, 
                class = class, 
                stoppedTargeting = false,
                hasBeenHealed = false,
                damageTaken = damage,
                debug = "I have been damaged while targeting the player and when alive."
            })
        elseif damage < 0 then -- I have been healed while targeting the player and when alive.
            player:sendEvent('SendCombatData', { 
                self = self,
                object = self.object,
                id = id,
                health = health.current, 
                maxHealth = health.base, 
                name = name, 
                level = level, 
                class = class, 
                stoppedTargeting = false,
                hasBeenHealed = true,
                debug = "I have been healed while targeting the player and when alive."
            })
        else 
            -- I am targeting the player.
        end
    elseif not hasStoppedTargetingPlayer then -- I have stopped targeting the player and I am alive.
        player:sendEvent('SendCombatData', { 
            self = self,
            object = self.object,
            id = id,
            health = health.current, 
            maxHealth = health.base, 
            name = name, 
            level = level, 
            class = class, 
            stoppedTargeting = true,
            hasBeenHealed = false,
            debug = "I have stopped targeting the player and I am alive."
        })
        hasStoppedTargetingPlayer = true
    end
    lastHealth = health.current
end

return {
    engineHandlers = {
		onUpdate = onUpdate
    }
}