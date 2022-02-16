--[[
learn intervention destination /abot
--]]
local defaultConfig = {
disableTooltip = false,
disableMessage = false,
messageHotkey = { -- Shift+z by default
	keyCode = tes3.scanCode.z,
	isAltDown = false,
	isControlDown = false,
	isShiftDown = true
},
showCellXY = false,
minMysticismNeeded = 75, -- Min Mysticism needed to feel the closest destination automatically
interventionTo = "Intervention to", -- editable message string
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium
}

local author = 'abot'
local modName = 'Smart Intervention'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end

local tes3_effect_almsiviIntervention = tes3.effect.almsiviIntervention
local tes3_effect_divineIntervention = tes3.effect.divineIntervention

-- set in modConfigReady()
local interventions, templeMarkerObj, divineMarkerObj

local function getInterventionId(magic)
	local interventionId, id
	for _, eff in ipairs(magic.effects) do
		id = eff.id
		if interventions[id] then
			interventionId = id
			break
		end
	end
	return interventionId
end

-- set in loaded()
local player, mobilePlayer

local function getMarkerXYkey(ref)
	return string.format("%s,%s",
		math.floor(ref.position.x + 0.5),
		math.floor(ref.position.y + 0.5)
	)
end

local function magicCasted(e)
	if not (e.caster == player) then
		return
	end
	local interventionId = getInterventionId(e.source)
	if not interventionId then
		return
	end
	---tes3.messageBox("%s casted", interventions[interventionId])
	local markerRef
	if interventionId == tes3_effect_almsiviIntervention then
		markerRef = tes3.findClosestExteriorReferenceOfObject({object = templeMarkerObj})
	else
		markerRef = tes3.findClosestExteriorReferenceOfObject({object = divineMarkerObj})
	end
	if not markerRef then
		return
	end
	---assert(player)
	if not player.data then
		player.data = {}
	end
	local knownInterventions = player.data.ab01knownInterventions
	if not knownInterventions then
		player.data.ab01knownInterventions = {}
		knownInterventions = player.data.ab01knownInterventions
	end
	local XYkey = getMarkerXYkey(markerRef)
	if knownInterventions[XYkey] then
		return
	end
	if config.logLevel >= 1 then
		mwse.log("%s: magicCasted(e) set knownInterventions[%s] to 1", modPrefix, XYkey)
	end
	knownInterventions[XYkey] = 1 -- mark it as known by x,y coordinates
end


local function getClosestMarker(interventionId)
	local markerRef
	if interventionId == tes3_effect_almsiviIntervention then
		markerRef = tes3.findClosestExteriorReferenceOfObject({object = templeMarkerObj})
	else
		markerRef = tes3.findClosestExteriorReferenceOfObject({object = divineMarkerObj})
	end
	if not markerRef then
		return nil
	end
	if mobilePlayer.mysticism.current >= config.minMysticismNeeded then
		return markerRef
	end
	---assert(player)
	if not player.data then
		return nil
	end
	local knownInterventions = player.data.ab01knownInterventions
	if not knownInterventions then
		return nil
	end
	local XYkey = getMarkerXYkey(markerRef)
	if knownInterventions[XYkey] then
		if config.logLevel >= 2 then
			mwse.log("%s: getClosestMarker() found knownInterventions[%s]", modPrefix, XYkey)
		end
		return markerRef
	end
	return nil
end

local function getClosestDestination(interventionId)
	local markerRef = getClosestMarker(interventionId)
	if not markerRef then
		return nil
	end
	local cell = markerRef.cell
	local s
	---s = string.format("Closest %s destination:\nid: %s\nname: %s\ndisplayName: %s\neditorName: %s", interventions[interventionId], cell.id, cell.name, cell.displayName, cell.editorName)
	if config.showCellXY then
		s = cell.editorName
	else
		s = cell.displayName
	end
	return string.format("%s:\n%s", config.interventionTo, s)
end

local function getClosestInterventionDestination(interventionId)
	local markerRef = getClosestMarker(interventionId)
	if not markerRef then
		return nil
	end
	local cell = markerRef.cell
	local s
	if config.showCellXY then
		s = cell.editorName
	else
		s = cell.displayName
	end
	return string.format("%s to:\n%s", interventions[interventionId], s)
end

local function addTooltipString(tooltip, s)
	local outBlock = tooltip:createBlock()
	outBlock.flowDirection = 'top_to_bottom'
	outBlock.widthProportional = 1
	outBlock.autoHeight = true
	outBlock.borderAllSides = 1
	---outBlock:createDivider()
	local innBlock = outBlock:createBlock()
	innBlock.flowDirection = 'left_to_right'
	innBlock.widthProportional = 1
	innBlock.autoHeight = true
	innBlock.borderAllSides = 0
	local label = innBlock:createLabel({text = s})
	label.borderAllSides = 1
end

local function uiMagicTooltip(tooltip, magic)
	if config.disableTooltip then
		return
	end
	local interventionId = getInterventionId(magic)
	if not interventionId then
		return
	end
	local s = getClosestDestination(interventionId)
	if not s then
		return
	end
	addTooltipString(tooltip, s)
end

local function uiSpellTooltip(e)
	uiMagicTooltip(e.tooltip, e.spell)
end

local tes3_objectType_clothing = tes3.objectType.clothing
local tes3_clothingSlot_ring = tes3.clothingSlot.ring
local tes3_clothingSlot_amulet = tes3.clothingSlot.amulet

local function uiObjectTooltip(e)
	local obj = e.object
	local ench = obj.enchantment
	if not ench then
		return
	end
	if obj.objectType == tes3_objectType_clothing then
		if (obj.slot == tes3_clothingSlot_ring)
		or (obj.slot == tes3_clothingSlot_amulet) then
			if obj.script then
				return -- skip teleport home items
			end
		end
	end
	uiMagicTooltip(e.tooltip, ench)
end

local function keyDown(e)
	if config.disableMessage then
		return
	end
	local hotKey = config.messageHotkey
	if not (e.keyCode == hotKey.keyCode) then
		return
	end
	if (e.isShiftDown == hotKey.isShiftDown)
	and (e.isAltDown == hotKey.isAltDown)
	and (e.isControlDown == hotKey.isControlDown) then
		local almsivi = getClosestInterventionDestination(tes3_effect_almsiviIntervention)
		local divine = getClosestInterventionDestination(tes3_effect_divineIntervention)
		local s
		if almsivi then
			s = almsivi
			if divine then
				s = s .. "\n" .. divine
			end
		elseif divine then
			s = divine
		end
		if s then
			tes3.messageBox(s)
		end
		return false
	end
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()

	templeMarkerObj = tes3.getObject('TempleMarker')
	divineMarkerObj = tes3.getObject('DivineMarker')

	interventions = {
		[tes3_effect_almsiviIntervention] = tes3.findGMST(tes3.gmst.sEffectAlmsiviIntervention).value,
		[tes3_effect_divineIntervention] = tes3.findGMST(tes3.gmst.sEffectDivineIntervention).value
	}

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage({
		label='Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = string.format([[There are two ways you can know the closest Intervention spell destination:
First one is to remember the destination once you have already visited the place by intervention spells (suggested),
second one is to have high enough Mysticism skill to automatically feel the possible destination (default %s).
If you want to always know the intervention destination from the start, you can just lower the needed Mysticism threshold.]],
defaultConfig.minMysticismNeeded)
	})

	local controls = preferences:createCategory({label = ""})

	controls:createYesNoButton({
		label = 'Disable Tooltip',
		description = [[Default: No.
Disable destination tooltip for Intervention spells.]],
		variable = createConfigVariable('disableTooltip')
	})

	controls:createYesNoButton({
		label = 'Disable Message',
		description = [[Default: No.
Disable destination message for Intervention spells.]],
		variable = createConfigVariable('disableMessage')
	})
	controls:createKeyBinder({
		label = 'Message Hotkey', allowCombinations = true,
		variable = createConfigVariable('messageHotkey')
	})
	controls:createOnOffButton({
		label = 'Show destination cell XY coordinates',
		description = [[Default: No.
Show also XY exterior coordinates for Intervention destination.]],
		variable = createConfigVariable('showCellXY')
	})
	controls:createSlider({
		label = "Min. Mysticism needed for immediate knowledge of destination",
		description = string.format([[Minimum Mysticism skill needed to feel Intervention destinations
	without having to visiting the place first (default: %s)]],
			defaultConfig.minMysticismNeeded),
		variable = createConfigVariable("minMysticismNeeded")
		,min = 0, max = 200, step = 1, jump = 5
	})
	controls:createTextField({
		label = "Intervention to: message prefix",
		description = string.format(
			"Text prefix used by intervention destination messages (default: %s).",
			defaultConfig.interventionTo
		),
		variable = createConfigVariable("interventionTo")
	})
	controls:createDropdown({
		label = "Logging level:",
		options = {
			{ label = "0. Low", value = 0 },
			{ label = "1. Medium", value = 1 },
			{ label = "2. High", value = 2 },
		},
		variable = createConfigVariable("logLevel"),
		description = "Default: 0. Low."
	})

	mwse.mcm.register(template)

	event.register('keyDown',keyDown)
	event.register('loaded', loaded)
	event.register('magicCasted', magicCasted) -- spell, alchemy or enchanted items
	event.register('uiSpellTooltip', uiSpellTooltip)
	event.register('uiObjectTooltip', uiObjectTooltip, {priority = 200})

	logConfig(config, {indent = false})
	---mwse.log("%s: modConfigReady", modPrefix)
end
event.register('modConfigReady', modConfigReady)