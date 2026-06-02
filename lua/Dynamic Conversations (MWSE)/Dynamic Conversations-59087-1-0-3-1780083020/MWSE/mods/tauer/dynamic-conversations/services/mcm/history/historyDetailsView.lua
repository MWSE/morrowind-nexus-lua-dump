local guiBuilder = require("tauer.dynamic-conversations.services.gui.guiBuilder")
local translations = require("tauer.dynamic-conversations.services.translations.translations")
local dialogResolver = require("tauer.dynamic-conversations.services.dialog.dialogResolver")
local conversationHistory = require("tauer.dynamic-conversations.services.conversations.conversationHistoryController")
local historyPlayer = require("tauer.dynamic-conversations.services.mcm.history.historyPlayer")

local ID = require("tauer.dynamic-conversations.services.mcm.enums.ID")
local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

--- Renders conversation history details in the MCM
---@class historyDetailsView : initializedService
local this = {}

---@private
---@type tes3uiElement|nil
this.root = nil

---@private
this.speakerColors = {
    { 0.75, 0.55, 0.15 },
    { 0.45, 0.30, 0.65 },
}

---@private
this.textures = {
    playButtonIdle = "textures/tauer/dynamic-conversations/play-button-idle.tga",
    playButtonOver = "textures/tauer/dynamic-conversations/play-button-over.tga",
    playButtonPressed = "textures/tauer/dynamic-conversations/play-button-pressed.tga",

    stopButtonIdle = "textures/tauer/dynamic-conversations/stop-button-idle.tga",
    stopButtonOver = "textures/tauer/dynamic-conversations/stop-button-over.tga",
    stopButtonPressed = "textures/tauer/dynamic-conversations/stop-button-pressed.tga",
}

---@public
---@return boolean
function this.initialize()
    event.register(EVENTS.conversationHistoryPlay, this.onConversationHistoryPlay)
    event.register(EVENTS.conversationHistoryPlayStop, this.onConversationHistoryPlayStop)
    return true
end

--- Builds the conversation history details view
---@public
---@param configuration conversationConfiguration The conversation configuration to display details for
---@param root tes3uiElement The root UI element of the conversation history MCM page
function this.build(configuration, root)
    this.root = root

    local details = this.tryResolveElement(ID.conversationHistoryDetailsBorder)
    if details then
        details:destroy()
    end

    local historyConfiguration = this.resolveConfiguration(configuration)
    if not historyConfiguration then
        logger:error("Failed to resolve configuration for conversation '%s'", configuration.id)
        return
    end

    this.createDetailsContainer(historyConfiguration)
    this.createDetailsContents(historyConfiguration)

    this.root:updateLayout()
end

---@private
---@param configuration conversationConfiguration
---@return historyConfiguration|nil
function this.resolveConfiguration(configuration)
    local speakers = this.resolveSpeakers(configuration)
    local dialog = {}

    for i, _ in ipairs(configuration.dialog) do
        local speakerIndex = (i - 1) % 2 + 1
        local speaker = speakers[speakerIndex]

        local resolvedDialog = dialogResolver.resolve({
            index = i,
            configuration = configuration,
            race = speaker.race,
            sex = speaker.sex,
        })

        if not resolvedDialog then
            return nil
        end

        table.insert(dialog, resolvedDialog)
    end

    return {
        id = configuration.id,
        name = configuration.name,
        dialog = dialog,
        speakers = speakers,
    }
end

---@private
---@param configuration historyConfiguration
function this.createDetailsContainer(configuration)
    local inner = this.mustResolveElement(ID.conversationHistoryInnerContainer)
    if not inner then
        return
    end

    local details = guiBuilder.createThinBorder({
            parent = inner,
            id = ID.conversationHistoryDetailsBorder,
        })
        :withBorder({ top = 5, bottom = 5, left = 10 })
        :withMinSize({ width = 0, height = 500 })
        :withProportional({ width = 0.95 })
        :build()


    local scroll = guiBuilder.createVerticalScrollPane({
            parent = details,
        })
        :withProportional({ width = 1.0 })
        :build()

    local block = guiBuilder.createBlock({
            parent = scroll,
            id = ID.conversationHistoryDetailsBlock,
        })
        :withFlowDirection(tes3.flowDirection.topToBottom)
        :withProportional({ width = 1.0 })
        :withAutoHeight()
        :build()

    local _ = guiBuilder.createLabel({
            parent = block,
        })
        :withText(string.format("%s: %s", translations.get(TRANSLATION_KEY.nameLabel), configuration.name))
        :withPalette(tes3.palette.bigNotifyColor)
        :withBorder({ all = 5 })
        :build()

    local _ = guiBuilder.createLabel({
            parent = block,
        })
        :withText(string.format("%s: %s", translations.get(TRANSLATION_KEY.idLabel), configuration.id))
        :withPalette(tes3.palette.disabledColor)
        :withBorder({ all = 5 })
        :build()

    local buttons = guiBuilder.createBlock({
            parent = block,
        })
        :withFlowDirection(tes3.flowDirection.leftToRight)
        :withProportional({ width = 1.0 })
        :withAutoHeight()
        :withBorder({ top = 10 })
        :build()

    local _ = guiBuilder.createImageButton({
            parent = buttons,
            idle = this.textures.playButtonIdle,
            over = this.textures.playButtonOver,
            pressed = this.textures.playButtonPressed,
        })
        :withBorder({ left = 10 })
        :withSize({ width = 32, height = 32 })
        :withData("configuration", configuration)
        :withUICallback(tes3.uiEvent.mouseClick, this.onPlayButtonClicked)
        :build()

    local _ = guiBuilder.createImageButton({
            parent = buttons,
            idle = this.textures.stopButtonIdle,
            over = this.textures.stopButtonOver,
            pressed = this.textures.stopButtonPressed,
        })
        :withBorder({ left = 10 })
        :withSize({ width = 32, height = 32 })
        :withUICallback(tes3.uiEvent.mouseClick, this.onStopButtonClicked)
        :build()

    local _ = guiBuilder.createButton({
            parent = buttons,
        })
        :withText(translations.get(TRANSLATION_KEY.deleteButton))
        :withAutoSize()
        :withPositionAlign({ x = 1.0, y = 0.5 })
        :withBorder({ right = 10 })
        :withWidgetColors({
            idle = tes3ui.getPalette(tes3.palette.healthColor),
        })
        :withData("configuration", configuration)
        :withUICallback(tes3.uiEvent.mouseClick, this.onDeleteButtonClicked)
        :build()

    local _ = guiBuilder.createDivider({
        parent = block,
    })
end

---@private
---@param eventData tes3uiEventData
function this.onPlayButtonClicked(eventData)
    tes3.playSound({
        soundPath = "Fx/menu click.wav",
    })

    local configuration = eventData.source:getLuaData("configuration") --[[@as historyConfiguration]]

    historyPlayer.playConversation(configuration.dialog)
end

function this.onStopButtonClicked()
    tes3.playSound({
        soundPath = "Fx/menu click.wav",
    })

    historyPlayer.stop()
end

---@private
---@param configuration historyConfiguration
function this.createDetailsContents(configuration)
    local detailsBlock = this.mustResolveElement(ID.conversationHistoryDetailsBlock)
    if not detailsBlock then
        return
    end

    for i, dialog in ipairs(configuration.dialog) do
        local speakerIndex = (i - 1) % 2 + 1

        local speaker = configuration.speakers[speakerIndex]

        local entryBlock = guiBuilder.createBlock({
                parent = detailsBlock,
            })
            :withFlowDirection(tes3.flowDirection.leftToRight)
            :withProportional({ width = 1.0 })
            :withAutoHeight()
            :withBorder({ left = 10, right = 10, top = 10, bottom = 10 })
            :build()

        local _ = guiBuilder.createLabel({
                parent = entryBlock,
            })
            :withText(string.format("%s: ", speaker.name))
            :withColor(this.speakerColors[speakerIndex])
            :withBorder({ right = 5 })
            :build()

        local dialogBlock = guiBuilder.createBlock({
                parent = entryBlock,
                id = ID.conversationHistoryDetailsDialogBlock,
            })
            :withFlowDirection(tes3.flowDirection.topToBottom)
            :withProportional({ width = 1.0 })
            :withData("configuration", configuration)
            :withAutoHeight()
            :build()

        local _ = guiBuilder.createTextSelect({
                parent = dialogBlock,
                id = ID.conversationHistoryDetailsDialogEntry(i),
            })
            :withData("dialog", dialog)
            :withUICallback(tes3.uiEvent.mouseClick, this.onDialogClicked)
            :withUICallback(tes3.uiEvent.destroy, this.onDialogDestroyed)
            :withProportional({ width = 1.0 })
            :withWrapText()
            :withText(string.format("\"%s\"", dialog.subtitle))
            :build()
    end
end

---@private
---@param configuration conversationConfiguration
---@return conversationHistorySpeaker[]
function this.resolveSpeakers(configuration)
    local raceAndSex = configuration.conditions and configuration.conditions.raceAndSex
    local firstSpeaker = raceAndSex and table.choice(raceAndSex)
    local secondSpeaker = raceAndSex and table.choice(raceAndSex)

    ---@type conversationHistorySpeaker[]
    local speakers = {
        {
            name = configuration.participants and this.format(configuration.participants[1]) or "A",
            race = firstSpeaker and this.extractRace(firstSpeaker),
            sex = firstSpeaker and this.extractSex(firstSpeaker),
        },
        {
            name = configuration.participants and this.format(configuration.participants[2]) or "B",
            race = secondSpeaker and this.extractRace(secondSpeaker),
            sex = secondSpeaker and this.extractSex(secondSpeaker),
        }
    }

    return speakers
end

---@private
---@param speaker string
---@return string
function this.format(speaker)
    return (speaker:lower():gsub("(%a)([%w_'-]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

---@private
---@param input string
---@return string
function this.extractSex(input)
    return input:sub(-1)
end

---@private
---@param input string
---@return string
function this.extractRace(input)
    return input:sub(1, #input - 2):trim()
end

---@private
---@param eventData tes3uiEventData
function this.onDeleteButtonClicked(eventData)
    tes3ui.showMessageMenu {
        message = translations.get(TRANSLATION_KEY.deleteConversationConfirmation),
        callbackParams = {
            configurationId = eventData.source:getLuaData("configuration").id, --[[@as string]]
        },
        buttons = {
            { text = translations.get(TRANSLATION_KEY.yesButton), callback = this.onDeleteButtonConfirmed },
            { text = translations.get(TRANSLATION_KEY.noButton) }
        }
    }
end

---@private
function this.onDeleteButtonConfirmed(callback)
    conversationHistory.delete(callback.configurationId)

    event.trigger(EVENTS.conversationHistoryDeleted)
end

---@private
---@param _ tes3uiEventData
function this.onDialogDestroyed(_)
    historyPlayer.stop()
end

---@private
---@param eventData tes3uiEventData
function this.onDialogClicked(eventData)
    local dialog = eventData.source:getLuaData("dialog") --[[@as dialog]]

    historyPlayer.playDialog(dialog)
end

---@private
function this.onConversationHistoryPlayStop()
    local dialogBlock = this.tryResolveElement(ID.conversationHistoryDetailsDialogBlock)
    if not dialogBlock then
        return
    end

    local configuration = dialogBlock:getLuaData("configuration") --[[@as historyConfiguration]]

    for i, _ in ipairs(configuration.dialog) do
        local label = this.tryResolveElement(ID.conversationHistoryDetailsDialogEntry(i))
        if label then
            label.widget.idle = tes3ui.getPalette(tes3.palette.normalColor)
            label:updateLayout()
        end
    end
end

---@private
---@param eventData conversationHistoryPlayEventData
function this.onConversationHistoryPlay(eventData)
    local previous = this.tryResolveElement(ID.conversationHistoryDetailsDialogEntry(eventData.index - 1))
    if previous then
        previous.widget.idle = tes3ui.getPalette(tes3.palette.disabledColor)
        previous:updateLayout()
    end

    local current = this.mustResolveElement(ID.conversationHistoryDetailsDialogEntry(eventData.index))
    if current then
        current.widget.idle = tes3ui.getPalette(tes3.palette.fatigueColor)
        current:updateLayout()
    end
end

---@private
---@param id string
---@return tes3uiElement|nil
function this.mustResolveElement(id)
    local element = this.tryResolveElement(id)
    if not element then
        logger:error("UI Element '%s' not found!", id)
    end
    return element
end

---@private
---@param id string
---@return tes3uiElement|nil
function this.tryResolveElement(id)
    return this.root:findChild(id)
end

return this
