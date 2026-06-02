local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')

local inventoryExtender = require('scripts.WeaponPoisoning.inventoryExtender')

local STATUS_SPELL_ID = 'wp_poisoned_weapon_status'
local DEFAULT_ALCHEMY_POISON_APPLICATION_GAIN = 0.1

local poisonedWeapons = {}
local activeWeaponId = nil
local activePoisonId = nil
local inInventory = false
local lastModEnabled = nil
local lastSuppressPoisonApplication = nil
local lastForcePoisonApplication = nil
local lastAutoReapplyPoison = nil
local lastStackPoisonsOnTarget = nil
local lastProtectStrongerPoison = nil
local lastNpcPoisoning = nil
local lastNpcPotionsRefinedIntegration = nil
local lastNpcReapplyCooldown = nil
local lastNpcGeneratedPoisonMaxCount = nil
local lastNpcPoisonAnimation = nil
local lastNpcDebugLogging = nil
local lastPoisonHitVfx = nil
local lastPoisonHitSound = nil
local lastPoisonVfxFullDuration = nil
local inventoryExtenderInitialized = false

local function isModEnabled()
    return storage.playerSection('Settings/WeaponPoisoning/1_Gameplay'):get('EnableMod') ~= false
end

local function gameplaySettings()
    return storage.playerSection('Settings/WeaponPoisoning/1_Gameplay')
end

local function showMessages()
    return gameplaySettings():get('ShowMessages') ~= false
end

local function keybindSettings()
    return storage.playerSection('Settings/WeaponPoisoning/2_Keybinds')
end

local function npcSettings()
    return storage.playerSection('Settings/WeaponPoisoning/3_NPC')
end

local function integrationsSettings()
    return storage.playerSection('Settings/WeaponPoisoning/4_Integrations')
end

local function vfxSettings()
    return storage.playerSection('Settings/WeaponPoisoning/5_VFX')
end

local function isInventoryExtenderIntegrationEnabled()
    return integrationsSettings():get('EnableInventoryExtenderIntegration') ~= false
end

local function currentWeapon()
    return types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
end

local function hasStatus()
    for _, spell in pairs(types.Actor.spells(self)) do
        if spell.id == STATUS_SPELL_ID then
            return true
        end
    end
    return false
end

local function removeLegacyTimedStatus()
    local activeSpells = types.Actor.activeSpells(self)
    for _, spell in pairs(activeSpells) do
        if spell.id == STATUS_SPELL_ID and spell.activeSpellId and spell.temporary then
            pcall(function()
                activeSpells:remove(spell.activeSpellId)
            end)
        end
    end
end

local function removeStatus()
    pcall(function()
        types.Actor.spells(self):remove(STATUS_SPELL_ID)
    end)
    removeLegacyTimedStatus()
    activeWeaponId = nil
    activePoisonId = nil
end

local function addStatus(weaponId, poisonId)
    removeLegacyTimedStatus()
    if hasStatus() then
        pcall(function()
            types.Actor.spells(self):remove(STATUS_SPELL_ID)
        end)
    end
    activeWeaponId = weaponId
    activePoisonId = poisonId
end

local function applyStatusForWeapon(weaponId, poisonId)
    if not poisonId then
        if activeWeaponId or activePoisonId or hasStatus() then
            removeStatus()
        end
        return
    end

    if activeWeaponId == weaponId and activePoisonId == poisonId then
        return
    end

    addStatus(weaponId, poisonId)
end

local function refreshStatus()
    if not isModEnabled() then
        if activeWeaponId or activePoisonId or hasStatus() then
            removeStatus()
        end
        return
    end

    local weapon = currentWeapon()
    local weaponId = weapon and weapon.id or nil
    local poisonId = weaponId and poisonedWeapons[weaponId] or nil
    applyStatusForWeapon(weaponId, poisonId)
end

local function syncPoisonedWeapons(data)
    poisonedWeapons = data and data.poisonedWeapons or {}
    if not inInventory then
        refreshStatus()
    end
end

local function onEquipmentEvent(data)
    if not data or not data.item or data.item.type == types.Weapon then
        if not inInventory then
            refreshStatus()
        end
    end
end

local function syncModEnabled()
    local enabled = isModEnabled()
    if enabled ~= lastModEnabled then
        lastModEnabled = enabled
        core.sendGlobalEvent('WP_SetModEnabled', { enabled = enabled })
    end
end

local function syncSuppressPoisonApplication()
    local key = keybindSettings():get('SuppressPoisonApplicationKey')
    local suppress = input.isKeyPressed(type(key) == 'number' and key or input.KEY.RightCtrl)
    if suppress ~= lastSuppressPoisonApplication then
        lastSuppressPoisonApplication = suppress
        core.sendGlobalEvent('WP_SetSuppressPoisonApplication', { suppress = suppress })
    end
end

local function syncForcePoisonApplication()
    local key = keybindSettings():get('ForcePoisonApplicationKey')
    local force = input.isKeyPressed(type(key) == 'number' and key or input.KEY.RightAlt)
    if force ~= lastForcePoisonApplication then
        lastForcePoisonApplication = force
        core.sendGlobalEvent('WP_SetForcePoisonApplication', { force = force })
    end
end

local function syncAutoReapplyPoison()
    local autoReapply = gameplaySettings():get('AutoReapplyPoison') == true
    if autoReapply ~= lastAutoReapplyPoison then
        lastAutoReapplyPoison = autoReapply
        core.sendGlobalEvent('WP_SetAutoReapplyPoison', { autoReapply = autoReapply })
    end
end

local function syncStackPoisonsOnTarget()
    local stackPoisons = gameplaySettings():get('StackPoisonsOnTarget') == true
    if stackPoisons ~= lastStackPoisonsOnTarget then
        lastStackPoisonsOnTarget = stackPoisons
        core.sendGlobalEvent('WP_SetStackPoisonsOnTarget', { stackPoisons = stackPoisons })
    end
end

local function syncProtectStrongerPoison()
    local protect = gameplaySettings():get('ProtectStrongerPoison') ~= false
    if protect ~= lastProtectStrongerPoison then
        lastProtectStrongerPoison = protect
        core.sendGlobalEvent('WP_SetProtectStrongerPoison', { protect = protect })
    end
end

local function syncNpcPoisoning()
    local enabled = npcSettings():get('EnableNpcPoisoning') ~= false
    if enabled ~= lastNpcPoisoning then
        lastNpcPoisoning = enabled
        core.sendGlobalEvent('WP_SetNpcPoisoning', { enabled = enabled })
    end
end

local function syncNpcPotionsRefinedIntegration()
    local enabled = integrationsSettings():get('EnableNpcPotionsRefinedIntegration') ~= false
    if enabled ~= lastNpcPotionsRefinedIntegration then
        lastNpcPotionsRefinedIntegration = enabled
        core.sendGlobalEvent('WP_SetNpcPotionsRefinedIntegration', { enabled = enabled })
    end
end

local function syncNpcReapplyCooldown()
    local seconds = npcSettings():get('NpcPoisonReapplyCooldownSeconds')
    if type(seconds) ~= 'number' then
        seconds = 10
    end
    seconds = math.max(0, math.min(60, seconds))
    if seconds ~= lastNpcReapplyCooldown then
        lastNpcReapplyCooldown = seconds
        core.sendGlobalEvent('WP_SetNpcReapplyCooldown', { seconds = seconds })
    end
end

local function syncNpcGeneratedPoisonMaxCount()
    local count = npcSettings():get('NpcGeneratedPoisonMaxCount')
    if type(count) ~= 'number' then
        count = 3
    end
    count = math.max(1, math.min(10, math.floor(count)))
    if count ~= lastNpcGeneratedPoisonMaxCount then
        lastNpcGeneratedPoisonMaxCount = count
        core.sendGlobalEvent('WP_SetNpcGeneratedPoisonMaxCount', { count = count })
    end
end

local function syncNpcPoisonAnimation()
    local enabled = npcSettings():get('EnableNpcPoisonAnimation') ~= false
    if enabled ~= lastNpcPoisonAnimation then
        lastNpcPoisonAnimation = enabled
        core.sendGlobalEvent('WP_SetNpcPoisonAnimation', { enabled = enabled })
    end
end

local function syncNpcDebugLogging()
    local enabled = npcSettings():get('EnableNpcDebugLogging') == true
    if enabled ~= lastNpcDebugLogging then
        lastNpcDebugLogging = enabled
        core.sendGlobalEvent('WP_SetNpcDebugLogging', { enabled = enabled })
    end
end

local function syncPoisonHitVfxSettings()
    local vfxEnabled = vfxSettings():get('EnablePoisonHitVfx') ~= false
    local soundEnabled = vfxSettings():get('EnablePoisonHitSound') ~= false
    local fullDuration = vfxSettings():get('ShowPoisonVfxForFullDuration') ~= false
    if vfxEnabled ~= lastPoisonHitVfx
        or soundEnabled ~= lastPoisonHitSound
        or fullDuration ~= lastPoisonVfxFullDuration
    then
        lastPoisonHitVfx = vfxEnabled
        lastPoisonHitSound = soundEnabled
        lastPoisonVfxFullDuration = fullDuration
        core.sendGlobalEvent('WP_SetPoisonHitVfxSettings', {
            vfxEnabled = vfxEnabled,
            soundEnabled = soundEnabled,
            fullDuration = fullDuration,
        })
    end
end

local function grantAlchemyProgress()
    local skillProgression = I.SkillProgression
    if not skillProgression or type(skillProgression.skillUsed) ~= 'function' then
        return
    end

    local skillGain = gameplaySettings():get('AlchemyProgressGain')
    if type(skillGain) ~= 'number' then
        skillGain = DEFAULT_ALCHEMY_POISON_APPLICATION_GAIN
    end
    skillGain = math.max(0, math.min(1, skillGain))
    if skillGain <= 0 then
        return
    end

    local useTypes = skillProgression.SKILL_USE_TYPES or {}
    skillProgression.skillUsed('alchemy', {
        useType = useTypes.Alchemy_CreatePotion,
        skillGain = skillGain,
    })
end

local function poisonRecordForWeapon(weapon)
    if not isModEnabled() then
        return nil
    end
    if not weapon or weapon.type ~= types.Weapon then
        return nil
    end
    local poisonId = poisonedWeapons[weapon.id]
    return poisonId and types.Potion.records[poisonId] or nil
end

local function initInventoryExtenderIntegration()
    if inventoryExtenderInitialized then
        return
    end
    if not isInventoryExtenderIntegrationEnabled() then
        return
    end
    inventoryExtenderInitialized = inventoryExtender.init({
        enabled = isInventoryExtenderIntegrationEnabled,
        poisonRecordForWeapon = poisonRecordForWeapon,
    }) == true
end

local function initIntegrations()
    initInventoryExtenderIntegration()
end

local function syncSettings()
    syncModEnabled()
    syncSuppressPoisonApplication()
    syncForcePoisonApplication()
    syncAutoReapplyPoison()
    syncStackPoisonsOnTarget()
    syncProtectStrongerPoison()
    syncNpcPoisoning()
    syncNpcPotionsRefinedIntegration()
    syncNpcReapplyCooldown()
    syncNpcGeneratedPoisonMaxCount()
    syncNpcPoisonAnimation()
    syncNpcDebugLogging()
    syncPoisonHitVfxSettings()
end

return {
    eventHandlers = {
        WP_SyncPoisonedWeapons = syncPoisonedWeapons,
        WP_ShowMessage = function(data)
            if showMessages() and data and data.text then
                ui.showMessage(data.text)
            end
        end,
        WP_GrantAlchemyProgress = grantAlchemyProgress,
        ItemEquipped = onEquipmentEvent,
        ItemUnequipped = onEquipmentEvent,
        UiModeChanged = function(data)
            if data and data.oldMode == 'Inventory' and data.newMode ~= 'Inventory' then
                inInventory = false
                refreshStatus()
            elseif data and data.newMode == 'Inventory' then
                inInventory = true
            end
        end,
    },
    engineHandlers = {
        onInit = function()
            initIntegrations()
            removeStatus()
            core.sendGlobalEvent('WP_RequestSync')
            lastModEnabled = nil
            lastSuppressPoisonApplication = nil
            lastForcePoisonApplication = nil
            lastAutoReapplyPoison = nil
            lastStackPoisonsOnTarget = nil
            lastProtectStrongerPoison = nil
            lastNpcPoisoning = nil
            lastNpcPotionsRefinedIntegration = nil
            lastNpcReapplyCooldown = nil
            lastNpcGeneratedPoisonMaxCount = nil
            lastNpcPoisonAnimation = nil
            lastNpcDebugLogging = nil
            lastPoisonHitVfx = nil
            lastPoisonHitSound = nil
            lastPoisonVfxFullDuration = nil
            syncSettings()
        end,
        onLoad = function()
            initIntegrations()
            removeStatus()
            core.sendGlobalEvent('WP_RequestSync')
            lastModEnabled = nil
            lastSuppressPoisonApplication = nil
            lastForcePoisonApplication = nil
            lastAutoReapplyPoison = nil
            lastStackPoisonsOnTarget = nil
            lastProtectStrongerPoison = nil
            lastNpcPoisoning = nil
            lastNpcPotionsRefinedIntegration = nil
            lastNpcReapplyCooldown = nil
            lastNpcGeneratedPoisonMaxCount = nil
            lastNpcPoisonAnimation = nil
            lastNpcDebugLogging = nil
            lastPoisonHitVfx = nil
            lastPoisonHitSound = nil
            lastPoisonVfxFullDuration = nil
            syncSettings()
        end,
        onFrame = function()
            syncSettings()
        end,
        onUpdate = function()
            initIntegrations()
            if not inInventory then
                refreshStatus()
            end
        end,
    },
}
