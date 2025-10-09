local types = require 'openmw.types'
local world = require 'openmw.world'

local NPCFightThreshold = 90
local CreatureFightThreshold = 83

--- Given a cell object, check the hostility ratings of all actors inside of it
---@param senderCell GameCell
---@return boolean hasLiveTargets whether or not the cell has active combat targets
local function cellHasCombatTargets(senderCell)
    local objects = senderCell:getAll()
    local foundLiveHostiles = 0

    for _, object in ipairs(objects) do
        local isNPC = types.NPC.objectIsInstance(object)
        local isCreature = types.Creature.objectIsInstance(object)

        if not isNPC and not isCreature then goto continue end

        local fightStat = object.type.stats.ai.fight(object)
        local fightLimit = isNPC and NPCFightThreshold or CreatureFightThreshold

        if fightStat.modified >= fightLimit and not object.type.isDead(object) then
            foundLiveHostiles = foundLiveHostiles + 1
        end

        ::continue::
    end

    return foundLiveHostiles > 0
end

--- Given a cell object, find all unique static Ids and content files which placed statics in the cell
---@param cell GameCell
---@return string[] addedStatics, string[] addedContentFiles
local function getStaticsInActorCell(cell)
    local uniqueStaticIds, uniqueContentFiles = {}, {}

    local addedStatics, addedContentFiles = {}, {}

    local staticsInCell = cell:getAll(types.Static)

    for _, static in ipairs(staticsInCell) do
        if not uniqueStaticIds[static.recordId] then
            addedStatics[#addedStatics + 1] = static.recordId
            uniqueStaticIds[static.recordId] = true
        end

        if not uniqueContentFiles[static.contentFile] then
            if static.contentFile and static.contentFile ~= '' then
                addedContentFiles[#addedContentFiles + 1] = static.contentFile:lower()
                uniqueContentFiles[static.contentFile] = true
            end
        end
    end

    return addedStatics, addedContentFiles
end

--- Finds the nearest associated region to a cell, returning it if one is found.
---@param cell GameCell
---@return string? nearestRegion
local function getNearestRegionForCell(cell)
    if cell.region ~= '' then return cell.region end

    local allDoors = cell:getAll(types.Door)

    local nearestRegion
    for _, door in ipairs(allDoors) do
        if not door.type.isTeleport(door) then goto CONTINUE end

        local targetCell = door.type.destCell(door)
        if targetCell.region ~= '' then
            nearestRegion = targetCell.region
            break
        end
        ::CONTINUE::
    end

    return nearestRegion
end

local Globals = world.mwscript.getGlobalVariables()

---@enum WeatherType
local WeatherType = {
    [0] = 'clear',
    [1] = 'cloudy',
    [2] = 'foggy',
    [3] = 'overcast',
    [4] = 'rain',
    [5] = 'thunder',
    [6] = 'ash',
    [7] = 'blight',
    [8] = 'snow',
    [9] = 'blizzard',
}

return {
    interfaceName = 'S3maphoreG',
    interface = {
        findCellMatches = function(pattern)
            local cellStr = ''

            for _, cell in ipairs(world.cells) do
                if cell.name
                    and cell.name ~= ''
                    and cell.name:lower():find(pattern)
                then
                    cellStr = ("%s['%s'] = true,\n"):format(cellStr, cell.name:lower():gsub("'", "\\'"))
                end
            end

            return cellStr
        end,

        cellHasCombatTargets = cellHasCombatTargets,

        getStaticsInActorCell = getStaticsInActorCell,
    },

    engineHandlers = {

        onUpdate = function()
            if Globals.S3maphoreWeatherTracker ~= -1 then
                local weatherName = WeatherType[Globals.S3maphoreWeatherTracker]

                for _, player in ipairs(world.players) do
                    player:sendEvent('S3maphoreWeatherChanged', weatherName)
                end

                Globals.S3maphoreWeatherTracker = -1
            end
        end,

    },

    eventHandlers = {
        S3maphoreCellChanged = function(sender)
            local senderCell = sender.cell
            local staticRecordIds, staticContentFiles = getStaticsInActorCell(senderCell)

            sender:sendEvent('S3maphoreCellDataUpdated', {
                staticList = {
                    contentFiles = staticContentFiles,
                    recordIds = staticRecordIds,
                },
                hasCombatTargets = cellHasCombatTargets(senderCell),
                nearestRegion = getNearestRegionForCell(senderCell),
            })
        end,

        -- This function seems like it could have some issues.
        -- It only determines if there are actors in the cell which are *likely* to engage the player, and doesn't take into account whether or not 
        -- any are actively fighting the player. But it's a useful heauristic to determine whether or not the player is *in* a dungeon or not.
        S3maphoreUpdateCellHasCombatTargets = function(sender)
            sender:sendEvent('S3maphoreCombatTargetsUpdated', cellHasCombatTargets(sender.cell))
        end,
    },
}
