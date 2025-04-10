local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Hunger")

---@class GuarWhisperer.Hunger.GuarCompanion.refData

---@class GuarWhisperer.Hunger.GuarCompanion : GuarWhisperer.GuarCompanion

---@class GuarWhisperer.Hunger
---@field guar GuarWhisperer.Hunger.GuarCompanion
---@field refData GuarWhisperer.Hunger.GuarCompanion.refData
local Hunger = {}

function Hunger.new(guar)
    local self = setmetatable({}, { __index = Hunger })
    self.guar = guar
    return self
end

function Hunger:processFood(amount)
    self.guar.needs:modHunger(-amount)

    --Eating restores health as a % of base health
    local healthCurrent = self.guar.mobile.health.current
    local healthMax = self.guar.mobile.health.base
    local difference = healthMax - healthCurrent
    local healthFromFood = math.remap(
        amount,
        0, 100,
        0, healthMax
    )
    healthFromFood = math.min(difference, healthFromFood)
    tes3.modStatistic{
        reference = self.guar.reference,
        name = "health",
        current = healthFromFood
    }

    --Before guar is willing to follow, feeding increases trust
    if not self.guar.needs:hasTrustLevel("Wary") then
        self.guar.needs:modTrust(3)
    end
end


return Hunger
