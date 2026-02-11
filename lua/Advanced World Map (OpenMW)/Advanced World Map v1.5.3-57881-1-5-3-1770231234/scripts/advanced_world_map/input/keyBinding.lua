local core = require("openmw.core")

local keyCodes = require("scripts.advanced_world_map.input.keyCodes")


local differenceThreshold = 1.25 -- seconds


local this = {}

---@type table<string, number>
this.lastPressed = {}
---@type table<integer, boolean>
this.pressed = {}
---@type table<string, table<function, {[1] : function, [2] : number, [3] : string}>>
this.binds = {}
---@type table<string, boolean>
this.triggered = {}


---@param keyCombination string
---@param handlerFunc fun()
---@param priority integer?
function this.register(keyCombination, handlerFunc, priority)
    if type(handlerFunc) ~= "function" then return end
    this.binds[keyCombination] = this.binds[keyCombination] or {}
    this.binds[keyCombination][handlerFunc] = {handlerFunc, priority or 0, keyCombination}
end


---@param keyCombination string
---@param handlerFunc fun()
function this.unregister(keyCombination, handlerFunc)
    this.binds[keyCombination] = this.binds[keyCombination] or {}
    this.binds[keyCombination][handlerFunc] = nil
end


---@param keyCombination string
---@return boolean
function this.isContainsHandler(keyCombination)
    return this.binds[keyCombination] ~= nil and next(this.binds[keyCombination]) ~= nil
end


---@param keyCombination string?
---@return boolean
---@return boolean
function this.trigger(keyCombination)
    if not keyCombination then return false, false end

    local handlers = this.binds[keyCombination]
    if not handlers then return false, false end

    local sortedHandlers = {}
    for _, v in pairs(handlers) do
        table.insert(sortedHandlers, v)
    end
    table.sort(sortedHandlers, function (a, b)
        return a[2] > b[2]
    end)

    local res = false
    local handlerRes = false
    for _, handlerData in ipairs(sortedHandlers) do
        local handlerFunc = handlerData[1]
        handlerRes = handlerFunc(handlerData[3]) or handlerRes or false
        res = true
    end

    return res, handlerRes
end


local function createKeyCombinationDataSimple()
    local combination = {}

    for keyId, _ in pairs(this.pressed) do
        if keyCodes.isPressed(keyId) then
            table.insert(combination, keyId)
        else
            this.pressed[keyId] = nil
        end
    end

    return combination
end


function this.triggerKeyCombinations(lastKeyCode)
    local combination = createKeyCombinationDataSimple()

    if #combination > 4 then
        local combStr = keyCodes.getCombinationString(combination)
        this.trigger(combStr)
    else
        local keyCombMap, keyCombArr = keyCodes.getAllCombinationsMap(combination)

        for keyStr, _ in pairs(this.triggered) do
            if not keyCombMap[keyStr] then
                this.triggered[keyStr] = nil
            end
        end

        table.sort(keyCombArr, function (a, b)
            return a[2] > b[2]
        end)

        for _, keyData in ipairs(keyCombArr) do
            local keyStr = keyData[1]
            local keyMap = keyData[3]
            if this.isContainsHandler(keyStr) then
                if not this.triggered[keyStr] or keyMap[lastKeyCode] then
                    local res, handlerRes = this.trigger(keyStr)
                    this.triggered[keyStr] = true

                    if handlerRes then
                        break
                    end
                end
            end
        end
    end
end



function this.onKeyPress(e)
    local keyId = keyCodes.getKeyboardKeyId(e.code)

    this.pressed[keyId] = true
    this.triggerKeyCombinations(keyId)
end

function this.onMouseButtonPress(button)
    local buttonId = keyCodes.getMouseButtonId(button)

    this.pressed[buttonId] = true
    this.triggerKeyCombinations(buttonId)
end

function this.onControllerButtonPress(id)
    local buttonId = keyCodes.getControllerButtonId(id)

    this.pressed[buttonId] = true
    this.triggerKeyCombinations(buttonId)
end


function this.onKeyRelease(e)
    local keyId = keyCodes.getKeyboardKeyId(e.code)

    this.pressed[keyId] = nil
end

function this.onMouseButtonRelease(button)
    local buttonId = keyCodes.getMouseButtonId(button)

    this.pressed[buttonId] = nil
end

function this.onControllerButtonRelease(id)
    local buttonId = keyCodes.getControllerButtonId(id)

    this.pressed[buttonId] = nil
end



--#################################################################################################
--For renderer


function this.onKeyPressRenderer(e)
    local keyId = keyCodes.getKeyboardKeyId(e.code)

    this.pressed[keyId] = true
    this.lastPressed[keyId] = core.getRealTime()
end

function this.onMouseButtonPressRenderer(button)
    local buttonId = keyCodes.getMouseButtonId(button)

    this.pressed[buttonId] = true
    this.lastPressed[buttonId] = core.getRealTime()
end

function this.onControllerButtonPressRenderer(id)
    local buttonId = keyCodes.getControllerButtonId(id)

    this.pressed[buttonId] = true
    this.lastPressed[buttonId] = core.getRealTime()
end


function this.onKeyReleaseRenderer(e)
    local keyId = keyCodes.getKeyboardKeyId(e.code)
    this.triggerKeyCombinations(keyId)
    this.pressed[keyId] = nil
end

function this.onMouseButtonReleaseRenderer(button)
    local buttonId = keyCodes.getMouseButtonId(button)
    this.triggerKeyCombinations(buttonId)
    this.pressed[buttonId] = nil
end

function this.onControllerButtonReleaseRenderer(id)
    local buttonId = keyCodes.getControllerButtonId(id)
    this.triggerKeyCombinations(buttonId)
    this.pressed[buttonId] = nil
end


local function createKeyCombinationData(lastKeyCode)
    local combination = {}
    local timestamp = core.getRealTime()

    local function wasPressed(code)
        return this.lastPressed[code] and timestamp - this.lastPressed[code] < differenceThreshold
    end

    if lastKeyCode and not this.pressed[lastKeyCode] and wasPressed(lastKeyCode) then
        table.insert(combination, lastKeyCode)
    end

    for keyId, _ in pairs(this.pressed) do
        if wasPressed(keyId) or keyCodes.isPressed(keyId) then
            table.insert(combination, keyId)
        else
            this.pressed[keyId] = nil
        end
    end

    return combination
end


---@return string?
---@return integer[]?
function this.getKeyCombinationString(lastCode)
    local combination = createKeyCombinationData(lastCode)

    local str = keyCodes.getCombinationString(combination)
    return str, combination
end


--#################################################################################################


function this.resetPressed()
    for k, _ in pairs(this.pressed) do
        this.pressed[k] = nil
    end
end


function this.hasPressedKeys()
    return next(this.pressed) and true or false
end


return this