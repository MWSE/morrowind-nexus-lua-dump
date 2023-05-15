local common = {}
common.mod = "Furniture Catalogue"
local furnConfig = require("JosephMcKean.furnitureCatalogue.furnConfig")

local config = require("JosephMcKean.furnitureCatalogue.config")
local logging = require("logging.logger")

---@type mwseLogger
common.log = logging.new({ name = "common", logLevel = config.debugMode and "DEBUG" or "INFO" })
common.loggers = { common.log }
-- create loggers for services of this mod 
common.createLogger = function(serviceName)
	local logger = logging.new { name = string.format("Furniture Catalogue - %s", serviceName), logLevel = config.debugMode and "DEBUG" or "INFO" }
	table.insert(common.loggers, logger)
	return logger -- return a table of logger
end

---@param obj tes3object
---@return furnitureCatalogue.furniture?
function common.getFurniture(obj)
	local craftableId = obj.id
	local prefix = "jsmk_fc_crate_"
	if string.startswith(craftableId:lower(), prefix) then
		local index = string.gsub(craftableId, prefix, "")
		return furnConfig.furniture[index]
	end
end

---@param ref tes3reference
---@return boolean
function common.isAshlander(ref)
	local faction = ref.object.faction
	if faction and faction.id == "Ashlanders" then
		common.log:debug("%s is an Ashlander", ref.id)
		return true
	end
	common.log:debug("%s is not an Ashlander", ref.id)
	return false
end

return common
