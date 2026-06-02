--
-- [ Libraries ]
--
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local iUI = require('openmw.interfaces').UI
local core = require('openmw.core')
local async = require('openmw.async')
local types = require('openmw.types')
local self  = require('openmw.self')


--
-- [ Constants ]
--
local cannotRestGMST = 'sRestMenu4'
local debugPassword = 'chronotrigger'
local daySeconds = 86400
local hourSeconds = 3600


--
-- [ Variables ]
--
-- _ General _
local recoveryTimerInit = false
local recoveryTimerComplete = false
local restRecovery = 8
local restCounter = 28800
local restStartTime = 0
-- _ Debug _
local debugRecoveryCycle = 450


--
-- [ Settings ]
--
-- _ Get max rest credit _
local function getMaxRestCredit()
    local maxRestCredit = storage.playerSection('F_GeneralSettings'):get('MaxRestCredit')*hourSeconds
    return maxRestCredit
end
--[[
-- _ Get max rest debit _
local function getMaxRestDebit()
    local maxRestDebit = storage.playerSection('F_GeneralSettings'):get('MaxRestDebit')*hourSeconds
    return -maxRestDebit
end
]]--
-- _ Is Wake Up installed _
local function isWakeUpInstalled()
    if storage.playerSection('F_GeneralSettings'):get('WakeUpInstalled') then return true
    else return false
    end
end
-- _ Is debug mode on _
local function isDebugMode()
    if storage.playerSection('S_DebugSettings'):get('Password') == debugPassword then return true
    else return false
    end
end


--
-- [ Utilities ]
--
-- _ Limit time range _
local function limitTimeRange(value)
    if value > getMaxRestCredit() then return getMaxRestCredit()
    elseif value < -daySeconds then return -daySeconds
    else return value
    end
end
-- _ Show GMST message _
local function showGMSTMessage(message)
    ui.showMessage(message, { showInDialogue = false})
end


--
-- [ Debug Mode  ]
--
-- _ Add/substract rest counter _
local function onKeyPress(key)
    if isDebugMode() then
        ---- add
        if key.symbol == 'x' then
            restCounter = limitTimeRange(restCounter+hourSeconds)
            print(restCounter)
            core.sendGlobalEvent('onRestCounterReceived', restCounter)
        ---- substract
        elseif key.symbol == 'w' then
            restCounter = limitTimeRange(restCounter-hourSeconds)
            print(restCounter)
            core.sendGlobalEvent('onRestCounterReceived', restCounter)
        end
    end
end


--
-- [ Recovery Timer ]
--
-- _ Callback _
local recoveryTimerCallback = async:registerTimerCallback('rest recovery',
function()
    recoveryTimerComplete = true
end)
-- _ Trigger _
local function recoveryTimer()
    if isDebugMode() then
        debugRecoveryCycle = storage.playerSection('S_DebugSettings'):get('RecoveryCycle')
        async:newGameTimer(debugRecoveryCycle, recoveryTimerCallback)
    else
        async:newGameTimer(daySeconds, recoveryTimerCallback)
    end
end
-- _ Init/Reset _
local function onUpdate(dt)
    ---- init
    if not recoveryTimerInit and types.Player.isCharGenFinished(self) then
        recoveryTimer()
        if isDebugMode() then print(" \n=================================\nREST RECOVERY TIMER INITIATED\n=================================") end
        recoveryTimerInit = true
    end
    ---- reset
    if recoveryTimerComplete then
        restRecovery = storage.playerSection('F_GeneralSettings'):get('RestRecovery')
        restCounter = limitTimeRange(restCounter+(restRecovery*hourSeconds))
        core.sendGlobalEvent('onRestCounterReceived', restCounter)
        recoveryTimer()
        if isDebugMode() then print(" \n=================================\nREST RECOVERY TIMER RESET\n=================================") end
        recoveryTimerComplete = false
    end
end


--
-- [ Resting ]
--
local function UiModeChanged(data)
    -- _ Rest activation _
    if data.newMode == 'Rest' and not data.oldMode and restCounter <= 0 then
        if not isWakeUpInstalled() then
            showGMSTMessage(core.getGMST(cannotRestGMST))
        end
    -- _ Rest started _
    elseif data.oldMode == 'Rest' and data.newMode == 'Loading' then restStartTime = math.floor(core.getGameTime())
    -- _ Rest ended _
    elseif data.oldMode == 'Rest' and not data.newMode then
        if isDebugMode() and restStartTime == 0 then print(restCounter) end
        if restStartTime > 0 then
            restCounter = limitTimeRange(restCounter-(math.floor(core.getGameTime())-restStartTime))
            core.sendGlobalEvent('onRestCounterReceived', restCounter)
            if isDebugMode() then print(restCounter) end
            restStartTime = 0
        end
    end
end
-- _ Prevent resting _
local function onFrame()
    if restCounter <= 0 then iUI.removeMode('Rest') end
end


--
-- [ Save/load data  ]
--
-- _ Save _
local function onSave()
  return {
    savedRecoveryTimerInit = recoveryTimerInit,
    savedRestCounter = restCounter
  }
end
-- _ Load _
local function onLoad(data)
    ---- timer trigger condition
    if data.savedRecoveryTimerInit then recoveryTimerInit = data.savedRecoveryTimerInit end
    ---- rest counter
    if data.savedRestCounter then restCounter = data.savedRestCounter end
    ---- send to global
    core.sendGlobalEvent('onRestCounterReceived', restCounter)
end


--
-- [ Handlers ]
--
return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onSave = onSave,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onFrame = onFrame
    },
    eventHandlers = {
        showGMSTMessage = showGMSTMessage,
        UiModeChanged = UiModeChanged
    }
}
