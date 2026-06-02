--
-- [ Libraries ]
--
local ui = require('openmw.ui')
local iUI = require('openmw.interfaces').UI
local core = require('openmw.core')
local self  = require('openmw.self')


--
-- [ Variables ]
--
local cannotRestGMST = 'sRestMenu4'
local inBed = false


--
-- [ Functions ]
--
-- __ Check if bed __
local function UiModeChanged(data)
    if data.newMode == 'Rest' and not data.oldMode then
        if data.arg then inBed = true
        else core.sendGlobalEvent('onNoBedReceived', self)
        end
    elseif inBed and not data.newMode and data.oldMode == 'Rest' then inBed = false
    end
end
-- __ Prevent resting if no bed __
local function onFrame()
    if not inBed then
        iUI.removeMode('Rest')
    end
end
-- _ Show no bed message _
local function showMessageNoBed()
    ui.showMessage('You must find a bed.', { showInDialogue = false})
end


--
-- [ Handlers ]
--
return {
    engineHandlers = {
        onFrame = onFrame
    },
    eventHandlers = {
        showMessageNoBed = showMessageNoBed,
        UiModeChanged = UiModeChanged
    }
}
