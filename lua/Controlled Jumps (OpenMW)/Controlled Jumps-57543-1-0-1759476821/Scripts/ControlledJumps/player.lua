local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local types = require('openmw.types')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local controls = require('openmw.interfaces').Controls
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')

local playerSettings = storage.playerSection('SettingsPlayerControlledJumps')
local msg = core.l10n('ControlledJumps', 'en')

local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic
local NPCRecord = types.NPC.record(self)

local acrobaticsModifier = 0 
local acrobaticsDamage = 0 

local jumping = false
local count = 0
local startPos = nil

local hasBonus = false
local maxCount = 100


local element = nil
local v2 = util.vector2
local layout = {
    layer = 'Windows',
    template = I.MWUI.templates.boxSolid,
    props = {                
        position = v2(0, 0),
        relativePosition = v2(.50, .80),
        anchor = v2(0, 1),
    },    
    content = ui.content {{
        template = I.MWUI.templates.padding,
        content = ui.content {{
            layer = 'Windows',
            type = ui.TYPE.Text,
            name = "text",
            template = I.MWUI.templates.textNormal,
            props = {
                text = ""
            }
        }}
    }}
}

local function createTimerWindow()
    if element == nil then
        element = ui.create(layout)
    end
end
local function destroyTimerWindow()
    if element ~= nil then
        element:destroy()   
        element = nil
    end    
end

local function cjCount(data)
  count = data.count
  if count > maxCount then count = maxCount end

  if count == 60  then
    local finishPos = self.position  
    if finishPos == startPos then
      hasBonus = true
    end
  end
  createTimerWindow()
  element.layout.content[1].content[1].props.text = ""..count.."%"
  element:update()
end

local function cjJump(count)
    acrobaticsModifier = skills.acrobatics(self).modifier 
    acrobaticsDamage = skills.acrobatics(self).damage 
    
    local fatiguePercent =  (dynamic.fatigue(self).current/dynamic.fatigue(self).base)*100
    if playerSettings:get('cjBonus') and hasBonus and count == 100 and fatiguePercent >= 80 then
      local bonus = playerSettings:get('cjBoost')
      skills.acrobatics(self).modifier = bonus
      if playerSettings:get('cjBonusSound') then
        local isMale = NPCRecord.isMale
        if isMale then
            ambient.playSoundFile('Sound\\ControlledJumps\\MaleChargedJump.wav')
        else
            ambient.playSoundFile('Sound\\ControlledJumps\\FemaleChargedJump.wav')
        end
      end
    else
      hasBonus = false
      skills.acrobatics(self).modifier = -skills.acrobatics(self).modified*(1-count/100)
    end
    jumping = true
end

local function onKeyPress(key)
  if not playerSettings:get('cjEnable') then return end

  if key.code == playerSettings:get('cjKey')  then
    if types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then 
      startPos = self.position
      hasBonus = false
      --controls.overrideMovementControls(true)
      core.sendGlobalEvent("cjStart",{})
    end
  end
end

local function onKeyRelease(key)
  if not playerSettings:get('cjEnable') then return end
  

  if key.code == playerSettings:get('cjKey') then
    core.sendGlobalEvent("cjDone",{})
    if types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then 
      controls.overrideMovementControls(true)
      cjJump(count)
      self.controls.jump = true
    end
  end
end

local onAir = false
local function onUpdate()

  if jumping and not (types.Actor.isOnGround(self) or types.Actor.isSwimming(self)) then
    onAir = true
  end

  if jumping then
    destroyTimerWindow()
    controls.overrideMovementControls(false) 
    skills.acrobatics(self).modifier = acrobaticsModifier
    skills.acrobatics(self).damage = acrobaticsDamage
  end

  if onAir and (types.Actor.isOnGround(self) or types.Actor.isSwimming(self)) then 
        if hasBonus then
          if playerSettings:get('cjBonusSound') then
            local isMale = NPCRecord.isMale
            if isMale then
                ambient.playSoundFile('Sound\\ControlledJumps\\MaleChargedLanding.wav')
            else
                ambient.playSoundFile('Sound\\ControlledJumps\\FemaleChargedLanding.wav')
            end
          end
        end
        hasBonus = false
        jumping = false
        onAir = false
      end
end

local function onInputAction(id)
  --print("onInputAction "..id) x§
  if id == input.ACTION.Jump then  
    if playerSettings:get('cjEnableShort') then
      local key = playerSettings:get('cjKeyShort')
      local trigger = (key == "Shift" and input.isShiftPressed() or key == "Ctrl" and input.isCtrlPressed() or key == "Alt" and input.isAltPressed())
      if trigger then
        local percent = playerSettings:get('cjPercent')
        cjJump(percent)
      end
    end
    -- jumping = true
    --print("on jump acrobatics modified "..skills.acrobatics(self).modified)
  end
end

return {
  engineHandlers = {
    onKeyPress = onKeyPress,
    onKeyRelease = onKeyRelease,
    onUpdate =  onUpdate,
    onInputAction = onInputAction,  
  },
    eventHandlers = {
        cjCount = cjCount,
        cjJump = cjJump,
        destroyTimerWindow = destroyTimerWindow,
    }

}
