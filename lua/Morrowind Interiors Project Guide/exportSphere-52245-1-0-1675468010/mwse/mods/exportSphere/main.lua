local exportHidden = false

local exportTypes = {
    tes3.objectType.activator,
    tes3.objectType.alchemy,
    tes3.objectType.ammunition,
    tes3.objectType.apparatus,
    tes3.objectType.armor,
    tes3.objectType.book,
    tes3.objectType.clothing,
    tes3.objectType.container,
    -- tes3.objectType.creature,
    tes3.objectType.door,
    tes3.objectType.ingredient,
    tes3.objectType.light,
    tes3.objectType.lockpick,
    tes3.objectType.miscItem,
    -- tes3.objectType.npc,
    tes3.objectType.probe,
    tes3.objectType.repairItem,
    tes3.objectType.static,
    tes3.objectType.weapon,
}

local sphere
local function loadSphere()
    sphere = tes3.loadMesh("g7\\widget_sphere.nif")
    sphere.appCulled = true
end
event.register("initialized", loadSphere)


local function showSphere()
    sphere.appCulled = false
    sphere:clearTransforms()

    local root = tes3.game.worldSceneGraphRoot.children[9]
    assert(root.name == "WorldVFXRoot")
    root:attachChild(sphere, true)

    sphere:update()
    sphere:updateProperties()
    sphere:updateNodeEffects()
end


local function hideSphere()
    sphere.parent:detachChild(sphere)
    sphere.appCulled = true
end


local function positionSphere(e)
    if tes3ui.menuMode() then return end
    if sphere.appCulled then return end

    local ray = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = {tes3.player},
    }

    if ray then
        sphere.translation = ray.intersection
        sphere:update()
    end
end
event.register("simulate", positionSphere)


local function scaleSphere(e)
    if tes3ui.menuMode() then return end
    if sphere.appCulled then return end

    sphere.scale = math.max(0, sphere.scale + e.delta * 0.5)
    sphere:update()

    tes3.messageBox("Scale: %.2f", sphere.scale)
end
event.register("mouseWheel", scaleSphere)


local function boundsIntersect(objA, objB)
    local dist = objA.worldBoundOrigin:distance(objB.worldBoundOrigin)
    local radi = objA.worldBoundRadius + objB.worldBoundRadius
    return dist <= radi
end


local function clean(root)
    for obj in table.traverse(root.children) do
        -- remove extra data
        local extraData = obj.extraData
        while extraData do
            if not extraData.string then
                obj:removeExtraData(extraData)
            end
            extraData = extraData.next
        end
        -- remove dynamic effects
        if obj:isInstanceOfType(tes3.niType.NiNode) then
            for i=0, 4 do
                local effect = obj:getEffect(i)
                if effect then
                    obj:detachChild(effect)
                    obj:detachEffect(effect)
                end
            end
        end
    end
end


local function export()
    local sphereOrigin = sphere.worldBoundOrigin
    local sphereRadius = sphere.worldBoundRadius

    local root = niNode.new()
    local largest = root

    -- collect references
    for i, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(exportTypes) do
            if ref.sceneNode and not (ref.disabled or ref.deleted) then
                if boundsIntersect(sphere, ref.sceneNode) then
                    local node = ref.sceneNode:clone()
                    node:removeAllControllers()
                    root:attachChild(node)
                    if node.worldBoundRadius >= largest.worldBoundRadius then
                        largest = node
                    end
                end
            end
        end
    end

    -- remove appCulled
    if not exportHidden then
        for node in table.traverse(root.children) do
            if node.appCulled then
                node.parent:detachChild(node)
            end
        end
    end

    -- add landscape stuff
    if not tes3.player.cell.isInterior then
        local land = tes3.game.worldLandscapeRoot

        local node = niNode.new()
        node.name = land.name
        node.materialProperty = land.materialProperty
        node.texturingProperty = land.texturingProperty
        root:attachChild(node)

        for shape in table.traverse(land.children) do
            if shape:isInstanceOfType(tes3.niType.NiTriShape) then
                if boundsIntersect(sphere, shape) then
                    local t = shape.worldTransform.translation:copy()
                    local shape = shape:clone()
                    shape.translation = t
                    if not shape.texturingProperty then
                        shape.texturingProperty = tes3.game.worldLandscapeRoot.texturingProperty
                    end
                    node:attachChild(shape)
                end
            end
        end
    end

    -- apply scene origin
    local origin = largest.translation:copy()
    for i, node in pairs(root.children) do
        node.translation = node.translation - origin
    end

    clean(root)

    root:saveBinary("data files\\meshes\\g7\\export.nif")
    tes3.messageBox("exported to 'meshes\\g7\\export.nif'")
end


local function onKeyDownE(e)
    if tes3ui.menuMode() then return end
    if e.isShiftDown then return end

    -- Ctrl+Alt+E
    if e.isControlDown and e.isAltDown then
        if sphere.appCulled then
            showSphere()
        else
            export()
            hideSphere()
        end
    end
end
event.register("keyDown", onKeyDownE, { filter = tes3.scanCode.e })
