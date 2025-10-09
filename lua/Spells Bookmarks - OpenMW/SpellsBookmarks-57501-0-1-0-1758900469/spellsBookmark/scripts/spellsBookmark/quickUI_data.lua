local core = require('openmw.core')
local types = require('openmw.types')
local storage = require('openmw.storage')


--- @type {spell: {}, spellID: string}
local bookmarkedSpellIds = {}
local DATA_KEY = "quickUI_bookmarks"




-- print(storage.playerSection(DATA_KEY))
-- print(storage.playerSection('1p2ojeo1i2je'))

local ids = storage.playerSection(DATA_KEY):get('spellIds')
-- print("NEWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWw")
-- print('ids = ', ids)

local function saveData()
        local idsToSave = {}
        -- print('saving spells: ', bookmarkedSpellIds)

        for _, v in ipairs(bookmarkedSpellIds) do
                table.insert(idsToSave, v.id)
        end
        local data = storage.playerSection(DATA_KEY)
        data:set("spellIds", idsToSave)
end

local function loadData(actor)
        -- if next(bookmarkedSpellIds) ~= nil then
        --     return
        -- end

        local data = storage.playerSection(DATA_KEY)
        local savedIds = data:get("spellIds")
        -- print('loading spells: ', savedIds)
        if savedIds then
                -- for i = #bookmarkedSpellIds, 1, -1 do
                --     table.remove(bookmarkedSpellIds, i)
                -- end
                for _, id in ipairs(savedIds) do
                        local spell = types.Player.spells(actor)[id]
                        if spell then
                                table.insert(bookmarkedSpellIds, { id = spell.id, spell = spell })
                        end
                end
        end
end

return {
        bookmarkedSpellIds = bookmarkedSpellIds,
        saveData = saveData,
        loadData = loadData,
}
