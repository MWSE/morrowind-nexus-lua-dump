--[[
Hide/delete most exterior/exterior likegrass statics references on the fly
to be rendered as moving grass by MGE-XE instead
]]

local defaultConfig = {
hideLevel = 3,
skipInteriors = false,
logLevel = 0,
}
local author = 'abot'
local modName = 'Hide Grass'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local hideLevel, hideLevel1, hideLevel2, hideLevel3, hideLevel4
local skipInteriors
local logLevel, logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	hideLevel = config.hideLevel
	hideLevel1 = hideLevel >= 1
	hideLevel2 = hideLevel >= 2
	hideLevel3 = hideLevel >= 3
	hideLevel4 = hideLevel >= 4
	skipInteriors = config.skipInteriors
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end
updateFromConfig()

-- set in modConfigReady()
local grassDict = {}

local tes3_objectType_static = tes3.objectType.static

local function referenceActivated(e)
	if not hideLevel1 then
		return
	end
	local ref = e.reference
	local obj = ref.object
	if not (obj.objectType == tes3_objectType_static) then
		return
	end
	local mesh = obj.mesh
	if not mesh then
		return
	end
	local objId = obj.id
	local lcMesh = string.lower(mesh)
	if not grassDict[lcMesh] then
		if logLevel3 then
			mwse.log('%s: "%s" mesh "%s", skip', modPrefix, objId, mesh)
		end
		return
	end
	if ref.disabled
	or ref.deleted then
		return
	end
	local cell = ref.cell
	if skipInteriors then
		if not cell.isOrBehavesAsExterior then
			if logLevel2 then
				mwse.log('%s: "%s" mesh "%s" in "%s" interior cell, skip',
					modPrefix, objId, mesh, cell.editorName)
			end
			return
		end
	end
	local sceneNode = obj.sceneNode
	--[[if sceneNode then
		if sceneNode.appCulled then
			return -- nope appCulled alone sometimes is not enough
		end
	end]]
	if sceneNode then
		if logLevel1 then
			mwse.log('%s: "%s" mesh "%s" culled', modPrefix, objId, mesh)
		end
		sceneNode.appCulled = true
	end
	if not hideLevel2 then
		return
	end
	if logLevel1 then
		mwse.log('%s: "%s" mesh "%s" disabled', modPrefix, objId, mesh)
	end
	ref:disable()
	---mwscript.setDelete({reference = ref, delete = true})
	if hideLevel3 then
		if logLevel1 then
			mwse.log('%s: "%s" mesh "%s" deleted', modPrefix, objId, mesh)
		end
		ref:delete()
	end
	if hideLevel4 then
		return
	end
	ref.modified = false
end

local function doubleSlash(s)
	return string.gsub(s, [[\/]], [[\\]])
end

local function initGrassDict()
	local relPath = 'mge3\\Hide Grass.ovr'
	local verifyMsg = 'please verify you have installed the mod correctly'

	local function logMsg(operation)
		mwse.log('%s initGrassDict(): error %s "%s", %s.',
			modPrefix, operation, relPath, verifyMsg)
	end

	local f = io.open(relPath)
	if not f then
		logMsg('opening')
		return
	end

	local lines = f:lines()
	if not lines then
		f:close()
		logMsg('reading')
		return
	end

	if logLevel1 then
		mwse.log('%s initGrassDict(): "%s" detected meshes:',
			modPrefix, relPath)
	end
	local ok = false
	for line in lines do
		local lcLine = doubleSlash(  string.lower( string.trim(line) )  )
		if not string.find(lcLine, '^[:;]') then
			local path = string.match(lcLine, '(.+%.nif)%s*=%s*grass')
			if path
			and (not grassDict[path]) then
				if logLevel1 then
					mwse.log('"%s",', path)
				end
				grassDict[path] = true
				ok = true
			end
		end
	end
	f:close()
	if not ok then
		mwse.log('%s initGrassDict(): no valid meshes found in "%s", %s.',
			modPrefix, relPath, verifyMsg)
	end
end

local function onClose()
	updateFromConfig()
	mwse.saveConfig(configName, config, {indent = true})
end

local function modConfigReady()
	initGrassDict()

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local info = [[Hide Grass

Hide/delete most exterior/exterior like grass statics references on the fly
to be rendered as moving grass by MGE-XE instead
(assuming you first regenerate MGE-XE distant land after loading the provided
"MGE3\Hide Grass.ovr" MGE-XE settings).
Note: "Cull, Disable, Delete, Modify" option will store grass references deletion to saved games.
Read the readme before using it.]]

	local sideBarPage = template:createSideBarPage({
		label = modName,
		description = info,
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local optionList = {'Off', 'Cull', 'Cull, Disable', 'Cull, Disable, Delete', 'Cull, Disable, Delete, Modify'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	--[[local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end]]

	sideBarPage:createYesNoButton({
		label = 'Skip interior cells',
		description = [[Skip processing interior cells.
Note: as MGE-XE may still render grass-like meshes in some big interior cell,
if you see grass like meshes moving in some interior better
to keep this setting disabled.]],
		configKey = 'skipInteriors'
	})

	sideBarPage:createDropdown({
		label = 'Hide Grass:',
		options = getOptions(),
		configKey = 'hideLevel'
	})

	optionList = {'Off', 'Low', 'Medium', 'High'}
	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})
	mwse.mcm.register(template)
	if table.size(grassDict) > 0 then
		event.register('referenceActivated', referenceActivated)
	end
end
event.register('modConfigReady', modConfigReady)