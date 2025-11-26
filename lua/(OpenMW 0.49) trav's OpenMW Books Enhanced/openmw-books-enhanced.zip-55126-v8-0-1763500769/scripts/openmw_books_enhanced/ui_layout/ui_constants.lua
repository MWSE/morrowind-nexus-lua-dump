local openmwConstants = require('scripts.omw.mwui.constants')
local util = require('openmw.util')
local ui = require('openmw.ui')
local core = require('openmw.core')

local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        print("UNEXPECTED COLOR: rgb of size=", #rgb)
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local C = {
    documentWindowWidthMultiplier = 2.01,
    documentWindowHeightMultiplier = 2.01,
    textDocumentNormalSize = openmwConstants.textNormalSize + 10,
    textDocumentButtonSize = openmwConstants.textNormalSize + 11,
    paperLikeColor = getColorFromGameSettings("FontColor_color_normal"),
    fontColorJournalNormalText = getColorFromGameSettings("FontColor_color_background"),
    fontColorJournalButtonIdle = util.color.rgb(60 / 255, 24 / 255, 4 / 255),
    fontColorJournalButtonOver = util.color.rgb(127 / 255, 52 / 255, 8 / 255),
    fontColorJournalButtonShadow = util.color.rgb(234 / 255, 210 / 255, 175 / 255),
    fontColorJournalButtonPressed = util.color.rgb(255 / 255, 255 / 255, 189 / 255),
    whiteTexture = ui.texture { path = 'white' },
    scrollbarWidth = 5,
}

C.textDocumentPageNumberSize = C.textDocumentNormalSize
C.textJournalPageNumberColor = C.fontColorJournalNormalText


return C
