local core = require('openmw.core')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local types = require("openmw.types")
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local v2 = require('openmw.util').vector2

local constants = require('scripts.OblivionRemasterLikeLeveling.constants')
local templates = require('scripts.OblivionRemasterLikeLeveling.templates')

local helper = {}

function helper.contains(array, value)
  for _, otherValue in ipairs(array) do
    if otherValue == value then
      return true
    end
  end
  return false
end

function helper.isMajorSkill(skillId)
  return  helper.contains(types.NPC.classes.record(types.NPC.record(self).class).majorSkills, skillId)
end

function helper.isMinorSkill(skillId)
  return  helper.contains(types.NPC.classes.record(types.NPC.record(self).class).minorSkills, skillId)
end

function helper.isMiscSkill(skillId)
  if next(helper.miscSkills) == nil then
    for i, v in ipairs(constants.SKILLS) do
      if not helper.contains(types.NPC.classes.record(types.NPC.record(self).class).minorSkills,v) and not helper.contains(types.NPC.classes.record(types.NPC.record(self).class).majorSkills,v) then
        table.insert(helper.miscSkills,v)
      end
    end
  end

  return helper.contains(helper.miscSkills, skillId)
end

function helper.addHeaders(text,extraProps)
  return helper.addTextBox(text, extraProps, I.MWUI.templates.textHeader)
end

function helper.addNormalText(text, extraProps)
  return helper.addTextBox(text, extraProps, I.MWUI.templates.textNormal)
end

function helper.addTextBox(str, extraProps, template)
  local props = { text = str,}
  if extraProps then
    for k, v in pairs(extraProps) do
      props[k] = v
    end
  end
  return {
    type = ui.TYPE.Text,
    template = template,
    props = props,
  }
end

function helper.addEmptyBox(horizontal, vertical)
  return { props = { size = v2(horizontal, vertical) } }
end

function helper.getBorderedButton(content, padding)
  return helper.addToTemplate(content, padding, templates.borderedButton)
end

function helper.getBorderedBox(content, padding)
  return helper.addToTemplate(content, padding, I.MWUI.templates.boxSolid)
end

function helper.getPaddingContainer(content, padding)

  local layout =  {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content({content})
  }

  if padding then
    layout.props.size = content.props.size + padding
  else
    layout.props.size = content.props.size
  end

  return layout

end

function helper.addToTemplate(content, padding, template)

  return  {
    type = ui.TYPE.Container,
    template = template,

    content = ui.content({
      helper.getPaddingContainer(content, padding)
    }),
  }
end

function helper.getAttributeValue(attributeName)
  return types.Actor.stats.attributes[attributeName](self).base
end

function helper.setAttributeValue(attributeName, newValue)
  types.Actor.stats.attributes[attributeName](self).base = newValue
end

function helper.getLevel()
  return types.Actor.stats.level(self).current
end

function helper.increaselevelUpProgress(options, value, rollUpSkillPoints)

  local iLevelUpTotal = core.getGMST('iLevelupTotal')

  local newProgress = types.Actor.stats.level(self).progress + value

  local currentRollUp = 0

  if newProgress >  iLevelUpTotal then
    currentRollUp = newProgress - iLevelUpTotal
    options.levelUpProgress  = value - currentRollUp
  else
    options.levelUpProgress  = value
  end

  options.levelUpAttribute = nil

  return rollUpSkillPoints + currentRollUp
end

function helper.levelUp(rollUpSkillPoints)
  types.Actor.stats.level(self).current = types.Actor.stats.level(self).current + 1
  if rollUpSkillPoints >= 100 then
    types.Actor.stats.level(self).progress = 100
    return rollUpSkillPoints - 100
  else
    types.Actor.stats.level(self).progress = rollUpSkillPoints
    return 0
  end
end

function helper.show(uiElement)
  uiElement.props.visible = true
end

function helper.hide(uiElement)
  uiElement.props.visible = false
end

function helper.getLevelUpMessage(level)
  if level > 20 then
    return  core.getGMST('Level_Up_Default')
  else
    return core.getGMST('Level_Up_Level' .. level)
  end
end

function helper.getLevelUpMessageHeight(level)
  if level > 20 then
    return  80
  else
    return constants.LEVEL_UP_MESSAGE_HEIGHT[level]
  end
end

-- Adapts the odd original algorithm (see https://gitlab.com/OpenMW/openmw/-/blob/master/apps/openmw/mwgui/levelupdialog.cpp#L265)
-- May behave strangely with the implemented level up mechanics
function helper.getLevelUpImagePath()

  local class = "acrobat"

  local increasedCombatSkills = types.Actor.stats.level(self).skillIncreasesForSpecialization.combat
  local increasedMagicSkills = types.Actor.stats.level(self).skillIncreasesForSpecialization.magic
  local increasedStealthSkills = types.Actor.stats.level(self).skillIncreasesForSpecialization.stealth

  local totalIncreasedSkills = increasedCombatSkills + increasedMagicSkills + increasedStealthSkills

  if totalIncreasedSkills > 0 then

    local combatFraction = math.floor((increasedCombatSkills / totalIncreasedSkills) * 10)
    local magicFraction = math.floor((increasedMagicSkills / totalIncreasedSkills) * 10)
    local stealthFraction = math.floor((increasedStealthSkills / totalIncreasedSkills) * 10)

    if combatFraction > 6 then
      class = "warrior"
    elseif magicFraction > 6 then
      class = "mage"
    elseif stealthFraction > 6 then
      class = "thief"
    end

    if combatFraction == 6 then
      if stealthFraction == 1 then
        class = "barbarian"
      elseif stealthFraction == 3 then
        class = "crusader"
      else
        class = "knight"
      end
    elseif combatFraction == 5 then
      if stealthFraction == 3 then
        class = "scout"
      else
        class = "archer"
      end
    elseif combatFraction == 4 then
      class = "rogue"
    end

    if magicFraction == 6 then
      if combatFraction == 2 then
        class = "sorcerer"
      elseif increasedCombatSkills == 3 then
        class = "healer"
      else
        class = "battlemage"
      end
    elseif magicFraction ==  5 then
      class = "witchhunter"
    elseif magicFraction == 4 then
      class = "spellsword"
    end


    if stealthFraction == 6 then
      if magicFraction == 1 then
        class = "agent";
      elseif increasedMagicSkills == 3 then
        class = "assassin"
      else
        class = "acrobat"
      end
    elseif stealthFraction == 5 then
      if increasedMagicSkills == 3 then
        class = "monk"
      else
        class = "pilgrim"
      end
    elseif stealthFraction == 3 then
      if magicFraction == 3 then
        class = "bard"
      end
    end
  end

  return "textures/levelup/" .. class .. ".dds"
end

function helper.checkValue(data, default)
  if data == nil then
    return default
  else
    return data
  end
end

function helper.increaseHealth()
  local multiplier = core.getGMST('fLevelUpHealthEndMult')
  local enduranceValue = types.Actor.stats.attributes[constants.ENDURANCE](self).base
  
  local healthIncrease = enduranceValue*multiplier
  types.Player.stats.dynamic.health(self).base = types.Player.stats.dynamic.health(self).base + healthIncrease
  
  types.Player.stats.dynamic.health(self).current = math.min(math.max( types.Player.stats.dynamic.health(self).current + healthIncrease, 1), types.Player.stats.dynamic.health(self).base)
  
end

-- Try to synchronize update instructions to avoid "Error in Delayed Action Update UI: Lua error: Delayed Action is not allowed to create another DelayedAction" errors
function helper.update(component)
  if(component.needUpdate) then
    component.needUpdate = false
    component.uiElement:update()
    component.needUpdate = true
  end
end

return helper
