local log = require("OperatorJack.MagickaExpanded.utils.logger")
local data = require("OperatorJack.MagickaExpanded.data")

--[[
    This module should only be loaded AFTER the game has been initialized.
]]
---@class MagickaExpanded.Vfx.Nodes.Stencils
local this = {}

local vfx = {}

local stenciledActors = {}

local masks = {}

local vanillaStencilProperties = {}
local vanillaStencilObjects = {
    ["Left Upper Leg"] = true,
    ["Left Ankle"] = true,
    ["Left Knee"] = true,
    ["Left Upper Arm"] = true,
    ["Left Forearm"] = true,
    ["Left Wrist"] = true,
    ["Left Foot"] = true,
    ["Left Pauldron"] = true
}

local function reattachStencils(e)
    -- Initialize player.
    if e.reference == tes3.player or e.reference == tes3.player1stPerson then
        stenciledActors[e.reference] = nil
        this.attachStencilProperty(e.reference)

        -- Reset any stenciled actors since scene node was rebuilt.
    elseif stenciledActors[e.reference] then
        stenciledActors[e.reference] = nil
        this.attachStencilProperty(e.reference)
    end
end

-- Handle initializing and rebuilding scenegraph for stenciled actors.
event.register(tes3.event.referenceSceneNodeCreated, reattachStencils)

-- Handle change in equipment for stenciled actors.
event.register(tes3.event.equipped, function(e)
    timer.delayOneFrame(function()
        if e.reference == tes3.player then
            reattachStencils({reference = tes3.player1stPerson})
        end
        reattachStencils(e)
    end)
end)
event.register(tes3.event.unequipped, function(e)
    timer.delayOneFrame(function()
        if e.reference == tes3.player then
            reattachStencils({reference = tes3.player1stPerson})
        end
        reattachStencils(e)
    end)
end)

-- When invalidated, scene node will be recreated. Remove from tracking.
event.register(tes3.event.objectInvalidated, function(e) stenciledActors[e.object] = nil end)

masks = {
    player1st = assert(tes3.loadMesh(data.paths.stencils.player1st).stencilProperty),
    player = assert(tes3.loadMesh(data.paths.stencils.player).stencilProperty),
    playerMirror = assert(tes3.loadMesh(data.paths.stencils.playerMirror).stencilProperty),
    npc = assert(tes3.loadMesh(data.paths.stencils.npc).stencilProperty),
    npcMirror = assert(tes3.loadMesh(data.paths.stencils.npcMirror).stencilProperty),
    creature = assert(tes3.loadMesh(data.paths.stencils.creature).stencilProperty),
    weapon = assert(tes3.loadMesh(data.paths.stencils.weapon).stencilProperty)
}

local function attachStencilPropertyToReference(reference, mask)
    reference.sceneNode.stencilProperty = mask
    reference.sceneNode:update()
    reference.sceneNode:updateNodeEffects()
    reference.sceneNode:updateProperties()
    stenciledActors[reference] = true
end

local function attachStencilMirrorPropertiesToReference(reference, mask)
    -- Replace vanilla arm and leg stencil property. Cache to reset later.
    for name in pairs(vanillaStencilObjects) do
        local node = reference.sceneNode:getObjectByName(name)
        if node then
            vanillaStencilProperties[name] = node.stencilProperty
            node.stencilProperty = mask
        end
    end
end

local function attachWeaponStencilPropertyToReference(reference, mask)
    local node = reference.sceneNode:getObjectByName("Weapon Bone")

    if node then node.stencilProperty = mask end
end

--[[
    Removes stencil properties from the given actor reference, if the reference is being tracked by the framework. 
    The reference must be the player, an npc, or a creature. 
    The reference will be removed from stencil tracking.
]]
---@param reference tes3reference The reference to remove the stencil properties from.
this.detachStencilProperty = function(reference)
    if not stenciledActors[reference] then return end

    -- Dettach character stencil.
    local sceneNode = reference.sceneNode --[[@as niNode]]
    sceneNode.stencilProperty = nil

    -- Reset vanilla stencils.
    for name in pairs(vanillaStencilObjects) do
        if not vanillaStencilProperties[name] then
            log:error("Cached vanilla stencil property not found.")
        else
            local node = sceneNode:getObjectByName(name)
            if node then
                node.stencilProperty = nil
                node:attachProperty(vanillaStencilProperties[name])
            end
        end
    end

    sceneNode:update()
    sceneNode:updateEffects()
    sceneNode:updateProperties()
    stenciledActors[reference] = nil

    log:debug("Removed stencil properties from %s.", reference)
end

--[[
    Applies stencil properties to the given actor reference, so that stencil VFX effects can be used. The reference must be the player, an npc, or a creature. 
    The reference will be tracked for the current game session and stencil properties automatically applied when appropriate (such as when removed by the game engine).
]]
---@param reference tes3reference The reference to attach the stencil properties to. The reference must be the player, an npc, or a creature. 
this.attachStencilProperty = function(reference)
    if stenciledActors[reference] then return end

    -- Set mask paths & process
    if reference == tes3.player then
        attachStencilMirrorPropertiesToReference(reference, masks.playerMirror)
        attachWeaponStencilPropertyToReference(reference, masks.weapon)
        attachStencilPropertyToReference(reference, masks.player)

    elseif reference == tes3.player1stPerson then
        attachWeaponStencilPropertyToReference(reference, masks.weapon)
        attachStencilPropertyToReference(reference, masks.player1st)

    elseif reference.object.objectType == tes3.objectType.npc then
        attachStencilMirrorPropertiesToReference(reference, masks.npcMirror)
        attachWeaponStencilPropertyToReference(reference, masks.weapon)
        attachStencilPropertyToReference(reference, masks.npc)

    elseif reference.object.objectType == tes3.objectType.creature then
        attachWeaponStencilPropertyToReference(reference, masks.weapon)
        attachStencilPropertyToReference(reference, masks.creature)

    end

    log:debug("Added stencil properties to %s.", reference)
end

return this
