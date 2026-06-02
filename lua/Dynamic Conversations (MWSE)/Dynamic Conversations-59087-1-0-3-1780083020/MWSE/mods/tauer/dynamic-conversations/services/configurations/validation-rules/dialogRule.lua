local fileHelper = require("tauer.dynamic-conversations.services.files.fileHelper")
local FILE_TYPE = require("tauer.dynamic-conversations.services.files.enums.FILE_TYPE")
local dialogTemplateLoader = require("tauer.dynamic-conversations.services.dialog.dialogTemplateLoader")
local animationTemplateLoader = require("tauer.dynamic-conversations.services.animations.animationTemplateLoader")

-----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

--- Validation rule for dialog entries in conversation configurations
---@class DialogValidationRule: conversationValidationRule
local this = {}

---@type { [string]: boolean }
this.soundPathValidationCache = {}

---@type { [string]: boolean }
this.animationPathValidationCache = {}

---@type { [string]: boolean }
this.animationTemplateValidationCache = {}

---@public
---@param configuration conversationConfiguration
---@return boolean, reason|nil
function this.isMet(configuration)
	local dialog = configuration.dialog

	if not dialog or table.size(dialog) < 1 then
		return false, "dialog is missing"
	end

	for index, dialogEntry in pairs(dialog) do
		local valid, reason = this.validate(dialogEntry, configuration)
		if not valid then
			return false, string.format("dialog entry %d invalid because %s", index, reason)
		end
	end

	return true, nil
end

---@private
---@param dialog dialog
---@param configuration conversationConfiguration
---@return boolean, string|nil
function this.validate(dialog, configuration)
	if dialog.template and (dialog.subtitle or dialog.soundPath) then
		return false, "it has both template and subtitle/sound path"
	end

	if dialog.template then
		return this.validateTemplate(dialog.template, configuration)
	end

	return this.validateDialog(dialog, configuration)
end

---@private
---@param templateName string
---@param configuration conversationConfiguration
---@return boolean, string|nil
function this.validateTemplate(templateName, configuration)
	local dialogTemplate = dialogTemplateLoader.loadAll(templateName)
	if not dialogTemplate or table.size(dialogTemplate) < 1 then
		return false, string.format("dialog template '%s' not found", templateName)
	end

	for _, dialog in pairs(dialogTemplate) do
		local valid, reason = this.validateDialog(dialog, configuration)
		if not valid then
			return false, reason
		end
	end

	return true, nil
end

---@private
---@param dialog dialog
---@param configuration conversationConfiguration
---@return boolean, string|nil
function this.validateDialog(dialog, configuration)
	if not dialog.soundPath then
		return false, "sound path is missing"
	end

	if not dialog.subtitle then
		return false, "subtitle is missing"
	end

	if dialog.animation then
		local valid, reason = this.validateAnimation(dialog.animation)
		if not valid then
			return false, reason
		end
	end

	return this.validateSound(dialog, configuration)
end

---@private
---@param animation animation
---@return boolean, string|nil
function this.validateAnimation(animation)
	if animation.template and (animation.path or animation.group) then
		return false, "animation has both template and animation path/group"
	end

	if animation.template then
		return this.validateAnimationTemplate(animation.template)
	end

	return this.validateAnimationFile(animation)
end

---@private
---@param templateName animationTemplateName
---@return boolean, string|nil
function this.validateAnimationTemplate(templateName)
	if this.animationTemplateValidationCache[templateName] then
		return true, nil
	end

	local template = animationTemplateLoader.loadAll(templateName)
	if not template or table.size(template) < 1 then
		return false, string.format("animation template '%s' not found", templateName)
	end

	for _, animation in pairs(template) do
		local valid, reason = this.validateAnimationFile(animation)
		if not valid then
			return false, reason
		end
	end

	this.animationTemplateValidationCache[templateName] = true
	return true, nil
end

---@private
---@param animation animation
---@return boolean, string|nil
function this.validateAnimationFile(animation)
	if this.soundPathValidationCache[animation.path] then
		return true, nil
	end

	if not animation.path or not animation.group then
		return false, "animation path or group is missing"
	end

	if not fileHelper.isValidAnimationFile(animation.path) then
		return false, string.format("'%s' is not a valid animation file", animation.path)
	end

	if not tes3.animationGroup[animation.group] then
		return false, string.format("'%s' is not a valid animation group", animation.group)
	end

	this.animationPathValidationCache[animation.path] = true
	return true, nil
end

---@private
---@param dialog dialog
---@param configuration conversationConfiguration
---@return boolean, string|nil
function this.validateSound(dialog, configuration)
	if configuration.conditions and configuration.conditions.raceAndSex then
		for _, raceAndSex in pairs(configuration.conditions.raceAndSex) do
			local race, sex = this.splitRaceAndSex(raceAndSex)
			local soundPath = dialog.soundPath:gsub("%%RACE%%", race):gsub("%%SEX%%", sex)

			local valid, reason = this.validateSoundFile(soundPath)
			if not valid then
				return false, reason
			end
		end
		return true, nil
	end

	return this.validateSoundFile(dialog.soundPath)
end

---@private
---@param soundPath string
---@return boolean, string|nil
function this.validateSoundFile(soundPath)
	if this.soundPathValidationCache[soundPath] then
		return true, nil
	end

	if not fileHelper.isFileType(soundPath, FILE_TYPE.mp3) then
		return false, string.format("sound file at path '%s' is not a .mp3 file", soundPath)
	end

	local file = io.open(string.format("data files\\sound\\%s", soundPath), "r")
	if file then
		io.close(file)
		this.soundPathValidationCache[soundPath] = true
		return true, nil
	end

	return false, string.format("no sound file was found at path '%s'", soundPath)
end

---@private
---@param raceAndSex string
function this.splitRaceAndSex(raceAndSex)
	local race = string.sub(raceAndSex, 1, -2):gsub("^%s*(.-)%s*$", "%1")
	local sex = string.sub(raceAndSex, -1)
	return race, sex
end

return this
