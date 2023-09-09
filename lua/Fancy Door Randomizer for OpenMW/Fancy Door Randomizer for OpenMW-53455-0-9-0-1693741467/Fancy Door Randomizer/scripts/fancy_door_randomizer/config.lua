local advTable = require("scripts.fancy_door_randomizer.utils.table")
local stringLib = require("scripts.fancy_door_randomizer.utils.string")

---@class fdr.config
local this = {}

local delimiter = "."

this.storageName = "Settings_fancy_door_randomizer_by_diject"

this.prefix = "fdr_by_diject_"

this.version = 1

this.modes = {"nearestMode", "simpleMode"}

---@class fdr.configData
this.default = {
    enabled = false,
    chance = 25,
    mode = this.modes[1],
    radius = 2,
    interval = 24,
    exitDoor = true,
    swap = true,
    allowLockedExit = true,
    unlockLockedExit = true,
    untrapExit = false,
    saveOnFailure = true,
    inToEx = {
        toInToEx = true,
        toInToIn = false,
        toExToEx = false,
        toExToIn = false,
    },
    inToIn = {
        toInToEx = false,
        toInToIn = true,
        toExToEx = false,
        toExToIn = false,
    },
    exToEx = {
        toInToEx = false,
        toInToIn = false,
        toExToEx = true,
        toExToIn = false,
    },
    exToIn = {
        toInToEx = false,
        toInToIn = false,
        toExToEx = false,
        toExToIn = true,
    },
}

---@type fdr.configData
this.data = advTable.deepcopy(this.default)

function this.loadData(data)
    if not data then return end
    advTable.applyChanges(this.data, data)
end

function this.setValueByString(val, str)
    local var = this.data
    local lastName
    local prevVar
    for _, varName in ipairs(stringLib.split(str, delimiter)) do
        if var[varName] ~= nil then
            lastName = varName
            prevVar = var
            var = var[lastName]
        else
            return false
        end
    end
    if lastName then
        if prevVar ~= nil then
            prevVar[lastName] = val
        else
            var[lastName] = val
        end
        return true
    end
    return false
end

function this.getValueByString(str)
    local var = this.data
    for _, varName in pairs(stringLib.split(str, delimiter)) do
        if var[varName] ~= nil then
            var = var[varName]
        else
            return nil
        end
    end
    return var
end

function this.loadPlayerSettings(storageTable)
    for name, val in pairs(storageTable) do
        this.setValueByString(val, name)
    end
end

function this.getDoorConfigTable(isDoorExterior, isDestinationExterior)
    local posExterior = isDoorExterior
    local destExterior = isDestinationExterior
    if posExterior and destExterior then
        return this.data.exToEx
    elseif posExterior and not destExterior then
        return this.data.exToIn
    elseif not posExterior and destExterior then
        return this.data.inToEx
    elseif not posExterior and not destExterior then
        return this.data.inToIn
    end
end

return this