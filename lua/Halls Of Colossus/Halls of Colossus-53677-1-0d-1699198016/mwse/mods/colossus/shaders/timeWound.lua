local log = require("colossus.log")
local utils = require("colossus.utils")

local PORTAL_ID = {
    ["ggw_artifact"] = true,
    ["ggw_portal_door_back"] = true,
    ["ggw_portal_door_forward"] = true,
    ["ggw_portal_door_forward01"] = true,
    ["ggw_conj_portal_door"] = true,
    ["ggw_portal_door_back_arc"] = true,
    ["ggw_portal_door_desert"] = true,
    ["ggw_portal_door_desert_exit"] = true,
    ["ggw_timewound"] = true,
}

---@type { [tes3reference] : boolean }
local activePortals = {}

---@param target tes3reference
local function setShaderTarget(target)
    if activePortals[target] then
        return
    end

    log:debug("[%s] setShaderTarget(%s)", os.clock(), target)

    for portal in pairs(activePortals) do
        activePortals[portal] = portal == target
    end

    local shader = utils.getShader("ggw_swirl")
    ---@diagnostic disable
    shader.sphereCenter = target.sceneNode.worldBoundOrigin
    shader.sphereRadius = target.sceneNode.worldBoundRadius
    ---@diagnostic enable
end

local function update()
    local camera = tes3.worldController.worldCamera.cameraData.camera
    local cameraPosition = tes3.getCameraPosition()

    local closestPortal = nil
    local closestDistance = math.huge

    for portal in pairs(activePortals) do
        local sceneNode = portal.sceneNode
        if sceneNode
            and not sceneNode:isAppCulled()
            and not sceneNode:isFrustumCulled(camera)
        then
            local distance = cameraPosition:distance(sceneNode.worldBoundOrigin)
            if distance < closestDistance then
                closestDistance = distance
                closestPortal = portal
            end
        end
    end

    if closestPortal then
        setShaderTarget(closestPortal)
    end
end

local function updateShader()
    local shader = utils.getShader("ggw_swirl")
    if shader == nil then
        return
    end

    if not next(activePortals) then
        shader.enabled = false
        event.unregister("simulate", update)
        return
    end

    shader.enabled = true
    if not event.isRegistered("simulate", update) then
        event.register("simulate", update)
    end
end

---@param ref tes3reference
---@return boolean
local function isPortal(ref)
    return PORTAL_ID[ref.id] ~= nil
end

---@param e referenceActivatedEventData
local function onReferenceActivated(e)
    if isPortal(e.reference) then
        activePortals[e.reference] = false
        updateShader()
    end
end
event.register("referenceActivated", onReferenceActivated)

---@param e referenceDeactivatedEventData
local function onReferenceDeactivated(e)
    if isPortal(e.reference) then
        activePortals[e.reference] = nil
        updateShader()
    end
end
event.register("referenceDeactivated", onReferenceDeactivated)
