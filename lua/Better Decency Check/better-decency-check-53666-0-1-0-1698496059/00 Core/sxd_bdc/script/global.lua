local world = require'openmw.world'

local PlayerNoClothes = require'sxd_bdc.event.PlayerNoClothes'
local PlayerSomeClothes = require'sxd_bdc.event.PlayerSomeClothes'

local HOLDING_CELL_NAME = 'SxD_BDC_HoldingCell'
-- In OpenMW record IDs are always returned in lowercase when queried,
-- so these names need to be stored here like this for comparisons.
local NO_CLOTHES_FAIRY_NAME = 'sxd_bdc_noclothesfairy'
local SOME_CLOTHES_FAIRY_NAME = 'sxd_bdc_someclothesfairy'

local function teleportFairyToPlayer(fairyName, player)
    local fairyObject

    for _, object in ipairs(world.getCellByName(HOLDING_CELL_NAME):getAll()) do
        if object.recordId == fairyName then
            fairyObject = object
            break
        end
    end

    if fairyObject == nil then
        error(
            string.format(
                'Did not find object of record %s in cell %s',
                fairyName,
                HOLDING_CELL_NAME
            )
        )
    end

    fairyObject:teleport(player.cell.name, player.position)
end

return {
    eventHandlers = {
        [PlayerNoClothes.eventName] = function(eventData)
            teleportFairyToPlayer(NO_CLOTHES_FAIRY_NAME, eventData.player)
        end,
        [PlayerSomeClothes.eventName] = function(eventData)
            teleportFairyToPlayer(SOME_CLOTHES_FAIRY_NAME, eventData.player)
        end
    }
}
