local input = require("openmw.input")
local core = require("openmw.core")

local common = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.config")

local l10n = core.l10n(common.l10nKey)


local this = {}


this.isGamepad = true


this.keyName = {
    ["LMB"] = l10n("leftMouseButton"),
    ["MMB"] = l10n("middleMouseButton"),
    ["RMB"] = l10n("rightMouseButton"),
    ["MB4"] = l10n("mouseButton4"),
    ["MB5"] = l10n("mouseButton5"),
    ["C_A"] = "A",
    ["C_B"] = "B",
    ["C_X"] = "X",
    ["C_Y"] = "Y",
    ["C_Back"] = "Back",
    ["C_Guide"] = "Guide",
    ["C_Start"] = "Start",
    ["C_LeftStick"] = "Left Stick",
    ["C_RightStick"] = "Right Stick",
    ["C_LeftShoulder"] = "LB",
    ["C_RightShoulder"] = "RB",
    ["C_DPadUp"] = "D-pad Up",
    ["C_DPadDown"] = "D-pad Down",
    ["C_DPadLeft"] = "D-pad Left",
    ["C_DPadRight"] = "D-pad Right",
}


local function splitKeyCombination(comb)
    local keys = {}
    for key in string.gmatch(comb, "[^%s%+]+") do
        table.insert(keys, key)
    end
    return keys
end


---@param combination string?
---@return string?
function this.keyCombinationToString(combination)
    if not combination then return end

    local keys = splitKeyCombination(combination)
    local keyNames = {}
    for _, key in ipairs(keys) do
        local name
        local isKey, keyId = pcall(function ()
            return input.KEY[key]
        end)
        if isKey and keyId then
            name = input.getKeyName(keyId)
        else
            name = this.keyName[key]
        end
        name = name or key

        table.insert(keyNames, name)
    end

    return table.concat(keyNames, " + ")
end


local function isKeyValidToShow(comb)
    if not comb then return false end
    local hasGamepadKey = comb:find("C_") and true or false
    return this.isGamepad == hasGamepadKey
end



return this