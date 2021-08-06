-- user variables
local mesh = "kurp\\Ex_DAE_Boethiah.nif" 

-- internal variables
local path = lfs.currentdir() .. "\\data files\\meshes\\"
local mtime = {}
local reference = nil
local meshSceneRoot = nil


local function copyfile(src, dst)
    src = io.open(src, 'rb')
    dst = io.open(dst, 'wb')
    if src and dst then
        dst:write(src:read('*a'))
        dst:close(); src:close()
    end
end


local function updateMeshSceneNode()
    local temp = ("_%s.nif"):format(mtime.new)

    -- mwse.log("liveMeshEditing; copyfile(%s, %s)", path .. mesh, path .. temp)
    copyfile(path .. mesh, path .. temp)

    -- mwse.log("liveMeshEditing; loadMesh(%s)", temp)
    local newMesh = tes3.loadMesh(temp)

    -- mwse.log("liveMeshEditing; os.remove(%s)", path .. temp)
    os.remove(path .. temp)

    for i=1, #meshSceneRoot.children do
        -- mwse.log("liveMeshEditing; meshSceneRoot:detachChildAt(%s)", i)
        meshSceneRoot:detachChildAt(i)
    end

    -- mwse.log("liveMeshEditing; meshSceneRoot:attachChild(%s)", newMesh)
    meshSceneRoot:attachChild(newMesh, true)

    if reference then
        reference.sceneNode:update()
        reference.sceneNode:updateNodeEffects()
    end
end


event.register("keyDown", function(e)
    if reference then return end

    local eyevec = tes3.getPlayerEyeVector()
    local eyepos = tes3.getPlayerEyePosition()
    local rayhit = tes3.rayTest{position=eyepos, direction=eyevec, ignore={tes3.player}}
    if rayhit then
        reference = tes3.createReference{
            object = tes3activator.create{mesh=mesh},
            position = rayhit.intersection,
            cell = tes3.player.cell
        }
    end
end, {filter=tes3.scanCode.x})


event.register("simulate", function(e)
    mtime.new = lfs.attributes(path .. mesh, "modification")
    if mtime.new ~= mtime.old then
        mtime.old = mtime.new
        updateMeshSceneNode()
        if reference then
            reference:disable()
            reference.modified = false
            reference = tes3.createReference{object=reference.object, position=reference.position, cell=reference.cell}
            reference.modified = false
        end
    end
end)


event.register("loaded", function(e)
    reference = nil
end)


event.register("initialized", function(e)
    meshSceneRoot = tes3.loadMesh(mesh)
end)