local common = require("blight.common")

local bodyPartBlacklist = {
    [tes3.activeBodyPart.groin] = true,
    [tes3.activeBodyPart.hair] = true,
    [tes3.activeBodyPart.leftPauldron] = true,
    [tes3.activeBodyPart.rightPauldron] = true,
    [tes3.activeBodyPart.shield] = true,
    [tes3.activeBodyPart.weapon] = true,
}

local decalTextures = {
    ["textures\\tb\\decal_blight1.dds"] = true,
    ["textures\\tb\\decal_blight2.dds"] = true,
}

--
-- Functions
--

local function iterBlightDecals(texturingProperty)
    return coroutine.wrap(function()
        for i, map in ipairs(texturingProperty.maps) do
            local texture = map and map.texture
            local fileName = texture and texture.fileName
            if decalTextures[fileName] then
                coroutine.yield(i, map)
            end
        end
    end)
end

local function hasBlightDecal(texturingProperty)
    return iterBlightDecals(texturingProperty)() ~= nil
end

local function addBlightDecal(sceneNode)
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local alphaProperty = node:getProperty(0x0)
            local texturingProperty = node:getProperty(0x4)
            if (alphaProperty == nil
                and texturingProperty ~= nil
                and texturingProperty.canAddDecal == true
                and hasBlightDecal(texturingProperty) == false)
            then
                -- we have to detach/clone the property
                -- because it could have multiple users
                local texturingProperty = node:detachProperty(0x4):clone()
                texturingProperty:addDecalMap(table.choice(decalTextures))
                node:attachProperty(texturingProperty)
                node:updateProperties()
                common.debug("Added blight decal to '%s'.", node.name)
            end
        end
    end
end

local function removeBlightDecal(sceneNode)
    for node in table.traverse{sceneNode} do
        local texturingProperty = node:getProperty(0x4)
        if texturingProperty then
            for i in iterBlightDecals(texturingProperty) do
                texturingProperty:removeDecalMap(i)
                common.debug("Removed blight decal from '%s'.", node.name)
            end
        end
    end
end

--
-- Events
--

event.register("initialized", function()
    for k, v in pairs(decalTextures) do
        decalTextures[k] = niSourceTexture.createFromPath(k)
    end
end)

event.register("loaded", function(e)
    tes3.player:updateEquipment()
    tes3.mobilePlayer.firstPersonReference:updateEquipment()
end)

event.register("bodyPartAssigned", function(e)
    if common.config.enableDecalMapping == false then
        return
    end

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
        if not ref:valid() then return end
        if not (ref.bodyPartManager and bodyPartIndex and bodyPart) then return end

        local sceneNode = ref.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base, bodyPartIndex).node
        if sceneNode and common.hasBlight(ref) then
            common.debug("'%s' was assigned a blighted bodypart '%s' at index %s.", ref, bodyPart, bodyPartIndex)
            addBlightDecal(sceneNode)
        end
    end)
end)

event.register("referenceActivated", function(e)
    if common.config.enableDecalMapping == false then
        return
    end

    if e.reference.object.organic and common.hasBlight(e.reference) then
        common.debug("'%s' was loaded and is already blighted.", e.reference)
        addBlightDecal(e.reference.sceneNode)
    end
end)

event.register("blight:AddedBlight", function(e)
    if common.config.enableDecalMapping == false then
        return
    end

    if e.reference.object.organic then
        addBlightDecal(e.reference.sceneNode)
    else
        e.reference:updateEquipment()
        if e.reference == tes3.player then
            tes3.mobilePlayer.firstPersonReference:updateEquipment()
        end
    end
end)

event.register("blight:RemovedBlight", function(e)
    removeBlightDecal(e.reference.sceneNode)
    if e.reference == tes3.player then
        removeBlightDecal(tes3.mobilePlayer.firstPersonReference.sceneNode)
    end
end)
