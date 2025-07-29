local framework = require("OperatorJack.MagickaExpanded")
local decals = framework.vfx.nodes.decals

tes3.claimSpellEffectId("conjureAshShell", 334)

local ASHSHELL_DECAL_PATH = "Data Files\\Textures\\OJ\\ME\\ashshell_decal.dds"

decals.preloadDecal(ASHSHELL_DECAL_PATH)

--
-- Decal Management Events
--

local bodyPartBlacklist = {
    [tes3.activeBodyPart.groin] = true,
    [tes3.activeBodyPart.leftPauldron] = true,
    [tes3.activeBodyPart.rightPauldron] = true,
    [tes3.activeBodyPart.shield] = true,
    [tes3.activeBodyPart.weapon] = true
}

event.register(tes3.event.loaded, function(e)
    tes3.player:updateEquipment()
    tes3.mobilePlayer.firstPersonReference:updateEquipment()
end)

---@param e bodyPartAssignedEventData
event.register(tes3.event.bodyPartAssigned, function(e)
    -- ignore covered slots
    if e.object ~= nil then return end

    -- ignore blacklisted slots
    if bodyPartBlacklist[e.index] then return end

    -- the bodypart scene node is available on the next frame
    -- make a safe handle in case it gets deleted before then
    local ref = tes3.makeSafeObjectHandle(e.reference)
    local bodyPartIndex = e.index
    local bodyPart = e.bodyPart

    timer.frame.delayOneFrame(function()
        if not ref or not ref:valid() or not (ref.bodyPartManager and bodyPartIndex and bodyPart) then
            return
        end

        local reference = ref:getObject()
        local sceneNode = reference.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base,
                                                                      bodyPartIndex).node
        if sceneNode and reference.mobile and
            tes3.isAffectedBy({reference = reference, effect = tes3.effect.conjureAshShell}) then
            framework.log:debug("'%s' was assigned to bodypart '%s' at index %s.", reference,
                                bodyPart, bodyPartIndex)
            decals.attachDecal(sceneNode, ASHSHELL_DECAL_PATH)
        end
    end)
end)

---@param e referenceActivatedEventData
event.register(tes3.event.referenceActivated, function(e)
    if e.reference.object.organic and e.reference.mobile and
        tes3.isAffectedBy({reference = e.reference, effect = tes3.effect.conjureAshShell}) then
        framework.log:debug("'%s' was loaded and is already affected.", e.reference)
        decals.attachDecal(e.reference.sceneNode, ASHSHELL_DECAL_PATH)
    end
end)

-- Create damage event handler to block all damage sources while effected by Ash Shell.
--- @param e damageEventData
local function damageCallback(e)
    if (tes3.isAffectedBy({effect = tes3.effect.conjureAshShell, reference = e.reference}) == true) then
        framework.log:debug("Reference affected by Ash Shell. Negating damage.")
        e.damage = 0
        return false
    end
end
event.register(tes3.event.damage, damageCallback, {priority = 1000})

---@type tes3spell|nil
local paralysis = nil

local vfxs = {}

---@param e tes3magicEffectTickEventData
local function onTick(e)
    -- Verify effect conditions are met.
    local caster = e.sourceInstance.caster
    if (caster.cell.isInterior == true) then
        if (caster == tes3.player) then
            tes3.messageBox("Вы не можете обратиться к духам в помещении.")
        end

        framework.log:debug("Attempted casting failed exterior check.")
        e.effectInstance.state = tes3.spellState.retired
    end

    if (tes3.worldController.weatherController.currentWeather.index ~= tes3.weather.ash and
        tes3.worldController.weatherController.currentWeather.index ~= tes3.weather.blight) then
        if (caster == tes3.player) then
            tes3.messageBox("Вы не можете обратиться к духам, когда нет пепельной бури.")
        end

        framework.log:debug("Attempted casting failed weather check.")
        e.effectInstance.state = tes3.spellState.retired
    end

    local target = e.effectInstance.target or e.sourceInstance.target or e.sourceInstance.caster
    paralysis = (paralysis or tes3.getObject("OJ_ME_ConjureAshShellParalysis")) --[[@as tes3spell]]

    if (target) then
        -- Check if the effect is just starting, or if we're reloading a save game and no longer tracking VFX.
        if (e.effectInstance.state == tes3.spellState.working) then
            -- Disable controls via paralysis disease.
            if (target.object.spells:contains(paralysis) == false) then
                tes3.addSpell({reference = target, spell = paralysis})
                framework.log:debug("Added paralysis to target.")
            end

            if (not vfxs[e.sourceInstance.serialNumber]) then
                -- Handle special circumstance VFX.
                if target.object.organic then
                    decals.attachDecal(target.sceneNode, ASHSHELL_DECAL_PATH)
                else
                    target:updateEquipment()
                    if target == tes3.player then
                        tes3.mobilePlayer.firstPersonReference:updateEquipment()
                    end
                end
                framework.log:debug("Added decal to target.")
                vfxs[e.sourceInstance.serialNumber] = true

            end
        end

        if (e.effectInstance.state == tes3.spellState.ending) then
            if (vfxs[e.sourceInstance.serialNumber]) then
                decals.removeDecal(target.sceneNode, ASHSHELL_DECAL_PATH)
                if target == tes3.player then
                    decals.removeDecal(tes3.mobilePlayer.firstPersonReference.sceneNode,
                                       ASHSHELL_DECAL_PATH)
                end
                framework.log:debug("Removed decal from target.")
                vfxs[e.sourceInstance.serialNumber] = nil

            end

            -- Enable player controls. 
            tes3.removeSpell({reference = target, spell = paralysis})
            framework.log:debug("Removed paralysis from target.")
        end
    else
        framework.log:error("Invalid target! Target not found.")
    end

    -- Trigger into the spell system.
    if (not e:trigger()) then return end
end

local HIT_ID = "oj_me_vfx_ashshell_hit"
local BOLT_ID = "oj_me_vfx_ashshell_bolt"
local CAST_ID = "oj_me_vfx_ashshell_cast"

local VFX_HIT_PATH = "OJ\\ME\\wp\\ashshell_hit.nif"
local VFX_BOLT_PATH = "OJ\\ME\\wp\\ashshell_hit.nif"
local VFX_CAST_PATH = "OJ\\ME\\wp\\ashshell_cast.nif"

local hitVFX = tes3.createObject({
    id = HIT_ID,
    objectType = tes3.objectType.static,
    mesh = VFX_HIT_PATH
})
--- @cast hitVFX tes3static

local boltVfx = tes3.createObject({
    id = BOLT_ID,
    objectType = tes3.objectType.weapon,
    mesh = VFX_BOLT_PATH,
    type = tes3.weaponType.arrow
})
---@cast boltVfx tes3weapon

local castVfx = tes3.createObject({
    id = CAST_ID,
    objectType = tes3.objectType.static,
    mesh = VFX_CAST_PATH
})
---@cast castVfx tes3static

--[[
    TODO:
    - Add custom icon
    - Add custom bolt VFX
]]
framework.effects.conjuration.createBasicEffect({
    -- Base information.
    id = tes3.effect.conjureAshShell,
    name = "Пепельный панцирь",
    description = "Обратитесь к духам природы, чтобы создать оболочку из пепла. Для этого необходимо находиться на улице во время пепельной бури. Наделяет заклинателя неуязвимостью, но не позволяет ему двигаться.",

    -- Basic dials.
    baseCost = 25.0,

    -- Various flags.
    allowEnchanting = false,
    allowSpellmaking = false,
    hasNoMagnitude = true,
    hasNoDuration = false,
    isHarmful = true,
    nonRecastable = true,
    casterLinked = true,
    canCastTouch = true,
    canCastTarget = true,
    canCastSelf = true,

    -- Graphics/sounds.
    hitVFX = hitVFX,
    castVFX = castVfx,
    areaVFX = framework.data.ids.objects.static.vfxEmpty,
    hasContinuousVFX = true,

    -- Required callbacks.
    onTick = onTick
})
