local ui = require('openmw.ui')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local l10n = require('openmw.core').l10n("openmw_books_enhanced")
local templates = require("scripts.openmw_books_enhanced.ui_layout.ui_templates")
local window_sizer = require('scripts.openmw_books_enhanced.window.window_sizer')
local book_button = require('scripts.openmw_books_enhanced.window.book_button')
local book_readable = require('scripts.openmw_books_enhanced.window.book_readable')
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")
local settings = require("scripts.openmw_books_enhanced.settings")

local function deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for originalKey, originalValue in next, orig, nil do
            copy[deepCopy(originalKey)] = deepCopy(originalValue)
        end
    else
        copy = orig
    end
    return copy
end

local function addLeftPageTextBox(bookWindow, documentWindowData)
    book_readable.addReadableSpace(
        bookWindow,
        documentWindowData.pagesTextArrangement.page1,
        content_name.leftPage)
end

local function addRightPageTextBox(bookWindow, documentWindowData)
    if documentWindowData.pagesTextArrangement.page2 ~= nil then
        documentWindowData.pagesTextArrangement.page2.textArea.width =
            documentWindowData.pagesTextArrangement.page1.textArea.width
        documentWindowData.pagesTextArrangement.page2.textArea.height =
            documentWindowData.pagesTextArrangement.page1.textArea.height
        book_readable.addReadableSpace(
            bookWindow,
            documentWindowData.pagesTextArrangement.page2,
            content_name.rightPage)
    end
end

local function createPageNumberLeft(documentWindowData)
    return {
        name = content_name.leftPageNumber,
        template = templates.journalPageNumberText,
        props = {
            text = "123",
            position = util.vector2(
                documentWindowData.pagesTextArrangement.page1.pageNumber.posCenterX,
                documentWindowData.pagesTextArrangement.page1.pageNumber.posCenterY
            ),
        }
    }
end

local function createPageNumberRight(documentWindowData)
    return {
        name = content_name.rightPageNumber,
        template = templates.journalPageNumberText,
        props = {
            text = "456",
            position = util.vector2(
                documentWindowData.pagesTextArrangement.page2.pageNumber.posCenterX,
                documentWindowData.pagesTextArrangement.page2.pageNumber.posCenterY
            ),
        }
    }
end

local function createTakeButton(documentWindowData)
    local result = book_button.createJournalButton()
    result.name = content_name.takeButton
    result.props = {
        position = util.vector2(
            documentWindowData.takeButton.posCenterX,
            documentWindowData.takeButton.posCenterY
        ),
        text = l10n("Take")
    }
    return result
end

local function createPrevButton(documentWindowData)
    local result = book_button.createJournalButton()
    result.name = content_name.prevButton
    result.props = {
        position = util.vector2(
            documentWindowData.prevButton.posCenterX,
            documentWindowData.prevButton.posCenterY
        ),
        text = l10n("Prev")
    }
    return result
end

local function createNextButton(documentWindowData)
    local result = book_button.createJournalButton()
    result.name = content_name.nextButton
    result.props = {
        position = util.vector2(
            documentWindowData.nextButton.posCenterX,
            documentWindowData.nextButton.posCenterY
        ),
        text = l10n("Next")
    }
    return result
end

local function createCloseButton(documentWindowData)
    local result = book_button.createJournalButton()
    result.name = content_name.closeButton
    result.props = {
        position = util.vector2(
            documentWindowData.closeButton.posCenterX,
            documentWindowData.closeButton.posCenterY
        ),
        text = l10n("Close")
    }
    return result
end

local function addLeftPageNumber(bookWindow, documentWindowData)
    if documentWindowData.pagesTextArrangement.page1.textArea.isScrollableVertically then
        return
    end

    table.insert(bookWindow.content, createPageNumberLeft(documentWindowData))
end

local function addRightPageNumber(bookWindow, documentWindowData)
    if documentWindowData.pagesTextArrangement.page2 == nil then
        return
    end

    table.insert(bookWindow.content, createPageNumberRight(documentWindowData))
end

local function addPrevButton(bookWindow, documentWindowData)
    if documentWindowData.pagesTextArrangement.page1.textArea.isScrollableVertically then
        return
    end

    table.insert(bookWindow.content, createPrevButton(documentWindowData))
end

local function addNextButton(bookWindow, documentWindowData)
    if documentWindowData.pagesTextArrangement.page1.textArea.isScrollableVertically then
        return
    end

    table.insert(bookWindow.content, createNextButton(documentWindowData))
end

local function applyDocumentTexture(bookWindow, documentWindowData, activatedBookObject)
    if not settings.SettingsTravOpenmwBooksEnhanced_colorBookcover()
        or not documentWindowData.texture.colorable
        or not documentWindowData.getUiColoring then
        bookWindow.props.resource = ui.texture({ path = documentWindowData.texture.path })
        return
    end

    local colorableTexturePath =
        string.sub(documentWindowData.texture.path, 1, #documentWindowData.texture.path - 4) .. "_colorable.dds"
    local nonColorableTexturePath =
        string.sub(documentWindowData.texture.path, 1, #documentWindowData.texture.path - 4) .. "_nonColorable.dds"

    if not vfs.fileExists(colorableTexturePath) or not vfs.fileExists(nonColorableTexturePath) then
        bookWindow.props.resource = ui.texture({ path = documentWindowData.texture.path })
        return
    end

    local usedColor = documentWindowData.getUiColoring(activatedBookObject)
    if not usedColor then
        bookWindow.props.resource = ui.texture({ path = documentWindowData.texture.path })
        return
    end

    table.insert(bookWindow.content, {
        name = content_name.documentTextureColorable,
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = ui.texture { path = colorableTexturePath },
            visible = true,
            color = usedColor,
        },
    })
    table.insert(bookWindow.content, {
        name = content_name.documentTextureNonColorable,
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = ui.texture { path = nonColorableTexturePath },
            visible = true,
        },
    })
end

local J = {}

function J.createBookWindow(activatedBookObject, documentWindowData,BookIcon)
    local bookWindow = {
        layer = 'Windows',
        type = ui.TYPE.Image,
        props = {
            name="BookUI",
            size = util.vector2(documentWindowData.texture.width, documentWindowData.texture.height),
            --size = ui.screenSize(),
            --relativeSize = util.vector2(1,1),
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            visible = true,
        },
        content = {},
    }

	if BookIcon then
		bookWindow.content={{ type = ui.TYPE.Image, props = { visible=true, relativeSize = util.vector2(0.1, 0.1),relativePosition=util.vector2(0.5, 0.5),  anchor = (util.vector2(0.5, 0.5)), resource = ui.texture { path = BookIcon},}}}
	end

    applyDocumentTexture(bookWindow, documentWindowData, activatedBookObject)

    if documentWindowData.additionalWidgetsInDocumentUi then
        for _, widget in pairs(documentWindowData.additionalWidgetsInDocumentUi) do
            table.insert(bookWindow.content, deepCopy(widget))
        end
    end

--   table.insert(bookWindow.content, createTakeButton(documentWindowData))
--   table.insert(bookWindow.content, createCloseButton(documentWindowData))
    addLeftPageTextBox(bookWindow, documentWindowData)
--    addRightPageTextBox(bookWindow, documentWindowData)
--    addLeftPageNumber(bookWindow, documentWindowData)
--    addRightPageNumber(bookWindow, documentWindowData)
--    addPrevButton(bookWindow, documentWindowData)
--    addNextButton(bookWindow, documentWindowData)

    bookWindow.content = ui.content(bookWindow.content)
    local uiVal = ui.create(bookWindow)

    window_sizer.resizeDocumentWindowForUserSettings(uiVal.layout, documentWindowData)

    return uiVal
end

return J
