-- scripts/BookWorm/player.lua
--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org>.
--]]

local input = require('openmw.input')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local aux_ui = require('openmw_aux.ui')
local ui = require('openmw.ui') 
local ambient = require('openmw.ambient') 
local storage = require('openmw.storage')
local async = require('openmw.async')

local L = core.l10n('BookWorm', 'en')
local utils = require('scripts.BookWorm.utils')
local ui_library = require('scripts.BookWorm.ui_library')
local scanner = require('scripts.BookWorm.scanner')
local state_manager = require('scripts.BookWorm.state_manager') 
local handler = require('scripts.BookWorm.input_handler')
local invScanner = require('scripts.BookWorm.inventory_scanner')
local reader = require('scripts.BookWorm.reader')
local ui_handler = require('scripts.BookWorm.ui_handler')
local remote = require('scripts.BookWorm.remote_manager')
local transition = require('scripts.BookWorm.transition_handler')
local scanner_ctrl = require('scripts.BookWorm.scanner_controller')

local booksRead, notesRead = {}, {}
local activeWindow, activeMode = nil, nil
local masterTotals = nil
local searchString = ""
local isSearchActive = false
local isDebug = false

-- Added tracking for the currently open container/target for the unread list
local currentOpenContainer = nil

local sessionState = {
    InventoryDiscoveryMessage = "none"
}

local uiSettings = storage.playerSection("Settings_BookWorm_UI")
local keySettings = storage.playerSection("Settings_BookWorm_Keys")
local notifSettings = storage.playerSection("Settings_BookWorm_Notif")

local cfg = {
    itemsPerPage = uiSettings:get("itemsPerPage"),
    unreadMaxList = uiSettings:get("unreadMaxList"),
    openTomesKey = keySettings:get("openTomesKey"):lower(),
    openLettersKey = keySettings:get("openLettersKey"):lower(),
    prevPageKey = keySettings:get("prevPageKey"):lower(),
    nextPageKey = keySettings:get("nextPageKey"):lower(),
    listUnreadKey = keySettings:get("listUnreadKey"):lower(), 
    displayNotificationMessage = notifSettings:get("displayNotificationMessage"),
    displayNotificationMessageOnReading = notifSettings:get("displayNotificationMessageOnReading"),
    throttleInventoryNotifications = notifSettings:get("throttleInventoryNotifications"),
    playNotificationSounds = notifSettings:get("playNotificationSounds"),
    recognizeSkillBooks = notifSettings:get("recognizeSkillBooks"),
    showSkillNames = notifSettings:get("showSkillNames"),
    playSkillNotificationSounds = notifSettings:get("playSkillNotificationSounds")
}

local bookFilter, noteFilter = utils.FILTER_NONE, utils.FILTER_NONE
local bookPage, notePage = 1, 1

local function updateConfig()
    cfg.itemsPerPage = uiSettings:get("itemsPerPage")
    cfg.unreadMaxList = uiSettings:get("unreadMaxList")
    cfg.openTomesKey = keySettings:get("openTomesKey"):lower()
    cfg.openLettersKey = keySettings:get("openLettersKey"):lower()
    cfg.prevPageKey = keySettings:get("prevPageKey"):lower()
    cfg.nextPageKey = keySettings:get("nextPageKey"):lower()
    cfg.listUnreadKey = keySettings:get("listUnreadKey"):lower() 
    cfg.displayNotificationMessage = notifSettings:get("displayNotificationMessage")
    cfg.displayNotificationMessageOnReading = notifSettings:get("displayNotificationMessageOnReading")
    cfg.throttleInventoryNotifications = notifSettings:get("throttleInventoryNotifications")
    cfg.playNotificationSounds = notifSettings:get("playNotificationSounds")
    cfg.recognizeSkillBooks = notifSettings:get("recognizeSkillBooks")
    cfg.showSkillNames = notifSettings:get("showSkillNames")
    cfg.playSkillNotificationSounds = notifSettings:get("playSkillNotificationSounds")
end

local function getClampedPage(dataMap, currentPage)
    local count = 0
    for _ in pairs(dataMap) do count = count + 1 end
    local max = math.max(1, math.ceil(count / cfg.itemsPerPage))
    return math.min(currentPage, max)
end

uiSettings:subscribe(async:callback(function(section, key)
    updateConfig()
    if key == "itemsPerPage" then
        bookPage = getClampedPage(booksRead, bookPage)
        notePage = getClampedPage(notesRead, notePage)
        if activeWindow then
            core.sendEvent('BookWorm_JumpToPage', { mode = activeMode, page = (activeMode == "TOMES" and bookPage or notePage) })
        end
    end
end))

keySettings:subscribe(async:callback(function(section, key)
    updateConfig()
    if key:match("Key$") then
        if activeWindow then
            aux_ui.deepDestroy(activeWindow)
            activeWindow, activeMode = nil, nil
            I.UI.setMode(nil)
        end
    end
end))

notifSettings:subscribe(async:callback(function(section, key)
    updateConfig()
    if activeWindow then
        refreshUI(false, true)
    end
end))

local function initializeState()
    bookFilter, noteFilter = utils.FILTER_NONE, utils.FILTER_NONE
    bookPage, notePage = 1, 1
    searchString = ""
    isSearchActive = false
    masterTotals = state_manager.buildMasterList(utils) 
end

local function refreshUI(isSearchUpdate, isFilterUpdate)
    local targetFilter = (activeMode == "TOMES" and bookFilter or noteFilter)
    local targetPage = (activeMode == "TOMES" and bookPage or notePage)
    
    if isSearchUpdate then
        if activeMode == "TOMES" then bookPage = 1 else notePage = 1 end
        targetPage = 1
    end

    activeWindow, activeMode = handler.toggleWindow({
        activeWindow=activeWindow, activeMode=activeMode, mode=activeMode, 
        booksRead=booksRead, notesRead=notesRead, 
        bookPage=targetPage, notePage=targetPage, 
        itemsPerPage=cfg.itemsPerPage,
        openTomesKey = cfg.openTomesKey,
        openLettersKey = cfg.openLettersKey,
        prevPageKey = cfg.prevPageKey,
        nextPageKey = cfg.nextPageKey,
        utils=utils, masterTotals=masterTotals, 
        activeFilter=targetFilter, searchString=searchString,
        isSearchChange = isSearchUpdate, 
        isFilterChange = isFilterUpdate,
        isSearchActive = isSearchActive
    })
end

return {
    interfaceName = "BookWorm",
    interface = {
        toggleDebug = function()
            isDebug = not isDebug
            print("[BookWorm] Debug mode: " .. tostring(isDebug))
        end,
        getDebug = function() return isDebug end
    },
    engineHandlers = {
        onInterfaceOverride = function(base)
            return base
        end,

        onInit = function()
            booksRead, notesRead = {}, {}
            initializeState()
        end,

        onSave = function() return { booksRead = booksRead, notesRead = notesRead, saveTimestamp = core.getSimulationTime() } end,
        
        onLoad = function(data)
            isDebug = false
            local loaded = state_manager.processLoad(data, utils)
            booksRead, notesRead = loaded.books, loaded.notes
            sessionState.InventoryDiscoveryMessage = "none"
            initializeState()
        end,

        onUpdate = function(dt) 
            if transition.check({ activeWindow = activeWindow, remote = remote, self = self }) then 
                activeWindow, activeMode = nil, nil 
                return 
            end
            scanner_ctrl.update(dt, { 
                scanner = scanner, 
                utils = utils, 
                booksRead = booksRead, 
                notesRead = notesRead,
                cfg = cfg 
            })
        end,

        onKeyPress = function(key)
            if activeWindow and isSearchActive then
                if key.code == input.KEY.Enter then
                    isSearchActive = false
                    refreshUI(false, true)
                    ambient.playSound("book page2")
                elseif key.code == input.KEY.Backspace then
                    searchString = searchString:sub(1, -2)
                    refreshUI(true, false)
                    ambient.playSound("book page2")
                elseif key.symbol and key.symbol:match("[%a%d%-%_% ]") and #searchString < 30 then
                    searchString = searchString .. key.symbol
                    refreshUI(true, false)
                    ambient.playSound("book page2")
                end
                return
            end

            local symbol = key.symbol:lower()
            if symbol == cfg.openTomesKey or symbol == cfg.openLettersKey then
                if not masterTotals then masterTotals = state_manager.buildMasterList(utils) end

                local newMode = (symbol == cfg.openTomesKey) and "TOMES" or "LETTERS"
                if input.isShiftPressed() then
                    local rawLabel = (newMode == "TOMES") and L('Player_Label_Tomes') or L('Player_Label_Letters')
                    if newMode == "TOMES" then state_manager.exportBooks(booksRead, utils)
                    else state_manager.exportLetters(notesRead, utils) end
                    ui.showMessage(L('Player_Msg_Export_Success', {label = rawLabel}))
                else
                    searchString = ""
                    isSearchActive = false
                    local targetFilter = (newMode == "TOMES" and bookFilter or noteFilter)
                    local targetPage = (newMode == "TOMES" and bookPage or notePage)
                    activeWindow, activeMode = handler.toggleWindow({
                        activeWindow=activeWindow, activeMode=activeMode, mode=newMode, 
                        booksRead=booksRead, notesRead=notesRead, bookPage=targetPage, notePage=targetPage, 
                        itemsPerPage=cfg.itemsPerPage,
                        openTomesKey = cfg.openTomesKey,
                        openLettersKey = cfg.openLettersKey,
                        prevPageKey = cfg.prevPageKey,
                        nextPageKey = cfg.nextPageKey,
                        utils=utils, masterTotals=masterTotals, 
                        activeFilter=targetFilter, searchString=searchString, isSearchActive = isSearchActive
                    })
                    I.UI.setMode(activeWindow and 'Interface' or nil, {windows = {}})
                end
                return
            end

            if activeWindow then
                if key.code == input.KEY.Backspace then
                    isSearchActive = true
                    refreshUI(false, true)
                    ambient.playSound("book page2")
                elseif symbol == cfg.prevPageKey or symbol == cfg.nextPageKey then
                    local mockKey = { code = (symbol == cfg.nextPageKey and input.KEY.O or input.KEY.I) }
                    local win, page = handler.handlePagination(mockKey, {
                        activeWindow=activeWindow, activeMode=activeMode, booksRead=booksRead, 
                        notesRead=notesRead, bookPage=bookPage, notePage=notePage, 
                        itemsPerPage=cfg.itemsPerPage,
                        openTomesKey = cfg.openTomesKey,
                        openLettersKey = cfg.openLettersKey,
                        prevPageKey = cfg.prevPageKey,
                        nextPageKey = cfg.nextPageKey,
                        utils=utils, masterTotals=masterTotals,
                        activeFilter=(activeMode == "TOMES" and bookFilter or noteFilter), 
                        searchString=searchString, isSearchActive = isSearchActive
                    })
                    activeWindow = win
                    if activeMode == "TOMES" then bookPage = page else notePage = page end
                end
            else
                if symbol == cfg.listUnreadKey then
                    local uiMode = I.UI.getMode()
                    if uiMode == "Container" or uiMode == "Barter" or uiMode == "Interface" then
                        ui_handler.showUnreadList({
                            mode = uiMode,
                            target = currentOpenContainer,
                            self = self,
                            booksRead = booksRead,
                            notesRead = notesRead,
                            utils = utils,
                            cfg = cfg
                        })
                    end
                    return
                end
            end
        end
    },
    eventHandlers = {
        BookWorm_ManualMark = function(obj) reader.mark(obj, booksRead, notesRead, utils) end,
        BookWorm_RemoteRead = function(data)
            if activeWindow then remote.handleAudio(true); aux_ui.deepDestroy(activeWindow); activeWindow, activeMode = nil, nil end
            remote.request(data.recordId:lower(), self, utils.isLoreNote(data.recordId:lower()))
        end,
        BookWorm_OpenRemoteUI = function(data)
            remote.set(data.recordId:lower(), data.target)
            I.UI.setMode(data.mode, { target = data.target })
        end,
        BookWorm_JumpToPage = function(data)
            if not activeWindow then return end
            if data.mode == "TOMES" then bookPage = data.page else notePage = data.page end
            local currentFilter = (data.mode == "TOMES" and bookFilter or noteFilter)
            activeWindow, activeMode = handler.toggleWindow({
                activeWindow=activeWindow, activeMode=activeMode, mode=data.mode, 
                booksRead=booksRead, notesRead=notesRead, bookPage=bookPage, notePage=notePage,
                itemsPerPage=cfg.itemsPerPage,
                openTomesKey = cfg.openTomesKey,
                openLettersKey = cfg.openLettersKey,
                prevPageKey = cfg.prevPageKey,
                nextPageKey = cfg.nextPageKey,
                utils=utils, masterTotals=masterTotals,
                isJump = true, activeFilter=currentFilter, searchString=searchString, isSearchActive = isSearchActive
            })
            ambient.playSound("book page2")
        end,
        BookWorm_ChangeFilter = function(data)
            if not activeMode or isSearchActive then return end
            if activeMode == "TOMES" then
                bookFilter = (bookFilter == data.filter) and utils.FILTER_NONE or data.filter
                bookPage = 1
            else
                noteFilter = (noteFilter == data.filter) and utils.FILTER_NONE or data.filter
                notePage = 1
            end
            refreshUI(false, true)
            ambient.playSound("book page2")
        end,
        UiModeChanged = function(data)
            if data.newMode == "Container" or data.newMode == "Barter" then
                currentOpenContainer = data.arg
            elseif data.newMode == nil or data.newMode == "Interface" then
                currentOpenContainer = nil
            end

            local rId, rTarget = remote.get()
            local result = ui_handler.handleModeChange(data, {
                activeWindow = activeWindow, lastLookedAtObj = scanner_ctrl.getLastLookedAt(),
                booksRead = booksRead, notesRead = notesRead, currentRemoteRecordId = rId, currentRemoteTarget = rTarget,
                reader = reader, invScanner = invScanner, utils = utils, self = self,
                cfg = cfg,
                sessionState = sessionState,
                isDebug = isDebug
            })
            if result == "CLOSE_LIBRARY" then activeWindow, activeMode = nil, nil
            elseif result == "CLEANUP_GHOST" then remote.cleanup(self); remote.handleAudio(false) end
        end
    }
}
