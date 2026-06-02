local core = require('openmw.core')
local input = require('openmw.input')
local storage = require('openmw.storage')

local browserUi = require('scripts.ItemBrowser.ui')

local GENERAL_SECTION = 'Settings/ItemBrowser/1_General'

local function generalSettings()
    return storage.playerSection(GENERAL_SECTION)
end

local function enabled()
    return generalSettings():get('Enabled') ~= false
end

local function openKey()
    return generalSettings():get('OpenKey') or input.KEY.I
end

browserUi.setCallbacks({
    search = function(data)
        core.sendGlobalEvent('ItemBrowser_SearchRequest', data)
    end,
    details = function(data)
        core.sendGlobalEvent('ItemBrowser_DetailRequest', data)
    end,
    add = function(data)
        core.sendGlobalEvent('ItemBrowser_AddItemRequest', data)
    end,
})

local function onKeyPress(e)
    if browserUi.handleKeyPress(e) then
        return
    end

    local key = openKey()
    if browserUi.isOpen() then
        if enabled() and e.code == key then
            browserUi.requestCloseFromOpenKey()
        end
        return
    end

    if enabled() and e.code == key then
        browserUi.open()
    end
end

local function onKeyRelease(e)
    browserUi.handleKeyRelease(e)
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onFrame = function(dt)
            browserUi.onFrame(dt)
        end,
        onMouseWheel = function(vertical)
            browserUi.onMouseWheel(vertical)
        end,
    },
    eventHandlers = {
        ItemBrowser_SearchResults = function(data)
            browserUi.setResults(data)
        end,
        ItemBrowser_SearchError = function(data)
            browserUi.showSearchError(data)
        end,
        ItemBrowser_ItemDetails = function(data)
            browserUi.setItemDetails(data)
        end,
        ItemBrowser_AddResult = function(data)
            browserUi.showAddResult(data)
        end,
    },
}
