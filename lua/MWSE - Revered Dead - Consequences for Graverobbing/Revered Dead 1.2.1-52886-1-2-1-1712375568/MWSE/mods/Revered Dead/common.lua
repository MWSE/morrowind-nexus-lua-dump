local common = {}
local config = require("Revered Dead.config")

local logger = require("logging.logger")
common.log = logger.new{
    name = "Revered Dead",
    logLevel = config.logLevel,
}

common.log:setLogLevel(config.logLevel)

common.checkIsEmpire = function(actor)
    if actor.faction and (actor.faction.id == "Imperial Cult" or actor.faction.id == "Imperial Legion" or actor.faction.id == "Blades" or actor.faction.id == "Imperial Knights" or actor.faction.id == "Census and Excise") then
        return true
    else
        return false
    end
end

common.checkBlacklisted = function(gravegood)
    for _, item in pairs(config.blacklist) do
        if item == gravegood.id then
            common.log:debug("%s was on the config blacklist.", gravegood.id)
            return true
        end
    end
    return false
end

common.checkWhitelisted = function(gravegood)
    for _, item in pairs(config.whitelist) do
        if item == gravegood.id then
            common.log:debug("%s was on the config whitelist.", gravegood.id)
            return true
        end
    end
    return false
end

common.CheckIsArtifact = function(gravegood)
    for _, item in pairs(config.unique_whitelist) do
        if item == gravegood.id then
            common.log:debug("%s was on the special artifact whitelist.", gravegood.id)
            return true
        end
    end
    return false
end

common.checkIsGraveGoods = function(offeredItems)
	for _, tile in ipairs(offeredItems) do
		if tile.itemData and (tile.itemData.data.reveredDead and (tile.itemData.data.reveredDead.isGraveGoods == true)) then
			return tile.item
		end
	end
	return false
end

common.checkIsExtremeGraveGoods = function(offeredItems)
	for _, tile in ipairs(offeredItems) do
		if tile.itemData and (tile.itemData.data.reveredDead and (tile.itemData.data.reveredDead.isExtremeGraveGoods == true)) then
			return tile.item
		end
	end
	return false
end

common.triggerTradeMenuClose = function()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
    local cancelButton = menu:findChild(tes3ui.registerID("MenuBarter_Cancelbutton"))
    cancelButton:triggerEvent("mouseClick")
end

common.triggerDialogueMenuClose = function()
    local dialogueMenu = tes3ui.findMenu("MenuDialog")
    local byeButton = dialogueMenu:findChild(tes3ui.registerID("MenuDialog_button_bye"))
    byeButton:triggerEvent("mouseClick")
end

common.handleContainerItems = function(ref, force_unstolen)
    if common.checkWhitelisted(ref) then
        common.log:debug("Container %s was skipped due to whitelist.", ref.id)
        return
    end
    for _, stack in pairs(ref.object.inventory) do
        if stack.object.supportsLuaData == true then
            if (stack.object.objectType ~= tes3.objectType.leveledItem) and (stack.object.objectType ~= tes3.objectType.book) then
                local itemData = stack.variables and stack.variables[1]
                if not itemData then
                    itemData = tes3.addItemData{to = ref, item = stack.object}
                end
                if force_unstolen == true then
                    common.assignGraveGoodData(itemData, false, stack.object)
                else
                    common.assignGraveGoodData(itemData, true, stack.object)
                end
            end
        end
    end
end

common.assignGraveGoodData = function(gravegood, isStolen, refObject)
    if not gravegood.data.reveredDead then
        if common.checkWhitelisted(refObject) == false and refObject.value >= config.minSuspiciousValue then
            gravegood.data.reveredDead = {}
            gravegood.data.reveredDead.isGraveGoods = isStolen
            if common.checkBlacklisted(refObject) or refObject.value >= config.minAlarmingValue then
                if config.inconspicuousArtifacts == false or (config.inconspicuousArtifacts == true and not common.CheckIsArtifact(refObject)) then
                    gravegood.data.reveredDead.isExtremeGraveGoods = true
                end
            end
        end
    end
end

return common