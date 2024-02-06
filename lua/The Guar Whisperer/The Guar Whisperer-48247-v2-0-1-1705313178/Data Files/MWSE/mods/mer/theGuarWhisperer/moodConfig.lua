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
        description = "is completely miserable",
        maxValue = 20,
    },

    {
        id = "Depressed",
        description = "looks quite depressed",
        maxValue = 40,
    },

    {
        id = "Sad",
        description = "could use some affection",
        maxValue = 60,
    },

    {
        id = "Content",
        description = "looks content",
        maxValue = 80,
    },

    {
        id = "Happy",
        description = "looks happy",
        maxValue = 90,
    },

    {
        id = "Joyful",
        description = "is full of joy",
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
            return guar:format("You you pat {name}, but {he} still looks neglected.")
        end,
        maxValue = 25
    },
    {
        id = "Lonely",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("{Name} starts to cheer up as you pat {him} on the head.")
        end,
        maxValue = 50
    },
    {
        id = "Affectionate",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("{Name} purrs loudly as you give {him} a scratch behind the ears.")
        end,
        maxValue = 75
    },
    {
        id = "Very Affectionate",
        ---@param guar GuarWhisperer.GuarCompanion
        pettingResult = function(guar)
            return guar:format("{Name} snuggles you affectionately.")
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
        description = "doesn't trust you at all",
        minValue = 0,
        maxValue = 20
    },
    {
        id = "Wary",
        description = "is wary of you",
        skillDescription = "will now move or follow you and attack enemies at your command.",
        minValue = 20,
        maxValue = 40
    },
    {
        id = "Familiar",
        description = "has grown familiar with you",
        skillDescription = "can now fetch, harvest and steal items for you.",
        minValue = 40,
        maxValue = 60
    },
    {
        id = "Trusting",
        description = "is beginning to trust you",
        skillDescription = "can now wear a pack and be ridden.",
        minValue = 60,
        maxValue = 80
    },
    {
        id = "Very Trusting",
        description = "trusts you unconditionally",
        skillDescription = "can now breed with other guars.",
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
        description = "full"
    },
    {
        minValue = 20,
        maxValue = 40,
        description = "peckish"
    },
    {
        minValue = 40,
        maxValue = 60,
        description = "hungry"
    },
    {
        minValue = 60,
        maxValue = 80,
        description = "very hungry"
    },
    {
        minValue = 80,
        maxValue = 100,
        description = "starving"
    },
}


this.defaultHunger = 50
this.defaultPlay = 20

return this