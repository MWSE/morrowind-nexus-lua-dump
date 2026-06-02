local modName = "Morrowind Reading"

local configModule = require("MorrowindReading.config")
local config = configModule.current

require("MorrowindReading.mcm")

-- Safety defaults for older saved configs.
if config.allowReadingFromList == nil then
    config.allowReadingFromList = true
end

if config.addScrollsToReadingList == nil then
    config.addScrollsToReadingList = false
end

if config.showTranslatedScrollText == nil then
    config.showTranslatedScrollText = false
end

local saveDataKey = "MorrowindReading"

local UI_ID_ReadingBlock = tes3ui.registerID("MorrowindReading:StatsBlock")
local UI_ID_ReadingLabel = tes3ui.registerID("MorrowindReading:StatsLabel")
local UI_ID_ReadingButton = tes3ui.registerID("MorrowindReading:StatsButton")

local UI_ID_ReadListMenu = tes3ui.registerID("MorrowindReading:ReadListMenu")
local UI_ID_ReadListClose = tes3ui.registerID("MorrowindReading:ReadListClose")
local UI_ID_ReadListPrev = tes3ui.registerID("MorrowindReading:ReadListPrev")
local UI_ID_ReadListNext = tes3ui.registerID("MorrowindReading:ReadListNext")

local UI_ID_BookViewerMenu = tes3ui.registerID("MorrowindReading:BookViewerMenu")
local UI_ID_BookViewerClose = tes3ui.registerID("MorrowindReading:BookViewerClose")
local UI_ID_BookViewerPrev = tes3ui.registerID("MorrowindReading:BookViewerPrev")
local UI_ID_BookViewerNext = tes3ui.registerID("MorrowindReading:BookViewerNext")

local readListPage = 1
local booksPerPage = 12
local bookViewerLinesPerPage = 18

local function getSaveData()
    tes3.player.data[saveDataKey] = tes3.player.data[saveDataKey] or {}
    tes3.player.data[saveDataKey].readBooks = tes3.player.data[saveDataKey].readBooks or {}

    return tes3.player.data[saveDataKey]
end

local function isBook(object)
    return object and object.objectType == tes3.objectType.book
end

local function isScroll(book)
    return isBook(book) and book.type == tes3.bookType.scroll
end

local function getBookId(book)
    if not book or not book.id then
        return nil
    end

    return string.lower(book.id)
end

local function shouldTrackObject(object)
    if not isBook(object) then
        return false
    end

    -- Scrolls are optional.
    if isScroll(object) and not config.addScrollsToReadingList then
        return false
    end

    return true
end

local function markBookRead(book)
    if not config.enabled then
        return
    end

    if not shouldTrackObject(book) then
        return
    end

    local bookId = getBookId(book)

    if not bookId then
        return
    end

    local data = getSaveData()

    if data.readBooks[bookId] then
        return
    end

    data.readBooks[bookId] = book.name or book.id

    mwse.log("[%s] Marked read: %s", modName, bookId)
end

local function hasReadBook(book)
    local bookId = getBookId(book)

    if not bookId then
        return false
    end

    local data = getSaveData()
    return data.readBooks[bookId] ~= nil
end

local function getSortedReadBooks()
    local data = getSaveData()
    local books = {}

    for bookId, bookName in pairs(data.readBooks) do
        local object = tes3.getObject(bookId)

        if object and isBook(object) then
            -- If scrolls are disabled, hide already-tracked scrolls from the list/count.
            if not isScroll(object) or config.addScrollsToReadingList then
                table.insert(books, {
                    id = bookId,
                    name = tostring(bookName == true and bookId or bookName),
                })
            end
        end
    end

    table.sort(books, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return books
end

local function countReadBooks()
    return #getSortedReadBooks()
end

local function stripBookMarkup(text)
    if not text then
        return ""
    end

    text = text:gsub("<BR>", "\n")
    text = text:gsub("<br>", "\n")
    text = text:gsub("<P>", "\n\n")
    text = text:gsub("<p>", "\n\n")
    text = text:gsub("<DIV>", "\n")
    text = text:gsub("<div>", "\n")
    text = text:gsub("<[^>]->", "")

    return text
end

local function splitTextIntoLines(text, maxLineLength)
    local lines = {}

    text = stripBookMarkup(text or "")

    for paragraph in text:gmatch("[^\n]+") do
        local line = ""

        for word in paragraph:gmatch("%S+") do
            if #line + #word + 1 > maxLineLength then
                if line ~= "" then
                    table.insert(lines, line)
                end

                line = word
            else
                if line == "" then
                    line = word
                else
                    line = line .. " " .. word
                end
            end
        end

        if line ~= "" then
            table.insert(lines, line)
        end

        table.insert(lines, "")
    end

    if #lines == 0 then
        table.insert(lines, "")
    end

    return lines
end

local function showBookViewer(bookId, page)
    local existing = tes3ui.findMenu(UI_ID_BookViewerMenu)

    if existing then
        existing:destroy()
    end

    local book = tes3.getObject(bookId)

    if not book or book.objectType ~= tes3.objectType.book then
        tes3.messageBox("Morrowind Reading: could not find book '%s'.", bookId)
        return
    end

    local viewerText = book.text

    if isScroll(book) and not config.showTranslatedScrollText then
        viewerText = "The scroll's text is unintelligible."
    end

    local lines = splitTextIntoLines(viewerText, 72)
    local totalPages = math.max(1, math.ceil(#lines / bookViewerLinesPerPage))

    local currentPage = page or 1

    if currentPage < 1 then
        currentPage = 1
    end

    if currentPage > totalPages then
        currentPage = totalPages
    end

    local startIndex = ((currentPage - 1) * bookViewerLinesPerPage) + 1
    local endIndex = math.min(startIndex + bookViewerLinesPerPage - 1, #lines)

    local menu = tes3ui.createMenu({
        id = UI_ID_BookViewerMenu,
        fixedFrame = true,
    })

    menu.width = 620
    menu.height = 620
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.paddingTop = 12
    menu.paddingBottom = 12
    menu.paddingLeft = 12
    menu.paddingRight = 12

    local title = menu:createLabel({
        text = book.name or book.id,
    })

    title.wrapText = true
    title.width = 580

    local pageLabel = menu:createLabel({
        text = string.format("Page %d / %d", currentPage, totalPages),
    })

    pageLabel.wrapText = false

    local bodyBlock = menu:createBlock({})
    bodyBlock.flowDirection = tes3.flowDirection.topToBottom
    bodyBlock.width = 580
    bodyBlock.height = 460
    bodyBlock.paddingTop = 8
    bodyBlock.paddingBottom = 8
    bodyBlock.paddingLeft = 8
    bodyBlock.paddingRight = 8

    for i = startIndex, endIndex do
        local label = bodyBlock:createLabel({
            text = lines[i],
        })

        label.wrapText = false
        label.width = 560
    end

    local buttonRow = menu:createBlock({})
    buttonRow.flowDirection = tes3.flowDirection.leftToRight
    buttonRow.autoHeight = true
    buttonRow.width = 580

    local prevButton = buttonRow:createButton({
        id = UI_ID_BookViewerPrev,
        text = "Previous",
    })

    prevButton.width = 110
    prevButton.height = 30

    prevButton:register(tes3.uiEvent.mouseClick, function()
        showBookViewer(bookId, currentPage - 1)
    end)

    local nextButton = buttonRow:createButton({
        id = UI_ID_BookViewerNext,
        text = "Next",
    })

    nextButton.width = 110
    nextButton.height = 30

    nextButton:register(tes3.uiEvent.mouseClick, function()
        showBookViewer(bookId, currentPage + 1)
    end)

    local closeButton = buttonRow:createButton({
        id = UI_ID_BookViewerClose,
        text = "Close",
    })

    closeButton.width = 100
    closeButton.height = 30

    closeButton:register(tes3.uiEvent.mouseClick, function()
        menu:destroy()
    end)

    if currentPage <= 1 then
        prevButton.disabled = true
    end

    if currentPage >= totalPages then
        nextButton.disabled = true
    end

    menu:updateLayout()
    tes3ui.enterMenuMode(UI_ID_BookViewerMenu)
end

local function showReadBookList()
    local existing = tes3ui.findMenu(UI_ID_ReadListMenu)

    if existing then
        existing:destroy()
    end

    local books = getSortedReadBooks()
    local totalBooks = #books
    local totalPages = math.max(1, math.ceil(totalBooks / booksPerPage))

    if readListPage > totalPages then
        readListPage = totalPages
    end

    if readListPage < 1 then
        readListPage = 1
    end

    local startIndex = ((readListPage - 1) * booksPerPage) + 1
    local endIndex = math.min(startIndex + booksPerPage - 1, totalBooks)

    local menu = tes3ui.createMenu({
        id = UI_ID_ReadListMenu,
        fixedFrame = true,
    })

    menu.width = 560
    menu.height = 520
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.paddingTop = 12
    menu.paddingBottom = 12
    menu.paddingLeft = 12
    menu.paddingRight = 12

    local title = menu:createLabel({
        text = string.format("Morrowind Reading - %d Books Read", totalBooks),
    })

    title.wrapText = false

    local pageLabel = menu:createLabel({
        text = string.format("Page %d / %d", readListPage, totalPages),
    })

    pageLabel.wrapText = false

    local listBlock = menu:createBlock({})
    listBlock.flowDirection = tes3.flowDirection.topToBottom
    listBlock.width = 520
    listBlock.height = 380
    listBlock.paddingTop = 8
    listBlock.paddingBottom = 8
    listBlock.paddingLeft = 8
    listBlock.paddingRight = 8

    if totalBooks == 0 then
        listBlock:createLabel({
            text = "No books read yet.",
        })
    else
        for i = startIndex, endIndex do
            local book = books[i]

            if config.allowReadingFromList then
                local button = listBlock:createButton({
                    text = book.name,
                })

                button.width = 500
                button.height = 24

                button:register(tes3.uiEvent.mouseClick, function()
                    showBookViewer(book.id, 1)
                end)
            else
                local label = listBlock:createLabel({
                    text = "- " .. book.name,
                })

                label.wrapText = true
                label.width = 500
            end
        end
    end

    local buttonRow = menu:createBlock({})
    buttonRow.flowDirection = tes3.flowDirection.leftToRight
    buttonRow.autoHeight = true
    buttonRow.width = 520

    local prevButton = buttonRow:createButton({
        id = UI_ID_ReadListPrev,
        text = "Previous",
    })

    prevButton.width = 110
    prevButton.height = 30

    prevButton:register(tes3.uiEvent.mouseClick, function()
        readListPage = readListPage - 1
        showReadBookList()
    end)

    local nextButton = buttonRow:createButton({
        id = UI_ID_ReadListNext,
        text = "Next",
    })

    nextButton.width = 110
    nextButton.height = 30

    nextButton:register(tes3.uiEvent.mouseClick, function()
        readListPage = readListPage + 1
        showReadBookList()
    end)

    local closeButton = buttonRow:createButton({
        id = UI_ID_ReadListClose,
        text = "Close",
    })

    closeButton.width = 100
    closeButton.height = 30

    closeButton:register(tes3.uiEvent.mouseClick, function()
        menu:destroy()
    end)

    if readListPage <= 1 then
        prevButton.disabled = true
    end

    if readListPage >= totalPages then
        nextButton.disabled = true
    end

    menu:updateLayout()
    tes3ui.enterMenuMode(UI_ID_ReadListMenu)
end

local function onBookGetText(e)
    markBookRead(e.book)
end

event.register(tes3.event.bookGetText, onBookGetText)

local function addTooltipLine(tooltip, text)
    if not tooltip then
        return
    end

    tooltip:createLabel({
        text = text,
    })

    tooltip:updateLayout()
end

local function onObjectTooltip(e)
    if not config.enabled then
        return
    end

    if not config.showTooltipStatus then
        return
    end

    local object = e.object

    if not shouldTrackObject(object) then
        return
    end

    if hasReadBook(object) then
        addTooltipLine(e.tooltip, "Read Status: Read")
    else
        addTooltipLine(e.tooltip, "Read Status: Unread")
    end
end

event.register(tes3.event.uiObjectTooltip, onObjectTooltip)

local function updateStatsMenu()
    local menu = tes3ui.findMenu("MenuStat")

    if not menu then
        return
    end

    local existing = menu:findChild(UI_ID_ReadingBlock)

    if existing then
        existing:destroy()
    end

    local block = menu:createBlock({
        id = UI_ID_ReadingBlock,
    })

    block.flowDirection = tes3.flowDirection.leftToRight
    block.autoHeight = true
    block.autoWidth = true
    block.paddingTop = 8
    block.paddingLeft = 8
    block.paddingRight = 8

    block:createLabel({
        id = UI_ID_ReadingLabel,
        text = string.format("Morrowind Reading: %d books read", countReadBooks()),
    })

    local button = block:createButton({
        id = UI_ID_ReadingButton,
        text = "Show List",
    })

    button.width = 100
    button.height = 24
    button.paddingLeft = 8

    button:register(tes3.uiEvent.mouseClick, function()
        showReadBookList()
    end)

    menu:updateLayout()
end

event.register(tes3.event.menuEnter, function()
    timer.delayOneFrame(updateStatsMenu)
end)

mwse.log("[%s] Initialized.", modName)