local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("DynamicCamera")
local AlphaBlendController = require("mer.fishing.Camera.AlphaBlendController")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@class Fishing.DynamicCamera.constructorParams
---@field camera Fishing.LureCamera The camera to use for the dynamic camera
---@field changeFrequencySeconds number The average number of seconds between camera changes
---@field changeVariance number The percentage of changeFrequency to vary by
---@field startingState Fishing.DynamicCamera.StateType?

---When active, the camera switches between player 1st person, ThirdPerson mode, and pointing at another reference.
---@class Fishing.DynamicCamera : Fishing.DynamicCamera.constructorParams
---@field states table<string, Fishing.DynamicCamera.State>
---@field currentState Fishing.DynamicCamera.StateType
---@field changeTimer mwseTimer
---@field wasInFirstPerson boolean
local DynamicCamera = {}

---@class Fishing.DynamicCamera.State
---@field enterState fun(self: Fishing.DynamicCamera)
---@field exitState fun(self: Fishing.DynamicCamera)

---@alias Fishing.DynamicCamera.StateType
---| '"ThirdPerson"'
---| '"FirstPerson"'
---| '"Locked"'
---| '"Underwater"'

---@type table<Fishing.DynamicCamera.StateType, Fishing.DynamicCamera.State>
DynamicCamera.states = {}

local function setBlendState(state)
    local fish = FishingStateManager.getCurrentFish()
    if fish and AlphaBlendController.registeredFish[fish.fishType.baseId] then
        local lure = FishingStateManager.getLure()
        if lure then
            AlphaBlendController.setSwitch(lure, state)
        end
    end
end


DynamicCamera.states.ThirdPerson = {
    enterState = function(_)
        tes3.force3rdPerson()
        setBlendState("CLIP")
    end,
    exitState = function(_)
        --NO OP
    end
}

DynamicCamera.states.FirstPerson = {
    enterState = function(_)
        tes3.force1stPerson()
        setBlendState("CLIP")
    end,
    exitState = function(_)
        --NO OP
    end
}

DynamicCamera.states.Locked = {
    enterState = function(self)
        self.camera.allowUnderwater = false
        self.camera:start()
        setBlendState("CLIP")
    end,
    exitState = function(self)
        self.camera:stop{ returnToFirstPersion = false}
    end
}


DynamicCamera.states.Underwater = {
    enterState = function(self)
        self.camera.allowUnderwater = true
        self.camera:start()
        setBlendState("BLEND")
    end,
    exitState = function(self)
        self.camera:stop{ returnToFirstPersion = false}
    end
}

---@param o Fishing.DynamicCamera.constructorParams
---@return Fishing.DynamicCamera?
function DynamicCamera:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    if not o.camera then
        logger:error("DynamicCamera requires a camera")
        return nil
    end
    ---@cast o Fishing.DynamicCamera
    o.startingState = o.startingState or "FirstPerson"
    o.currentState = o.startingState
    return o
end


---@param newState Fishing.DynamicCamera.StateType
function DynamicCamera:changeState(newState)
    logger:debug("Changing camera state to %s", newState)
    if self.currentState then
        self:getCurrentState().exitState(self)
    end
    self.currentState = newState
    self:getCurrentState().enterState(self)
end


function DynamicCamera:start()
    if not config.mcm.dynamicCamera then
        logger:debug("DynamicCamera disabled in MCM")
        return
    end
    self.wasInFirstPerson = not tes3.player.mobile.is3rdPerson
    logger:debug("Starting DynamicCamera")
    self:changeState(self.currentState)
    self:startTimer()
end

---@return Fishing.DynamicCamera.StateType
function DynamicCamera:pickNewState()
    local stateOrder = {
        "ThirdPerson",
        "Locked",
        "FirstPerson",
        "Underwater"
    }
    local currentIndex = table.find(stateOrder, self.currentState)
    local nextIndex = currentIndex + 1
    if nextIndex > #stateOrder then
        nextIndex = 1
    end
    logger:debug("Picking new camera state %s", stateOrder[nextIndex])
    return stateOrder[nextIndex]
end

function DynamicCamera:startTimer()
    local variance = self.changeVariance or 0
    local min = self.changeFrequencySeconds * (1 - variance)
    local max = self.changeFrequencySeconds * (1 + variance)
    local duration = math.remap(math.random(), 0, 1, min, max)
    self.changeTimer = timer.start{
        duration = duration,
        iterations = 1,
        callback = function()
            local newState = self:pickNewState()
            self:changeState(newState)
            self:startTimer()
            logger:debug("Next camera change in %s seconds", duration)
        end
    }
end

function DynamicCamera:stop()
    if not config.mcm.dynamicCamera then
        logger:debug("DynamicCamera disabled in MCM")
        return
    end
    if self.changeTimer then
        self.changeTimer:cancel()
    end
    if self.currentState then
        self:getCurrentState().exitState(self)
    end
    if self.wasInFirstPerson then
        tes3.force1stPerson()
    else
        tes3.force3rdPerson()
    end
end

---@return Fishing.DynamicCamera.State
function DynamicCamera:getCurrentState()
    return self.states[self.currentState]
end

return DynamicCamera