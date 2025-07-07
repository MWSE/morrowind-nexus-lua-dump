local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local util = require('openmw.util')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local ambient = require('openmw.ambient')
local nearby = require('openmw.nearby')
local async = require('openmw.async')

config = require('scripts.QuickStack.config')

-- i10n/yaml doesn't work and I have no idea why. It keeps returning the key instead of the value when l10n('configtTitle') == "configTitle"
local l10n = core.l10n('QuickStack')
local commonData = require("scripts.QuickStack.commonData")

local transferGui = require('scripts.QuickStack.transferGui')

local activatedContainerInventory = nil
local activatedContainer = nil

local activatedNPC

local currentFollowers = {}

local stashContainer

local transferResult = {}

local autoCloseTransferGuiDuration = config.options.successVerboseNotificationAutoCloseDuration

local autoCloseTransferGui = async:registerTimerCallback('autoCloseTransferGui', function(data)
	transferGui.hideTransferResultBox()
end)

local function displayMessage(message)
	ui.showMessage(commonData.content.message.prefix.. message)
end

local function sentInventory(data)
	activatedContainer = data.container
	activatedContainerInventory = types.Container.inventory(data.container)
end

local function sentNPCInventory(data)
	activatedNPC = data.npc
end

local function sentFollowerActor(data)
	if #data.targets == 0 then 
		currentFollowers[data.actor.id] = nil
	elseif currentFollowers[data.actor.id] == nil then
		currentFollowers[data.actor.id] = data.actor
	end
end

local function getInventory(object)
	if tostring(object.type) == 'Container' then
		return types.Container.inventory(object)
	elseif tostring(object.type) == 'Actor' or tostring(object.type) == 'NPC' or tostring(object.type) == 'Player' then
		return types.Actor.inventory(object)
	end
end

local function quickStackComplete(hasTransfered)
	if hasTransfered == true then
		if config.options.isSuccessNotificationEnabled == true and config.options.isSuccessNotificationVerboseOrSimple == "Simple" then
			displayMessage(commonData.content.message.transferedItemsSuccess)
		end
		interfaces.UI.removeMode('Container')
		interfaces.UI.removeMode('Companion')
		ambient.playSoundFile("Sound\\Fx\\item\\item.wav")
		if config.options.isSuccessNotificationEnabled == true and config.options.isSuccessNotificationVerboseOrSimple == "Verbose" then
			-- send data to transferGUI
			transferGui.setTransferResultData(transferResult)
			-- show transferGui
			transferGui.showTransferResultBox()
			
			-- Timer for when to auto-close transfer menu
			async:newSimulationTimer(autoCloseTransferGuiDuration, autoCloseTransferGui)
		end
		return true
	else
		if config.options.isFailureNotificationEnabled == true then
			displayMessage(commonData.content.message.transferedNothing)
		end
		return false
	end
end

local function isCapacityValid(itemType, itemWeight, container, containerCapacity, containerEncumberance)
	if containerCapacity < (containerEncumberance + itemWeight) then
		local message = commonData.content.message.cannotTransferPrefix.. types.Container.record(container.recordId).name.. " ".. commonData.content.message.cannotTransferCapacity
		displayMessage(message)
		return false
	end
	return true
end

local function getSoulGemSoul(item)
	local soul = "none"
	if types.Item.itemData(item).soul ~= nil then
		soul = types.Item.itemData(item).soul
	end
	return soul
end

local function transferItems(destinationContainer, sourceContainer, item, count)
	local itemType = tostring(item.type)
	local itemWeight = types[itemType].record(item).weight
	local itemName = types[itemType].record(item).name
	--checking for over capacity
	if tostring(destinationContainer.type) == 'Container' then
		local containerEncumberance = types.Container.getEncumbrance(destinationContainer)
		local containerCapacity = types.Container.getCapacity(destinationContainer)
		if isCapacityValid(itemType, itemWeight, destinationContainer, containerCapacity, containerEncumberance) == false then return false end
	end
	-- Add to list of items/containers for the result pgae
	-- Need to get accruate count of the item by this point
	-- Get soulgem soulgem

	if types.Item.itemData(item).soul ~= nil then
		local soul = types.Item.itemData(item).soul
		local creature = types.Creature.record(soul)
		itemName = itemName.. " (".. creature.name.. ")"
	end
	
	--Build transfer result for transferGui
	if transferResult[destinationContainer.id] == nil then 
		transferResult[destinationContainer.id] = {}
		transferResult[destinationContainer.id].name = types[tostring(destinationContainer.type)].record(destinationContainer.recordId).name
		transferResult[destinationContainer.id].items = {}
	end
	if transferResult[destinationContainer.id].items[itemName] == nil then
		transferResult[destinationContainer.id].items[itemName] = count
	end
	core.sendGlobalEvent('ChangeInventory', {item=item, destinationContainer=destinationContainer, sourceContainer=sourceContainer, count=count})
	if tostring(destinationContainer.type) == 'Container' and containerEncumberance ~= nil then
		containerEncumberance = containerEncumberance + itemWeight
	end
	return true
end

local function quickStack(destinationContainer, sourceContainer)
	local destinationItems = getInventory(destinationContainer):getAll()
	local hasTransfered = false
	
	local destinationSoulGems = {}

	for _, item in pairs(destinationItems) do
		local sourceInventory = getInventory(sourceContainer)
		
		--Skip gold in stack if set in settings
		if string.find(item.recordId, "gold_001") ~= nil and config.options.isGoldTransferred == false then
			goto continue
		end
		--Soul gem handler
		if string.find(item.recordId, "misc_soulgem") ~= nil then
			local soul = getSoulGemSoul(item)
			
			--Build container soulgems to know what to look for in player inventory
			if destinationSoulGems[item.recordId] == nil then
				destinationSoulGems[item.recordId] = {}
			end
			if destinationSoulGems[item.recordId][soul] == nil then
				destinationSoulGems[item.recordId][soul] = 1
			end
			
			-- look through player inventory for gems in container soul gems
			for _, sourceItem in pairs(sourceInventory:getAll()) do
				if string.find(sourceItem.recordId, "misc_soulgem") ~= nil then
					local soul = getSoulGemSoul(sourceItem)
					if destinationSoulGems[sourceItem.recordId] ~= nil and destinationSoulGems[sourceItem.recordId][soul] ~= nil then
						--Use transferItems() here?
						hasTransfered = transferItems(destinationContainer, sourceContainer, sourceItem, sourceItem.count)
						--core.sendGlobalEvent('ChangeInventory', {item=playerItem, container=container, player=self.object})
						--hasTransfered = true
					end
				end
			end
		::continue::	
		--Non-Soulgems (fuck soulgems)
		else
			local sourceItem = sourceInventory:find(item.recordId)
			if sourceItem == nil then goto continue end
			local sourceCount = sourceInventory:countOf(item.recordId)
			local sourceItemStack = sourceInventory:findAll(item.recordId)
			local isTransferSuccess = false
			-- Case for multiple item stacks for the same item (IE repair hammers or lockpicks with different uses)
			if #sourceItemStack > 1 then
				for _, item in pairs(sourceItemStack)  do
					isTransferSuccess = transferItems(destinationContainer, sourceContainer, item, #sourceItemStack)
					if isTransferSuccess == false then
						break
					else
						hasTransfered = true
					end
				end
			--Basic transfer case
			elseif sourceCount > 0 then
				isTransferSuccess = transferItems(destinationContainer, sourceContainer, sourceItem, sourceItem.count)
			end
			if isTransferSuccess == false then
				break
			else
				hasTransfered = true
			end

		end
		::continue::
	end
	if hasTransfered == true then
		return true
	else
		return false
	end
end

local function singleQuickStack(destinationContainer, sourceContainer)
	hasTransfered = quickStack(destinationContainer, sourceContainer)
	quickStackComplete(hasTransfered)
end

local function buildValidContainerString(validContainers)
	local validContainersString = ""
	for i, container in pairs(validContainers) do
		if i == 1 then
			validContainersString = validContainersString.. container
		else
			validContainersString = validContainersString.. ", ".. container
		end
	end
	return validContainersString
end

local function containerValidations(container)
	local isValidContainer = true
	
	-- Check if container is locked
	if types.Lockable.isLocked(container) == true then 
		--local message = commonData.content.message.cannotTransferPrefix.. types.Container.record(container.recordId).name.. " ".. commonData.content.message.cannotTransferLocked
		--displayMessage(message)
		isValidContainer = false
	end
	
	--Check if 'organic"
	if types.Container.record(container.recordId).isOrganic == true then 
		--local message = commonData.content.message.cannotTransferPrefix.. types.Container.record(container.recordId).name.. " ".. commonData.content.message.cannotTransferOrganic
		--displayMessage(message)
		isValidContainer = false
	end
	
	--Check if container is owned or not?
	if container.owner.recordId ~= nil then
		--local message = commonData.content.message.cannotTransferPrefix.. types.Container.record(container.recordId).name.. " ".. commonData.content.message.cannotTransferOwned
		--displayMessage(message)
		isValidContainer = false
	end
	
	-- Check if container is "safe"/non-respawning
	if types.Container.record(container.recordId).isRespawning == true then 
		--If so, show prompt warning player and give them option to include/eclude from transfer?
		--local message = commonData.content.message.cannotTransferPrefix.. types.Container.record(container.recordId).name.. " ".. commonData.content.message.cannotTransferRespawning
		--displayMessage(message)
		isValidContainer = false
	end
	
	return isValidContainer
end

local function companionValidations(actor)
	local isValid = true
	
	return isValid
end

local function isDestinationWithinArea(destination, source)
	local sourcePosition = source.position
	local destinationPosition = destination.position

	local positionDifference = sourcePosition - destinationPosition
	
	local xDistanceLimit = config.options.distanceHorizontal
	local yDistanceLimit = config.options.distanceHorizontal
	local zDistanceLimit = config.options.distanceVertical
	if ((positionDifference.x < xDistanceLimit and positionDifference.x > -xDistanceLimit) and  (positionDifference.y < yDistanceLimit and positionDifference.y > -yDistanceLimit) and (positionDifference.z < zDistanceLimit and positionDifference.z > -zDistanceLimit)) then
		return true
	else
		return false
	end
end

local function nearbyQuickStackCompanions(sourceContainer, validDestinations, transferedDestinations, hasTransfered)
	local nearbyActors = nearby.actors
	
	-- End function if no nearby actors found.
	if #nearbyActors == 0 then
		return
	end
	
	local nearbyFollowers = {}
	for _, actor in pairs(nearbyActors) do
		print("actor:", actor)
		if currentFollowers[actor.id] ~= nil then
			print("Found follower!", actor)
			if isDestinationWithinArea(actor, sourceContainer) == true then
				print("follower in range", actor)
				if companionValidations(actor) == false then goto continue end
			
				local actorName = types[tostring(actor.type)].record(actor.recordId).name
				table.insert(validDestinations, actorName)
				currentTransferedStatus = quickStack(actor, sourceContainer)
				if hasTransfered == false then
					hasTransfered = currentTransferedStatus
				end
				if currentTransferedStatus == true then
					table.insert(transferedDestinations, actorName)
					if config.options.isTransferAnimationEnabled == true then
						actor:sendEvent("PlayTransferedContainerAnimation", {duration=config.options.transferAnimationDuration})
					end
				end
			end
		end
		::continue::
    end
	
	return hasTransfered
end

local function nearbyQuickStackContainers(sourceContainer, validDestinations, transferedDestinations, hasTransfered)
	local nearbyContainers = nearby.containers
	
	-- End function if no nearby containers found.
	if #nearbyContainers == 0 then
		return
	end
	
	for _, container in pairs(nearbyContainers) do
		if isDestinationWithinArea(container, sourceContainer) == true then
			if containerValidations(container) == false then goto continue end
			
			table.insert(validDestinations, types.Container.record(container.recordId).name)
			currentTransferedStatus = quickStack(container, sourceContainer)
			if hasTransfered == false then
				hasTransfered = currentTransferedStatus
			end
			if currentTransferedStatus == true then
				table.insert(transferedDestinations, types.Container.record(container.recordId).name)
				if config.options.isTransferAnimationEnabled == true then
					container:sendEvent("PlayTransferedContainerAnimation", {duration=config.options.transferAnimationDuration})
				end
			end
		end
		::continue::
	end

	return hasTransfered
end

local function nearbyQuickStack(sourceContainer)
	-- Create optional verify prompt for yes or no for nearby stack
	local sourcePosition = sourceContainer.object.position
	local validDestinations = {}
	local transferedDestinations = {}
	local hasTransfered = false
	
	--stack to companions first
	hasTransfered = nearbyQuickStackCompanions(sourceContainer, validDestinations, transferedDestinations, hasTransfered)
	
	--stack to containers first
	hasTransfered = nearbyQuickStackContainers(sourceContainer, validDestinations, transferedDestinations, hasTransfered)
	
	-- End function if no valid containers found.
	if table.getn(validDestinations) == 0 and config.options.isFailureNotificationEnabled == true then
		displayMessage(commonData.content.message.noContainers)
		return
	end
	quickStackComplete(hasTransfered)
	if hasTransfered == true and config.options.isSuccessNotificationEnabled == true and config.options.isSuccessNotificationVerboseOrSimple == "Simple" then
		validContainersString =  buildValidContainerString(transferedContainers)
		local message = commonData.content.message.transferedNearbySuccessPrefix.. validContainersString
		displayMessage(message)
	end
end

--NOT IMPLEMENTED YET -- Needs item limiting
local function stashTesting()
	currentMode = interfaces.UI.getMode()
	if currentMode=='Container' then
		print("Mysticism Skill: ", types.NPC.stats.skills.mysticism(self).base)
		print("Marking container as Stash")
		stashContainer = activatedContainer
	else
		print("This is your stash:", stashContainer.recordId, stashContainer.id, types.Container.record(stashContainer.recordId).names)
		local stashInventory = types.Container.inventory(stashContainer):getAll()
		print("This is the stash inventory:")
		for _, item in pairs(stashInventory) do
			print(item)
		end
		stashQuickStack()
	end
end

local function onKeyPress(key)
	--Add ability to couple/de-couple container stack and nearbyStack functions?
	if key.code == config.keybinds.keybindStack then
		currentMode = interfaces.UI.getMode()
		transferGui.hideTransferResultBox()
		-- Clear table for new transfer
		transferResult = {}
		if currentMode=='Container' then
			singleQuickStack(activatedContainer, self)
		elseif currentMode == 'Companion' then
			singleQuickStack(activatedNPC, self)
		elseif currentMode == nil then
			nearbyQuickStack(self)

		end
	elseif key.symbol == "m" then
		--stashTesting()
	end	
end

return {
	eventHandlers = { 
		SentInventory = sentInventory,
		SentNPCInventory = sentNPCInventory,
		SentFollowerActor = sentFollowerActor
	},
	engineHandlers = {
		onKeyPress = onKeyPress,
	},
}