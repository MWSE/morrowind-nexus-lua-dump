local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local ui      = require('openmw.ui')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local raycast = require('scripts.cursed_raycast')
local shared  = require('scripts.DoBA_shared')

local section  = storage.playerSection('SettingsDoBA')
local DEFAULTS = shared.DEFAULTS

local onUpdate, onSave, onLoad
local onShowMessage, onPlayDeathSound

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    SCAN_INTERVAL        = get('SCAN_INTERVAL'),
    MOD_ENABLED          = get('MOD_ENABLED'),
    FOLLOWER_ENABLED     = get('FOLLOWER_ENABLED'),
    REMOVE_BROKEN_CHANCE = get('REMOVE_BROKEN_CHANCE'),
}

section:subscribe(async:callback(function(_, key)
    if key then
        cachedSettings[key] = get(key)
    else
        for k in pairs(cachedSettings) do
            cachedSettings[k] = get(k)
        end
    end
end))

local lastScanTime   = 0
local summonedForIds = {}

local function processInventory()
    local inv = types.Actor.inventory(self)
    local pools = { inv:getAll(types.Armor), inv:getAll(types.Weapon) }

    local seenBroken = {}

    for _, pool in ipairs(pools) do
        for _, obj in ipairs(pool) do
            local data = types.Item.itemData(obj)
            local rId  = obj.recordId
            if data and data.condition ~= nil and data.enchantmentCharge ~= nil then
                if data.condition <= 0 then
                    seenBroken[rId] = true
                    if not summonedForIds[rId] then

                        local stats = {
                            int  = types.Actor.stats.attributes.intelligence(self).modified,
                            will = types.Actor.stats.attributes.willpower(self).modified,
                            conj = types.NPC.stats.skills.conjuration(self).modified,
                        }

                        core.sendGlobalEvent("CursedItem_Summon", {
                            actor           = self,
                            charge          = data.enchantmentCharge,
                            spawnPos        = raycast.findSafeSpawnPos(self),
                            stats           = stats,
                            followerEnabled = cachedSettings.FOLLOWER_ENABLED,
                        })
                        summonedForIds[rId] = true

                        local removeChance = cachedSettings.REMOVE_BROKEN_CHANCE or 0
                        if removeChance > 0 and math.random(1, 100) <= removeChance then
                            core.sendGlobalEvent("CursedItem_RemoveBroken", {
                                actor = self,
                                item  = obj,
                            })
                            summonedForIds[rId] = nil
                        end
                    end
                else
                    summonedForIds[rId] = nil
                end
            end
        end
    end

    for rId in pairs(summonedForIds) do
        if not seenBroken[rId] then
            summonedForIds[rId] = nil
        end
    end
end

-- engine handlers
onUpdate = function()
    if not cachedSettings.MOD_ENABLED then return end
    local now = core.getSimulationTime()
    if now - lastScanTime >= cachedSettings.SCAN_INTERVAL then
        lastScanTime = now
        processInventory()
    end
end

onSave = function()
    return {
        summonedForIds = summonedForIds,
        lastScanTime   = lastScanTime,
    }
end

onLoad = function(saved)
    if not saved then return end
    summonedForIds = saved.summonedForIds or {}
    lastScanTime   = saved.lastScanTime or 0
end

-- event handlers
onShowMessage = function(data)
    ui.showMessage(data.message)
    ambient.playSound("conjuration cast")
    ambient.playSound("conjuration hit")
end

onPlayDeathSound = function()
    ambient.playSound("conjuration hit")
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        CursedItem_ShowMessage    = onShowMessage,
        CursedItem_PlayDeathSound = onPlayDeathSound,
    },
}