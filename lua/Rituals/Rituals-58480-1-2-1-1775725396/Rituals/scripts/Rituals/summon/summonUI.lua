local ui = require('openmw.ui')
local async = require('openmw.async')
local types = require('openmw.types')
local util = require('openmw.util')
local self = require('openmw.self')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')

local v2 = util.vector2
local screenSize = ui.screenSize()
local boxSize = v2(screenSize.x*0.12,screenSize.y*0.3)
local buttonSize = v2(boxSize.x,boxSize.y/8)

local dialogCreature = nil
local summonUi = nil
local stayIndicator = nil
local pointing = false
local equip = nil

local restTime = nil

local stayText = {
  template = I.MWUI.templates.textNormal,
  layer = 'Modal',
  props = {
    text = "Go over there!",
    relativePosition = v2(0.5,0.5),
    anchor = v2(0,-0.5),
  },
}

local follow_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize - v2(10,10),
        text = "Follow",
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}
local stay_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize - v2(10,10),
        text = "Stay",
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}

local staythere_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize - v2(10,10),
        text = "Go over there",
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}

local drink_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize - v2(10,10),
        text = "Drink potion",
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}

local wield_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize - v2(10,10),
        text = "Wield weapon",
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}

local inv_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize - v2(10,10),
        text = "Inventory",
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}

local stats_button = {
  template = I.MWUI.templates.boxSolidThick,
  content = ui.content{
    {
      template = I.MWUI.templates.textNormal,
      props = {
        autoSize = false,
        size = buttonSize:emul(v2(1,2)) - v2(10,0),
        text = "Stats",
        wordWrap = true,
        multiline = true,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
    },
  },
}

local function sendAIPackage(type)
  if dialogCreature ~= nil then
    dialogCreature:sendEvent('StartAIPackage',{type=type,target=self})
  end
end

local function changeMode(mode)
  if dialogCreature == nil then return end
  dialogCreature:sendEvent('R_SummonChangeMode',{mode=mode})
end

follow_button.events = {
  mouseClick = async:callback(
  function()
    --print("Follow")
    sendAIPackage("Follow")
    changeMode("follow")
    I.UI.removeMode(I.UI.MODE.Interface)
    summonUi:destroy()
    dialogCreature = nil
  end)
}

stay_button.events = {
  mouseClick = async:callback(
  function()
    --print("Stay")
    changeMode("stay")
    dialogCreature:sendEvent('RemoveAIPackages', 'Follow')
    I.UI.removeMode(I.UI.MODE.Interface)
    summonUi:destroy()
    dialogCreature = nil
  end)
}

staythere_button.events = {
  mouseClick = async:callback(
  function()
    --print("Stay here")
    I.UI.removeMode(I.UI.MODE.Interface)
    summonUi:destroy()
    stayIndicator = ui.create(stayText)
    pointing = true
  end)
}

inv_button.events = {
  mouseClick = async:callback(
  function()
    I.UI.removeMode(I.UI.MODE.Interface)
    summonUi:destroy()
    self:sendEvent('AddUiMode', {mode = 'Container', target = dialogCreature})
    dialogCreature = nil
  end)
}

drink_button.events = {
  mouseClick = async:callback(
  function()
    I.UI.removeMode(I.UI.MODE.Interface)
    dialogCreature:sendEvent('R_DrinkPotion_Start')
    summonUi:destroy()
    equip = 'potion'
    self:sendEvent('AddUiMode', {mode = 'Container', target = dialogCreature})
  end)
}

wield_button.events = {
  mouseClick = async:callback(
  function()
    local canUse = types.Creature.record(dialogCreature.recordId).canUseWeapons
    I.UI.removeMode(I.UI.MODE.Interface)
    if canUse then
      dialogCreature:sendEvent('R_Wield_Start')
      equip = 'weapon'
      self:sendEvent('AddUiMode', {mode = 'Container', target = dialogCreature})
    else
      ui.showMessage('This creature can not wield weapons.')
    end
    summonUi:destroy()
  end)
}

local cont = {
  type = ui.TYPE.Widget,
  layer = 'Modal',
  name = 'root',
  props = {
    relativePosition = v2(0.5,0.5),
    size = boxSize,
    anchor = v2(0.5,0.5),
  },
  content = ui.content{
    {
      template = I.MWUI.templates.boxSolidThick,
      content = ui.content{
        {
          type = ui.TYPE.Flex,
          props = {
            size = boxSize - v2(10,10),
            autoSize = false,
          },
          content = ui.content{stats_button,follow_button,stay_button,staythere_button,inv_button,drink_button,wield_button}
        },
      },
    },
  },
}

local function getStats(actor)
  local hBase = types.Actor.stats.dynamic.health(actor).base
  local mBase = types.Actor.stats.dynamic.magicka(actor).base
  local fBase = types.Actor.stats.dynamic.fatigue(actor).base
  local eMax = types.Actor.getCapacity(actor)
  
  local health = types.Actor.stats.dynamic.health(actor).current
  local magicka = types.Actor.stats.dynamic.magicka(actor).current
  local fatigue = types.Actor.stats.dynamic.fatigue(actor).current
  local enc = types.Actor.getEncumbrance(actor)
  
  local strings = {
    health = "Health: "..string.format("%.0f", health).."/"..string.format("%.0f", hBase),
    magicka = "Magicka: "..string.format("%.0f", magicka).."/"..string.format("%.0f", mBase),
    fatigue = "Fatigue: "..string.format("%.0f", fatigue).."/"..string.format("%.0f", fBase),
    enc = "Encumbrance: "..string.format("%.0f", enc).."/"..string.format("%.0f", eMax)
  }
  
  return strings
end

local function openDialog(data)
  --print("Opening dialog for: ",data.actor)
  dialogCreature = data.actor
  
  local stats = getStats(data.actor)
  
  stats_button.content[1].props.text = stats.health..'\n'..stats.magicka..'\n'..stats.fatigue..'\n'..stats.enc
  
  I.UI.addMode(I.UI.MODE.Interface,{windows={}})
  summonUi = ui.create(cont)
end

local function onUiChanged(data)
  --print(tostring(data.oldMode).." -> "..tostring(data.newMode))
  if data.oldMode == 'Rest' and data.newMode == 'Rest' then
    restTime = core.getGameTime()
    --print("Start rest:",restTime)
  elseif data.oldMode == 'Rest' and data.newMode == nil then
    if not restTime then return end
    local newTime = core.getGameTime()
    local dif = newTime - restTime
    --print("Passed seconds while resting:",dif)
    core.sendGlobalEvent('R_ApplySummonRest',{duration=dif})
  end
  
  if equip and dialogCreature and data.oldMode == 'Container' then
    if equip == 'potion' then
      dialogCreature:sendEvent('R_DrinkPotion_End')
      equip = nil
    else
      dialogCreature:sendEvent('R_Wield_End')
      equip = nil
    end
    dialogCreature = nil
  end
  
  if summonUi ~= nil and data.oldMode == 'Interface' then
    summonUi:destroy()
  end
end

local function castRay()
  local startPos = camera.getPosition()
  local lookVec = camera.viewportToWorldVector(util.vector2(0.5,0.5)):normalize()
--  startPos = startPos - lookVec * 30
  local endPos = startPos + lookVec * 5000
  local result = nearby.castRay(startPos,endPos)
  --print(result.hit)
  if result.hit then
    dialogCreature:sendEvent('StartAIPackage',{type='Travel',destPosition = result.hitPos})
    changeMode("stay")
  end
  dialogCreature = nil
end

input.registerTriggerHandler('Activate',async:callback(
  function(e)
    if pointing then
      --print("Pointed at pointing pointer")
      castRay()
      pointing = false
      if stayIndicator then stayIndicator:destroy() end
    end
    return true
  end
))

return {
  eventHandlers = {
    UiModeChanged = onUiChanged,
    R_Summon_GUI_Open = openDialog,
  },
}