local moodConfig = require("mer.theGuarWhisperer.moodConfig")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Needs")

---@class GuarWhisperer.Needs.GuarCompanion.refData
---@field hunger number
---@field trust number
---@field affection number
---@field play number
---@field happiness number
---@field lastUpdated number

---@class GuarWhisperer.Needs.GuarCompanion : GuarWhisperer.GuarCompanion
---@field refData GuarWhisperer.Needs.GuarCompanion.refData

--- This class manages a companion's needs.
---@class GuarWhisperer.Needs
---@field guar GuarWhisperer.Needs.GuarCompanion
local Needs = {
    default = {
        trust = moodConfig.defaultTrust,
        affection = moodConfig.defaultAffection,
        play = moodConfig.defaultPlay,
        hunger = 50,
        happiness = 0,
    }
}

---@param guar GuarWhisperer.Needs.GuarCompanion
---@return GuarWhisperer.Needs
function Needs.new(guar)
    local self = setmetatable({}, { __index = Needs })
    self.guar = guar
    return self
end

---------------------------------------------------------
--- Hunger
---------------------------------------------------------

---@return number
function Needs:getHunger()
    return self.guar.refData.hunger or Needs.default.hunger
end

---@param hunger number
function Needs:setHunger(hunger)
    self.guar.refData.hunger = hunger
end

---@return GuarWhisperer.Hunger.Status
function Needs:getHungerStatus()
    --init hunger value for getMood
    self:setHunger(self:getHunger())
    return self:getMood("hunger")
end

function Needs:modHunger(amount)
    local previousMood = self:getHungerStatus()
    self:setHunger(math.clamp(self:getHunger() + amount, 0, 100))
    local newMood = self:getMood("hunger")
    if newMood ~= previousMood then
        tes3.messageBox(self.guar:format("{Name} %s.", newMood.description))
    end
    tes3ui.refreshTooltip()
end

function Needs:updateHunger(timeSinceUpdate)
    local changeAmount = self.guar.animalType.hunger.changePerHour * timeSinceUpdate
    self:modHunger(changeAmount)
end

---------------------------------------------------------
--- Trust
---------------------------------------------------------

---@return number
function Needs:getTrust()
    return self.guar.refData.trust or Needs.default.trust
end

---@param trust number
function Needs:setTrust(trust)
    self.guar.refData.trust = trust
end

---@return GuarWhisperer.Trust.Status
function Needs:getTrustStatus()
    return self:getMood("trust")
end

function Needs:modTrust(amount)
    local previousTrust = self:getTrust()
    self:setTrust(math.clamp(previousTrust+ amount, 0, 100))
    local afterTrust = self:getTrust()
    self.guar.reference.mobile.fight = 50 - (self:getTrust() / 2 )

    for _, trustData in ipairs(moodConfig.trust) do
        if previousTrust < trustData.minValue and afterTrust > trustData.minValue then
            local message = self.guar:format("{Name} {trustsYou}. ")
            if trustData.skillDescription then
                message = message .. self.guar:format("{He} %s", trustData.skillDescription)
            end
            timer.delayOneFrame(function()
                tes3.messageBox{ message = message, buttons = {"ОК"} }
            end)
        end
    end
    tes3ui.refreshTooltip()
    return afterTrust
end

function Needs:updateTrust(timeSinceUpdate)
    --Limit trust update while time skipping
    if timeSinceUpdate > 0.5 then
        logger:debug("Resting/Waiting, trust update limited to %s", moodConfig.trustWaitMultiplier)
        timeSinceUpdate = timeSinceUpdate * moodConfig.trustWaitMultiplier
    end
    --Trust changes if nearby
    local happinessMulti = math.remap(self:getHappiness(), 0, 100, -1.0, 1.0)
    local trustChangeAmount = (
        self.guar.animalType.trust.changePerHour *
        happinessMulti *
        timeSinceUpdate
    )
    self:modTrust(trustChangeAmount)
    logger:trace("Trust change amount: %s. New Trust: %s", trustChangeAmount, self:getTrust())
end


---------------------------------------------------------
--- Affection
---------------------------------------------------------

---@return number
function Needs:getAffection()
    return self.guar.refData.affection or Needs.default.affection
end

---@param affection number
function Needs:setAffection(affection)
    self.guar.refData.affection = affection
end

---@return GuarWhisperer.Affection.Status
function Needs:getAffectionStatus()
    return self:getMood("affection")
end

function Needs:modAffection(amount)
    --As he gains affection, his fight level decreases
    if amount > 0 then
        self.guar.mobile.fight = self.guar.mobile.fight - math.min(amount, 100 - self:getAffection())
    end
    self:setAffection(math.clamp(self:getAffection() + amount, 0, 100))
    return self:getAffection()
end

function Needs:updateAffection(timeSinceUpdate)
    if timeSinceUpdate > 0.5 then
        logger:debug("Resting/Waiting, affection update limited to %s", moodConfig.affectionWaitMultiplier)
        timeSinceUpdate = timeSinceUpdate * moodConfig.affectionWaitMultiplier
    end

    local changeAmount = self.guar.animalType.affection.changePerHour * timeSinceUpdate
    self:modAffection(changeAmount)
end

---------------------------------------------------------
--- Play
---------------------------------------------------------

---@return number
function Needs:getPlay()
    return self.guar.refData.play or Needs.default.play
end

---@param play number
function Needs:setPlay(play)
    self.guar.refData.play = play
end

function Needs:modPlay(amount)
    self:setPlay(math.clamp(self:getPlay() + amount, 0, 100))
    tes3ui.refreshTooltip()
    return self:getPlay()
end

function Needs:updatePlay(timeSinceUpdate)
    local changeAmount = self.guar.animalType.play.changePerHour * timeSinceUpdate
    self:modPlay(changeAmount)
end

---------------------------------------------------------
--- Happiness
---------------------------------------------------------

---@return number
function Needs:getHappiness()
    return self.guar.refData.happiness or Needs.default.happiness
end

---@param happiness number
function Needs:setHappiness(happiness)
    self.guar.refData.happiness = happiness
end

---@return GuarWhisperer.Happiness.Status
function Needs:getHappinessStatus()
    return self:getMood("happiness")
end


function Needs:updateHappiness()
    local healthRatio = self.guar.reference.mobile.health.current / self.guar.reference.mobile.health.base
    local comfort = math.remap(healthRatio, 0, 1.0, -80, 0)
    local hungerEffect = math.remap(self:getHunger(), 100, 0, -25, 30)
    local affection = math.remap(self:getAffection(), 0, 100, -20, 40)
    local play = math.remap(self:getPlay(), 0, 100, -20, 20)
    local trust = math.remap(self:getTrust(), 0, 100, 0, 20)

    local newHappiness = hungerEffect + comfort + affection + play + trust
    newHappiness = math.clamp(newHappiness, 0, 100)

    self:setHappiness(newHappiness)

    self.guar.reference.mobile.flee = 75 - (self:getHappiness()/ 2)
    tes3ui.refreshTooltip()
end

---------------------------------------------------------

---@param trustId GuarWhisperer.Trust.id
function Needs:hasTrustLevel(trustId)
    local trustConfig = moodConfig.trustMap[trustId]
    if trustConfig then
        return self:getTrust() >= trustConfig.minValue
    end
end


function Needs:updateNeeds()
    --get the time since last updated
    local now = common.util.getHoursPassed()
    if not self.guar:isActive() then
        --not active, reset time
        self.guar.refData.lastUpdated = now
        return
    end
    local lastUpdated = self.guar.refData.lastUpdated or now
    local timeSinceUpdate = now - lastUpdated
    self:updatePlay(timeSinceUpdate)
    self:updateAffection(timeSinceUpdate)
    self:updateHappiness()
    self:updateHunger(timeSinceUpdate)
    self:updateTrust(timeSinceUpdate)
    self.guar.refData.lastUpdated = now
end

---@private
---Gets the status of a need
function Needs:getMood(moodType)
    for _, mood in ipairs(moodConfig[moodType]) do
        if self.guar.refData[moodType] <= mood.maxValue then
            return mood
        end
    end
end

return Needs