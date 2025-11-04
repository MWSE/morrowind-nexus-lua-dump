---@diagnostic disable: param-type-mismatch

local tableLib = require("scripts.quest_guider_lite.utils.table")

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
                table.insert(str, string.format("and %d more", (customNumber or tableLib.size(tb)) - count))
            else
                str = string.format("%s and %d more", str, (customNumber or tableLib.size(tb)) - count)
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
---@return string
function this.removeSpecialCharactersFromJournalText(text)
    return text:gsub('[@#\127]', "") ---@diagnostic disable-line: redundant-return-value
end


---@param text string
---@param phrase string
---@return boolean
function this.hasPhrase(text, phrase)
    local escapedPhrase = phrase:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")

    local pattern = "%f[%w]" .. escapedPhrase .. "%f[^%w]"

    if text:find(pattern) then
        return true
    else
        return false
    end
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
    local pattern = "[%wа-яА-ЯёЁąćęłńóśźżĄĆĘŁŃÓŚŹŻčďěňřšťůžČĎĚŇŘŠŤŮŽäöüßÄÖÜéèêëÉÈÊËàâæçîïôœùûüÿÀÂÆÇÎÏÔŒÙÛÜŸ]+"
    for word in str:gmatch(pattern) do
        table.insert(words, word)
    end
    if #words == 0 and str ~= "" then
        table.insert(words, str)
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
    local i = 1
    local byte_start, byte_end
    for p, c in utf8.codes(s) do
        if i == start then
            byte_start = p
        end
        if i == start + len then
            byte_end = p - 1
            break
        end
        i = i + 1
    end
    byte_start = byte_start or 1
    byte_end = byte_end or #s
    return s:sub(byte_start, byte_end)
end


function this.isWordChar(c)
    return c:match("[%wа-яА-ЯёЁąćęłńóśźżĄĆĘŁŃÓŚŹŻčďěňřšťůžČĎĚŇŘŠŤŮŽäöüßÄÖÜéèêëÉÈÊËàâæçîïôœùûüÿÀÂÆÇÎÏÔŒÙÛÜŸ]")
end


---@param pattern string should be lowercase
---@return boolean
function this.fuzzyTopicSearch(text, pattern, threshold)
    if not threshold then
        local len = this.length(pattern)

        threshold = len > 3 and math.min(5, 1 + len / 5) or 0
    end

    local text_lower = this.utf8_lower(text)

    local dist = levenshtein.utf8_levenshtein(text, pattern) or math.huge
    if dist <= threshold then
        return true
    end

    return false
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


return this