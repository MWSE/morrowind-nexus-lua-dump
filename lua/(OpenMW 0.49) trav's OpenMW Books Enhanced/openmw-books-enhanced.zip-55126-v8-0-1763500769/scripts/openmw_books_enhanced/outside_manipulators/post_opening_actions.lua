local types = require('openmw.types')
local self = require('openmw.self')
local settings = require("scripts.openmw_books_enhanced.settings")

local M = {}

local function tryEquippingMagicSpellInBook(activatedBookObject)
    if not settings.SettingsTravOpenmwBooksEnhanced_equipEnchantments() then
        return
    end

    local bookRecord = types.Book.records[activatedBookObject.recordId]
    if not bookRecord or not bookRecord.enchant or bookRecord.enchant == "" then
        return
    end

    types.Actor.setSelectedEnchantedItem(self, activatedBookObject)
end

local function recordReadStatusForThisItemRecord(activatedBookObject, savedDataForThisMod)
    if not activatedBookObject
        or not activatedBookObject.recordId
        or not savedDataForThisMod then
        return
    end

    if not savedDataForThisMod.alreadyReadTexts then
        savedDataForThisMod.alreadyReadTexts = {}
    end

    savedDataForThisMod.alreadyReadTexts[activatedBookObject.recordId] = true
end

function M.applyPostOpeningActions(activatedBookObject, savedDataForThisMod)
    tryEquippingMagicSpellInBook(activatedBookObject)
    recordReadStatusForThisItemRecord(activatedBookObject, savedDataForThisMod)
end

return M
