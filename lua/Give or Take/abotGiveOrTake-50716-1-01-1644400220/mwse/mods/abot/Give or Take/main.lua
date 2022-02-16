--[[
Give or Take, a nice mod /pun intended /abot
]]

-- begin configurable parameters
local defaultConfig = {
maxStackCount = 10000,
giveOrTakeButtons = true,
alwaysShowTakeButton = true,
skipEquippedItems = true,
showMovedStat = true,
logLevel = 2
}
-- end configurable parameters

local author = 'abot'
local modName = 'Give or Take'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local GUI_ID_PartDragMenu_center_frame = tes3ui.registerID('PartDragMenu_center_frame')
local GUI_ID_PartDragMenu_drag_frame = tes3ui.registerID('PartDragMenu_drag_frame')
local GUI_ID_PartDragMenu_main = tes3ui.registerID('PartDragMenu_main')
local GUI_ID_Buttons = tes3ui.registerID('Buttons')
local GUI_ID_MenuContents_takeallbutton = tes3ui.registerID('MenuContents_takeallbutton')
local GUI_ID_MenuContents_removebutton = tes3ui.registerID('MenuContents_removebutton')
local GUI_ID_MenuContents_closebutton = tes3ui.registerID('MenuContents_closebutton')

local GUI_ID_MenuInventory = tes3ui.registerID('MenuInventory')

local tes3_objectType_light = tes3.objectType.light

local function moveContents(menu, give)
	if not menu then
		return
	end
	if not menu.visible then
		return
	end

	local menuName = menu.name
	local containerRef = menu:getPropertyObject(menuName .. '_ObjectRefr')

	local sourceRef, destRef
	local tes3_player = tes3.player
	if give then
		menu = tes3ui.findMenu(GUI_ID_MenuInventory)
		if not menu then
			return
		end
		menuName = menu.name
		sourceRef = tes3_player
		destRef = containerRef
	else
		sourceRef = containerRef
		destRef = tes3_player
	end

	---mwse.log(menuName)
	local pane = menu:findChild(menuName .. '_scrollpane')
	if not pane then
		return
	end
	---mwse.log(pane.name)
	pane = pane:findChild('PartScrollPane_pane')
	if not pane then
		return
	end
	---mwse.log(pane.name)
	local inventoryTileId = menuName .. '_Thing'
	local totCount = 0
	local totValue = 0
	local totWeight = 0
	local itm, cnt, value, weight, stackValue, stackWeight, itmData
	local ok, tile
	local stop = false
	local stackCount = 0
	local maxStackCount = config.maxStackCount
	local skipEquippedItems = config.skipEquippedItems
	local logLevel1 = config.logLevel >= 1
	local logLevel2 = config.logLevel >= 2
	local showMovedStat = config.showMovedStat

	for _, vtile in ipairs(pane.children) do
		for j, el in ipairs(vtile.children) do
			tile = el:getPropertyObject(inventoryTileId, 'tes3inventoryTile')
			assert(tile)
			ok = true
			itm = tile.item
			if tile.isBoundItem then
				ok = false
				if logLevel1 then
					mwse.log('%s: Bound item %s "%s" skipped', modPrefix, itm.id, itm.name)
				end
			elseif tile.isEquipped
			and ( skipEquippedItems
			or (sourceRef == tes3_player) ) then
				ok = false
				if logLevel1 then
					mwse.log('%s: Equipped item %s "%s" skipped', modPrefix, itm.id, itm.name)
				end
			elseif itm.objectType == tes3_objectType_light then
				if itm.canCarry then
					if itm.isOffByDefault then
						if itm.radius < 17 then
							ok = false -- skip e.g. CDC inventory helpers light icons
							if logLevel1 then
								mwse.log('%s: Light icon %s "%s" skipped', modPrefix, itm.id, itm.name)
							end
						end
					end
				end
			end
			if ok then
				cnt = tile.count
				itmData = tile.itemData
				value = itm.value
				weight = itm.weight
				stackValue = value * cnt
				stackWeight = weight * cnt
				if logLevel2 then
					mwse.log('%s: %s item = %s, count = %s, value = %s, weight = %s, stackValue = %s, stacklWeight = %s',
						modPrefix, j, itm.name, cnt, value, weight, stackValue, stackWeight)
				end
				cnt = tes3.transferItem({from = sourceRef, to = destRef, item = itm, itemData = itmData, count = cnt,
					playSound = false, updateGUI = false, reevaluateEquipment = false})
				if cnt > 0 then
					totValue = (value * cnt) + totValue
					totCount = totCount + cnt
					totWeight = (weight * cnt) + totWeight
					stackCount = stackCount + 1
					if stackCount >= maxStackCount then
						stop = true
						break
					end
				end
			end
		end -- for j, el
		if stop then break end
	end -- for i, vtile
	if totCount <= 0 then
		return
	end
	if showMovedStat then
		tes3.messageBox("Items moved: %s\nTotal Weight: %.2f\nTotal Value: %.2f", totCount, totWeight, totValue)
	end
	tes3ui.updateContentsMenuTiles()
	tes3ui.updateInventoryTiles()
	tes3.updateInventoryGUI({reference = sourceRef})
	tes3.updateInventoryGUI({reference = destRef})
	---tes3ui.forcePlayerInventoryUpdate()
	if give then
		tes3.playSound({sound = 'Item Misc Down'})
	else
		tes3.playSound({sound = 'Item Misc Up'})
	end
	local mobile = destRef.mobile
	if mobile then
		local actorType = mobile.actorType -- 0 = creature, 1 = NPC, 2 = player
		local ob = mobile.object
		if (actorType == 1) -- NPC
		or (
			(actorType == 0) -- biped creature
			and ob.usesEquipment
		) then
			ob:reevaluateEquipment()
		end
	end
	if not tes3.hasOwnershipAccess({target = sourceRef, reference = destRef}) then
		tes3.triggerCrime({type = tes3.crimeType.theft, victim = tes3.getOwner(sourceRef), value = totValue })
	end
	if not tes3.hasOwnershipAccess({target = destRef, reference = sourceRef}) then
		tes3.triggerCrime({type = tes3.crimeType.trespass, victim = tes3.getOwner(destRef), value = totValue })
	end
end

local function uiMenuContents(menu)
	local menuName = menu.name
	local el = menu:findChild(GUI_ID_PartDragMenu_center_frame)
	if not el then
		return
	end
	---mwse.log(el.name)
	el = el:findChild(GUI_ID_PartDragMenu_drag_frame)
	if not el then
		return
	end
	---mwse.log(el.name)
	el = el:findChild(GUI_ID_PartDragMenu_main)
	if not el then
		return
	end
	---mwse.log(el.name)
	el = el:findChild(GUI_ID_Buttons)
	if not el then
		return
	end
	local takeAllowed = true
	if not config.alwaysShowTakeButton then
		local btn = el:findChild(GUI_ID_MenuContents_takeallbutton)
		if btn then
			if btn.visible then
				takeAllowed = false
			end
		end
		btn = el:findChild(GUI_ID_MenuContents_removebutton)
		if btn then
			if btn.visible then
				takeAllowed = false
			end
		end
	end
	el = el:findChild(GUI_ID_MenuContents_closebutton)
	if not el then
		return
	end
	local buttons = el.parent
	if not buttons then
		return
	end
	local container = menu:getPropertyObject(menuName..'_ObjectContainer')
	local giveAllowed = true
	if container.objectType == tes3.objectType.container then
		if container.organic then
			giveAllowed = false
			if config.logLevel > 0 then
				mwse.log('%s: "Give" button skipped for organic container item %s "%s"', modPrefix, container.id, container.name)
			end
		else
			local maxWeight = menu:getPropertyFloat(menuName..'_containerweight')
			local currWeight = container.inventory:calculateWeight()
			if currWeight >= maxWeight then
				giveAllowed = false
				if config.logLevel > 0 then
					mwse.log('%s: "Give" button skipped for full container item %s "%s"', modPrefix, container.id, container.name)
				end
			end
		end
	end
	if takeAllowed then
		if not buttons:findChild('buttonTake') then
			local take = buttons:createButton({text = 'Take', id = 'buttonTake'})
			buttons:reorderChildren(0, -1, 1)
			take.paddingLeft = 5
			take.paddingRight = 5
			take:register('mouseClick',	function ()	moveContents(menu) end)
		end
	end
	if giveAllowed then
		if not buttons:findChild('buttonGive') then
			local give = buttons:createButton({text = 'Give', id = 'buttonGive'})
			buttons:reorderChildren(0, -1, 1)
			give.paddingLeft = 5
			give.paddingRight = 5
			give:register('mouseClick', function () moveContents(menu, true) end)
		end
	end
end

local function uiActivatedMenuContents(e)
	if not e.newlyCreated then
		return
	end
	uiMenuContents(e.element)
end
event.register('uiActivated', uiActivatedMenuContents, {filter = 'MenuContents'})

--[[local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end]]

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Preferences",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = [[Adds "Give" and "Take" buttons to any suitable actor/container,
so you can easily move (all/all filtered) things in and out with Lua speed.]]}

	local controls = preferences:createCategory{label = ""}

	controls:createSlider{
		label = "Max moved items",
		variable = createConfigVariable("maxStackCount")
		,min = 1, max = defaultConfig.maxStackCount,
		description = string.format("Max number of items moved at once (default: %s).", defaultConfig.maxStackCount)
	}

	controls:createYesNoButton{
		label = 'Skip equipped items',
		description = [[Default: Yes.
Do not transfer item equipped by actors. Items equipped by player will always be skipped.]],
		variable = createConfigVariable("skipEquippedItems")
	}

	controls:createYesNoButton{
		label = 'Show "Give" and "Take" buttons',
		description = 'Default: Yes.\n'..
'Enable the mod, adding "Give" and "Take" buttons to to suitable inventories '..
'like player, containers, creatures, NPCs (traders excluded), '..
'so you can easily move (all/all filtered) things in and out with Lua speed.',
		variable = createConfigVariable("giveOrTakeButtons")
	}

	controls:createYesNoButton{
		label = 'Always show "Take" button',
		description = [[Default: Yes.
"Take" button added even when "Take All" or "Take Filtered" is available.
Note: "Take" button in this case is still useful if you don't want to autoclose the container window.]],
		variable = createConfigVariable("alwaysShowTakeButton")
	}

	controls:createYesNoButton{
		label = 'Show moved items statistics',
		description = [[Default: Yes.
Show moved items statistics (total count, weight, value).]],
		variable = createConfigVariable("showMovedStat")
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			--[[{ label = "3. High", value = 3 },]]
		},
		variable = createConfigVariable("logLevel"),
		description = "Default: 0. Disabled."
	}

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)