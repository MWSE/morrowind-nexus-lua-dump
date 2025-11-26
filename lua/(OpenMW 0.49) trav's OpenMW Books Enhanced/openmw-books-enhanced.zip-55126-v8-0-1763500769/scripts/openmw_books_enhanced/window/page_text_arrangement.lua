local ui = require('openmw.ui')
local util = require('openmw.util')
local ui_text = require("scripts.openmw_books_enhanced.ui_layout.ui_text")
local settings = require("scripts.openmw_books_enhanced.settings")
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")
local PhraseType = require("scripts.openmw_books_enhanced.wording.phrase_type")

local function tryResizingImage(imageWidget, pageSize)
    local function multiplyImageSizeBy(mult)
        imageWidget.props.size = imageWidget.props.size * mult
        imageWidget.userData.width = imageWidget.props.size.x
        imageWidget.userData.height = imageWidget.props.size.y
    end

    local resizeMultiplier = settings.SettingsTravOpenmwBooksEnhanced_imageSizeMult()
    multiplyImageSizeBy(resizeMultiplier)

    if ((imageWidget.userData.width < pageSize.x)
         and settings.SettingsTravOpenmwBooksEnhanced_expandImageToWidth()
         and (imageWidget.userData.width >= pageSize.x * settings.SettingsTravOpenmwBooksEnhanced_expandThreshold()))
    or ((imageWidget.userData.width > pageSize.x) and settings.SettingsTravOpenmwBooksEnhanced_shrinkImageToWidth()) then
        local resizeMultiplier = pageSize.x / imageWidget.props.size.x
        multiplyImageSizeBy(resizeMultiplier)
        return
    end
end

local function makeLineWidget(line, pureTextHeight, alignment)
    local lineWidth = 0.0
    local lineHeight = 0.0
    for _, phrase in pairs(line) do
        if phrase.userData ~= nil or phrase.userData.width ~= nil then
            if phrase.userData.height == nil then
                phrase.userData.height = pureTextHeight
            end
            lineWidth = lineWidth + phrase.userData.width
            lineHeight = math.max(lineHeight, phrase.userData.height)
        end
    end
    return {
        type = ui.TYPE.Flex,
        props = {
            size = util.vector2(0, 0),
            horizontal = true,
            relativeSize = util.vector2(1.0, 1.0),
            align = alignment,
        },
        userData = {
            width = lineWidth,
            height = lineHeight,
        },
        content = ui.content(line)
    }
end

local function insertPhraseIntoLine(currentLine, phrase)
    table.insert(currentLine, phrase)
end

local function insertGatheredWhitespaces(currentLine, encounteredWhitespaces)
    for _, whitespace in pairs(encounteredWhitespaces) do
        table.insert(currentLine, whitespace)
    end
end

local function insertPreparedLine(lines, currentLine, pureTextHeight, alignment)
    if #currentLine <= 0 then
        return
    end
    table.insert(lines, makeLineWidget(currentLine, pureTextHeight, alignment))
end

local function shortenTooLongPhrases(splitPhrases, lineWidthLimit)
    local cutAtPercentage = 0.5

    local indicesOfPhrasesWhichAreLongerThanLineWidthLimit = {}
    local idxForCuttingPhrases = 1
    while idxForCuttingPhrases <= #splitPhrases do
        if splitPhrases[idxForCuttingPhrases].userData.type ~= PhraseType.IMAGE and splitPhrases[idxForCuttingPhrases].userData.width > lineWidthLimit then
            -- print("LONG PHRASE", "phraseWidth:" .. splitPhrases[idxForCuttingPhrases].userData.width,
            --     "lineLimit:" .. lineWidthLimit,
            --     ">>" .. splitPhrases[idxForCuttingPhrases].props.text .. "<<")
            table.insert(indicesOfPhrasesWhichAreLongerThanLineWidthLimit, idxForCuttingPhrases)
        end
        idxForCuttingPhrases = idxForCuttingPhrases + 1
    end
    if #indicesOfPhrasesWhichAreLongerThanLineWidthLimit < 1 then
        return splitPhrases
    end

    local result = {}

    idxForCuttingPhrases = 1
    local idxOfGatheredIndices = 1
    while idxForCuttingPhrases <= #splitPhrases do
        if idxForCuttingPhrases == indicesOfPhrasesWhichAreLongerThanLineWidthLimit[idxOfGatheredIndices] then
            local longPhrase = splitPhrases[idxForCuttingPhrases]
            local newWidth = math.ceil(longPhrase.userData.width * cutAtPercentage)
            local numberOfGlyphs = 0
            for currentCharacterStep, thisCharacterByte in utf8.codes(longPhrase.props.text) do
                numberOfGlyphs = numberOfGlyphs + 1
            end
            local halvedNumberOfGlyphs = math.ceil(numberOfGlyphs * cutAtPercentage) + 1
            -- print("new width:", newWidth, "text length:", numberOfGlyphs, ">>" .. longPhrase.props.text .. "<<")

            numberOfGlyphs = 0
            local startForSecondHalf = 1
            for currentCharacterStep, _ in utf8.codes(longPhrase.props.text) do
                numberOfGlyphs = numberOfGlyphs + 1
                if halvedNumberOfGlyphs == numberOfGlyphs then
                    local firstHalf = {
                        template = longPhrase.template,
                        props = {
                            text = string.sub(longPhrase.props.text, 1, currentCharacterStep - 1),
                            textSize = longPhrase.props.textSize
                        },
                        userData = longPhrase.userData,
                    }
                    firstHalf.userData.width = newWidth
                    if longPhrase.content then
                        firstHalf.content = {}
                        for idx = 1, halvedNumberOfGlyphs, 1 do
                            table.insert(firstHalf.content, longPhrase.content[idx])
                        end
                        firstHalf.content = ui.content(firstHalf.content)
                    end
                    table.insert(result, firstHalf)
                    startForSecondHalf = currentCharacterStep
                end
            end
            local secondHalf = {
                template = longPhrase.template,
                props = {
                    text = string.sub(longPhrase.props.text, startForSecondHalf, #longPhrase.props.text),
                    textSize = longPhrase.props.textSize
                },
                userData = longPhrase.userData,
            }
            secondHalf.userData.width = newWidth
            if longPhrase.content then
                secondHalf.content = {}
                for idx = halvedNumberOfGlyphs + 1, #longPhrase.content, 1 do
                    table.insert(secondHalf.content, longPhrase.content[idx])
                end
                secondHalf.content = ui.content(secondHalf.content)
            end
            table.insert(result, secondHalf)

            idxOfGatheredIndices = idxOfGatheredIndices + 1
        else
            table.insert(result, splitPhrases[idxForCuttingPhrases])
        end
        idxForCuttingPhrases = idxForCuttingPhrases + 1
    end

    return result
end

local function createLines(documentWindow, splitPhrases)
    local pureTextHeight = settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()

    local lines = {}
    local lineWidthLimit = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size.x

    splitPhrases = shortenTooLongPhrases(splitPhrases, lineWidthLimit)

    local currentLine = {}
    local lineWidthSoFar = 0
    local encounteredWhitespaces = {}
    local currentAlignment = ui.ALIGNMENT.Start
    for idx, phrase in ipairs(splitPhrases) do
        if phrase.userData.type == PhraseType.ALIGN_LEFT then
            currentAlignment = ui.ALIGNMENT.Start
        elseif phrase.userData.type == PhraseType.ALIGN_CENTER then
            currentAlignment = ui.ALIGNMENT.Center
        elseif phrase.userData.type == PhraseType.ALIGN_RIGHT then
            currentAlignment = ui.ALIGNMENT.End
        elseif phrase.userData.type == PhraseType.DOUBLE_NEWLINE then
            insertPreparedLine(lines, currentLine, pureTextHeight, currentAlignment)
            encounteredWhitespaces = {}
            currentLine = {}
            lineWidthSoFar = 0
            insertPhraseIntoLine(currentLine, phrase)
            insertPreparedLine(lines, currentLine, pureTextHeight, currentAlignment)
            lines[#lines].userData.isDoubleNewline = true
            currentLine = {}
        elseif phrase.userData.type == PhraseType.NEWLINE then
            insertPreparedLine(lines, currentLine, pureTextHeight, currentAlignment)
            encounteredWhitespaces = {}
            currentLine = {}
            lineWidthSoFar = 0
        elseif phrase.userData.type == PhraseType.WHITESPACE then
            table.insert(encounteredWhitespaces, phrase)
        elseif phrase.userData.type == PhraseType.PUNCTUATION and #encounteredWhitespaces == 0 then
            insertPhraseIntoLine(currentLine, phrase)
            lineWidthSoFar = lineWidthSoFar + 0 + phrase.userData.width
        else
            local widthOfWhitespacesBeforeThisPhrase = 0
            for _, whitespace in pairs(encounteredWhitespaces) do
                widthOfWhitespacesBeforeThisPhrase = widthOfWhitespacesBeforeThisPhrase + whitespace.userData.width
            end
            local wouldThisPhraseFitIntoTheLine =
                ((lineWidthSoFar + widthOfWhitespacesBeforeThisPhrase + phrase.userData.width) < lineWidthLimit)
            if wouldThisPhraseFitIntoTheLine then
                insertGatheredWhitespaces(currentLine, encounteredWhitespaces)
                if phrase.userData.height and phrase.userData.type == PhraseType.IMAGE then
                    tryResizingImage(
                        phrase,
                        documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size)
                end
                insertPhraseIntoLine(currentLine, phrase)
                lineWidthSoFar = lineWidthSoFar + widthOfWhitespacesBeforeThisPhrase + phrase.userData.width
            else
                insertPreparedLine(lines, currentLine, pureTextHeight, currentAlignment)
                currentLine = {}
                lineWidthSoFar = 0
                if phrase.userData.height and phrase.userData.type == PhraseType.IMAGE then
                    tryResizingImage(
                        phrase,
                        documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size)
                end
                insertPhraseIntoLine(currentLine, phrase)
                lineWidthSoFar = lineWidthSoFar + phrase.userData.width
            end
            encounteredWhitespaces = {}
        end
    end
    if #currentLine > 0 then
        insertPreparedLine(lines, currentLine, pureTextHeight, currentAlignment)
    end
    return lines
end

PT = {}

function PT.createLinesSplitIntoPages(documentWindow, splitPhrases)
    local lines = createLines(documentWindow, splitPhrases)
    local shouldSplitIntoPages = (documentWindow.layout.content:indexOf(content_name.leftPage.pageScrollbarDownButton_BORDER) == nil)

    local currentPage = 1
    local pageHeightLimit = documentWindow.layout.content[content_name.leftPage.pageReadableSpace].props.size.y
    local pageHeightSoFar = 0
    for _, line in pairs(lines) do
        if shouldSplitIntoPages and pageHeightSoFar + line.userData.height > pageHeightLimit then
            currentPage = currentPage + 1
            if line.userData.isDoubleNewline then
                line.userData.shouldBeRemovedBecauseItsEmptyAndStartsANewPage = true
            end
            pageHeightSoFar = 0
        end
        pageHeightSoFar = pageHeightSoFar + line.userData.height
        line.userData.page = currentPage
    end

    local result = {}
    for _, line in pairs(lines) do
        if not line.userData.shouldBeRemovedBecauseItsEmptyAndStartsANewPage then
            table.insert(result, line)
        end
    end
    return result
end

return PT
