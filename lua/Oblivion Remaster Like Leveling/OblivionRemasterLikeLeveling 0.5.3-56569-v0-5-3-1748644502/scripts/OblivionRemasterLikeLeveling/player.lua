local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require("openmw.util")
local self = require('openmw.self')
local v2 = require('openmw.util').vector2
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local core = require('openmw.core')
local async = require('openmw.async')
local types = require("openmw.types")
local messageSource = core.l10n("OblivionRemasterLikeLeveling")

local constants = require('scripts.OblivionRemasterLikeLeveling.constants')
local helper = require('scripts.OblivionRemasterLikeLeveling.helper')


local levelUpSettings = storage.playerSection('levelUpSettings')
local skillsSettings = storage.playerSection('skillSettings')

local attributePoints
local maxUpdatableAttribute

local levelupMenu = {needUpdate = false}

local tooltipPopUp = {needUpdate = false}

local skillPointRollUp = 0

I.SkillProgression.addSkillLevelUpHandler(function(skillId, source, options)

    local skillbase = types.NPC.stats.skills[skillId](self).base
   
    if constants.MAX_SKILL_VALUE > skillbase then
    
      local majorSkillsImpact = skillsSettings:get('majorSkillsImpact')
      local minorSkillsImpact = skillsSettings:get('minorSkillsImpact')
      local miscSkillsImpact = skillsSettings:get('miscSkillsImpact')

      if helper.isMajorSkill(skillId) then
        skillPointRollUp = helper.increaselevelUpProgress(options, majorSkillsImpact, skillPointRollUp)
      elseif helper.isMinorSkill(skillId) then
        skillPointRollUp = helper.increaselevelUpProgress(options, minorSkillsImpact, skillPointRollUp)
      elseif miscSkillsImpact > 0 then
        skillPointRollUp = helper.increaselevelUpProgress(options, miscSkillsImpact, skillPointRollUp)
      end
      
    end

    return true
end)


local function getOffset(attributeName)
  local offset =1

  if constants.LUCK == attributeName and levelUpSettings:get('allowLuckIncrease') then
    offset = levelUpSettings:get('luckIncreaseCost')
  end

  return offset
end

local function getAttributeIncreaseLimit(attributeName)
  local attrIncreaseLimit = constants.ATRIBUTE_INCREASE_LIMIT
  if not levelUpSettings:get('allowLuckIncrease') and constants.LUCK == attributeName then
    attrIncreaseLimit = 1
  end
  return attrIncreaseLimit
end

local function createImageButton(actionFunction, textureProps, size, padding)

  local imageElement = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture(textureProps),
      size = size,
      autoSize = false,
      visible = true,
      color = constants.IDLE_COLOR
    }
  }

  local button = helper.getPaddingContainer(imageElement,padding)

  button.props = {
    visible = true
  }

  button.events = {
    mousePress = async:callback(function(event, this)
      this.changeColor(constants.PRESSED_COLOR)
      helper.update(levelupMenu)
    end),
    mouseRelease = async:callback(function(event, this)
      this.changeColor(constants.IDLE_COLOR)
      actionFunction(event,this)
      ambient.playSound(constants.CLICK_SOUND)
    end)
  }

  function button.changeColor(color)
    imageElement.props.color = color;
  end

  return button
end

local function createTextButton(actionFunction, text, size, padding)
  local textElement = {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
      text = text,
      textColor = constants.IDLE_COLOR,
      size = size,
      autoSize = false,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center
    }
  }

  local button = helper.getBorderedButton(textElement, padding)

  button.props = {
    visible = true
  }

  button.events = {
    mousePress = async:callback(function(event, this)
      this.changeTextColor(constants.PRESSED_COLOR)
      helper.update(levelupMenu)
    end),
    mouseRelease = async:callback(function(event, this)
      this.changeTextColor(constants.IDLE_COLOR)
      actionFunction(event,this)
      ambient.playSound(constants.CLICK_SOUND)
    end),
  }

  function button.changeTextColor(color)
    textElement.props.textColor = color;
  end

  return button
end

local function createTooltip(attribute)

  local attributeIcon = {
    type = ui.TYPE.Image,

    props = {
      resource = attribute.icon,
      autoSize = false,
      size = v2(32,32)
    }
  }

  local attributeName = {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textHeader,
    props = {
      textAlignV = ui.ALIGNMENT.Center,
      autoSize = false,
      text = core.getGMST('sAttribute' .. attribute.id:gsub('^%l', string.upper)),
      size = v2(attribute.tooltipSize.x - 40,32)
    }
  }

  local attributeDescription = {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
      text = core.getGMST(attribute.tooltip),
      wordWrap = true,
      autoSize = false,
      size = attribute.tooltipSize
    }
  }

  local tooltipPadding = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = v2(attribute.tooltipSize.x + 10, attribute.tooltipSize.y + 50),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content ({
      {
        type = ui.TYPE.Flex,
        props = {
          autoSize = false,
          size = v2(attribute.tooltipSize.x, 32),
          horizontal = true,
        },
        content = ui.content {
          attributeIcon,
          helper.addEmptyBox(8,0),
          attributeName
        }
      },
      helper.addEmptyBox(0,8),
      attributeDescription
    })
  }

  return tooltipPadding

end

local function createTooltipPopUp()

  local tooltip = {
    type = ui.TYPE.Container,
    layer = constants.POP_UP_LAYER,
    template = I.MWUI.templates.boxSolid,
    props = {
      visible = false,
      anchor = v2(0.5, 0)
    },
    content = ui.content {}
  }

  function tooltip.show(attribute)
    tooltip.content = ui.content ({createTooltip(attribute)})
    helper.show(tooltip)
    helper.update(tooltipPopUp)
  end

  function tooltip.move(event, data)
    tooltip.props.position = event.position + v2(0, 40)
    helper.update(tooltipPopUp)
  end

  function tooltip.hide()
    tooltip.props.visible = false
    helper.update(tooltipPopUp)
  end

  return tooltip;
end

local function createAttributeRow(attribute, parentWindow)

  local initialValue = helper.getAttributeValue(attribute.id)

  local attributeRow = {
    type = ui.TYPE.Flex,

    newAttributeIncrease = 0,
    attrValue = initialValue,
    attrId = attribute.id,

    props =
    {
      horizontal = true,
      autoSize = false,
      size = util.vector2(300,20),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
    },

    events = {
      focusGain = async:callback(function(event, this)
        this.changeTextColor(constants.HOVER_COLOR)
        parentWindow.tooltip.show(attribute)
        helper.update(levelupMenu)
      end),
      focusLoss = async:callback(function(event, this)
        this.changeTextColor(constants.IDLE_COLOR)
        parentWindow.tooltip.hide()
        helper.update(levelupMenu)
      end),
      mouseMove = async:callback(function(event, this)
        parentWindow.tooltip.move(event, attribute)
      end)
    }
  }

  local attributeNameText = helper.addNormalText(core.getGMST('sAttribute' .. attribute.id:gsub('^%l', string.upper)), {size = v2(80,20), autoSize=false, textAlignV = ui.ALIGNMENT.Center })
  local attributeValueText = helper.addNormalText(tostring(attributeRow.attrValue + attributeRow.newAttributeIncrease), {textAlignH = ui.ALIGNMENT.End, textAlignV = ui.ALIGNMENT.Center, autoSize = false, size = v2(20,20)})
  local attributeIncreaseText = helper.addNormalText(tostring(attributeRow.newAttributeIncrease), {textAlignH = ui.ALIGNMENT.Center, textAlignV = ui.ALIGNMENT.Center, autoSize = false, size = v2(15,20) })

  local increaseAttribute = function (e, this)
    local offset = getOffset(attributeRow.attrId)
    if attributeRow.newAttributeIncrease == 0 then
      attributeRow.incrementUpdatedAttributes(1)
    end
    attributeRow.incrementNewAttributeIncrease(1)
    attributeRow.setValueText(tostring(attributeRow.attrValue + attributeRow.newAttributeIncrease))
    attributeRow.incrementAttributePoints(-offset)
    parentWindow.refreshAttributePoints()
  end

  local decreaseAttribute = function (e, this)
    local offset = getOffset(attributeRow.attrId)
    attributeRow.incrementNewAttributeIncrease(-1)
    attributeRow.setValueText(tostring(attributeRow.attrValue + attributeRow.newAttributeIncrease))
    attributeRow.incrementAttributePoints(offset)
    if attributeRow.newAttributeIncrease == 0 then
      attributeRow.incrementUpdatedAttributes(-1)
    end
    parentWindow.refreshAttributePoints()
  end

  local minusButton = createImageButton(decreaseAttribute, constants.DECREMENT_BUTTON_TEXTURE_PROPERTIES, v2(5, 9), v2(10,11))

  local plusButton = createImageButton(increaseAttribute, constants.INCREMENT_BUTTON_TEXTURE_PROPERTIES, v2(5, 9), v2(10,11))

  attributeRow.content = ui.content({
    attributeNameText,
    helper.addEmptyBox(100,0),
    minusButton,
    helper.addEmptyBox(5,0),
    attributeIncreaseText,
    helper.addEmptyBox(5,0),
    plusButton,
    helper.addEmptyBox(25,0),
    attributeValueText,
  })

  function attributeRow.setValueText(text)
    attributeValueText.props.text = text
  end

  function attributeRow.setIncreaseText(text)
    attributeIncreaseText.props.text = text
  end

  function attributeRow.incrementNewAttributeIncrease(value)
    attributeRow.newAttributeIncrease = attributeRow.newAttributeIncrease + value
    attributeRow.setIncreaseText(tostring(attributeRow.newAttributeIncrease))
  end

  function attributeRow.incrementAttributePoints(value)
    parentWindow.attributePoints = parentWindow.attributePoints + value;
  end

  function attributeRow.incrementUpdatedAttributes(value)
    parentWindow.updatedAttributes = parentWindow.updatedAttributes + value;
  end

  function attributeRow.showPlusButton()
    helper.show(plusButton)
  end

  function attributeRow.hidePlusButton()
    helper.hide(plusButton)
  end

  function attributeRow.showMinusButton()
    helper.show(minusButton)
  end

  function attributeRow.hideMinusButton()
    helper.hide(minusButton)
  end

  function attributeRow.hideAttributeIncreaseBox()
    helper.hide(attributeIncreaseText)
  end

  function attributeRow.showAttributeIncreaseBox()
    helper.show(attributeIncreaseText)
  end

  function attributeRow.changeTextColor(color)
    attributeNameText.props.textColor = color
  end

  return attributeRow
end

local function createAttributesTable(parentWindow)
  local attributeRows = {}

  for i, attr in ipairs(constants.ATRIBUTES) do
    table.insert(attributeRows,createAttributeRow(attr, parentWindow))
  end

  local attributesTable = {
    type = ui.TYPE.Flex,
    attributeRows = attributeRows,
    props = {
      align = ui.ALIGNMENT.Start,
      arrange = ui.ALIGNMENT.Start,
      size = util.vector2(300, 180),
    },
    content = ui.content(attributeRows)
  }

  return attributesTable

end

local function createAttributePointsBox()

  local attributePointsHeader = helper.addHeaders(messageSource("choose_attributes_label",{count=maxUpdatableAttribute}), {autoSize = false, size = v2(280,20), textAlignH = ui.ALIGNMENT.Center})
  local attributePointsValue = helper.addNormalText(tostring(attributePoints), {autoSize = false, size = v2(20,20), textAlignH = ui.ALIGNMENT.End})
  local attributePointsText = helper.addNormalText(messageSource("remaining_points_label"), {textAlignH = ui.ALIGNMENT.Start})

  local virtuesBar = {
    type = ui.TYPE.Container,
    autoSize = false,
    size = v2(280,20),
    content = ui.content{}
  }

  local attributePointBox = {
    coins = {},
    type = ui.TYPE.Flex,

    props = {
      autoSize = false,
      size = v2(300,70),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content({
      attributePointsHeader,
      helper.addEmptyBox(0,5),
      virtuesBar,
      {
        type = ui.TYPE.Flex,

        props = {
          horizontal = true,
          autoSize = false,
          size = v2(280,20),
          align = ui.ALIGNMENT.Center,
          arrange = ui.ALIGNMENT.Start,
        },
        content = ui.content({
          attributePointsValue,
          helper.addEmptyBox(5,0),
          attributePointsText
        })
      }
    })
  }

  function attributePointBox.draw(value)
    attributePointsValue.props.text = tostring(value)

    if not next(attributePointBox.coins) then
      for i=1,value do
        table.insert(attributePointBox.coins,{
          type = ui.TYPE.Image,
          props = {
            resource = ui.texture(constants.GOLD_COIN_TEXTURE_PROPERTIES),
            size = v2(12,12),
            autoSize = false,
            visible = true,
            position = v2((i-1)*8 , 0),
            alpha = 1
          }
        })
      end
    else
      for index, coin in ipairs(attributePointBox.coins) do

        if index <= value then
          coin.props.alpha = 1
        else
          coin.props.alpha = 0
        end
      end
    end

    virtuesBar.content =  ui.content(attributePointBox.coins);
  end

  return attributePointBox
end

local function getLevelUpMessageBox(reachedLevel)

  local height = helper.getLevelUpMessageHeight(reachedLevel)
  return  {
    type = ui.TYPE.Flex,
    props = {
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
      autoSize = false,
      size = v2(300, height)
    },
    content = ui.content({
      helper.addNormalText(helper.getLevelUpMessage(reachedLevel), {wordWrap = true, autoSize = false, size = v2(260, height)}),
    })
  }
end

local function getLevelUpImageBox()

  local imagePath = helper.getLevelUpImagePath()

  local image = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture({path=imagePath}),
      size = v2(256, 128),
      autoSize = false,
      visible = true
    }
  }

  return helper.getBorderedBox(image,v2(4,4))

end

local function getLevelupWindow(tooltip)
  maxUpdatableAttribute = levelUpSettings:get('maxUpdatableAttribute')
  local attributePoinBox = createAttributePointsBox()

  local mainWindow = {
    layer = constants.WINDOWS_LAYER,
    template = I.MWUI.templates.boxTransparentThick,
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(.5, .5),
      anchor = v2(.5, .5),
    },
    tooltip = tooltip,
    attributePoints = attributePoints,
    updatedAttributes = 0,
  }

  local attributesTable = createAttributesTable(mainWindow)

  local validateLevelUp = function ()

    if (mainWindow.attributePoints == 0) then

      for i, v in ipairs(attributesTable.attributeRows) do
        if v.newAttributeIncrease > 0 then
          local attributeName = v.attrId
          helper.setAttributeValue(attributeName, v.newAttributeIncrease + v.attrValue)
        end
      end

      helper.increaseHealth()

      skillPointRollUp = helper.levelUp(skillPointRollUp)
      I.UI.removeMode(constants.LEVEL_UP_MODE)

    else
      ui.showMessage(messageSource("remaining_points_error"))
    end

  end

  local confirmButton = createTextButton(validateLevelUp, core.getGMST('sOK'), v2(41, 17))

  local reachedLevel = helper.getLevel()+1;

  mainWindow.content = ui.content({
    {
      type = ui.TYPE.Flex,
      props = {
        horizontal = false,
        align = ui.ALIGNMENT.Center,
        arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
        helper.addEmptyBox(0,10),
        getLevelUpImageBox(),
        helper.addEmptyBox(0,5),
        helper.addNormalText(core.getGMST('sLevelUpMenu1') .. tostring(reachedLevel)),
        helper.addEmptyBox(0,5),
        getLevelUpMessageBox(reachedLevel),
        helper.addEmptyBox(0,5),
        attributePoinBox,
        helper.addEmptyBox(0,5),
        attributesTable,
        {
          type = ui.TYPE.Flex,
          props = {
            align = ui.ALIGNMENT.End,
            arrange = ui.ALIGNMENT.End,
            size = v2(280, 30),
            autoSize = false
          },
          content = ui.content({confirmButton}),
        },
        helper.addEmptyBox(0,10)
      })
    }
  })

  function mainWindow.refreshAttributePoints()
    attributePoinBox.draw(mainWindow.attributePoints)

    for i, v in ipairs(attributesTable.attributeRows) do

      local attributeIncreaseLimit = getAttributeIncreaseLimit(v.attrId)

      if mainWindow.attributePoints == 0
        or mainWindow.attributePoints - getOffset(v.attrId) < 0
        or v.newAttributeIncrease == attributeIncreaseLimit
        or v.attrValue + v.newAttributeIncrease == constants.MAX_ATTRIBUTE_VALUE
        or (maxUpdatableAttribute <= mainWindow.updatedAttributes and v.newAttributeIncrease == 0) then
        v.hidePlusButton()
        if v.newAttributeIncrease == 0 then
          v.hideAttributeIncreaseBox()
        end
      else
        v.showPlusButton()
        v.showAttributeIncreaseBox()
      end
      if v.newAttributeIncrease == 0 then
        v.hideMinusButton()
      else
        v.showMinusButton()
      end
    end
    helper.update(levelupMenu)
  end

  return mainWindow
end

local function showLevelupMenu()
  if not levelupMenu.uiELement then
    local tooltip = createTooltipPopUp()
    local levelupWindow = getLevelupWindow(tooltip)

    levelupMenu.uiElement = ui.create(levelupWindow)
    levelupMenu.needUpdate = true
    tooltipPopUp.uiElement = ui.create(tooltip)
    tooltipPopUp.needUpdate = true

    levelupWindow.refreshAttributePoints()
  end
end

local function calculateAttributepoints()

  attributePoints = levelUpSettings:get('attributePoints')

  local remainingPointsToSet = 0
  local totalPointsToSet = 0
  local luckPointsToSet = 0
  local luckOffset = 0

  for i, attribute in ipairs(constants.ATRIBUTES) do
    local attributeName = attribute.id

    local attrIncreaseLimit = getAttributeIncreaseLimit(attributeName)
    local offSet = getOffset(attributeName)
    local maxAttrUpdate = constants.MAX_ATTRIBUTE_VALUE - helper.getAttributeValue(attributeName)

    local attrPointsToSet = 0
    if maxAttrUpdate > attrIncreaseLimit then
      attrPointsToSet = attrIncreaseLimit*offSet
    elseif maxAttrUpdate > 0 then
      attrPointsToSet = maxAttrUpdate*offSet
    end

    if constants.LUCK == attributeName then
      luckPointsToSet = attrPointsToSet
      luckOffset = offSet
    end

    remainingPointsToSet = remainingPointsToSet + attrPointsToSet
  end

  if remainingPointsToSet < attributePoints then
    attributePoints = remainingPointsToSet
  else
    local otherAttrPointsToSet = remainingPointsToSet - luckPointsToSet
    if attributePoints > otherAttrPointsToSet  then
      attributePoints = otherAttrPointsToSet + math.floor((attributePoints - otherAttrPointsToSet)/luckOffset) * luckOffset
    end
  end
end

local closeLevelupMenu = function ()
  if (levelupMenu.uiElement) then
    levelupMenu.uiElement:destroy()
  end
  if tooltipPopUp.uiElement then
    tooltipPopUp.uiElement:destroy()
  end
end

local function registerLevelUpMenu()
  I.UI.registerWindow(
    constants.LEVEL_UP_DIALOG,
    function ()
      calculateAttributepoints()
      ambient.streamMusic(constants.LEVEL_UP_MUSIC)
      showLevelupMenu()
    end,
    function ()
      closeLevelupMenu()
    end
  )
end

return {
  engineHandlers = {
    onActive = function ()
      registerLevelUpMenu()
    end,
    onLoad = function(data)
      if data then
        skillPointRollUp = helper.checkValue(data.skillPointRollUp, 0)
      end
    end,
    onSave = function()
      return {
        skillPointRollUp = skillPointRollUp,
      }
    end,
  }
}
