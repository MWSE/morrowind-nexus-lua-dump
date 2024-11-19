local self = require('openmw.self')
local types = require('openmw.types')

local V = {}

local function createTableOfPossibleVariableValues()
    return {
        ["%%[pP][cC][nN][Aa][Mm][Ee]"] = types.Player.record(self).name,
        ["%%[pP][cC][cC][lL][aA][sS][sS]"] = types.Player.classes.records[types.Player.record(self).class].name,
        ["%%[pP][cC][Rr][Aa][Cc][Ee]"] = types.Player.races.records[types.Player.record(self).race].name,
        ["%%[Yy][Ee][Aa][Rr]"] = "427", --eeeh it's good enough, right? Right?
    }
end

function V.tryToReplaceWithFilledValues(bookRecord)
    if not string.match(bookRecord.text, "(%%%w+)") then
        return nil
    end

    local result = { text = bookRecord.text }

    local variables = createTableOfPossibleVariableValues()
    for pattern, value in pairs(variables) do
        result.text = string.gsub(result.text, pattern, value)
    end

    return result
end

function V.overwriteNewlines(bookRecord)
    if not string.match(bookRecord.text, "\n") then
        return nil
    end
    local result = string.gsub(
        bookRecord.text,
        "<BR>%s*<BR>",
        "<BR><BR>"
    )

    result = string.gsub(
        result,
        "<BR>[ \t]*\r\n?",
        "<BR>"
    )

    result = string.gsub(
        result,
        "<BR>[ \t]*\n\r?",
        "<BR>"
    )

    result = string.gsub(
        result,
        "<DIV%s+ALIGN=\"([^\"]-)\"><BR>",
        "<BR><DIV ALIGN=\"%1\">"
    )

    result = string.gsub(
        result,
        "<DIV",
        "<BR><DIV"
    )

    return {
        text = string.gsub(
            result,
            "\n",
            "<BR>"
        )
    }
end

return V
