local phrase = require("scripts.openmw_books_enhanced.wording.phrase")
local PhraseType = require("scripts.openmw_books_enhanced.wording.phrase_type")
local html_tag_setting = require("scripts.openmw_books_enhanced.wording.html_tag_setting")
local ui = require('openmw.ui')
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local l10n = require('openmw.core').l10n("openmw_books_enhanced")

local possibleTag = {
    P = 100,
    B = 200,
    END_B = 250,
    BR = 300,
    FONT = 400,
    END_FONT = 450,
    DIV = 500,
    END_DIV = 550,
    IMG = 600,
}

local alignmentToPhraseType = {
    ["left"] = PhraseType.ALIGN_LEFT,
    ["right"] = PhraseType.ALIGN_RIGHT,
    ["center"] = PhraseType.ALIGN_CENTER,
}

local function establishImageTexturePath(imageTexture)
    local candidates = {
        "bookart/" .. imageTexture,
        "bookart/" .. string.sub(imageTexture, 1, #imageTexture - 4) .. "_377_253.tga",
        "bookart/" .. string.sub(imageTexture, 1, #imageTexture - 4) .. ".dds",
        "bookart/" .. string.sub(imageTexture, 1, #imageTexture - 4) .. "_377_253.dds",
    }
    for _, candidate in pairs(candidates) do
        if vfs.fileExists(candidate) then
            return candidate
        end
    end

    print(
        l10n("SettingsTravOpenmwBooksEnhanced_Warning"),
        "IMG",
        imageTexture)
    return "bookart/" .. imageTexture
end

local function findTagBeginning(lowercaseTextCopy, textStartingPosition)
    local currentCharacterStep = textStartingPosition

    local thisCharacterByte = string.byte(lowercaseTextCopy.s, currentCharacterStep, currentCharacterStep)
    if thisCharacterByte ~= string.byte("<") then
        return nil
    end
    currentCharacterStep = currentCharacterStep + 1

    local expectingNext = nil
    while currentCharacterStep <= #lowercaseTextCopy.s do
        thisCharacterByte = string.byte(lowercaseTextCopy.s, currentCharacterStep, currentCharacterStep)
        if thisCharacterByte == string.byte(" ") or thisCharacterByte == string.byte("\t") then
            currentCharacterStep = currentCharacterStep + 1
        elseif expectingNext then
            return expectingNext[thisCharacterByte]
        elseif thisCharacterByte == string.byte("p") then
            return possibleTag.P
        elseif thisCharacterByte == string.byte("f") then
            return possibleTag.FONT
        elseif thisCharacterByte == string.byte("d") then
            return possibleTag.DIV
        elseif thisCharacterByte == string.byte("i") then
            return possibleTag.IMG
        elseif thisCharacterByte == string.byte("b") then
            expectingNext = {
                [string.byte("r")] = possibleTag.BR,
                [string.byte(">")] = possibleTag.B,
            }
            currentCharacterStep = currentCharacterStep + 1
        elseif thisCharacterByte == string.byte("/") then
            expectingNext = {
                [string.byte("f")] = possibleTag.END_FONT,
                [string.byte("d")] = possibleTag.END_DIV,
                [string.byte("b")] = possibleTag.END_B,
            }
            currentCharacterStep = currentCharacterStep + 1
        end
    end
end

local H = {}

function H.parseTag(lowercaseTextCopy, textStartingPosition)
    local newWidgets = {}
    local numberOfCharactersToSkipBy = nil
    local newFontColor = nil
    local newFontFace = nil
    local newTextSize = nil

    local foundTag = findTagBeginning(lowercaseTextCopy, textStartingPosition)

    if (foundTag == possibleTag.P) then
        local paragraphMatch = string.match(lowercaseTextCopy.s, "^<%s*p%s*>", textStartingPosition)
        if paragraphMatch then
            table.insert(newWidgets, phrase.createPhrase("", PhraseType.DOUBLE_NEWLINE))
            numberOfCharactersToSkipBy = #paragraphMatch
        else
            foundTag = false
        end
    elseif (foundTag == possibleTag.BR) then
        local doubleNewlineMatch = string.match(lowercaseTextCopy.s, "^<%s*br%s*>%s*<%s*br%s*>", textStartingPosition)
        if doubleNewlineMatch then
            table.insert(newWidgets, phrase.createPhrase("", PhraseType.DOUBLE_NEWLINE))
            numberOfCharactersToSkipBy = #doubleNewlineMatch
        else
            local newlineMatch = string.match(lowercaseTextCopy.s, "^<%s*br%s*>", textStartingPosition)
            if newlineMatch then
                table.insert(newWidgets, phrase.createPhrase("", PhraseType.NEWLINE))
                numberOfCharactersToSkipBy = #newlineMatch
            else
                foundTag = false
            end
        end
    elseif (foundTag == possibleTag.FONT) then
        local patternsForFont = {
            '^(<%s*font%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s+size%s*=%s*[\'"](%d+)[\'"]%s*>)',
            '^(<%s*font%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s+size%s*=%s*[\'"](%d+)[\'"]%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)',
            '^(<%s*font%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s+size%s*=%s*[\'"](%d+)[\'"]%s*>)',
            '^(<%s*font%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s+size%s*=%s*[\'"](%d+)[\'"]%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s*>)',
            '^(<%s*font%s+size%s*=%s*[\'"](%d+)[\'"]%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s*>)',
            '^(<%s*font%s+size%s*=%s*[\'"](%d+)[\'"]%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)',
            '^(<%s*font%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s+size%s*=%s*[\'"](%d+)[\'"]%s*>)',
            '^(<%s*font%s+size%s*=%s*[\'"](%d+)[\'"]%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)',
            '^(<%s*font%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s*>)',
            '^(<%s*font%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)',
            '^(<%s*font%s+size%s*=%s*[\'"](%d+)[\'"]%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s*>)',
            '^(<%s*font%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s+size%s*=%s*[\'"](%d+)[\'"]%s*>)',
            '^(<%s*font%s+face%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)',
            '^(<%s*font%s+size%s*=%s*[\'"](%d+)[\'"]%s*>)',
            '^(<%s*font%s+color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]%s*>)',
            '^(<%s*font%s*>)',
        }
        local foundFontMatch = false
        local fontMatch = nil
        for _, pattern in pairs(patternsForFont) do
            fontMatch = string.match(lowercaseTextCopy.s, pattern, textStartingPosition)
            if fontMatch then
                foundFontMatch = true
                break
            end
        end
        if foundFontMatch then
            local possibleNewColor = { string.match(fontMatch, 'color%s*=%s*[\'"](%x%x%x%x%x%x)[\'"]') }
            if #possibleNewColor > 0 then
                newFontColor = possibleNewColor[1]
            end

            local possibleNewFontFace = { string.match(fontMatch, 'face%s*=%s*[\'"]([^\'">]+)[\'"]') }
            if #possibleNewFontFace > 0 then
                newFontFace = possibleNewFontFace[1]
            end

            local possibleNewTextSize = { string.match(fontMatch, 'size%s*=%s*[\'"](%d+)[\'"]') }
            if #possibleNewTextSize > 0 then
                newTextSize = possibleNewTextSize[1]
            end

            numberOfCharactersToSkipBy = #(fontMatch)
        else
            foundTag = false
        end
    elseif (foundTag == possibleTag.END_FONT) then
        local fontEndMatch = string.match(lowercaseTextCopy.s, "^<%s*/%s*font%s*>", textStartingPosition)
        if fontEndMatch then
            newFontColor = html_tag_setting.RESETSETTING
            newFontFace = html_tag_setting.RESETSETTING
            newTextSize = html_tag_setting.RESETSETTING
            numberOfCharactersToSkipBy = #fontEndMatch
        else
            foundTag = false
        end
    elseif (foundTag == possibleTag.DIV) then
        local divMatch = {
            string.match(
                lowercaseTextCopy.s,
                '^(<%s*div%s+align%s*=%s*"([cntrlefigh]+)"%s*>)',
                textStartingPosition)
        }
        if #divMatch > 0 then
            local newAlignment = alignmentToPhraseType[divMatch[2]]
            if newAlignment then
                table.insert(newWidgets, phrase.createPhrase("", newAlignment))
            else
                table.insert(newWidgets, phrase.createPhrase("", PhraseType.ALIGN_LEFT))
            end
            numberOfCharactersToSkipBy = #(divMatch[1])
        else
            divMatch = string.match(
                lowercaseTextCopy.s,
                "^<%s*div%s*>",
                textStartingPosition)
            if divMatch then
                numberOfCharactersToSkipBy = #divMatch
            else
                foundTag = false
            end
        end
    elseif (foundTag == possibleTag.END_DIV) then
        local divEndMatch = string.match(lowercaseTextCopy.s, "^<%s*/%s*div%s*>", textStartingPosition)
        if divEndMatch then
            table.insert(newWidgets, phrase.createPhrase("", PhraseType.ALIGN_LEFT))
            numberOfCharactersToSkipBy = #divEndMatch
        else
            foundTag = false
        end
    elseif (foundTag == possibleTag.IMG) then
        local patternsForImage = {
            ['^(<%s*img%s+src%s*=%s*[\'"]([^\'">]+)[\'"]%s+width%s*=%s*[\'"](%d+)[\'"]%s+height%s*=%s*[\'"](%d+)[\'"]%s*>)'] = { src = 1, width = 2, height = 3 },
            ['^(<%s*img%s+src%s*=%s*[\'"]([^\'">]+)[\'"]%s+height%s*=%s*[\'"](%d+)[\'"]%s+width%s*=%s*[\'"](%d+)[\'"]%s*>)'] = { src = 1, width = 3, height = 2 },
            ['^(<%s*img%s+width%s*=%s*[\'"](%d+)[\'"]%s+src%s*=%s*[\'"]([^\'">]+)[\'"]%s+height%s*=%s*[\'"](%d+)[\'"]%s*>)'] = { src = 2, width = 1, height = 3 },
            ['^(<%s*img%s+width%s*=%s*[\'"](%d+)[\'"]%s+height%s*=%s*[\'"](%d+)[\'"]%s+src%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)'] = { src = 3, width = 1, height = 2 },
            ['^(<%s*img%s+height%s*=%s*[\'"](%d+)[\'"]%s+width%s*=%s*[\'"](%d+)[\'"]%s+src%s*=%s*[\'"]([^\'">]+)[\'"]%s*>)'] = { src = 3, width = 2, height = 1 },
            ['^(<%s*img%s+height%s*=%s*[\'"](%d+)[\'"]%s+src%s*=%s*[\'"]([^\'">]+)[\'"]%s+width%s*=%s*[\'"](%d+)[\'"]%s*>)'] = { src = 2, width = 3, height = 1 },
        }
        local foundImageMatch = false
        local usedImageOrdering = nil
        local imageMatch = nil
        for pattern, ordering in pairs(patternsForImage) do
            if foundImageMatch then
                break
            end
            imageMatch = { string.match(lowercaseTextCopy.s, pattern, textStartingPosition) }
            usedImageOrdering = ordering
            foundImageMatch = (#imageMatch > 0)
        end
        if foundImageMatch then
            local width = tonumber(imageMatch[usedImageOrdering.width + 1])
            local height = tonumber(imageMatch[usedImageOrdering.height + 1])
            local imageTexture = imageMatch[usedImageOrdering.src + 1]
            table.insert(newWidgets, {
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(width, height),
                    resource = ui.texture { path = establishImageTexturePath(imageTexture) },
                },
                userData = {
                    type = PhraseType.IMAGE,
                    width = width,
                    height = height,
                },
            })
            numberOfCharactersToSkipBy = #(imageMatch[1])
        else
            foundTag = false
        end
    elseif (foundTag == possibleTag.B or foundTag == possibleTag.END_B) then
        local boldMatch = string.match(lowercaseTextCopy.s, "^<%s*/?%s*b%s*>", textStartingPosition)
        if boldMatch then
            numberOfCharactersToSkipBy = #boldMatch
        else
            foundTag = false
        end
    end

    if foundTag then
        return {
            newWidgets = newWidgets,
            numberOfCharactersToSkipBy = numberOfCharactersToSkipBy,
            newFontColor = newFontColor,
            newFontFace = newFontFace,
            newTextSize = newTextSize,
        }
    else
        print(
            l10n("SettingsTravOpenmwBooksEnhanced_Warning"),
            "TAG",
            string.sub(lowercaseTextCopy.s, textStartingPosition, textStartingPosition + 50))
        return nil
    end
end

return H
