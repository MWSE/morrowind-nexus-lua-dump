local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")
local templates = require("scripts.openmw_books_enhanced.ui_layout.ui_templates")
local util = require('openmw.util')
local ui = require('openmw.ui')

local function makePage(documentWindow, pageNumber, contentName)
    local linesForPage = {}
    local accumulatedLineWidth = 0
    local accumulatedLineHeight = 0
    for _, line in pairs(documentWindow.layout.userData.lines) do
        if line.userData.page == pageNumber then
            table.insert(linesForPage, line)
            accumulatedLineWidth = math.max(accumulatedLineWidth, line.userData.width)
            accumulatedLineHeight = accumulatedLineHeight + line.userData.height
        end
    end
    return {
        name = contentName.pageReadableSpaceInside,
        template = templates.journalPageText,
        props = {
            position = util.vector2(0, 0),
        },
        userData = {
            width = accumulatedLineWidth,
            height = accumulatedLineHeight,
        },
        content = ui.content(linesForPage)
    }
end

local PS = {}

function PS.setPages(documentWindow)
    documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content = ui.content({
        makePage(documentWindow, documentWindow.layout.userData.currentPageNumber, content_name.leftPage)
    })

    if documentWindow.layout.content:indexOf(content_name.leftPageNumber) ~= nil then
        documentWindow.layout.content[content_name.leftPageNumber].props.text =
            tostring(documentWindow.layout.userData.currentPageNumber)
    end

    if documentWindow.layout.content:indexOf(content_name.rightPageNumber) ~= nil then
        documentWindow.layout.content[content_name.rightPageNumber].props.text =
            tostring(documentWindow.layout.userData.currentPageNumber + 1)
    end

    if documentWindow.layout.content:indexOf(content_name.rightPage.pageReadableSpace) ~= nil then
        if documentWindow.layout.userData.lines
            and #documentWindow.layout.userData.lines > 0
            and documentWindow.layout.userData.currentPageNumber + 1 <= documentWindow.layout.userData.lines[#documentWindow.layout.userData.lines].userData.page then
            documentWindow.layout.content[content_name.rightPage.pageReadableSpace].content = ui.content({
                makePage(documentWindow, documentWindow.layout.userData.currentPageNumber + 1, content_name.rightPage)
            })
        else
            documentWindow.layout.content[content_name.rightPage.pageReadableSpace].content = ui.content({})
        end
    end

    if documentWindow.layout.content:indexOf(content_name.prevButton) ~= nil then
        documentWindow.layout.content[content_name.prevButton].props.visible = (documentWindow.layout.userData.currentPageNumber ~= 1)
    end
    if documentWindow.layout.content:indexOf(content_name.nextButton) ~= nil then
        local numberOfPages = 0
        if documentWindow.layout.userData.lines and #documentWindow.layout.userData.lines > 0 then
            numberOfPages = documentWindow.layout.userData.lines[#documentWindow.layout.userData.lines].userData.page
        end
        local shouldShowNextButton = (documentWindow.layout.userData.currentPageNumber < numberOfPages)
        if documentWindow.layout.content:indexOf(content_name.rightPageNumber) ~= nil and numberOfPages % 2 == 0 then
            shouldShowNextButton = (documentWindow.layout.userData.currentPageNumber + 1 < numberOfPages)
        end
        documentWindow.layout.content[content_name.nextButton].props.visible = shouldShowNextButton
    end
    if documentWindow.layout.content:indexOf(content_name.leftPage.pageScrollbarDownButton_BORDER) ~= nil then
        local boundaryHeight = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size.y
        local readableHeight = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].content
            [content_name.leftPage.pageReadableSpaceInside].userData.height

        local shouldShowScrolling = (readableHeight >= boundaryHeight)
        documentWindow.layout.content[content_name.leftPage.pageScrollbarUpButton_BORDER].props.visible =
            shouldShowScrolling
        documentWindow.layout.content[content_name.leftPage.pageScrollbarElevator_BORDER].props.visible =
            shouldShowScrolling
        documentWindow.layout.content[content_name.leftPage.pageScrollbarDownButton_BORDER].props.visible =
            shouldShowScrolling
    end
end

return PS
