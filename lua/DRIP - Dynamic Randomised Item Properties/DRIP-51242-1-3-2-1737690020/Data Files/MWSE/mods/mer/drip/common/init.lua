local Common = {}
local config = require("mer.drip.config")
Common.config = require("mer.drip.config")
local logger = require("logging.logger")
local logLevel = Common.config.mcm.logLevel
local loggers = {}
Common.createLogger = function(serviceName)
    local thisLogger = logger.new{
        name = string.format("%s: %s", Common.config.modName, serviceName),
        logLevel = logLevel
    }
    table.insert(loggers, thisLogger)
    return thisLogger
end
Common.updateLoggers = function(newLogLevel)
    for _, logger in ipairs(loggers) do
        logger:setLogLevel(newLogLevel)
    end
end

function Common.getVersion()
    return config.metadata.package.version
end

Common.getAllLootObjectIds = function()
    local objectIds = {}
    table.copy(Common.config.armor, objectIds)
    table.copy(Common.config.weapons, objectIds)
    table.copy(Common.config.clothing, objectIds)
    return objectIds
end

---@param obj tes3object
Common.canBeDripified = function(obj)
    local objIds = Common.getAllLootObjectIds()
    return objIds[obj.id:lower()] ~= nil
end

local propertiesToCopy = { "condition" }
---@param e { itemData: tes3itemData, object: tes3object|tes3armor, baseObject: tes3object|tes3armor, soul: tes3object}
Common.copyItemData = function(e)
    	-- Blacklist books, because the game does weird things with them. Can revert after MWSE fixes this behavior.
	if (e.baseObject.objectType == tes3.objectType.book) then
		return
	end

	-- Was there a script? If so copy it over.
	if (e.baseObject.script) then
		e.object.script = e.baseObject.script
	end

	local itemData = nil
	if (e.object.script) then
		itemData = tes3.player.object.inventory:findItemStack(e.object).variables[1]
		mwse.log("Inherited item data")
	else
		itemData = tes3.addItemData({ to = tes3.player, item = e.object })
		mwse.log("Created itemData through tes3.addItemData")
	end

    -- Copy over basic properties.
    for _, property in ipairs(propertiesToCopy) do
        itemData[property] = e.itemData[property]
    end

    if e.itemData.data then
        mwse.log("has data, copying into itemData")
        for k, v in pairs(e.itemData.data) do
            itemData.data[k] = v
        end
    end

    if e.itemData.tempData then
        for k, v in pairs(e.itemData.tempData) do
            itemData.tempData[k] = v
        end
    end
end


return Common