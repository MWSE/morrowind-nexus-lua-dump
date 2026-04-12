local types = require('openmw.types')
local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local calendar = require('openmw_aux.calendar')

local ritualStorage = storage.playerSection('RitualsMod')
local customEffects = ritualStorage:getCopy('CustomEffects')

local spellPrepared = false

ritualStorage:subscribe(
  async:callback(function(section,key)
    if key == 'CustomEffects' then
      customEffects = ritualStorage:getCopy(key)
      if customEffects['r_prepare_spell'] ~= nil then
        if customEffects['r_prepare_spell'].enabled then
          spellPrepared = true
        else
          spellPrepared = false
        end
      end
    end
  end))

local function castChance(spell)
  local lowestSkill = nil
  local lowestSkillName = nil
  local y = nil
  for id,effect in ipairs(spell.effects) do
    local x = effect.duration
    x = math.max(1,x)
    x = x*0.1*effect.effect.baseCost
    x = x*0.5*(effect.magnitudeMin+effect.magnitudeMax)
    x = x+effect.area*0.05*effect.effect.baseCost
    if effect.range == core.magic.RANGE.Target then
      x = x*1.5
    end
    x = x*core.getGMST('fEffectCostMult')
    
    local currentSchool = effect.effect.school
    local s = 2*types.NPC.stats.skills[effect.effect.school](self).modified
    if y == nil or s-x < y then
      y = s - x
      lowestSkill = s
      lowestSkillName = currentSchool
    end
  end
  local willpower = types.NPC.stats.attributes.willpower(self).modified
  local luck = types.NPC.stats.attributes.luck(self).modified
  local fatigueCurrent = types.Actor.stats.dynamic.fatigue(self).current
  local fatigueBase = types.Actor.stats.dynamic.fatigue(self).base
  
  local fatigueMult = 0.75 + 0.5 * (fatigueCurrent / fatigueBase)
  local baseNeeded = 100 / fatigueMult
  local skillNeeded = spell.cost - 0.2 * willpower - 0.1 * luck + baseNeeded
  skillNeeded = skillNeeded / 2  
  skillNeeded = math.ceil(skillNeeded)
  
  return skillNeeded,lowestSkillName
end

I.SkillProgression.addSkillUsedHandler(
  function(skillId,params)
    local enabled = false
    local customEffect = customEffects['r_skill_gain']
    if customEffect ~= nil then
      enabled = customEffect.enabled
    end
    if enabled then
      local skillGain = params.skillGain
      skillGain = skillGain + skillGain*0.2
      params.skillGain = skillGain
    end
    return true
  end
)

local buff = nil
local school = nil

local mana_replenished = false

input.registerActionHandler('Use',async:callback(
function(a)
  if spellPrepared and a then
    if types.Actor.getStance(self) == types.Actor.STANCE.Spell and I.UI.getMode() == nil then
      local t = customEffects['r_prepare_spell']
      if types.Actor.getSelectedSpell(self).id ~= t.spell then return end
      print(mana_replenished)
      if mana_replenished then return end
      local mana = types.Actor.stats.dynamic.magicka(self).current
      mana = mana + t.cost
      types.Actor.stats.dynamic.magicka(self).current = mana
      mana_replenished = true
    end
  end
end))

I.AnimationController.addTextKeyHandler('spellcast',
function(groupname,key)
  if not spellPrepared then return end
--  print(key)
  local start = {
    ["self start"] = true,
    ["touch start"] = true,
    ["target start"] = true
  }
  if start[key] then
    local enabled = false
    local customEffect = customEffects['r_prepare_spell']
    if customEffect ~= nil then
      enabled = customEffect.enabled
    end
    if enabled then
      -- do the thing
      local id = customEffect.spell
      local spell = types.Actor.getSelectedSpell(self)
      if spell.id == id then
        local s,n = castChance(spell)
        local schoolVal = types.NPC.stats.skills[n](self).modified
        local diff = s-schoolVal
        if diff > 0 then
          --add skill temporarliy
          local modifier = types.NPC.stats.skills[n](self).modifier
          modifier = modifier + diff
          types.NPC.stats.skills[n](self).modifier = modifier
          buff = diff
          school = n
        else
          buff = 0
        end
      end
    end
  elseif key:sub(-7) == "release" then
    if buff then
      if buff ~= 0 then
        local modifier = types.NPC.stats.skills[school](self).modifier
        modifier = modifier - buff
        types.NPC.stats.skills[school](self).modifier = modifier
        buff = nil
        school = nil
      end
      
      mana_replenished = false
      local day = calendar.formatGameTime("%w", calendar.gameTime())
      customEffects['r_prepare_spell'] = {day=day}
      ritualStorage:set('CustomEffects',customEffects)
    end
  end
end)