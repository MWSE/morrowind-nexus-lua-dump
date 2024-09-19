local unit = {}

local defaultConfig = {
sortOrderCombo = { -- right mouse button
	mouseButton = 1,
},
sortOrderCombo2 = { -- alt + right mouse button
	mouseButton = 1,
	isAltDown = true,
},
showSortBy = true,
ctrlClickEquip = true,
modEnabled = true,
logLevel = 0,
}

local author = 'abot'
local modName = 'Inventory Sorter'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

--[[
local function getScriptPath()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*[/\\])")
end
]]

local function notYetImplemented(funcName)
	mwse.log('%s: %s not yet implemented', modPrefix, funcName)
end

-- to be overriden
function unit.mcmOnClose()
  notYetImplemented('mcmOnClose()')
end
function unit.updateFromConfig()
  notYetImplemented('updateFromConfig()')
end

-- to be saved/loaded
local timestamp = 0 -- integer timestamp, to be saved/loaded in
local itemRecs = {} -- e.g. itemRecs['bk_affairsofwizards'] = {a = timestamp, e = timestamp}}

local function incTimestamp()
	timestamp = timestamp + 1
	return timestamp
end

local function getSavedDataTable()
	local data = tes3.player.data
	---assert(data)
	local ab01inso = data.ab01inso
	if not ab01inso then
		data.ab01inso = {}
		ab01inso = data.ab01inso
	end
	return ab01inso
end

local function save()
	local ab01inso = getSavedDataTable()
	ab01inso.timestamp = timestamp
	ab01inso.itemRecs = itemRecs
end
event.register('save', save)

local function loaded()
	local ab01inso = getSavedDataTable()
	timestamp = ab01inso.timestamp or 0
	itemRecs = ab01inso.itemRecs
	if itemRecs then
		-- clean/pack the table in case some mod is no more loaded
		local t = {}
		for k, v in pairs(itemRecs) do
			if v then
				if tes3.getObject(k) then
					t[k] = v
					itemRecs[k] = nil
				end
			end
		end
		itemRecs = t
	else
		itemRecs = {}
	end
end
event.register('loaded', loaded)

local function saveConfig()
	mwse.saveConfig(configName, config, {indent = true})
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function clearItemrecs()
	for k, v in pairs(itemRecs) do
		if v then
			itemRecs[k] = nil
		end
	end
	itemRecs = {}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	local info = [[Use the defined Sorting Order Key/Right Mouse Click Combos to select Inventory/Contents/Barter items secondary sorting order.
Default is set to use right click to access sorting menu (works well assigning e.g. the TAB key to open menus).
Notes:
As far as I know there is no MWSE-Lua way yet to hook into/change original Morrowind inventory tiles sorting function
(e.g. vanilla sorts item tiles by equipped/traded, then item category and finally by name).
As a workaround this mod provides some secondary sorting by quickly changing/restoring the item names under the hood.
Last activated/equipped item timestamps (used to sort by Time Activated/Time Equipped) are stored in game saves.
Temporary item name changes are not stored.
Sorting by Score is currently calculated as some mix/average of available item properties
(e.g. value, weight, damage, reach, speed, armor rating, enchant capacity...).
The mod should be compatible/working better/empowered by UI Expansion Search Bar/Filters.
Compatibility with other complex UI tweaking mods or mods renaming items from MWSE-Lua is not tested/officially supported, although in theory many should work as item name changes by this mod are done on the fly and usually reset right after the sorting happens.]]

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = 'Info',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	})
	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})
	local controls = preferences:createCategory({})

	template.onClose = unit.mcmOnClose

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Huge', 'Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	--[[local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end]]

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}
	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	-- controls:createYesNoButton({
		-- label = 'Enables',
		-- description = getYesNoDescription([[Default: %s.
-- Toggle mod functionality.
-- effective only on game reload.]], 'modEnabled'),
		-- variable = createConfigVariable('modEnabled')
	-- })
	
	controls:createKeyBinder({
		label = "Sorting Order Combo",
		description = [[Mouse/Hotkey combination to select sorting order.
Left mouse button not allowed.]],
		allowMouse = true,
		variable = createConfigVariable('sortOrderCombo'),
	})

	controls:createKeyBinder({
		label = "Sorting Order Combo (no quantity)",
		description = [[Mouse/Hotkey combination to select sorting order without taking item quantity into account.
Left mouse button not allowed.]],
		allowMouse = true,
		variable = createConfigVariable('sortOrderCombo2'),
	})

	controls:createDropdown({
		label = 'Logging level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	controls:createYesNoButton({
		label = 'Show sorting order',
		description = getYesNoDescription([[Default: %s.
Show selected sorting order on window header.]], 'showSortBy'),
		variable = createConfigVariable('showSortBy')
	})

	controls:createYesNoButton({
		label = 'Ctrl Click toggle equip',
		description = getYesNoDescription([[Default: %s.
Press Ctrl + Click to toggle equipping/unequipping a single inventory item (e.g. cuirass),
Press Ctrl + Shift + Click to toggle equipping multiple items (e.g. ammunitions).
Ctrl + Click should still take a single item from a multiple items stack as usual.]], 'ctrlClickEquip'),
		variable = createConfigVariable('ctrlClickEquip')
	})

	local function onButton(e)
		if e.button == 0 then -- Yes pressed
			clearItemrecs()
			unit.updateFromConfig()
		end
	end

	controls:createButton({
		---label = 'Reset',
		description = [[Reset last activated/equipped item timestamps data.]],
		buttonText = 'Reset timestamps',
		label = [[
Pros: it will probably reduce save file size a little.
Cons: stored data about last activated/equipped items will be lost, resetting related sorting by Time Activated/Time Equipped.]],
		callback = function ()
			tes3.messageBox({
				message = 'Do you really want to reset last activated/equipped item timestamps data?',
				buttons = {'Yes', 'No'},
				callback = onButton
			})
		end
	})	
	
	mwse.mcm.register(template)

end

-- public
unit.author = author
unit.modName = modName
unit.modPrefix = modPrefix
unit.configName = configName
unit.mcmName = mcmName
unit.defaultConfig = defaultConfig
unit.config = config
unit.saveConfig = saveConfig
unit.modConfigReady = modConfigReady
unit.itemRecs = itemRecs
unit.timestamp = timestamp
unit.incTimestamp = incTimestamp

return unit