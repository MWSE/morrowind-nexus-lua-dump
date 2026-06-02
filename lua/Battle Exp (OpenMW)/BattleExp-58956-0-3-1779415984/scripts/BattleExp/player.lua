-- useful commands for testing:
-- reloadlua
-- luap / exit()
-- I.SkillFramework.skillLevelUp('battle_experience')

local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local player = require('openmw.self')
local SF = require('openmw.interfaces').SkillFramework
local storage = require('openmw.storage')
local core = require('openmw.core')

local H = require('scripts/BattleExp/helpers')
local log = H.log

local settings = storage.globalSection('SettingsBattleExp')
local DEBUG = settings:get('debug')
H.setDebug(DEBUG)

if not SF then
  error('[BattleExp] Skill Framework is not loaded! Make sure it is installed and enabled.')
end

local skillIdBattleExp = 'battle_experience'
local useTypes = { Kill = 1 }
timeLastDestructiveMagicUse = 0 -- os.time() of last Destruction or Enchant skill XP gain

SF.registerSkill(skillIdBattleExp, {
  name = 'Battle Experience',
  description = 'Hard-earned combat experience, forged in the ashes of slain foes.',
  icon = { fgr = 'icons/k/Attribute_Endurance.dds' },
  attribute = 'endurance',
  specialization = SF.SPECIALIZATION.Combat,
  skillGain = {
    [useTypes.Kill] = 0.1 -- Amount of XP gained per kill (default)
  }
})

local statBattleExp = SF.getSkillStat(skillIdBattleExp)

-- Curve up the progression
-- progression 25->26 is ~4.18x slower than 5->6
-- progression 49->50 is ~8.26x slower than 5->6
local function getScaledExp(currentSkillLevel, xp)
  local oldSkillProgressionFormula = currentSkillLevel + 1
  local newSkillProgressionFormula = currentSkillLevel * currentSkillLevel / 10 + 1
  local scale = oldSkillProgressionFormula / newSkillProgressionFormula

  local scaledExp = xp * scale

  local userScale = math.min(math.max(settings:get('userBattleExpScale'), 1), 1000) / 100

  local userScaledExp = scaledExp * userScale

  log('XP scaling. currentSkillLevel: %s, xp: %.2f, scaledExp: %.4f, userScaledExp: %.4f',
    currentSkillLevel, xp, scaledExp, userScaledExp)

  return userScaledExp
end

-- Initialize the skill to a base level of 5 if it's currently 0 or nil
-- This ensures the UI progress bar math calculates properly
local skillStat = SF.getSkillStat(skillIdBattleExp)
if skillStat and (skillStat.base == nil or skillStat.base < 5) then
  skillStat.base = 5
end

local function growEndurance(amount)
  local endurance = types.Actor.stats.attributes.endurance(player)
  local newVal = endurance.base + amount
  endurance.base = newVal
  log('Endurance increased to %d due to BattleExp', newVal)
end

-- HP formula: e + (e^2 / 100)
-- 30 endurance = 39 hp (9 HP more than in vanilla)
-- 50 endurance = 75 hp (15 HP more than in vanilla)
-- 62 endurance = 100 hp (corresponds to ~10 lvl orc)
-- 100 endurance = 200 hp (corresponds to ~20 lvl orc)
local function calcMaxHP(endurance)
  return endurance + (endurance * endurance / 100)
end

local function setHealthFromEndurance()
  local e = types.Actor.stats.attributes.endurance(player).base
  local newMaxHP = calcMaxHP(e)
  local health = types.Actor.stats.dynamic.health(player)
  health.base = newMaxHP
  -- log('Endurance=%d -> MaxHP=%.1f', e, newMaxHP)
end

-- hide character level in char sheet
local API = require('openmw.interfaces').StatsWindow
local C = API.Constants
API.modifyLine(C.DefaultLines.LEVEL, {
  visibleFn = function()
    return not settings:get('hideLevel')
  end,
})

local meleeSkills = {
  axe = true, 
  bluntweapon = true, 
  longblade = true, 
  shortblade = true, 
  spear = true
}

local SP = require('openmw.interfaces').SkillProgression
SP.addSkillLevelUpHandler(function(skillId, source, options)
  -- prevent leveling up character  
  if settings:get('disableLevel') then
    options.levelUpProgress = 0
  end
end)

SP.addSkillUsedHandler(function(skillId, params)
  -- Track Destruction XP gains as a proxy for player-caused magic damage.
  -- When an enemy dies with an unknown killer, we check these timestamps to decide
  -- whether the player was likely responsible (within the last 60 seconds).
  local timeNow = os.time()
  if skillId == 'destruction' then
    timeLastDestructiveMagicUse = timeNow
    log('Destruction spell used, timestamp: %d', timeNow)
  end

  if not meleeSkills[skillId] then return end

  -- reward melee fighters with small BattleExp bonus for every hit  
  if settings:get('rewardMelee') then
    local meleeBonusExp = getScaledExp(statBattleExp.base, 0.01)
    log('Rewarded Melee use! %s', meleeBonusExp)
    SF.skillUsed(skillIdBattleExp, {
      skillGain = meleeBonusExp,
      useType = useTypes.Kill
    })
  end

  -- slightly increase all other melee skills for using a melee skill
  if settings:get('synergicTraining') then
    for otherSkillId, _ in pairs(meleeSkills) do
      if otherSkillId ~= skillId then
        local otherSkill = types.NPC.stats.skills[otherSkillId](player)
        local otherSkillLevel = otherSkill.base

        if otherSkillLevel < 50 then
          -- Level 5: 0.05 (+5%)
          -- Level 6: 0.0347 (+3.5%)
          -- Level 10: 0.0125 (+1.25%)
          -- Level 25: 0.002 (+0.2%)
          -- Level 49: ≈ 0.00052 (+0.05%)
          local synergicExpProgressBonus = 0.05 * (5 / otherSkillLevel) ^ 2

          log('synergically training: %s (level: %s, progress: %s, bonus: %s)', 
            otherSkillId, otherSkillLevel, otherSkill.progress, synergicExpProgressBonus)

          if otherSkill.progress + synergicExpProgressBonus >= 1 then
            -- granting xp would trigger a level up
            otherSkill.base = otherSkillLevel + 1
            otherSkill.progress = 0 -- reset progress after level up
          else
            -- we can't use SP.skillUsed because we don't want infinite loop
            otherSkill.progress = otherSkill.progress + synergicExpProgressBonus
          end
        end
      end
    end
  end
end)

local function trimZeros(numStr)
  numStr = numStr:gsub("(%..-)0+$", "%1")
  numStr = numStr:gsub("%.$", "")
  return numStr
end

local function formatDisplayedExp(xp)
  local abs = math.abs(xp)
  local num

  if xp % 1 == 0 then
    num = string.format("%.0f", xp)
  elseif abs >= 10 then
    num = string.format("%.1f", xp)
  elseif abs >= 1 then
    num = string.format("%.2f", xp)
  elseif abs >= 0.01 then
    num = string.format("%.3f", xp)
  else
    num = string.format("%.4f", xp)
  end

  return trimZeros(num)
end

local function getItemRecord(item)
  if item.type and item.type.record then
    return item.type.record(item)
  end
  return nil
end

local function getItemEnchantment(item)
  local record = getItemRecord(item)
  if record and record.enchant then
    return core.magic.enchantments.records[record.enchant]
  end
  return nil
end

local function GrantBattleExp(data)
  log('GrantBattleExp')
  local enemyLevel = data and data.level or 1
  local enemyName = data and data.name
  local baseExpFactor = 0.1

  local reqForCurentLevel = SF.getSkillProgressRequirement(skillIdBattleExp)

  local currentProgressPercent = statBattleExp.progress or 0
  local currentProgress = currentProgressPercent * reqForCurentLevel

  local xpNeededToLevelUp = reqForCurentLevel - currentProgress

  log('xpNeededToLevelUp: %s', tostring(xpNeededToLevelUp))

  local proportionalExp = enemyLevel * baseExpFactor
  local proportionalExpScaled = getScaledExp(statBattleExp.base, proportionalExp)

  if proportionalExpScaled >= xpNeededToLevelUp then
    local levelBefore = SF.getSkillStat(skillIdBattleExp).base

    -- add until level up
    SF.skillUsed(skillIdBattleExp, {
      skillGain = xpNeededToLevelUp,
      useType = useTypes.Kill
    })
    
    -- carryover surplus XP
    local surplusXP = proportionalExpScaled - xpNeededToLevelUp
    if surplusXP > 0 then
      SF.skillUsed(skillIdBattleExp, {
        skillGain = surplusXP,
        useType = useTypes.Kill
      })
    end

    local levelAfter = SF.getSkillStat(skillIdBattleExp).base
    local levelsGained = levelAfter - levelBefore

    growEndurance(levelsGained) -- +1 Endurance per skill level gained
    setHealthFromEndurance()
  else
    -- no skill level up
    SF.skillUsed(skillIdBattleExp, {
      skillGain = proportionalExpScaled,
      useType = useTypes.Kill
    })
  end

  if settings:get('showXpNotifications') then
    local xpToDisplay = settings:get('showScaledXp') and proportionalExpScaled or proportionalExp
    local xpToDisplayFormatted = formatDisplayedExp(xpToDisplay)
    ui.showMessage(string.format('%s defeated (+%s XP)', enemyName, xpToDisplayFormatted))
  end
end

return {
  engineHandlers = {
    onLoad = function()
      core.sendGlobalEvent('ClearAllPlayerSummons')
      core.sendGlobalEvent('ClearAllPlayerFollowers')      
      setHealthFromEndurance()
    end,
    onActive = function()
      setHealthFromEndurance()
    end,
    onInputAction = function(id)
      -- we need to track destructive enchanted items and spell scrolls used in magic stance
      -- (needed for cases when killer is unknown)
      local input = require('openmw.input')
      local self = require('openmw.self')
      local types = require('openmw.types')
      
      if id ~= input.ACTION.Use then return end

      log('Player pressed attack/use key')

      if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
        log('Player was not in magic stance (R)')
        return
      end

      log('Player used enchanted item, scroll or spell')
      local spell = types.Actor.getSelectedSpell(self)
      local item = types.Actor.getSelectedEnchantedItem(self)

      -- Absorb Health from Mysticism school is destructive as well
      if spell then
        log('Player used spell %s', spell.name)
        local spellRecord = core.magic.spells.records[spell.id]
        if spellRecord and spellRecord.effects then
          for i, effect in ipairs(spellRecord.effects) do
            local magicEffect = core.magic.effects.records[effect.id]

            if (magicEffect.name == 'Absorb Health') then
                log('it has Absorb Health effect')
                local timeNow = os.time()
                timeLastDestructiveMagicUse = timeNow
                break
            end
          end
        end
        return
      end

      if item then
        log('Player used enchanted item or scroll')
        log('item.recordId: %s', tostring(item.recordId))
      end

      local enchantment = getItemEnchantment(item)
      if enchantment then
        for _, effect in pairs(enchantment.effects) do
            local magicEffect = core.magic.effects.records[effect.id]
            local magicSchool = magicEffect.school
            log('magic effect id: %s', effect.id)
            log('magic effect school: %s', magicSchool)

            if magicSchool == 'destruction' then
              log('Player wrecks havoc with magic item or scroll')
              local timeNow = os.time()
              timeLastDestructiveMagicUse = timeNow
            break
          end
        end
      end
    end
  },
  eventHandlers = {
    UiModeChanged = function(data)
    if not data.newMode then
      -- UI was just closed (rest, char sheet, etc.)
      setHealthFromEndurance()
      end
    end,
    GrantBattleExpConditionally = function(data)
      -- workaround for hit handler not registering magic kills
      local timeNow = os.time()
      local hasUsedDestructiveMagicInLastMinute = timeNow - timeLastDestructiveMagicUse < 60
      if not hasUsedDestructiveMagicInLastMinute then return end
      log('GrantBattleExpConditionally (player used destructive magic in last minute)')
      GrantBattleExp(data)
    end,
    GrantBattleExp = GrantBattleExp,
    FDU_UpdateFollowerList = function(data)
        log('FDU_UpdateFollowerList')
        core.sendGlobalEvent('FDU_UpdateFollowerListFromPlayer', data)
    end,
  }
}

-- TODO:
-- level armor while moving (like MWSE Armor Training)
