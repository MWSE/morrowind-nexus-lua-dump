local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')
local l10n = require('openmw.core').l10n("openmw_books_enhanced")

local function isStyleTemplateCorrect(styleTemplate)
    return styleTemplate
        and styleTemplate.shouldApplyTo
        and styleTemplate.texture
        and styleTemplate.texture.path
        and styleTemplate.texture.width
        and styleTemplate.texture.height
        and styleTemplate.pagesTextArrangement
        and styleTemplate.pagesTextArrangement.page1
        and styleTemplate.pagesTextArrangement.page1.textArea
        and styleTemplate.pagesTextArrangement.page1.textArea.width
        and styleTemplate.pagesTextArrangement.page1.textArea.height
        and styleTemplate.pagesTextArrangement.page1.textArea.posTopLeftCornerX
        and styleTemplate.pagesTextArrangement.page1.textArea.posTopLeftCornerY
        and styleTemplate.pagesTextArrangement.page1.pageNumber
        and styleTemplate.pagesTextArrangement.page1.pageNumber.posCenterX
        and styleTemplate.pagesTextArrangement.page1.pageNumber.posCenterY
        and (
            styleTemplate.pagesTextArrangement.page2 == nil
            or (
                styleTemplate.pagesTextArrangement.page2
                and styleTemplate.pagesTextArrangement.page2.textArea
                and (styleTemplate.pagesTextArrangement.page2.textArea.isScrollableVertically == nil)
                and (
                    styleTemplate.pagesTextArrangement.page2.textArea.width == nil
                    or styleTemplate.pagesTextArrangement.page2.textArea.width == styleTemplate.pagesTextArrangement.page1.textArea.width
                )
                and (
                    styleTemplate.pagesTextArrangement.page2.textArea.height == nil
                    or styleTemplate.pagesTextArrangement.page2.textArea.height == styleTemplate.pagesTextArrangement.page1.textArea.height
                )
                and styleTemplate.pagesTextArrangement.page2.textArea.posTopLeftCornerX
                and styleTemplate.pagesTextArrangement.page2.textArea.posTopLeftCornerY
                and styleTemplate.pagesTextArrangement.page2.pageNumber
                and styleTemplate.pagesTextArrangement.page2.pageNumber.posCenterX
                and styleTemplate.pagesTextArrangement.page2.pageNumber.posCenterY
            )
        )
        and styleTemplate.takeButton
        and styleTemplate.takeButton.posCenterX
        and styleTemplate.takeButton.posCenterY
        and (
            styleTemplate.pagesTextArrangement.page1.textArea.isScrollableVertically
            or
            (
                styleTemplate.prevButton
                and styleTemplate.prevButton.posCenterX
                and styleTemplate.prevButton.posCenterY
                and styleTemplate.nextButton
                and styleTemplate.nextButton.posCenterX
                and styleTemplate.nextButton.posCenterY
            )
        )
        and styleTemplate.closeButton
        and styleTemplate.closeButton.posCenterX
        and styleTemplate.closeButton.posCenterY
end

local S = {}

function S.chooseDocumentWindowStyle(activatedBookObject)
--[[
    local possibleTemplates = {}

    local expectedDirectoryPath = "scripts/data_for_openmw_books_enhanced"

    for file in vfs.pathsWithPrefix(expectedDirectoryPath) do
        if string.match(file, ".*%.lua") then
            file = file.gsub(file, ".lua", "")
            local styleTemplate = require(file)

            if type(styleTemplate) == 'table' then
                if not isStyleTemplateCorrect(styleTemplate) then
                    print(
                        l10n("SettingsTravOpenmwBooksEnhanced_Warning"),
                        file,
                        l10n("SettingsTravOpenmwBooksEnhanced_Warning_InvalidLuaStyleTable"))
                elseif styleTemplate.shouldApplyTo(activatedBookObject) then
                    table.insert(possibleTemplates, styleTemplate)
                end
            else
                print(
                    l10n("SettingsTravOpenmwBooksEnhanced_Warning"),
                    file,
                    l10n("SettingsTravOpenmwBooksEnhanced_Warning_InvalidLuaStyleTable"))
            end
        end
    end

    if #possibleTemplates > 0 then
        return possibleTemplates[#possibleTemplates] -- returning last match (is that good? we'll see)
    else
        print(
            l10n("SettingsTravOpenmwBooksEnhanced_Warning"),
            activatedBookObject,
            l10n("SettingsTravOpenmwBooksEnhanced_Warning_MatchingStyleNotFound"))
        return require('scripts.data_for_openmw_books_enhanced.0100_vanilla_book')
    end
]]--
    return require('scripts.data_for_openmw_books_enhanced.0100_vanilla_book')
end

return S
