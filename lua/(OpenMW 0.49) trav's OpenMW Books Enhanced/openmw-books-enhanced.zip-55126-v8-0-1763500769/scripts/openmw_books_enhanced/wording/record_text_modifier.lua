local self = require('openmw.self')
local types = require('openmw.types')

local V = {}

function V.tryToReplaceWithFilledValues(replacedBookText)
    if replacedBookText == nil then
        return nil
    end

    return { text = replacedBookText }
end

function V.overwriteHtmlTags(bookRecord)
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

    result = string.gsub(
        result,
        "<#[^>\t\n\r]*>",
        ""
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
