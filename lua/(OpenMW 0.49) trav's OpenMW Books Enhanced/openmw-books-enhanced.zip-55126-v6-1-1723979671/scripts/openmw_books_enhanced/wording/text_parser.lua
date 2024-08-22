local types = require('openmw.types')
local phrase_splitting = require('scripts.openmw_books_enhanced.wording.phrase_splitting')
local record_text_modifier = require('scripts.openmw_books_enhanced.wording.record_text_modifier')
local text_arrangement = require('scripts.openmw_books_enhanced.window.page_text_arrangement')
local page_setter = require("scripts.openmw_books_enhanced.outside_manipulators.page_setter")

local TP = {}

function TP.applyBookObjectTextToWindow(activatedBookObject, documentWindow, documentWindowData)
    if documentWindow.layout.userData == nil then
        documentWindow.layout.userData = {}
    end

    local bookRecord = types.Book.records[activatedBookObject.recordId]
    local modifiedBookRecord = record_text_modifier.tryToReplaceWithFilledValues(bookRecord)
    if modifiedBookRecord then
        modifiedBookRecord = record_text_modifier.overwriteNewlines(modifiedBookRecord)
    else
        modifiedBookRecord = record_text_modifier.overwriteNewlines(bookRecord)
    end

    if documentWindowData.modifyTextBeforeApplying ~= nil then
        if modifiedBookRecord then
            modifiedBookRecord = { text = documentWindowData.modifyTextBeforeApplying(modifiedBookRecord.text) }
        else
            modifiedBookRecord = { text = documentWindowData.modifyTextBeforeApplying(bookRecord.text) }
        end
    end

    local splitPhrases = nil
    if modifiedBookRecord then
        splitPhrases = phrase_splitting.splitToPhraseWidgets(modifiedBookRecord)
    else
        splitPhrases = phrase_splitting.splitToPhraseWidgets(bookRecord)
    end
    documentWindow.layout.userData.lines = text_arrangement.createLinesSplitIntoPages(documentWindow, splitPhrases)
    documentWindow.layout.userData.currentPageNumber = 1

    page_setter.setPages(documentWindow)
end

return TP
