---@class EffectResolver
local this = {}
local combat = require("longod.DPSTooltips.combat")
local logger = require("longod.DPSTooltips.logger")

-- TODO key should use tes3.effect.*attribute to be better than original?
---@class AttributeModifier
---@field damage {[tes3.attribute] : number},
---@field drain {[tes3.attribute] : number},
---@field absorb {[tes3.attribute] : number},
---@field restore {[tes3.attribute] : number},
---@field fortify {[tes3.attribute] : number},

-- TODO key should use tes3.effect.*skill to be better than original?
---@class SkillModifier
---@field damage {[tes3.skill] : number},
---@field drain {[tes3.skill] : number},
---@field absorb {[tes3.skill] : number},
---@field restore {[tes3.skill] : number},
---@field fortify {[tes3.skill] : number},

---@class Modifier
---@field damages {[tes3.effect] : number}
---@field positives {[tes3.effect] : number}
---@field negatives {[tes3.effect] : number}
---@field attributes AttributeModifier
---@field skills SkillModifier
---@field resists {[tes3.effect] : number} resolved resistance
---@field actived Modifier

---@class ScratchData
---@field attacker Modifier
---@field target Modifier

---@class Params
---@field data ScratchData
---@field key tes3.effect
---@field value number
---@field speed number
---@field isSelf boolean
---@field attacker boolean
---@field target boolean
---@field attribute tes3.attribute
---@field skill tes3.skill
---@field weaponSkillId tes3.skill
---@field actived boolean

---@return ScratchData
function this.CreateScratchData()
    ---@type ScratchData
    local data = {
        attacker = {
            positives = {},
            negatives = {},
            attributes = {
                damage = {},
                drain = {},
                absorb = {},
                restore = {},
                fortify = {},
            },
            skills = {
                damage = {},
                drain = {},
                absorb = {},
                restore = {},
                fortify = {},
            },
            resists = {},
            actived = {
                positives = {},
                negatives = {},
                attributes = {
                    damage = {},
                    drain = {},
                    absorb = {},
                    restore = {},
                    fortify = {},
                },
                skills = {
                    damage = {},
                    drain = {},
                    absorb = {},
                    restore = {},
                    fortify = {},
                },
                resists = {},
            },
        },
        target = {
            damages = {},
            positives = {},
            negatives = {},
            attributes = {
                damage = {},
                drain = {},
                absorb = {},
                restore = {},
                fortify = {},
            },
            skills = {
                damage = {},
                drain = {},
                absorb = {},
                restore = {},
                fortify = {},
            },
            resists = {},
        },
    }
    return data
end

---@param tbl { [number]: number }
---@param key number
---@param initial number
---@return number
function this.GetValue(tbl, key, initial)
    if not tbl[key] then -- no allocate if it does not exists
        return initial
    end
    return tbl[key]
end

---@param tbl { [number]: number }
---@param key number
---@param value number
---@return number
function this.AddValue(tbl, key, value)
    tbl[key] = this.GetValue(tbl, key, 0) + value
    return tbl[key]
end

---@param tbl { [number]: number }
---@param key number
---@param value number
---@return number
function this.MulValue(tbl, key, value)
    tbl[key] = this.GetValue(tbl, key, 1) * value
    return tbl[key]
end

---@class FilterFlag
---@field attacker boolean
---@field target boolean

---@class AttributeFilter
---@field [tes3.attribute] FilterFlag
local attributeFilter = {
    [tes3.attribute.strength] = { attacker = true, target = false }, -- damage
    [tes3.attribute.intelligence] = { attacker = false, target = false },
    [tes3.attribute.willpower] = { attacker = true, target = true }, -- fatigue
    [tes3.attribute.agility] = { attacker = true, target = true },   -- evade, hit, fatigue
    [tes3.attribute.speed] = { attacker = false, target = false },   -- if weapon swing mod
    [tes3.attribute.endurance] = { attacker = true, target = true }, -- fatigue or if realtime health calculate mod
    [tes3.attribute.personality] = { attacker = false, target = false },
    [tes3.attribute.luck] = { attacker = true, target = true },      -- evade, hit
}

---@class SkillFilter
---@field [tes3.skill] FilterFlag
local skillFilter = {
    [tes3.skill.block] = { attacker = false, target = true },
    [tes3.skill.armorer] = { attacker = false, target = false },
    [tes3.skill.mediumArmor] = { attacker = false, target = true },
    [tes3.skill.heavyArmor] = { attacker = false, target = true },
    [tes3.skill.bluntWeapon] = { attacker = true, target = false },
    [tes3.skill.longBlade] = { attacker = true, target = false },
    [tes3.skill.axe] = { attacker = true, target = false },
    [tes3.skill.spear] = { attacker = true, target = false },
    [tes3.skill.athletics] = { attacker = false, target = false },
    [tes3.skill.enchant] = { attacker = false, target = false },
    [tes3.skill.destruction] = { attacker = false, target = false },
    [tes3.skill.alteration] = { attacker = false, target = false },
    [tes3.skill.illusion] = { attacker = false, target = false },
    [tes3.skill.conjuration] = { attacker = false, target = false },
    [tes3.skill.mysticism] = { attacker = false, target = false },
    [tes3.skill.restoration] = { attacker = false, target = false },
    [tes3.skill.alchemy] = { attacker = false, target = false },
    [tes3.skill.unarmored] = { attacker = false, target = false },
    [tes3.skill.security] = { attacker = false, target = false },
    [tes3.skill.sneak] = { attacker = false, target = false },
    [tes3.skill.acrobatics] = { attacker = false, target = false },
    [tes3.skill.lightArmor] = { attacker = false, target = true },
    [tes3.skill.shortBlade] = { attacker = true, target = false },
    [tes3.skill.marksman] = { attacker = true, target = false },
    [tes3.skill.mercantile] = { attacker = false, target = false },
    [tes3.skill.speechcraft] = { attacker = false, target = false },
    [tes3.skill.handToHand] = { attacker = false, target = false },
}


---@param params Params
---@param absorb boolean
---@return boolean
local function IsAffectedAttribute(params, absorb)
    local f = attributeFilter[params.attribute]
    if f then
        -- lua: a and b or c idiom is useless when b and c are boolean, it return b or c.
        if absorb then
            local both = f.target or f.attacker
            return params.target and both
        elseif params.isSelf then
            return params.attacker and f.attacker
        else
            return params.target and f.target
        end
    end
    return false
end

---@param params Params
---@param absorb boolean
---@return boolean
local function IsAffectedSkill(params, absorb)
    local f = skillFilter[params.skill]
    if f then
        -- lua: a and b or c idiom is useless when b and c are boolean, it return b or c.
        if absorb then
            local both = f.target or (f.attacker and params.skill == params.weaponSkillId)
            return params.target and both
        elseif params.isSelf then
            return params.skill == params.weaponSkillId and params.attacker and f.attacker
        else
            return params.target and f.target
        end
    end
    return false
end

---@param params Params
---@return boolean
local function DamageHealth(params)
    if params.isSelf then
    else
        if params.target then
            this.AddValue(params.data.target.damages, params.key, combat.CalculateDPS(params.value, params.speed))
            return true
        end
    end
    return false
end

---@param params Params
---@return boolean
local function DrainHealth(params)
    if params.isSelf then
    else
        if params.target then
            this.AddValue(params.data.target.damages, params.key, params.value)
            return true
        end
    end
    return false
end

---@param params Params
---@return boolean
local function CurePoison(params)
    if params.isSelf then
    else
        if params.target then
            params.data.target.positives[params.key] = 1
            return true
        end
    end
    return false
end

---@param params Params
---@return boolean
local function PositiveModifier(params)
    if params.isSelf then
        if params.attacker then
            if params.actived then
                this.AddValue(params.data.attacker.actived.positives, params.key, params.value)
            else
                this.AddValue(params.data.attacker.positives, params.key, params.value)
            end
            return true
        end
    else
        if params.target then
            this.AddValue(params.data.target.positives, params.key, params.value)
            return true
        end
    end
    return false
end

---@param params Params
---@return boolean
local function PositiveModifierWithSpeed(params)
    if params.isSelf then
        if params.attacker then
            if params.actived then
                this.AddValue(params.data.attacker.actived.positives, params.key,
                combat.CalculateDPS(params.value, params.speed))
            else
                this.AddValue(params.data.attacker.positives, params.key, combat.CalculateDPS(params.value, params.speed))
            end
            return true
        end
    else
        if params.target then
            this.AddValue(params.data.target.positives, params.key, combat.CalculateDPS(params.value, params.speed))
            return true
        end
    end
    return false
end

---@param params Params
---@return boolean
local function NegativeModifier(params)
    if params.isSelf then
        if params.attacker then
            if params.actived then
                this.AddValue(params.data.attacker.actived.negatives, params.key, params.value)
            else
                this.AddValue(params.data.attacker.negatives, params.key, params.value)
            end
            return true
        end
    else
        if params.target then
            this.AddValue(params.data.target.negatives, params.key, params.value)
            return true
        end
    end
    return false
end

-- only positive
---@param params Params
---@return boolean
local function MultModifier(params)
    if params.isSelf then
    else
        if params.target then
            this.MulValue(params.data.target.positives, params.key, combat.InverseNormalize(params.value))
            return true
        end
    end
    return false
end


---@param params Params
---@return boolean
local function FortifyAttribute(params)
    if not IsAffectedAttribute(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.attributes.fortify, params.attribute, params.value)
        else
            this.AddValue(params.data.attacker.attributes.fortify, params.attribute, params.value)
        end
    else
        this.AddValue(params.data.target.attributes.fortify, params.attribute, params.value)
    end
    return true
end

---@param params Params
---@return boolean
local function DamageAttribute(params)
    if not IsAffectedAttribute(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.attributes.damage, params.attribute,
            combat.CalculateDPS(params.value, params.speed))
        else
            this.AddValue(params.data.attacker.attributes.damage, params.attribute,
            combat.CalculateDPS(params.value, params.speed))
        end
    else
        this.AddValue(params.data.target.attributes.damage, params.attribute,
        combat.CalculateDPS(params.value, params.speed))
    end
    return true
end

---@param params Params
---@return boolean
local function DrainAttribute(params)
    if not IsAffectedAttribute(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.attributes.drain, params.attribute, params.value)
        else
            this.AddValue(params.data.attacker.attributes.drain, params.attribute, params.value)
        end
    else
        this.AddValue(params.data.target.attributes.drain, params.attribute, params.value)
    end
    return true
end

---@param params Params
---@return boolean
local function AbsorbAttribute(params)
    if not IsAffectedAttribute(params, true) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.attributes.absorb, params.attribute, params.value)
        else
            return false
        end
    else
        this.AddValue(params.data.attacker.attributes.absorb, params.attribute, params.value)
        this.AddValue(params.data.target.attributes.absorb, params.attribute, params.value)
    end
    return true
end

---@param params Params
---@return boolean
local function RestoreAttribute(params)
    if not IsAffectedAttribute(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.attributes.restore, params.attribute,
            combat.CalculateDPS(params.value, params.speed))
        else
            this.AddValue(params.data.attacker.attributes.restore, params.attribute,
            combat.CalculateDPS(params.value, params.speed))
        end
    else
        this.AddValue(params.data.target.attributes.restore, params.attribute,
        combat.CalculateDPS(params.value, params.speed))
    end
    return true
end

---@param params Params
---@return boolean
local function FortifySkill(params)
    if not IsAffectedSkill(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.skills.fortify, params.skill, params.value)
        else
            this.AddValue(params.data.attacker.skills.fortify, params.skill, params.value)
        end
    else
        this.AddValue(params.data.target.skills.fortify, params.skill, params.value)
    end
    return true
end

---@param params Params
---@return boolean
local function DamageSkill(params)
    if not IsAffectedSkill(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.skills.damage, params.skill,
            combat.CalculateDPS(params.value, params.speed))
        else
            this.AddValue(params.data.attacker.skills.damage, params.skill,
            combat.CalculateDPS(params.value, params.speed))
        end
    else
        this.AddValue(params.data.target.skills.damage, params.skill, combat.CalculateDPS(params.value, params.speed))
    end
    return true
end

---@param params Params
---@return boolean
local function DrainSkill(params)
    if not IsAffectedSkill(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.skills.drain, params.skill, params.value)
        else
            this.AddValue(params.data.attacker.skills.drain, params.skill, params.value)
        end
    else
        this.AddValue(params.data.target.skills.drain, params.skill, params.value)
    end
    return true
end

---@param params Params
---@return boolean
local function AbsorbSkill(params)
    if not IsAffectedSkill(params, true) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.skills.absorb, params.skill, params.value)
        else
            return false
        end
    else
        this.AddValue(params.data.attacker.skills.absorb, params.skill, params.value)
        this.AddValue(params.data.target.skills.absorb, params.skill, params.value)
    end
    return true
end

---@param params Params
---@return boolean
local function RestoreSkill(params)
    if not IsAffectedSkill(params, false) then
        return false
    end
    if params.isSelf then
        if params.actived then
            this.AddValue(params.data.attacker.actived.skills.restore, params.skill,
            combat.CalculateDPS(params.value, params.speed))
        else
            this.AddValue(params.data.attacker.skills.restore, params.skill,
            combat.CalculateDPS(params.value, params.speed))
        end
    else
        this.AddValue(params.data.target.skills.restore, params.skill, combat.CalculateDPS(params.value, params.speed))
    end
    return true
end

---@class Resolver
---@field func fun(params: Params): boolean
---@field attacker boolean affect when hitting
---@field target boolean affect when hitting

-- only vanilla effects
---@class ResolverTable
---@field [number] Resolver?
local resolver = {
    -- waterBreathing 0
    -- swiftSwim 1
    -- waterWalking 2
    [3] = { func = PositiveModifier, attacker = false, target = true }, -- shield 3
    [4] = { func = PositiveModifier, attacker = false, target = true }, -- fireShield 4
    [5] = { func = PositiveModifier, attacker = false, target = true }, -- lightningShield 5
    [6] = { func = PositiveModifier, attacker = false, target = true }, -- frostShield 6
    -- burden 7
    -- feather 8
    -- jump 9
    -- levitate 10
    -- slowFall 11
    -- lock 12
    -- open 13
    [14] = { func = DamageHealth, attacker = false, target = true },     -- fireDamage 14
    [15] = { func = DamageHealth, attacker = false, target = true },     -- shockDamage 15
    [16] = { func = DamageHealth, attacker = false, target = true },     -- frostDamage 16
    [17] = { func = DrainAttribute, attacker = true, target = true },    -- drainAttribute 17
    [18] = { func = DrainHealth, attacker = false, target = true },      -- drainHealth 18
    -- drainMagicka 19
    [20] = nil,                                                          -- drainFatigue 20
    [21] = { func = DrainSkill, attacker = true, target = true },        -- drainSkill 21
    [22] = { func = DamageAttribute, attacker = true, target = true },   -- damageAttribute 22
    [23] = { func = DamageHealth, attacker = false, target = true },     -- damageHealth 23
    -- damageMagicka 24
    [25] = nil,                                                          -- damageFatigue 25
    [26] = { func = DamageSkill, attacker = true, target = true },       -- damageSkill 26
    [27] = { func = DamageHealth, attacker = false, target = true },     -- poison 27
    [28] = { func = NegativeModifier, attacker = false, target = true }, -- weaknesstoFire 28
    [29] = { func = NegativeModifier, attacker = false, target = true }, -- weaknesstoFrost 29
    [30] = { func = NegativeModifier, attacker = false, target = true }, -- weaknesstoShock 30
    [31] = { func = NegativeModifier, attacker = true, target = true },  -- weaknesstoMagicka 31
    -- weaknesstoCommonDisease 32
    -- weaknesstoBlightDisease 33
    -- weaknesstoCorprusDisease 34
    [35] = { func = NegativeModifier, attacker = false, target = true }, -- weaknesstoPoison 35
    [36] = { func = NegativeModifier, attacker = false, target = true }, -- weaknesstoNormalWeapons 36
    -- disintegrateWeapon 37
    [38] = nil,                                                          -- disintegrateArmor 38
    -- invisibility 39
    -- chameleon 40
    -- light 41
    [42] = { func = PositiveModifier, attacker = false, target = true }, -- sanctuary 42
    -- nightEye 43
    -- charm 44
    -- paralyze 45
    -- silence 46
    [47] = { func = NegativeModifier, attacker = true, target = false }, -- blind 47
    -- sound 48
    -- calmHumanoid 49
    -- calmCreature 50
    -- frenzyHumanoid 51
    -- frenzyCreature 52
    -- demoralizeHumanoid 53
    -- demoralizeCreature 54
    -- rallyHumanoid 55
    -- rallyCreature 56
    [57] = { func = PositiveModifier, attacker = true, target = true }, -- dispel 57
    -- soultrap 58
    -- telekinesis 59
    -- mark 60
    -- recall 61
    -- divineIntervention 62
    -- almsiviIntervention 63
    -- detectAnimal 64
    -- detectEnchantment 65
    -- detectKey 66
    [67] = { func = MultModifier, attacker = true, target = true }, -- spellAbsorption 67
    [68] = { func = MultModifier, attacker = true, target = true }, -- reflect 68
    -- cureCommonDisease 69
    -- cureBlightDisease 70
    -- cureCorprusDisease 71
    [72] = { func = CurePoison, attacker = false, target = true },                -- curePoison 72
    -- cureParalyzation 73
    [74] = { func = RestoreAttribute, attacker = true, target = true },           -- restoreAttribute 74
    [75] = { func = PositiveModifierWithSpeed, attacker = false, target = true }, -- restoreHealth 75
    -- restoreMagicka 76
    [77] = nil,                                                                   -- restoreFatigue 77
    [78] = { func = RestoreSkill, attacker = true, target = true },               -- restoreSkill 78
    [79] = { func = FortifyAttribute, attacker = true, target = true },           -- fortifyAttribute 79
    [80] = { func = PositiveModifier, attacker = false, target = true },          -- fortifyHealth 80
    -- fortifyMagicka 81
    [82] = nil,                                                                   -- fortifyFatigue 82
    [83] = { func = FortifySkill, attacker = true, target = true },               -- fortifySkill 83
    -- fortifyMaximumMagicka 84
    [85] = { func = AbsorbAttribute, attacker = false, target = true },           -- absorbAttribute 85
    [86] = { func = DamageHealth, attacker = false, target = true },              -- absorbHealth 86
    -- absorbMagicka 87
    [88] = nil,                                                                   -- absorbFatigue 88
    [89] = { func = AbsorbSkill, attacker = false, target = true },               -- absorbSkill 89
    [90] = { func = PositiveModifier, attacker = false, target = true },          -- resistFire 90
    [91] = { func = PositiveModifier, attacker = false, target = true },          -- resistFrost 91
    [92] = { func = PositiveModifier, attacker = false, target = true },          -- resistShock 92
    [93] = { func = PositiveModifier, attacker = true, target = true },           -- resistMagicka 93
    -- resistCommonDisease 94
    -- resistBlightDisease 95
    -- resistCorprusDisease 96
    [97] = { func = PositiveModifier, attacker = false, target = true }, -- resistPoison 97
    [98] = { func = PositiveModifier, attacker = false, target = true }, -- resistNormalWeapons 98
    -- resistParalysis 99
    -- removeCurse 100
    -- turnUndead 101
    -- summonScamp 102
    -- summonClannfear 103
    -- summonDaedroth 104
    -- summonDremora 105
    -- summonAncestralGhost 106
    -- summonSkeletalMinion 107
    -- summonBonewalker 108
    -- summonGreaterBonewalker 109
    -- summonBonelord 110
    -- summonWingedTwilight 111
    -- summonHunger 112
    -- summonGoldenSaint 113
    -- summonFlameAtronach 114
    -- summonFrostAtronach 115
    -- summonStormAtronach 116
    [117] = { func = PositiveModifier, attacker = true, target = false }, -- fortifyAttack 117
    -- commandCreature 118
    -- commandHumanoid 119
    [120] = nil, -- boundDagger 120
    [121] = nil, -- boundLongsword 121
    [122] = nil, -- boundMace 122
    [123] = nil, -- boundBattleAxe 123
    [124] = nil, -- boundSpear 124
    [125] = nil, -- boundLongbow 125
    -- eXTRASPELL 126
    -- boundCuirass 127
    -- boundHelm 128
    -- boundBoots 129
    -- boundShield 130
    -- boundGloves 131
    -- corprus 132
    -- vampirism 133
    -- summonCenturionSphere 134
    [135] = { func = DamageHealth, attacker = false, target = true }, -- sunDamage 135
    -- stuntedMagicka 136
    -- summonFabricant 137
    -- callWolf 138
    -- callBear 139
    -- summonBonewolf 140
    -- sEffectSummonCreature04 141
    -- sEffectSummonCreature05 142
}

---@param effectId tes3.effect
---@return Resolver
function this.Get(effectId)
    return resolver[effectId]
end

-- TODO test actived case
-- unittest
---@param self EffectResolver
---@param unitwind MyUnitWind
function this.RunTest(self, unitwind)
    unitwind:start("DPSTooltips.effect")

    unitwind:test("Empty", function()
        local r = self.Get(tes3.effect.detectAnimal)
        unitwind:expect(r).toBe(nil)
    end)

    unitwind:test("DamageHealth", function()
        local e = {
            tes3.effect.fireDamage,
            tes3.effect.shockDamage,
            tes3.effect.frostDamage,
            tes3.effect.damageHealth,
            tes3.effect.poison,
            tes3.effect.absorbHealth,
            tes3.effect.sunDamage,
        }
        for _, v in ipairs(e) do
            --logger:debug(tostring(v))
            local r = self.Get(v)
            unitwind:expect(r).NOT.toBe(nil)
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = v,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(true)
            unitwind:expect(data.target.damages[params.key]).toBe(20)
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:test("DrainHealth", function()
        local v = tes3.effect.drainHealth
        local r = self.Get(v)
        unitwind:expect(r).NOT.toBe(nil)
        local data = self.CreateScratchData()
        ---@type Params
        local params = {
            data = data,
            key = v,
            value = 10,
            speed = 2,
            isSelf = false,
            attacker = r.attacker,
            target = r.target,
        }
        local affect = r.func(params)
        unitwind:expect(affect).toBe(true)
        unitwind:expect(data.target.damages[params.key]).toBe(10)
        params.isSelf = true
        affect = r.func(params)
        unitwind:expect(affect).toBe(false)
    end)

    unitwind:test("CurePoison", function()
        local v = tes3.effect.curePoison
        local r = self.Get(v)
        unitwind:expect(r).NOT.toBe(nil)
        local data = self.CreateScratchData()
        ---@type Params
        local params = {
            data = data,
            key = v,
            value = 10,
            speed = 2,
            isSelf = false,
            attacker = r.attacker,
            target = r.target,
        }
        local affect = r.func(params)
        unitwind:expect(affect).toBe(true)
        unitwind:expect(data.target.positives[params.key]).toBe(1)
        params.isSelf = true
        affect = r.func(params)
        unitwind:expect(affect).toBe(false)
    end)

    unitwind:test("PositiveModifier", function()
        local e = {
            [tes3.effect.shield] = { true, false },
            [tes3.effect.fireShield] = { true, false },
            [tes3.effect.lightningShield] = { true, false },
            [tes3.effect.frostShield] = { true, false },
            [tes3.effect.sanctuary] = { true, false },
            [tes3.effect.dispel] = { true, true },
            [tes3.effect.fortifyHealth] = { true, false },
            [tes3.effect.resistFire] = { true, false },
            [tes3.effect.resistFrost] = { true, false },
            [tes3.effect.resistShock] = { true, false },
            [tes3.effect.resistMagicka] = { true, true },
            [tes3.effect.resistPoison] = { true, false },
            [tes3.effect.resistNormalWeapons] = { true, false },
            [tes3.effect.fortifyAttack] = { false, true },
        }
        for k, v in pairs(e) do
            -- logger:debug(tostring(k))
            local r = self.Get(k)
            unitwind:expect(r).NOT.toBe(nil)
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = k,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v[1])
            if affect then
                unitwind:expect(data.target.positives[params.key]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v[2])
            if affect then
                unitwind:expect(data.attacker.positives[params.key]).toBe(10)
            end
        end
    end)

    unitwind:test("PositiveModifierWithSpeed", function()
        local v = tes3.effect.restoreHealth
        local r = self.Get(v)
        unitwind:expect(r).NOT.toBe(nil)
        local data = self.CreateScratchData()
        ---@type Params
        local params = {
            data = data,
            key = v,
            value = 10,
            speed = 2,
            isSelf = false,
            attacker = r.attacker,
            target = r.target,
        }
        local affect = r.func(params)
        unitwind:expect(affect).toBe(true)
        unitwind:expect(data.target.positives[params.key]).toBe(20)
        params.isSelf = true
        affect = r.func(params)
        unitwind:expect(affect).toBe(false)
    end)

    unitwind:test("NegativeModifier", function()
        local e = {
            [tes3.effect.weaknesstoFire] = { true, false },
            [tes3.effect.weaknesstoFrost] = { true, false },
            [tes3.effect.weaknesstoShock] = { true, false },
            [tes3.effect.weaknesstoMagicka] = { true, true },
            [tes3.effect.weaknesstoPoison] = { true, false },
            [tes3.effect.weaknesstoNormalWeapons] = { true, false },
            [tes3.effect.blind] = { false, true },
        }
        for k, v in pairs(e) do
            -- logger:debug(tostring(k))
            local r = self.Get(k)
            unitwind:expect(r).NOT.toBe(nil)
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = k,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v[1])
            if affect then
                unitwind:expect(data.target.negatives[params.key]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v[2])
            if affect then
                unitwind:expect(data.attacker.negatives[params.key]).toBe(10)
            end
        end
    end)

    unitwind:test("MultModifier", function()
        local e = {
            tes3.effect.spellAbsorption,
            tes3.effect.reflect,
        }
        for _, v in ipairs(e) do
            -- logger:debug(tostring(k))
            local r = self.Get(v)
            unitwind:expect(r).NOT.toBe(nil)
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = v,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(true)
            unitwind:expect(data.target.positives[params.key]).toBe(0.9)
            affect = r.func(params)
            unitwind:expect(data.target.positives[params.key]).toBe(0.81)
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:test("FortifyAttribute", function()
        local e = tes3.effect.fortifyAttribute
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(attributeFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                attribute = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.attributes.fortify[params.attribute]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.attributes.fortify[params.attribute]).toBe(10)
            end
        end
    end)

    unitwind:test("DamageAttribute", function()
        local e = tes3.effect.damageAttribute
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(attributeFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                attribute = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.attributes.damage[params.attribute]).toBe(20)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.attributes.damage[params.attribute]).toBe(20)
            end
        end
    end)

    unitwind:test("DrainAttribute", function()
        local e = tes3.effect.drainAttribute
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(attributeFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                attribute = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.attributes.drain[params.attribute]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.attributes.drain[params.attribute]).toBe(10)
            end
        end
    end)

    unitwind:test("AbsorbAttribute", function()
        local e = tes3.effect.absorbAttribute
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(attributeFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                attribute = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target or v.attacker)
            if v.target or v.attacker then
                unitwind:expect(data.attacker.attributes.absorb[params.attribute]).toBe(10)
                unitwind:expect(data.target.attributes.absorb[params.attribute]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(false) -- self absorb is no affect
        end
    end)

    unitwind:test("RestoreAttribute", function()
        local e = tes3.effect.restoreAttribute
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(attributeFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                attribute = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.attributes.restore[params.attribute]).toBe(20)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.attributes.restore[params.attribute]).toBe(20)
            end
        end
    end)

    unitwind:test("FortifySkill", function()
        local e = tes3.effect.fortifySkill
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(skillFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                skill = k,
                weaponSkillId = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.skills.fortify[params.skill]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.skills.fortify[params.skill]).toBe(10)
            end
            params.weaponSkillId = tes3.skill.unarmored -- mismatch
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:test("DamageSkill", function()
        local e = tes3.effect.damageSkill
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(skillFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                skill = k,
                weaponSkillId = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.skills.damage[params.skill]).toBe(20)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.skills.damage[params.skill]).toBe(20)
            end
            params.weaponSkillId = tes3.skill.unarmored -- mismatch
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:test("DrainSkill", function()
        local e = tes3.effect.drainSkill
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(skillFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                skill = k,
                weaponSkillId = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.skills.drain[params.skill]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.skills.drain[params.skill]).toBe(10)
            end
            params.weaponSkillId = tes3.skill.unarmored -- mismatch
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:test("AbsorbSkill", function()
        local e = tes3.effect.absorbSkill
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(skillFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                skill = k,
                weaponSkillId = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target or v.attacker)
            if v.target or v.attacker then
                unitwind:expect(data.attacker.skills.absorb[params.skill]).toBe(10)
                unitwind:expect(data.target.skills.absorb[params.skill]).toBe(10)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)         -- self absorb is no affect
            params.weaponSkillId = tes3.skill.unarmored -- mismatch
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:test("RestoreSkill", function()
        local e = tes3.effect.restoreSkill
        local r = self.Get(e)
        unitwind:expect(r).NOT.toBe(nil)
        for k, v in pairs(skillFilter) do
            -- logger:debug(tostring(k))
            local data = self.CreateScratchData()
            ---@type Params
            local params = {
                data = data,
                key = e,
                value = 10,
                speed = 2,
                isSelf = false,
                attacker = r.attacker,
                target = r.target,
                skill = k,
                weaponSkillId = k,
            }
            local affect = r.func(params)
            unitwind:expect(affect).toBe(v.target)
            if affect then
                unitwind:expect(data.target.skills.restore[params.skill]).toBe(20)
            end
            params.isSelf = true
            affect = r.func(params)
            unitwind:expect(affect).toBe(v.attacker)
            if affect then
                unitwind:expect(data.attacker.skills.restore[params.skill]).toBe(20)
            end
            params.weaponSkillId = tes3.skill.unarmored -- mismatch
            affect = r.func(params)
            unitwind:expect(affect).toBe(false)
        end
    end)

    unitwind:finish()
end

return this
