local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local API = require('openmw.interfaces').SkillFramework
local l10n = core.l10n('Swimming')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')

local skillId = 'swimming_skill'
local checkTimer = 0
local CHECK_INTERVAL = 1.0

local dashSpeedBase = 300
local dashSpeedMax = 1500
local dashFatigueCostBase = 40
local dashFatigueCostMin = 15
local dashDurationBase = 0.5
local dashDurationMax = 1.0
local dashSfxVolume = 1.0

local wasSwimming = false
local currentSpeedBonus = 0
local currentCombatModifier = 0
local dashTotal = 0
local canDash = true

print("==========================================")
print("SWIMMING SKILL MOD: Loading")
print("==========================================")

API.registerSkill(skillId, {
    name = l10n('skill_swimming_name'),
    description = l10n('skill_swimming_desc'),
    icon = { fgr = "icons/swimming/swim.dds" },
    attribute = "endurance",
    specialization = API.SPECIALIZATION.Combat,
    skillGain = {
        [1] = 0.15,
    },
    startLevel = 5,
    maxLevel = 100,
    statsWindowProps = {
        subsection = API.STATS_WINDOW_SUBSECTIONS.Movement
    }
})

API.registerRaceModifier(skillId, 'argonian', 25)
API.registerRaceModifier(skillId, 'khajiit', 10)
API.registerRaceModifier(skillId, 'nord', -5)
API.registerRaceModifier(skillId, 'orc', -5)

print("SWIMMING SKILL MOD: ✓ Skill registered")

local function getSpeedBonus()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return 0 end
    return skillStat.modified
end

local function getCombatModifier()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return -15 end
    
    local swimmingSkill = skillStat.modified
    
    if swimmingSkill >= 100 then
        return 20
    elseif swimmingSkill >= 90 then
        return 15
    elseif swimmingSkill >= 80 then
        return 10
    elseif swimmingSkill >= 60 then
        return 5
    elseif swimmingSkill >= 50 then
        return 0
    elseif swimmingSkill >= 30 then
        return -5
    elseif swimmingSkill >= 15 then
        return -10
    else
        return -15
    end
end

local function getDashParameters()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return dashSpeedBase, dashFatigueCostBase, dashDurationBase end
    
    local swimmingSkill = skillStat.modified
    local skillPercent = math.min(swimmingSkill / 100.0, 1.0)
    
    local dashSpeed = dashSpeedBase + (dashSpeedMax - dashSpeedBase) * skillPercent
    local fatigueCost = dashFatigueCostBase - (dashFatigueCostBase - dashFatigueCostMin) * skillPercent
    local duration = dashDurationBase + (dashDurationMax - dashDurationBase) * skillPercent
    
    return dashSpeed, fatigueCost, duration
end

local function speedMod(modSign, modVal)
    if modVal > 0 then
        modVal = math.abs(modVal)
        local speedAttr = types.Actor.stats.attributes.speed(self)
        if modSign > 0 then
            speedAttr.modifier = math.max(0, speedAttr.modifier + modVal)
        else
            speedAttr.modifier = math.max(0, speedAttr.modifier - modVal)
        end
    end
end

local function applySpeedBonus()
    local bonus = getSpeedBonus()
    local speedAttr = types.Actor.stats.attributes.speed(self)
    
    if currentSpeedBonus > 0 then
        speedAttr.modifier = speedAttr.modifier - currentSpeedBonus
    end
    
    speedAttr.modifier = speedAttr.modifier + bonus
    currentSpeedBonus = bonus
    
    print("SWIMMING SKILL MOD: Applied +" .. bonus .. " Speed bonus")
end

local function removeSpeedBonus()
    if currentSpeedBonus > 0 then
        local speedAttr = types.Actor.stats.attributes.speed(self)
        speedAttr.modifier = speedAttr.modifier - currentSpeedBonus
        print("SWIMMING SKILL MOD: Removed +" .. currentSpeedBonus .. " Speed bonus")
        currentSpeedBonus = 0
    end
end

local function applyCombatModifier()
    local modifier = getCombatModifier()
    local skills = types.NPC.stats.skills
    
    if currentCombatModifier ~= 0 then
        skills.axe(self).modifier = skills.axe(self).modifier - currentCombatModifier
        skills.bluntweapon(self).modifier = skills.bluntweapon(self).modifier - currentCombatModifier
        skills.longblade(self).modifier = skills.longblade(self).modifier - currentCombatModifier
        skills.shortblade(self).modifier = skills.shortblade(self).modifier - currentCombatModifier
        skills.spear(self).modifier = skills.spear(self).modifier - currentCombatModifier
        skills.marksman(self).modifier = skills.marksman(self).modifier - currentCombatModifier
        skills.handtohand(self).modifier = skills.handtohand(self).modifier - currentCombatModifier
    end
    
    skills.axe(self).modifier = skills.axe(self).modifier + modifier
    skills.bluntweapon(self).modifier = skills.bluntweapon(self).modifier + modifier
    skills.longblade(self).modifier = skills.longblade(self).modifier + modifier
    skills.shortblade(self).modifier = skills.shortblade(self).modifier + modifier
    skills.spear(self).modifier = skills.spear(self).modifier + modifier
    skills.marksman(self).modifier = skills.marksman(self).modifier + modifier
    skills.handtohand(self).modifier = skills.handtohand(self).modifier + modifier
    
    currentCombatModifier = modifier
    
    print(string.format("SWIMMING SKILL MOD: Combat effectiveness %+d", modifier))
end

local function removeCombatModifier()
    if currentCombatModifier ~= 0 then
        local skills = types.NPC.stats.skills
        
        skills.axe(self).modifier = skills.axe(self).modifier - currentCombatModifier
        skills.bluntweapon(self).modifier = skills.bluntweapon(self).modifier - currentCombatModifier
        skills.longblade(self).modifier = skills.longblade(self).modifier - currentCombatModifier
        skills.shortblade(self).modifier = skills.shortblade(self).modifier - currentCombatModifier
        skills.spear(self).modifier = skills.spear(self).modifier - currentCombatModifier
        skills.marksman(self).modifier = skills.marksman(self).modifier - currentCombatModifier
        skills.handtohand(self).modifier = skills.handtohand(self).modifier - currentCombatModifier
        
        print(string.format("SWIMMING SKILL MOD: Removed combat modifier (%+d)", currentCombatModifier))
        currentCombatModifier = 0
    end
end

local function onInputAction(action)
    if action == input.ACTION.Jump then
        if types.Actor.isSwimming(self) and canDash then
            local dynamic = types.Actor.stats.dynamic
            local currentFatigue = dynamic.fatigue(self).current
            
            local dashSpeed, fatigueCost, duration = getDashParameters()
            
            if currentFatigue >= fatigueCost then
                canDash = false
                
                dynamic.fatigue(self).current = math.max(0, currentFatigue - fatigueCost)
                
                speedMod(1, dashSpeed)
                dashTotal = dashTotal + dashSpeed
                
                if ambient and dashSfxVolume > 0 then
                    local skillStat = API.getSkillStat(skillId)
                    local swimmingSkill = skillStat and skillStat.modified or 5
                    local pitchBonus = (swimmingSkill / 100.0) * 0.3
                    
                    ambient.playSound("footwaterleft", { 
                        volume = (0.6 * dashSfxVolume), 
                        pitch = (0.95 + pitchBonus + 0.1 * math.random()) 
                    })
                    ambient.playSound("footwaterright", { 
                        volume = (0.6 * dashSfxVolume), 
                        pitch = (0.95 + pitchBonus + 0.1 * math.random()) 
                    })
                end
                
                print(string.format("SWIMMING SKILL MOD: DASH! +%.0f speed for %.1fs (-%d fatigue)", 
                    dashSpeed, duration, fatigueCost))
                
                async:newUnsavableSimulationTimer(
                    duration,
                    function()
                        speedMod(-1, dashTotal)
                        dashTotal = 0
                        canDash = true
                    end
                )
            else
                ui.showMessage(string.format("Not enough fatigue for dash (need %.0f)", fatigueCost))
            end
        end
    end
end

local function onUpdate(dt)
    checkTimer = checkTimer + dt
    
    if checkTimer >= CHECK_INTERVAL then
        checkTimer = 0
        
        local isSwimming = types.Actor.isSwimming(self)
        
        if isSwimming then
            API.skillUsed(skillId, { useType = 1 })
            
            if not wasSwimming then
                applySpeedBonus()
                applyCombatModifier()
                wasSwimming = true
            end
        else
            if wasSwimming then
                removeSpeedBonus()
                removeCombatModifier()
                wasSwimming = false
            end
        end
    end
end

print("==========================================")
print("SWIMMING SKILL MOD: Ready!")
print("Racial bonuses:")
print("  Argonian: +25 | Khajiit: +10")
print("  Nord: -5 | Orc: -5")
print("==========================================")

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInputAction = onInputAction,
        onSave = function()
            return {
                wasSwimming = wasSwimming,
                currentSpeedBonus = currentSpeedBonus,
                currentCombatModifier = currentCombatModifier,
                dashTotal = dashTotal,
                version = 1
            }
        end,
        onLoad = function(data)
            if data then
                wasSwimming = data.wasSwimming or false
                currentSpeedBonus = data.currentSpeedBonus or 0
                currentCombatModifier = data.currentCombatModifier or 0
                dashTotal = data.dashTotal or 0
                
                if dashTotal > 0 then
                    speedMod(-1, dashTotal)
                    dashTotal = 0
                end
                if currentCombatModifier ~= 0 then
                    removeCombatModifier()
                end
            end
        end,
    }
}