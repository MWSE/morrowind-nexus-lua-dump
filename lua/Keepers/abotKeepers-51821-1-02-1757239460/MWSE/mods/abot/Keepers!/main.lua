--[[
Marks with a suffix character (! by default) items you may want to keep/avoid selling, including:
- keys counted/used to open something in game
- player items counted in dialog filters
- other player items counted and removed from scripts/dialog result
]]

local defaultConfig = {
itemSuffix = '!', -- suffix to mark counted name
modList = {}, -- {[modName] = size} storage
counted = {}, -- counted items storage e.g. {['bk_a1_1_caiuspackage'] = 1}
removed = {}, -- removed items storage array e.g. {[1] = 'bk_a1_1_caiuspackage'}
reset = false,
logItems = false,
addSuffix = true,
hideIngred = false,
itemsBlackList = {'gold_', 'Misc_SoulGem', '_signal', 'ab01wlBook01', 'ab01wlMap01', '_hg_robe', 'ab01BoundArrow',
'ab01dummymisc', 'ab01uniquemisc', 'ab01uniquering', 'ab01fakehelmet', 'ab01ingred', 'ab01gunpcriding',
'slave_bracer_left', 'slave_bracer_right'},
---'Am_Book'. 'AM_BrooMShield'. 'AM_Lute', 'AM_Mortar', 'AM_Pestle'
itemsWhiteList = {'QOTW', 'EMYN_db_'},
modsBlackList = {'Crafting', 'NOM3', 'NOM_', 'abotBoats', 'abotGondoliers', 'abotSiltStriders', 'DualWeapons'},
blockMarkedIngredientConsumption = true,
logLevel = 0,
}
-- mark them even if not removed from player


local author = 'abot'
local modName = 'Keepers!'
local mcmName = author .. "'s " .. modName
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores

local dataFilesPath = tes3.installDirectory..'\\Data Files\\'
local tes3_objectType_miscItem = tes3.objectType.miscItem


local config, itemSuffix, addSuffix, hideIngred
local logLevel, logLevel1

local mcm = {}

local function collectedGarbage(funcId)
	local v = collectgarbage('count')
	collectgarbage()
	collectgarbage()
	if logLevel1 then
		mwse.log('%s %s: collected garbage = %d',
			modPrefix, funcId, ( v - collectgarbage('count') ) * 1024)
	end
end
	
function mcm.onClose()
	mwse.saveConfig(configName, config, {indent = true}) -- save our precious tables first
	for k in pairs(config) do
		config[k] = nil
	end
	config = nil
	collectedGarbage('mcm.onClose()')
end

local sYes, sNo -- set in modConfigReady()

local tes3_objectType_book = tes3.objectType.book
local tes3_objectType_ingredient = tes3.objectType.ingredient

local string_find = string.find
local string_format = string.format
local string_gmatch = string.gmatch
local string_multifind = string.multifind

local function getItems()

	local items = {}
	local itemsDict = {}

	if not config then
		config = mwse.loadConfig(configName, defaultConfig)
		assert(config)
	end
	if config.reset then
		config.reset = false
		config.modList = {}
	end

	itemSuffix = config.itemSuffix
	addSuffix = config.addSuffix
	hideIngred = config.hideIngred
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1

	local tes3ModList = tes3.getModList() -- e.g. {[1] = 'Morrowind.esm', [2] = 'Bloodmoon.esm'}
	local currModList = {}
	for i = 1, #tes3ModList do
		local modNam = tes3ModList[i]
		local modSize = lfs.attributes(dataFilesPath .. modNam, 'size')
		currModList[i] = {name = modNam, size = modSize}
	end

	local counted = config.counted

	local removed = {}
	-- from array to dictionary
	local a = config.removed
	for i = 1, #a do
		removed[a[i]] = true
	end

	local skipItems = {}
	a = config.itemsBlackList
	for i = 1, #a do
		skipItems[i] = a[i]:lower()
		---mwse.log('skipItems[%s] = %s', i, skipItems[i])
	end

	local skipMods = {}
	a = config.modsBlackList
	for i = 1, #a do
		skipMods[i] = a[i]:lower()
		---mwse.log('skipMods[%s] = %s', i, skipMods[i])
	end

	local keepItems = {}
	a = config.itemsWhiteList
	for i = 1, #a do
		keepItems[i] = a[i]:lower()
		---mwse.log('keepItems[%s] = %s', i, keepItems[i])
	end

	local function isMiscOrKeyOrKeeper(lcId)
		local obj = tes3.getObject(lcId)
		if not obj then
			return false
		end
		if obj.objectType == tes3_objectType_miscItem then
			return true
		end
		if string_find(lcId, 'key', 1, true) then
			if not string_multifind(lcId, {'detect','whiskey'}, 1, true) then
				return true
			end
		end
		if string_multifind(lcId, keepItems, 1, true) then
			return true
		end
		return false
	end

	local function getModData(mod_name)
		local filePath = dataFilesPath..mod_name
		local f = io.open(filePath, 'rb')
		if not f then
			assert(f)
			return
		end
		local text = f:read('*a')
		f:close()
		--[[if not text then
			assert(text)
			return
		end]]
		local s = text:lower()

		local c
		-- check keys opening some door or container
		-- this one was hard to figure, it does not work if you put control characters like \x04 or \004 in pattern

		-- Aaargh there is even a mod using _AA_Kyori"s_chest as identifier...
		for lcId in string_gmatch(s, [[fltv.....%z%z%zknam.%z%z%z([%C]+)%z]]) do
			c = counted[lcId]
			if (not c)
			or (c < 2) then
				if not string_multifind(lcId, skipItems, 1, true) then
					---mwse.log('"%s" used key', lcId)
					counted[lcId] = 2
				end
			end
		end

		-- check player items counted in dialog condition opcodes
		for lcId in string_gmatch(s, [[scvr.%z%z%z%d5ix[0-5]([%C]+)intv]]) do
			if not counted[lcId] then
				if not string_multifind(lcId, skipItems, 1, true) then
					---mwse.log('"%s" counted in dialog filter', lcId)
					counted[lcId] = 2
				end
			end
		end

		-- check misc items counted in scripts/dialog result.
		-- higher priority as they could be keys
		-- oh well fuck if an item has embedded " in the id or similar they deserve being lost LOL
		for lcId in string_gmatch(s, [[getitemcount[%s,]+"?"?([^%c>=<%(%),"]+)"?"?[%s,]+[>=<]=?]]) do
			if not counted[lcId] then
				if isMiscOrKeyOrKeeper(lcId) then
					if not string_multifind(lcId, skipItems, 1, true) then
						---mwse.log('"%s" counted in scripts', lcId)
						counted[lcId] = 2
					end
				end
			end
		end


		-- LOWER PRIORITY COUNTED ITEMS STAY ONLY IF REMOVED FROM PLAYER

		if string_find(s, '_sort', 1, true) then -- skip possible item sorters
			return
		end
		-- check non-key player items counted in scripts/dialog result
		for lcId in string_gmatch(s, [[player"?%s-%->%s-getitemcount[%s,]+"?"?([^%c>=<%(%),"]+)"?"?[%s,]+[>=<]=?]]) do
			if not counted[lcId] then
				if not string_multifind(lcId, skipItems, 1, true) then
					---mwse.log('"%s" counted in scripts', lcId)
					counted[lcId] = 1
				end
			end
		end

		-- check player items removed in scripts/dialog result
		for lcId in string_gmatch(s, [[player"?%s-%->%s-removeitem[%s,]+"?"?([^%c>=<%(%),"]+)"?"?[%s,]+%d]]) do
			if not removed[lcId] then
				c = counted[lcId]
				if (not c)
				or (c < 2) then
					if not string_multifind(lcId, skipItems, 1, true) then
						---mwse.log('"%s" removed in dialog or scripts', lcId)
						removed[lcId] = true
					end
				end
			end
		end

	end -- getModData(mod_name)


	local configModList = config.modList
	local newModList = {}
	local configUpdated = false

	local n = #currModList
	if n > 0 then
	---and ( not (n == #configModList) ) then
		for i = 1, n do
			local mod = currModList[i]
			local name = mod.name
			if not (mod.size == configModList[name]) then -- if mod name or size changed in current loading list
				configUpdated = true
				if not string_multifind(name:lower(), skipMods, 1, true) then
					getModData(name) -- update mod data
				elseif logLevel1 then
					mwse.log('%s: "%s" skipped', modPrefix, name)
				end
			end
			newModList[name] = mod.size
		end
	end
	config.modList = newModList

	local modIndexes = table.invert(tes3ModList) -- e.g. {['Morrowind.esm'] = 1, ['Bloodmoon.esm'] = 2}

	-- adjust and pack counted table to a new tc table, prepare the keepers items list

	local tc = {}
	local j = 0
	for lcId, val in pairs(counted) do
		local obj = tes3.getObject(lcId)
		if obj
		and val then
			if (val > 1) -- keep high priority items
			or removed[lcId] then -- and low priority items counted and removed from player
				tc[lcId] = val
				local name = obj.name
				if name then
					local nameLen = name:len()
					if nameLen > 0 then
						if name:sub(-1) == itemSuffix then
							if not addSuffix then
								name = name:sub(1, -2)
								obj.name = name -- update object name removing suffix
							end
						elseif addSuffix then
							if nameLen < 31 then
								if not (
										(obj.objectType == tes3_objectType_book)
									and string_find(name, '(Read)', 1, true) -- for Bookworm mod
								) then
									name = name .. itemSuffix
									obj.name = name -- update object name adding suffix
								end
							end
						end
						local sourceMod = obj.sourceMod
						local objId = obj.id
						if not itemsDict[objId] then
							itemsDict[objId] = true
							j = j + 1
							items[j] = {id = objId, na = name, mo = sourceMod, mi = modIndexes[sourceMod],
								ing = (obj.objectType == tes3_objectType_ingredient)}
						end
					end
				end
			end
		else -- no more loaded, remove from data tables
			counted[lcId] = nil
			removed[lcId] = nil
		end
	end

	-- clean no more needed table
	for k in pairs(itemsDict) do
		itemsDict[k] = nil
	end
	itemsDict = nil

	-- update config.counted table
	config.counted = tc

	local fmt = "%05d%s"
	local function sortByModIdItemId(a1, b1)
		return string_format(fmt, a1.mi, a1.id:lower()) < string_format(fmt, b1.mi, b1.id:lower())
	end

	-- sort items to display by mod loading order, item id
	-- note: sorting by itemId first and then by modId would probably be faster, but not conservative
	table.sort(items, sortByModIdItemId)

	-- clean no more needed table
	for k in pairs(modIndexes) do
		modIndexes[k] = nil
	end
	---modIndexes = nil

	-- pack removed dictionary to a new array
	a = {}
	j = 0
	for k in pairs(removed) do
		j = j + 1
		a[j] = k
	end

	-- sort and update config.removed array
	table.sort(a)
	config.removed = a

	-- clean no more used tables
	for k in pairs(counted) do
		counted[k] = nil
	end
	counted = nil
	for k in pairs(removed) do
		removed[k] = nil
	end
	removed = nil

	if configUpdated then
		mwse.saveConfig(configName, config, {indent = true})
	end

	return items
end -- getItems()

local lastSearch = true
function mcm.onCreate(container)

	local function createLabel(parent, labelText)
		local block = parent:createBlock({})
		block.flowDirection = 'top_to_bottom'
		block.paddingAllSides = 3
		block.layoutWidthFraction = 1.0
		block.height = 22
		block:createLabel({text = labelText})
	end

	local function createBooleanConfig(params)
		local block = params.parent:createBlock({})
		--block.flowDirection = "left_to_right"
		block.layoutWidthFraction = 1.0
		block.height = 32
		block.childAlignY = 0.5 -- Y centered
		block.paddingAllSides = 4

		local label = block:createLabel({text = params.label})

		local function yesOrNo()
			if params.config[params.key] then
				return sYes
			else
				return sNo
			end
		end

		local button = block:createButton({text = yesOrNo()})
		button.borderTop = 7
		button:register('mouseClick',
			function(e)
				params.config[params.key] = not params.config[params.key]
				button.text = yesOrNo()
				if (params.onUpdate) then
					params.onUpdate(e)
				end
			end
		)
		local info = block:createLabel({text = params.info or ''})

		return {block = block, label = label, button = button, info = info}
	end

	local mainPane, searchInput, list

	local sSearch = 'Search...'

	local function updateList()
		local searchText = searchInput.text:lower()
		local search = not (
			(searchText == '')
			or (searchText == sSearch:lower())
		)
		if search == lastSearch then
			if not search then
				return
			end
		end
		lastSearch = search
		local lbl, visible
		local children = list:getContentElement().children
		local updated = false
		for _, el in pairs(children) do
			if el then -- better safe than sorry
				---mwse.log('el %s %s', el.id, el.name)
				lbl = el.children[1]
				---mwse.log('lbl %s %s %s', lbl.id, lbl.name, lbl.text)
				if search then
					if string_find(lbl.text:lower(), searchText, 1, true) then
						visible = true
					else
						visible = false
					end
				else
					visible = true
				end
				if not (el.visible == visible) then
					el.visible = visible
					updated = true
				end
			end
		end
		if updated then
			mainPane:getTopLevelMenu():updateLayout() -- this is needed too
			list.widget:contentsChanged()
		end
	end

	local function onFilter()
		updateList()
	end

	local function onClear(e)
		e.source.text = sSearch
		updateList()
	end

	local function makeInput(el)
		---tes3.messageBox(el.name)
		local searchInputBlock = el:createBlock{}
		searchInputBlock.width = 120
		searchInputBlock.autoHeight = true
		---searchInputBlock.childAlignX = 0.5
		searchInputBlock.childAlignX = 0.0
		local border = searchInputBlock:createThinBorder{}
		border.width = searchInputBlock.width
		---border.height = 30
		border.autoHeight = true
		---border.childAlignX = 0.5
		---border.childAlignY = 0.5
		local input = border:createTextInput({id = 'ab01SearchInput'})
		input.text = sSearch
		input.borderLeft = 3
		input.borderRight = 3
		input.widget.lengthLimit = 31
		input.widget.eraseOnFirstKey = true
		el:register('keyEnter', onFilter) -- only works when text input is not captured
		input:register('keyEnter', onFilter)
		input:register('mouseClick', onClear)

		input:registerAfter('keyPress', onFilter)

		---border:register('mouseClick', acquireTextInput)
		--[[local menu = el:getTopLevelMenu()
		menu:updateLayout()]]
		tes3ui.acquireTextInput(input) -- automatically reset when menu is closed
		return input
	end

	mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0

	local items = getItems() -- this initializes also config

	local function createBoolCfg(lbl, keyId)
		return createBooleanConfig({parent = mainPane, label = lbl,	config = config, key = keyId})
	end

	createBoolCfg("Log items list?", "logItems")
	createBoolCfg("Reset configuration on game restart?", "reset")
	createBoolCfg(string_format("Add %s suffix to items?", itemSuffix), "addSuffix")
	createBoolCfg(string_format('Block "%s" marked ingredients consumption? (CTRL on drop to bypass)',
		itemSuffix), "blockMarkedIngredientConsumption")
	
	createBoolCfg("Hide ingredients from list?", "hideIngred")

	createLabel(mainPane, "Keepers items you may want to keep/avoid selling, including:")
	createLabel(mainPane, "- keys counted/used to open something in game")
	createLabel(mainPane, "- player items counted in dialog filters")
	createLabel(mainPane, "- other player items counted and removed from scripts/dialog result")

	mainPane:createDivider({})

	searchInput = makeInput(mainPane)

	createLabel(mainPane,'"Item ID", "Name", "Used by Mod"')

	list = mainPane:createVerticalScrollPane({})
	list.borderAllSides = 6
	list.widthProportional = 1.0
	list.heightProportional = 1.0

	local doLog = config.logItems
	if doLog then
		mwse.log("%s: items list", modPrefix)
	end

	---for _, v in ipairs(items) do -- {id = lcId, na = name, mo = sourceMod, mi = sorceModIndex}
	local showIngred = not hideIngred
	for i = 1, #items do
		local itm = items[i]
		if showIngred
		or (not itm.ing) then
			local s = string_format('"%s", "%s", "%s"', itm.id, itm.na, itm.mo)
			if doLog then
				mwse.log(s)
			end
			createLabel(list, s)
		end
	end

	mainPane:getTopLevelMenu():updateLayout()
	list.widget:contentsChanged()

	-- clean unneeded
	for k in pairs(items) do
		items[k] = nil
	end
	---items = nil
	
end

--- @param e equipEventData
local function equip(e)
	if not config.blockMarkedIngredientConsumption then
		return
	end
	local item = e.item
	if not (item.objectType == tes3_objectType_ingredient) then
		return
	end
	local itemName = item.name
	if itemName:sub(-1) == itemSuffix then
		if tes3.worldController.inputController:isControlDown() then
			return -- normal consuming if CTRL pressed
		end
        if e.reference == tes3.player then
		    tes3.messageBox([[%s: consumption of "%s" marked "%s" ingredient is blocked by default (it could be a quest-required item), you can bypass the block by keeping CTRL pressed while dropping.]], modPrefix, itemSuffix, item.name)
        end
		e.block = true
	end
end


local function modConfigReady(e)
	sYes = tes3.findGMST(tes3.gmst.sYes).value
	sNo = tes3.findGMST(tes3.gmst.sNo).value
	mwse.registerModConfig(mcmName, mcm)
	getItems()
	event.register('equip', equip, {priority = 100})
	collectedGarbage(e.eventType..'()')
end
event.register('modConfigReady', modConfigReady)
