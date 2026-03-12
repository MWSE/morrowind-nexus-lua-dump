
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local self = require('openmw.self')
local util = require('openmw.util')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local storage = require('openmw.storage')
local camera = require('openmw.camera')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local vfs = require('openmw.vfs')
local controls = require('openmw.interfaces').Controls
local async = require("openmw.async")
local anim = require('openmw.animation')

local slowUpdateTimer = 0
local showTextPromptInst = nil
local showTextPromptTimer = 0

local playerIsFlying = false
local skyshipSpeed = 0
local playerIsPlacingItem = false

local soundTime = 0
local updateSoundTimer = 0
local creakWaitTimer = 0
local windVolume = 0

-- INPUTS
local input_moveFwd = false
local input_moveBack = false
local input_moveL = false
local input_moveR = false
local input_jump = false
local input_run = false
local input_activate = false
local input_use = false
local inputkey_pickup_furniture = 'P'


I.Settings.registerPage {
     key = "BensmodzSkyships",
     l10n = "Skyships",
     name = "Skyships",
     description = "Skyships settings",
}
I.Settings.registerGroup {
    key = 'BensmodzSkyshipsGroup',
    page = 'BensmodzSkyships',
    l10n = 'Skyships',
    name = 'Main Settings',
    permanentStorage = true,
    settings = {
        {
          key = "showFlyControlsPrompt",
          renderer = "checkbox",
          name = "Show Fly Controls Prompt When Flying",
          default = true,
          argument = {
               disabled = false,
          },
        },
        {
          key = "lowFpsMode",
          renderer = "checkbox",
          name = "Performance Mode (Low Fps Mode)",
          default = false,
          argument = {
               disabled = false,
          },
        },
    },
}

local function ss_showMessage(data)
  ui.showMessage(tostring(data.message))
end


local function ss_showTextPrompt(data) 

  if showTextPromptInst ~= nil then
    showTextPromptInst:destroy()
    showTextPromptInst = nil
  end
  
  showTextPromptTimer = data.timer
  
  local text = ui.create {
       template = I.MWUI.templates.textNormal,
       layer = 'Windows',
       type = ui.TYPE.Text,
       props = {
          text = data.text,
          multiline = true,
          textAlignH = ui.ALIGNMENT.Center,
       },
  }
  
  local padding = ui.create {
      type = ui.TYPE.Container,
      template = I.MWUI.templates.padding,
      layer = 'Windows',
      content = ui.content({text}),
      props = {
          relativeSize = util.vector2(2, 2),
       },
  }
  
  local textBox = ui.create {
      type = ui.TYPE.Container,
      template = I.MWUI.templates.boxSolidThick,
      layer = 'Windows',
      props = {
          relativePosition = util.vector2(.05, .9),
          anchor = util.vector2(0, 1),
      },
      content = ui.content({padding}),
  }
  
  showTextPromptInst = textBox
  --delayUpdateTimer = 10

end

local function loadUserSettings() 
  core.sendGlobalEvent("Ss_updateUserSettings", { 
    showFlyControlsPrompt = storage.playerSection('BensmodzSkyshipsGroup'):get("showFlyControlsPrompt"),
    lowFpsMode = storage.playerSection('BensmodzSkyshipsGroup'):get("lowFpsMode"),
  })
end

local function onUpdate(dt)  

  if ((self.cell.isExterior and skyshipSpeed > 0) or windVolume > 0) then
    if skyshipSpeed > 0 then windVolume = skyshipSpeed / 8 
    else windVolume = windVolume - dt / 3 end
    soundTime = soundTime + dt
    updateSoundTimer = updateSoundTimer - dt
    if updateSoundTimer <= 0 then
      updateSoundTimer = .5
      ambient.stopSound("BM Wind")
      ambient.playSound("BM Wind", { volume = windVolume, timeOffset = soundTime})
    end
    if not ambient.isSoundPlaying('BM Wind') then 
      soundTime = 0 
      ambient.playSound("BM Wind", { volume = windVolume, timeOffset = soundTime})  
    end
    creakWaitTimer = creakWaitTimer - dt
    if creakWaitTimer <= 0 then
      if not ambient.isSoundPlaying('Boat Creak') then ambient.playSound("Boat Creak", { volume = skyshipSpeed / 30}) end
      creakWaitTimer = math.random(5,18)
    end
  end

  core.sendGlobalEvent('Ss_SetPlayerInputs', { 
    camForward = camera.viewportToWorldVector(util.vector2(.5,.5)), 
    --moveFwd = input.isActionPressed(input.ACTION.MoveForward), 
    --moveBack = input.isActionPressed(input.ACTION.MoveBackward),
    --moveL = input.isActionPressed(input.ACTION.MoveLeft),
    --moveR = input.isActionPressed(input.ACTION.MoveRight),
    jump = input.isActionPressed(input.ACTION.Jump),
    --crouch = input.isActionPressed(input.ACTION.Sneak),
    moveFwd = input_moveFwd, 
    moveBack = input_moveBack,
    moveL = input_moveL,
    moveR = input_moveR,
    --jump = input_jump,
    run = input_run,
    activate = input.isActionPressed(input.ACTION.Activate),
    use = input.isActionPressed(input.ACTION.Use),
  })
  --input_jump = false
  
  if showTextPromptTimer > 0 then
    if not playerIsFlying and not playerIsPlacingItem then showTextPromptTimer = 0 end
    showTextPromptTimer = showTextPromptTimer - dt
    if (showTextPromptTimer <= 0) then
      showTextPromptInst:destroy()
      showTextPromptInst = nil
    end
  end
  
  if (I.UI.getMode() == I.UI.MODE.MainMenu) then
      loadUserSettings()
  end

  --ui.showMessage(tostring(self.position))
  --self.position = self.position + util.vector3(0,1,0)
  --self.teleport(self,"",self.position + util.vector3(0,1,0))
end

local function getPlayerGoldAmount() 
  local gold = types.Actor.inventory(self):find('gold_001')
  if gold then return gold.count end
  return 0
end

local function ss_raycastToFindSurface(data)
  local results = nearby.castRay(data.from,data.to,{ignore=self})
  if results.hit then
    core.sendGlobalEvent('Ss_SetRaycastFoundSurface', { hitPos = results.hitPos } )
  end
end

local function raycastCameraForward(data) 
  local results = nearby.castRay(camera.getPosition() + camera.viewportToWorldVector(util.vector2(.5,.5)) * 50 ,camera.getPosition() + camera.viewportToWorldVector(util.vector2(.5,.5)) * 5000,{ignore=data.ignoreList})
  if results.hit then
    core.sendGlobalEvent('Ss_SetRaycastFoundSurface', { hitPos = results.hitPos } )
  end
end

local function playerPlayAnimation(data) 
  if (data.animationName == nil) then anim.clearAnimationQueue(self, true)
  else anim.playQueued(self, data.animationName) end
end

local function closeInventory() 
  I.UI.setMode()
end

local function setSkyshipInfo(data) 
  playerIsPlacingItem = data.playerIsPlacingItem
  playerIsFlying = data.playerIsFlying
  skyshipSpeed = data.skyshipSpeed
end

local function pickUpFurniture()
  local results = nearby.castRenderingRay(camera.getPosition() + camera.viewportToWorldVector(util.vector2(.5,.5)) * 50 ,camera.getPosition() + camera.viewportToWorldVector(util.vector2(.5,.5)) * 300,{ignore=self})
  if results.hit then
    if results.hitObject.type == types.Activator then
      local objName = types.Activator.record(results.hitObject).name
      if (string.find(objName,"Skyship Furniture - ") ~= nil or string.find(objName,"Skyship Upgrade - ") ~= nil) then
        core.sendGlobalEvent("Ss_PickUpFurniture",{object = results.hitObject})
        ambient.playSound("Item Misc Up")
      end
    end
  end
end

local function ss_playSound(data)
  ambient.playSound(data.sound, { volume = data.volume, pitch = data.pitch })  
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = function()
          self.type.addTopic(self, "Skyships")
          loadUserSettings()
          input.registerActionHandler("MoveForward", async:callback(function(value) input_moveFwd = value end))
          input.registerActionHandler("MoveBackward", async:callback(function(value) input_moveBack = value end))
          input.registerActionHandler("MoveLeft", async:callback(function(value) input_moveL = value end))
          input.registerActionHandler("MoveRight", async:callback(function(value) input_moveR = value end))
          input.registerTriggerHandler('Jump', async:callback(function() input_jump = true end))
          input.registerActionHandler("Run", async:callback(function(value) input_run = value end))
          input.registerTriggerHandler("Activate", async:callback(function(value) input_activate = true end))
          --input.registerTriggerHandler("Use", async:callback(function() input_use = true end))
        end,
        onKeyPress = function(key)
            if key.symbol == 'x' then
               --raycastCameraForward()
            end
            if key.symbol == 'z' then
                print(tostring(self.position))
            end
            if key.symbol == string.lower(inputkey_pickup_furniture) then
                pickUpFurniture()
            end
            if key.symbol == 'b' then
              core.sendGlobalEvent('Ss_PrintPlayerBoatDifferenceVector', {} )
            end
        end
    },
    eventHandlers = { 
      UiModeChanged = function(data)
          if (data.oldMode == "Barter" or data.oldMode == "Dialogue") then 
            local inv = types.Actor.inventory(self)
            local items = inv:getAll(types.Book)
            for k,v in pairs(items) do
              local record = types.Book.record(v)
              if record.name == "Skyship Deed" then
                core.sendGlobalEvent('Ss_BuySkyship', {} )
              end
            end
          end
      end,
      Ss_showMessage = ss_showMessage,
      Ss_RaycastToFindSurface = ss_raycastToFindSurface,
      Ss_PlayerPlayAnimation = playerPlayAnimation,
      Ss_RaycastCameraForward = raycastCameraForward,
      Ss_CloseInventory = closeInventory,
      Ss_SetSkyshipInfo = setSkyshipInfo,
      Ss_playSound = ss_playSound,
      Ss_showTextPrompt = ss_showTextPrompt,
    }
}
