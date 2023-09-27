---@class Gamble.Settings
local this = {}
this.oddsList = {
    0, -- free
    1,
    5,
    25,
    100,
}
this.penaltyPointPerRound = 5 -- per round

--- Probability value, since the multiplier applied is likely to result in a larger payment than estimated.
---@param mult KoiKoi.HouseRule.Multiplier
---@return number
function this.GetMultiplierFactorByHouseRule(mult)
    local hr = require("Hanafuda.KoiKoi.houseRule")
    local multiplierFactor = {
        [hr.multiplier.none] = 1,
        [hr.multiplier.doublePointsOver7] = 1.5,
        [hr.multiplier.eachTimeKoiKoi] = 2,
    }
    return multiplierFactor[mult] or 1
end

this.dispositionByInsufficientCoefficient = 0.2

this.factionRankBias = 1

this.fightThreshold = {
    base = 70,
}
this.dispositionThreshold = {
    base = 20,
}

this.bettingModifier = 1.0
this.bettingDispositionRange = {
    ---@type Gamble.Range
    current = {
        min = this.dispositionThreshold.base,
        max = 100,
    },
    ---@type Gamble.Range
    out = {
        min = -0.5,
        max = 0.5,
    },
}

---@param gamble number
---@param greedy number
---@return KoiKoi.RandomBrain.Params
function this.CalculateRandomBrainParams(gamble, greedy)
    return {
        koikoiChance = math.clamp(math.remap(greedy, 0, 1, 0.1, 0.6), 0, 1),
        meaninglessDiscardChance = math.clamp(math.remap(gamble, 0, 1, 0.3, 0.0), 0, 1),
        waitHand = { s = 1, e = 3 },
        waitDrawn = { s = 0.5, e = 1.5 },
        waitCalling = { s = 1.5, e = 3.5 },
    }
end

---@class Gamble.Range
---@field min number
---@field max number

---@class Gamble.Attribute
---@field attribute tes3.attribute
---@field weight number
---@field current Gamble.Range
---@field out Gamble.Range

---@class Gamble.Skill
---@field skill tes3.skill
---@field weight number
---@field current Gamble.Range
---@field out Gamble.Range

---@class Gamble.Ability
---@field attributes Gamble.Attribute[]?
---@field skills Gamble.Skill[]?

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param ability Gamble.Ability
---@return number
function this.CalculateAbility(mobile, ability)
    local value = 0
    local total = 0
    if ability.attributes then
        local attributes = mobile.attributes
        for _, a in ipairs(ability.attributes) do
            local v = math.remap(attributes[a.attribute + 1].current, a.current.min, a.current.max, a.out.min, a.out.max)
            v = math.clamp(v, 0.0, 1.0)
            value = value + v * a.weight
            total = total + a.weight
        end
    end
    if mobile.actorType == tes3.actorType.creature then
        -- no skill
    else
        ---@cast mobile tes3mobileNPC|tes3mobilePlayer
        if ability.skills then
            local skills = mobile.skills
            for _, s in ipairs(ability.skills) do
                local v = math.remap(skills[s.skill + 1].current, s.current.min, s.current.max, s.out.min, s.out.max)
                v = math.clamp(v, 0.0, 1.0)
                value = value + v * s.weight
                total = total + s.weight
            end
        end
    end
    if total > 0 then
        value = value / total -- normalize
        value = math.clamp(value, 0, 1)
    end
    return value
end

-- Most NPC's luck is 40
-- Other attributes range from 30 to 100
-- Mercantile of most NPCs is less than 60
-- Speechcraft of most NPCs is less than 75, 70
-- Security of most NPCs is less than 65
-- Sneak of most NPCs is less than 70

---@type Gamble.Ability
this.gambleAbility = {
    attributes = {
        {
            attribute = tes3.attribute.willpower,
            weight = 1.0,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.intelligence,
            weight = 1.0,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.luck,
            weight = 0.5,
            current = {
                min = 40,
                max = 60,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
    skills = {
        {
            skill = tes3.skill.mercantile, -- need gammble skill
            weight = 0.5,
            current = {
                min = 0,
                max = 60,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
}

-- not ability, but same formula
---@type Gamble.Ability
this.greedyAbility = {
    attributes = {
        {
            attribute = tes3.attribute.willpower,
            weight = 1.0,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 1.0,
                max = 0.0,
            },
        },
    },
    skills = {
        {
            skill = tes3.skill.mercantile,
            weight = 0.5,
            current = {
                min = 0,
                max = 60,
            },
            out = {
                min = 1.0,
                max = 0.0,
            },
        },
    },
}

-- affect both PC and NPC
---@type Gamble.Ability
this.cheatAbility = {
    attributes = {
        {
            attribute = tes3.attribute.personality,
            weight = 0.5,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.agility,
            weight = 0.5,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.luck,
            weight = 0.25,
            current = {
                min = 40,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
    skills = {
        {
            skill = tes3.skill.security,
            weight = 1.0,
            current = {
                min = 0,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            skill = tes3.skill.speechcraft,
            weight = 0.5,
            current = {
                min = 0,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
}

-- affect both PC and NPC
---@type Gamble.Ability
this.spotAbility = {
    attributes = {
        {
            attribute = tes3.attribute.willpower,
            weight = 0.5,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.intelligence,
            weight = 0.5,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.luck,
            weight = 0.25,
            current = {
                min = 40,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
    skills = {
        {
            skill = tes3.skill.security,
            weight = 1,
            current = {
                min = 0,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
}

-- affect both PC and NPC?
-- not ability, but same formula
---@type Gamble.Ability
this.luckyAbility = {
    attributes = {
        {
            attribute = tes3.attribute.luck,
            weight = 1.0,
            current = {
                min = 0,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
    skills = nil,
}

-- affect both PC and NPC
---@type Gamble.Ability
this.bettingAbility = {
    attributes = {
        {
            attribute = tes3.attribute.personality,
            weight = 0.5,
            current = {
                min = 30,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            attribute = tes3.attribute.luck,
            weight = 0.25,
            current = {
                min = 40,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
    skills = {
        {
            skill = tes3.skill.mercantile,
            weight = 1.0,
            current = {
                min = 0,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
        {
            skill = tes3.skill.speechcraft,
            weight = 0.5,
            current = {
                min = 0,
                max = 100,
            },
            out = {
                min = 0.0,
                max = 1.0,
            },
        },
    },
}

return this
