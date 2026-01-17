local animation = require('openmw.animation')
local input = require('openmw.input')
local gameSelf = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local forceRelease = false
local BlasterData = require('scripts.sw4.data.blasters')
local LogMessage = require('scripts.sw4.helper.logmessage')
local ModInfo = require('scripts.sw4.modinfo')

local AutoBlasterStorage = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'BlasterGroupAutomatic')
local SpeedBlasterStorage = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'BlasterGroupSpeed')

local WeaponSlot = gameSelf.type.EQUIPMENT_SLOT.CarriedRight
local CrossbowType = types.Weapon.TYPE.MarksmanCrossbow
local BowType = types.Weapon.TYPE.MarksmanBow

local Stats = gameSelf.type.stats
local Skills = Stats.skills
local Attributes = Stats.attributes

local SkillMarksman = Skills.marksman(gameSelf)

local GlobalManagement

--- Handles animation text keys and shoot overrides for the player
--- Allows automatic shooting of blasters
---@class ShootManager
---@field onFrame fun(self, dt: number): nil If signalled by the animation handlers, will force the player to engage or release an attack
---@field textKeyHandler fun(_: string, key: string): nil Signals the onFrame handler to start/release an attack depending on animation state
local ShootManager = {
    CurrentShotCooldown = 0,
    BlasterTypes = BlasterData.Types,
}

function ShootManager:onFrame(dt)
    ShootManager.CurrentShotCooldown = math.max(0.0, ShootManager.CurrentShotCooldown - dt)

    if forceRelease and ShootManager.CurrentShotCooldown <= 0.0 then
        gameSelf.controls.use = 0
        forceRelease = false
        ShootManager.CurrentShotCooldown = ShootManager.getBlasterDelay(ShootManager.getBlasterType())
    end
end

local BlasterSettingNames = {
    [BlasterData.Types.Pistol] = {
        UseAuto = 'AutomaticPistolsEnable',
        UseCancel = 'AutomaticPistolsCancelAnimations',
        SpeedMult = 'SpeedMultPistol',
        CooldownMin = 'PistolCooldownMin',
        CooldownMax = 'PistolCooldownMax',
    },
    [BlasterData.Types.Rifle] = {
        UseAuto = 'AutomaticRiflesEnable',
        UseCancel = 'AutomaticRiflesCancelAnimations',
        SpeedMult = 'SpeedMultRifle',
        CooldownMin = 'RifleCooldownMin',
        CooldownMax = 'RifleCooldownMax',
    },
    [BlasterData.Types.Repeater] = {
        UseAuto = 'AutomaticRepeatersEnable',
        UseCancel = 'AutomaticRepeatersCancelAnimations',
        SpeedMult = 'SpeedMultRepeater',
        CooldownMin = 'RepeaterCooldownMin',
        CooldownMax = 'RepeaterCooldownMax',
    },
    [BlasterData.Types.Sniper] = {
        UseAuto = 'AutomaticSnipersEnable',
        UseCancel = 'AutomaticSnipersCancelAnimations',
        SpeedMult = 'SpeedMultSniper',
        CooldownMin = 'SniperCooldownMin',
        CooldownMax = 'SniperCooldownMax',
    },
}

function ShootManager.getBlasterDelay(blasterType)
    local cooldownMin, cooldownMax = ShootManager.getBlasterCooldowns(blasterType)

    local effectiveMarksman = math.min(100, SkillMarksman.base)

    local actualDelay = util.remap(effectiveMarksman, 100, 1, cooldownMin, cooldownMax)

    LogMessage('Shoot Handler: Blaster shot delay: ' .. tostring(actualDelay))
    return actualDelay
end

---@alias BlasterType number

---@param blasterType BlasterType
---@return boolean
function ShootManager.canFireAutomatically(blasterType)
    local blasterSetting = AutoBlasterStorage:get('AutomaticBlastersEnable')
    if not blasterSetting then return false end

    return AutoBlasterStorage:get(BlasterSettingNames[blasterType].UseAuto)
end

---@param blasterType BlasterType
---@return boolean
function ShootManager.canAnimCancel(blasterType)
    return AutoBlasterStorage:get(BlasterSettingNames[blasterType].UseCancel)
end

---@param blasterType BlasterType
---@return number TypedCooldown cooldown between shots per blaster type
function ShootManager.getBlasterCooldowns(blasterType)
    local blasterSettings = BlasterSettingNames[blasterType]
    return SpeedBlasterStorage:get(blasterSettings.CooldownMin),
        SpeedBlasterStorage:get(blasterSettings.CooldownMax)
end

function ShootManager.isRangedWeapon(equippedWeapon)
    local weaponRecord = equippedWeapon.type.records[equippedWeapon.recordId]
    return weaponRecord.type == CrossbowType or weaponRecord.type == BowType
end

function ShootManager.getBlasterType()
    local blaster = gameSelf.type.getEquipment(gameSelf, WeaponSlot)

    if not blaster or not ShootManager.isRangedWeapon(blaster) then return BlasterData.Types.None end

    local blasterId = blaster.recordId

    for blasterType, blasterGroup in pairs(BlasterData) do
        if blasterGroup[blasterId] then
            LogMessage('Shoot Handler: Found blaster type: ' .. tostring(blasterType) .. ' ' .. blasterId)
            return BlasterData.Types[blasterType]
        end
    end

    LogMessage('Shoot Handler: Unknown blaster type: ' .. blasterId)
    return BlasterData.Types.None
end

--- Get the speed multiplier for the current blaster type
---@param blasterType BlasterType
function ShootManager.getBlasterSpeedMultiplier(blasterType)
    local speedFactor = math.min(100, SkillMarksman.base) / 100
    local blasterMultiplier = SpeedBlasterStorage:get(BlasterSettingNames[blasterType].SpeedMult)
    assert(blasterMultiplier, 'Shoot Handler: No blaster multiplier found for blaster type: ' .. blasterType)

    local speed = blasterMultiplier * speedFactor
    LogMessage('Shoot Handler: Blaster speed multiplier: ' .. tostring(speed))

    return 1 + speed
end

function ShootManager.textKeyHandler(group, key)
    local blasterType = ShootManager.getBlasterType()

    if not ShootManager.canFireAutomatically(blasterType) then
        LogMessage('Shoot Handler: Automatic fire not enabled for the current blaster type.')
        return
    end

    if key == 'shoot start' then
        LogMessage("Shoot Handler: Increasing shoot speed!")

        animation.setSpeed(gameSelf, group, ShootManager.getBlasterSpeedMultiplier(blasterType))
    elseif key == 'shoot min hit' or key == 'shoot max attack' then
        if gameSelf.controls.use == 0 or not input.getBooleanActionValue('Use') then return end

        LogMessage('Shoot Handler: Releasing shot!')

        forceRelease = true
    elseif key == 'shoot follow start' and ShootManager.canAnimCancel(blasterType) then
        LogMessage('Shoot Handler: Cancelling animation!')
        animation.cancel(gameSelf, group)
    end
end

I.AnimationController.addTextKeyHandler('crossbow', ShootManager.textKeyHandler)
I.AnimationController.addTextKeyHandler('bowandarrow', ShootManager.textKeyHandler)

---@param managementStore ManagementStore
---@return ShootManager
return function(managementStore)
    assert(managementStore)
    GlobalManagement = managementStore
    return ShootManager
end
