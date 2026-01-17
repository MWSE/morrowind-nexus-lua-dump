local myUtil = require('scripts.oneKeyActionsList.myLib.myUtils')
local input = require('openmw.input')
local core = require('openmw.core')
local myVars = require('scripts.oneKeyActionsList.myLib.myVars')

local keyMaps = {
        [input.KEY.W]                       = 'up',
        [input.KEY.UpArrow]                 = 'up',
        [input.CONTROLLER_BUTTON.DPadUp]    = 'up',

        [input.KEY.S]                       = 'down',
        [input.KEY.DownArrow]               = 'down',
        [input.CONTROLLER_BUTTON.DPadDown]  = 'down',

        [input.KEY.A]                       = 'left',
        [input.KEY.LeftArrow]               = 'left',
        [input.CONTROLLER_BUTTON.DPadLeft]  = 'left',

        [input.KEY.D]                       = 'right',
        [input.KEY.RightArrow]              = 'right',
        [input.CONTROLLER_BUTTON.DPadRight] = 'right',

        [input.KEY.Enter]                   = 'select',
        [input.KEY.E]                       = 'select',
        [input.CONTROLLER_BUTTON.A]         = 'select',

}

---@enum myActions
local myActions = {
        up     = 'up',
        down   = 'down',
        left   = 'left',
        right  = 'right',
        select = 'select',
}

local keys = {}
local alreadyPressed = {}
local keyPressTime = {}
local FAST_DELAY = 0.02
local holdDelay = 0.23

---@param actionKey myActions
---@param action function
---@param hold boolean
local function checkKey(actionKey, action, hold)
        if keys[actionKey] == true then
                if hold == true then
                        if not alreadyPressed[actionKey] then
                                alreadyPressed[actionKey] = true
                                action()
                        elseif keyPressTime[actionKey] and core.getRealTime() - keyPressTime[actionKey] > holdDelay then
                                myUtil.throt('keyPresses', FAST_DELAY, action)
                        end
                elseif not alreadyPressed[actionKey] then
                        alreadyPressed[actionKey] = true
                        action()
                end
        end
end




---@param code number
---@param pressed true|nil
local function handlePress(code, pressed)
        if not myVars.mainWindow.element.layout then
                return
        end

        local key = keyMaps[code]
        if key then
                keys[key] = pressed

                if pressed then
                        keyPressTime[key] = core.getRealTime()
                else
                        alreadyPressed[key] = nil
                        keyPressTime[key] = nil
                end
        end
end



local function reset()
        keys = {}
        alreadyPressed = {}
end


return {
        checkKey = checkKey,
        handlePress = handlePress,
        reset = reset,
}
