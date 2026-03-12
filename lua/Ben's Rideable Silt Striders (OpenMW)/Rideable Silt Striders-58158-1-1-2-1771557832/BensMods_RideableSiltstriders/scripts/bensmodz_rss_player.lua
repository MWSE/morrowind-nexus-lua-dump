
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
local anim = require('openmw.animation')

local travelActorsList = nil
local activeTravelData = nil
local slowUpdateTimer = 0
local showingCustomTravelMenu = false
local playerIsTraveling = false;
local controlsPrompt = nil
local showFreeRidePromptTimer = 0

local soundTime = 0
local updateSoundTimer = 0

local playerRiding = false
local travelSpeed = 0

local spdOpts = { "    Very Slow     ", "       Slow         ", "      Normal      ", "      Quick        ", "       Fast         ", "     Very Fast     ",  " Ludicrous Speed ", }

--MOVE THIS SETTINGS CRAP SOMEWHERE ELSE!!!!
I.Settings.registerPage {
     key = "IFTSettings",
     l10n = "IFT",
     name = "Rideable Silt Striders",
     description = "Rideable Silt Striders settings\n\nTIP: Press 'HOME' button on keyboard to reset nearby travel npcs if they are missing or dislocated"
}
I.Settings.registerGroup {
    key = 'IFTSettingsGroup',
    page = 'IFTSettings',
    l10n = 'IFT',
    name = 'Main Settings',
    permanentStorage = true,
    settings = {
        {
          key = "speedSetting",
          renderer = "select",
          l10n = "XXXX",
          name = "Silt Strider Speed (default: Normal)",
          default = spdOpts[3],
          argument = {
               disabled = false,
               l10n = "XXXX",
               items = spdOpts,
          },

        },
    },
}

local function getPlayer()
    for i, ref in ipairs(nearby.actors) do
        if (ref.type == types.Player) then
            print("did it")
            return ref
        end
    end
end

local function LoadUserSettings() 
  local playerSettings = storage.playerSection('IFTSettingsGroup')
  local str = playerSettings:get('speedSetting')
  local val = 8 if str == spdOpts[1] then val = 2 elseif str == spdOpts[2] then val = 4 elseif str == spdOpts[3] then val = 8 elseif str == spdOpts[4] then val = 12 elseif str == spdOpts[5] then val = 16 elseif str == spdOpts[6] then val = 24 elseif str == spdOpts[7] then val = 32 end
  core.sendGlobalEvent('Rss_LoadUserSettings', { speed = val } )
end
--MOVE THIS SETTINGS CRAP SOMEWHERE ELSE!!!!


local function disableNearestStrider()
    for _, obj in ipairs(nearby.activators) do
        if obj.recordId == "a_siltstrider" then
            core.sendGlobalEvent('Rss_EnableDisableObject', { obj = obj, isActive = false } )
        end
    end
end

local function showMessage(data)
    ui.showMessage(tostring(data['message']))
end


local function createcontrolsPrompt(timer, text) 

  if controlsPrompt ~= nil then
    controlsPrompt:destroy()
    controlsPrompt = nil
  end

  showFreeRidePromptTimer = timer
  
  local text = ui.create {
       template = I.MWUI.templates.textNormal,
       layer = 'Windows',
       type = ui.TYPE.Text,
       props = {
          text = text,
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
          relativePosition = util.vector2(.5, .9),
          anchor = util.vector2(.5, 1),
      },
      content = ui.content({padding}),
  }
  
  controlsPrompt = textBox

end

local function resetNearbyActors(data)
  for _, actor in ipairs(nearby.actors) do
      if actor.recordId ~= 'player' and travelActorsList[actor.recordId] ~= nil then
        if (self.position - actor.position):length() < 10000 then
          core.sendGlobalEvent('Rss_TeleportActorToPos', { actor = actor, pos = actor.startingPosition } )
        end
      end
  end
end

local function onUpdate(dt)  

  -- Wind Audio
  if (self.cell.isExterior and travelSpeed > 0) then
    soundTime = soundTime + dt
    updateSoundTimer = updateSoundTimer - dt
    if updateSoundTimer <= 0 then
      updateSoundTimer = .5
      ambient.stopSound("BM Wind")
      ambient.playSound("BM Wind", { volume = math.min(1, travelSpeed / 8), timeOffset = soundTime})
    end
    if not ambient.isSoundPlaying('BM Wind') then 
      soundTime = 0 
      ambient.playSound("BM Wind", { volume = math.min(1, travelSpeed / 8), timeOffset = soundTime})  
    end
    travelSpeed = travelSpeed - dt * 2
  end  

  if input.isKeyPressed(input.KEY.Home) then 
    resetNearbyActors()
  end
  
  if input.isActionPressed(input.ACTION.Activate) then 
    core.sendGlobalEvent('Rss_PlayerJumpOffStriderEarly', {} )
  end
  core.sendGlobalEvent('Rss_SetPlayerInputs', { 
    camForward = camera.viewportToWorldVector(util.vector2(.5,.5)), 
    moveFwd = input.getRangeActionValue('MoveForward'), 
    moveL = input.getRangeActionValue('MoveLeft'),
    moveR = input.getRangeActionValue('MoveRight'),
    jump = input.isActionPressed(input.ACTION.Jump),
  })
  
  --if not winCreated then showMessageBox("windowName", { "text1", "text2" }, nil) end
  if not I.UI.getMode() ~= nil then
    if (I.UI.getMode() == I.UI.MODE.Travel) then
        local buttons = {}
        local sortedKeys = {}
        if activeTravelData ~= nil then
          for key, _ in pairs(activeTravelData) do table.insert(sortedKeys, key) end
          table.sort(sortedKeys, function(key1, key2) return activeTravelData[key1].sort < activeTravelData[key2].sort end)
          for _, k in pairs(sortedKeys) do
            if activeTravelData[k] ~= nil then
              table.insert(buttons, "  " .. k .. " - " .. activeTravelData[k]['cost'] .. "gp" .. "  ")
            end
          end
          table.insert(buttons, "  " .. "Free Ride - 250gp  ")
          self:sendEvent("Rss_ShowMessageBoxEvent", {winName = "IFT", textLines = { "", "Immersive Travel", "    Select Destination    ", "________________" },  buttons = buttons })
        end
        showingCustomTravelMenu = true
    end
    if showingCustomTravelMenu and I.UI.getMode() ~= I.UI.MODE.Travel then
        self:sendEvent("Rss_HideMessageBox", { } )
        --I.MessageBox.hideMessageBox()
        showingCustomTravelMenu = false
    end
    if (I.UI.getMode() == I.UI.MODE.MainMenu) then
        LoadUserSettings() 
    end
  end
  
  slowUpdateTimer = slowUpdateTimer + .016
  if slowUpdateTimer > 2 then
    slowUpdateTimer = 0
  end
  
  if playerIsTraveling then
    if camera.getMode() == camera.MODE.Vanity then
      
    end
  end
  
  if showFreeRidePromptTimer > 0 then
    showFreeRidePromptTimer = showFreeRidePromptTimer - dt
    if (showFreeRidePromptTimer <= 0) then
      controlsPrompt:destroy()
    end
  end

  --ui.showMessage(tostring(self.position))
  --self.position = self.position + util.vector3(0,1,0)
  --self.teleport(self,"",self.position + util.vector3(0,1,0))
end

--time.runRepeatedly(checkIfNearTravelActor, 1 * time.second)

--local function getPlayerGoldAmount

local function getListOfTravelActors(data) 
  travelActorsList = data.list
end

local function setActiveTravelData(data) 
  activeTravelData = data.tData
end

local function getPlayerGoldAmount() 
  local gold = types.Actor.inventory(self):find('gold_001')
  if gold then return gold.count end
  return 0
end

local function destinationSelected(data) 
  LoadUserSettings() 
  local key = data.text:match("^%s*(.-)%s%-")
  local cost = 0
  local freeRide = (key == "Free Ride")
  if freeRide then cost = 250
  else cost = activeTravelData[key].cost end
  if getPlayerGoldAmount() >= cost then
    core.sendGlobalEvent('Rss_ReducePlayersGold', { amount = cost } )
    if freeRide then
      createcontrolsPrompt(20, " \n'Forward' to Accelerate\n'Left' and 'Right' to Turn\nHold 'Jump' to Fly (Default: E)\n\n    Press 'Activate' to hop out and continue on foot (Default: SPACE)   \n ") 
    else
      createcontrolsPrompt(10, "\nSelected " .. key .. "\n\n   Press 'Activate' to hop out and continue on foot (Default: SPACE)   \n") 
      --ui.showMessage("Press 'L' to hop out and end your travel at any point.")
      --ui.showMessage("Selected " .. key)
    end 
    core.sendGlobalEvent('Rss_StartTravel', { key = key } )
  else
    ui.showMessage("You don't have enough gold.")
  end
end

local function setPlayerIsTraveling(data) 
  playerIsTraveling = data.isTraveling
  --if playerIsTraveling then I.Camera.disableModeControl("Vanity") else I.Camera.enableModeControl("Vanity") end
end

local function raycastToFindSurface(data)
  local results = nearby.castRay(data.from,data.to,{ignore=self})
  if results.hit then
    core.sendGlobalEvent('Rss_SetRaycastFoundSurface', { hitPos = results.hitPos } )
  end
end

local function rss_playerPlayAnimation(data) 
  if (data.animationName == nil) then anim.clearAnimationQueue(self, true)
  else anim.playQueued(self, data.animationName) end
end

local function rss_getGlobalData(data) 
  playerRiding = data.playerRiding
  if playerRiding then travelSpeed = data.travelSpeed end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = function(key)
            if key.symbol == 'x' then
              
            end
            if key.symbol == 'z' then
                print(tostring(self.position))
            end
            if key.symbol == 'b' then

            end
            if key.symbol == 'l' then
                --core.sendGlobalEvent('Rss_PlayerJumpOffStriderEarly', {} )
            end
        end
    },
    eventHandlers = { 
      Rss_DisableNearestStrider = disableNearestStrider,
      Rss_ShowMessage = showMessage,
      Rss_DestinationSelected = destinationSelected,
      Rss_SetActiveTravelData = setActiveTravelData,
      Rss_ResetNearbyActors = resetNearbyActors,
      Rss_SetPlayerIsTraveling = setPlayerIsTraveling,
      Rss_RaycastToFindSurface = raycastToFindSurface,
      Rss_GetListOfTravelActors = getListOfTravelActors,
      Rss_getGlobalData = rss_getGlobalData,
      Rss_playerPlayAnimation = rss_playerPlayAnimation,
    }
}
