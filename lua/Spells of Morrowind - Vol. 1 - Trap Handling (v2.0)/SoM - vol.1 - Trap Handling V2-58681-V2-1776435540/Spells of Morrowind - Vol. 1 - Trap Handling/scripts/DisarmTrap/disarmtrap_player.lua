-- ============================================================
-- Spells of Morrowind - Vol. 1 - Trap Handling
-- ============================================================

local self   = require('openmw.self')
local types  = require('openmw.types')
local ui     = require('openmw.ui')
local I      = require('openmw.interfaces')
local core   = require('openmw.core')
local camera = require('openmw.camera')
local util   = require('openmw.util')
local nearby = require('openmw.nearby')
local async  = require('openmw.async')
local input  = require('openmw.input')
local debug  = require('openmw.debug')
local storage = require('openmw.storage')

-- Timing provided by user: Touch Start (293.66) -> Release (294.60) = 0.94s
local INTERCEPT_DELAY = 0.94

local processedNPCs = {}
local npcScanTimer = 0
local activeRegens = {}
local pendingSkillGains = {}
local lastMagicka = 0
local isCasting = false

-- ============================================================
-- UI & Restoration Handler
-- ============================================================
local function onDisarmResult(data)
    -- Instantly purge all mod-related icons and active effects
    pcall(function()
        if types.Actor.activeSpells then
            local spells = types.Actor.activeSpells(self)
            spells:remove('absorbtrap_spell')
            spells:remove('disarmtrap_spell')
            spells:remove('disarmtrap_abs_magicka')
            spells:remove('trap_abs_mg')
        end
    end)

    if data.mode == 'disarm' then
        if data.success then
            ui.showMessage("Trap disarmed!")
        else
            core.sound.playSound3d("Open Lock Fail", self)
            if data.tooComplex then
                ui.showMessage("The trap is too complex.")
            else
                ui.showMessage("You failed to disarm the trap.")
            end
        end
    elseif data.mode == 'absorb' then
        if data.success then
            ui.showMessage(string.format("Successfully absorbing %d Magicka over 5 seconds.", data.amount or 25))
        else
            core.sound.playSound3d("Open Lock Fail", self)
            ui.showMessage("You've failed to absorb the trap.")
        end
    end
end

local function levelUpSkill(skillId, skillName, newBaseValue)
    local skill = types.NPC.stats.skills[skillId](self)
    skill.base = newBaseValue
    
    local skillNameGMST = core.getGMST('sSkill' .. skillName) or skillName
    local skillUpMsg = core.getGMST('sSkillUp') or "Your %s skill has increased to %d."
    ui.showMessage(string.format(skillUpMsg, skillNameGMST, newBaseValue))
    core.sound.playSound3d("skillraise", self)
    
    local levelStats = types.Player.stats.level(self)
    if levelStats then
        levelStats.progress = levelStats.progress + 1
        if skillId == 'alteration' or skillId == 'mysticism' then
            local currentAttrVal = levelStats.skillIncreasesForAttribute['willpower'] or 0
            levelStats.skillIncreasesForAttribute['willpower'] = currentAttrVal + 1
            local currentSpecVal = levelStats.skillIncreasesForSpecialization['magic'] or 0
            levelStats.skillIncreasesForSpecialization['magic'] = currentSpecVal + 1
        end
    end
end

local function hookMagickaDropSuccess(spellId, skillId, skillName)
    local gainAmount = (skillId == 'mysticism') and 0.02 or 0.01
    pendingSkillGains[skillId] = {
        timer = 0.4,
        skillName = skillName,
        amount = gainAmount
    }
end

local function onUpdate(dt)
    local magickaStats = types.Actor.stats.dynamic.magicka(self)
    if not magickaStats then return end
    
    local currentMagicka = magickaStats.current
    if not currentMagicka then return end
    
    if currentMagicka < lastMagicka then
        local currentSpell = types.Actor.getSelectedSpell(self)
        if currentSpell then
            if currentSpell.id == 'disarmtrap' or currentSpell.id == 'disarmtrap_spell' then
                pendingSkillGains['alteration'] = { skillName = 'Alteration', amount = 0.01 }
            elseif currentSpell.id == 'detecttrap_alt_spell' then
                pendingSkillGains['alteration'] = { skillName = 'Alteration', amount = 0.002 }
            elseif currentSpell.id == 'absorbtrap' or currentSpell.id == 'absorbtrap_spell' then
                pendingSkillGains['mysticism'] = { skillName = 'Mysticism', amount = 0.02 }
            elseif currentSpell.id == 'detecttrap_spell' then
                pendingSkillGains['mysticism'] = { skillName = 'Mysticism', amount = 0.002 }
            end
        end
    end
    lastMagicka = currentMagicka

    -- Process smooth stat regeneration
    for statName, data in pairs(activeRegens) do
        data.timer = data.timer - dt
        local stat = types.Actor.stats.dynamic[statName](self)
        if stat then
            local heal = data.perSecond * dt
            stat.current = math.min(stat.base, stat.current + heal)
        end
        if data.timer <= 0 then
            activeRegens[statName] = nil
        end
    end
end

-- ============================================================
-- Vanilla Cast Interception (Essential for Gameplay)
-- ============================================================
local function interceptVanillaCast()
    local currentSpell = types.Actor.getSelectedSpell(self)
    if not currentSpell then return end
    local spellId = currentSpell.id
    if spellId ~= 'disarmtrap_spell' and spellId ~= 'absorbtrap_spell' and spellId ~= 'detecttrap_spell' and spellId ~= 'detecttrap_alt_spell' then return end

    -- Award Skill XP only if magicka was spent (verified success) and animation finished
    local skillKey = (spellId == 'disarmtrap_spell' or spellId == 'detecttrap_alt_spell') and 'alteration' or 'mysticism'
    local skillData = pendingSkillGains[skillKey]
    if skillData then
        local skill = types.NPC.stats.skills[skillKey](self)
        if skill and skill.base and skill.base < 100 then
            local currentProgress = skill.progress + skillData.amount
            local currentBase = skill.base
            while currentProgress >= 1.00 and currentBase < 100 do
                currentBase = currentBase + 1
                currentProgress = currentProgress - 1.00
                levelUpSkill(skillKey, skillData.skillName, currentBase)
            end
            skill.progress = math.max(0, currentProgress)
        end
        pendingSkillGains[skillKey] = nil
    end

    local cp = -camera.getPitch()
    local cy = camera.getYaw()
    local cameraDir = util.vector3(math.cos(cp) * math.sin(cy), math.cos(cp) * math.cos(cy), math.sin(cp))
    local startPos = camera.getPosition()
    local hitObject = nil
    
    local ray = nearby.castRay(startPos, startPos + (cameraDir * 500), { ignore = self })
    if ray.hit and ray.hitObject then
        hitObject = ray.hitObject
    end

    core.sendGlobalEvent('MagExp_OnMagicHit', {
        attacker   = self,
        target     = hitObject,
        spellId    = spellId,
        hitPos     = ray.hitPos or startPos,
        spellType  = core.magic.RANGE.Touch,
        isAoE      = false,
        area       = 0
    })
end

local function onInputAction(id)
    if id == input.ACTION.Use then
        if types.Actor.getStance(self) == types.Actor.STANCE.Spell then
            local currentSpell = types.Actor.getSelectedSpell(self)
            if currentSpell and (currentSpell.id == 'disarmtrap_spell' or currentSpell.id == 'absorbtrap_spell' or currentSpell.id == 'detecttrap_spell' or currentSpell.id == 'detecttrap_alt_spell') then
                if isCasting then return end
                
                local magicka = types.Actor.stats.dynamic.magicka(self).current
                local spellRec = core.magic.spells.records[currentSpell.id]
                if spellRec and magicka >= (spellRec.cost or 0) then
                    isCasting = true
                    -- Proactively clear any lingering mod icons/effects before starting new cast
                    onDisarmResult({ count = 0 })
                    
                    local cSnd = (currentSpell.id == 'disarmtrap_spell' or currentSpell.id == 'detecttrap_alt_spell') and "alteration cast" or "mysticism cast"
                    core.sound.playSound3d(cSnd, self)
                    async:newUnsavableSimulationTimer(INTERCEPT_DELAY, function()
                        isCasting = false
                        if types.Actor.getStance(self) == types.Actor.STANCE.Spell then
                            interceptVanillaCast()
                        end
                    end)
                end
            end
        end
    end
end

return {
    eventHandlers = {
        DisarmTrap_Result = onDisarmResult,
        DetectTrap_Result = function(data)
            local diffText = ""
            if data.cost >= 98 then diffText = "Lethal"
            elseif data.cost >= 63 then diffText = "Very Strong"
            elseif data.cost >= 35 then diffText = "Strong"
            elseif data.cost >= 15 then diffText = "Moderate"
            else diffText = "Weak"
            end
            ui.showMessage(string.format("Trap: %s\nTrap Level: %d\nTrap Power: %s", data.name, data.cost, diffText))
        end,
        DetectTrapAlt_Result = function(data)
            ui.showMessage(string.format("Trap Level: %d", data.cost))
        end,
        StartRestoration = function(data)
            if not data or not data.stat then return end
            local gainedStat = data.stat
            local totalToHeal = data.amount or 25
            activeRegens[gainedStat] = {
                timer = 5.0,
                perSecond = totalToHeal / 5.0
            }
        end,
        AddVfx = function(data)
            if data and data.model then
                if I.AnimationController.addVfx then
                    I.AnimationController.addVfx(self, data.model, data.options or { mwMagicVfx = true })
                end
            end
        end,
    },
    engineHandlers = {
        onInputAction = onInputAction,
        onUpdate = onUpdate,
    }
}
