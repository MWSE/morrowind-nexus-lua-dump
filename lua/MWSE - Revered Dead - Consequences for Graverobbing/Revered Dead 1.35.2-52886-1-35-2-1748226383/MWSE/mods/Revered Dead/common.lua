local common = {}
local config = require("Revered Dead.config")
local strings = require("Revered Dead.strings")

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

common.checkCellWhitelisted = function(playerCell)
    for _, cell in pairs(config.cell_whitelist) do
        if cell == playerCell.displayName then
            common.log:debug("%s was on the cell whitelist.", playerCell.displayName)
            return true
        end
    end
    return false
end

common.checkItemType = function(objType)
    if (objType == tes3.objectType.alchemy and config.excludeAlchemy == false) then
        return true
    elseif (objType == tes3.objectType.apparatus and config.excludeApparatus == false) then
        return true
    elseif (objType == tes3.objectType.armor and config.excludeArmor == false) then
        return true
    elseif (objType == tes3.objectType.clothing and config.excludeClothing == false) then
        return true
    elseif (objType == tes3.objectType.ingredient and config.excludeIngredient == false) then
        return true
    elseif (objType == tes3.objectType.lockpick and config.excludeLockpick == false) then
        return true
    elseif (objType == tes3.objectType.miscItem and config.excludeMisc == false) then
        return true
    elseif (objType == tes3.objectType.probe and config.excludeProbe == false) then
        return true
    elseif (objType == tes3.objectType.repairItem and config.excludeRepair == false) then
        return true
    elseif (objType == tes3.objectType.weapon and config.excludeWeapon == false) then
        return true
    else
        return false
    end
end

common.getCleanCost = function(merchant)
    common.log:debug("Evaluating base cost for merchant: " .. merchant.reference.object.id)
    if merchant.object.faction and merchant.object.faction.id == "Camonna Tong" then -- Relam Arinith
        return 100
    else -- Otherwise, it's Sold Fine-Hair
        return 50 
    end

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


common.showCleaningMenu = function(e)
    local merchant = tes3ui.getServiceActor()
    local cleanerCost = common.getCleanCost(merchant)
    local cleaningItem = e.itemData
    if e.item then
        common.log:debug("Menu handling " .. e.item.id)
        local finalCost = (math.round(((config.cleanCost / 100) * e.item.value) + cleanerCost))
        common.log:debug("Final Cost Value is now" .. finalCost)
        tes3ui.showMessageMenu({
            message = "Obfuscate the origin of this " .. e.item.name .. " for " .. finalCost .. " gold?",
            buttons = {
                {
                    text = "Confirm",
                    callback = function()
                        common.log:debug("Confirmation box: Confirmed")
                        common.doCleaning(cleaningItem, merchant, finalCost)
                    end
                },
                {
                    text = "Cancel" 
                },
                cancels = true
            }
        })
    end
end

common.doCleaning = function(cleaningItem, merchant, finalCost)
    local playerGold = tes3.getPlayerGold()
    if playerGold >= finalCost then
        if cleaningItem and cleaningItem.data.reveredDead then
            
            cleaningItem.data.reveredDead.isGraveGoods = false
            cleaningItem.data.reveredDead.isExtremeGraveGoods = false
            tes3.transferItem({
                from = tes3.player,
                to = merchant,
                item = "gold_001",
                count = finalCost
            })
        else
            common.log:debug("Item has no RD data, skipping.")
        end
    else
        tes3.messageBox(strings.cleanTooExpensive)
    end
    dofile("Revered Dead.smugglerclean")
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
    common.log:debug("Reached assignment phase...")
    if not gravegood.data.reveredDead or isStolen == false then
        if ((common.checkWhitelisted(refObject) == false and common.checkItemType(refObject.objectType) == true and refObject.value >= config.minSuspiciousValue or isStolen == false)) then
            gravegood.data.reveredDead = {}
            gravegood.data.reveredDead.isGraveGoods = isStolen
            if (common.checkBlacklisted(refObject) or refObject.value >= config.minAlarmingValue) then
                if config.inconspicuousArtifacts == false or (config.inconspicuousArtifacts == true and not common.CheckIsArtifact(refObject)) then
                    gravegood.data.reveredDead.isExtremeGraveGoods = isStolen
                end
            end
        end
    end
end



return common