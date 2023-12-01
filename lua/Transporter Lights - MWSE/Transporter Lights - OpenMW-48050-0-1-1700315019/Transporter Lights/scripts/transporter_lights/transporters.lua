local self = require "openmw.self"
local types = require "openmw.types"
local core = require "openmw.core"
local async = require "openmw.async"
local storage = require "openmw.storage"
local time = require "openmw_aux.time"
local util = require "openmw.util"

local numOfAltLights = #require("scripts.transporter_lights.constants").alternateLights
local option = storage.globalSection("Settings_Transporter_Lights_Options_Key_KINDI")

local index = math.random(numOfAltLights)
local theSameDay = false
local curDay = 0x0

local function equipLight(debug)
    core.sendGlobalEvent("TRANSPORTER_LIGHTS_EQUIP_LIGHT_EQNX", {
        self,
        debug and index
    })
end

local function isNight()
    local gameHour = core.getGameTime() / time.hour % 24
    return (gameHour >= 20 or gameHour <= 6)
end

local function update()
    async:newUnsavableSimulationTimer(0.2, update)
    local day = util.round(core.getGameTime() / time.day)
    if option:get("Debug") then
        index = (index % numOfAltLights) + 1
        equipLight(true)
        return
    end
    if curDay ~= day then
        theSameDay = false
        curDay = day
        return
    end
    if isNight() then
        if not theSameDay then
            theSameDay = true
            equipLight()
        end
    else
        theSameDay = false -- i dont know if this is necessary anyway..
    end
end

async:newUnsavableSimulationTimer(0.5, update)

option:subscribe(async:callback(function()
    core.sendGlobalEvent("TRANSPORTER_LIGHTS_EQUIP_LIGHT_EQNX", {
        self,
        option:get("Debug") and index
    })
end))
