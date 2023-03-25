local core = require("SpellsReforged.SR_0_Core")

---@param effect tes3effect
---@param params table<string, any>
local function compareEffect(effect, params)
    for key, value in pairs(params) do
        if effect[key] ~= value then
            return false
        end
    end
    return true
end

---@param sourceInstance tes3magicSourceInstance
---@param params table<string, any>
local function hasEffect(sourceInstance, params)
    if sourceInstance then
        for _, effect in pairs(sourceInstance.sourceEffects) do
            if compareEffect(effect, params) then
                return true
            end
        end
    end
    return false
end

---@param caster tes3reference
local function createCreatureHandsVFX(caster, handsVFX)
    if caster.object.objectType ~= tes3.objectType.creature then
        return
    end
    for _, name in pairs({ "Bip01 L Hand", "Bip01 R Hand" }) do
        local object = caster.sceneNode:getObjectByName(name) ---@diagnostic disable-line
        if object then
            tes3.createVisualEffect({
                effect = handsVFX.id,
                lifespan = handsVFX.lifespan,
                avObject = object,
            })
        end
    end
end

--- Add VFX attached to casters hands when using enchants or spells.
---
---@param e vfxCreatedEventData
local function createHandsVFX(e)
    local magicEffects = tes3.dataHandler.nonDynamicData.magicEffects
    local vfxObjectId = e.vfx.effectObject and e.vfx.effectObject.id

    for effectId, effectData in pairs(core.vfxData) do
        if effectData.handsVFX
            and hasEffect(e.vfx.sourceInstance, { id = effectId })
        then
            -- The engine uses the "VFX_Hands" object humanoid casters.
            if vfxObjectId == "VFX_Hands" then
                -- Get rid of the vanilla vfx.
                e.vfx.expired = true
                -- Do our replacement instead.
                tes3.createVisualEffect({
                    effect = effectData.handsVFX.id,
                    lifespan = effectData.handsVFX.lifespan,
                    avObject = e.vfx.attachNode,
                })
            else
                -- Creatures don't use "VFX_Hands", handle them separately.
                if vfxObjectId == magicEffects[effectId].castVisualEffect.id then
                    createCreatureHandsVFX(e.vfx.sourceInstance.caster, effectData.handsVFX.id)
                end
            end
        end
    end
end
event.register("vfxCreated", createHandsVFX)

---@param e magicCastedEventData
local function createTouchVFX(e)
    -- Only interested in spell/enchant usage. (ignore alchemy)
    if e.source.objectType ~= tes3.objectType.spell
        and e.source.objectType ~= tes3.objectType.enchantment
    then
        return
    end
    -- Spawn the appropriate touchVFX for this magic source.
    for effectId, effectData in pairs(core.vfxData) do
        if effectData.touchVFX
            and hasEffect(e.sourceInstance, { id = effectId, rangeType = tes3.effectRange.touch })
        then
            local vfx = tes3.createVisualEffect({
                effect = effectData.touchVFX.id,
                lifespan = effectData.touchVFX.lifespan,
                avObject = e.caster.sceneNode,
            })
            local vfxRoot = vfx.effectNode.children[1]
            if vfxRoot and vfxRoot:isInstanceOfType(ni.type.NiBSParticleNode) then ---@diagnostic disable-line
                vfxRoot.rotation = e.caster.sceneNode.rotation
            end
        end
    end
end
event.register("magicCasted", createTouchVFX)
