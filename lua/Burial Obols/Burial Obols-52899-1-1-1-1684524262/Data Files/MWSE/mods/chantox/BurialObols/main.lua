local log = require("chantox.BurialObols.log")
local config = require("chantox.BurialObols.config")
require("chantox.BurialObols.mcm")

---Gets all cells whose id contains "Ancestral Tomb"
local function getTombs()
    log:trace("Getting tombs...")
    local tombs = {}
    local count = 0
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if string.find(cell.displayName, "Ancestral Tomb") and cell.isInterior then
            table.insert(tombs, cell.id)
            count = count + 1
        end
    end
    log:debug("Found " .. count .. " tombs")
    return tombs
end

---@param cell tes3cell
---@return string|nil refid
local function tryPlaceCoin(cell)
    log:trace("Start tryPlaceCoin at " .. cell.id)
    local chests = {} -- First priority
    local backup = {} -- Second priority
    for _, ref in pairs(cell.statics) do
        local type = ref.object.objectType
        if type == tes3.objectType.container then
            if not ref.object.organic and not ref.object.respawns then
                if (string.sub(ref.object.name, 1, 3) == "Urn" or
                    string.sub(ref.object.name, 1, 4) == "Sack") then
                    table.insert(backup, ref)
                else
                    table.insert(chests, ref)
                end
            end
        end
    end

    local container
    if #chests == 0 then
        if #backup == 0 then
            log:debug("Failed to find appropriate container.")
            return nil
        end
        container = backup[math.random(1, #backup)]
    else
        container = chests[math.random(1, #chests)]
    end
    log:debug("Chose container " .. container.id)
    tes3.addItem{reference = container, item = "BurialObols_coin_lucky"}
    return container.id
end

---@param e cellChangedEventData
local function onCellChanged(e)
    if not e.cell.isInterior then
        return
    end

    local data = tes3.player.data
    for index, value in ipairs(data.burialObols.selection) do
        if e.cell.id == value then
            log:trace("Entered lucky tomb")
            log:debug("Removing tomb " .. data.burialObols.selection[index])
            table.remove(data.burialObols.selection, index)
            local containerId = tryPlaceCoin(e.cell)

            -- If coin placement fails, select a new tomb
            if not containerId then
                if #data.burialObols.backup > 0 then
                    local j = math.random(1, #data.burialObols.backup)
                    local backup = table.remove(data.burialObols.backup, j)
                    table.insert(data.burialObols.selection, backup)
                    log:debug("Inserted backup tomb " .. backup)
                end
            end

            -- If no tombs with coins remain, our job is done
            if #data.burialObols.selection == 0 then
                log:debug("All coins placed, unregistering...")
                data.burialObols.backup = {}
                event.unregister(tes3.event.cellChanged, onCellChanged)
            end
            return
        end
    end
end

local function onLoaded()
    local data = tes3.player.data
    if data.burialObols then
        if #data.burialObols.selection == 0 and #data.burialObols.backup == 0 then
            log:debug("All coins placed, unregistering...")
            event.unregister(tes3.event.cellChanged, onCellChanged)
            return
        end

        log:debug("Selected tombs: ")
        for _, value in ipairs(data.burialObols.selection) do
            log:debug(value)
        end
        return
    end

    log:trace("Setting up initial player data...")
    data.burialObols = {}
    data.burialObols.backup = getTombs()
    data.burialObols.selection = {}
    for i = 1, config.amount do
        if #data.burialObols.backup > 0 then
            local j = math.random(1, #data.burialObols.backup)
            data.burialObols.selection[i] = table.remove(data.burialObols.backup, j)
        else
            log:warn("Located " .. #data.burialObols.selection .. "/" .. config.amount .. " tombs")
            break
        end
    end

    log:debug("Selected tombs:")
    for _, value in ipairs(data.burialObols.selection) do
        log:debug(value)
    end
end

local function onInitialized()
    event.register(tes3.event.loaded, onLoaded)
    event.register(tes3.event.cellChanged, onCellChanged)

    log:info("Initialized.")
end
event.register(tes3.event.initialized, onInitialized)
