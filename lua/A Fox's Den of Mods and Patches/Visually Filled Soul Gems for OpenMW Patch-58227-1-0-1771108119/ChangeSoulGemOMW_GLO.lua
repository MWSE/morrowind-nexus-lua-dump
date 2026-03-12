local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')

-- Mapping table for soul gem replacement
local soulGemMapping = {
    ['misc_soulgem_common'] = 'misc_soulgem_common_svnr',
    ['misc_soulgem_grand'] = 'misc_soulgem_grand_svnr',
    ['misc_soulgem_greater'] = 'misc_soulgem_greater_svnr',
    ['misc_soulgem_lesser'] = 'misc_soulgem_lesser_svnr',
    ['misc_soulgem_petty'] = 'misc_soulgem_petty_svnr',
}

-- Function to replace soul gems
local function ChangeSoulGem(item)
    local Cell = item.cell
    local Position = item.position
    local Rotation = item.rotation
    local Soul = types.Miscellaneous.getSoul(item)

    local OwnerID = item.owner.recordId
    local OwnerFactionId = item.owner.factionId
    local OwnerFactionRank = item.owner.factionRank

    local newSoulGemId = soulGemMapping[item.recordId]

    if newSoulGemId then
        local NewSoulGem = world.createObject(newSoulGemId, item.count)
        if NewSoulGem then
            item:remove(item.count)
            NewSoulGem:teleport(Cell, Position, Rotation)
            types.Miscellaneous.setSoul(NewSoulGem, Soul)

            NewSoulGem.owner.recordId = OwnerID
            NewSoulGem.owner.factionId = OwnerFactionId
            NewSoulGem.owner.factionRank = OwnerFactionRank
        end
    end
end


return {
    engineHandlers = {
        onItemActive = function(item)
            if soulGemMapping[item.recordId] and types.Miscellaneous.getSoul(item) then
                ChangeSoulGem(item)
            end
        end,
    }
}