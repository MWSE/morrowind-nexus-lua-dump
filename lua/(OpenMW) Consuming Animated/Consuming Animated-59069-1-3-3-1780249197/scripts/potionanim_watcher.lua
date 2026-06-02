local self    = require('openmw.self')
local core    = require('openmw.core')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local async   = require('openmw.async')
local I       = require('openmw.interfaces')
local AI      = I.AI
local shared  = require('scripts.potionanim_shared')

-- CONSTANTS

local ANIM_GROUP = "potion"
local VFX_MESH   = "meshes/dbs/potion_standard_drink.nif"
local VFX_ID     = "potionanim_drink"
local VFX_BONE   = "Weapon Bone"

-- SETTINGS

local cachedSettings = {
    NPC_ENABLE             = shared.DEFAULTS.NPC_ENABLE,
    NPC_ANIMATION_COOLDOWN = shared.DEFAULTS.NPC_ANIMATION_COOLDOWN,
    NPC_ANIMATION_SPEED    = shared.DEFAULTS.NPC_ANIMATION_SPEED,
    NPC_LOCK_WEAPON        = shared.DEFAULTS.NPC_LOCK_WEAPON,
    NPC_SOUND_ENABLE       = shared.DEFAULTS.NPC_SOUND_ENABLE,
    NPC_SOUND_VOLUME       = shared.DEFAULTS.NPC_SOUND_VOLUME,
    NPC_SOUND_PITCH        = shared.DEFAULTS.NPC_SOUND_PITCH,
}

local function cfg(key)
    return cachedSettings[key]
end

-- ANIMATION STATE

local cooldownUntil = 0
local savedStance   = nil
local savedWeapon   = nil
local aiDisabled    = false
local animActive    = false

local function restoreStance()
    if savedStance == nil then return end
    -- only restore if the actor hasn't changed stance meanwhile
    if types.Actor.getStance(self.object) == types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, savedStance)
    end
    savedStance = nil
end

-- re-equip the weapon that was unequipped for the animation
local function restoreWeapon()
    if savedWeapon == nil then return end
    local weapon = savedWeapon
    savedWeapon = nil
    if types.Actor.isDead(self.object) then return end
    -- only re-equip if it's still in the actor's inventory
    if not weapon:isValid() then return end
    local inv = types.Actor.inventory(self)
    if not inv:find(weapon.recordId) then return end
    -- merge into the current equipment table so armor/shield are not cleared
    local equip = types.Actor.getEquipment(self.object)
    equip[types.Actor.EQUIPMENT_SLOT.CarriedRight] = weapon
    types.Actor.setEquipment(self, equip)
end

local function playDrinkSound()
    if not cfg('NPC_SOUND_ENABLE') then return end
    local sounds = shared.DRINK_SOUNDS
    core.sound.playSoundFile3d(sounds[math.random(#sounds)], self, {
        volume = cfg('NPC_SOUND_VOLUME') / 100,
        pitch  = cfg('NPC_SOUND_PITCH') / 100,
    })
end

local function onAnimationEnd()
    if not animActive then return end
    animActive = false
    restoreStance()
    restoreWeapon()
    if aiDisabled then
        aiDisabled = false
        if not types.Actor.isDead(self.object) then
            self:enableAI(true)
        end
    end
    playDrinkSound()
end

local function playPotionAnimation()
    I.AnimationController.playBlendedAnimation(ANIM_GROUP, {
        startKey = 'start',
        stopKey  = 'stop',
        priority = {
            [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.Torso]    = anim.PRIORITY.Scripted,
        },
        autoDisable = true,
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso
                  + anim.BLEND_MASK.RightArm,
        speed = cfg('NPC_ANIMATION_SPEED'),
    })

    anim.addVfx(self, VFX_MESH, {
        loop     = true,
        vfxId    = VFX_ID,
        boneName = VFX_BONE,
    })

    local fallback = cfg('NPC_ANIMATION_COOLDOWN') / cfg('NPC_ANIMATION_SPEED') + 1.0
    async:newUnsavableSimulationTimer(fallback, function()
        anim.removeVfx(self, VFX_ID)
        onAnimationEnd()
    end)
end

local function commitAnimation()
    animActive    = true
    cooldownUntil = core.getSimulationTime() + cfg('NPC_ANIMATION_COOLDOWN')

    if cfg('NPC_LOCK_WEAPON') then
        -- freeze the AI so it can't re-draw the weapon, then sheathe once
        self:enableAI(false)
        aiDisabled = true

        -- unequip the weapon: re-set the full equipment table minus CarriedRight
        local equip = types.Actor.getEquipment(self.object)
        local weapon = equip[types.Actor.EQUIPMENT_SLOT.CarriedRight]
        if weapon then
            savedWeapon = weapon
            equip[types.Actor.EQUIPMENT_SLOT.CarriedRight] = nil
            types.Actor.setEquipment(self, equip)
        end

        local stance = types.Actor.getStance(self.object)
        if stance ~= types.Actor.STANCE.Nothing then
            savedStance = stance
            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
            -- let the sheathe transition settle before the scripted animation
            async:newUnsavableSimulationTimer(0.35, playPotionAnimation)
            return
        end
    end

    playPotionAnimation()
end

-- HANDLERS

local function onConsume(item)
    if not cfg('NPC_ENABLE') then return end
    -- a dead NPC never drinks
    if types.Actor.isDead(self.object) then return end
    -- only potions
    if not types.Potion.objectIsInstance(item) then return end
    -- skip blacklisted potions
    if shared.BLACKLIST[item.recordId] then return end

    if core.getSimulationTime() < cooldownUntil then return end

    commitAnimation()
end

local function registerTextKeys()
    I.AnimationController.addTextKeyHandler(ANIM_GROUP, function(groupname, key)
        if key == 'discard' then
            anim.removeVfx(self, VFX_ID)
        elseif key == 'stop' then
            onAnimationEnd()
        end
    end)
end

local function onSettingsUpdated(newSettings)
    if not newSettings then return end
    for k, v in pairs(newSettings) do
        cachedSettings[k] = v
    end
end

-- true if this actor currently has a Combat package targeting the given player.
local function isFightingPlayer(player)
    for _, t in ipairs(AI.getTargets("Combat")) do
        if t == player then return true end
    end
    return false
end

local function onQuery(data)
    local player = data and data.player
    if not player or not player:isValid() then return end
    -- stay silent unless actually hostile
    if isFightingPlayer(player) then
        player:sendEvent("PotionAnim_HostileReport", { actor = self.object })
    end
end

local function onInactive()
    core.sendGlobalEvent("PotionAnim_WatcherInactive", { actor = self.object })
end

local function onSave()
    return {
        animActive  = animActive,
        savedStance = savedStance,
        savedWeapon = savedWeapon,
        aiDisabled  = aiDisabled,
    }
end

-- on load: re-register text keys
local function onLoad(data)
    registerTextKeys()
    if not data then return end

    savedStance = data.savedStance
    savedWeapon = data.savedWeapon
    aiDisabled  = data.aiDisabled or false
    animActive  = data.animActive or false

    if animActive then
        anim.removeVfx(self, VFX_ID)
        -- onAnimationEnd restores stance, re-equips the weapon and re-enables AI
        onAnimationEnd()
    elseif aiDisabled then
        -- defensive: AI was frozen but no animation is active
        aiDisabled = false
        if not types.Actor.isDead(self.object) then
            self:enableAI(true)
        end
    end
end

return {
    engineHandlers = {
        onInit      = registerTextKeys,
        onLoad      = onLoad,
        onSave      = onSave,
        onConsume   = onConsume,
        onInactive  = onInactive,
    },
    eventHandlers = {
        PotionAnim_Query           = onQuery,
        PotionAnim_SettingsUpdated = onSettingsUpdated,
    },
}