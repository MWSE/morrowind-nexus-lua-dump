local ControllerGroups = require("mer.fishing.PlayerAnimations.ControllerGroups")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local LureCamera = require("mer.fishing.Camera.LureCamera")

---@type ControllerGroups
local controllers1stPerson = ControllerGroups.new("mer_fishing\\playerAnimations1st.nif")
local controllers3rdPerson = ControllerGroups.new("mer_fishing\\playerAnimations3rd.nif")



---@class PlayerAnimations
---@field enabled boolean
---@field addedPull number Additional value added to pull.
---@field addedDirection number Additional value added to direction.
---@field pullSpeed number Controls pull accumulation speed.
local this  = {
    pullSpeed = 1.8,
    addedPull = 0,
    addedDirection = 0,
    maxPull = 0.7,
}

--- Private variables that are calculated per frame.
local pull = 0
local direction = 0

--- How far the fishing pole is pulled back. ( 0: not pulled, 1: fully pulled )
---@return number
function this.getPull()
    return pull + this.addedPull
end

--- Which direction the fishing pole is pulled. ( -1: right, 0: center, +1: left )
---@return number
function this.getDirection()
    return direction + this.addedDirection
end

--- Enable player fishing animations.
---
function this.enable()
    if this.enabled ~= true then
        this.enabled = true
        controllers1stPerson:setTarget(tes3.player1stPerson, "Bip01 Neck")
        controllers3rdPerson:setTarget(tes3.player, "Bip01 Spine1")
    end
end

--- Disable player fishing animations.
---
function this.disable()
    if this.enabled ~= false then
        this.enabled = false
        controllers1stPerson:clearTarget()
        controllers3rdPerson:clearTarget()
    end
end


---
--- Private Methods/Events
---

--- Increase pull while right mouse is held, decrease while not.
---
---@param wc tes3worldController
local function updatePull(wc)
    local delta = wc.deltaTime * this.pullSpeed

    if wc.inputController:isMouseButtonDown(0) then
        pull = math.min(pull + delta, this.maxPull)
    else
        pull = math.max(pull - delta, 0.0)
    end
end

--- Calculate direction based on the screen position of the lure.
---
---@param wc tes3worldController
---@param lure tes3reference
local function updateDirection(wc, lure)
    if LureCamera.isActive() then
        --Don't update when lure camera is active.
        return
    end
    local camera = wc.worldCamera.cameraData.camera
    local lurePos = lure.sceneNode.worldTransform.translation
    local screenPoint = camera:worldPointToScreenPoint(lurePos)
    if screenPoint then
        direction = 2.0 * screenPoint.x / wc.viewWidth
    end
end

--- Update controllers using the current pull/direction values.
---
local function updateControllers()
    ---@type table<Fishing.fishingState, boolean>
    local animStates = {
        IDLE = false,
        CASTING = false,
        WAITING = false,
        CHASING = false,
        BITING = false,
        REELING = true,
        CATCHING = true,
        BLOCKED = false,
    }


    local currentState = FishingStateManager.getCurrentState()
    if not animStates[currentState] then
        this.disable()
        return
    end

    local lure = FishingStateManager.getLure()
    if lure == nil then
        return
    end

    this.enable()

    local worldController = tes3.worldController
    updatePull(worldController)
    updateDirection(worldController, lure)

    if tes3.is3rdPerson() then
        controllers3rdPerson:update(this.getPull(), this.getDirection())
    else
        controllers1stPerson:update(this.getPull(), this.getDirection())
    end
end
event.register(tes3.event.simulated, updateControllers, { priority = 1000 })

return this
