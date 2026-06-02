---@diagnostic disable: param-type-mismatch
local core = require("openmw.core")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local commonData = require("scripts.quest_guider_lite.common")
local cacheLib = require("scripts.quest_guider_lite.utils.cache")

local l10n = core.l10n(commonData.l10nKey)

local levenshtein = require("scripts.quest_guider_lite.utils.levenshtein")

local this = {}

--- Returns string like ' "1", "2" and 3 more '
---@param tb table<any, string>
---@param max integer
---@param framePattern string|nil pattern with %s into which result will packed if max more than 0
---@param returnTable boolean? return an array with values
---@param customNumber integer? number of elements in the table
---@return string|string[]|nil
function this.getValueEnumString(tb, max, framePattern, returnTable, customNumber, valueFormat)
    local str = returnTable and {} or ""
    local count = 0
    valueFormat = valueFormat or "\"%s\""

    if max <= 0 then
        return str
    end

    for _, value in pairs(tb) do
        if count >= max then
            if returnTable then
                table.insert(str, string.format(l10n("andMorePattern"), (customNumber or tableLib.size(tb)) - count))
            else
                str = string.format("%s "..(l10n("andMorePattern")), str, (customNumber or tableLib.size(tb)) - count)
            end
            break
        end

        local valueForm = string.format(valueFormat, value)

        if returnTable then
            table.insert(str, string.format(framePattern or "%s", valueForm))
        else
            str = string.format("%s%s%s", str, str:len() ~= 0 and ", " or "", valueForm)
        end
        count = count + 1

    end

    if framePattern and not returnTable then
        return string.format(framePattern, str)
    end

    return str
end


---@param name string
---@return string
function this.convertDialogueName(name)
    return string.sub(name, 7)
end


---@param text string
---@return string?
function this.removeSpecialCharactersFromJournalText(text)
    if not text then return end
    return text:gsub('[@#\127]', "") ---@diagnostic disable-line: redundant-return-value
end


---@param text string
---@param phrase string
---@param threshold number|nil optional threshold for Levenshtein distance
---@return boolean
function this.hasPhrase(text, phrase, threshold)
    local textLower = this.utf8_lower(text)
    local phraseLower = this.utf8_lower(phrase)

    if textLower:find(phraseLower, 1, true) then
        return true
    end

    local phraseWords = this.utf8_splitWords(phraseLower)
    local textWords = this.utf8_splitWords(textLower)

    local phraseWordCount = #phraseWords
    local textWordCount = #textWords

    if phraseWordCount == 0 then
        return false
    end

    if textWordCount < phraseWordCount then
        return false
    end

    local phraseJoined = table.concat(phraseWords, " ")
    local phraseLen = this.length(phraseJoined)

    if not threshold then
        threshold = phraseLen > 5 and math.min(3, 1 + math.floor((phraseLen - 6) / 10)) or 0
    end

    local phraseByteLen = #phraseJoined

    for i = 1, textWordCount - phraseWordCount + 1 do
        local windowText
        if phraseWordCount == 1 then
            windowText = textWords[i]
        else
            local windowWords = {}
            for j = i, i + phraseWordCount - 1 do
                windowWords[j - i + 1] = textWords[j]
            end
            windowText = table.concat(windowWords, " ")
        end

        local windowByteLen = #windowText
        if math.abs(windowByteLen - phraseByteLen) <= threshold then
            local dist = levenshtein.utf8_levenshtein_bounded(windowText, phraseJoined, threshold)
            if dist <= threshold then
                return true
            end
        end
    end

    return false
end


---@param textWordDt {[1]: string, [2]:integer}
---@param phraseWordDt {[1]: string, [2]:integer}
---@param suffixFuzzyLen number how many ending characters to check with fuzzy matching
---@param maxDist number max allowed distance (for early termination)
---@return number distance (0 = exact, math.huge = no match)
local function matchWordWithEndingFuzzy(textWordDt, phraseWordDt, suffixFuzzyLen, maxDist)
    local phraseLen = phraseWordDt[2]
    local textLen = textWordDt[2]
    local textWord = textWordDt[1]
    local phraseWord = phraseWordDt[1]

    if textWord == phraseWord then
        return 0
    end

    if math.abs(textLen - phraseLen) > maxDist then
        return math.huge
    end

    local exactMatchLen = math.max(4, phraseLen - suffixFuzzyLen)

    if exactMatchLen > 0 then
        local phraseSplitByte = utf8.offset(phraseWord, exactMatchLen + 1) or (#phraseWord + 1)
        local phrasePrefix = phraseWord:sub(1, phraseSplitByte - 1)

        local _, prefixEnd = textWord:find(phrasePrefix, 1, true)
        if prefixEnd ~= phraseSplitByte - 1 then
            return math.huge
        end

        local phraseSuffix = phraseWord:sub(phraseSplitByte)
        local textSuffix = textWord:sub(prefixEnd + 1)

        if #phraseSuffix == 0 and #textSuffix == 0 then
            return 0
        end

        return levenshtein.utf8_levenshtein_short(textSuffix, phraseSuffix)
    end

    return levenshtein.utf8_levenshtein_short(textWord, phraseWord)
end


---@param textWords {[1]: string, [2]:integer}[]
---@param startIdx number
---@param phraseWords {[1]: string, [2]:integer}[]
---@param suffixFuzzyLen number
---@param totalThreshold number total threshold for the entire phrase
---@return number totalDistance (0 = all exact, math.huge = no match)
local function matchPhraseWords(textWords, startIdx, phraseWords, suffixFuzzyLen, totalThreshold)
    local totalDist = 0

    for i, phraseWordDt in ipairs(phraseWords) do
        local textWordDt = textWords[startIdx + i - 1]

        local thr = totalThreshold - totalDist
        if math.abs(textWordDt[2] - phraseWordDt[2]) > thr then
            return math.huge
        end
        local dist = matchWordWithEndingFuzzy(textWordDt, phraseWordDt, suffixFuzzyLen, thr)

        if dist == math.huge then
            return math.huge
        end

        totalDist = totalDist + dist
        if totalDist > totalThreshold then
            return math.huge
        end
    end

    return totalDist
end


---@class hasPhrasePosition
---@field startPos number byte position start
---@field endPos number byte position end

---@param text string
---@param phrases string[]
---@param threshold number|nil optional total threshold for Levenshtein distance for entire phrase
---@param suffixFuzzyLen number|nil how many ending characters to check with fuzzy matching (default 3)
---@return table<string, hasPhrasePosition[]> map of phrase to list of positions
function this.findPhrases(text, phrases, threshold, suffixFuzzyLen)
    local cachedVal = cacheLib.get("hasPhrase", text)
    if cachedVal then
        return cachedVal
    end

    local results = {}
    if not phrases or #phrases == 0 then
        return results
    end

    suffixFuzzyLen = suffixFuzzyLen or 3

    local textLower = this.utf8_lower(text)

    local textWords = {}
    local wordPositions = {}
    local usedWords = {}

    for word, endPos in textLower:gmatch("([^%s%p%c]+)()") do
        local startPos = endPos - #word
        table.insert(textWords, {word, this.length(word)})
        table.insert(wordPositions, {startPos, endPos - 1})
    end

    local textWordCount = #textWords

    for _, phrase in ipairs(phrases) do
        local phraseWords = {}
        for word in phrase:gmatch("[^%s%p%c]+") do
            table.insert(phraseWords, {word, this.length(word)})
        end
        local wordCount = #phraseWords

        if wordCount > 0 and wordCount <= textWordCount then

            local phraseThreshold = threshold
            if not threshold then
                local totalPhraseLen = this.length(phrase)
                if totalPhraseLen <= 3 then
                    phraseThreshold = 0
                    suffixFuzzyLen = 0
                else
                    phraseThreshold = totalPhraseLen > 4 and math.min(4, 2 + math.floor((totalPhraseLen - 4) / 8)) or 2
                    suffixFuzzyLen = math.min(3, phraseThreshold)
                    suffixFuzzyLen = 3
                end
            end

            local matches = {}

            local hasValue = false
            for i = 1, textWordCount - wordCount + 1 do
                local canMatch = true
                for w = 0, wordCount - 1 do
                    if usedWords[i + w] then
                        canMatch = false
                        break
                    end
                end

                if canMatch then
                    local dist = matchPhraseWords(
                        textWords, i, phraseWords, suffixFuzzyLen, phraseThreshold
                    )

                    if dist <= phraseThreshold then
                        table.insert(matches, {
                            startPos = wordPositions[i][1],
                            endPos = wordPositions[i + wordCount - 1][2]
                        })
                        hasValue = true
                        for w = 0, wordCount - 1 do
                            usedWords[i + w] = true
                        end
                    end
                end
            end

            if hasValue then
                results[phrase] = matches
            end
        end
    end

    cacheLib.set("hasPhrase", text, results)

    return results
end


---@param text string
---@param phrases string[]
---@return table<string, hasPhrasePosition[]> map of phrase to list of positions
function this.findPhrasesExact(text, phrases)
    local cachedVal = cacheLib.get("hasPhrase", text)
    if cachedVal then
        return cachedVal
    end

    local results = {}
    if not phrases or #phrases == 0 then
        return results
    end

    local textLower = this.utf8_lower(text)

    local usedRanges = {}
    local function isOverlapping(startPos, endPos)
        for _, range in ipairs(usedRanges) do
            if not (endPos < range.startPos or startPos > range.endPos) then
                return true
            end
        end
        return false
    end

    for _, phrase in ipairs(phrases) do
        local startPos = 1

        while true do
            local foundStart, foundEnd = textLower:find(phrase, startPos, true)
            if not foundStart then
                break
            end

            if not isOverlapping(foundStart, foundEnd) then
                if not results[phrase] then
                    results[phrase] = {}
                end
                table.insert(results[phrase], {
                    startPos = foundStart,
                    endPos = foundEnd
                })
                table.insert(usedRanges, {startPos = foundStart, endPos = foundEnd})
            end

            startPos = foundStart + 1
        end
    end

    cacheLib.set("hasPhrase", text, results)

    return results
end


---@param str string
---@return number
function this.length(str)
    return utf8.len(str) or string.len(str) or 0
end


---@return string[]
function this.findTextLinks(text)
    local results = {}
    for match in text:gmatch("@(.-)#") do
        table.insert(results, match)
    end
    return results
end


function this.utf8_splitWords(str)
    local words = {}
    for word in str:gmatch("[^%s%p%c]+") do
        table.insert(words, word)
    end
    return words
end


function this.utf8_removeLast(str, n)
    local len = utf8.len(str)
    if not len or n > len then return "" end
    local byte_pos = utf8.offset(str, len - n + 1)
    return str:sub(1, byte_pos - 1)
end


-- English, French, German, Spanish, Polish, Czech
local lowercaseMap = {
    ["A"]="a", ["B"]="b", ["C"]="c", ["D"]="d", ["E"]="e", ["F"]="f", ["G"]="g", ["H"]="h", ["I"]="i", ["J"]="j", ["K"]="k", ["L"]="l", ["M"]="m",
    ["N"]="n", ["O"]="o", ["P"]="p", ["Q"]="q", ["R"]="r", ["S"]="s", ["T"]="t", ["U"]="u", ["V"]="v", ["W"]="w", ["X"]="x", ["Y"]="y", ["Z"]="z",
    ["À"]="à", ["Â"]="â", ["Æ"]="æ", ["Ç"]="ç", ["É"]="é", ["È"]="è", ["Ê"]="ê", ["Ë"]="ë", ["Î"]="î", ["Ï"]="ï", ["Ô"]="ô", ["Œ"]="œ",
    ["Ù"]="ù", ["Û"]="û", ["Ÿ"]="ÿ", ["Ñ"]="ñ", ["Á"]="á", ["Í"]="í", ["Ú"]="ú",
    ["Ä"]="ä", ["Ö"]="ö", ["Ü"]="ü", ["ẞ"]="ß",
    ["Ą"]="ą", ["Ć"]="ć", ["Ę"]="ę", ["Ł"]="ł", ["Ń"]="ń", ["Ó"]="ó", ["Ś"]="ś", ["Ź"]="ź", ["Ż"]="ż",
    ["Č"]="č", ["Ď"]="ď", ["Ě"]="ě", ["Ň"]="ň", ["Ř"]="ř", ["Š"]="š", ["Ť"]="ť", ["Ů"]="ů", ["Ž"]="ž",
    -- Russian
    ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="ё", ["Ж"]="ж", ["З"]="з", ["И"]="и", ["Й"]="й",
    ["К"]="к", ["Л"]="л", ["М"]="м", ["Н"]="н", ["О"]="о", ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у", ["Ф"]="ф",
    ["Х"]="х", ["Ц"]="ц", ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ", ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я",
}

function this.utf8_lower(str)
    return (str:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
        return lowercaseMap[c] or string.lower(c)
    end))
end


local uppercaseMap = {
    -- English, French, German, Spanish, Polish, Czech
    ["a"]="A", ["b"]="B", ["c"]="C", ["d"]="D", ["e"]="E", ["f"]="F", ["g"]="G", ["h"]="H", ["i"]="I", ["j"]="J", ["k"]="K", ["l"]="L", ["m"]="M",
    ["n"]="N", ["o"]="O", ["p"]="P", ["q"]="Q", ["r"]="R", ["s"]="S", ["t"]="T", ["u"]="U", ["v"]="V", ["w"]="W", ["x"]="X", ["y"]="Y", ["z"]="Z",
    ["à"]="À", ["â"]="Â", ["æ"]="Æ", ["ç"]="Ç", ["é"]="É", ["è"]="È", ["ê"]="Ê", ["ë"]="Ë", ["î"]="Î", ["ï"]="Ï", ["ô"]="Ô", ["œ"]="Œ",
    ["ù"]="Ù", ["û"]="Û", ["ÿ"]="Ÿ", ["ñ"]="Ñ", ["á"]="Á", ["í"]="Í", ["ú"]="Ú",
    ["ä"]="Ä", ["ö"]="Ö", ["ü"]="Ü", ["ß"]="ẞ",
    ["ą"]="Ą", ["ć"]="Ć", ["ę"]="Ę", ["ł"]="Ł", ["ń"]="Ń", ["ó"]="Ó", ["ś"]="Ś", ["ź"]="Ź", ["ż"]="Ż",
    ["č"]="Č", ["ď"]="Ď", ["ě"]="Ě", ["ň"]="Ň", ["ř"]="Ř", ["š"]="Š", ["ť"]="Ť", ["ů"]="Ů", ["ž"]="Ž",
    -- Russian
    ["а"]="А", ["б"]="Б", ["в"]="В", ["г"]="Г", ["д"]="Д", ["е"]="Е", ["ё"]="Ё", ["ж"]="Ж", ["з"]="З", ["и"]="И", ["й"]="Й",
    ["к"]="К", ["л"]="Л", ["м"]="М", ["н"]="Н", ["о"]="О", ["п"]="П", ["р"]="Р", ["с"]="С", ["т"]="Т", ["у"]="У", ["ф"]="Ф",
    ["х"]="Х", ["ц"]="Ц", ["ч"]="Ч", ["ш"]="Ш", ["щ"]="Щ", ["ъ"]="Ъ", ["ы"]="Ы", ["ь"]="Ь", ["э"]="Э", ["ю"]="Ю", ["я"]="Я",
}

function this.utf8_upper(str)
    return (str:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
        return uppercaseMap[c] or string.upper(c)
    end))
end


function this.utf8_chars(str)
    local chars = {}
    for _, c in utf8.codes(str) do
        table.insert(chars, utf8.char(c))
    end
    return chars
end


function this.utf8_sub(s, start, len)
    local byte_start = utf8.offset(s, start) or 1
    local byte_end
    if len then
        local next_pos = utf8.offset(s, start + len)
        byte_end = next_pos and (next_pos - 1) or #s
    else
        byte_end = #s
    end
    return s:sub(byte_start, byte_end)
end


local separatorPattern = "[%s%p%c]"

function this.isSeparator(c)
    return c:match(separatorPattern) ~= nil
end


function this.isWordChar(c)
    return not this.isSeparator(c)
end


---@param data  questGuider.quest.getRequirementPositionData.positionData
---@return string?
---@return string? backward
function this.getPathToPosition(data)
    local descr
    local descrBack
    if not data.description then
        if data.pathFromPlayer then
            for _, cellName in ipairs(data.pathFromPlayer) do
                descr = descr and string.format("%s => \"%s\"", descr, cellName) or
                    string.format("\"%s\"", cellName)
                descrBack = descrBack and string.format("\"%s\" <= %s", cellName, descrBack) or
                    string.format("\"%s\"", cellName)
            end

        elseif data.cellPath then
            for i = #data.cellPath, 1, -1 do
                descr = descr and string.format("%s => \"%s\"", descr, data.cellPath[i].name) or
                    string.format("\"%s\"", data.cellPath[i].name)
                descrBack = descrBack and string.format("\"%s\" <= %s", data.cellPath[i].name, descrBack) or
                    string.format("\"%s\"", data.cellPath[i].name)
            end

        elseif data.id then
            descr = string.format("\"%s\"", data.id)
            descrBack = descr

        else
            descr = "???"
            descrBack = "???"
        end
    else
        descr = data.description
    end

    return descr, descrBack
end


function this.getBeforeComma(str)
    local pos = string.find(str, ",")
    if pos then
        return string.sub(str, 1, pos - 1)
    else
        return str
    end
end


function this.getAfterComma(str)
    local pos = string.find(str, ", ")
    if pos then
        return string.sub(str, pos + 2, #str)
    else
        return str
    end
end


function this.replaceGameTags(str, replacements)
    return (str:gsub("%%(%w+)", function(key)
        return replacements[key] or ("%"..key)
    end))
end


return this