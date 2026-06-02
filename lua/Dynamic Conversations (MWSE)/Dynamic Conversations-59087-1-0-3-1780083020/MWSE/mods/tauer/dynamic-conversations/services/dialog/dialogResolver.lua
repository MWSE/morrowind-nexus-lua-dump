local dialogTemplateLoader = require("tauer.dynamic-conversations.services.dialog.dialogTemplateLoader")
local animationTemplateLoader = require("tauer.dynamic-conversations.services.animations.animationTemplateLoader")

local logger = mwse.Logger.new()

--- Provides functionality to resolve dialog lines and associated resources from conversation configurations
---@class dialogResolver
local this = {}

--- Resolves a concrete dialog line for a given dialog index
---@public
---@param params resolveDialogParams
---@return dialog|nil dialog The resolved dialog line, or nil if resolution failed
function this.resolve(params)
    local dialogIndex = params.index
    local configuration = params.configuration

    local dialog = this.resolveDialogOrTemplate(table.deepcopy(configuration.dialog[dialogIndex]))
    if not dialog then
        logger:error("Could not resolve dialog at index %d", dialogIndex)
        return nil
    end

    dialog.animation = this.resolveAnimationOrTemplate(dialog)
    dialog.soundPath = this.resolveSoundPath(dialog, configuration, params.race, params.sex)
    dialog.duration = this.calculateDuration(dialog.soundPath)

    return dialog
end

---@private
---@param dialog dialog
---@return dialog|nil
function this.resolveDialogOrTemplate(dialog)
    if not dialog.template then
        return dialog
    end

    local template = dialogTemplateLoader.loadRandom(dialog.template)
    if not template then
        logger:error("Could not load dialog template '%s'", dialog.template)
        return nil
    end

    -- Prioritize configured dialog animation over template animation
    template.animation = dialog.animation or template.animation

    return template
end

---@private
---@param dialog dialog
---@return animation|nil
function this.resolveAnimationOrTemplate(dialog)
    local animation = dialog.animation

    if not animation then
        return animationTemplateLoader.loadRandom("talk")
    end

    if animation.template then
        return animationTemplateLoader.loadRandom(animation.template)
    end

    return animation
end

---@private
---@param dialog dialog
---@param configuration conversationConfiguration
---@param race string
---@param sex SEX
---@return filePath
function this.resolveSoundPath(dialog, configuration, race, sex)
    local soundPath = dialog.soundPath
    if not configuration.conditions or not configuration.conditions.raceAndSex then
        return soundPath
    end

    local path = dialog.soundPath:gsub("%%RACE%%", race):gsub("%%SEX%%", sex)
    return path
end

---@private
---@param soundPath filePath
---@return number
function this.calculateDuration(soundPath)
    local fileSize = lfs.attributes(string.format("data files\\sound\\%s", soundPath), "size")
    local bitRateBytePerSeconds = 64000
    local duration = fileSize / (bitRateBytePerSeconds / 8)
    return duration + 0.85
end

return this
