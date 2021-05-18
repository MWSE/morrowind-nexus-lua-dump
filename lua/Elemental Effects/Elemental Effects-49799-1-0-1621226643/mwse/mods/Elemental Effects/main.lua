local config = mwse.loadConfig("Elemental Effects", {
    enabled = true,
	disfiguredEffect = true,
    resistThreshold = 20,
})


local bodyPartBlacklist = {
    [tes3.activeBodyPart.groin] = true,
    [tes3.activeBodyPart.hair] = true,
    [tes3.activeBodyPart.leftPauldron] = true,
    [tes3.activeBodyPart.rightPauldron] = true,
    [tes3.activeBodyPart.shield] = true,
    [tes3.activeBodyPart.skirt] = true,
    [tes3.activeBodyPart.tail] = true,
    [tes3.activeBodyPart.weapon] = true,
}


local effectTextures = {
    [tes3.effect.fireDamage] = "textures\\anu\\ee\\burned.dds",
    [tes3.effect.shockDamage] = "textures\\anu\\ee\\calcinated.dds",
    [tes3.effect.frostDamage] = "textures\\anu\\ee\\frozen.dds",
    [tes3.effect.sunDamage] = "textures\\anu\\ee\\burned.dds",
    [tes3.effect.poison] = "textures\\anu\\ee\\poisoned.dds",
}


-- UTILITY FUNCTIONS --

local function isElementalEffect(effect)
    return effectTextures[effect.id] ~= nil
end


local function getExposedBodyParts(ref)
    return coroutine.wrap(function()
        for name, index in pairs(tes3.activeBodyPart) do
            if not bodyPartBlacklist[index] then
                local bodyPart = ref.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base, index)
                if bodyPart and bodyPart.node then
                    coroutine.yield(index, name)
                end
            end
        end
    end)
end


local function updateExposedStates(ref, effect)
    local updated = false

    local exposedStates = ref.data.ee or {}
    for bodyPartIndex in getExposedBodyParts(ref) do
        if exposedStates[tostring(bodyPartIndex)] ~= effect.id then
            exposedStates[tostring(bodyPartIndex)] = effect.id
            updated = true
        end
    end

    if updated then
        ref.data.ee = exposedStates
    end

    return updated
end


-- DECAL FUNCTIONS --


local function iterEffectDecals(texturingProperty)
    return coroutine.wrap(function()
        for i, map in ipairs(texturingProperty.maps) do
            local texture = map and map.texture
            local fileName = texture and texture.fileName
            for k, v in pairs(effectTextures) do
                if v.fileName == fileName then
                    coroutine.yield(i, map)
                    break
                end
            end
        end
    end)
end


local function hasEffectDecal(texturingProperty, texture)
    for i, map in iterEffectDecals(texturingProperty) do
        if map.texture.fileName == texture.fileName then
            return true
        end
    end
    return false
end

local function removeEffectDecals(sceneNode)
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local texturingProperty = node:getProperty(0x4)
            if texturingProperty then
                for i in iterEffectDecals(texturingProperty) do
                    texturingProperty:removeDecalMap(i)
                end
            end
        end
    end
end


local function addEffectDecal(sceneNode, effectId)
    local texture = effectTextures[effectId]
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local alphaProperty = node:getProperty(0x0)
            local texturingProperty = node:getProperty(0x4)
            if (alphaProperty == nil
                and texturingProperty ~= nil
                and texturingProperty.canAddDecal == true
                and hasEffectDecal(texturingProperty, texture) == false)
            then
                -- we have to detach/clone the property
                -- because it could have multiple users
                local texturingProperty = node:detachProperty(0x4):clone()
                texturingProperty:addDecalMap(texture)
                node:attachProperty(texturingProperty)
                node:updateProperties()
            end
        end
    end
end

local function applyDisfigureSpell(ref)
	local disfigureSpellId = "ee_disfigured"
	local disfigureSpell = tes3.getObject(disfigureSpellId) or tes3spell.create(disfigureSpellId, "Disfigured")
	local effect = disfigureSpell.effects[1]
	effect.id = tes3.effect.drainAttribute
	effect.rangeType = tes3.effectRange.self
	effect.min = (100 / config.resistThreshold)
	effect.max = (200 / config.resistThreshold)
	effect.attribute = tes3.attribute.personality
	
	disfigureSpell.castType = tes3.spellType.ability
	
	if config.disfiguredEffect then
		if ref.data.ee then
			mwscript.addSpell({
				reference = ref,
				spell = disfigureSpell
			})
		else
			mwscript.removeSpell({
				reference = ref,
				spell = disfigureSpell
			})
		end
	end
end
	

-- EVENTS --


--[[
    Create textures for elemental effects. Runs once on startup.
--]]
local function createEffectTextures()
    for k, v in pairs(effectTextures) do
        effectTextures[k] = niSourceTexture.createFromPath(v)
    end
end
event.register("initialized", createEffectTextures)


--[[
    Detect when elemental spells are cast on a target and store the
    exposure states of bodyparts at the time of receiving the effect.
--]]
local function onSpellResist(e)
    if not config.enabled then return end
    if e.resistedPercent >= config.resistThreshold then return end

    local ref = e.target
    local update = false

    for _, effect in pairs(e.source.effects) do
        if isElementalEffect(effect) then
            if updateExposedStates(ref, effect) then
                update = true
				applyDisfigureSpell(ref)
            end
		end
    end

    if update then
        ref:updateEquipment()
        if ref == tes3.player then
            tes3.mobilePlayer.firstPersonReference:updateEquipment()
        end
    end
end
event.register("spellResist", onSpellResist)


local function onRestoreHealth(e)
    if e.effect.id == tes3.effect.restoreHealth or e.effect.id == tes3.effect.absorbHealth then
        if e.target.data.ee then
            e.target.data.ee = nil
            removeEffectDecals(e.target.sceneNode)
			applyDisfigureSpell(e.target)
            if e.target == tes3.player then
                removeEffectDecals(tes3.mobilePlayer.firstPersonReference.sceneNode)
            end
        end
    end
end
event.register("spellResist", onRestoreHealth)


--[[
    Simple flag to signal the inventory paper doll needs updating.
--]]
local needsInventoryUpdate = false
event.register("enterFrame", function(e)
    if needsInventoryUpdate ~= false then
        needsInventoryUpdate = false
        tes3ui.updateInventoryCharacterImage()
    end
end)


--[[
    Apply effect decals to bodyparts which were previously marked as
    exposed.
--]]
local function onBodyPartAssigned(e)
    local ref = e.reference

    -- ignore when disabled
    if not config.enabled then return end

    -- ignore covered slots
    if e.object ~= nil then return end

    -- ignore blacklisted slots
    if bodyPartBlacklist[e.index] then return end

    -- override first person ref
    if e.isFirstPerson then
        ref = tes3.getReference("player")
    end

    -- ignore unaffected actors
    local exposedStates = ref.data.ee
    if not exposedStates then return end

    -- sceneNode is available next frame
    local activeBodyPart = e.manager:getActiveBodyPart(tes3.activeBodyPartLayer.base, e.index)
    local isPlayer = ref == tes3.player
    local bodyPartIndex = e.index

    timer.frame.delayOneFrame(function()
        local sceneNode = activeBodyPart and activeBodyPart.node
        if sceneNode then
            local effectId = exposedStates[tostring(bodyPartIndex)]
            if effectId then
                addEffectDecal(activeBodyPart.node, effectId)
            end
            if isPlayer then
                needsInventoryUpdate = true
            end
        end
    end)
end
event.register("bodyPartAssigned", onBodyPartAssigned)


event.register("loaded", function(e)
    tes3.player:updateEquipment()
    tes3.mobilePlayer.firstPersonReference:updateEquipment()
end)

--[[
    MCM
--]]

local function registerModConfig()
	local template = mwse.mcm.createTemplate{ name = "Elemental Effects" }
    template:saveOnClose("Elemental Effects", config)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = "Elemental Effects\n\nApplies visual effects to both NPCs and the player when damaged by fire, frost, shock, poison, or sun damage.\n\nDefault: On"
	
	settings:createOnOffButton{
        label = "Enable Mod",
        description = "Enable elemental effect decals.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config}
    }
	settings:createOnOffButton{
        label = "Enable Disfigured Effect",
        description = "Enable the application of a drain personality status effect while disfigured from an elemental attack, scaled based on the Resist Threshold. Removed upon health absorption or restoration.\n\nDefault: On",
        variable = mwse.mcm.createTableVariable{id = "disfiguredEffect", table = config}
    }
	settings:createSlider{
        label = "Resist Threshold: %s%%",
        description = "Effectively determines how often the effects are displayed, based on what percent of a spell must be resisted before a decal is applied to the player/NPC. Higher values mean effects are more common.\n\n Default: 20%",
        min = 0, max = 100,
        step = 1, jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "resistThreshold", table = config}
    }
end
event.register("modConfigReady", registerModConfig)