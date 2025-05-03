local core = require("openmw.core")
local world = require("openmw.world")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")
local constants = require("scripts.transporter_lights.constants")

local option = storage.globalSection("Settings_Transporter_Lights_Options_Key_KINDI")

local alternateLights = constants.alternateLights
local defaultLights = constants.lights
local refreshRate = 0.1

if not next(defaultLights) then
    option:set("Mod Status", false)
end

if not next(alternateLights) then
    option:set("Alternate Lights", false)
end

local function isNight()
    local gameHour = world.mwscript.getGlobalVariables()["gamehour"] -- core.getGameTime() / time.hour % 24
    return gameHour >= 20 or gameHour <= 6
end
local function pickFallbackLight(actor)
    return defaultLights[types.NPC.record(actor).class]
end

local function cloneRecord(recordId)
    local baseRecord = types.Light.records[recordId]
    local cloneDraft = types.Light.createRecordDraft(baseRecord)
    return world.createRecord(cloneDraft)
end
local function actorHasObject(object, actor)
    if object and object:isValid() and object.count > 0 and object.parentContainer == actor then
        return true
    end
    return false
end

local function findInTable(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then
            return k
        end
    end
end

local function getNextLight(actor)
    local transporterData = I.transporter_lights.transporters[actor.id]
    if next(transporterData) then
        local currentLightIndex = findInTable(alternateLights, transporterData.lightId)
        return alternateLights[(currentLightIndex or 0) % #alternateLights + 1]
    else
        return alternateLights[math.random(#alternateLights)]
    end
end

local function selectLight(actor)
    local lightId = pickFallbackLight(actor)
    local altType = option:get("Alternate Lights")

    if altType == "cycle" then
        lightId = getNextLight(actor)
    elseif altType == "randomize" then
        local currentLightId = I.transporter_lights.transporters[actor.id].lightId
        repeat
            lightId = alternateLights[math.random(#alternateLights)]
        until lightId ~= currentLightId or #alternateLights == 1
    end

    return lightId
end
local function removeLightAllTransporters()
    for actorId in pairs(I.transporter_lights.transporters) do
        local actor = world.getObjectByFormId("FormId:" .. actorId)
        I.transporter_lights.removeLight(actor)
    end
end

local function equipLightAllTransporters()
    for actorId in pairs(I.transporter_lights.transporters) do
        local actor = world.getObjectByFormId("FormId:" .. actorId)
        I.transporter_lights.equipLight(actor, selectLight(actor))
    end
end

local function onUpdate()
    local today = world.mwscript.getGlobalVariables()["day"] -- util.round(core.getGameTime() / time.day)
    if option:get("Debug") then
        equipLightAllTransporters()
        return
    end

    if option:get("Mod Status") then
        if isNight() then
            if I.transporter_lights.currentDay ~= today then
                I.transporter_lights.setCurrentDay(today)
                equipLightAllTransporters()
            end
        end
    else
        removeLightAllTransporters()
    end
end

time.runRepeatedly(onUpdate, refreshRate)

option:subscribe(async:callback(function(_, optionName)
    if optionName == "Debug" then
        return
    end
    if option:get("Mod Status") then
        equipLightAllTransporters()
    else
        removeLightAllTransporters()
    end
end))

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.type == types.NPC and not types.Actor.isDead(actor) and defaultLights[types.NPC.record(actor).class] then
                if I.transporter_lights.transporters[actor.id] == nil then
                    I.transporter_lights.transporters[actor.id] = {}
                end
            else
                I.transporter_lights.transporters[actor.id] = nil
            end
        end,

        onLoad = function(data)
            I.transporter_lights.loadData(data)
        end,
        onSave = function()
            return {
                version = I.transporter_lights.version,
                transporters = I.transporter_lights.transporters,
                currentDay = I.transporter_lights.currentDay
            }
        end
    },
    interfaceName = "transporter_lights",
    interface = setmetatable({
        version = 0.2,
        info = tostring(require("scripts.transporter_lights.modInfo")),
        help = constants.help,
        currentDay = -1, -- keep track of day
        transporters = {} -- stores last light equipped by the transporters
    }, {
        __index = function(this, key)
            if key == "setCurrentDay" then
                return function(newDay)
                    this.currentDay = newDay
                end
            end
            if key == "loadData" then
                return function(data)
                    if data and data.version == this.version then
                        this.transporters = data.transporters
                        this.currentDay = data.currentDay
                    end
                end
            end
            if key == "removeLight" then
                return function(actor)
                    local lightObject = this.transporters[actor.id].lightObject
                    if actorHasObject(lightObject, actor) then
                        lightObject:remove()
                    end
                end
            end
            if key == "equipLight" then
                return function(actor, lightId)
                    -- create a clone so it doesn't stack with vanilla lights
                    local clonedSuccessfully, lightRecordClone = pcall(cloneRecord, lightId)

                    if clonedSuccessfully then
                        local lightObject = world.createObject(lightRecordClone.id, 1)
                        lightObject:moveInto(actor)

                        I.ItemUsage.addHandlerForObject(lightObject, actorHasObject)
                        core.sendGlobalEvent("UseItem", {
                            object = lightObject,
                            actor = actor,
                            force = true
                        })

                        this.removeLight(actor)
                        this.transporters[actor.id] = {
                            lightObject = lightObject,
                            lightId = lightId,
                            lightName = lightObject.type.records[lightId].name
                        }
                    else
                        error(string.format("'%s' is not a valid object record!", lightId))
                    end
                end
            end
            if key == "listTransporters" then
                local str = aux_util.deepToString(this.transporters, 3)
                for id in pairs(this.transporters) do
                    local object = world.getObjectByFormId("FormId:" .. id:gsub("^@", ""))
                    str = str:gsub(id, tostring(object))
                end
                return str
            end
        end
    })

}
