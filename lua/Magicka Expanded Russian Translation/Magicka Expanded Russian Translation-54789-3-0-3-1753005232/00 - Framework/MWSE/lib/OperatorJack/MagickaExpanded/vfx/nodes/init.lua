local log = require("OperatorJack.MagickaExpanded.utils.logger")
local data = require("OperatorJack.MagickaExpanded.data")

---@class MagickaExpanded.Vfx.Nodes
local this = {}

local vfx = {}

---@type MagickaExpanded.Vfx.Nodes.Decals
this.decals = require("OperatorJack.MagickaExpanded.vfx.nodes.decals")

---@type MagickaExpanded.Vfx.Nodes.Stencils?
this.stencils = nil

event.register(tes3.event.initialized, function()
    this.stencils = require("OperatorJack.MagickaExpanded.vfx.nodes.stencils")
end, {priority = 10000})

--[[
    Applies the given VFX mesh to a reference and returns the VFX node on the reference. If the reference already has the VFX applied, the existing VFX is loaded from the reference sceneNode. 
    This function will also morph the VFX mesh to account for the game enginee modifying NPC meshes due to height and weight, so that the VFX is not visibily altered.
]]
---@param reference tes3reference The reference to upsert the VFX onto.
---@param vfxObjectName string The name of the node to search for or attach. This value should match the name of the root node in the VFX mesh.
---@param path string The path of the VFX mesh to attach to the reference. The mesh must have a unique name in the root node.
---@param parentObjectName? string The name of the parent node to attach the Vfx to, if desired. Otherwise, attached to the sceneNode of the reference.
---@returned NiNode
this.getOrAttachVfx = function(reference, vfxObjectName, path, parentObjectName)
    local node, parent
    if (parentObjectName) then
        parent = reference.sceneNode:getObjectByName(parentObjectName) --[[@as niNode]]
    else
        parent = reference.sceneNode --[[@as niNode]]
    end

    node = parent:getObjectByName(vfxObjectName) --[[@as niNode]]

    if (not node) then
        if not vfx[vfxObjectName] then vfx[vfxObjectName] = assert(tes3.loadMesh(path)) end
        node = vfx[vfxObjectName]:clone() --[[@as niNode]]

        if (reference.object.race) then
            if (reference.object.race.weight and reference.object.race.height) then
                local weight = reference.object.race.weight.male
                local height = reference.object.race.height.male
                if (reference.object.female == true) then
                    weight = reference.object.race.weight.female
                    height = reference.object.race.height.female
                end

                local weightMod = 1 / weight
                local heightMod = 1 / height

                local r = node.rotation
                local s = tes3vector3.new(weightMod, weightMod, heightMod)
                node.rotation = tes3matrix33.new(r.x * s, r.y * s, r.z * s)
            end
        end

        parent:attachChild(node, true)
        node:update({controllers = true})
        node:updateEffects()

        log:debug("Added object %s to %s.", vfxObjectName, reference)
    end

    return node
end

--[[
    Uses appculling to show the given NiNode, node.
]]
---@param node niNode The node to show.
this.showNode = function(node) if (node.appCulled == true) then node.appCulled = false end end

--[[
    Uses appculling to hide the given NiNode, node.
]]
---@param node niNode The node to hide.
this.hideNode = function(node) if (node.appCulled == false) then node.appCulled = true end end

return this
