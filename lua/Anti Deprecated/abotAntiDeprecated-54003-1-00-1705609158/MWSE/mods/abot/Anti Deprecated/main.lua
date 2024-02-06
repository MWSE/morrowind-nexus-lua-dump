--[[
Anti Deprecated
try and fix those pesky deprecated objects
]]

-- begin configurable parameters
local defaultConfig = {
hideLevel = 0,	-- 0 Off | 1 Disable | 2 Disable, Delete
removeLevel = 0, -- 0 Off | 1 Only from player inventory | 2 From all containers/actors inventories
skipMarked = true,
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium 3 = High, 4 = Max
}
-- end configurable parameters

local author = 'abot'
local modName = 'Anti Deprecated'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local keepersDetected = tes3.getFileExists('MWSE/mods/abot/Keepers!/main.lua')

local config = mwse.loadConfig(configName, defaultConfig)

local hideLevel, hideLevel1, hideLevel2
local removeLevel, removeLevel1, removeLevel2, skipMarked
local logLevel, logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	hideLevel = config.hideLevel
	hideLevel1 = hideLevel >= 1
	hideLevel2 = hideLevel >= 2
	removeLevel = config.removeLevel
	removeLevel1 = removeLevel >= 1
	removeLevel2 = removeLevel >= 2
	skipMarked = keepersDetected and config.skipMarked
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end
updateFromConfig()

local function isDeprecatedString(s)
	if s then
		if skipMarked then
			if string.sub(s, -1) == '!' then
				return false
			end
		end
		if string.find(string.lower(s), 'deprec', 1, true) then
			return true
		end
	end
	return false
end

local function isDeprecatedObj(obj)
	if obj.script then
		return false -- skip scripted things
	end
	local deprecated = isDeprecatedString(obj.name)
	if not deprecated then
		deprecated = isDeprecatedString(obj.mesh)
		if not deprecated then
			deprecated = isDeprecatedString(obj.icon)
		end
	end
	return deprecated
end

local fixedCount = 0

local function checkRef(ref)
	if logLevel3 then
		mwse.log('%s: checkRef(%s)', modPrefix, ref.id)
	end
	local obj = ref.object
	if not isDeprecatedObj(obj) then
		return
	end
	if ref.disabled
	or ref.deleted then
		return true
	end
	local refId = ref.id
	local mesh = obj.mesh
	local prefix = ''
	local suffix = ''
	if logLevel1 then
		if obj.sourceMod then
			prefix = string.format('"%s" ', obj.sourceMod)
		end
		if ref.sourceMod then
			suffix = string.format(' "%s"', ref.sourceMod)
		end
	end
	if hideLevel1 then
		if logLevel1 then
			mwse.log('%s: %s"%s" "%s"%s disabled', modPrefix, prefix, refId, mesh, suffix)
		end
		ref:disable()
		if hideLevel2 then
			if logLevel1 then
				mwse.log('%s: %s"%s" "%s"%s deleted', modPrefix, prefix, refId, mesh, suffix)
			end
			ref:delete()
		end
		--[[if not hideLevel3 then
			ref.modified = false
		end]]
	end
	fixedCount = fixedCount + 1
	return true
end

local function checkInventory(ref)
	if logLevel3 then
		mwse.log('%s: checkInventory(%s)', modPrefix, ref.id)
	end
	local refObj = ref.object
	local inventory = refObj.inventory
	if not inventory then
		return
	end
	local items = inventory.items
	local t = {}
	local count = 0
	local itemStack, obj
	for i = 1, #items do
		itemStack = items[i]
		obj = itemStack.object
		if isDeprecatedObj(obj) then
			count = count + 1
			t[count] = {id = obj.id, count = itemStack.count}
		end
	end
	if count <= 0 then
		return
	end
	local data, id, c
	for i = 1, count do
		data = t[i]
		id = data.id
		c = data.count
		tes3.removeItem({reference = ref, item = id, count = c, playSound = false})
		fixedCount = fixedCount + 1
		if logLevel1 then
			mwse.log('%s: %s deprecated "%s" removed from "%s"', modPrefix, c, id, ref.id)
		end
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	if mob.actorType then
		ref:updateEquipment()
	end
end

local function referenceActivated(e)
	if not hideLevel1 then
		return
	end
	local ref = e.reference
	if checkRef(ref) then
		return
	end
	if removeLevel2 then
		checkInventory(ref)
		return
	end
	if ref == tes3.player then
		if removeLevel1 then
			checkInventory(ref)
		end
	end
end

local function toggleReferenceActivated(on)
	if event.isRegistered('referenceActivated', referenceActivated) then
		if on then
			return
		end
		event.unregister('referenceActivated', referenceActivated)
		return
	end
	if on then
		event.register('referenceActivated', referenceActivated)
	end
end

local function saved()
	if logLevel1 then
		if fixedCount > 0 then
			mwse.log('%s: %s deprecated objects deleted since game start',
				modPrefix, fixedCount)
		end
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	local info = [[Allow to automatically Disable/Delete pesky deprecated objects on the fly,
including those obnoxious/immersion breaking inventory items labeled as "deprecated/depreciated".

Disclaimer:
Keep a backup savegame from before enabling the mod options for safety as deprecated items will be disabled/deleted in next saves.]]

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	local controls = preferences:createCategory({})

	--[[local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end]]

	template.onClose = function()
		updateFromConfig()
		toggleReferenceActivated(hideLevel1 or removeLevel1)
		mwse.saveConfig(configName, config, {indent = true})
	end

	local optionList = {'Off', 'Disable', 'Disable, Delete'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createDropdown({
		label = 'Hide deprecated objects references:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','hideLevel'),
		variable = createConfigVariable('hideLevel'),
	})

	optionList = {'Off', 'Only from player inventory', 'From all containers/actors inventories'}
	controls:createDropdown({
		label = 'Remove deprecated items:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s]],'removeLevel'),
		variable = createConfigVariable('removeLevel'),
	})

	if keepersDetected then
		controls:createYesNoButton({
			label = 'Skip items marked with ! suffix',
			description = getYesNoDescription([[Default: %s.
Skip deprecated items having ! suffix. Useful coupled with my Keepers! mod to keep possible deprecated (and marked) quest items.]], 'skipMarked'),
			variable = createConfigVariable('skipMarked')
		})
	end

	optionList = {'Off', 'Low', 'Medium', 'High'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})

	toggleReferenceActivated(hideLevel1 or removeLevel1)

	event.register('saved', saved)
end
event.register('modConfigReady', modConfigReady)