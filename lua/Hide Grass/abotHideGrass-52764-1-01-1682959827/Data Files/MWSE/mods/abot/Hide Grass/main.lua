--[[
Hide/delete most exterior/exterior likegrass statics references on the fly
to be rendered as moving grass by MGE-XE instead
]]

local defaultConfig = {
hideLevel = 3,
logLevel = 0,
}
local author = 'abot'
local modName = 'Hide Grass'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local hideLevel = config.hideLevel
local logLevel = config.logLevel
local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2
local logLevel3 = logLevel >= 3

 -- set in modConfigReady()
local grassDict = {}

local tes3_objectType_static = tes3.objectType.static

local function referenceActivated(e)
	if hideLevel == 0 then
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
	if ref.sceneNode.appCulled then
		return
	end
	local cell = ref.cell
	if not cell.isOrBehavesAsExterior then
		if logLevel2 then
			mwse.log('%s: "%s" mesh "%s" in "%s" interior cell, skip',
				modPrefix, ref.object.id, ref.object.mesh, cell.editorName)
		end
		return
	end
	if logLevel1 then
		mwse.log('%s: "%s" mesh "%s" culled', modPrefix, objId, mesh)
	end
	ref.sceneNode.appCulled = true
	if hideLevel < 2 then
		return
	end
	if logLevel1 then
		mwse.log('%s: "%s" mesh "%s" disabled', modPrefix, objId, mesh)
	end
	ref:disable()
	---mwscript.setDelete({reference = ref, delete = true})
	if hideLevel >= 3 then
		if logLevel1 then
			mwse.log('%s: "%s" mesh "%s" deleted', modPrefix, ref.object.id, ref.object.mesh)
		end
		ref:delete()
	end
	if hideLevel < 4 then
		ref.modified = false
	end
end

local function modConfigReady()

	local grass = {
"ag\\ar_fernp.nif",
"bf\\rmj_fern_1.nif",
"bf\\rmj_fern_2.nif",
"bf\\rmj_fern_3.nif",
"caverns_o\\c_o_grass.nif",
"coi\\stargazerlily01.nif",
"coi\\stargazerlily02.nif",
"f\\f_abc_grass00.nif",
"f\\f_stros_fern.nif",
"f\\f_stros_kelp01.nif",
"f\\f_stros_kelp02.nif",
"f\\flora_ash_grass_b_01.nif",
"f\\flora_ash_grass_r_01.nif",
"f\\flora_ash_grass_w_01.nif",
"f\\flora_bc_fern_02.nif",
"f\\flora_bc_fern_03.nif",
"f\\flora_bc_fern_04.nif",
"f\\flora_bc_grass_01.nif",
"f\\flora_bc_grass_02.nif",
"f\\flora_bc_lilypad_01.nif",
"f\\flora_bc_lilypad_02.nif",
"f\\flora_bc_lilypad_03.nif",
"f\\flora_bm_grass_01.nif",
"f\\flora_bm_grass_02.nif",
"f\\flora_bm_grass_03.nif",
"f\\flora_bm_grass_04.nif",
"f\\flora_bm_grass_05.nif",
"f\\flora_bm_grass_06.nif",
"f\\flora_bm_shrub_01.nif",
"f\\flora_bm_shrub_02.nif",
"f\\flora_bm_shrub_03.nif",
"f\\flora_grass_01.nif",
"f\\flora_grass_02.nif",
"f\\flora_grass_03.nif",
"f\\flora_grass_04.nif",
"f\\flora_grass_05.nif",
"f\\flora_grass_06.nif",
"f\\flora_grass_07.nif",
"f\\flora_kelp_01.nif",
"f\\flora_kelp_02.nif",
"f\\flora_kelp_03.nif",
"f\\flora_kelp_04.nif",
"fa\\1\\cave_mud_ferns_01.nif",
"fa\\1\\fern_01.nif",
"fern_xx.nif",
"i\\in_cave_plant00.nif",
"i\\in_cave_plant10.nif",
"jmk-obli\\2wetlily.nif",
"ko_fern_013.nif",
"ko_fern_017.nif",
"ko_fern_020.nif",
"ko_small_fern_01.nif",
"ko_small_fern_03.nif",
"ks\\dg-wf_lilypad.nif",
"mg\\f\\fern_01.nif",
"mg\\i\\cave_mold_ferns_01.nif",
"oaab\\f\\fern_01.nif",
"oaab\\f\\goldreedgrass.nif",
"oaab\\f\\kelpabc_01.nif",
"oaab\\f\\kelpabc_02.nif",
"oaab\\f\\kelpabc_03.nif",
"oaab\\f\\kelpabc_04.nif",
"oaab\\f\\kelpvnl1g_01.nif",
"oaab\\f\\kelpvnl1g_02.nif",
"oaab\\f\\kelpvnl2_01.nif",
"oaab\\f\\kelpvnl2_02.nif",
"oaab\\f\\kelpvnl2_03.nif",
"oaab\\f\\kelpvnl2g_01.nif",
"oaab\\f\\mv_grass_01.nif",
"oaab\\f\\rem_ash_grass_black.nif",
"oaab\\f\\rem_ash_grass_red.nif",
"oaab\\f\\rem_ash_grass_white.nif",
"oaab\\i\\cave_mold_ferns_01.nif",
"pc\\f\\pc_flora_ch_shrub.nif",
"pc\\f\\pc_flora_ch_shrub02.nif",
"pc\\f\\pc_flora_ch_shrub03.nif",
"pc\\f\\pc_flora_ch_shrub04.nif",
"pc\\f\\pc_flora_ch_shrub05.nif",
"pc\\f\\pc_flora_ch_shrub06.nif",
"pc\\f\\pc_flora_ch_shrub07.nif",
"pc\\f\\pc_flora_fern.nif",
"pc\\f\\pc_flora_fernscamp.nif",
"pc\\f\\pc_flora_gc_shrub01.nif",
"pc\\f\\pc_flora_gc_shrub02.nif",
"pc\\f\\pc_flora_gf_shrub.nif",
"pc\\f\\pc_flora_hl_shrub.nif",
"pc\\f\\pc_flora_kp_sgrass_01.nif",
"pc\\f\\pc_flora_kp_sgrass_02.nif",
"pc\\f\\pc_flora_kp_sgrass_03.nif",
"pc\\f\\pc_flora_kp_sgrass_04.nif",
"pc\\f\\pc_flora_kp_shrub_01.nif",
"pc\\f\\pc_flora_kp_shrub_02.nif",
"pc\\f\\pc_flora_kp_shrub_03.nif",
"pc\\f\\pc_flora_kp_shrub_04.nif",
"pc\\f\\pc_flora_lilypad_01.nif",
"pc\\f\\pc_flora_lilypad_02.nif",
"pc\\f\\pc_flora_lilypad_03.nif",
"pc\\f\\pc_flora_str_shrub01.nif",
"pc\\f\\pc_flora_ww_shrub.nif",
"pek\\dg-wf_lilypad.nif",
"tr\\f\\tr_f_fern01_db.nif",
"tr\\f\\tr_f_fern01_db2.nif",
"tr\\f\\tr_f_fern02_db.nif",
"tr\\f\\tr_f_red_lily_01.nif",
"tr\\f\\tr_flora_moor_fern01.nif",
"tr\\f\\tr_flora_thirrlily_01.nif",
"tr\\f\\tr_flora_thirrlily_02.nif",
"tr\\f\\tr_flora_thirrlily_03.nif",
"tr\\f\\tr_flora_thirrlily_flw.nif",
"tr\\f\\tr_flora_tv_grass_01.nif",
"tr\\f\\tr_flora_tv_grass_02.nif",
"tr\\f\\tr_flora_tv_grass_03.nif",
"x\\ex_cave_grass00.nif",
"x\\vurt_ashgrass.nif",
}
	grassDict = table.invert(grass)

	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId, table = config}
	end

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		hideLevel = config.hideLevel
		logLevel = config.logLevel
		logLevel1 = logLevel >= 1
		logLevel2 = logLevel >= 2
		logLevel3 = logLevel >= 3
		mwse.saveConfig(configName, config, {indent = true})
	end

	local info = [[Hide Grass

Hide/delete most exterior/exterior like grass statics references on the fly
to be rendered as moving grass by MGE-XE instead
(assuming you first regenerate MGE-XE distant land after loading the provided
"MGE3\Hide Grass.ovr" MGE-XE settings).
Note: "Cull, Disable, Delete, Modify" option will store grass references deletion to saved games.
Read the readme before using it.]]

	local preferences = template:createSideBarPage{
		label = info,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	local controls = preferences:createCategory({})

	--[[local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end]]

	---local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	---local function getYesNoDescription(frmt, variableId)
		---return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	---end

	local optionList = {'Off', 'Cull', 'Cull, Disable', 'Cull, Disable, Delete', 'Cull, Disable, Delete, Modify'}
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

	controls:createDropdown({
		label = 'Hide Grass:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','hideLevel'),
		variable = createConfigVariable('hideLevel'),
	})

	optionList = {'Off', 'Low', 'Medium', 'High'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})
	mwse.mcm.register(template)
	event.register('referenceActivated', referenceActivated)
end
event.register('modConfigReady', modConfigReady)
