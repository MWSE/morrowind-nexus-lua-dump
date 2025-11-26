local settings = require("scripts.openmw_books_enhanced.settings")
local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")
local util = require('openmw.util')
local ui = require('openmw.ui')
local vfs = require('openmw.vfs')

-- function courtesy of @pwn - thanks!
local function readFont(file)
    local temp = file:reverse()
    local fileNameLength = temp:find("/") - 1
    local path = file:sub(1, -fileNameLength - 1)
    local maxHeight = 0
    local minYOffset = 99999
    local lines = {}
    for line in vfs.lines(file) do
        table.insert(lines, line)
    end

    local glyphData = {}
    for i = 2, #lines do
        if i < 5 or lines[i]:sub(1, 4) == "char" then
            glyphData[i] = {}
            for a in lines[i]:gmatch("%S+") do
                local delimiterPos = a:find("=")
                if delimiterPos then
                    glyphData[i][a:sub(1, delimiterPos - 1)] = a:sub(delimiterPos + 1, #a)
                end
            end
        end
    end

    local glyphFile = path .. glyphData[3].file:sub(2, -2)
    local lineHeight = glyphData[2].lineHeight
    local glyphs = {}
    for i = 5, #glyphData do
        minYOffset = math.min(minYOffset, tonumber(glyphData[i].yoffset))
    end
    for i = 5, #glyphData do
        glyphData[i].yoffset = tonumber(glyphData[i].yoffset) --minYOffset
        maxHeight = math.max(maxHeight, tonumber(glyphData[i].height) + tonumber(glyphData[i].yoffset))
    end
    local minXOffset = 0
    local maxXOffset = 0
    local minYOffset = 0
    local maxYOffset = 0
    for i = 5, #glyphData do
        local character = string.char(tonumber(glyphData[i].id))
        glyphs[character] = {
            xadvance = tonumber(glyphData[i].xadvance),
            xoffset  = tonumber(glyphData[i].xoffset),
            yoffset  = tonumber(glyphData[i].yoffset),
            height   = tonumber(glyphData[i].height),
            width    = tonumber(glyphData[i].width),
            texture  = ui.texture {
                path = glyphFile,
                offset = util.vector2(tonumber(glyphData[i].x), tonumber(glyphData[i].y)),
                size = util.vector2(tonumber(glyphData[i].width), tonumber(glyphData[i].height))
            }
        }
        minXOffset = math.min(minXOffset, glyphs[character].xoffset)
        maxXOffset = math.max(maxXOffset, glyphs[character].xoffset)
        minYOffset = math.min(minYOffset, glyphs[character].yoffset)
        maxYOffset = math.max(maxYOffset, glyphs[character].yoffset)
    end
    return {
        glyphs = glyphs,
        lineHeight = lineHeight,
        base = glyphData[2].base,
        maxYOffset = math.abs(minYOffset) + math.abs(maxYOffset),
        starterXOffset = math.abs(minXOffset),
        starterYOffset = math.abs(minYOffset),
    }
end

local demonicLettersFontData = readFont("textures/openmw_books_enhanced/font_faces/512/DemonicLetters.fnt")
local pentagramFontData = readFont("textures/openmw_books_enhanced/font_faces/512/PentaGramMalefissent.fnt")

local D = {}

function D.makeDaedricPhraseContents(text, formattingSettings)
    local resultPhraseContents = {}
    local resultWidth = 0
    local resultHeight = 0

    local currentCharacterStep = 1
    local letterSize = settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()

    local textColor = constants.fontColorJournalNormalText
    if formattingSettings and formattingSettings.newFontColor then
        textColor = util.color.hex(formattingSettings.newFontColor)
    end

    local rescaleMultiplier = 1.1
    local fontData = demonicLettersFontData
    if settings.SettingsTravOpenmwBooksEnhanced_daedricDisplay() == "SettingsTravOpenmwBooksEnhanced_daedricDisplay_battlespireFont" then
        fontData = pentagramFontData
        rescaleMultiplier = 1.3 --because it's a bit small
    end

    rescaleMultiplier = rescaleMultiplier * (letterSize / fontData.base)

    while currentCharacterStep <= #text do
        local thisCharacter = string.sub(text, currentCharacterStep, currentCharacterStep)
        if fontData.glyphs[thisCharacter] then
            local glyphData = fontData.glyphs[thisCharacter]

            local thisGlyph = {
                type = ui.TYPE.Image,
                props = {
                    visible = true,
                    -- resource = constants.whiteTexture,
                    -- color = util.color.rgb(math.random(), math.random(), math.random()),
                    size = util.vector2(
                        math.max(
                            glyphData.xadvance,
                            fontData.starterXOffset + glyphData.xoffset + glyphData.width),
                        fontData.maxYOffset + glyphData.height
                    ),
                },
                userData = {
                    width = glyphData.xadvance,
                    height = fontData.maxYOffset + glyphData.height,
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = glyphData.texture,
                            visible = true,
                            position = util.vector2(
                                fontData.starterXOffset + glyphData.xoffset,
                                fontData.starterYOffset + glyphData.yoffset
                            ),
                            size = util.vector2(glyphData.width, glyphData.height),
                            color = textColor,
                        },
                    }
                })
            }

            thisGlyph.userData.width = thisGlyph.userData.width * rescaleMultiplier
            thisGlyph.userData.height = thisGlyph.userData.height * rescaleMultiplier
            thisGlyph.props.size = thisGlyph.props.size * rescaleMultiplier
            thisGlyph.content[1].props.size = thisGlyph.content[1].props.size * rescaleMultiplier
            thisGlyph.content[1].props.position = thisGlyph.content[1].props.position * rescaleMultiplier

            resultWidth = resultWidth + thisGlyph.userData.width
            resultHeight = math.max(resultHeight, thisGlyph.userData.height)
            table.insert(resultPhraseContents, thisGlyph)
        end
        currentCharacterStep = currentCharacterStep + 1
    end

    return {
        content = resultPhraseContents,
        width = resultWidth,
        height = resultHeight,
    }
end

return D
