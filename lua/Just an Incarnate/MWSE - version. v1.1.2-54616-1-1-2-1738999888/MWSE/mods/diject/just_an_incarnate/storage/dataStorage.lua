require("diject.just_an_incarnate.libs.types")
local log = include("diject.just_an_incarnate.utils.log")
local globalStorage = include("diject.just_an_incarnate.storage.globalStorage")
local config = include("diject.just_an_incarnate.config")

local playerDataLabel = "playerData"

local this = {}

---@type table<string, jai.storage.playerData> player id as the id
this.playerData = globalStorage.data[playerDataLabel]
if this.playerData == nil then
    this.playerData = {}
    globalStorage.data[playerDataLabel] = this.playerData
end


function this.save()
    globalStorage.save()
end

---@param race tes3race
---@return jai.storage.race
function this.getRaceData(race)
    local raceBodyPart = {"ankle", "chest", "clavicle", "foot", "forearm", "groin", "hands",
        "knee", "neck", "tail", "upperArm", "upperLeg", "vampireHead", "wrist",
    }
    ---@type jai.storage.race
    local raceData = {female = {}, male = {}, isBeast = race.isBeast}
    for _, bodyPartName in pairs(raceBodyPart) do
        raceData.female[bodyPartName] = race.femaleBody[bodyPartName] and race.femaleBody[bodyPartName].id or nil
        raceData.male[bodyPartName] = race.maleBody[bodyPartName] and race.maleBody[bodyPartName].id or nil
    end
    return raceData
end

---@param playerId string
function this.savePlayerDeathInfo(playerId)
    if not this.playerData[playerId] then this.playerData[playerId] = {} end ---@diagnostic disable-line: missing-fields
    local deathCount = (this.playerData[playerId].count or 0) + 1
    this.playerData[playerId].count = deathCount

    this.save()
end

function this.getDeathCount(playerId)
    local playerData = this.playerData[playerId]
    if not playerData then return nil end
    return playerData.count
end

function this.getPlayerName(name, useLocalDeathCounter)
    local num = useLocalDeathCounter and config.localConfig.count or this.getDeathCount(config.localConfig.id)
    if num then
        return tes3.player.object.name.." The "..tostring(num + 1).."th"
    else
        return tes3.player.object.name
    end
end

return this