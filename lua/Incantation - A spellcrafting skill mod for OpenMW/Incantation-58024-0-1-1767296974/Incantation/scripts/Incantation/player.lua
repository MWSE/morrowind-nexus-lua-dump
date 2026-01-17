local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local API = require('openmw.interfaces').SkillFramework
local I = require('openmw.interfaces')
local l10n = core.l10n('Incantation')
local ui = require('openmw.ui')

local skillId = 'incantation_skill'
local knownSpells = {}
local customSpells = {}
local spellCheckTimer = 0
local CHECK_INTERVAL = 0.5
local castedSpell = nil
local lastCastCost = 0

local Player = types.Player

print("==========================================")
print("INCANTATION SKILL MOD: Loading")
print("==========================================")

API.registerSkill(skillId, {
    name = l10n('skill_incantation_name'),
    description = l10n('skill_incantation_desc'),
    icon = { fgr = "icons/incantation/Incantation.dds" },
    attribute = "intelligence",
    specialization = API.SPECIALIZATION.Magic,
    skillGain = {
        [1] = 1.0,
    },
    startLevel = 5,
    maxLevel = 100,
    statsWindowProps = {
        subsection = API.STATS_WINDOW_SUBSECTIONS.Magic
    }
})

-- Racial bonuses for naturally magical races
API.registerRaceModifier(skillId, 'breton', 10)
API.registerRaceModifier(skillId, 'altmer', 15)
API.registerRaceModifier(skillId, 'dunmer', 5)

print("INCANTATION SKILL MOD: ✓ Skill registered")

-- Calculate magicka refund percentage based on skill level
-- Simple linear: 0.5% per skill level, so 50% at skill 100
local function getMagickaRefundPercent()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return 0 end
    
    local incantationSkill = skillStat.modified
    
    -- 0.5% per skill level
    return math.min(incantationSkill * 0.005, 0.50)
end

-- Calculate spell creation cost reduction (optional bonus)
local function getCreationCostReduction()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return 1.0 end
    
    local incantationSkill = skillStat.modified
    
    -- At 100 skill: 25% cost reduction for creating spells
    -- Linear scaling from 0% at skill 0 to 25% at skill 100
    local reduction = incantationSkill * 0.0025  -- Max 0.25 at skill 100
    return 1.0 - reduction
end

local function isCustomSpell(spellId)
    return spellId:find("^player%$") or spellId:find("^Generated")
end

local function initializeKnownSpells()
    knownSpells = {}
    customSpells = {}
    local spells = types.Actor.spells(self)
    
    for _, spell in ipairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            knownSpells[spell.id] = true
            
            if isCustomSpell(spell.id) then
                customSpells[spell.id] = {
                    name = spell.name,
                    cost = spell.cost,
                    effects = {}
                }
                
                for _, effect in ipairs(spell.effects) do
                    table.insert(customSpells[spell.id].effects, {
                        id = effect.id,
                        school = effect.effect.school
                    })
                end
            end
        end
    end
    
    print(string.format("INCANTATION SKILL MOD: Initialized - %d total spells, %d custom spells", 
        #knownSpells, #customSpells))
end

local function checkForNewSpells()
    local spells = types.Actor.spells(self)
    
    for _, spell in ipairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            if not knownSpells[spell.id] then
                knownSpells[spell.id] = true
                
                if isCustomSpell(spell.id) then
                    customSpells[spell.id] = {
                        name = spell.name,
                        cost = spell.cost,
                        effects = {}
                    }
                    
                    for _, effect in ipairs(spell.effects) do
                        table.insert(customSpells[spell.id].effects, {
                            id = effect.id,
                            school = effect.effect.school
                        })
                    end
                    
                    -- Apply cost reduction based on skill
                    local baseCost = spell.cost
                    local costReduction = getCreationCostReduction()
                    local xpGain = math.max(5.0, (baseCost * costReduction) / 10)
                    
                    API.skillUsed(skillId, { 
                        useType = 1, 
                        skillGain = xpGain 
                    })
                    
                    local refundPercent = getMagickaRefundPercent()
                    ui.showMessage(string.format("Custom spell created: %s (+%.1f Incantation XP)\nMagicka refund on cast: %.1f%%", 
                        spell.name, xpGain, refundPercent * 100))
                    
                    print(string.format("INCANTATION SKILL MOD: New custom spell - ID='%s' Name='%s' Cost=%d (+%.1f XP)", 
                        spell.id, spell.name, spell.cost, xpGain))
                    
                    for _, effect in ipairs(spell.effects) do
                        print(string.format("  Effect: %s (School: %s)", 
                            effect.id, effect.effect.school))
                    end
                end
            end
        end
    end
end

I.AnimationController.addTextKeyHandler('', function(groupname, key)
    if groupname == "spellcast" then
        if key == "self start" or key == "touch start" or key == "target start" then
            castedSpell = Player.getSelectedSpell(self)
            if castedSpell and isCustomSpell(castedSpell.id) then
                -- Store the cost before casting
                lastCastCost = castedSpell.cost
            end
        elseif key == "self stop" or key == "touch stop" or key == "target stop" then
            castedSpell = nil
            lastCastCost = 0
        end
    end
end)

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
    local magickaSkills = {
        destruction = true,
        restoration = true,
        conjuration = true,
        mysticism = true,
        illusion = true,
        alteration = true,
    }
    
    if magickaSkills[skillId] and castedSpell then
        if isCustomSpell(castedSpell.id) then
            -- Grant XP for casting
            local xpGain = math.max(1.0, castedSpell.cost / 20)
            API.skillUsed('incantation_skill', { 
                useType = 1, 
                skillGain = xpGain 
            })
            
            -- Apply magicka refund
            local refundPercent = getMagickaRefundPercent()
            if refundPercent > 0 and lastCastCost > 0 then
                local refundAmount = math.floor(lastCastCost * refundPercent)
                
                local dynamic = types.Actor.stats.dynamic
                local currentMagicka = dynamic.magicka(self).current
                local maxMagicka = dynamic.magicka(self).base
                
                -- Apply refund, capping at max magicka
                local newMagicka = math.min(currentMagicka + refundAmount, maxMagicka)
                dynamic.magicka(self).current = newMagicka
                
                print(string.format("INCANTATION SKILL MOD: Cast custom spell '%s' (+%.1f XP, +%d magicka [%.1f%% refund])", 
                    castedSpell.name, xpGain, refundAmount, refundPercent * 100))
                
                if refundAmount >= 5 then
                    ui.showMessage(string.format("+%d Magicka refunded (%.1f%%)", 
                        refundAmount, refundPercent * 100))
                end
            else
                print(string.format("INCANTATION SKILL MOD: Cast custom spell '%s' (+%.1f XP)", 
                    castedSpell.name, xpGain))
            end
        end
    end
end)

local function onUpdate(dt)
    spellCheckTimer = spellCheckTimer + dt
    
    if spellCheckTimer >= CHECK_INTERVAL then
        spellCheckTimer = 0
        checkForNewSpells()
    end
end

local function onLoad(data)
    if data then
        if data.knownSpells then
            knownSpells = data.knownSpells
        end
        if data.customSpells then
            customSpells = data.customSpells
        end
        print(string.format("INCANTATION SKILL MOD: Loaded %d known spells, %d custom spells", 
            #knownSpells, #customSpells))
    else
        initializeKnownSpells()
    end
end

initializeKnownSpells()

local skillStat = API.getSkillStat(skillId)
local currentRefund = getMagickaRefundPercent()

print("==========================================")
print("INCANTATION SKILL MOD: Ready!")
print("Create custom spells at spellmakers!")
print("Current Incantation skill: " .. (skillStat and skillStat.modified or 5))
print(string.format("Current magicka refund: %.1f%%", currentRefund * 100))
print("")
print("XP gains:")
print("  Creating spell: 5-20 XP (based on cost)")
print("  Casting spell: 1-10 XP (based on cost)")
print("")
print("Skill benefits:")
print("  +0.5% magicka refund per skill level")
print("  Skill 5: 2.5% refund")
print("  Skill 25: 12.5% refund")
print("  Skill 50: 25% refund")
print("  Skill 75: 37.5% refund")
print("  Skill 100: 50% refund")
print("==========================================")

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function()
            return {
                knownSpells = knownSpells,
                customSpells = customSpells,
                version = 1
            }
        end,
        onLoad = onLoad,
    }
}