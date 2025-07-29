local PhraseType = require("scripts.openmw_books_enhanced.wording.phrase_type")
local html_tag_parsing = require("scripts.openmw_books_enhanced.wording.html_tag_parsing")
local phrase = require("scripts.openmw_books_enhanced.wording.phrase")
local character_sizing = require("scripts.openmw_books_enhanced.wording.character_sizing")

local function addPhraseToTable(targetTable, text, phraseType, formattingSettings, characterSizingTable)
    table.insert(targetTable, phrase.createPhrase(text, phraseType, formattingSettings, characterSizingTable))
end

local PUNCTUATION = "%.%?!,;\"”“’‘‥…，、。？！；「」﹁﹂『』《》〈〉"
local PATTERN_FOR_WORD_END = "^[" .. PUNCTUATION .. "%s]"
local PATTERN_FOR_WHITESPACE = "^[\t ]"
local PATTERN_FOR_PUNCTUATION = "^[" .. PUNCTUATION .. "]"
local PATTERN_FOR_NEWLINE = "^[\n\r]"
local PATTERN_FOR_TAG_START = string.byte("<")

local WSP = {}

local function debugPrint(debugType, currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength,
                          phraseStart, lengthOfCurrentCharacter)
    if true then --set to false to show debug
        return
    end
    if debugType == "DEBUG1" then
        print(":: ", "currentCharacterStep:", currentCharacterStep, "thisCharacterByte:", thisCharacterByte, ">>",
            utf8.char(thisCharacterByte), "<<")
    elseif debugType == "DEBUG2" then
        print("--:: ",
            "this step " .. currentCharacterStep .. " skipped! " .. nextStepLength .. " skipping steps left")
    elseif debugType == "DEBUG3" then
        print("", "+++", "thisCharacterByte:" .. thisCharacterByte .. " at " ..
            currentCharacterStep .. " starts a tag!", ">>",
            utf8.char(thisCharacterByte), "<<")
    elseif debugType == "DEBUG4" then
        debugPrint("++:: ", "PATTERN_FOR_WORD_END",
            "added pre-phrase PhraseType.NORMAL_TEXT",
            ">>" .. string.sub(bookRecord.text, phraseStart, currentCharacterStep - 1) .. "<<",
            "[" .. phraseStart .. ".." .. (currentCharacterStep - 1) .. "]")
    elseif debugType == "DEBUG5" then
        debugPrint("++:: ", "PATTERN_FOR_WHITESPACE",
            "added phrase PhraseType.WHITESPACE",
            ">>" ..
            string.sub(bookRecord.text, currentCharacterStep, currentCharacterStep + lengthOfCurrentCharacter - 1) ..
            "<<",
            "[" ..
            currentCharacterStep .. ".." .. (currentCharacterStep + lengthOfCurrentCharacter - 1) .. "]")
    elseif debugType == "DEBUG6" then
        debugPrint("++:: ", "PATTERN_FOR_PUNCTUATION",
            "added phrase PhraseType.PUNCTUATION",
            ">>" ..
            string.sub(bookRecord.text, currentCharacterStep, currentCharacterStep + lengthOfCurrentCharacter - 1) ..
            "<<",
            "[" ..
            currentCharacterStep .. ".." .. (currentCharacterStep + lengthOfCurrentCharacter - 1) .. "]")
    elseif debugType == "DEBUG7" then
        debugPrint("++:: ", "currentCharacterStep == #text",
            "added end-phrase PhraseType.NORMAL_TEXT",
            ">>" .. string.sub(bookRecord.text, phraseStart, #bookRecord.text) .. "<<",
            "[" .. phraseStart .. ".." .. (#bookRecord.text) .. "]")
    end
end

function WSP.splitToPhraseWidgets(bookRecord)
    local splitPhrases = {}
    local characterSizingTable = character_sizing.createCharacterSizingTools()

    local text = bookRecord.text
    local lowercaseTextCopy = { s = string.lower(text) }

    local phraseStart = 1
    local currentFormattingSettings = {
        newFontColor = nil,
        newFontFace = nil,
        newTextSize = nil,
    }
    local nextStepLength = 1

    for currentCharacterStep, thisCharacterByte in utf8.codes(lowercaseTextCopy.s) do
        debugPrint("DEBUG1", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength)

        nextStepLength = nextStepLength - 1
        if nextStepLength > 0 then
            debugPrint("DEBUG2", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength)
        else
            local foundPhraseAlready = false
            nextStepLength = 1

            -- determine if tag is beginning
            if thisCharacterByte == PATTERN_FOR_TAG_START then
                debugPrint("DEBUG3", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength)
                local tagResult = html_tag_parsing.parseTag(lowercaseTextCopy, currentCharacterStep)
                if tagResult then
                    if phraseStart <= currentCharacterStep - 1 then
                        addPhraseToTable(
                            splitPhrases,
                            string.sub(text, phraseStart, currentCharacterStep - 1),
                            PhraseType.NORMAL_TEXT,
                            currentFormattingSettings,
                            characterSizingTable)
                    end
                    if tagResult.newFontColor ~= nil then
                        currentFormattingSettings.newFontColor = tagResult.newFontColor
                    end
                    if tagResult.newFontFace ~= nil then
                        currentFormattingSettings.newFontFace = tagResult.newFontFace
                    end
                    if tagResult.newTextSize ~= nil then
                        currentFormattingSettings.newTextSize = tagResult.newTextSize
                    end

                    nextStepLength = tagResult.numberOfCharactersToSkipBy
                    phraseStart = currentCharacterStep + nextStepLength
                    foundPhraseAlready = true
                    if tagResult.newWidgets then
                        for _, newWidget in pairs(tagResult.newWidgets) do
                            table.insert(splitPhrases, newWidget)
                        end
                    end
                end
            end

            if not foundPhraseAlready then
                if string.match(lowercaseTextCopy.s, PATTERN_FOR_WORD_END, currentCharacterStep) then
                    local lengthOfCurrentCharacter = 1
                    if thisCharacterByte > 127 then
                        local matchedSymbol = string.match(
                            lowercaseTextCopy.s,
                            "^" .. utf8.charpattern .. "",
                            currentCharacterStep)
                        lengthOfCurrentCharacter = #matchedSymbol
                    end

                    if phraseStart < currentCharacterStep then
                        addPhraseToTable(
                            splitPhrases,
                            string.sub(text, phraseStart, currentCharacterStep - 1),
                            PhraseType.NORMAL_TEXT,
                            currentFormattingSettings,
                            characterSizingTable)
                        debugPrint("DEBUG4", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength,
                            phraseStart)
                    end
                    if string.match(lowercaseTextCopy.s, PATTERN_FOR_WHITESPACE, currentCharacterStep) then
                        addPhraseToTable(
                            splitPhrases,
                            string.sub(text, currentCharacterStep, currentCharacterStep + lengthOfCurrentCharacter - 1),
                            PhraseType.WHITESPACE,
                            currentFormattingSettings,
                            characterSizingTable)
                        debugPrint("DEBUG5", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength,
                            phraseStart, lengthOfCurrentCharacter)
                    elseif string.match(lowercaseTextCopy.s, PATTERN_FOR_PUNCTUATION, currentCharacterStep) then
                        addPhraseToTable(
                            splitPhrases,
                            string.sub(text, currentCharacterStep, currentCharacterStep + lengthOfCurrentCharacter - 1),
                            PhraseType.PUNCTUATION,
                            currentFormattingSettings,
                            characterSizingTable)
                        debugPrint("DEBUG6", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength,
                            phraseStart, lengthOfCurrentCharacter)
                    elseif string.match(lowercaseTextCopy.s, PATTERN_FOR_NEWLINE, currentCharacterStep) then
                        --fallthrough
                    end
                    phraseStart = currentCharacterStep + lengthOfCurrentCharacter
                elseif currentCharacterStep == #text then
                    addPhraseToTable(
                        splitPhrases,
                        string.sub(text, phraseStart, #text),
                        PhraseType.NORMAL_TEXT,
                        currentFormattingSettings,
                        characterSizingTable)
                    debugPrint("DEBUG7", currentCharacterStep, thisCharacterByte, bookRecord, nextStepLength, phraseStart)
                end
            end
        end
    end

    return splitPhrases
end

return WSP
