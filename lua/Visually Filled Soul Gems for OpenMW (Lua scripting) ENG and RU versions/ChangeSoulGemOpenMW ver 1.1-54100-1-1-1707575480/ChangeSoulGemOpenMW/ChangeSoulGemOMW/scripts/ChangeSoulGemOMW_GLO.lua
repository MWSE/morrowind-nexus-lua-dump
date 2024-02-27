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
	local OwnerID = item.ownerRecordId
	local OwnerFactionId = item.ownerFactionId
	local OwnerFactionRank = item.ownerFactionRank
    local newSoulGemId = soulGemMapping[item.recordId]

    if newSoulGemId then -- Check if there is a mapping for the item
        local NewSoulGem = world.createObject(newSoulGemId,item.count)
        if NewSoulGem then -- If the new soul gem was created successfully
            item:remove(item.count)
            NewSoulGem:teleport(Cell, Position, Rotation)
            types.Miscellaneous.setSoul(NewSoulGem, Soul)
            NewSoulGem.ownerRecordId = OwnerID
            NewSoulGem.ownerFactionId = OwnerFactionId
            NewSoulGem.ownerFactionRank = OwnerFactionRank
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