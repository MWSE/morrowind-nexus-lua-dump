local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")
local settings = require("scripts.openmw_books_enhanced.settings")
local page_setter = require("scripts.openmw_books_enhanced.outside_manipulators.page_setter")
local util = require('openmw.util')
local ambient = require('openmw.ambient')

local RSS = {}

function RSS.shiftSpaceUp(documentWindow)
    if
        documentWindow == nil
        or documentWindow.layout == nil
        or documentWindow.layout.content == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace] == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside] == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside].userData == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside].props == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside].props.position == nil
    then
        return
    end

    local boundaryHeight = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size.y
    local readableHeight = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
        [content_name.leftPage.pageReadableSpaceInside].userData.height
    local currentYPosition = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
        [content_name.leftPage.pageReadableSpaceInside].props.position.y
    local limit = 0

    if currentYPosition >= limit or readableHeight <= boundaryHeight then
        return
    end

    local amountToShiftBy = settings.SettingsTravOpenmwBooksEnhanced_scrollRatio() *
        settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()

    documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
    [content_name.leftPage.pageReadableSpaceInside].props.position = util.vector2(0, currentYPosition + amountToShiftBy)
end

function RSS.shiftSpaceDown(documentWindow)
    if
        documentWindow == nil
        or documentWindow.layout == nil
        or documentWindow.layout.content == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace] == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside] == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside].userData == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside].props == nil
        or documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content[content_name.leftPage.pageReadableSpaceInside].props.position == nil
    then
        return
    end

    local boundaryHeight = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size.y
    local readableHeight = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
        [content_name.leftPage.pageReadableSpaceInside].userData.height
    local currentYPosition = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
        [content_name.leftPage.pageReadableSpaceInside].props.position.y
    local limit = -(readableHeight - boundaryHeight)

    if currentYPosition <= limit or readableHeight <= boundaryHeight then
        return
    end

    local amountToShiftBy = settings.SettingsTravOpenmwBooksEnhanced_scrollRatio() *
        settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()

    documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
    [content_name.leftPage.pageReadableSpaceInside].props.position = util.vector2(0, currentYPosition - amountToShiftBy)
end

function RSS.shiftToNextPage(documentWindow)
    if
        documentWindow == nil
        or documentWindow.layout == nil
        or documentWindow.layout.userData == nil
        or documentWindow.layout.userData.lines == nil
        or #documentWindow.layout.userData.lines < 1
        or documentWindow.layout.userData.currentPageNumber == nil
    then
        return
    end

    local numberOfPages =
        documentWindow.layout.userData.lines[#documentWindow.layout.userData.lines].userData.page

    local newPageNumber = documentWindow.layout.userData.currentPageNumber
    if documentWindow.layout.content:indexOf(content_name.rightPageNumber) ~= nil then
        if numberOfPages % 2 == 0 then
            numberOfPages = numberOfPages - 1
        end
        newPageNumber = math.min(
            numberOfPages,
            documentWindow.layout.userData.currentPageNumber + 2
        )
    else
        newPageNumber = math.min(
            numberOfPages,
            documentWindow.layout.userData.currentPageNumber + 1
        )
    end

    if newPageNumber ~= documentWindow.layout.userData.currentPageNumber then
        documentWindow.layout.userData.currentPageNumber = newPageNumber
        page_setter.setPages(documentWindow)
        ambient.playSound("book page2")
    end
end

function RSS.shiftToPrevPage(documentWindow)
    if
        documentWindow == nil
        or documentWindow.layout == nil
        or documentWindow.layout.userData == nil
        or documentWindow.layout.userData.currentPageNumber == nil
    then
        return
    end

    local newPageNumber = documentWindow.layout.userData.currentPageNumber
    if documentWindow.layout.content:indexOf(content_name.rightPageNumber) ~= nil then
        newPageNumber = math.max(
            1,
            documentWindow.layout.userData.currentPageNumber - 2)
    else
        newPageNumber = math.max(
            1,
            documentWindow.layout.userData.currentPageNumber - 1)
    end

    if newPageNumber ~= documentWindow.layout.userData.currentPageNumber then
        documentWindow.layout.userData.currentPageNumber = newPageNumber
        page_setter.setPages(documentWindow)
        ambient.playSound("book page")
    end
end

return RSS
