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

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    SCAN_INTERVAL = get('SCAN_INTERVAL'),
    MOD_ENABLED = get('MOD_ENABLED'),
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
    local all = types.Actor.inventory(self):getAll()
    for _, obj in ipairs(all) do
        local isEquippable = types.Armor.objectIsInstance(obj) or types.Weapon.objectIsInstance(obj)
        if isEquippable then
            local data = types.Item.itemData(obj)
            local rId  = obj.recordId
            if data and data.condition ~= nil and data.enchantmentCharge ~= nil then
                if data.condition <= 0 then
                    if not summonedForIds[rId] then
                        core.sendGlobalEvent("CursedItem_Summon", {
                            actor    = self,
                            charge   = data.enchantmentCharge,
                            spawnPos = raycast.findSafeSpawnPos(self)
                        })
                        summonedForIds[rId] = true
                    end
                elseif data.condition > 0 then
                    summonedForIds[rId] = nil
                end
            end
        end
    end
end

return {
    engineHandlers = {
        onUpdate = function()
        if not cachedSettings.MOD_ENABLED then return end
            local now = core.getSimulationTime()
            if now - lastScanTime >= cachedSettings.SCAN_INTERVAL then
                lastScanTime = now
                processInventory()
            end
        end
    },
    eventHandlers = {
        CursedItem_ShowMessage = function(data)
            ui.showMessage(data.message)
            ambient.playSound("conjuration cast")
            ambient.playSound("conjuration hit")
        end,
        CursedItem_PlayDeathSound = function()
            ambient.playSound("conjuration hit")
        end
    }
}