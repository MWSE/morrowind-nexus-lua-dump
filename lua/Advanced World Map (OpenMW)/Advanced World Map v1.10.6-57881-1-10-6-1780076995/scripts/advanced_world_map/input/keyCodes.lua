local input = require("openmw.input")


local this = {}

---@type table<integer, string>
this.keyByCode = {}

for n, v in pairs(input.KEY) do this.keyByCode[v + 1000] = n end
for n, v in pairs(input.CONTROLLER_BUTTON) do this.keyByCode[v + 100] = "C_"..n end
this.keyByCode[1] = "LMB"
this.keyByCode[2] = "MMB"
this.keyByCode[3] = "RMB"
this.keyByCode[4] = "MB4"
this.keyByCode[5] = "MB5"


function this.getKeyboardKeyId(key)
    return key + 1000
end

function this.getMouseButtonId(button)
    return button
end

function this.getControllerButtonId(button)
    return button + 100
end


---@return boolean
function this.isPressed(code)
    if not code then return false end

    if code >= 1000 then
        return input.isKeyPressed(code - 1000)
    elseif code >= 100 then
        return input.isControllerButtonPressed(code - 100)
    else
        return input.isMouseButtonPressed(code)
    end

    return false
end


---@param combination integer[]
function this.getCombinationString(combination)
    table.sort(combination, function (a, b)
        return a > b
    end)

    local res
    for _, keyId in ipairs(combination) do
        local keyName = this.keyByCode[keyId]
        if keyName then
            res = res and res.." + "..keyName or keyName
        end
    end

    return res
end



function this.getAllCombinationsMap(combination)
    local resMap = {}
    local resArr = {}

    table.sort(combination, function (a, b)
        return a > b
    end)

    local n = #combination
    local totalCombinations = 2^n - 1

    for i = 1, totalCombinations do
        local comboStr
        local keys = {}
        local num = i
        local count = 0
        for j = 1, n do
            if num % 2 == 1 then
                local keyCode = combination[j]
                local keyName = this.keyByCode[keyCode]
                if keyName then
                    keys[keyCode] = keyName
                    count = count + 1
                    comboStr = comboStr and comboStr.." + "..keyName or keyName
                end
            end
            num = math.floor(num / 2)
        end
        if comboStr then
            resMap[comboStr] = keys
            table.insert(resArr, {comboStr, count, keys})
        end
    end

    return resMap, resArr
end


return this