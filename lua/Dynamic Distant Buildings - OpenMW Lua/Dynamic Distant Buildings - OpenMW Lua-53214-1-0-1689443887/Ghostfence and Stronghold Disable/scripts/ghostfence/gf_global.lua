local types = require("openmw.types")
local world = require("openmw.world")
local quests = types.Player.quests
local didCheck = false
if quests == nil then
    error("This version of OpenMW has no lua quest support. Update to the latest 0.49 or development release.")
end
local function getStrongState()
    local hr = quests(world.players[1])["hr_stronghold"].stage
    local ht = quests(world.players[1])["ht_stronghold"].stage
    local hh = quests(world.players[1])["hh_stronghold"].stage
    local sstage = math.max(hr, ht, hh)

    local stateMapping = {
        [300] = 6,
        [200] = 4,
        [100] = 2,
        [55] = 1,
    }

    local colonyState = stateMapping[sstage] or 0

    return colonyState
end
local function getColonyState()
    local stage = quests(world.players[1])["Colony_update"].stage
    local stage1 = quests(world.players[1])["CO_12a"].stage
    local stage2 = quests(world.players[1])["CO_12"].stage

    local stateMapping = {
        [10] = 2,
        [20] = 3,
        [30] = 5,
        [40] = 10,
        [50] = 20,
        [70] = 30,
        [60] = 21,
        [0] = 0
    }

    local colonyState = stateMapping[stage] or stateMapping[stage1] or stateMapping[stage2] or 0

    return colonyState
end
local function setColonyState(cellList)
    local state = getColonyState()
    print(state, "is")
    local conditions = {
        ["colony_d_1_f"] = state < 3,
        ["colony_d_1_i"] = state < 1,
        ["colony_d_1_m"] = state < 2,
        ["colony_d_1_mine"] = state == 1,
        ["colony_d_2_f"] = state < 10,
        ["colony_d_3_f"] = state < 20,
        ["colony_door_uryn"] = state >= 3,
        ["colony_e_1_f"] = state >= 3,
        ["colony_e_1_i"] = state >= 1,
        ["colony_e_1_m"] = state >= 1 and state < 3,
        ["colony_e_1_mine"] = state >= 2,
        ["colony_e_2_f"] = state >= 10,
        ["colony_e_2_m"] = state >= 3 and state < 10,
        ["colony_e_3_m"] = state >= 12 and state < 20,
        ["colony_e_3_f"] = state >= 20,
        ["colony_e_4_f"] = state >= 30,
        ["colony_e_4_m"] = state >= 22 and state < 30,
        ["colony_e_torch"] = state == 30,
        ["colony_first_boat"] = state >= 3,
        ["stronfg2_not"] = state < 3,
        ["colonyfactor1_d"] = state ~= 31 and state ~= 34,
        ["colonyfactor1_final"] = state == 34,
        ["colonyfactor1_mid"] = state == 31,
        ["colonyfactor2_d"] = state ~= 32 and state ~= 35,
        ["colonyfactor2_final"] = state == 35,
        ["colonyfactor2_mid"] = state == 32,
        ["colonyfactor3_d"] = state ~= 33 and state ~= 36,
        ["colonyfactor3_final"] = state >= 36,
        ["colonyfactor3_mid"] = state == 33,
    }
    for index, cell in ipairs(cellList) do
        for index, obj in ipairs(cell:getAll()) do
            if obj.type == types.NPC or obj.type == types.Creature then
                --We don't care about actors, they can be disabled when they are in render range
            else
                local scr = obj.type.record(obj).mwscript
                if scr and conditions[scr] ~= nil then
                    obj.enabled = conditions[scr]
                elseif scr and conditions[scr] == nil and state == 0 and scr ~= "" then
                    obj.enabled = false
                end
            end
        end
    end
end
local uhscr = {}
local function setStrongCellState(cell)
    local state = getStrongState()
    print(state, "state is")
    local conditions = {
        ["strong1"] = state > 0,
        ["strong2"] = state > 2,
        ["strong3"] = state > 4,
        ["strong1_construct"] = state == 1,
        ["strong2_construct"] = state == 3,
        ["strong3_construct"] = state == 5,
        ["strong1_complete"] = state >= 2,
        ["strong2_complete"] = state >= 4,
        ["strong3_complete"] = state >= 6,
        ["strong1_only"] = state == 2,
        ["strong2_only"] = state == 4,
        ["strong3_only"] = state == 6,
        ["strong2_not"] = state < 3,
        ["strong3_not"] = state < 5
    }

    for index, obj in ipairs(cell:getAll()) do
        if obj.type == types.NPC or obj.type == types.Creature then
            --We don't care about actors, they can be disabled when they are in render range
        else
            local scr = obj.type.record(obj).mwscript
            if scr and conditions[scr] ~= nil then
                obj.enabled = conditions[scr]
            elseif scr and conditions[scr] == nil and state == 0 and scr ~= "" then
                if not uhscr[scr] then
                    print("Unhandled script: " .. scr)
                end
                uhscr[scr] = true
                obj.enabled = false
            end
        end
    end
end
--TODO: Add script to Azura/MSQ related object, to trigger the ghostfence disabling when that happens.
local fenceCells = { { x = -3, y = 9 }, { x = -3, y = 10 }, { x = -3, y = 11 }, { x = -2, y = 9 }, { x = -2, y = 11 },
    { x = -1, y = 8 }, { x = -1, y = 9 }, { x = -1, y = 11 }, { x = -1, y = 12 }, { x = 0, y = 5 }, { x = 0, y = 6 },
    { x = 0, y = 7 }, { x = 0, y = 8 }, { x = 0, y = 12 }, { x = 1, y = 4 }, { x = 1, y = 6 }, { x = 1, y = 7 },
    { x = 1, y = 11 }, { x = 2, y = 4 }, { x = 2, y = 11 }, { x = 2, y = 12 }, { x = 3, y = 4 }, { x = 3, y = 5 },
    { x = 3, y = 11 }, { x = 3, y = 12 }, { x = 4, y = 5 }, { x = 4, y = 6 }, { x = 4, y = 7 }, { x = 4, y = 11 },
    { x = 5, y = 7 }, { x = 5, y = 8 }, { x = 5, y = 9 }, { x = 5, y = 10 }, { x = 5, y = 11 } }
local function disableFence()
    local fences = 0
    local nofence = 0
    local dataString = ""
    for index, cellLoc in ipairs(fenceCells) do
        local cell = world.getExteriorCell(cellLoc.x, cellLoc.y)
        local activators = cell:getAll(types.Activator)
        local scrName = "GhostfenceScript"
        local thisCell = false
        for index, obj in ipairs(activators) do
            if (obj.type.record(obj).mwscript:lower() == scrName:lower()) then
                obj.enabled = false
                thisCell = true
                local formattedString = string.format("{id = '%s', cf = '%s'},", obj.id, obj.contentFile)
                dataString = dataString .. formattedString
            end
        end
        if thisCell == true then
            -- print(x,y,cell.name)
            fences = fences + 1
        else
            nofence = nofence + 1
        end
    end
    print("changed this amount of cells: ", fences)
    print("did not changed this amount of cells: ", nofence)
    print(dataString)
end
local function killActivators(cell)
    local activators = cell:getAll(types.Activator)
    local scrName = "GhostfenceScript"
    for index, obj in ipairs(activators) do
        if (obj.type.record(obj).mwscript == "" or obj.type.record(obj).mwscript == nil) then
            --if object has no script, we shouldn't disable it
        else
            local obId = obj.recordId
            if not string.find(obId, "tree") then
                obj.enabled = false --Raven rock has trees that are disabled as the building is completed, so will have to keep those.
            end
        end
    end
    for index, obj in ipairs(cell:getAll(types.Light)) do
        if (obj.type.record(obj).mwscript == "" or obj.type.record(obj).mwscript == nil) then

        else
            obj.enabled = false
        end
    end

    for index, obj in ipairs(cell:getAll(types.Door)) do
        if (obj.type.record(obj).mwscript == "" or obj.type.record(obj).mwscript == nil) then

        else
            obj.enabled = false
        end
    end

    for index, obj in ipairs(cell:getAll(types.Container)) do
        if (obj.type.record(obj).mwscript == "" or obj.type.record(obj).mwscript == nil) then

        else
            if (types.Container.capacity(obj) > 0) then
                obj.enabled = false
            end
        end
    end
end
local function updateRavenRock()

   -- local ravenRock = { world.getExteriorCell(-25, 19), world.getExteriorCell(-24, 19), world.getExteriorCell(-25, 18) }
   local ravenRock = {}
   for index, value in ipairs(world.cells) do
    if value.name == "Raven Rock" then
table.insert(ravenRock,value)
    end
   end
    setColonyState(ravenRock)
end
local function updateStrongholds()
    local tel = world.getExteriorCell(10, 1)
    local balIsra = world.getExteriorCell(-5, 9)
    local odai = world.getExteriorCell(-5, -5)

    setStrongCellState(tel)
    setStrongCellState(balIsra)
    setStrongCellState(odai)
end
local function onSave()
    return { didCheck = didCheck }
end
local function onPlayerAdded(player)
    if (didCheck == false) then
        if (quests(world.players[1])["C3_DestroyDagoth"].stage >= 20) then --check if the main quest was completed before loading this mod
            disableFence()
        end
    else
        return
    end
    updateRavenRock()   --Set raven rock objects to initial state
    updateStrongholds() --set stronghold objects to intial state
    print("check is made")
    didCheck = true
end
local function onLoad(data)
    print("Load")
    if (data) then
        didCheck = data.didCheck
    end
end
return {
    interfaceName  = "Ghostfence_ZHAC",
    interface      = {
        version = 1,
        disableFence = disableFence,
        killActivators = killActivators,
        onPlayerAdded = onPlayerAdded,
        updateRavenRock = updateRavenRock
    },
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers  = {
        disableFence_X = disableFence,
        updateStrongholds = updateStrongholds,
        updateRavenRock = updateRavenRock,
        onPlayerAdded = onPlayerAdded,
    },
}
