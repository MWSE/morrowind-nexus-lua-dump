local core  = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local async = require("openmw.async")
local I     = require("openmw.interfaces")

local shared       = require("scripts.gshared")
local KHAJIIT_RACE = shared.KHAJIIT_RACE
local GOLD_IDS     = shared.GOLD_IDS
local DEFAULTS     = shared.DEFAULTS

local messages = require("scripts.gnddys_messages")

local LOCAL_SCRIPT = "scripts/gnddys_local.lua"

local cachedSettings = {
    PICKUP_RADIUS        = DEFAULTS.PICKUP_RADIUS,
    PICKUP_DELAY         = DEFAULTS.PICKUP_DELAY,
    EQUIP_ARMOR          = DEFAULTS.EQUIP_ARMOR,
    SHOW_PICKUP_MESSAGES = DEFAULTS.SHOW_PICKUP_MESSAGES,
    SHOW_HEAVY_MESSAGES  = DEFAULTS.SHOW_HEAVY_MESSAGES,
}

local lastBroadcastData = nil

local pendingItems = {}

local function randomMessage()
    local msgs = messages.PICKUP_MESSAGES
    return msgs[math.random(#msgs)]
end

local function khajiitMessage(isMoonSugar)
    if isMoonSugar then
        local msgs = messages.KHAJIIT_SUGAR_MESSAGES
        return msgs[math.random(#msgs)]
    end
    local msgs = messages.KHAJIIT_MESSAGES
    return msgs[math.random(#msgs)]
end

local ARROW = types.Weapon.TYPE.Arrow
local BOLT  = types.Weapon.TYPE.Bolt

local function getAmmoType(item)
    if not types.Weapon.objectIsInstance(item) then return nil end
    local wtype = types.Weapon.record(item).type
    if wtype == ARROW then return "arrow" end
    if wtype == BOLT  then return "bolt"  end
    return nil
end

local function ammoMessage(ammoType, isKhajiit)
    if ammoType == "bolt" then
        if isKhajiit then
            local msgs = messages.KHAJIIT_BOLT_PICKUP_MESSAGES
            return msgs[math.random(#msgs)]
        end
        local msgs = messages.BOLT_PICKUP_MESSAGES
        return msgs[math.random(#msgs)]
    end
    if isKhajiit then
        local msgs = messages.KHAJIIT_ARROW_PICKUP_MESSAGES
        return msgs[math.random(#msgs)]
    end
    local msgs = messages.ARROW_PICKUP_MESSAGES
    return msgs[math.random(#msgs)]
end

local function ensureLocalScript(npc)
    if not npc:hasScript(LOCAL_SCRIPT) then
        npc:addScript(LOCAL_SCRIPT)
        if lastBroadcastData then
            npc:sendEvent("GreedyNPCs_SettingsUpdated", lastBroadcastData)
        end
    end
end

return {
    eventHandlers = {
        GreedyNPCs_SettingsUpdated = function(data)
            cachedSettings.PICKUP_RADIUS        = data.PICKUP_RADIUS
            cachedSettings.PICKUP_DELAY         = data.PICKUP_DELAY
            cachedSettings.EQUIP_ARMOR          = data.EQUIP_ARMOR
            cachedSettings.SHOW_PICKUP_MESSAGES = data.SHOW_PICKUP_MESSAGES
            cachedSettings.SHOW_HEAVY_MESSAGES  = data.SHOW_HEAVY_MESSAGES
            if cachedSettings.SHOW_PICKUP_MESSAGES == nil then cachedSettings.SHOW_PICKUP_MESSAGES = DEFAULTS.SHOW_PICKUP_MESSAGES end
            if cachedSettings.SHOW_HEAVY_MESSAGES  == nil then cachedSettings.SHOW_HEAVY_MESSAGES  = DEFAULTS.SHOW_HEAVY_MESSAGES  end
            lastBroadcastData = data
            for _, actor in ipairs(world.activeActors) do
                if actor:hasScript(LOCAL_SCRIPT) then
                    actor:sendEvent("GreedyNPCs_SettingsUpdated", data)
                end
            end
        end,

        NpcTooHeavyItem = function(data)
            local item = data.item
            local npc  = data.npc
            if not item or not item:isValid() then return end
            if not npc  or not npc:isValid()  then return end

            if pendingItems[item.id] then return end
            pendingItems[item.id] = true

            if cachedSettings.SHOW_HEAVY_MESSAGES then
                local npcName = types.NPC.record(npc).name or "Someone"
                local npcRace = (types.NPC.record(npc).race or ""):lower()
                local player = world.players[1]
                if player then
                    local msg
                    if KHAJIIT_RACE[npcRace] then
                        local msgs = messages.KHAJIIT_TOO_HEAVY_MESSAGES
                        msg = msgs[math.random(#msgs)]
                    else
                        local msgs = messages.TOO_HEAVY_MESSAGES
                        msg = msgs[math.random(#msgs)]
                    end
                    player:sendEvent("NpcPickupMessage", {
                        message = npcName .. ": \"" .. msg .. "\""
                    })
                end
            end

            async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
                pendingItems[item.id] = nil
            end)
        end,

        GNPCs_EnsureLocalAndQueryPickup = function(data)
            if not data or not data.npc or not data.npc:isValid() then return end
            if not data.item or not data.item:isValid() then return end
            ensureLocalScript(data.npc)
            data.npc:sendEvent("GNPCs_QueryPickup", { item = data.item })
        end,

        GNPCs_EnsureLocalAndLure = function(data)
            if not data or not data.npc or not data.npc:isValid() then return end
            if not data.item or not data.item:isValid() then return end
            ensureLocalScript(data.npc)
            data.npc:sendEvent("GNPCs_LureToItem", {
                item    = data.item,
                itemPos = data.itemPos,
            })
        end,

        GNPCs_EnsureLocalAndQueryCrime = function(data)
            if not data or not data.npc or not data.npc:isValid() then return end
            if not data.player or not data.player:isValid() then return end
            ensureLocalScript(data.npc)
            data.npc:sendEvent("GNPCs_QueryCrime", { player = data.player })
        end,

        NpcPickupItem = function(data)
            local item     = data.item
            local npc      = data.npc
            local maxCount = data.maxCount  -- nil means full stack
            if not item or not item:isValid() then return end
            if not npc  or not npc:isValid()  then return end

            if pendingItems[item.id] then return end
            pendingItems[item.id] = true

            async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
                pendingItems[item.id] = nil

                if not item:isValid() then return end
                if not npc:isValid() or types.Actor.isDead(npc) then return end
                local player = world.players[1]
                if not player then return end
                if (item.position - player.position):length() > cachedSettings.PICKUP_RADIUS then return end
                if item.cell == nil then return end
                if item.count <= 0 then return end

                local pickCount = maxCount and math.min(maxCount, item.count) or item.count
                local movedItem
                if pickCount < item.count then
                    movedItem = item:split(pickCount)
                    movedItem:moveInto(types.Actor.inventory(npc))
                else
                    item:moveInto(types.Actor.inventory(npc))
                    movedItem = item
                end

                local id = string.lower(movedItem.recordId)
                local ammoType = getAmmoType(movedItem)
                local sound
                if GOLD_IDS[id] then
                    sound = "Item Gold Up"
                elseif ammoType then
                    sound = "Item Ammo Up"
                elseif types.Weapon.objectIsInstance(movedItem) then
                    sound = "Item Weapon Shortblade Up"
                elseif types.Book.objectIsInstance(movedItem) then
                    sound = "Item Book Up"
                elseif types.Apparatus.objectIsInstance(movedItem) then
                    sound = "Item Apparatus Up"
                elseif types.Clothing.objectIsInstance(movedItem) then
                    sound = "Item Clothes Up"
                elseif types.Armor.objectIsInstance(movedItem) then
                    sound = "Item Armor Medium Up"
                elseif types.Ingredient.objectIsInstance(movedItem) then
                    sound = "Item Ingredient Up"
                elseif types.Potion.objectIsInstance(movedItem) then
                    sound = "Item Potion Up"
                elseif types.Lockpick.objectIsInstance(movedItem) then
                    sound = "Item Lockpick Up"
                elseif types.Probe.objectIsInstance(movedItem) then
                    sound = "Item Probe Up"
                elseif types.Repair.objectIsInstance(movedItem) then
                    sound = "Item Repair Up"
                else
                    sound = "Item Misc Up"
                end
                core.sound.playSound3d(sound, npc)

                if cachedSettings.SHOW_PICKUP_MESSAGES then
                    local npcName = types.NPC.record(npc).name or "Someone"
                    local npcRace = (types.NPC.record(npc).race or ""):lower()
                    local msg
                    if ammoType then
                        msg = ammoMessage(ammoType, KHAJIIT_RACE[npcRace])
                    elseif KHAJIIT_RACE[npcRace] then
                        msg = khajiitMessage(id == "ingred_moon_sugar_01")
                    else
                        msg = randomMessage()
                    end
                    player:sendEvent("NpcPickupMessage", {
                        message = npcName .. ": \"" .. msg .. "\""
                    })
                end

                if cachedSettings.EQUIP_ARMOR and types.Armor.objectIsInstance(movedItem) then
                    npc:sendEvent("GNPCs_TryEquipArmor", { item = movedItem })
                end
            end)
        end,

        NpcLurePickupItem = function(data)
            local item     = data.item
            local npc      = data.npc
            local maxCount = data.maxCount  -- nil means full stack
            if not item or not item:isValid() then return end
            if not npc  or not npc:isValid()  then return end
            if item.cell == nil then return end
            if item.count <= 0 then return end

            local pickCount = maxCount and math.min(maxCount, item.count) or item.count
            local movedItem
            if pickCount < item.count then
                movedItem = item:split(pickCount)
                movedItem:moveInto(types.Actor.inventory(npc))
            else
                item:moveInto(types.Actor.inventory(npc))
                movedItem = item
            end

            local id = string.lower(movedItem.recordId)
            local ammoType = getAmmoType(movedItem)
            local sound
            if GOLD_IDS[id] then
                sound = "Item Gold Up"
            elseif ammoType then
                sound = "Item Ammo Up"
            elseif types.Weapon.objectIsInstance(movedItem) then
                sound = "Item Weapon Shortblade Up"
            elseif types.Book.objectIsInstance(movedItem) then
                sound = "Item Book Up"
            elseif types.Apparatus.objectIsInstance(movedItem) then
                sound = "Item Apparatus Up"
            elseif types.Clothing.objectIsInstance(movedItem) then
                sound = "Item Clothes Up"
            elseif types.Armor.objectIsInstance(movedItem) then
                sound = "Item Armor Medium Up"
            elseif types.Ingredient.objectIsInstance(movedItem) then
                sound = "Item Ingredient Up"
            elseif types.Potion.objectIsInstance(movedItem) then
                sound = "Item Potion Up"
            elseif types.Lockpick.objectIsInstance(movedItem) then
                sound = "Item Lockpick Up"
            elseif types.Probe.objectIsInstance(movedItem) then
                sound = "Item Probe Up"
            elseif types.Repair.objectIsInstance(movedItem) then
                sound = "Item Repair Up"
            else
                sound = "Item Misc Up"
            end
            core.sound.playSound3d(sound, npc)

            if cachedSettings.SHOW_PICKUP_MESSAGES then
                local npcName = types.NPC.record(npc).name or "Someone"
                local npcRace = (types.NPC.record(npc).race or ""):lower()
                local player = world.players[1]
                if player then
                    local msg
                    if ammoType then
                        msg = ammoMessage(ammoType, KHAJIIT_RACE[npcRace])
                    elseif KHAJIIT_RACE[npcRace] then
                        msg = khajiitMessage(id == "ingred_moon_sugar_01")
                    else
                        msg = randomMessage()
                    end
                    player:sendEvent("NpcPickupMessage", {
                        message = npcName .. ": \"" .. msg .. "\""
                    })
                end
            end

            if cachedSettings.EQUIP_ARMOR and types.Armor.objectIsInstance(movedItem) then
                npc:sendEvent("GNPCs_TryEquipArmor", { item = movedItem })
            end
        end,

        ContrabandCrime = function(data)
            if not data or not data.player then return end
            I.Crimes.commitCrime(data.player, {
                type = types.Player.OFFENSE_TYPE.Trespassing,
                victimAware = true,
            })
        end,

        -- ArrowStick mod notifies when an arrow/bolt is placed in the world
        ArrowStick_ArrowPlaced = function(data)
            if not data or not data.arrowSticked then return end
            local item = data.item
            if not item or not item:isValid() then return end
            local player = world.players[1]
            if not player then return end
            player:sendEvent("GNPCs_NotifyItemDrop", {
                recordId = item.recordId,
                position = item.position,
            })
        end,
    },
}