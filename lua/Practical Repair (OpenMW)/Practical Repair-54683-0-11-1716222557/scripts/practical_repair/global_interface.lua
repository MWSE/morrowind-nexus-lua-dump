local core = require("openmw.core")
local world = require("openmw.world")
local aux_util = require("openmw_aux.util")

local l10n = core.l10n("practical_repair")

local activationBlock = setmetatable({}, {
    __index = function()
        return {}
    end
})

local stations = {{
    id = "furn_anvil00",
    name = l10n("PracticalRepair_Anvil"),
    tool = "hammer"
}, {
    id = "furn_t_fireplace_01",
    name = l10n("PracticalRepair_Forge"),
    tool = "prong"
}, {
    id = "furn_de_forge_01",
    name = l10n("PracticalRepair_Forge"),
    tool = "prong"
}, {
    id = "furn_de_bellows_01",
    name = l10n("PracticalRepair_Forge"),
    tool = "prong"
}, {
    id = "Furn_S_forge",
    name = l10n("PracticalRepair_Forge"),
    tool = "prong"
}}

local help = [[
    addStation(arg): Adds a repair station to the mod database.
    Added stations are not persistent between sessions.
    I.PracticalRepair_eqnx.addStation({
        id = "my_workstation_recordid",
        name = "my_workstation_name",
        tool = "prong_hammer_anypattern"
    })

    registeredStations: Prints all registered stations
    I.PracticalRepair_eqnx.registeredStations

    stationsInfo: Prints all location of registered stations
    I.PracticalRepair_eqnx.stationsInfo

    blockActivation(obj): Increments activation block counter for the object
    I.PracticalRepair_eqnx.blockActivation(world.players[1])

    info: Prints info about the mod
]]

return {
    interfaceName = "PracticalRepair_eqnx",
    interface = setmetatable({}, {
        __index = function(_, key)
            if key == "info" then
                return tostring(require("scripts.practical_repair.modInfo"))
            end
            if key == "help" then
                return help
            end
            if key == "registeredStations" then
                return aux_util.deepToString(stations, 2)
            end
            if key == "addStation" then
                return function(arg)
                    assert(arg.id, "Please provide id of the station.")
                    assert(arg.tool, "Please provide tool for the station")
                    assert(arg.name, "Please provide name for the station")
                    print(string.format("[Practical Repair] Adding station: %s [%s]", arg.id, arg.tool))

                    table.insert(stations, arg)

                    for _, player in pairs(world.players) do
                        player:sendEvent("PracticalRepair_updateStation_eqnx", {
                            id = arg.id,
                            name = arg.name
                        })
                    end
                end
            end
            if key == "stationsInfo" then
                local stationIds = {}
                local str = ""
                for _, station in pairs(stations) do
                    stationIds[station.id] = station.tool
                end
                for _, cell in pairs(world.cells) do
                    for _, object in pairs(cell:getAll()) do
                        if stationIds[object.recordId] then
                            str = str .. object.recordId ..
                                      string.format(" [%s] ---> [%s]\n", stationIds[object.recordId], cell.name)
                        end
                    end
                end
                return str
            end
            if key == "stations" then
                return stations
            end
            if key == "blockActivation" then
                return function(player)
                    assert(player, "No game object provided")
                    if #activationBlock[player.id] == 0 then
                        activationBlock[player.id] = {}
                    end
                    table.insert(activationBlock[player.id], true)
                end
            end
            if key == "activationBlock" then
                return activationBlock
            end
        end
    })
}
