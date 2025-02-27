 I = require('openmw.interfaces')
    local core = require('openmw.core')
    local self = require('openmw.self')
    local player = self
	local speakingActor
	local smellynewmode = 'is the new mode'
	local smellyoldmode = 'is the old mode'
	local smellyactor =  'is the actor'
    I.UI.setPauseOnMode('Dialogue', false)
    
    
    return {
     eventHandlers  = {
	 UiModeChanged = function(data)
     if data.newMode == 'Dialogue' and data.oldMode == nil then 
	 print (data.newMode, smellynewmode)
	 print (data.oldMode, smellyoldmode)
	 speakingActor = data.arg 
	 print (speakingActor, smellyactor)
    elseif speakingActor and not data.newMode and data.oldMode == 'Dialogue' then 
   print 'The event is being sent'
  speakingActor:sendEvent('SMELLY_INTERRUPTTURNING') 
  core.sendGlobalEvent('Unpause')
  speakingActor = nil
  	end
    end,
    }
    }
    
	