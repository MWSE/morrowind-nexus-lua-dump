local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local debug = require('openmw.debug')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local effectData = require("scripts.AlterationMovement.AlterationMovement_effects")
local settingsFile = require("scripts.AlterationMovement.AlterationMovement_settings")
local knownEffects = {}
local currentEffectData = {}
local ambLoaded, ambient = pcall(require, 'openmw.ambient')
--local jumpHeld = false
--local sneakHeld = false
local timePassed = 0
if not settingsFile then
    error("Missing dependancies, check script settings")
end
local function exerciseSkill(amount)
    I.SkillProgression.skillUsed("alteration",
        { useType = I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump, skillGain = amount })
end

local alterationMovementSettings = storage.playerSection("SettingsAlterationMovement")
local function godMode()
    return debug.isGodMode()
end
local function getRequiredAlteration()
    if godMode() then return 0 end --If in god mode, can always fly
    return alterationMovementSettings:get("levelreq")
end
--local slowfallSpell = "lack_am_slowfall1"--This is the slowfall ability applied by the mod
--local levitateSpell = "lack_am_levitate1"--This is the levitate ability applied by the mod

local function getMagicka() --Quick way to check the player's current magicka
    return types.Actor.stats.dynamic.magicka(self).current
end
local function modMagicka(amount) --Modify player macicka by the asked about amount, unless in god mode
    if godMode() then return end
    types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).current - amount
end
local function playSound(soundName)
    if ambLoaded then
        ambient.playSound(soundName) --Playsound normally.
    end
end
local function playAlterationHit()
    if (alterationMovementSettings:get("enableSounds")) then
        playSound("alteration hit")
    end
end

local function playAlterationFail()
    if (alterationMovementSettings:get("enableSounds")) then
        playSound("Spell Failure Alteration")
    end
end
local function endEffects(id)
    if id then
        local value = effectData[id]
        if value.spell then
            types.Actor.spells(self):remove(value.spell)
        else
            types.Actor.activeEffects(self):set(0, effectData[id].effectId)
        end
        if not currentEffectData[id] then
            currentEffectData[id] = {}
        end
        currentEffectData[id].currentlyPressed = false
        currentEffectData[id].currentlyActive = false
        playAlterationFail()
        return
    end
    for key, value in pairs(effectData) do
        if value.spell then
            types.Actor.spells(self):remove(value.spell)
        else
            types.Actor.activeEffects(self):remove(value.effectId)
        end
        if not currentEffectData[id] then
            currentEffectData[id] = {}
        end
        currentEffectData[key].currentlyPressed = false
        currentEffectData[key].currentlyActive = false
    end
    --Add the two effects, by spell ID, specified above.

    playAlterationFail() --Play the effect for removing the effects, but only if sound is on
    timePassed = 0
end
local function startEffects(id)
    if effectData[id].spell then
        types.Actor.spells(self):add(effectData[id].spell)
    else
        types.Actor.activeEffects(self):modify(effectData[id].magnitude, effectData[id].effectId)
    end
    exerciseSkill(0.5)
    playAlterationHit()
    if not currentEffectData[id] then
        currentEffectData[id] = {}
    end
    currentEffectData[id].currentlyPressed = true
    currentEffectData[id].currentlyActive = true
end

--local flyKnown = false--Stores the info about if the fly effect is known.
--local fallKnown = false--Stores the info about if the slowfall effect is known.
local function onUpdate(dt)
    local held = false
    local requireKnown = alterationMovementSettings:get("requireKnown")
    for key, value in pairs(effectData) do
        if not currentEffectData[key] then
            currentEffectData[key] = {}
        end
        if value.action ~= nil and currentEffectData[key].currentlyPressed and not input.isActionPressed(value.action) and not alterationMovementSettings:get("toggleMode") then
            endEffects(key)
        elseif not value.action then
        elseif currentEffectData[key].currentlyPressed then
        end
        if currentEffectData[key].currentlyPressed then
            held = true
        end
        if requireKnown and not knownEffects[key] then
            local activeEffects = types.Actor.activeEffects(self)
            local hasEffect = activeEffects:getEffect(value.effectId)
            if hasEffect and hasEffect.magnitude > 0 then
                knownEffects[key] = true
                ui.showMessage("You can now intuitively cast " .. value.id .. ".")
            end
        end
    end
    if held then               --Reduce macika while we are engaged.
        timePassed = timePassed + dt
        if timePassed > 1 then --Only reduce magicak once a second.
            timePassed = 0
            local mag = getMagicka()
            local magCost = alterationMovementSettings:get("magickaCost")
            if mag < magCost then
                endEffects() --Remove all effects now.
            else
                exerciseSkill(0.2)
                modMagicka(magCost) --Reduce by the specified amount.
            end
        end
    end
end
local function getSpellKnown(id) --Checks if we can cast the slowvall/levitation effects
    if alterationMovementSettings:get("requireKnown") == false then
        return true
    elseif knownEffects[id] then
        return true
    else
        return false
    end
end
local function onInputAction(id)
    --onInputAction is used so that we can be correct with all bound controls, including controls.
    --There is no onInputActionEnded, so we must use onUpdate to check for it.
    if core.isWorldPaused() or core.getSimulationTime() == 0 then
        return --Do nothing while paused
    end
    if types.NPC.stats.skills.alteration(self).modified < getRequiredAlteration() then return end
    --Verify we are eligible to use the effects.
    for key, value in pairs(effectData) do
        if not currentEffectData[key] then
            currentEffectData[key] = {}
        end
        if id == value.action and value.qualifier() and not currentEffectData[key].currentlyActive then
            if not getSpellKnown(key) then return end

            timePassed = 0 --Reset so we start counting now.
            local mag = getMagicka()
            local magCost = alterationMovementSettings:get("magickaCost")
            if mag < magCost then --Don't allow effects if we can't afford them.
                playAlterationFail()
                return
            end
            startEffects(key)
        elseif id == value.action and currentEffectData[key].currentlyActive and alterationMovementSettings:get("toggleMode") then
            endEffects(value.effectId)
        end
    end
end
local function onSave()
    return { currentEffectData = currentEffectData, knownEffects = knownEffects } --Need to save these states.
end
local function onLoad(data)
    if data and data.knownEffects then --Only set these if we previously had data here.
        knownEffects = data.knownEffects
        currentEffectData = data.currentEffectData
        for key, value in pairs(currentEffectData) do
            if value.currentlyActive then
                endEffects(key)
            end
        end
        --  fallKnown = data.fallKnown
        --   flyKnown = data.flyKnown
    elseif data and data.fallKnown ~= nil then
        knownEffects["levitate"] = data.flyKnown
        knownEffects["slowfall"] = data.fallKnown
    end
    --    types.Actor.spells(self):remove(slowfallSpell) --Should never have these on load,
    --  types.Actor.spells(self):remove(levitateSpell) --so remove them in case the game was saved with them applied
end
return { engineHandlers = { onInputAction = onInputAction, onUpdate = onUpdate, onLoad = onLoad, onSave = onSave } }
