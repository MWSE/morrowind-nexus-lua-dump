local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local jumpHeld = false
local sneakHeld = false
local timePassed = 0

local slowfallSpell = "lack_am_slowfall1"
local levitateSpell = "lack_am_levitate1"
local alterationMovementSettings = storage.playerSection("SettingsAlterationMovement")
if not types.Actor.activeEffects then
    error("OpenMW version is too old for Alteration Movement to work!")
end
local function getMagicka()
    return types.Actor.stats.dynamic.magicka(self).current
end
local function modMagicka(amount)
    types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).current - amount
end
local function playAlterationHit()
    if (alterationMovementSettings:get("enableSounds")) then
        core.sendGlobalEvent("createObjectAtPlayer", "lack_soundplayer_alterationHit")
    end
end

local function playAlterationFail()
    if (alterationMovementSettings:get("enableSounds")) then
        core.sendGlobalEvent("createObjectAtPlayer", "lack_soundplayer_alterationFail")
    end
end
local function endEffects()
    types.Actor.spells(self):remove(levitateSpell)
    types.Actor.spells(self):remove(slowfallSpell)
    jumpHeld = false
    sneakHeld = false
    playAlterationFail()
    timePassed = 0
end
local function isFalling()
    local isFlying = false
    local levEffect = types.Actor.activeEffects(self):getEffect("levitate")
    if levEffect and levEffect.magnitude > 0 then
        isFlying = true
    end
    if not isFlying and not types.Actor.isOnGround(self) and (not types.Actor.isSwimming(self) or alterationMovementSettings:get("allowWaterTakeoff")) then
        return true
    else
        return false
    end
end

local flyKnown = false
local fallKnown = false
local function onUpdate(dt)
    if jumpHeld then
        if not input.isActionPressed(input.ACTION.Jump) and not alterationMovementSettings:get("toggleMode") then
            types.Actor.spells(self):remove(levitateSpell)
            jumpHeld = false
            playAlterationFail()
        end
    end
    if sneakHeld then
        if not input.isActionPressed(input.ACTION.Sneak) and not alterationMovementSettings:get("toggleMode") then
            types.Actor.spells(self):remove(slowfallSpell)
            sneakHeld = false
            playAlterationFail()
        end
    end
    if jumpHeld or sneakHeld then
        timePassed = timePassed + dt
        if timePassed > 1 then
            timePassed = 0
            local mag = getMagicka()
            local magCost = alterationMovementSettings:get("magickaCost")
            if mag < magCost then
                endEffects()
            else
                modMagicka(magCost)
            end
        end
    end
    if alterationMovementSettings:get("requireKnown") == true and (not flyKnown or not fallKnown) then
        local activeEffects = types.Actor.activeEffects(self)
        if not flyKnown then
            local hasLevitate = activeEffects:getEffect(core.magic.EFFECT_TYPE.Levitate)
            if hasLevitate and hasLevitate.magnitude > 0 then
                flyKnown = true
                ui.showMessage("You can now intuitively cast levitation.")
            end
        end
        if not fallKnown then
            local hasSlowFall = activeEffects:getEffect(core.magic.EFFECT_TYPE.SlowFall)
            if hasSlowFall and hasSlowFall.magnitude > 0 then
                flyKnown = true
                ui.showMessage("You can now intuitively cast slowfall.")
            end
        end
    end
end
local function getSpellKnown(id)
    if alterationMovementSettings:get("requireKnown") == false then
        return true
    elseif id == "fly" and flyKnown == true then
        return true
    elseif id == "fall" and fallKnown == true then
        return true
    else
        return false
    end
end
local slowFallEnabled = false
local function onInputAction(id)
    if core.isWorldPaused() or core.getSimulationTime() == 0 then
        return
    end
    if types.NPC.stats.skills.alteration(self).modified < alterationMovementSettings:get("levelreq") then return end
    if id == input.ACTION.Jump and isFalling() then
        if not getSpellKnown("fly") then return end
        timePassed = 0
        local mag = getMagicka()
        local magCost = alterationMovementSettings:get("magickaCost")
        if mag < magCost then
            playAlterationFail()
            return
        end
        types.Actor.spells(self):add(levitateSpell)
        playAlterationHit()
        jumpHeld = true
    elseif id == input.ACTION.Jump and jumpHeld and alterationMovementSettings:get("toggleMode") then
        timePassed = 0
        types.Actor.spells(self):remove(levitateSpell)
        jumpHeld = false
        playAlterationFail()
    elseif id == input.ACTION.Sneak and isFalling() and not sneakHeld then
        if not getSpellKnown("fall") then return end
        local mag = getMagicka()
        local magCost = alterationMovementSettings:get("magickaCost")
        if mag < magCost then
            playAlterationFail()
            return
        end
        if alterationMovementSettings:get("toggleMode") then
            slowFallEnabled = true
        end
        types.Actor.spells(self):add(slowfallSpell)
        playAlterationHit()
        sneakHeld = true
    elseif id == input.ACTION.Sneak and slowFallEnabled == true then
        types.Actor.spells(self):remove(slowfallSpell)
        sneakHeld = false
        playAlterationFail()
        slowFallEnabled = false
    end
end
local function onSave()
    return { fallKnown = fallKnown, flyKnown = flyKnown }
end
local function onLoad(data)
    if data then
        fallKnown = data.fallKnown
        flyKnown = data.flyKnown
    end
    types.Actor.spells(self):remove(slowfallSpell)
    types.Actor.spells(self):remove(levitateSpell)
end
return { engineHandlers = { onInputAction = onInputAction, onUpdate = onUpdate, onLoad = onLoad, onSave = onSave } }
