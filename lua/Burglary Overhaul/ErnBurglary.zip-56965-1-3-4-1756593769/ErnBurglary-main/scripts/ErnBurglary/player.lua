--[[
ErnBurglary for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local interfaces = require("openmw.interfaces")
local settings = require("scripts.ErnBurglary.settings")
local infrequent = require("scripts.ErnBurglary.infrequent")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local self = require("openmw.self")
local util = require("openmw.util")
local localization = core.l10n(settings.MOD_NAME)
local ui = require('openmw.ui')
local aux_util = require('openmw_aux.util')

settings.registerPage()

-- lastCellID will be nil if loading from a save game.
-- otherwise, it will be the cell we just moved from.
local lastCellID = nil

-- inDialogue is true while talking to an NPC.
-- this is an attempt to get this working with Pause Control.
local inDialogue = false
-- forgiveNewItems is set to true to skip the next item check.
local forgiveNewItems = false

-- itemsInInventory is used to track changes in the
-- player's inventory.
-- it's a map of item instance id -> {item=instance,count=count}.
-- count is tracked separately because we need to detect changes.
local itemsInInventory = {}
local function trackInventory()
    itemsInInventory = {}
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        itemsInInventory[item.id] = {
            item = item,
            count = item.count
        }
    end
end
trackInventory()

local function elusiveness(distance)
    -- https://en.uesp.net/wiki/Morrowind:Sneak

    local sneakTerm = types.NPC.stats.skills.sneak(self).modified
    local agilityTerm = types.Actor.stats.attributes.agility(self).modified / 5
    local luckTerm = types.Actor.stats.attributes.luck(self).modified / 10
    local distanceTerm = 0.5 + (distance / 500)
    local fatigueStat = types.Actor.stats.dynamic.fatigue(self)
    local fatigueTerm = 0.75 + (0.5 * math.min(1, math.max(0, fatigueStat.current / fatigueStat.base)))

    local chameleonEffect = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Chameleon)
    local chameleon = 0
    if chameleonEffect ~= nil then
        chameleon = chameleonEffect.magnitude
    end

    local elusivenessScore = (sneakTerm + agilityTerm + luckTerm) * distanceTerm * fatigueTerm + chameleon
    -- settings.debugPrint("elusiveness: " .. elusivenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                        luckTerm .. ") * " .. distanceTerm .. " * " .. fatigueTerm .. " + " .. chameleon)
    return elusivenessScore
end

local function directionMult(actor)
    -- 1.5 if on either side or in front
    -- 0.5 if behind

    -- dot product returns 0 if at 90*, 1 if codirectional, -1 if opposite.

    -- so, take (dot product)/2 + 1

    local facing = actor.rotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize()
    local relativePos = (self.position - actor.position):normalize()
    local mult = 1 + facing:dot(relativePos) / 2
    --settings.debugPrint("directionMult for " .. actor.recordId .. ": "..tostring(mult))
    return mult
end

local function awareness(actor)
    -- https://en.uesp.net/wiki/Morrowind:Sneak
    local sneakTerm = types.NPC.stats.skills.sneak(actor).modified
    local agilityTerm = types.Actor.stats.attributes.agility(actor).modified / 5
    local luckTerm = types.Actor.stats.attributes.luck(actor).modified / 10

    local fatigueStat = types.Actor.stats.dynamic.fatigue(self)
    local fatigueTerm = 0.75 + (0.5 * math.min(1, math.max(0, fatigueStat.current / fatigueStat.base)))

    local blindEffect = types.Actor.activeEffects(actor):getEffect(core.magic.EFFECT_TYPE.Blind)
    local blind = 0
    if blindEffect ~= nil then
        blind = blindEffect.magnitude
    end

    local awarenessScore = (sneakTerm + agilityTerm + luckTerm - blind) * fatigueTerm * directionMult(actor)
    -- settings.debugPrint("awareness: " .. awarenessScore .. " = " .. "(" .. sneakTerm .. "+" .. agilityTerm .. "+" ..
    --                        luckTerm .. "-" .. blind .. ") * " .. fatigueTerm .. " * " .. directionMult)
    return awarenessScore
end

-- sneakCheck should return true if the actor can't see the player.
local function sneakCheck(actor, distance)
    local invisibilityEffect = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Invisibility)
    if (invisibilityEffect ~= nil) and (invisibilityEffect.magnitude > 0) then
        settings.debugPrint("invisible; ignoring greeting")
        return true
    end

    -- if we aren't sneaking, then you don't pass the check.
    if self.controls.sneak ~= true then
        return false
    end

    local sneakChance = math.min(100, math.max(0, elusiveness(distance) - awareness(actor)))
    local roll = math.random(0, 100)

    -- settings.debugPrint("sneak chance: " .. sneakChance .. ", roll: " .. roll)

    return sneakChance >= roll
end

local function isTalking(actor)
    return core.sound.isSayActive(actor)
end

-- sendSpottedEvent notifies the rest of the mod that a detection occurred. If you are making a sneak mechanic overhaul mod,
-- then you should send the global event inside this function every time the player is spotted by an NPC.
local function sendSpottedEvent(npc)
    settings.debugPrint("sending spotted by event for " .. npc.recordId)

    core.sendGlobalEvent(settings.MOD_NAME .. "onSpotted", {
        player = self,
        npc = npc,
        cellID = self.cell.id
    })
end

local function LOS(player, actor)
    -- cast once from center of box to center of box
    local playerCenter = player:getBoundingBox().center
    local actorCenter = actor:getBoundingBox().center

    local castResult = nearby.castRay(actorCenter, playerCenter, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor
    })
    --settings.debugPrint("raycast(center, "..tostring(actorCenter)..") from " .. actor.recordId .. " hit" ..
    --                        aux_util.deepToString(castResult.hitObject, 4))

    if (castResult.hitObject ~= nil) and (castResult.hitObject.id == player.id) then
        return true
    end

    -- and one more check from top of one box to near-center of other.
    -- this exists so merchants can spot you behind counters.
    local actorHead = actor:getBoundingBox().center + util.vector3(0, 0, actor:getBoundingBox().halfSize.z)
    local playerChest = player:getBoundingBox().center + util.vector3(0, 0, (player:getBoundingBox().halfSize.z) / 2)

    castResult = nearby.castRay(actorHead, playerChest, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor
    })
    --settings.debugPrint("raycast(head, "..tostring(actorHead)..") from " .. actor.recordId .. " hit" ..
    --                        aux_util.deepToString(castResult.hitObject, 4))

    if (castResult.hitObject ~= nil) and (castResult.hitObject.id == player.id) then
        return true
    end

    return false
end

local function detectionCheck(dt)
    -- find out which NPC is talking
    for _, actor in ipairs(nearby.actors) do
        -- check for detection
        if (actor.id ~= self.id) and types.NPC.objectIsInstance(actor) and (types.Actor.isDead(actor) ~= true) and
            (types.Actor.isDeathFinished(actor) ~= true) then
            local distance = (self.position - actor.position):length()
            if distance <= 400 then
                local sneakResult = sneakCheck(actor, distance)
                if (isTalking(actor) or (distance <= 100)) and (sneakResult ~= true) then
                    -- do a raycast to check if we have line of sight
                    if LOS(self, actor) then
                        sendSpottedEvent(actor)
                    end
                end
            end
        end
    end
end

local function inventoryChangeCheck(dt)
    local newItemsList = {}
    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        local itemBag = itemsInInventory[item.id]
        if itemBag == nil then
            local newBag = {
                item = item,
                count = (item.count)
            }
            -- brand new item.
            table.insert(newItemsList, newBag)
            settings.debugPrint("found " .. tostring(newBag.count) .. " new item: " .. aux_util.deepToString(item, 2))
            -- don't re-add the item
            itemsInInventory[item.id] = newBag
        elseif (item.count == nil) or (itemBag.count == nil) then
            -- TODO: actually fix this sometime.
            error("Something bad happened.")
            return
        elseif item.count > itemBag.count then
            -- the count of the item in the player inventory went up.
            local newBag = {
                item = item,
                count = (item.count - itemBag.count)
            }
            table.insert(newItemsList, newBag)
            settings.debugPrint("found " .. tostring(newBag.count) .. " new items in stack: " ..
                aux_util.deepToString(item, 2))
            -- update count in stack
            local updatedBag = {
                item = item,
                count = (item.count)
            }
            itemsInInventory[item.id] = updatedBag
        end
    end
    if forgiveNewItems then
        settings.debugPrint("forgave new items")
        forgiveNewItems = false
        return
    end

    if #newItemsList > 0 then
        if inDialogue then
            settings.debugPrint("forgave new items")
            return
        end

        -- lastCellID might not be set yet, so use current cell as a backup.
        local itemCell = lastCellID
        if itemCell == nil or itemCell == "" then
            itemCell = self.cell.id
        end

        core.sendGlobalEvent(settings.MOD_NAME .. "onNewItem", {
            player = self,
            cellID = itemCell,
            itemsList = newItemsList
        })
    end
end

local bounty = types.Player.getCrimeLevel(self)

local function onInfrequentUpdate(dt)
    -- this is not called when the game is paused.

    inventoryChangeCheck(dt)

    if lastCellID ~= self.cell.id then
        settings.debugPrint("cell changed from " .. tostring(lastCellID) .. " to " .. self.cell.id)

        -- now process cell change

        core.sendGlobalEvent(settings.MOD_NAME .. "onCellChange", {
            player = self,
            lastCellID = lastCellID,
            newCellID = self.cell.id
        })

        -- at this point, lastCellID is not correct, because it is the current cell.
        lastCellID = self.cell.id

        -- reset per-cell state
        trackInventory()

        return
    end

    if settings.disableDetection() ~= true then
        detectionCheck(dt)
    end

    local newBounty = types.Player.getCrimeLevel(self)
    if bounty < newBounty then
        settings.debugPrint("detected bounty increase")
        -- we got caught!
        -- notify global that we got caught.
        -- this will immediately check for pending thefts
        core.sendGlobalEvent(settings.MOD_NAME .. "onBountyIncreased", {
            player = self,
            oldBounty = bounty,
            newBounty = newBounty
        })

        bounty = newBounty
    end
end

local infrequentMap = infrequent.FunctionCollection:new()
infrequentMap:addCallback("onInfrequentUpdate", 0.15, onInfrequentUpdate)

local function onUpdate(dt)
    if dt ~= 0 then
        infrequentMap:onUpdate(dt)
    end
end

local lastNPCActivated = nil
local function onNPCActivated(data)
    -- this is called before dialogue and before pickpocketing
    lastNPCActivated = data.npc
end

local function UiModeChanged(data)
    --settings.debugPrint("ui changed: " .. aux_util.deepToString(data, 2))
    if data.newMode == "Dialogue" or data.newMode == "Companion" then
        settings.debugPrint("in dialogue")
        if lastNPCActivated ~= nil then
            settings.debugPrint("talking with " .. lastNPCActivated.recordId .. ", they spot us for free")
            -- this is probably the NPC talking to us.
            -- they get to spot us for free.
            sendSpottedEvent(lastNPCActivated)
        end
        -- this is for a pause control patch
        inDialogue = true
        -- bounty check is for detecting bounty payoffs
        bounty = types.Player.getCrimeLevel(self)

        lastNPCActivated = nil
    elseif data.oldMode == "Dialogue" or data.oldMode == "Companion" then
        settings.debugPrint("was in dialogue")
        inDialogue = false
        -- ensure we skip the NEXT item check.
        -- the item check is not done while paused in vanilla.
        forgiveNewItems = true

        -- detect bounty payoffs
        local newBounty = types.Player.getCrimeLevel(self)
        if (newBounty == 0) and (bounty ~= 0) then
            bounty = 0
            -- we paid off our bounty.
            core.sendGlobalEvent(settings.MOD_NAME .. "onPaidBounty", {
                player = self,
                previousBounty = bounty
            })
        end

        lastNPCActivated = nil
    end
end

local function setItemsAllowed(data)
    if (data == nil) or (data.allowed == nil) then
        error("bad data")
    end
    settings.debugPrint("overriding inDialogue to" .. tostring(data.allowed))
    inDialogue = data.allowed
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. "setItemsAllowed"] = setItemsAllowed,
        [settings.MOD_NAME .. "onNPCActivated"] = onNPCActivated,
        UiModeChanged = UiModeChanged
    },
    engineHandlers = {
        onUpdate = onUpdate
    }
}
