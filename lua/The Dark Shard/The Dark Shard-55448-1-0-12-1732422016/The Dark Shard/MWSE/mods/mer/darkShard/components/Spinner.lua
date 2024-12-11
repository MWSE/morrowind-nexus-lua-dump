
local common = require("mer.darkShard.common")
local logger = common.createLogger("Spinner")
local CometEffect = require("mer.darkShard.components.CometEffect")
local function lerp(a, b, t) return a + (b - a) * t end

---A Spinner is a ref that randomly rotates over time
---When initialised, pick a random target velocity and acceleration
---Update the spinner each frame to move towards the target velocity
---Once the target velocity is reached, pick a new random target velocity
---@class DarkShard.Spinner
---@field ref tes3reference
---@field data DarkShard.Spinner.refData
local Spinner = {
    registeredSpinners = {},

    MIN_INTERVAL_SECONDS = 1,
    MAX_INTERVAL_SECONDS = 4,

    MIN_ACCELERATION = 1,
    MAX_ACCELERATION = 3,

    MAX_VELOCITY = 4,

    MIN_HEIGHT = 30,
    MAX_HEIGHT = 100,
    MIN_HEIGHT_DURATION = 30,
    MAX_HEIGHT_DURATION = 40,
}

---@class DarkShard.Spinner.refData
---@field acceleration number Degrees per second per second to accelerate towards target velocity
---@field nextChangeTime number Simulate time in hours when the next target velocity should be picked
---@field velocity number Current velocity in degrees per second
---@field initialHeight number Initial height
---@field targetHeight number Target height
---@field currentHeight number Current height
---@field heightTransitionTime number Time in seconds since the last height transition
---@field heightTransitionDuration number Duration in seconds for the height transition

---@param ref tes3reference
---@return DarkShard.Spinner
function Spinner:new(ref)
    ref.data.darkShardSpinner = ref.data.darkShardSpinner or {}
    local self = {
        ref = ref,
        data = ref.data.darkShardSpinner or {},
    }
    setmetatable(self, { __index = Spinner })
    self:init()
    return self
end

function Spinner.register(id)
    Spinner.registeredSpinners[id:lower()] = true
end

function Spinner.isSpinner(ref)
    return ref.object.isSoulGem or
        Spinner.registeredSpinners[ref.object.id:lower()] ~= nil
end

function Spinner:getNextChangeTime()
    local now = tes3.getSimulationTimestamp()
    logger:debug("Current time: %s", now)
    local realSecondsToChange = math.random(self.MIN_INTERVAL_SECONDS, self.MAX_INTERVAL_SECONDS)

    local timescale = tes3.findGlobal("TimeScale").value
    local gameSecondsToChange = realSecondsToChange / timescale
    local gameHoursToChange = gameSecondsToChange / 3600
    local nextChangeTime = now + gameHoursToChange
    logger:debug("Next change time: %s", nextChangeTime)
    return nextChangeTime
end

function Spinner:getRandomAcceleration()
    local newAcceleration = math.random(self.MIN_ACCELERATION, self.MAX_ACCELERATION)
    if self.data.acceleration ~= nil and self.data.acceleration > 0 then
        newAcceleration = -newAcceleration
    end
    logger:debug("New acceleration: %s", newAcceleration)
    return newAcceleration
end

function Spinner:getRandomHeight()
    return math.random(self.MIN_HEIGHT, self.MAX_HEIGHT) + self.data.initialHeight
end

function Spinner:getRandomHeightTransitionDuration()
    local heightDifference = math.abs(self.data.targetHeight - self.data.currentHeight)
    local duration = math.random(self.MIN_HEIGHT_DURATION, self.MAX_HEIGHT_DURATION)
    --larger height difference, longer duration
    duration = duration * (heightDifference / 100)
    return duration
end

function Spinner:init()
    self.data.nextChangeTime = self.data.nextChangeTime or self:getNextChangeTime()
    self.data.acceleration = self.data.acceleration or self:getRandomAcceleration()
    self.data.velocity = self.data.velocity or 0
    self.data.initialHeight = self.data.initialHeight or self.ref.position.z
    self.data.targetHeight = self.data.targetHeight or self:getRandomHeight()
    self.data.currentHeight = self.data.currentHeight or self.ref.position.z
    self.data.heightTransitionTime = self.data.heightTransitionTime or 0
    self.data.heightTransitionDuration = self.data.heightTransitionDuration or self:getRandomHeightTransitionDuration()

    local cometStrength = CometEffect.getEffectStrength()
    if cometStrength <= 0 then
        self.data.targetHeight = self.data.initialHeight
    end

    logger:debug("Initialised spinner with acceleration: %s", self.data.acceleration)
    logger:debug("Initialised spinner with next change time: %s", self.data.nextChangeTime)
    logger:debug("Initialised spinner with velocity: %s", self.data.velocity)
    logger:debug("Initialised spinner with target height: %s", self.data.targetHeight)
    logger:debug("Initialised spinner with current height: %s", self.data.currentHeight)
end

function Spinner:reset()
    self.ref.data.darkShardSpinner = {}
    self.data = self.ref.data.darkShardSpinner
end

---@param delta number Time in seconds since last frame
function Spinner:update(delta)
    local effectStrength = CometEffect.getEffectStrength()
    logger:debug("Updating spinner %s", self.ref.object.id)
    local data = self.data
    local now = tes3.getSimulationTimestamp()
    local velocityChange = data.acceleration *  delta
    data.velocity = data.velocity + velocityChange
    --Slow down as effect weakens
    data.velocity = math.min(data.velocity, self.MAX_VELOCITY * effectStrength)
    self:applyVelocity(data.velocity, delta)
    logger:debug("Updated spinner with velocity: %s", data.velocity)

    if now >= data.nextChangeTime then
        logger:debug("Change time reached, picking new target acceleration")
        self.nextChangeTime = self:getNextChangeTime()
        self.acceleration = self:getRandomAcceleration()
    end

    if data.velocity > self.MAX_VELOCITY or data.velocity < -self.MAX_VELOCITY then
        logger:debug("Velocity too high, reversing acceleration")
        data.acceleration = -data.acceleration
    end

    -- Update height
    data.heightTransitionTime = data.heightTransitionTime + delta
    local t = data.heightTransitionTime / data.heightTransitionDuration
    if t > 1 then t = 1 end
    local easedT = math.ease.cubicInOut(t)
    data.currentHeight = data.currentHeight + (data.targetHeight - data.currentHeight) * easedT
    logger:debug("Current height: %s", data.currentHeight)

    -- Check if target height is reached
    if math.abs(data.currentHeight - data.targetHeight) < 0.01 then
        if data.targetHeight == data.initialHeight then
            data.targetHeight = self:getRandomHeight()
        else
            data.targetHeight = data.initialHeight
        end
        data.heightTransitionTime = 0 -- Reset transition time
        data.heightTransitionDuration = self:getRandomHeightTransitionDuration()
        logger:debug("New target height: %s", data.targetHeight)
    end
    -- Apply the height to the object
    self.ref.position = tes3vector3.new(self.ref.position.x, self.ref.position.y, data.currentHeight)
end

function Spinner:applyVelocity(velocity, delta)
    self.ref.orientation = self.ref.orientation + tes3vector3.new(0, 0, velocity * delta)
end

return Spinner