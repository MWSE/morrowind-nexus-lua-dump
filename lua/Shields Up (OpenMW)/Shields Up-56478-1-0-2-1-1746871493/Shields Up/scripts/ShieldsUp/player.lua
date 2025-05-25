-- scripts/ShieldsUp/player.lua
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
-- local ui = require('openmw.ui') -- Not directly used for UI elements here
local anim = require('openmw.animation')
local Controls = require('openmw.interfaces').Controls
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces') -- Already required, but good to note

local modInfo = require('scripts.ShieldsUp.modInfo')

-- default fucker block button (Right Click) - used if setting is not found
local defaultBlockButton = 3
-- Controller block button
local CONST_CONTROLLER_BLOCK_BUTTON = input.CONTROLLER_BUTTON.LeftShoulder

-- Runtime state variables
local isBlocking = false
local hasShieldEquipped = false
local isInWeaponStance = false
local hasOneHandedWeapon = false
local isBlockDebuffed = false
local isBlockBuffActive = false -- Track if the active block buff is applied

-- NPC and Actor stats types
local skills = types.NPC.stats.skills
local attributes = types.Actor.stats.attributes

-- Runtime settings variables (will be populated by updateSettings)
local blockBuffPercent
local weaponDebuffPercent
local speedDebuffPercent
local blockButton

-- Default values for settings (used if not found in storage)
local blockBuffPercent_default = 65
local weaponDebuffPercent_default = 35
local speedDebuffPercent_default = 35

-- Storage keys for settings values
local generalSettingsStorageKey = 'Settings/' .. modInfo.name .. '/General'
local keybindsStorageKey = 'Settings/' .. modInfo.name .. '/Keybinds'
local blockKeybindSettingKeyInStorage = 'blockKeybind' -- Name of the key within the keybinds group

-- Store modifier values for saving/loading
local savedBlockModifier = 0
local blockDebuffModifier = 0 -- Store the modifier applied by the 100% debuff

local function modifySkill(skill, percent, isBuff)
    if not skill or skill.base == nil then print("[ShieldsUp] ERROR: Invalid skill object in modifySkill"); return 0 end
    if percent == 0 then return 0 end
    local modValue = math.floor(skill.base * (percent / 100))
    if modValue == 0 and percent ~= 0 and skill.base > 0 then
        modValue = (percent > 0) and 1 or -1
    end
    skill.modifier = skill.modifier + (isBuff and modValue or -modValue)
    return modValue
end

local function modifyAttribute(attribute, percent, isBuff)
    if not attribute or attribute.base == nil then print("[ShieldsUp] ERROR: Invalid attribute object in modifyAttribute"); return 0 end
    if percent == 0 then return 0 end
    local modValue = math.floor(attribute.base * (percent / 100))
    if modValue == 0 and percent ~= 0 and attribute.base > 0 then
         modValue = (percent > 0) and 1 or -1
    end
    attribute.modifier = attribute.modifier + (isBuff and modValue or -modValue)
    return modValue
end

local function updateEquipmentStatus()
    local shield = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    hasShieldEquipped = shield ~= nil and shield.type == types.Armor

    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and weapon.recordId then -- Check if weapon and recordId exist
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

local function shouldApplyBlockDebuff()
    return isInWeaponStance and hasShieldEquipped and hasOneHandedWeapon
end

local function applyBlockDebuff()
    if shouldApplyBlockDebuff() and not isBlockDebuffed then
        local currentBlockSkill = skills.block(self)
        if currentBlockSkill.base ~= nil then
            blockDebuffModifier = -currentBlockSkill.base -- Apply a 100% reduction based on the base skill
            currentBlockSkill.modifier = currentBlockSkill.modifier + blockDebuffModifier
            isBlockDebuffed = true
        end
    elseif not shouldApplyBlockDebuff() and isBlockDebuffed then
        local currentBlockSkill = skills.block(self)
        if currentBlockSkill.base ~= nil then
            currentBlockSkill.modifier = currentBlockSkill.modifier - blockDebuffModifier
            blockDebuffModifier = 0
            isBlockDebuffed = false
        end
    end
end

local function canBlock()
    return isInWeaponStance and hasShieldEquipped and hasOneHandedWeapon and not isBlocking
end

local function _performBlockStart()
    isBlocking = true
    isBlockBuffActive = true -- Mark the buff as active
    -- Controls.overrideCombatControls(true) -- Ensure this line is commented out

    -- Temporarily remove the block debuff if it's active
    if isBlockDebuffed then
        local currentBlockSkill = skills.block(self)
        if currentBlockSkill.base ~= nil then
            currentBlockSkill.modifier = currentBlockSkill.modifier - blockDebuffModifier
        end
        isBlockDebuffed = false
    end

    savedBlockModifier = modifySkill(skills.block(self), blockBuffPercent, true)
    modifySkill(skills.axe(self), weaponDebuffPercent, false)
    modifySkill(skills.bluntweapon(self), weaponDebuffPercent, false)
    modifySkill(skills.longblade(self), weaponDebuffPercent, false)
    modifySkill(skills.shortblade(self), weaponDebuffPercent, false)
    modifyAttribute(attributes.speed(self), speedDebuffPercent, false)

    I.AnimationController.playBlendedAnimation('shieldraise', {
        startKey = 'start', stopKey = 'stop', priority = {[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon},
        autoDisable = false, blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm,
    })
end

local function _performBlockEnd()
    isBlocking = false
    isBlockBuffActive = false -- Mark the buff as inactive
    Controls.overrideCombatControls(false)

    local currentBlockSkill = skills.block(self)

    if savedBlockModifier ~= 0 and currentBlockSkill then
        currentBlockSkill.modifier = currentBlockSkill.modifier - savedBlockModifier
        savedBlockModifier = 0
    end

    modifySkill(skills.axe(self), weaponDebuffPercent, true)
    modifySkill(skills.bluntweapon(self), weaponDebuffPercent, true)
    modifySkill(skills.longblade(self), weaponDebuffPercent, true)
    modifySkill(skills.shortblade(self), weaponDebuffPercent, true)
    modifyAttribute(attributes.speed(self), speedDebuffPercent, true)

    -- Re-apply the block debuff if the conditions are met
    if shouldApplyBlockDebuff() and not isBlockDebuffed then
        applyBlockDebuff()
    end

    I.AnimationController.playBlendedAnimation('idle1', {
        startKey = 'loop start', stopKey = 'loop stop', priority = {[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon},
        autoDisable = true,
    })
end

local function onMouseButtonPress_handler(button_code)
    local isPaused = core.isWorldPaused()
    local uiMode = I.UI and I.UI:getMode()
    if isPaused or (uiMode and (uiMode == "Dialogue" or uiMode == "Inventory")) then return end
    updateEquipmentStatus()
    if button_code == blockButton and canBlock() and hasShieldEquipped then _performBlockStart() end
end

local function onMouseButtonRelease_handler(button_code)
    local isPaused = core.isWorldPaused()
    local uiMode = I.UI and I.UI:getMode()
    if isPaused or (uiMode and (uiMode == "Dialogue" or uiMode == "Inventory")) then return end
    if button_code == blockButton and isBlocking then _performBlockEnd() end
end

local function onKeyPress_handler(event)
    local isPaused = core.isWorldPaused()
    local uiMode = I.UI and I.UI:getMode()
    if isPaused or (uiMode and (uiMode == "Dialogue" or uiMode == "Inventory")) then return end
    updateEquipmentStatus()
    local key_code = event.code
    if key_code == blockButton and canBlock() and hasShieldEquipped then _performBlockStart() end
end

local function onKeyRelease_handler(event)
    local isPaused = core.isWorldPaused()
    local uiMode = I.UI and I.UI:getMode()
    if isPaused or (uiMode and (uiMode == "Dialogue" or uiMode == "Inventory")) then return end
    local key_code = event.code
    if key_code == blockButton and isBlocking then _performBlockEnd() end
end

local function onControllerButtonPress_handler(cbutton)
    local isPaused = core.isWorldPaused()
    local uiMode = I.UI and I.UI:getMode()
    if isPaused or (uiMode and (uiMode == "Dialogue" or uiMode == "Inventory")) then return end
    updateEquipmentStatus()
    if cbutton == CONST_CONTROLLER_BLOCK_BUTTON and canBlock() and hasShieldEquipped then _performBlockStart() end
end

local function onControllerButtonRelease_handler(cbutton)
    local isPaused = core.isWorldPaused()
    local uiMode = I.UI and I.UI:getMode()
    if isPaused or (uiMode and (uiMode == "Dialogue" or uiMode == "Inventory")) then return end
    if cbutton == CONST_CONTROLLER_BLOCK_BUTTON and isBlocking then _performBlockEnd() end
end

local generalSettings_storage = storage.playerSection(generalSettingsStorageKey)
local keybinds_storage = storage.playerSection(keybindsStorageKey)

local function initializeSettingsFromStorage()
    blockBuffPercent = generalSettings_storage:get('blockBuffPercent') or blockBuffPercent_default
    weaponDebuffPercent = generalSettings_storage:get('weaponDebuffPercent') or weaponDebuffPercent_default
    speedDebuffPercent = generalSettings_storage:get('speedDebuffPercent') or speedDebuffPercent_default
    blockButton = keybinds_storage:get(blockKeybindSettingKeyInStorage) or defaultBlockButton
    -- print("[ShieldsUp Player] Initialized settings: blockButton=" .. tostring(blockButton))
end

-- Subscribe to settings changes
if generalSettings_storage.subscribe then
    generalSettings_storage:subscribe(async:callback(function()
        -- print("[ShieldsUp Player] General settings changed, re-initializing.")
        initializeSettingsFromStorage()
    end))
end
if keybinds_storage.subscribe then
     keybinds_storage:subscribe(async:callback(function()
        -- print("[ShieldsUp Player] Keybind settings changed, re-initializing.")
        initializeSettingsFromStorage()
    end))
end


local function onSave()
    return {
        isBlocking = isBlocking,
        hasShieldEquipped = hasShieldEquipped,
        isInWeaponStance = isInWeaponStance,
        hasOneHandedWeapon = hasOneHandedWeapon,
        isBlockDebuffed = isBlockDebuffed,
        isBlockBuffActive = isBlockBuffActive,
        savedBlockModifier = savedBlockModifier,
        blockDebuffModifier = blockDebuffModifier,
    }
end

local function onLoad(data)
    initializeSettingsFromStorage() -- Load settings first

    if data then
        isBlocking = data.isBlocking or false
        hasShieldEquipped = data.hasShieldEquipped or false
        isInWeaponStance = data.isInWeaponStance or false
        hasOneHandedWeapon = data.hasOneHandedWeapon or false
        isBlockDebuffed = data.isBlockDebuffed or false
        isBlockBuffActive = data.isBlockBuffActive or false
        savedBlockModifier = data.savedBlockModifier or 0
        blockDebuffModifier = data.blockDebuffModifier or 0

        local currentBlockSkill = skills.block(self)

        -- Cancel out any active buff on load
        if isBlockBuffActive and currentBlockSkill then
            currentBlockSkill.modifier = currentBlockSkill.modifier - savedBlockModifier
            savedBlockModifier = 0
            isBlockBuffActive = false
        end

        -- Re-apply the debuff based on the loaded state
        if shouldApplyBlockDebuff() and not isBlockDebuffed and currentBlockSkill.base ~= nil then
            currentBlockSkill.modifier = currentBlockSkill.modifier + blockDebuffModifier
            isBlockDebuffed = true
        elseif not shouldApplyBlockDebuff() and isBlockDebuffed and currentBlockSkill.base ~= nil then
            currentBlockSkill.modifier = currentBlockSkill.modifier - blockDebuffModifier
            blockDebuffModifier = 0
            isBlockDebuffed = false
        end
    end

    -- Ensure initial state is consistent
    updateCombatState()
    updateEquipmentStatus()
    applyBlockDebuff()
end

local function onActive_handler()
    initializeSettingsFromStorage()
    updateCombatState()
    updateEquipmentStatus()
    applyBlockDebuff()
    -- Ensure no active buff on activation (similar to load)
    if isBlockBuffActive then
        local currentBlockSkill = skills.block(self)
        if currentBlockSkill then
            currentBlockSkill.modifier = currentBlockSkill.modifier - savedBlockModifier
            savedBlockModifier = 0
            isBlockBuffActive = false
        end
    end
    -- print("[ShieldsUp Player] Script activated and initialized.")
end

local function onUpdate_handler(dt)
    local oldIsInWeaponStance = isInWeaponStance
    local oldHasShieldEquipped = hasShieldEquipped
    local oldHasOneHandedWeapon = hasOneHandedWeapon

    updateCombatState()
    updateEquipmentStatus()

    -- Re-evaluate block debuff on every update if relevant conditions change
    if oldIsInWeaponStance ~= isInWeaponStance or
        oldHasShieldEquipped ~= hasShieldEquipped or
        oldHasOneHandedWeapon ~= hasOneHandedWeapon then
        applyBlockDebuff()
    end
end

return {
    engineHandlers = {
        onMouseButtonPress = onMouseButtonPress_handler,
        onMouseButtonRelease = onMouseButtonRelease_handler,
        onKeyPress = onKeyPress_handler,
        onKeyRelease = onKeyRelease_handler,
        onControllerButtonPress = onControllerButtonPress_handler,
        onControllerButtonRelease = onControllerButtonRelease_handler,
        onActive = onActive_handler,
        onUpdate = onUpdate_handler,
        onSave = onSave,
        onLoad = onLoad,
    },
}