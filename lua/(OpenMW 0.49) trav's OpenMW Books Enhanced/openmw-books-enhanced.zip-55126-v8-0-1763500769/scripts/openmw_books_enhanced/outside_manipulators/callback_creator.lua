local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")
local readable_space_shifter = require("scripts.openmw_books_enhanced.outside_manipulators.readable_space_shifter")
local item_taker = require("scripts.openmw_books_enhanced.outside_manipulators.item_taker")
local I = require('openmw.interfaces')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local self = require('openmw.self')

local function applyWindowUpdateCallback(widget, documentWindow)
    if widget.userData == nil then
        widget.userData = {}
    end
    widget.userData.callUpdateWindow = function()
        if documentWindow == nil then
            return
        end
        documentWindow:update()
    end
end

local function closeBookOrScroll(documentWindow)
    if I.UI.getMode() == "Scroll" then
        I.UI.removeMode("Scroll")
    else
        I.UI.removeMode("Book")
    end
    if documentWindow then
        documentWindow:destroy()
        documentWindow = nil
    end
end

local function applyCloseButtonCallbacks(documentWindow)
    if documentWindow.layout.content:indexOf(content_name.closeButton) ~= nil then
        applyWindowUpdateCallback(documentWindow.layout.content[content_name.closeButton], documentWindow)
        documentWindow.layout.content[content_name.closeButton].userData.onClicking = function()
            closeBookOrScroll(documentWindow)
        end
    end
end

local function applyTakeButtonCallbacks(activatedBookObject, documentWindow)
    if documentWindow.layout.content:indexOf(content_name.takeButton) ~= nil then
        if activatedBookObject.parentContainer == self.object then
            documentWindow.layout.content[content_name.takeButton].props.visible = false
            return
        end

        applyWindowUpdateCallback(documentWindow.layout.content[content_name.takeButton], documentWindow)
        documentWindow.layout.content[content_name.takeButton].userData.onClicking = function()
            item_taker.takeItem(activatedBookObject)
            closeBookOrScroll(documentWindow)
        end
    end
end

local function applyPrevButtonCallbacks(documentWindow)
    if documentWindow.layout.content:indexOf(content_name.prevButton) ~= nil then
        applyWindowUpdateCallback(documentWindow.layout.content[content_name.prevButton], documentWindow)
        documentWindow.layout.content[content_name.prevButton].userData.onClicking = function()
            readable_space_shifter.shiftToPrevPage(documentWindow)
        end
    end
end

local function applyNextButtonCallbacks(documentWindow)
    if documentWindow.layout.content:indexOf(content_name.nextButton) ~= nil then
        applyWindowUpdateCallback(documentWindow.layout.content[content_name.nextButton], documentWindow)
        documentWindow.layout.content[content_name.nextButton].userData.onClicking = function()
            readable_space_shifter.shiftToNextPage(documentWindow)
        end
    end
end

local function applyScrollUpCallback(documentWindow)
    if documentWindow.layout.content:indexOf(content_name.leftPage.pageScrollbarUpButton_BORDER) ~= nil then
        applyWindowUpdateCallback(
            documentWindow.layout.content[content_name.leftPage.pageScrollbarUpButton_BORDER].content
            [content_name.leftPage.pageScrollbarUpButton],
            documentWindow)

        documentWindow.layout.content[content_name.leftPage.pageScrollbarUpButton_BORDER].content
        [content_name.leftPage.pageScrollbarUpButton].events =
        {
            mouseClick = async:callback(function(e, thisObject)
                ambient.playSound("menu click")
                readable_space_shifter.shiftSpaceUp(documentWindow)
                thisObject.userData.callUpdateWindow()
            end)
        }
    end
end

local function applyScrollDownCallback(documentWindow)
    if documentWindow.layout.content:indexOf(content_name.leftPage.pageScrollbarDownButton_BORDER) ~= nil then
        applyWindowUpdateCallback(
            documentWindow.layout.content[content_name.leftPage.pageScrollbarDownButton_BORDER].content
            [content_name.leftPage.pageScrollbarDownButton],
            documentWindow)

        documentWindow.layout.content[content_name.leftPage.pageScrollbarDownButton_BORDER].content
        [content_name.leftPage.pageScrollbarDownButton].events =
        {
            mouseClick = async:callback(function(e, thisObject)
                ambient.playSound("menu click")
                readable_space_shifter.shiftSpaceDown(documentWindow)
                thisObject.userData.callUpdateWindow()
            end)
        }
    end
end

local X = {}

function X.applyWindowCallbacks(activatedBookObject, documentWindow)
    if documentWindow == nil or documentWindow.layout == nil or documentWindow.layout.content == nil then
        return
    end

    applyCloseButtonCallbacks(documentWindow)
    applyTakeButtonCallbacks(activatedBookObject, documentWindow)
    applyPrevButtonCallbacks(documentWindow)
    applyNextButtonCallbacks(documentWindow)
    applyScrollUpCallback(documentWindow)
    applyScrollDownCallback(documentWindow)
end

return X
