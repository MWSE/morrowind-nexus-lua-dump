local fileHelper = require("tauer.dynamic-conversations.services.files.fileHelper")
local FILE_TYPE = require("tauer.dynamic-conversations.services.files.enums.FILE_TYPE")

--- Loads dialog lines from templates defined in JSON configuration files
---@class dialogTemplateLoader : initializedService
local this = {}

---@private
---@type string
this.fullTemplatesPath = "data files\\mwse\\config\\Dynamic Conversations\\dialog templates\\"

---@private
---@type string
this.relativeTemplatesPath = "Dynamic Conversations\\dialog templates\\"

---@private
---@type { [dialogTemplateName]: dialog[] }
this.templates = {}

---@public
---@return boolean
function this.initialize()
	local files = fileHelper.getAllFilesInDirectory(this.fullTemplatesPath, FILE_TYPE.json)
	if not files or table.size(files) == 0 then
		return false
	end

	for _, file in pairs(files) do
		local template, name = this.loadTemplate(file)
		if not template then
			return false
		end

		this.templates[name] = template
	end

	return true
end

--- Loads a random dialog line from the specified template
---@public
---@param templateName dialogTemplateName The name of the dialog template to load from
---@return dialog|nil dialog The randomly selected dialog line from the template, or nil if the template does not exist
function this.loadRandom(templateName)
	local template = this.templates[templateName]
	if not template then
		return nil
	end

	local dialog = table.choice(template) --[[@as dialog|nil]]
	return dialog and table.deepcopy(dialog)
end

--- Loads all dialog lines from the specified template
---@public
---@param templateName dialogTemplateName The name of the dialog template to load from
---@return dialog[] dialogs All dialog lines from the specified template
function this.loadAll(templateName)
	return this.templates[templateName]
end

---@private
---@param filePath string
---@return dialog[]|nil,string
function this.loadTemplate(filePath)
	local fileName = fileHelper.getFileName(filePath)
	return mwse.loadConfig(this.relativeTemplatesPath .. fileName, nil), fileName
end

return this
