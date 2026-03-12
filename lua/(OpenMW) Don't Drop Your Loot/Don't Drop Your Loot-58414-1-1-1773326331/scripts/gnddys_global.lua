local core  = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local async = require("openmw.async")
local I     = require("openmw.interfaces")

local shared            = require("scripts.gshared")
local KHAJIIT_RACE      = shared.KHAJIIT_RACE
local NARCOTIC_IDS      = shared.NARCOTIC
local CONTRABAND_IDS    = shared.CONTRABAND
local PAUPER_CONTRABAND = shared.PAUPER_CONTRABAND
local DEFAULTS          = shared.DEFAULTS

local messages = require("scripts.gnddys_messages")

local cachedSettings = {
    PICKUP_RADIUS   = DEFAULTS.PICKUP_RADIUS,
    PICKUP_DELAY    = DEFAULTS.PICKUP_DELAY,
    PICKUP_ENABLED  = DEFAULTS.PICKUP_ENABLED,
    MIN_APPARATUS   = DEFAULTS.MIN_APPARATUS,
    MIN_BOOK        = DEFAULTS.MIN_BOOK,
    MIN_CLOTHING    = DEFAULTS.MIN_CLOTHING,
    MIN_ARMOR       = DEFAULTS.MIN_ARMOR,
    MIN_WEAPON      = DEFAULTS.MIN_WEAPON,
    MIN_INGREDIENT  = DEFAULTS.MIN_INGREDIENT,
    MIN_POTION      = DEFAULTS.MIN_POTION,
    MIN_LOCKPICK    = DEFAULTS.MIN_LOCKPICK,
    MIN_PROBE       = DEFAULTS.MIN_PROBE,
    MIN_REPAIR      = DEFAULTS.MIN_REPAIR,
    MIN_MISC        = DEFAULTS.MIN_MISC,
}

local allowedItems = {}

local function registerDrop(recordId)
    allowedItems[recordId] = true
end

local function isAllowed(recordId)
    return allowedItems[recordId] == true
end

local function consumeAllowed(recordId)
    allowedItems[recordId] = nil
end

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

local function isValuable(item)
    local id = string.lower(item.recordId)
    if shared.GOLD_IDS[id] then return true end
    if types.Ingredient.objectIsInstance(item) then
        return types.Ingredient.record(item).value > cachedSettings.MIN_INGREDIENT
    end
    if types.Potion.objectIsInstance(item) then
        return types.Potion.record(item).value > cachedSettings.MIN_POTION
    end
    if types.Apparatus.objectIsInstance(item) then
        return types.Apparatus.record(item).value > cachedSettings.MIN_APPARATUS
    end
    if types.Book.objectIsInstance(item) then
        return types.Book.record(item).value >= cachedSettings.MIN_BOOK
    end
    if types.Clothing.objectIsInstance(item) then
        return types.Clothing.record(item).value >= cachedSettings.MIN_CLOTHING
    end
    if types.Armor.objectIsInstance(item) then
        return types.Armor.record(item).value > cachedSettings.MIN_ARMOR
    end
    if types.Weapon.objectIsInstance(item) then
        return types.Weapon.record(item).value > cachedSettings.MIN_WEAPON
    end
    if types.Lockpick.objectIsInstance(item) then
        return types.Lockpick.record(item).value > cachedSettings.MIN_LOCKPICK
    end
    if types.Probe.objectIsInstance(item) then
        return types.Probe.record(item).value > cachedSettings.MIN_PROBE
    end
    if types.Repair.objectIsInstance(item) then
        return types.Repair.record(item).value > cachedSettings.MIN_REPAIR
    end
    if types.Miscellaneous.objectIsInstance(item) then
        return types.Miscellaneous.record(item).value > cachedSettings.MIN_MISC
    end
    return false
end

return {
    engineHandlers = {
        onItemActive = function(item)
            if not cachedSettings.PICKUP_ENABLED then return end
            if not isAllowed(item.recordId) then return end
            local id         = string.lower(item.recordId)
            local narcotic   = NARCOTIC_IDS[id] or false
            local contraband = CONTRABAND_IDS[id] or false
            local valuable   = isValuable(item)
            if not valuable and not narcotic and not contraband then return end
            local player = world.players[1]
            if not player then return end
            if (item.position - player.position):length() > cachedSettings.PICKUP_RADIUS then return end
            local pauperContraband = contraband and PAUPER_CONTRABAND[id] or false
            player:sendEvent("NpcPickupCheck", {
                item             = item,
                narcotic         = narcotic,
                contraband       = contraband,
                pauperContraband = pauperContraband,
            })
        end,
    },

    eventHandlers = {
        GreedyNPCs_SettingsUpdated = function(data)
            cachedSettings = data
        end,

        NpcPickupRegister = function(data)
            if data and data.recordId then
                registerDrop(data.recordId)
            end
        end,

        NpcPickupRegisterBatch = function(data)
            if not data or not data.ids then return end
            for id in pairs(data.ids) do
                registerDrop(id)
            end
        end,

        NpcPickupItem = function(data)
            local item = data.item
            local npc  = data.npc
            if not item or not item:isValid() then return end
            if not npc  or not npc:isValid()  then return end
            consumeAllowed(item.recordId)
            async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
                if not item:isValid() then return end
                if not npc:isValid() or types.Actor.isDead(npc) then return end
                local player = world.players[1]
                if not player then return end
                if (item.position - player.position):length() > cachedSettings.PICKUP_RADIUS then return end
                if item.cell == nil then return end
                item:moveInto(types.Actor.inventory(npc))
                local id = string.lower(item.recordId)
                local sound
                if shared.GOLD_IDS[id] then
                    sound = "Item Gold Up"
                elseif types.Weapon.objectIsInstance(item) then
                    sound = "Item Weapon Shortblade Up"
                elseif types.Book.objectIsInstance(item) then
                    sound = "Item Book Up"
                elseif types.Apparatus.objectIsInstance(item) then
                    sound = "Item Apparatus Up"
                elseif types.Clothing.objectIsInstance(item) then
                    sound = "Item Clothes Up"
                elseif types.Armor.objectIsInstance(item) then
                    sound = "Item Armor Medium Up"
                elseif types.Ingredient.objectIsInstance(item) then
                    sound = "Item Ingredient Up"
                elseif types.Potion.objectIsInstance(item) then
                    sound = "Item Potion Up"
                elseif types.Lockpick.objectIsInstance(item) then
                    sound = "Item Lockpick Up"
                elseif types.Probe.objectIsInstance(item) then
                    sound = "Item Probe Up"
                elseif types.Repair.objectIsInstance(item) then
                    sound = "Item Repair Up"
                elseif id == "potion_skooma_01" then
                    sound = "Item Potion Up"
                else
                    sound = "Item Misc Up"
                end
                core.sound.playSound3d(sound, npc)
                local npcName = types.NPC.record(npc).name or "Someone"
                local npcRace = (types.NPC.record(npc).race or ""):lower()
                local itemId  = string.lower(item.recordId)
                local msg
                if KHAJIIT_RACE[npcRace] then
                    msg = khajiitMessage(itemId == "ingred_moon_sugar_01")
                else
                    msg = randomMessage()
                end
                player:sendEvent("NpcPickupMessage", {
                    message = npcName .. ": \"" .. msg .. "\""
                })
            end)
        end,

        ContrabandCrime = function(data)
            if not data or not data.player then return end
            I.Crimes.commitCrime(data.player, {
                type = types.Player.OFFENSE_TYPE.Trespassing,
                victimAware = true,
            })
        end,
    },
}