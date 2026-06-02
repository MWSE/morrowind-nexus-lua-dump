local fileHelper = require("tauer.dynamic-conversations.services.files.fileHelper")
local FILE_TYPE = require("tauer.dynamic-conversations.services.files.enums.FILE_TYPE")

--- Loads animations from templates defined in JSON configuration files
---@class animationTemplateLoader : initializedService
local this = {}

---@private
---@type string
this.fullTemplatesPath = "data files\\mwse\\config\\Dynamic Conversations\\animation templates\\"

---@private
---@type string
this.relativeTemplatesPath = "Dynamic Conversations\\animation templates\\"

---@private
---@type { [animationTemplateName]: animation[] }
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

--- Loads a random animation from the specified template
---@public
---@param templateName animationTemplateName The name of the animation template to load from
---@return animation|nil animation The randomly selected animation from the template, or nil if the template does not exist
function this.loadRandom(templateName)
	local template = this.templates[templateName]
	if not template then
		return nil
	end

	local animation = table.choice(template) --[[@as animation|nil]]
	return animation and table.deepcopy(animation)
end

--- Loads all animations from the specified template
---@public
---@param templateName animationTemplateName The name of the animation template to load from
---@return animation[] animations All animations from the specified template
function this.loadAll(templateName)
	return this.templates[templateName]
end

---@private
---@param filePath string
---@return animation[]|nil,string
function this.loadTemplate(filePath)
	local fileName = fileHelper.getFileName(filePath)
	return mwse.loadConfig(this.relativeTemplatesPath .. fileName, nil), fileName
end

return this
