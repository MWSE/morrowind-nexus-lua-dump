local self = require("openmw.self")
local I = require("openmw.interfaces")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")
local ambient = require("openmw.ambient")
local types = require("openmw.types")

require("scripts.Bullseye.logic.ammo")

local sectionPlayerStats = storage.globalSection("SettingsBullseye_playerStats")
local sectionFatigue = storage.globalSection("SettingsBullseye_fatigue")

local movementStatuses = {
    idling   = "idling",
    moving   = "moving",
    sneaking = "sneaking",
}
local animStates = {
    bowDraw        = "bowDraw",
    bowHold        = "bowHold",
    bowHoldTooLong = "bowHoldTooLong",
    crossbow       = "crossbow",
    thrown         = "thrown",
}
local fatigueRates = {
    bowDraw        = "bowDrawFatigueDrainRate",
    bowHold        = nil, -- reserved for bowHoldTooLong timer
    bowHoldTooLong = "bowHoldFatigueDrainRate",
    crossbow       = "crossbowFatigueDrainRate",
    thrown         = "thrownFatigueDrainRate",
}
local marksman = self.type.stats.skills.marksman(self)
local fatigue = self.type.stats.dynamic.fatigue(self)

local latestMovementStatus = movementStatuses.idling
local currMovementStatus = movementStatuses.idling
local currentAnimState = nil
local bowHoldTimerId = 0
local lastDamageMult = 1
local targetMovementDamage = 0

local movementEffect = {
    [movementStatuses.idling] = function() end,

    [movementStatuses.moving] = function(direction)
        local debuff = sectionPlayerStats:get("movementDebuff")
        if direction == -1 then
            -- cap removal to what we actually applied so partial healing
            -- in the last frame can't flip the stat into a net buff
            debuff = math.min(targetMovementDamage, debuff)
            debuff = math.max(0, debuff)
        end
        local newTarget      = math.max(0, targetMovementDamage + debuff * direction)
        local actual         = newTarget - targetMovementDamage -- respects the clamp
        targetMovementDamage = newTarget
        marksman.damage      = marksman.damage + actual
    end,

    [movementStatuses.sneaking] = function(direction)
        marksman.modifier = marksman.modifier
            + sectionPlayerStats:get("sneakBuff")
            * direction
    end,
}

local function updateCurrentMovementStatus(eqWeapon)
    local stance       = self.type.getStance(self)
    local weaponStance = stance == self.type.STANCE.Weapon
    if not weaponStance then
        currMovementStatus = movementStatuses.idling
        return
    end

    local weaponType = eqWeapon.type.records[eqWeapon.recordId].type
    local eqBow      = weaponType == eqWeapon.type.TYPE.MarksmanBow
    local eqCrossbow = weaponType == eqWeapon.type.TYPE.MarksmanCrossbow
    if not (eqBow or eqCrossbow) then
        currMovementStatus = movementStatuses.idling
        return
    end

    local isMoving     = self.type.getCurrentSpeed(self) ~= 0
    local isSneaking   = self.controls.sneak
    currMovementStatus = (isSneaking and movementStatuses.sneaking)
        or (isMoving and movementStatuses.moving)
        or movementStatuses.idling
end

local function drainFatigue(dt, amount)
    local drain = fatigue.current - amount * dt
    fatigue.current = math.max(0, drain)
end

-- +-----------------+
-- | Engine Handlers |
-- +-----------------+

local function onUpdate(dt)
    -- Re-enforce our damage contribution before the status transition check.
    -- Runs every frame, so any heal from the previous frame is undone immediately.
    if marksman.damage < targetMovementDamage then
        marksman.damage = targetMovementDamage
    end

    local eqWeapon = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
    local eqIsWeapon = eqWeapon and types.Weapon.objectIsInstance(eqWeapon)

    -- movement status stuff
    if eqIsWeapon then
        updateCurrentMovementStatus(eqWeapon)
    end
    if latestMovementStatus ~= currMovementStatus then
        movementEffect[latestMovementStatus](-1)
        movementEffect[currMovementStatus](1)
        latestMovementStatus = currMovementStatus
    end

    if eqIsWeapon and currentAnimState == fatigueRates.crossbow then
        local weaponType = eqWeapon.type.records[eqWeapon.recordId].type
        if weaponType ~= types.Weapon.TYPE.MarksmanCrossbow then
            currentAnimState = nil
        end
    end

    -- drain fatigue stuff
    local rateKey = fatigueRates[currentAnimState]
    if rateKey then
        drainFatigue(dt, sectionFatigue:get(rateKey))
    end
end

local function onSave()
    return {
        latestMovementStatus = latestMovementStatus,
        currMovementStatus = currMovementStatus,
        lastDamageMult = lastDamageMult,
    }
end

local function onLoad(data)
    if not data then return end
    latestMovementStatus = data.latestMovementStatus or latestMovementStatus
    currMovementStatus = data.currMovementStatus or currMovementStatus
    lastDamageMult = data.lastDamageMult or lastDamageMult
end

-- +----------------+
-- | Event Handlers |
-- +----------------+

local function playHeadshotSFX(volume)
    ambient.playSound("critical damage", {
        volume = volume
    })
end

local function updateSkillBoost(damageMult)
    lastDamageMult = damageMult
end

local bowstringHeldTooLongCallback = time.registerTimerCallback(
    "bowstringHeldTooLong",
    function(currTimerId)
        if bowHoldTimerId == currTimerId and currentAnimState == "bowHold" then
            currentAnimState = animStates.bowHoldTooLong
        end
    end
)

-- +------------+
-- | Interfaces |
-- +------------+

I.AnimationController.addTextKeyHandler("bowandarrow", function(_, key)
    if key == "shoot attach" then
        currentAnimState = animStates.bowDraw
    elseif key == "shoot max attack" then
        currentAnimState = animStates.bowHold
        bowHoldTimerId = bowHoldTimerId + 1

        time.newSimulationTimer(
            sectionFatigue:get("bowFatigueDrainDelay"),
            bowstringHeldTooLongCallback,
            bowHoldTimerId
        )
    elseif key == "shoot min hit" or key == "unequip start" then
        currentAnimState = nil
    end
end)

I.AnimationController.addTextKeyHandler("crossbow", function(_, key)
    if key == "shoot release" then
        currentAnimState = animStates.crossbow
    elseif key == "shoot follow stop" then
        currentAnimState = nil
    end
end)

I.AnimationController.addTextKeyHandler("throwweapon", function(_, key)
    if key == "shoot min hit" then
        currentAnimState = animStates.thrown
    elseif key == "shoot follow stop" then
        currentAnimState = nil
    end
end)

I.Combat.addOnHitHandler(AmmoHandler)

I.SkillProgression.addSkillUsedHandler(function(skillID, options)
    if skillID ~= "marksman"
        or options.useType ~= I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit
    then
        return
    end

    if options.skillGain then
        options.skillGain = options.skillGain * lastDamageMult
    else
        options.scale = options.scale + lastDamageMult
    end
end)

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Bullseye_PlayHeadshotSFX = playHeadshotSFX,
        Bullseye_hit = updateSkillBoost,
    }
}
