-- thanks to:
-- https://www.nexusmods.com/morrowind/mods/57576?tab=files
-- https://www.nexusmods.com/morrowind/mods/53977?tab=files

local self = require('openmw.self')
local ui = require('openmw.ui')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local ambient = require('openmw.ambient')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local animation = require('openmw.animation')

local cmn = require('Scripts.Scribo.common')
local msg = core.l10n('Scribo', 'en')

local playerSettings = storage.playerSection('SettingsPlayerScribo')

local attributes = types.Actor.stats.attributes
local dynamic = types.Actor.stats.dynamic
local skills = types.NPC.stats.skills

local TextBox = nil
local CounterBox = nil

local editStart = false
local editDone = false

local empty = nil
local source = nil

local inventory = false
local content = ""
local title = ""
local wasChanged = false

local function hide()
    if editStart then
        if TextBox and TextBox.layout then
            TextBox:destroy()
        end
        if CounterBox then
            CounterBox:destroy()
        end
    end
    editStart = false
    editDone = false
    source = nil
    empty = nil

end

local function editBookDone(mouseEvent, data)
    --print("scribo: editBookDone")

    if wasChanged then
        core.sendGlobalEvent('ReCreateBook', {
            actor = self,
            source = source,
            empty = empty,
            title = title,
            content = content,
            inventory = inventory
        })
    end

    for _, mode in ipairs({"Scroll", "Book", "Interface"}) do
        I.UI.removeMode(mode)
    end
    hide()
end

local function editBookPage(data)
    --print("scribo: editBookPage")
    core.sendGlobalEvent('Pause', cmn.pauseTag)

    editStart = true
    wasChanged = false

    inventory = data.inventory
    source = data.source
    empty = data.empty
    content = data.content
    title = data.title

    local initTitle = title
    local initContent = content

    local sourceRecord = types.Book.record(data.source)

    -- для свитка
    local height = 0.55
    local width = 0.48

    local topleft = (1 - width) / 2
    local tophigh = (1 - height) / 2
    height = height + 0.1

    local button_width = 0.1
    local button_width_padd = (1 - button_width) / 2

    local textColor = util.color.rgb(130 / 255, 61 / 255, 15 / 255) -- cmn.colorName2Hex("black", availableColors) --

    if sourceRecord.id == cmn.dirtyPageID then
        textColor = util.color.rgb(92 / 255, 92 / 255, 92 / 255)
    else
        textColor = util.color.rgb(20 / 255, 20 / 255, 20 / 255)
    end

    local maxLengthTitle = 50
    local maxLengthText = data.maxLengthText

    local function finishEditBook()
        wasChanged = not (initTitle == title and initContent == content)
        editBookDone()
        core.sendGlobalEvent('Unpause', cmn.pauseTag)
    end

    local function update()
        TextBox.layout.content['title'].props.text = title
        TextBox.layout.content['content'].props.text = content
        TextBox:update()
    end

    local TitleEditing
    TitleEditing = { -- TITLE EDIT inside box
        template = I.MWUI.templates.textEditLine,
        name = "title",
        layer = 'Windows',
        type = ui.TYPE.TextEdit,
        props = {
            multiline = false,
            wordWrap = false,
            text = title,
            textSize = 30,
            textColor = textColor,
            relativeSize = util.vector2(0.6, 0.1),
            relativePosition = util.vector2(0.0, 0.0)
        },
        events = {
            textChanged = async:callback(function(text)
                if text:len() > maxLengthTitle then
                    -- say beep
                    ambient.playSoundFile('Sound/Fx/magic/miss.wav')
                    title = text:sub(1, maxLengthTitle)
                    update()
                else
                    title = text
                end
            end),
            keyPress = async:callback(function(keyEvent)
                if keyEvent.code == input.KEY.Enter and input.isCtrlPressed() then
                    finishEditBook()
                end
            end)
        }
    }

    local TextEditing = { -- TITLE EDIT inside box
        template = I.MWUI.templates.textEditBox,
        name = "content",
        layer = 'Windows',
        type = ui.TYPE.TextEdit,
        props = {

            multiline = true,
            wordWrap = true,
            relativeSize = util.vector2(0.6, 0.4),
            relativePosition = util.vector2(0.0, 0.2),
            text = content,
            textSize = 30,
            textColor = textColor

        },
        events = {
            textChanged = async:callback(function(text)
                local textLen = text:len()
                if maxLengthText ~= 0 and textLen > maxLengthText then
                    -- say beep
                    ambient.playSoundFile('Sound/Fx/magic/miss.wav')
                    content = text:sub(1, maxLengthText)
                    update()
                else
                    content = text
                    local left = maxLengthText - textLen
                    if left > 0 then
                        CounterBox.layout.content[1].props.text = msg("left", {
                            char = left
                        })
                        CounterBox:update()
                    end
                end
            end),
            keyPress = async:callback(function(keyEvent)
                if keyEvent.code == input.KEY.Enter and input.isCtrlPressed() then
                    finishEditBook()
                end
            end)
        }
    }

    local Button = { -- TITLE BUTTON
        template = I.MWUI.templates.textNormal,
        name = "button",
        layer = 'Windows',
        type = ui.TYPE.Text,
        props = {
            relativeSize = util.vector2(button_width, 0.1),
            relativePosition = util.vector2(button_width_padd, 0.9),
            text = msg("done"),
            textSize = 20,
            textColor = textColor,
            textShadow = true,
            textAlignH = ui.ALIGNMENT.Center
        },
        events = {
            mousePress = async:callback(finishEditBook),
            keyPress = async:callback(function(keyEvent)
                if keyEvent.code == input.KEY.Enter then
                    finishEditBook()
                end
            end)
        }
    }

    TextBox = ui.create({ -- THE BOX
        name = "TitleBox",
        layer = 'Windows',
        type = ui.TYPE.Widget,
        -- template = I.MWUI.templates.borders,
        props = {
            -- autoSize = true,
            -- horizontal = false, 
            relativeSize = util.vector2(width, height),
            relativePosition = util.vector2(topleft, tophigh)
        },
        content = ui.content {TitleEditing, TextEditing, Button}
    })

    if maxLengthText > 0 then
        local Counter = {
            layer = 'Windows',
            template = I.MWUI.templates.boxSolid,
            props = {
                relativeSize = util.vector2(button_width, 0.1),
                relativePosition = util.vector2(button_width_padd, 0.9)
                -- size = v2(163, 63),    
            },

            content = ui.content {{
                layer = 'Windows',
                type = ui.TYPE.Text,
                name = "text",
                template = I.MWUI.templates.textNormal,
                props = {
                    text = msg("left", {
                        char = maxLengthText
                    })
                }
            }}
        }

        CounterBox = ui.create(Counter)
    end
end

local function processingItem(data)
    --print("processingItem")

    local key = playerSettings:get('scrbKey')

    local needAction = (key == "Shift" and input.isShiftPressed() or key == "Ctrl" and input.isCtrlPressed() or key ==
                           "Alt" and input.isAltPressed())
    if types.Actor.isSwimming(self) then
        needAction = false
    end
    data.needAction = needAction
    data.asHTML = playerSettings:get('scrbEditAsHTML')
    data.uncontrolEdit = playerSettings:get('scrbUncontrolEdit')
    data.disableEdit = playerSettings:get('scrbDisableEdit')

    if data.misc then
        core.sendGlobalEvent('MakeOrigami', data)
    else
        core.sendGlobalEvent('WriteBook', data)
    end
end

local function damageIntel(data)
    attributes.intelligence(self).damage = attributes.intelligence(self).damage + data.value
end
local function boostAgility(data)
    attributes.agility(self).modifier = attributes.intelligence(self).modifier + data.value
end
local function spendMagika(data)
    dynamic.magicka(self).current = dynamic.magicka(self).current - dynamic.magicka(self).base / 100 * data.value
end
local function spendFatigue(data)
    dynamic.fatigue(self).current = dynamic.fatigue(self).current - dynamic.fatigue(self).base / 100 * data.value
end

local shown = false
local function onFrame()
    local currentMode = I.UI.getMode()
    local isEditingMode = currentMode == "Scroll" or currentMode == "Book"

    if isEditingMode then
        shown = true
    elseif shown and not isEditingMode then
        shown = false
        hide()
        core.sendGlobalEvent('Unpause', cmn.pauseTag)
    end
end

local fadeScreen = nil
local fadeScreenText = nil
local FADE_TEXT = msg("fadeScreenText")
local TEXT_SIZE = 28
local overlayLayerName = "SCREEN_FADE_LAYER"
local function getTopmostLayerName()
    local lastName = 'HUD' -- there is always at least HUD
    for i, layer in ipairs(ui.layers) do
        lastName = layer.name
    end
    return lastName
end

local function promoteOverlayLayerIfNeeded()
    local myIndex = ui.layers.indexOf(overlayLayerName)
    local topName = getTopmostLayerName()
    local topIndex = ui.layers.indexOf(topName)
    if myIndex and topIndex and myIndex < topIndex then
        overlayLayerName = overlayLayerName .. "_top"
        ui.layers.insertAfter(topName, overlayLayerName, {
            interactive = true
        })
    end
end

local function ensureOverlayLayerExists()
    if ui.layers.indexOf(overlayLayerName) then
        promoteOverlayLayerIfNeeded()
        return
    end

    local afterName = getTopmostLayerName()
    ui.layers.insertAfter(afterName, overlayLayerName, {
        interactive = true
    })
end

local function unfade()
    if fadeScreenText then
        fadeScreenText:destroy()
        fadeScreenText = nil
    end
    if fadeScreen then
        fadeScreen:destroy()
        fadeScreen = nil
    end
end
local function fade()
    unfade()
    ensureOverlayLayerExists()

    local BLACK_PATH = "textures/scribo/ptc_black.png"
    fadeScreen = ui.create {
        layer = overlayLayerName,
        type = ui.TYPE.Image,
        props = {
            autoSize = false,
            size = ui.screenSize(), -- fill window
            resource = ui.texture {
                path = BLACK_PATH
            }
        },
        name = 'fade_bg'
    }

    fadeScreenText = ui.create {
        layer = overlayLayerName,
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            text = FADE_TEXT,
            textSize = TEXT_SIZE,
            textColor = util.color.rgb(1, 1, 1),
            textShadow = true
        },
        name = 'fade_label'
    }
end

return {
    eventHandlers = {
        ProcessingItem = processingItem,
        EditBookPage = editBookPage,
        DamageIntel = damageIntel,
        SpendMagika = spendMagika,
        SpendFatigue = spendFatigue,
        BoostAgility = boostAgility,
        Fade = fade,
        Unfade = unfade,

        ShowMessage = function(data)
            ui.showMessage(data.message)
        end
    },
    engineHandlers = {
        onFrame = onFrame
    }
}
