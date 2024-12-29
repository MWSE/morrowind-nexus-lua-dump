---@diagnostic disable: param-type-mismatch

--[[
Note: I wanted something fast & simple not using more HUD space
and able to use a single keyboard shortcut.
You only have to remember and press the key combo to show the vanilla hotkey settings window,
then you can one-click the desired action button
with the advantage of keeping your mouse pointer near the center of the screen).
This is basically a different concept compared to other visible hotkey bar mods
and will probably not work with them if they change the vanilla hotkey buttons dialog.
]]

local shortInfo = [[Click on a quick key slot to use it, Shift+click to assign it to a spell, magic item or inventory item.]]
local defaultConfig = {
logLevel = 1,
}

local author = 'abot'
local modName = 'Quicker Keys'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local smartCast, minActorAiFight, maxSpellTargetDist
local logLevel, logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	smartCast = config.smartCast
	minActorAiFight = config.minActorAiFight
	maxSpellTargetDist = config.maxSpellTargetDist
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	---mwse.log('>>> updateFromConfig() logLevel = %s', logLevel)
end
updateFromConfig()

-- set in initialized()
local inputController
local swiftCastingEnabled

-- set in loaded()
local player, mobilePlayer, player1stPerson

local hotkeyNum2String = {
[1] = 'One', [2] = 'Two', [3] = 'Three', [4] = 'Four', [5] = 'Five',
[6] = 'Six', [7] = 'Seven', [8] = 'Eight', [9] = 'Nine', [10] = 'Zero'
}
local hotkeyString2Num = table.invert(hotkeyNum2String)

local idMenuQuick_button_cancel = tes3ui.registerID('MenuQuick_button_cancel')
local idPartNonDragMenu_main = tes3ui.registerID('PartNonDragMenu_main')

local function tapBinding(keybind)
	local inputConfig = tes3.getInputBinding(keybind)
	if not inputConfig then
		return
	end
	local device = inputConfig.device
	---mwse.log('inputConfig.device = %s', device)
	if device == 0 then
		tes3.tapKey(inputConfig.code)
	end
end

---local tes3_objectType_weapon = tes3.objectType.weapon

local function equipHand2Hand()
	---mobilePlayer:unequip({type = tes3_objectType_weapon})
	---mobilePlayer.weaponReady = true
	tapBinding(tes3.keybind.quick10)
end

local function readyMagic()
	tapBinding(tes3.keybind.readyMagic)
end

local function useMagic(magicSource)
	local effects = magicSource.effects
	if not effects then
		return
	end
	---local effect = effects[1]
	
	---local controlDown = inputController:isControlDown()

	if swiftCastingEnabled then
		timer.frame.delayOneFrame(readyMagic)
	else
		mobilePlayer.castReady = true
		---timer.frame.delayOneFrame(readyMagicMCP)
	end
end

local magicalObjectTypes = {tes3.objectType.armor, tes3.objectType.book, tes3.objectType.clothing}

local function mouseClickHotKey(e)
	local el = e.source
	if inputController:isShiftDown() then
		el:forwardEvent(e)
		return
	end
	local s = string.gsub(el.name, 'MenuQuick_Quick_', '')
	local i = hotkeyString2Num[s]
	if not i then
		return
	end
	local closeMenu = false

	if i < 10 then
		local quickKey = tes3.getQuickKey({slot = i})
		if quickKey then
			---local controlDown = inputController:isControlDown()
			---local ctrlDown = inputController:isControlDown()
			local item = quickKey.item
			if item then
				closeMenu = true
				mobilePlayer:equip(item)
				if magicalObjectTypes[item.objectType] then
					if item.enchantment
					and (not item.script) then
						if logLevel2 then
							mwse.log('%s: useMagic("%s"."%s")', modPrefix,
								item.id, table.find(tes3.effect, item.enchantment.effects[1].id))
						end
						useMagic(item.enchantment)
					end
				elseif not mobilePlayer.weaponReady then
					mobilePlayer.weaponReady = true
				end
			else
				local spell = quickKey.spell
				if spell then
					closeMenu = true
					mobilePlayer:equipMagic({source = spell})
					if logLevel2 then
						mwse.log('%s: useMagic("%s"."%s") logLevel = %s', modPrefix,
							spell.id, table.find(tes3.effect, spell.effects[1].id), logLevel)
					end
					useMagic(spell)
				end -- if spell
			end -- if item
		end -- if quickKey
	else
		closeMenu = true
		timer.frame.delayOneFrame(equipHand2Hand)
	end -- if i < 10

	if closeMenu then
		local menu = el:getTopLevelMenu()
		if menu then
			local button = menu:findChild(idMenuQuick_button_cancel)
			if button then
				button:triggerEvent('mouseClick')
			end
		end
	end
end

local function uiActivatedMenuQuick(e)
	if not e.newlyCreated then
		return
	end
	local menu = e.element
	local el = menu:findChild(idPartNonDragMenu_main)
	if el then
		local child = el.children[1]
		child.children[1].text = modName
		child.children[2].text = shortInfo
	end
	for i = 1, 10 do
		local el2 = menu:findChild('MenuQuick_Quick_' .. hotkeyNum2String[i])
		if el2 then
			el2:register('mouseClick', mouseClickHotKey)
		end
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)
	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = 'Info',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = shortInfo})

	local controls = preferences:createCategory({})

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	---local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	---local function getYesNoDescription(frmt, variableId)
		---return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	---end
	
	---local function getDescription(frmt, variableId)
		---return string.format(frmt, defaultConfig[variableId])
	---end

	local optionList = {'Off', 'Message', 'Low', 'Medium'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1,
				optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)

local loadedOnceDone = false
local function loadedOnce()
	if loadedOnceDone then
		return
	end
	loadedOnceDone = true
	event.register('uiActivated', uiActivatedMenuQuick, {filter = 'MenuQuick'})
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	player1stPerson = tes3.player1stPerson
	loadedOnce()
end

event.register('initialized',
function ()
	inputController = tes3.worldController.inputController
	swiftCastingEnabled = tes3.hasCodePatchFeature(tes3.codePatchFeature.swiftCasting)
	event.register('loaded', loaded)
end, {doOnce = true})
