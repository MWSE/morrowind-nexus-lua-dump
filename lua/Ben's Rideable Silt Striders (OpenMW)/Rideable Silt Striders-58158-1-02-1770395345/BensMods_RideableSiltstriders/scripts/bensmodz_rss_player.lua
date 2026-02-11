
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

local travelActorsList = nil
local activeTravelData = nil
local slowUpdateTimer = 0
local showingCustomTravelMenu = false
local playerIsTraveling = false;
local freeRideControlsPrompt = nil
local showFreeRidePromptTimer = 0

local spdOpts = { "    Very Slow     ", "       Slow         ", "      Normal      ", "      Quick        ", "       Fast         ", "     Very Fast     ",  " Ludicrous Speed ", }

--MOVE THIS SETTINGS CRAP SOMEWHERE ELSE!!!!
I.Settings.registerPage {
     key = "IFTSettings",
     l10n = "IFT",
     name = "Immersive Fast Travel",
     description = "Immersive Fast Travel settings\n\nTIP: Press 'HOME' button on keyboard to reset nearby travel npcs if they are missing or dislocated"
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
  local val = 8 if str == spdOpts[1] then val = 4 elseif str == spdOpts[2] then val = 6 elseif str == spdOpts[3] then val = 8 elseif str == spdOpts[4] then val = 12 elseif str == spdOpts[5] then val = 16 elseif str == spdOpts[6] then val = 24 elseif str == spdOpts[7] then val = 32 end
  core.sendGlobalEvent('LoadUserSettings', { speed = val } )
end
--MOVE THIS SETTINGS CRAP SOMEWHERE ELSE!!!!


local function disableNearestStrider()
    for _, obj in ipairs(nearby.activators) do
        if obj.recordId == "a_siltstrider" then
            core.sendGlobalEvent('EnableDisableObject', { obj = obj, isActive = false } )
        end
    end
end

local function showMessage(data)
    ui.showMessage(tostring(data['message']))
end


local function createFreeRideControlsPrompt() 

  showFreeRidePromptTimer = 20
  
  local text = ui.create {
       template = I.MWUI.templates.textNormal,
       layer = 'Windows',
       type = ui.TYPE.Text,
       props = {
          text = ' \nForward to Accelerate\nLeft and Right to Turn\nHold Spacebar to Fly\n\n    Press L to end travel and continue on foot    \n ',
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
          relativePosition = util.vector2(.5, .8),
          anchor = util.vector2(.5, .5),
      },
      content = ui.content({padding}),
  }
  
  freeRideControlsPrompt = textBox

end

local function resetNearbyActors(data)
  for _, actor in ipairs(nearby.actors) do
      if actor.recordId ~= 'player' and travelActorsList[actor.recordId] ~= nil then
        if (self.position - actor.position):length() < 10000 then
          core.sendGlobalEvent('TeleportActorToPos', { actor = actor, pos = actor.startingPosition } )
        end
      end
  end
end

local function onUpdate(dt)  

  if input.isKeyPressed(input.KEY.Home) then 
    resetNearbyActors()
  end
  core.sendGlobalEvent('SetPlayerInputs', { 
    camForward = camera.viewportToWorldVector(util.vector2(.5,.5)), 
    moveFwd = input.getRangeActionValue('MoveForward'), 
    moveL = input.getRangeActionValue('MoveLeft'),
    moveR = input.getRangeActionValue('MoveRight'),
    jump = input.isKeyPressed(input.KEY.Space),
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
          self:sendEvent("ShowMessageBoxEvent", {winName = "IFT", textLines = { "", "Immersive Travel", "    Select Destination    ", "________________" },  buttons = buttons })
        end
        showingCustomTravelMenu = true
    end
    if showingCustomTravelMenu and I.UI.getMode() ~= I.UI.MODE.Travel then
        self:sendEvent("HideMessageBox", { } )
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
      freeRideControlsPrompt:destroy()
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
    core.sendGlobalEvent('ReducePlayersGold', { amount = cost } )
    if freeRide then
      createFreeRideControlsPrompt() 
    else
      ui.showMessage("Press 'L' to hop out and end your travel at any point.")
      ui.showMessage("Selected " .. key)
    end 
    core.sendGlobalEvent('StartTravel', { key = key } )
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
    core.sendGlobalEvent('SetRaycastFoundSurface', { hitPos = results.hitPos } )
  end
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
                core.sendGlobalEvent('PlayerJumpOffStriderEarly', {} )
            end
        end
    },
    eventHandlers = { 
      DisableNearestStrider = disableNearestStrider,
      ShowMessage = showMessage,
      DestinationSelected = destinationSelected,
      SetActiveTravelData = setActiveTravelData,
      ResetNearbyActors = resetNearbyActors,
      SetPlayerIsTraveling = setPlayerIsTraveling,
      RaycastToFindSurface = raycastToFindSurface,
      GetListOfTravelActors = getListOfTravelActors,
    }
}
