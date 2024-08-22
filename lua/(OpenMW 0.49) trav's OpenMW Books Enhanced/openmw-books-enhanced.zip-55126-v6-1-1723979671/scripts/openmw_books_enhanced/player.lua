local I = require('openmw.interfaces')
local book_window = require('scripts.openmw_books_enhanced.window.book_window')
local callback_creator = require('scripts.openmw_books_enhanced.outside_manipulators.callback_creator')
local nonmouse_controller = require('scripts.openmw_books_enhanced.outside_manipulators.nonmouse_controller')
local mousewheel = require("scripts.openmw_books_enhanced.outside_manipulators.mousewheel_handler")
local post_opening_actions = require("scripts.openmw_books_enhanced.outside_manipulators.post_opening_actions")
local style_chooser = require('scripts.openmw_books_enhanced.ui_layout.style_chooser')
local book_interface_overrides = require('scripts.openmw_books_enhanced.outside_manipulators.book_interface_overrides')
local read_status_checker = require('scripts.openmw_books_enhanced.outside_manipulators.read_status_checker')
local text_parser = require('scripts.openmw_books_enhanced.wording.text_parser')
local item_taker = require("scripts.openmw_books_enhanced.outside_manipulators.item_taker")

local documentWindow = nil
local savedDataForThisMod = {}

local function updateDocumentWindowInPlayerScript()
    if documentWindow == nil then
        return
    end
    documentWindow:update()
end

local function destroyDocumentWindow()
    if documentWindow then
        documentWindow:destroy()
        documentWindow = nil
    end
end

local function disableVanillaDocumentWindows()
    local replacedWindows = { "Book", "Scroll" }
    for _, windowName in pairs(replacedWindows) do
        I.UI.registerWindow(
            windowName,
            function()
                --when switching from journal to document
                if documentWindow and documentWindow.layout and documentWindow.layout.props and not documentWindow.layout.props.visible then
                    documentWindow.layout.props.visible = true
                    updateDocumentWindowInPlayerScript()
                    return
                end

                documentWindow = book_interface_overrides.createWindowForSituationsWhenBookDidntLoadDueToQuickKeyUsage()
            end,
            function()
                if documentWindow == nil then
                    return
                end

                --when switching from document to journal
                if I.UI.getMode() == "Journal" then
                    documentWindow.layout.props.visible = false
                    updateDocumentWindowInPlayerScript()
                    return
                end

                destroyDocumentWindow()
            end
        )
    end
end

local function onBookOpened(data)
    destroyDocumentWindow()
    if book_interface_overrides.wasBookUiOverridenBySomething() then
        return
    end

    local chosenDocumentWindowStyle = style_chooser.chooseDocumentWindowStyle(data.activatedBookObject)
    documentWindow = book_window.createBookWindow(data.activatedBookObject, chosenDocumentWindowStyle)
    callback_creator.applyWindowCallbacks(data.activatedBookObject, documentWindow)
    text_parser.applyBookObjectTextToWindow(data.activatedBookObject, documentWindow, chosenDocumentWindowStyle)
    nonmouse_controller.initiateNonMouseControls(documentWindow)
    post_opening_actions.applyPostOpeningActions(data.activatedBookObject, savedDataForThisMod)
end

return {
    engineHandlers = {
        onActive = function()
            disableVanillaDocumentWindows()
        end,
        onFrame = function()
            read_status_checker.runReadStatusCheckerOnPointedItem(savedDataForThisMod)
        end,
        onLoad = function(savedData)
            if savedData ~= nil then
                savedDataForThisMod = savedData
            end
        end,
        onSave = function()
            return savedDataForThisMod
        end,
        onMouseWheel = function(x, y)
            if documentWindow == nil
                or documentWindow.layout == nil
                or (documentWindow.layout.props ~= nil and not documentWindow.layout.props.visible)
                or x == 0
            then
                return
            end
            mousewheel.manipulateDocumentWindowBasedOnMouseWheelTurn(documentWindow, x)
            updateDocumentWindowInPlayerScript()
        end,
        onKeyPress = function(key)
            if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then return end
            nonmouse_controller.allowReactingToInputs()
        end,
        onKeyRelease = function(key)
            if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then return end
            nonmouse_controller.reactToKeyboardKey(documentWindow, key)
        end,

        onControllerButtonPress = function(controllerButton)
            if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then return end
            nonmouse_controller.allowReactingToInputs()
        end,
        onControllerButtonRelease = function(controllerButton)
            if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.props == nil or not documentWindow.layout.props.visible then return end
            nonmouse_controller.reactToControllerKey(documentWindow, controllerButton)
        end,
    },
    eventHandlers = {
        openmwBooksEnhancedBookActivated = onBookOpened,
        openmwBooksEnhancedRemoveTempStolenItem = item_taker.handleCrimeHackCleanup,
    },
}
