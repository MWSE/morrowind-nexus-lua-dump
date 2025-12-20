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
function this.trigger(keyCombination)
    if not keyCombination then return false end

    local handlers = this.binds[keyCombination]
    if not handlers then return false end

    local sortedHandlers = {}
    for _, v in pairs(handlers) do
        table.insert(sortedHandlers, v)
    end
    table.sort(sortedHandlers, function (a, b)
        return a[2] > b[2]
    end)

    local res = false
    for _, handlerData in ipairs(sortedHandlers) do
        local handlerFunc = handlerData[1]
        handlerFunc(handlerData[3])
        res = true
    end

    return res
end



function this.onKeyPress(e)
    local keyId = keyCodes.getKeyboardKeyId(e.code)

    this.pressed[keyId] = true
    this.lastPressed[keyId] = core.getRealTime()
end

function this.onMouseButtonPress(button)
    local buttonId = keyCodes.getMouseButtonId(button)

    this.pressed[buttonId] = true
    this.lastPressed[buttonId] = core.getRealTime()
end

function this.onControllerButtonPress(id)
    local buttonId = keyCodes.getControllerButtonId(id)

    this.pressed[buttonId] = true
    this.lastPressed[buttonId] = core.getRealTime()
end


function this.onKeyRelease(e)
    local keyId = keyCodes.getKeyboardKeyId(e.code)

    this.trigger(this.getKeyCombinationString(keyId))

    this.pressed[keyId] = nil
end

function this.onMouseButtonRelease(button)
    local buttonId = keyCodes.getMouseButtonId(button)

    this.trigger(this.getKeyCombinationString(buttonId))

    this.pressed[buttonId] = nil
end

function this.onControllerButtonRelease(id)
    local buttonId = keyCodes.getControllerButtonId(id)

    this.trigger(this.getKeyCombinationString(buttonId))

    this.pressed[buttonId] = nil
end


---@return string?
---@return integer[]?
function this.getKeyCombinationString(lastCode)
    local combination = {}
    local timestamp = core.getRealTime()

    local function wasPressed(code)
        return this.lastPressed[code] and timestamp - this.lastPressed[code] < differenceThreshold
    end

    if lastCode and not this.pressed[lastCode] and wasPressed(lastCode) then
        table.insert(combination, lastCode)
    end

    for keyId, _ in pairs(this.pressed) do
        if wasPressed(keyId) or keyCodes.isPressed(keyId) then
            table.insert(combination, keyId)
        else
            this.pressed[keyId] = nil
        end
    end

    local str = keyCodes.getCombinationString(combination)
    return str, combination
end


function this.resetPressed()
    for k, _ in pairs(this.pressed) do
        this.pressed[k] = nil
    end
end


function this.hasPressedKeys()
    return next(this.pressed) and true or false
end


return this