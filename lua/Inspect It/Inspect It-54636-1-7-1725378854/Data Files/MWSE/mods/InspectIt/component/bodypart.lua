---@class BodyPartResolver
local this = {}
local mesh = require("InspectIt.component.mesh")
local logger = require("InspectIt.logger")

---@class Socket
---@field name string?
---@field isLeft boolean?

---@type {[tes3.activeBodyPart] : Socket }
local sockets = {
    [tes3.activeBodyPart.head]          = { name = "Head", },
    [tes3.activeBodyPart.hair]          = { name = "Head", },
    [tes3.activeBodyPart.neck]          = { name = "Neck", },
    [tes3.activeBodyPart.chest]         = { name = "Chest", },
    [tes3.activeBodyPart.groin]         = { name = "Groin", },
    [tes3.activeBodyPart.skirt]         = { name = "Groin", },
    [tes3.activeBodyPart.rightHand]     = { name = "Right Hand", isLeft = false },
    [tes3.activeBodyPart.leftHand]      = { name = "Left Hand", isLeft = true },
    [tes3.activeBodyPart.rightWrist]    = { name = "Right Wrist", isLeft = false },
    [tes3.activeBodyPart.leftWrist]     = { name = "Left Wrist", isLeft = true },
    [tes3.activeBodyPart.shield]        = { name = "Shield Bone", },
    [tes3.activeBodyPart.rightForearm]  = { name = "Right Forearm", isLeft = false },
    [tes3.activeBodyPart.leftForearm]   = { name = "Left Forearm", isLeft = true },
    [tes3.activeBodyPart.rightUpperArm] = { name = "Right Upper Arm", isLeft = false },
    [tes3.activeBodyPart.leftUpperArm]  = { name = "Left Upper Arm", isLeft = true },
    [tes3.activeBodyPart.rightFoot]     = { name = "Right Foot", isLeft = false },
    [tes3.activeBodyPart.leftFoot]      = { name = "Left Foot", isLeft = true },
    [tes3.activeBodyPart.rightAnkle]    = { name = "Right Ankle", isLeft = false },
    [tes3.activeBodyPart.leftAnkle]     = { name = "Left Ankle", isLeft = true },
    [tes3.activeBodyPart.rightKnee]     = { name = "Right Knee", isLeft = false },
    [tes3.activeBodyPart.leftKnee]      = { name = "Left Knee", isLeft = true },
    [tes3.activeBodyPart.rightUpperLeg] = { name = "Right Upper Leg", isLeft = false },
    [tes3.activeBodyPart.leftUpperLeg]  = { name = "Left Upper Leg", isLeft = true },
    [tes3.activeBodyPart.rightPauldron] = { name = "Right Clavicle", isLeft = false },
    [tes3.activeBodyPart.leftPauldron]  = { name = "Left Clavicle", isLeft = true },
    [tes3.activeBodyPart.weapon]        = { name = "Weapon Bone", }, -- the real node name depends on the current weapon type.
    [tes3.activeBodyPart.tail]          = { name = "Tail" },
}

---@param bodypart BodyPart
---@param root niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
function this.BuildBodyPart(bodypart, root)
    local part = bodypart.part
    local socket = sockets[bodypart.type]
    if not socket then
        logger:error("Failed to find activeBodyPart %d: %s", bodypart.type, bodypart.part.id)
        return
    end
    local to = root:getObjectByName(socket.name) --[[@as niNode]]
    if not to then
        logger:error("Failed to find to attach to %s", socket.name)
        return
    end

    if not part.mesh or not tes3.getFileExists(string.format("Meshes\\%s", part.mesh)) then
        logger:error("Missing bodypart id: %s, mesh: %s, sourceMod: %s", part.id, part.mesh, part.sourceMod)
        return
    end
    logger:debug("Load bodypart id: %s, mesh: %s, sourceMod: %s", part.id, part.mesh, part.sourceMod)
    -- remaining skin instance with cache?
    local model = tes3.loadMesh(part.mesh, false) --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
    if not model.name then
        model.name = string.format("%s", part.mesh)
    end
    -- NOTE: If the root doesn't niNode (like niTriShape), it seems to create.
    -- NOTE: Worst of all, "a\A_Daedric_Skins.nif"'s bone naming convention is ridiculous and non-standard. It even has a niNode with Tri prefix name. That will be removed on loading.
    logger:trace("%s", mesh.Dump(model))

    -- case-senstive?
    local bip01 = model:getObjectByName("Bip01") --[[@as niNode]]
    local rootbone = model:getObjectByName("Root Bone") --[[@as niNode]] -- maybe creature only
    local skeleton = bip01 ~= nil or rootbone ~= nil

    if skeleton then
        -- place root children
        local parent = niNode.new()
        parent.name = socket.name -- sometime, skirt name is "Skirt", but ok
        root:attachChild(parent)
        to.parent:detachChild(to)

        local prefix = "tri " .. socket.name:lower()
        logger:trace("NiTriShape prefix: %s", prefix)
        mesh.foreach(model, function(node, _)
            if node:isInstanceOfType(ni.type.NiTriShape) then
                if node.name and node.name:lower():startswith(prefix) ~= true then
                    -- ignore unmatched part
                    logger:trace("Ignored: %s", node.name)
                    return
                end
                parent:attachChild(node)
                -- retarget
                if node.skinInstance then
                    -- It seems to crash if you try to check nil
                    node.skinInstance.root = parent
                    for index, bone in ipairs(node.skinInstance.bones) do
                        node.skinInstance.bones[index] = root:getObjectByName(bone.name)
                    end
                end
            end
        end)
    else
        -- use root node
        local parent = model
        parent.name = socket.name
        parent:copyTransforms(to)

        -- bone offset
        -- untest: In the case of vanilla, this seems to be fine without it because it is used as light sources...
        local offset = model:getObjectByName("BoneOffset")
        if offset then
            logger:trace("BoneOffset: %s", offset.translation)
            parent.translation = parent.translation:copy() + offset.translation:copy()
        end

        -- mirror
        if socket.isLeft == true then
            -- BSMirroredNode
            local mirror = niNode.new()
            mirror.name = "Mirrored"
            mirror.rotation = tes3matrix33.new(
                -1, 0, 0,
                0, 1, 0,
                0, 0, 1
            )
            -- add stencil property
            for _, child in ipairs(parent.children) do
                mirror:attachChild(child)
            end
            parent:detachAllChildren()
            parent:attachChild(mirror)
        end

        -- replace
        to.parent:attachChild(parent)
        to.parent:detachChild(to)

    end

end

return this
