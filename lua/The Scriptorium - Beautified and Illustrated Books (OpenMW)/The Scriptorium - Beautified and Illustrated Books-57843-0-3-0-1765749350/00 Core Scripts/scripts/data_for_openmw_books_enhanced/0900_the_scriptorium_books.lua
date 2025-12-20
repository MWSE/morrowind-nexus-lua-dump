-- Imports
local DocumentData = require('scripts.data_for_openmw_books_enhanced.0100_vanilla_book')
local readExternalText = require('scripts.the_scriptorium.read_external_text')
local storage = require('openmw.storage')

-- Settings storage
local generalSettingsKey = "TheScriptoriumGeneralSettings"
local storageGeneralSettings = storage.playerSection(generalSettingsKey)

-- Local variables
local bookId = nil
local baseShouldApplyTo = DocumentData.shouldApplyTo

-- Local data overrides
DocumentData.name = "TheScriptoriumBook"

DocumentData.shouldApplyTo = function(gameObject)
    -- Check if mod is globally enabled (default to true)
    local modEnabled = storageGeneralSettings:get('TheScriptoriumEnableMod')
    if not modEnabled then
        return false
    end
    
    -- Set book ID and use base logic
    bookId = gameObject.recordId:lower()
    return baseShouldApplyTo(gameObject)
end

DocumentData.modifyTextBeforeApplying = function(text)
    -- Check if calibration mode is on
    local calibrateMode = storageGeneralSettings:get('TheScriptoriumEnableCalibrateMode')

    if calibrateMode == true then
        -- Use calibration text in place of normal content
        local calibrateContent = readExternalText('debug_text_calibrate')
        if calibrateContent then
            return calibrateContent
        end
    end
    
    -- Normal mode: try to load book-specific external content
    local externalContent = readExternalText(bookId)
    if externalContent then
        return externalContent
    end
    
    -- Fallback to vanilla text
    return text
end

return DocumentData
