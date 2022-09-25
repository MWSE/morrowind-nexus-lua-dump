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
removed = {}, -- removed items storage e.g. {[1] = 'bk_a1_1_caiuspackage'}
reset = false,
logItems = false,
addSuffix = true,
itemsBlackList = {'gold_', 'Misc_SoulGem', 'ab01wlBook01', 'ab01wlMap01', '_hg_robe', 'ab01BoundArrow',
'ab01dummymisc', 'ab01uniquemisc', 'ab01uniquering', 'ab01fakehelmet', 'ab01ingred', 'ab01gunpcriding',
},
modsBlackList = {'Crafting', 'NOM3', 'NOM_', 'abotBoats', 'abotGondoliers', 'abotSiltStriders', 'DualWeapons'},
logLevel = 1,
}

local author = 'abot'
local modName = 'Keepers!'
local mcmName = author .. "'s " .. modName
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores

local dataFilesPath = tes3.installDirectory..'\\Data Files\\'
local tes3_objectType_miscItem = tes3.objectType.miscItem


local config, itemSuffix, addSuffix, logLevel


local function getItems()

	local items = {}

	if not config then
		config = mwse.loadConfig(configName, defaultConfig)
	end
	if config.reset then
		config.reset = false
		config.modList = {}
	end

	itemSuffix = config.itemSuffix
	addSuffix = config.addSuffix
	logLevel = config.logLevel

	local tes3ModList = tes3.getModList() -- e.g. {[1] = 'Morrowind.esm', [2] = 'Bloodmoon.esm'}
	local currModList = {}

	for i, modNam in ipairs(tes3ModList) do
		local modSize = lfs.attributes(dataFilesPath .. modNam, 'size')
		if not modSize then
			assert(modSize)
			return
		end
		currModList[i] = {name = modNam, size = modSize}
	end

	local counted = config.counted

	local removed = {}
	-- from array to hash
	for _, v in ipairs(config.removed) do
		removed[v] = 1
	end

	local skipItems = {}
	for i, v in ipairs(config.itemsBlackList) do
		skipItems[i] = v:lower()
		---mwse.log('skipItems[%s] = %s', i, skipItems[i])
	end

	local skipMods = {}
	for i, v in ipairs(config.modsBlackList) do
		skipMods[i] = v:lower()
		---mwse.log('skipMods[%s] = %s', i, skipMods[i])
	end

	local function isMiscOrKey(lcId)
		local obj = tes3.getObject(lcId)
		if not obj then
			return false
		end
		if obj.objectType == tes3_objectType_miscItem then
			return true
		end
		if lcId:find('key', 1, true) then
			if not lcId:multifind({'detect','whiskey'}, 1, true) then
				return true
			end
		end
		return false
	end

	local function getModData(modNam)
		local filePath = dataFilesPath..modNam
		local f = io.open(filePath, 'rb')
		if not f then
			assert(f)
			return
		end
		local text = f:read('*a')
		f:close()
		if not text then
			assert(text)
			return
		end
		local s = text:lower()

		local c
		-- check keys opening some door or container
		-- this one was hard to figure, it does not work if you put control characters like \x04 or \004 in pattern

		-- Aaargh there is even a mod using _AA_Kyori"s_chest identifier...


		for lcId in s:gmatch([[fltv.....%z%z%zknam.%z%z%z([%C]+)%z]]) do
			c = counted[lcId]
			if (not c)
			or (c < 2) then
				if not lcId:multifind(skipItems, 1, true) then
					---mwse.log('"%s" used key', lcId)
					counted[lcId] = 2
				end
			end
		end

		-- check player items counted in dialog condition opcodes
		for lcId in s:gmatch([[scvr.%z%z%z%d5ix[0-5]([%C]+)intv]]) do
			if not counted[lcId] then
				if not lcId:multifind(skipItems, 1, true) then
					---mwse.log('"%s" counted in dialog filter', lcId)
					counted[lcId] = 2
				end
			end
		end

		-- check misc items counted in scripts/dialog result.
		-- higher priority as they could be keys
		-- oh well fuck if an item has embedded " in the id or similar they deserve being lost LOL
		for lcId in s:gmatch([[getitemcount[%s,]+"?"?([^%c>=<%(%),"]+)"?"?[%s,]+[>=]?=?]]) do
			if not counted[lcId] then
				if isMiscOrKey(lcId) then
					if not lcId:multifind(skipItems, 1, true) then
						---mwse.log('"%s" counted in scripts', lcId)
						counted[lcId] = 2
					end
				end
			end
		end


		-- lower priority counted items stay only if removed from player

		-- check non-key player items counted in scripts/dialog result
		for lcId in s:gmatch([[player"?%s-%->%s-getitemcount[%s,]+"?"?([^%c>=<%(%),"]+)"?"?[%s,]+[>=]?=?]]) do
			if not counted[lcId] then
				if not lcId:multifind(skipItems, 1, true) then
					---mwse.log('"%s" counted in scripts', lcId)
					counted[lcId] = 1
				end
			end
		end

		-- check player items removed in scripts/dialog result
		for lcId in s:gmatch([[player"?%s-%->%s-removeitem[%s,]+"?"?([^%c>=<%(%),"]+)"?"?[%s,]+%d]]) do
			if not removed[lcId] then
				c = counted[lcId]
				if (not c)
				or (c < 2) then
					if not lcId:multifind(skipItems, 1, true) then
						---mwse.log('"%s" removed in dialog or scripts', lcId)
						removed[lcId] = 1
					end
				end
			end
		end

	end -- getModData(modNam)


	local configModList = config.modList
	local newModList = {}
	local configUpdated = false
	for _, v in ipairs(currModList) do
		local name = v.name
		if not (v.size == configModList[name]) then -- if mod name or size changed in current loading list
			configUpdated = true
			if not string.multifind(name:lower(), skipMods, 1, true) then
				getModData(name) -- update mod data
			elseif logLevel > 0 then
				mwse.log('%s: "%s" skipped', modPrefix, name)
			end
		end
		newModList[name] = v.size
	end
	config.modList = newModList

	local modIndexes = table.invert(tes3ModList) -- e.g. {['Morrowind.esm'] = 1, ['Bloodmoon.esm'] = 2}

	local obj

	-- adjust and pack counted table to a new tc table
	local tc = {}
	for lcId, v in pairs(counted) do
		if v then
			obj = tes3.getObject(lcId)
			if obj then
				if (v > 1) -- keep high priority items
				or removed[lcId] then -- and low priority items counted and removed from player
					tc[lcId] = v
				end
			else -- no more loaded, remove from data tables
				counted[lcId] = nil
				removed[lcId] = nil
			end
		end
	end

	-- update config.counted table
	config.counted = tc

	local name, nameLen, sourceMod
	local j = 0

	-- prepare the keepers items list
	for lcId, _ in pairs(tc) do
		obj = tes3.getObject(lcId)
		if obj then
			name = obj.name
			if name then
				nameLen = name:len()
				if nameLen > 0 then
					if name:sub(-1) == itemSuffix then
						if not addSuffix then
							name = name:sub(1, -2)
							obj.name = name -- update object name removing suffix
						end
					elseif addSuffix then
						if nameLen < 31 then
							name = name .. itemSuffix
							obj.name = name -- update object name adding suffix
						end
					end
					j = j + 1
					sourceMod = obj.sourceMod
					items[j] = {id = obj.id, na = name, mo = sourceMod, mi = modIndexes[sourceMod]}
				end
			end
		end
	end

	local fmt = "%05d%s"
	local function sortByModIdItemId(a, b)
		return fmt:format(a.mi, a.id:lower()) < fmt:format(b.mi, b.id:lower())
	end

	-- sort items to display by mod loading order, item id
	table.sort(items, sortByModIdItemId)

	-- clean unneeded
	for k in pairs(modIndexes) do
		modIndexes[k] = nil
	end
	---modIndexes = nil

	-- pack removed table to new tr table
	local tr = {}
	for k, v in pairs(removed) do
		if v then
			tr[k] = v
		end
	end

	-- update and sort config.removed table
	config.removed = {}
	for k, _ in pairs(tr) do
		table.insert(config.removed, k)
	end
	table.sort(config.removed)

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

	collectgarbage('collect')

	return items
end


local mcm = {}

function mcm.onClose()
	mwse.saveConfig(configName, config, {indent = true}) -- save our precious tables first

	for k in pairs(config) do
		config[k] = nil
	end
	config = nil

	collectgarbage('collect')

end

local sYes, sNo -- set in modConfigReady()

local function createListLabel(parent, labelText)
	local block = parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.paddingAllSides = 4
	block.layoutWidthFraction = 1.0
	block.height = 24
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


function mcm.onCreate(container)

	local items = getItems()

	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0

	createBooleanConfig({
		parent = mainPane,
		label = "Log items list?",
		config = config,
		key = "logItems",
	})

	createBooleanConfig({
		parent = mainPane,
		label = "Reset configuration on game restart?",
		config = config,
		key = "reset",
	})

	createBooleanConfig({
		parent = mainPane,
		label = ("Add %s suffix to items?"):format(itemSuffix),
		config = config,
		key = "addSuffix",
	})

	local list = mainPane:createVerticalScrollPane({})
	list.borderAllSides = 6
	list.widthProportional = 1.0
	list.heightProportional = 1.0
	createListLabel(list, "Keepers items you may want to keep/avoid selling, including:")
	createListLabel(list, "- keys counted/used to open something in game")
	createListLabel(list, "- player items counted in dialog filters")
	createListLabel(list, "- other player items counted and removed from scripts/dialog result")


	list:createDivider({})
	createListLabel( list, '"Item ID", "Name", "Used by Mod"')

	local doLog = config.logItems
	local s
	if doLog then
		mwse.log("%s: items list", modPrefix)
	end
	for _, v in ipairs(items) do -- {id = lcId, na = name, mo = sourceMod, mi = sorceModIndex}
		s = ('"%s", "%s", "%s"'):format(v.id, v.na, v.mo)
		if doLog then
			mwse.log(s)
		end
		createListLabel(list, s)
	end

	mainPane:getTopLevelParent():updateLayout()
	list.widget:contentsChanged()

	-- clean unneeded
	for k in pairs(items) do
		items[k] = nil
	end
	---items = nil

end


local function modConfigReady()
	sYes = tes3.findGMST(tes3.gmst.sYes).value
	sNo = tes3.findGMST(tes3.gmst.sNo).value
	getItems()
	mwse.registerModConfig(mcmName, mcm)
end
event.register('modConfigReady', modConfigReady)
