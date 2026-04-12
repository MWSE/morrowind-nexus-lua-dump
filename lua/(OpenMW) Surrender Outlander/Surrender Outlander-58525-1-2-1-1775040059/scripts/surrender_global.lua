local core  = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local util  = require("openmw.util")

local shared            = require("scripts.surrender_shared")
local KHAJIIT_RACE     = shared.KHAJIIT_RACE
local BRIBE_MESSAGES   = shared.BRIBE_MESSAGES
local KHAJIIT_MESSAGES = shared.KHAJIIT_MESSAGES
local BRIBEABLE_CLASSES = shared.BRIBEABLE_CLASSES
local EXEMPT_NPCS      = shared.EXEMPT_NPCS

local LOCAL_SCRIPT = "scripts/surrender_npc.lua"

local function pickMessage(npc)
    local record = types.NPC.record(npc)
    local race   = record and record.race and record.race:lower() or ""
    if KHAJIIT_RACE[race] then
        return KHAJIIT_MESSAGES[math.random(#KHAJIIT_MESSAGES)]
    end
    return BRIBE_MESSAGES[math.random(#BRIBE_MESSAGES)]
end

local function ensureLocalScript(npc)
    if not npc:hasScript(LOCAL_SCRIPT) then
        npc:addScript(LOCAL_SCRIPT)
    end
end

return {
    eventHandlers = {
        Surrender_Bribe = function(data)
            local goldItem = data.goldItem
            local npcs     = data.npcs
            local player   = data.player

            if not goldItem or not goldItem:isValid() then return end
            if not player or not player:isValid() then return end
            if not npcs or #npcs == 0 then return end

            -- find closest bribeable NPC to receive the gold
            local closest     = nil
            local closestDist = math.huge
            for _, npc in ipairs(npcs) do
                if npc:isValid() and not types.Actor.isDead(npc) then
                    local dist = (npc.position - goldItem.position):length()
                    if dist < closestDist then
                        closestDist = dist
                        closest     = npc
                    end
                end
            end

            if not closest then return end

            -- move gold into the closest NPC's inventory
            goldItem:moveInto(types.Actor.inventory(closest))
            core.sound.playSound3d("Item Gold Up", closest)

            -- show message from the gold-taker
            local npcName = types.NPC.record(closest).name or "Someone"
            player:sendEvent("SurrenderMessage", {
                message = npcName .. ": \"" .. pickMessage(closest) .. "\""
            })

            -- build ceasefire target list
            local ceasefireTargets
            if data.classCeasefire then
                ceasefireTargets = {}
                for _, actor in ipairs(world.activeActors) do
                    if types.NPC.objectIsInstance(actor)
                       and not types.Actor.isDead(actor)
                       and not EXEMPT_NPCS[actor.recordId:lower()] then
                        local record = types.NPC.record(actor)
                        if record and record.class and BRIBEABLE_CLASSES[record.class:lower()] then
                            table.insert(ceasefireTargets, actor)
                        end
                    end
                end
            else
                ceasefireTargets = npcs
            end

            -- tell targets to cease fire
            for _, npc in ipairs(ceasefireTargets) do
                if npc:isValid() and not types.Actor.isDead(npc) then
                    ensureLocalScript(npc)
                    npc:sendEvent("Surrender_Ceasefire", {
                        ceasefire = data.ceasefire,
                        player    = player,
                    })
                end
            end
        end,
        Surrender_PlayerAttacked = function()
            for _, actor in ipairs(world.activeActors) do
                if actor:hasScript(LOCAL_SCRIPT) then
                    actor:sendEvent("Surrender_BreakCeasefire", {})
                end
            end
        end,
        Surrender_ThrowGold = function(data)
            local player = data.player
            if not player or not player:isValid() then return end

            local amount = data.amount
            local yaw    = data.yaw

            local inv  = types.Actor.inventory(player)
            local gold = nil
            for _, item in ipairs(inv:getAll()) do
                if item.recordId:lower() == "gold_001" then
                    gold = item
                    break
                end
            end
            if not gold or not gold:isValid() then return end
            if gold.count < amount then return end

            local pos = player.position
            local dropPos = util.vector3(
                pos.x + math.sin(yaw) * 50,
                pos.y + math.cos(yaw) * 50,
                pos.z + 10
            )

            local dropped = gold:split(amount)
            dropped:teleport(player.cell, dropPos)

            core.sound.playSound3d("Item Gold Down", player)

            player:sendEvent('Surrender_TryBribeFromThrow', {
                amount = amount,
            })
            player:sendEvent('GNPCs_NotifyGoldDrop', {
                amount = amount,
            })
        end,
    },
}