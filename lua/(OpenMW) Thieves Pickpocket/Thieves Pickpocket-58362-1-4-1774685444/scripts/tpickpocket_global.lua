local core  = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")

local shared                = require("scripts.tshared")
local THIEF_FACTIONS        = shared.THIEF_FACTIONS
local THIEF_CLASSES         = shared.THIEF_CLASSES
local GOLD_IDS              = shared.GOLD_IDS
local STEALABLE_MISC        = shared.STEALABLE_MISC
local STEALABLE_INGREDIENTS = shared.STEALABLE_INGREDIENTS
local STEALABLE_CLOTHING    = shared.STEALABLE_CLOTHING

local currentSettings = {}

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not types.NPC.objectIsInstance(actor) then return end
            if types.Actor.isDead(actor) then return end
            for _, factionId in pairs(types.NPC.getFactions(actor)) do
                if THIEF_FACTIONS[factionId:lower()] then
                    actor:addScript("scripts/tpickpocket_local.lua")
                    if next(currentSettings) then
                        actor:sendEvent("TP_SettingsUpdated", currentSettings)
                    end
                    return
                end
            end
            local classId = types.NPC.record(actor).class
            if classId and THIEF_CLASSES[classId:lower()] then
                actor:addScript("scripts/tpickpocket_local.lua")
                if next(currentSettings) then
                    actor:sendEvent("TP_SettingsUpdated", currentSettings)
                end
            end
        end,
    },
    eventHandlers = {
        TP_SettingsUpdated = function(data)
            currentSettings = data
            for _, actor in ipairs(world.activeActors) do
                if actor:hasScript("scripts/tpickpocket_local.lua") then
                    actor:sendEvent("TP_SettingsUpdated", data)
                end
            end
        end,
        PickpocketDoSteal = function(data)
            if not data or not data.player or not data.player:isValid() then return end
            if not data.npc or not data.npc:isValid() then return end

            local choice = data.choice

            if choice.kind == "gold" then
                local remaining = choice.amount
                local inv = types.Actor.inventory(data.player)
                for _, item in ipairs(inv:getAll()) do
                    if remaining <= 0 then break end
                    if GOLD_IDS[string.lower(item.recordId)] then
                        local take = math.min(item.count, remaining)
                        remaining  = remaining - take
                        item:split(take):moveInto(types.Actor.inventory(data.npc))
                    end
                end

            elseif choice.kind == "item" then
                local inv = types.Actor.inventory(data.player)
                local equippedCount = 0
                local eqTable = types.Actor.getEquipment(data.player)
                if eqTable then
                    for _, eqItem in pairs(eqTable) do
                        if eqItem and eqItem:isValid() then
                            if string.lower(eqItem.recordId) == choice.recordId then
                                equippedCount = equippedCount + 1
                            end
                        end
                    end
                end
                local skipped = 0
                for _, item in ipairs(inv:getAll()) do
                    if string.lower(item.recordId) == choice.recordId then
                        if skipped < equippedCount then
                            skipped = skipped + 1
                        else
                            item:split(1):moveInto(types.Actor.inventory(data.npc))
                            break
                        end
                    end
                end
            end

            if data.playSound then
                local rid = choice.recordId
                local sound
                if choice.kind == "gold" then
                    sound = "Item Gold Down"
                elseif STEALABLE_CLOTHING[rid] then
                    sound = "Item Ring Down"
                elseif STEALABLE_INGREDIENTS[rid] then
                    sound = "Item Ingredient Down"
                elseif STEALABLE_MISC[rid] then
                    sound = "Item Misc Down"
                else
                    sound = "Item Misc Down"
                end
                core.sound.playSound3d(sound, data.npc)
            end

            if data.message then
                data.player:sendEvent("PickpocketMessage", { message = data.message })
            end
        end,
        PickpocketShowMessage = function(data)
            if data and data.message and data.player and data.player:isValid() then
                data.player:sendEvent("PickpocketMessage", { message = data.message })
            end
        end,
        PickpocketReturn = function(data)
            if not data or not data.player or not data.player:isValid() then return end
            if not data.npc or not data.npc:isValid() then return end
            local choice = data.choice
            if not choice then return end

            if choice.kind == "gold" then
                local remaining = choice.amount
                local inv = types.Actor.inventory(data.npc)
                for _, item in ipairs(inv:getAll()) do
                    if remaining <= 0 then break end
                    if GOLD_IDS[string.lower(item.recordId)] then
                        local give = math.min(item.count, remaining)
                        remaining  = remaining - give
                        item:split(give):moveInto(types.Actor.inventory(data.player))
                    end
                end

            elseif choice.kind == "item" then
                local inv = types.Actor.inventory(data.npc)
                for _, item in ipairs(inv:getAll()) do
                    if string.lower(item.recordId) == choice.recordId then
                        item:split(1):moveInto(types.Actor.inventory(data.player))
                        break
                    end
                end
            end

            local rid = choice.recordId
            local sound
            if choice.kind == "gold" then
                sound = "Item Gold Up"
            elseif STEALABLE_CLOTHING[rid] then
                sound = "Item Ring Up"
            elseif STEALABLE_INGREDIENTS[rid] then
                sound = "Item Ingredient Up"
            else
                sound = "Item Misc Up"
            end
            core.sound.playSound3d(sound, data.npc)
        end,
    },
}