---@class GuarWhisperer.MoodConfig
local this = {}

---@class GuarWhisperer.Happiness.Status
---@field id string @The id of the status
---@field description string @The description of the status, displayed to the player
---@field maxValue number @The maximum value of the status

---@type GuarWhisperer.Happiness.Status[]
this.happiness = {
    {
        id = "Miserable",
        description = "выглядит совершенно несчастно",
        maxValue = 20,
    },

    {
        id = "Depressed",
        description = "выглядит подавленно",
        maxValue = 40,
    },

    {
        id = "Sad",
        description = "не помешало бы немного ласки",
        maxValue = 60,
    },

    {
        id = "Content",
        description = "выглядит довольно",
        maxValue = 80,
    },

    {
        id = "Happy",
        description = "выглядит счастливо",
        maxValue = 90,
    },

    {
        id = "Joyful",
        description = "переполняет радость",
        maxValue = 100,
    },
}

---@class GuarWhisperer.Affection.Status
---@field id string @The id of the status
---@field pettingResult fun(guar: GuarWhisperer.GuarCompanion): string @The result of petting the guar
---@field maxValue number @The maximum value of the status

---@type GuarWhisperer.Affection.Status[]
this.affection = {
    {
        id = "Neglected",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("Вы гладите {name}, но {he} все еще выглядит бездомным.")
        end,
        maxValue = 25
    },
    {
        id = "Lonely",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("{Name} начинает веселиться, когда вы поглаживаете {him} по голове.")
        end,
        maxValue = 50
    },
    {
        id = "Affectionate",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("{Name} громко мурлычет, когда вы чешете {him} за ухом.")
        end,
        maxValue = 75
    },
    {
        id = "Very Affectionate",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("{Name} ласково прижимается к вам.")
        end,
        maxValue = 100
    },
}
this.defaultAffection = 20
--- Multiplier applied to affection gain while waiting/resting
this.affectionWaitMultiplier = 0.6

---@class GuarWhisperer.Trust.Status
---@field id GuarWhisperer.Trust.id @The id of the status
---@field description string @The description of the status, displayed to the player
---@field skillDescription? string @The description of the skill increase, displayed to the player
---@field minValue number @The minimum value of the status
---@field maxValue number @The maximum value of the status

---@alias GuarWhisperer.Trust.id
---| '"Untrusting"'
---| '"Wary"'
---| '"Familiar"'
---| '"Trusting"'
---| '"Very Trusting"'

---@type GuarWhisperer.Trust.Status[]
this.trust = {
    {
        id = "Untrusting",
        description = "совсем не доверяет вам",
        minValue = 0,
        maxValue = 20
    },
    {
        id = "Wary",
        description = "относится к вам настороженно",
        skillDescription = "теперь будет двигаться или следовать за вами и атаковать врагов по вашей команде.",
        minValue = 20,
        maxValue = 40
    },
    {
        id = "Familiar",
        description = "привык к вам",
        skillDescription = "может собирать урожай, приносить и красть предметы для вас.",
        minValue = 40,
        maxValue = 60
    },
    {
        id = "Trusting",
        description = "начинает доверять вам",
        skillDescription = "может носить седельную сумку и возить верхом.",
        minValue = 60,
        maxValue = 80
    },
    {
        id = "Very Trusting",
        description = "всецело доверяет вам",
        skillDescription = "может размножаться с другими гуарами.",
        minValue = 80,
        maxValue = 100
    },
}
---@type table<string, GuarWhisperer.Trust.Status>
this.trustMap = {}
for _, status in ipairs(this.trust) do
    this.trustMap[status.id] = status
end


this.defaultTrust = 10
---Multiplier applied to trust gain while waiting/resting
this.trustWaitMultiplier = 0.2
--- The skill requirements for each trust level.
this.skillRequirements = {
    follow = this.trust[2].minValue,
    attack = this.trust[2].minValue,
    eat = this.trust[2].minValue,
    fetch = this.trust[3].minValue,
    charm = this.trust[3].minValue,
    pack = this.trust[4].minValue,
    breed = this.trust[5].minValue
}

---@class GuarWhisperer.Hunger.Status
---@field minValue number @The minimum value of the status
---@field maxValue number @The maximum value of the status
---@field description string @The description of the status, displayed to the player

---@type GuarWhisperer.Hunger.Status[]
this.hunger = {
    {
        minValue = 0,
        maxValue = 20,
        description = "сыт"
    },
    {
        minValue = 20,
        maxValue = 40,
        description = "легкий голод"
    },
    {
        minValue = 40,
        maxValue = 60,
        description = "голоден"
    },
    {
        minValue = 60,
        maxValue = 80,
        description = "очень голоден"
    },
    {
        minValue = 80,
        maxValue = 100,
        description = "изголодался"
    },
}


this.defaultHunger = 50
this.defaultPlay = 20

return this