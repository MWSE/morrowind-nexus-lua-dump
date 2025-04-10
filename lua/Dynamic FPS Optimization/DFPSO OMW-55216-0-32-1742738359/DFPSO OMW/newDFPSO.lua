local core = require('openmw.core')
local async = require('openmw.async')
local camera = require('openmw.camera')
local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')

-- In a player script
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
I.Settings.registerPage {
    key = 'dfpsoPage',
    l10n = 'DFPSO',
    name = 'Dynamic FPS Optimization',
    description = 'Dynamic view distance adjustment based on framerate and other parameters.',
}
I.Settings.registerGroup {
    key = 'SettingsDFPSO',
    page = 'dfpsoPage',
    l10n = 'DFPSO',
    name = 'DFPSO Settings',
    description = 'Change DFPSO parameters',
    permanentStorage = true,
    settings = {
        {
            key = 'target',
            renderer = 'number',
            name = 'Target Framerate',
            description = 'This determines the framerate the script will try to reach. Default is 60, recommended to set slightly lower than your average framerate in non-stressed areas.',
            default = 60,
            argument = {
            
            min = 1,
            max = 500,
            integer = true,
            },
        },
        {
            key = 'tlr',
            renderer = 'number',
            name = 'Tolerance',
            description = 'Tolerance around target framerate, given as percent of target framerate.',
            default = 10,
            argument = {
            
            min = 1,
            max = 100,
            integer = true,
            },
        },
        {
            key = 'daw',
            default = true,
            renderer = 'checkbox',
            name = 'Delta Awareness',
            description = 'Increases change per frame when the difference between target and current frametime are large.',
        },
        {
            key = 'cpf',
            renderer = 'number',
            name = 'Change per Frame',
            description = 'Determines the View Distance amount to change by per frame. Values below 20 are recommended for a smooth look.',
            default = 10,
            argument = {
            
            min = 1,
            max = 10000,
            integer = true,
            },
        },
        {
            key = 'maxVD',
            renderer = 'number',
            name = 'Maximum View Distance',
            description = 'The maximum View Distance value DFPSO will set to.',
            default = 7168,
            argument = {
            
            min = 2500,
            max = 1000000,
            integer = true,
            },
        },
        {
            key = 'minVD',
            renderer = 'number',
            name = 'Minimum View Distance',
            description = 'The minimum View Distance value DFPSO will set to.',
            default = 2500,
            argument = {
            
            min = 2500,
            max = 1000000,
            integer = true,
            },
            },
            {
            key = 'useL',
            default = true,
            renderer = 'checkbox',
            name = 'Use Grid List',
            description = 'Restricts functionality to cells recorded in a list. Cells are automatically added to list based on Gridlist Threshold.',
        },
         {
            key = 'listThres',
            renderer = 'number',
            name = 'Gridlist Threshold',
            description = 'The framerate threshold for automatic list addition. If a cell performs worse than this framerate for three seconds, it is added to the list.',
            default = 40,
            argument = {
            
            min = 1,
            max = 100,
            integer = true,
            },
           },
        },
    
}

local DFPSOData = storage.playerSection('DFPSO')

local playerSettings = storage.playerSection('SettingsDFPSO')
local currentVD
local upperBound
local lowerBound
local deltamult

local onList
local listTH

local lastCell = util.vector2(0,0)
local currentCell = util.vector2(0,0)
local lowfpscount = 0

local lastFrametime = 0

function onKeyPress(key)

  if(key.symbol == 'u' and key.withShift) then
  
    DFPSOData:reset()
    ui.showMessage('Reset Grid List')
  end

end

function alaCheck()

  if(playerSettings:get('useL') == true)then
    
    currentCell = util.vector2(self.object.cell.gridX, self.object.cell.gridY)
    
    if(currentCell == lastCell)then
    
      if(lastFrametime > (1 / playerSettings:get('listThres'))) then
      
        lowfpscount = lowfpscount + 1
        
      else
        
        lowfpscount = 0
      
      end

    --check for lowfpscount high enough, then add cell
      if(lowfpscount >= 3) then
    
        if(DFPSOData:get(tostring(currentCell)) ~= true) then 
          DFPSOData:set(tostring(currentCell), true)
          ui.showMessage('Added cell to DFPSO list')
        end
        
        lowfpscount = 0
        
      end

    
    end
  
    lastCell = util.vector2(self.object.cell.gridX, self.object.cell.gridY)
  
  end

end

local regAla = time.runRepeatedly(alaCheck, time.second)

function onFrame(dt)

lastFrametime = core.getRealFrameDuration()
dt = core.getRealFrameDuration()
currentVD = camera.getViewDistance()
upperBound = playerSettings:get('target') * (1 - (playerSettings:get('tlr') / 100))
lowerBound = playerSettings:get('target') * (1 + (playerSettings:get('tlr') / 100))
deltamult = 1

if(playerSettings:get('useL') == true)then
onList = false
else
onList = true
end

--delta awareness
if(playerSettings:get('daw') == true) then

  if((math.abs(dt - (1/playerSettings:get('target'))) * 1000) > 1) then

    deltamult = math.abs(dt - (1/playerSettings:get('target'))) * 1000

  end

end

if(playerSettings:get('useL') == true)then
--grid comparison
if(DFPSOData:get(tostring(currentCell)) == true) then

  onList = true

end
end


--dfpso main function
if(onList == true) then
  if(dt < (1 / lowerBound)) then
    
    camera.setViewDistance(math.min(playerSettings:get('maxVD'), (currentVD + playerSettings:get('cpf') * deltamult)))
  end

  if(dt > (1 / upperBound)) then

    camera.setViewDistance(math.max(playerSettings:get('minVD'), (currentVD - playerSettings:get('cpf') * deltamult)))
  end
else

  --smooth return to max
  if(currentVD < playerSettings:get('maxVD')) then
  
    camera.setViewDistance(math.min(playerSettings:get('maxVD'), (currentVD + 100)))
  
  end

end
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onKeyPress = onKeyPress,
            }
}