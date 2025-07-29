local ui = require('openmw.ui')
local util = require('openmw.util')
local settings = require("scripts.openmw_books_enhanced.settings")
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")

local constantToDistinguishFromJournalEnhanced = 0.95

local resolutionToRecommendedSizeMultiplier = {
    ["(1980, 1080)"] = 2.5,
    ["(1920, 1080)"] = 2.5,
    ["(1768, 992)"] = 2.5,
    ["(1680, 1050)"] = 2.5,
    ["(1600, 1024)"] = 2.5,
    ["(1600, 900)"] = 2.125,
    ["(1440, 1080)"] = 2.5,
    ["(1440, 900)"] = 2.125,
    ["(1366, 768)"] = 1.875,
    ["(1360, 768)"] = 1.875,
    ["(1280, 1024)"] = 2.125,
    ["(1280, 960)"] = 2.125,
    ["(1280, 800)"] = 1.875,
    ["(1280, 768)"] = 1.875,
    ["(1280, 720)"] = 1.75,
    ["(1176, 664)"] = 1.625,
    ["(1152, 864)"] = 1.875,
    ["(1024, 768)"] = 1.6875,
    ["(800, 600)"] = 1.375,
    ["(720, 576)"] = 1.25,
    ["(720, 480)"] = 1.1875,
    ["(640, 480)"] = 1.125,
}

local function calculateResizeMultiplierWithFallbackValue(fallbackValue)
    local result = fallbackValue

    if settings.SettingsTravOpenmwBooksEnhanced_useRecommendedResolutionMultipliers() then
        local possibleMultiplier = resolutionToRecommendedSizeMultiplier[tostring(ui.screenSize())]
        if possibleMultiplier ~= nil then
            result = possibleMultiplier * constantToDistinguishFromJournalEnhanced
        end
    end

    return result
end

local function calculateWidthMultiplier()
    local widthMultiplier = settings.SettingsTravOpenmwBooksEnhanced_documentWindowWidthMultiplier()
    return calculateResizeMultiplierWithFallbackValue(widthMultiplier)
end

local function calculateHeightMultiplier()
    local heightMultiplier = settings.SettingsTravOpenmwBooksEnhanced_documentWindowHeightMultiplier()
    return calculateResizeMultiplierWithFallbackValue(heightMultiplier)
end

local function applyNewSizes(documentWindow, documentWindowData, widthMultiplier, heightMultiplier)
    documentWindow.props.size = util.vector2(
        documentWindow.props.size.x * widthMultiplier,
        documentWindow.props.size.y * heightMultiplier
    )

    local function changeSize(element)
        element.props.size = util.vector2(
            element.props.size.x * widthMultiplier,
            element.props.size.y * heightMultiplier
        )
    end

    local elementsNeedingResizing = {
        content_name.leftPage.pageReadableSpace,
    }
    if documentWindowData.pagesTextArrangement.page2 then
        table.insert(elementsNeedingResizing, content_name.rightPage.pageReadableSpace)
    end
    for _, elementName in pairs(elementsNeedingResizing) do
        changeSize(documentWindow.content[elementName])
    end

    if documentWindowData.pagesTextArrangement.page1.textArea.isScrollableVertically then
        changeSize(documentWindow.content[content_name.leftPage.pageScrollbarUpButton_BORDER].content
            [content_name.leftPage.pageScrollbarUpButton])
        changeSize(documentWindow.content[content_name.leftPage.pageScrollbarElevator_BORDER].content
            [content_name.leftPage.pageScrollbarElevator])
        changeSize(documentWindow.content[content_name.leftPage.pageScrollbarDownButton_BORDER].content
            [content_name.leftPage.pageScrollbarDownButton])
    end

    if documentWindowData.additionalWidgetsInDocumentUi then
        for _, value in pairs(documentWindowData.additionalWidgetsInDocumentUi) do
            changeSize(documentWindow.content[value.name])
        end
    end
end

local function applyNewPositions(documentWindow, documentWindowData, widthMultiplier, heightMultiplier)
    local elementsNeedingRepositioning = {
        content_name.leftPage.pageReadableSpace,
        content_name.leftPageNumber,
        content_name.takeButton,
        content_name.prevButton,
        content_name.nextButton,
        content_name.closeButton,
    }
    if documentWindowData.pagesTextArrangement.page1.textArea.isScrollableVertically then
        table.insert(elementsNeedingRepositioning, content_name.leftPage.pageScrollbarUpButton_BORDER)
        table.insert(elementsNeedingRepositioning, content_name.leftPage.pageScrollbarElevator_BORDER)
        table.insert(elementsNeedingRepositioning, content_name.leftPage.pageScrollbarDownButton_BORDER)
    end
    if documentWindowData.pagesTextArrangement.page2 then
        table.insert(elementsNeedingRepositioning, content_name.rightPage.pageReadableSpace)
        table.insert(elementsNeedingRepositioning, content_name.rightPageNumber)
    end
    for _, elementName in pairs(elementsNeedingRepositioning) do
        if documentWindow.content:indexOf(elementName) and documentWindow.content[elementName].props then
            documentWindow.content[elementName].props.position = util.vector2(
                documentWindow.content[elementName].props.position.x * widthMultiplier,
                documentWindow.content[elementName].props.position.y * heightMultiplier
            )
        end
    end

    if documentWindowData.additionalWidgetsInDocumentUi then
        for _, value in pairs(documentWindowData.additionalWidgetsInDocumentUi) do
            documentWindow.content[value.name].props.position = util.vector2(
                documentWindow.content[value.name].props.position.x * widthMultiplier,
                documentWindow.content[value.name].props.position.y * heightMultiplier
            )
        end
    end
end

local function applyNewFontSizes(documentWindow, documentWindowData)
    local buttonSize = settings.SettingsTravOpenmwBooksEnhanced_textDocumentButtonSize()
    local pageNumberSize = settings.SettingsTravOpenmwBooksEnhanced_textDocumentPageNumberSize()

    local elementsNeedingFontSizeChange = {
        [content_name.takeButton] = buttonSize,
        [content_name.prevButton] = buttonSize,
        [content_name.nextButton] = buttonSize,
        [content_name.closeButton] = buttonSize,
        [content_name.leftPageNumber] = pageNumberSize,
    }
    if documentWindowData.pagesTextArrangement.page2 then
        elementsNeedingFontSizeChange[content_name.rightPageNumber] = pageNumberSize
    end

    for elementName, elementValue in pairs(elementsNeedingFontSizeChange) do
        if documentWindow.content:indexOf(elementName) and documentWindow.content[elementName].props then
            documentWindow.content[elementName].props.textSize = elementValue
        end
    end
end

local WS = {}

function WS.resizeDocumentWindowForUserSettings(documentWindow, documentWindowData)
    applyNewFontSizes(documentWindow, documentWindowData)

    local widthMultiplier = calculateWidthMultiplier()
    local heightMultiplier = calculateHeightMultiplier()

    applyNewSizes(documentWindow, documentWindowData, widthMultiplier, heightMultiplier)
    applyNewPositions(documentWindow, documentWindowData, widthMultiplier, heightMultiplier)
end

return WS
