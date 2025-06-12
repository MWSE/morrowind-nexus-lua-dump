-- scripts/ShieldsUp/player.lua
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local anim = require('openmw.animation')
local Controls = require('openmw.interfaces').Controls
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local modInfo = require('scripts.ShieldsUp.modInfo')

-- --- Configuration ---
local defaultBlockButton = 3 -- Right Click (mouse button code)
local CONST_CONTROLLER_BLOCK_BUTTON = input.CONTROLLER_BUTTON.LeftShoulder

-- --- Script State ---
local isBlocking = false
local hasShieldEquipped = false
local isInWeaponStance = false
local hasOneHandedWeapon = false
local isPassiveDebuffActive = false

-- --- OpenMW Types ---
local skills = types.NPC.stats.skills
local attributes = types.Actor.stats.attributes

-- --- Settings (loaded from storage) ---
local blockBuffPercent
local weaponDebuffPercent
local speedDebuffPercent
local blockButton -- This will hold the key/button code from settings

-- Default values for settings
local blockBuffPercent_default = 50
local weaponDebuffPercent_default = 40
local speedDebuffPercent_default = 50

-- Storage keys
local generalSettingsStorageKey = 'Settings/' .. modInfo.name .. '/General'
local keybindsStorageKey = 'Settings/' .. modInfo.name .. '/Keybinds'
local blockKeybindSettingKeyInStorage = 'blockKeybind'

-- This table is the script's "ledger" for safe removal of effects.
local appliedValues = {
    block_mod = 0,
    axe_dmg = 0,
    blunt_dmg = 0,
    longblade_dmg = 0,
    shortblade_dmg = 0,
    speed_dmg = 0,
    passive_block_dmg = 0,
}

--
-- #region Stat Modification Helpers (Safe & Non-Destructive)
--

local function calculateValue(baseValue, percent)
    if baseValue == nil then return 0 end
    local val = math.floor(baseValue * (percent / 100))
    return (val == 0 and percent > 0 and baseValue > 0) and 1 or val
end

local function applyModifier(stat, value)
    if stat and stat.modifier ~= nil and value > 0 then
        stat.modifier = stat.modifier + value
    end
end

local function applyDamage(stat, value)
    if stat and stat.damage ~= nil and value > 0 then
        stat.damage = stat.damage + value
    end
end

local function removeModifier(stat, value)
    if stat and stat.modifier ~= nil and value > 0 then
        stat.modifier = math.max(0, stat.modifier - value)
    end
end

local function removeDamage(stat, value)
    if stat and stat.damage ~= nil and value > 0 then
        stat.damage = math.max(0, stat.damage - value)
    end
end

-- #endregion
--

local function removeAllAppliedValues()
    removeModifier(skills.block(self), appliedValues.block_mod)
    removeDamage(skills.block(self), appliedValues.passive_block_dmg)
    removeDamage(skills.axe(self), appliedValues.axe_dmg)
    removeDamage(skills.bluntweapon(self), appliedValues.blunt_dmg)
    removeDamage(skills.longblade(self), appliedValues.longblade_dmg)
    removeDamage(skills.shortblade(self), appliedValues.shortblade_dmg)
    removeDamage(attributes.speed(self), appliedValues.speed_dmg)

    for k in pairs(appliedValues) do
        appliedValues[k] = 0
    end
end

--
-- #region State Update Functions
--

local function updateEquipmentStatus()
    local shield = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    hasShieldEquipped = shield ~= nil and shield.type == types.Armor

    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and weapon.recordId then
        local weaponRecord = types.Weapon.records[weapon.recordId]
        local weaponTypes = types.Weapon.TYPE
        hasOneHandedWeapon = weaponRecord and (
            weaponRecord.type == weaponTypes.AxeOneHand or
            weaponRecord.type == weaponTypes.ShortBladeOneHand or
            weaponRecord.type == weaponTypes.LongBladeOneHand or
            weaponRecord.type == weaponTypes.BluntOneHand
        )
    else
        hasOneHandedWeapon = false
    end
end

local function updateCombatState()
    isInWeaponStance = (types.Actor.getStance(self) == types.Actor.STANCE.Weapon)
end

local function shouldApplyPassiveDebuff()
    return isInWeaponStance and hasShieldEquipped and hasOneHandedWeapon and not isBlocking
end

local function applyPassiveBlockDebuff()
    local currentBlockSkill = skills.block(self)
    if not currentBlockSkill then return end

    if shouldApplyPassiveDebuff() and not isPassiveDebuffActive then
        local debuffValue = currentBlockSkill.base
        appliedValues.passive_block_dmg = debuffValue
        applyDamage(currentBlockSkill, debuffValue)
        isPassiveDebuffActive = true
    elseif not shouldApplyPassiveDebuff() and isPassiveDebuffActive then
        removeDamage(currentBlockSkill, appliedValues.passive_block_dmg)
        appliedValues.passive_block_dmg = 0
        isPassiveDebuffActive = false
    end
end

-- #endregion
--

--
-- #region Core Blocking Logic
--

local function canBlock()
    return isInWeaponStance and hasShieldEquipped and hasOneHandedWeapon and not isBlocking
end

local function _performBlockStart()
    isBlocking = true

    if isPassiveDebuffActive then
        removeDamage(skills.block(self), appliedValues.passive_block_dmg)
        appliedValues.passive_block_dmg = 0
        isPassiveDebuffActive = false
    end

    appliedValues.block_mod = calculateValue(skills.block(self).base, blockBuffPercent)
    applyModifier(skills.block(self), appliedValues.block_mod)
    appliedValues.axe_dmg = calculateValue(skills.axe(self).base, weaponDebuffPercent)
    applyDamage(skills.axe(self), appliedValues.axe_dmg)
    appliedValues.blunt_dmg = calculateValue(skills.bluntweapon(self).base, weaponDebuffPercent)
    applyDamage(skills.bluntweapon(self), appliedValues.blunt_dmg)
    appliedValues.longblade_dmg = calculateValue(skills.longblade(self).base, weaponDebuffPercent)
    applyDamage(skills.longblade(self), appliedValues.longblade_dmg)
    appliedValues.shortblade_dmg = calculateValue(skills.shortblade(self).base, weaponDebuffPercent)
    applyDamage(skills.shortblade(self), appliedValues.shortblade_dmg)
    appliedValues.speed_dmg = calculateValue(attributes.speed(self).base, speedDebuffPercent)
    applyDamage(attributes.speed(self), appliedValues.speed_dmg)

    I.AnimationController.playBlendedAnimation('shieldraise', {
        startKey = 'start', stopKey = 'stop', priority = {[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon},
        autoDisable = false, blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
    })
end

local function _performBlockEnd()
    isBlocking = false
    Controls.overrideCombatControls(false)
    removeAllAppliedValues()
    applyPassiveBlockDebuff()

    I.AnimationController.playBlendedAnimation('idle1', {
        startKey = 'loop start', stopKey = 'loop stop', priority = {[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon},
        autoDisable = true,
    })
end

-- #endregion
--

--
-- #region Event Handlers
--

local function createInputHandler(actionFunc)
    return function(...)
        if core.isWorldPaused() or (I.UI and I.UI:getMode() ~= nil) then return end
        updateEquipmentStatus()
        actionFunc(...)
    end
end

local onKeyPress = createInputHandler(function(e)
    if e.code == blockButton and canBlock() then
        _performBlockStart()
    end
end)

local onKeyRelease = createInputHandler(function(e)
    if e.code == blockButton and isBlocking then
        _performBlockEnd()
    end
end)

local onMouseButtonPress = createInputHandler(function(button)
    if button == blockButton and canBlock() then
        _performBlockStart()
    end
end)

local onMouseButtonRelease = createInputHandler(function(button)
    if button == blockButton and isBlocking then
        _performBlockEnd()
    end
end)

local onControllerButtonPress = createInputHandler(function(button)
    if button == CONST_CONTROLLER_BLOCK_BUTTON and canBlock() then
        _performBlockStart()
    end
end)

local onControllerButtonRelease = createInputHandler(function(button)
    if button == CONST_CONTROLLER_BLOCK_BUTTON and isBlocking then
        _performBlockEnd()
    end
end)

local function onUpdate(dt)
    local oldState = {isInWeaponStance, hasShieldEquipped, hasOneHandedWeapon}
    updateCombatState()
    updateEquipmentStatus()
    if oldState[1] ~= isInWeaponStance or oldState[2] ~= hasShieldEquipped or oldState[3] ~= hasOneHandedWeapon then
        applyPassiveBlockDebuff()
    end
end

local function initializeSettingsFromStorage()
    local generalSettings = storage.playerSection(generalSettingsStorageKey)
    local keybindsSettings = storage.playerSection(keybindsStorageKey)
    blockBuffPercent = generalSettings:get('blockBuffPercent') or blockBuffPercent_default
    weaponDebuffPercent = generalSettings:get('weaponDebuffPercent') or weaponDebuffPercent_default
    speedDebuffPercent = generalSettings:get('speedDebuffPercent') or speedDebuffPercent_default
    blockButton = keybindsSettings:get(blockKeybindSettingKeyInStorage) or defaultBlockButton
end

local function onSettingsChanged()
    if isBlocking then _performBlockEnd() end
    initializeSettingsFromStorage()
    applyPassiveBlockDebuff()
end

--
-- #endregion
--

--
-- #region Save, Load, and Initialization
--

local function onSave()
    return {
        appliedValues = appliedValues
    }
end

local function onLoad(data)
    if data and data.appliedValues then
        appliedValues = data.appliedValues
        removeAllAppliedValues()
    end
    isBlocking = false
    isPassiveDebuffActive = false
    initializeSettingsFromStorage()
    updateCombatState()
    updateEquipmentStatus()
    applyPassiveBlockDebuff()
end

storage.playerSection(generalSettingsStorageKey):subscribe(async:callback(onSettingsChanged))
storage.playerSection(keybindsStorageKey):subscribe(async:callback(initializeSettingsFromStorage))

return {
    engineHandlers = {
        onActive = onLoad,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onMouseButtonPress = onMouseButtonPress,
        onMouseButtonRelease = onMouseButtonRelease,
        onControllerButtonPress = onControllerButtonPress,
        onControllerButtonRelease = onControllerButtonRelease,
    },
}