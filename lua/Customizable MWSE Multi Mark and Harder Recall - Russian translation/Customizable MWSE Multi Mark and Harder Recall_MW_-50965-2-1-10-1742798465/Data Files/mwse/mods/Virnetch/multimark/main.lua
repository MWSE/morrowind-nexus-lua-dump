local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
-- Check Magicka Expanded framework.
if (framework == nil) then
	local function warning()
		tes3.messageBox(
			"[MultiMark ERROR] Magicka Expanded framework не установлен!"
			.. " Вам необходимо установить его, чтобы использовать этот мод."
		)
	end
	event.register("initialized", warning)
	event.register("loaded", warning)
	return
end

tes3.claimSpellEffectId("multiMark", 601)
tes3.claimSpellEffectId("multiRecall", 602)

local config = mwse.loadConfig("multi_mark")
local default = {
	dispositionRequired = 90,
	multiMarkEnabled = true,
	limitedRecallEnabled = true,
	enableMisCast = false,
	increasedMagickaCostForDistanceTraveled = false,
	costBetweenUnlinkedAreas = 300,
	maxNumberOfMarks = 16,
	enableEnchantedItemAndPotion = true,
	teleportCompanions = true,
	sortMarkList = false,
	mysticismAffectsMaxMarks = true,
	useCurrentMysticism = false,
	mysticismRequiredForMaxMarks = 100,
	expMult = 2.0,
	iMCFDTcostMultiplier = 1.0,
	iMCFDTrecallChanceMultiplier = 1.0,
	limitedRecall = 2,
	companionIntervention = false,
	companionBlacklist = { "chargen boat guard 2", "guar_white_unique", "hlaalu guard", "hlaalu guard_outside", "Imperial Guard", "Imperial Guard_ebonhear", "ordinator stationary", "ordinator wander", "ordinator_high fane", "ordinator_mournhold", "redoran guard female", "redoran guard male", "telvanni guard", "telvanni sharpshooter", "ughash gro-batul", "yashnarz gro-ufthamph", "ab01bat01", "ab01bat02", "ab01bee01", "ab01bird01", "ab01bird02", "ab01bird03", "ab01bird04", "ab01bird05", "ab01bird06", "ab01bird07", "ab01bird10", "ab01bird11", "ab01bird12", "ab01bird13", "ab01bird14", "ab01bird15", "ab01butterfly01", "ab01butterfly02", "ab01butterfly03", "ab01butterfly04", "ab01firefly01" }
}
if config then
	for k, v in pairs(default) do
		if config[k] == nil then
			config[k] = v
		end
	end
else
	config = default
end


local MarkMenu = {}
local RecallMenu = {}

local lastCastCost = 0
local lastCastChance = 0

local MarkMenuid
local RecallMenuid
local NewMarkButtonid
local NewMarkMenuid
local NewMarkNameid
local NewMarkDeleteButtonid
local NewMarkCancelButtonid
local NewMarkOkButtonid
local RecallToMenuid
local CancelMarkid
local CancelRecallid
local RecallCompanionMenuid

local functions_
local functions
if config.enableMisCast then
	functions_ = include("OperatorJack.MiscastEnhanced.functions")
	if functions_ then
		functions = require("OperatorJack.MiscastEnhanced.functions")
	end
	if functions == nil then
		local function warning()
			if config.enableMisCast then
				tes3.messageBox(
					"[MultiMark ERROR] Miscast Enhanced не установлен!"
					.. " Вам необходимо установить этот мод чтобы использовать возможности Miscast Enhanced."
				)
				config.enableMisCast = false
			end
		end
		event.register("initialized", warning)
		event.register("loaded", warning)
	end
end

local debug = false

local vanillaMarkCost
local vanillaRecallCost
local function addEffects()
	local mark = assert(tes3.getMagicEffect(tes3.effect.mark))
	local recall = assert(tes3.getMagicEffect(tes3.effect.recall))

	vanillaMarkCost = mark.baseMagickaCost
	vanillaRecallCost = recall.baseMagickaCost
	local recallBaseCost
	local markBaseCost
	if config.multiMarkEnabled then
		markBaseCost = 0
		recallBaseCost = 0
	else
		markBaseCost = vanillaMarkCost
		recallBaseCost = vanillaRecallCost
	end

	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.multiMark,
		name = "Пометка",
		description = "Этот эффект позволяет игроку запоминать местоположение для использования заклинания Возврат. Местоположение определяется местоположением заклинателя во время произношения заклинания. Заклинатель также может создавать связь между существами и дружественными гуманоидами, позволяя заклинателю призвать их в выбранное местоположение с помощью заклинания Возврат.",

		-- Basic dials.
		baseCost = markBaseCost,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = false,
		appliesOnce = mark.appliesOnce,
		canCastSelf = true,
		canCastTarget = false,
		canCastTouch = false,
		hasNoDuration = true,
		hasNoMagnitude = true,
		nonRecastable = mark.nonRecastable,
		unreflectable = mark.unreflectable,

		-- Graphics/sounds.
		icon = mark.icon,
		particleTexture = mark.particleTexture,
		lighting = { mark.lightingRed, mark.lightingGreen, mark.lightingBlue }
	})

	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.multiRecall,
		name = "Возврат",
		description = "Субъект этого заклинания может мгновенно телепортироваться к маркеру, установленному заклинанием Пометка. Субъект также может призвать компаньонов, которые были связаны заклинанием Пометка с их текущим местоположением.",

		-- Basic dials.
		baseCost = recallBaseCost,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = false,
		appliesOnce = recall.appliesOnce,
		canCastSelf = true,
		canCastTarget = false,
		canCastTouch = false,
		hasNoDuration = true,
		hasNoMagnitude = true,
		nonRecastable = recall.nonRecastable,
		unreflectable = recall.unreflectable,

		-- Graphics/sounds.
		icon = recall.icon,
		particleTexture = recall.particleTexture,
		lighting = { recall.lightingRed, recall.lightingGreen, recall.lightingBlue }
	})
end
event.register("magicEffectsResolved", addEffects)

local function misCast()
	if lastCastCost > 0 and config.enableMisCast == true then	--Miscast, only for spells
		if functions == nil then
			config.enableMisCast = false
		else
			local chance = math.random(0, 100)
			if (chance <= 15 or functions.isDebug() == true) then
				functions.handlers.genericTeleportEffectHandler({ reference = tes3.mobilePlayer })
				functions.gatedMessageBox("Ваша неудачная попытка произнести заклинание привела к его неправильному действию.")
			end
		end
	end
end

local function castFailed()
	timer.start{
		duration = 0.1,
		callback = function()
		tes3.playSound{
			reference = tes3.player,
			sound = "Spell Failure Mysticism"
		}
		tes3.removeSound{
			reference = tes3.player,
			sound = "mysticism cast"
		}
		tes3.removeSound{
			reference = tes3.player,
			sound = "mysticism hit"
		}
	end}
end

local function addEffect(_, effect)
	tes3.applyMagicSource({
		reference = tes3.player,
		bypassResistances = true,
		effects = {
			{ id = effect, duration = 1 },
		}
	})
end

local function getRecallsLeft()
	local data = tes3.player.data.multiMark
	local day = tes3.worldController.daysPassed.value
	if day == data.lastRecallDay then
		return (config.limitedRecall - data.RecallsCast)
	else
		return config.limitedRecall
	end
end

--- @param cell tes3cell
--- @return tes3vector3?
local function findExteriorLocation(cell)
	--- @type tes3cell[]
	local linkedInteriors = {}
	--- @type tes3cell[]
	local cellsChecked = {}
		--Checks current cell for doors leading to exteriors
	for door in cell:iterateReferences(tes3.objectType.door, false) do
		local doorObject = door.object
		if doorObject then
			if door.destination then
				if door.destination.cell.isInterior == true then
					--Makes sure the interior hasn't been checked already
					if not table.find(cellsChecked, door.destination.cell.name) then
						--Add interior cells to table
						table.insert(linkedInteriors, door.destination.cell)
						table.insert(cellsChecked, door.destination.cell.name)
					end
				else
					--Return if an exterior cell was found
					local exteriorLocation = door.destination.marker.position
					return exteriorLocation
				end
			end
		end
	end
	table.insert(cellsChecked, cell.name)

	--If no exteriors were found from the doors in the current cell, check the interiors found
	while #linkedInteriors > 0 do		--Repeat until all interiors have been checked
		local interiorCell = linkedInteriors[1]
		for door in interiorCell:iterateReferences(tes3.objectType.door, false) do
			if door.destination then
				if door.destination.cell.isInterior == true then
					--Makes sure the interior hasn't been checked already
					if not table.find(cellsChecked, door.destination.cell.name) then
						--Adds found interiors to the list
						table.insert(linkedInteriors, door.destination.cell)
						table.insert(cellsChecked, door.destination.cell.name)
					end
				else
					--Return if an exterior was found
					local exteriorLocation = door.destination.marker.position
					return exteriorLocation
				end
			end
		end
		--Removes the checked interior from the list
		table.remove(linkedInteriors, 1)
	end
	return nil
end

--- @param cell tes3cell
--- @param target string
--- @return boolean
local function linkedInternalLocations(cell, target)
	--- @type tes3cell[]
	local linkedInteriors = {}
	--- @type tes3cell[]
	local cellsChecked = {}
	table.insert(linkedInteriors, cell)
	table.insert(cellsChecked, cell.name)
	--If no exteriors were found from the doors in the current cell, check the interiors found
	while #linkedInteriors > 0 do		--Repeat until all interiors have been checked
		local interiorCell = linkedInteriors[1]
		if interiorCell.id == target then
			return true
		end
		for door in interiorCell:iterateReferences(tes3.objectType.door, false) do
			if door.destination then
				if door.destination.cell.isInterior == true then
					--Makes sure the interior hasn't been checked already
					if not table.find(cellsChecked, door.destination.cell.name) then
						--Adds found interiors to the list
						table.insert(linkedInteriors, door.destination.cell)
						table.insert(cellsChecked, door.destination.cell.name)
					end
				end
			end
		end
		--Removes the checked interior from the list
		table.remove(linkedInteriors, 1)
	end
	return false
end


local function calcRecallDistance(markExtLocation, Markid)
		--Calculates distance from current exterior location to mark exterior location
	local currentPosition
	local distance
	if config.increasedMagickaCostForDistanceTraveled == true then
			--Magicka cost based on distance to mark.
		local cell = tes3.getPlayerCell()
		if cell.isInterior == true then
			currentPosition = findExteriorLocation(cell)
		else
			currentPosition = tes3.mobilePlayer.position
		end
--		if markExtLocation == nil or currentPosition == nil then
--			distance = 0
--		else
--			distance = markExtLocation:distance(currentPosition)
--		end
		local markCell = tes3.player.data.multiMark.MarkSlots[Markid].Cell
		if markExtLocation ~= nil and currentPosition ~= nil then
			distance = markExtLocation:distance(currentPosition)
		elseif linkedInternalLocations(cell, markCell) then
			distance = 0.0
		else
			distance = -1
		end

	else
		distance = 0
	end
	return distance
end

local function calcRecallCost(distance)
	local cost
	if config.increasedMagickaCostForDistanceTraveled == true then
--OLD	cost = lastCastCost + config.iMCFDTcostMultiplier * distance / 450
		if distance == -1 then	--Recalling between unlinked areas like Mournhold and Vvardenfell
			cost = config.costBetweenUnlinkedAreas
		elseif distance > 300000 then
			cost = 0.0025 * distance + 200
		else
			local costMult = tonumber(config.iMCFDTcostMultiplier)
			if not costMult then
				costMult = 1.0
				config.iMCFDTcostMultiplier = 1.0
			end
			cost = costMult * 1180 / ( 1 + math.exp(1) ^ ( -0.000014 * ( distance - 200000 ) ) )
		end
	else
		cost = lastCastCost
	end
	return cost
end

local function calcRecallChance(cost)
	local currentFatigue = tes3.mobilePlayer.fatigue.current
	local baseFatigue = tes3.mobilePlayer.fatigue.base
	local recallChance = tonumber(config.iMCFDTrecallChanceMultiplier)
	if not recallChance then
		recallChance = 1.0
		config.iMCFDTrecallChanceMultiplier = 1.0
	end
	local fatigueMultiplier = 0.75 + 0.5 * currentFatigue / baseFatigue
	local mysticism = tes3.mobilePlayer.mysticism.current

	if recallChance <= 0 or cost <= 0 then
		recallChance = 100
	elseif config.increasedMagickaCostForDistanceTraveled == false then
		recallChance = lastCastChance
	else
--OLD	recallChance = recallChance * (tes3.mobilePlayer.mysticism.current / 2)^1.2 * 285 / cost * fatigueMultiplier
		recallChance = recallChance * fatigueMultiplier * 125 / ( 1 + math.exp(1) ^ ( 0.003 * ( 100 / mysticism ) * ( cost - 3.4 * mysticism ) ) )
	end

	return recallChance
end

local function CancelMark()
	local menu = tes3ui.findMenu(NewMarkMenuid)

	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function CancelNewMark()
	local menu = tes3ui.findMenu(MarkMenuid)

	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function CancelRecallToMark()
	local menu = tes3ui.findMenu(RecallToMenuid)

	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function CancelRecallLocationSelection()
	local menu = tes3ui.findMenu(RecallMenuid)

	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
		if (config.limitedRecallEnabled == true and tes3.player.data.multiMark.RecallsCast > 0) then
			tes3.player.data.multiMark.RecallsCast = (tes3.player.data.multiMark.RecallsCast - 1)
		end
	end
end

local function CancelRecallCompanion()
	local menu = tes3ui.findMenu(RecallCompanionMenuid)

	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function DeleteMark(id)
--	local MarksUsed = tes3.player.data.multiMark.MarksUsed
--	tes3.player.data.multiMark.MarksUsed = (MarksUsed - 1)

	tes3.messageBox("Удалена пометка "..tes3.player.data.multiMark.MarkSlots[id].Name)
	table.remove(tes3.player.data.multiMark.MarkSlots, id)

	local markMenu = tes3ui.findMenu(NewMarkMenuid)
	local recallMenu = tes3ui.findMenu(RecallToMenuid)

	if (markMenu) then
		CancelMark()
		CancelNewMark()
	elseif (recallMenu) then
		CancelRecallToMark()
		CancelRecallLocationSelection()
	end
end

local function isActorInBlacklist(actor)
	local id = actor.reference.id
	if (actor.reference.object.isInstance) then
		id = actor.reference.object.baseObject.id
	end
	return (table.find(config.companionBlacklist, id) ~= nil)
end

local function NewMarkOk(MarkNumber)
	local menu = tes3ui.findMenu(NewMarkMenuid)
	local markMenu = tes3ui.findMenu(MarkMenuid)

	if (menu) then
		local MarkName = menu:findChild(NewMarkNameid).text

		tes3ui.leaveMenuMode()
		menu:destroy()
		if (markMenu) then
			markMenu:destroy()
		end

		local cell = tes3.getPlayerCell()
		local position = tes3.player.position:copy()
		local rotation = tes3.player.orientation:copy()

			--Finds the exterior location if marking interior
		local exteriorLocation
		if cell.isInterior == true then
			exteriorLocation = findExteriorLocation(cell)
		else
			exteriorLocation = position
		end

		if MarkNumber >= 1 then		--Replace Existing Mark
			tes3.player.data.multiMark.MarkSlots[MarkNumber] = {
				Name = MarkName,
				Cell = cell.id,
				Position = { position.x, position.y, position.z },
				Rotation = { 0, 0, rotation.z },
			}
			tes3.messageBox("Заменить предыдущую пометку "..MarkName)
		else						--Create a New Mark
		--	local MarksUsed = tes3.player.data.multiMark.MarksUsed
		--	tes3.player.data.multiMark.MarksUsed = (MarksUsed + 1)
		--	MarkNumber = tes3.player.data.multiMark.MarksUsed
			MarkNumber = #tes3.player.data.multiMark.MarkSlots + 1

			tes3.player.data.multiMark.MarkSlots[MarkNumber] = {
				Name = MarkName,
				Cell = cell.id,
				Position = { position.x, position.y, position.z },
				Rotation = { 0, 0, rotation.z },
			}
			tes3.messageBox("Создана пометка "..MarkName)
		end

		if exteriorLocation == nil then
			tes3.player.data.multiMark.MarkSlots[MarkNumber].exteriorLocation = nil
		else
			tes3.player.data.multiMark.MarkSlots[MarkNumber].exteriorLocation = { x = exteriorLocation.x, y = exteriorLocation.y, z = exteriorLocation.z }
		end


		tes3.playSound{
			reference = tes3.player,
			sound = "mysticism hit"
		}
		tes3.modStatistic({
			reference = tes3.player,
			name = "magicka",
			current = -lastCastCost
		})
		if lastCastCost > 0 then
				--Gives XP for successful cast
			local mystSkill = tes3.getSkill(tes3.skill.mysticism)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.mysticism, mystSkill.actions[1])
		end
	end
end

--Create New Mark or replace existing
local function NewMarkName(MarkNumber)
	if (tes3.mobilePlayer.magicka.current >= lastCastCost) then
		if (tes3ui.findMenu(NewMarkMenuid) ~= nil) then
			return
		end

		local NewMarkMenu = tes3ui.createMenu{ id = NewMarkMenuid, fixedFrame = true }
		NewMarkMenu.alpha = 1.0

		local NewMarkLabel
		if MarkNumber >= 1 then	--Replacing existing mark
			NewMarkLabel = NewMarkMenu:createLabel{ text = 'Заменить пометку '..tes3.player.data.multiMark.MarkSlots[MarkNumber].Name..' with:' }
		else					--Creating New Mark
			NewMarkLabel = NewMarkMenu:createLabel{ text = 'Создать новую пометку' }
		end
		NewMarkLabel.borderBottom = 5

		local NewMarkBlock = NewMarkMenu:createBlock{}
		NewMarkBlock.width = 300
		NewMarkBlock.autoHeight = true
		NewMarkBlock.childAlignX = 0.5

		local border = NewMarkBlock:createThinBorder{}
		border.width = 300
		border.height = 30
		border.childAlignX = 0.5
		border.childAlignY = 0.5

		local inputBlock = border:createTextInput{ id = NewMarkNameid }
		if MarkNumber >= 1 then	--Replacing existing mark
			inputBlock.text = tes3.player.data.multiMark.MarkSlots[MarkNumber].Name
		else					--Creating New Mark
			inputBlock.text = tes3.mobilePlayer.cell.name or tes3.mobilePlayer.cell.region.name
		end
		inputBlock.borderLeft = 5
		inputBlock.borderRight = 5
		inputBlock.widget.lengthLimit = 31

		local buttonBlock = NewMarkMenu:createBlock{}
		buttonBlock.widthProportional = 1.0
		buttonBlock.autoHeight = true
		buttonBlock.childAlignX = 1.0

		local buttonDelete = buttonBlock:createButton{ id = NewMarkDeleteButtonid, text = tes3.findGMST("sDelete").value }
		local buttonCancel = buttonBlock:createButton{ id = NewMarkCancelButtonid, text = tes3.findGMST("sCancel").value }
		local buttonOk = buttonBlock:createButton{ id = NewMarkOkButtonid, text = tes3.findGMST("sOK").value }

		buttonDelete:register(
			"mouseClick",
			function()
				DeleteMark(MarkNumber)
			end
		)
		buttonCancel:register("mouseClick", CancelMark)
		NewMarkMenu:register(
			"keyEnter",
			function()
				NewMarkOk(MarkNumber)
			end
		)
		inputBlock:register(
			"keyEnter",
			function()
				NewMarkOk(MarkNumber)
			end
		)
		buttonOk:register(
			"mouseClick",
			function()
				NewMarkOk(MarkNumber)
			end
		)

		NewMarkMenu:updateLayout()
		tes3ui.enterMenuMode(NewMarkMenuid)
		tes3ui.acquireTextInput(inputBlock)
	else
		tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicInsufficientSP).value)
	end
end

local function onCastMark()
	local MarksTotal
	if config.mysticismAffectsMaxMarks == true then
			--Calculate Maximum Number of Marks Based On Base Mysticism
		local playerMysticism
		if config.useCurrentMysticism == true then
			playerMysticism = tes3.mobilePlayer.mysticism.current
		else
			playerMysticism = tes3.mobilePlayer.mysticism.base
		end
		local maxMarks = config.maxNumberOfMarks
		local MystForMaxMarks = config.mysticismRequiredForMaxMarks
		local expMult = tonumber(config.expMult)
		if not expMult then
			expMult = 2.0
			config.expMult = 2.0
		end

		if playerMysticism >= MystForMaxMarks then
			MarksTotal = maxMarks
		else
			MarksTotal = ((playerMysticism / MystForMaxMarks * 100) ^ expMult) / ((100 ^ expMult) / maxMarks)
		end
	else
		MarksTotal = config.maxNumberOfMarks
	end

	MarksTotal = math.floor(MarksTotal)
	MarksTotal = math.max(MarksTotal, 1)

	if (tes3ui.findMenu(MarkMenuid) ~= nil) then
		return
	end

--Create Mark Menu
	MarkMenu = tes3ui.createMenu{ id = MarkMenuid, fixedFrame = true }
	local markMenuBlock = MarkMenu:createBlock{}
	markMenuBlock.flowDirection = "left_to_right"
	markMenuBlock.width = 550
	markMenuBlock.autoHeight = true
	markMenuBlock.childAlignX = 0.5

	local markBlock = markMenuBlock:createBlock{}
	markBlock.flowDirection = "top_to_bottom"
	markBlock.width = 300
	markBlock.autoHeight = true
	markBlock.childAlignX = 0.5

	local MarksLeft = (MarksTotal - #tes3.player.data.multiMark.MarkSlots)
	if MarksLeft < 0 then
		MarksLeft = 0
	end
	local MarkLabel = markBlock:createLabel{ text = 'У вас осталось '..MarksLeft..'/'..MarksTotal..' пометок. Какую пометку использовать для запоминания вашего текущего местоположения?' }
	MarkLabel.borderBottom = 5
	MarkLabel.wrapText = true
	MarkLabel.widthProportional = 1.0

	local markBorder = markBlock:createThinBorder{}
	markBorder.flowDirection = "top_to_bottom"
	markBorder.width = 300
	markBorder.height = 500
	markBorder.childAlignX = 0.5
	markBorder.childAlignY = 0.5

	local markList = markBorder:createVerticalScrollPane{}
	markList.widthProportional = 1.0
	markList.height = 400

	local buttonBlock = markBorder:createBlock{}
	buttonBlock.widthProportional = 1.0
	buttonBlock.autoHeight = true
	buttonBlock.childAlignX = 1.0

--Companion List
	local companionBlock = markMenuBlock:createBlock{}
	companionBlock.flowDirection = "top_to_bottom"
	companionBlock.width = 250
	companionBlock.autoHeight = true
	companionBlock.childAlignX = 0.5

	local companionLabel = companionBlock:createLabel{ text = 'Добавить компаньонов, чтобы затем призвать их к себе.' }
	companionLabel.borderBottom = 5
	companionLabel.wrapText = true
	companionLabel.widthProportional = 1.0

	local companionBorder = companionBlock:createThinBorder{}
	companionBorder.flowDirection = "top_to_bottom"
	companionBorder.width = 250
	companionBorder.height = 500
	companionBorder.childAlignX = 0.5
	companionBorder.childAlignY = 0.5

	local companionList = companionBorder:createVerticalScrollPane{}
	companionList.widthProportional = 1.0
	companionList.height = 400

--New Mark
	local NewMarkButton
	if MarksLeft > 0 then
		NewMarkButton = buttonBlock:createButton{ id = NewMarkButtonid, text = 'Создать новую пометку' }
		NewMarkButton:register(
			"mouseClick",
			function ()
				NewMarkName(0)
			end
		)
	end
--Used Mark Slots
	if config.sortMarkList then
		table.sort(tes3.player.data.multiMark.MarkSlots, function(a, b)
			return a.Name < b.Name
		end)
	end
	for i = 1, #tes3.player.data.multiMark.MarkSlots do
		local MarkName = tes3.player.data.multiMark.MarkSlots[i].Name	--Get Mark Name from table
		local markSelectUsed = markList:createButton{ id = "V1R_MM_UsedMarkButtons", text = MarkName }
		markSelectUsed:register(
			"mouseClick",
			function()
				NewMarkName(i)
			end
		)
	end
--Cancel
	local CancelMarkButton = buttonBlock:createButton{ id = CancelMarkid, text = tes3.findGMST("sCancel").value }
	CancelMarkButton:register("mouseClick", CancelNewMark)
--Companions
	local markedCompanions = tes3.player.data.multiMark.markedCompanions
	for _, companion in ipairs(tes3.mobilePlayer.friendlyActors) do
		local companionName = companion.reference.object.name
		if debug then print("Found Friendly Actor: "..companionName) end
		if companion ~= tes3.mobilePlayer then
			if tes3.getCurrentAIPackageId({ reference = companion }) == tes3.aiPackage.follow then
				if isActorInBlacklist(companion) == false then
					local animState = companion.actionData.animationAttackState
					if (companion.health.current > 0 and animState ~= tes3.animationState.dying and animState ~= tes3.animationState.dead) then
						local companionid = companion.reference.object.id
						local companionButton = companionList:createTextSelect{ id = "V1R_MM_CompanionButtons", text = companionName }
						if table.find(markedCompanions, companionid) then
							if debug then print("Added") end
							companionButton.color = {0, 0.9, 0}
							companionButton.widget.idle = {0, 0.9, 0}
							companionButton.widget.over = {0.25, 1.0, 0.25}
							companionButton.widget.pressed = {0.5, 1.0, 0.5}
						else
							if debug then print("Not Added") end
							companionButton.color = {0.9, 0, 0}
							companionButton.widget.idle = {0.9, 0, 0}
							companionButton.widget.over = {1.0, 0.25, 0.25}
							companionButton.widget.pressed = {1.0, 0.5, 0.5}
						end
						MarkMenu:updateLayout()

						companionButton:register(
							"mouseClick",
							function()
								if table.find(markedCompanions, companionid) then
									table.removevalue(markedCompanions, companionid)
									tes3.messageBox("Removed "..companionName)
									companionButton.color = {0.9, 0, 0}
									companionButton.widget.idle = {0.9, 0, 0}
									companionButton.widget.over = {1.0, 0.25, 0.25}
									companionButton.widget.pressed = {1.0, 0.5, 0.5}
								else
									local disposition =	companion.reference.object.disposition or 100
									if (companion.reference.object.objectType == tes3.objectType.npc) and (disposition < config.dispositionRequired) then
										tes3.messageBox("Компаньон не астолько привязан к вам, чтобы позволить вам телепортировать его.")
									else
										table.insert(markedCompanions, companionid)
										tes3.messageBox("Добавлено "..companionName)
										if debug then print("Added "..companionName) end
										companionButton.color = {0, 0.9, 0}
										companionButton.widget.idle = {0, 0.9, 0}
										companionButton.widget.over = {0.25, 1.0, 0.25}
										companionButton.widget.pressed = {0.5, 1.0, 0.5}
									end
								end
								MarkMenu:updateLayout()
							end
						)
					end
				end
			end
		end
	end

	MarkMenu:updateLayout()
	tes3ui.enterMenuMode(MarkMenuid)
end

local function RecallCompanion(companionid, cost, chance)
	local menu = tes3ui.findMenu(RecallCompanionMenuid)
	local recallMenu = tes3ui.findMenu(RecallMenuid)

	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()

		local companionRef = tes3.getReference(tes3.player.data.multiMark.markedCompanions[companionid])
		local companionName = companionRef.object.name
		local Cell = tes3.getPlayerCell()
		local Position = tes3.mobilePlayer.position

		if chance >= math.random(0, 100) then
			tes3.modStatistic({
				reference = tes3.player,
				name = "magicka",
				current = -cost
			})
			if (recallMenu) then recallMenu:destroy() end
			tes3.positionCell({
				reference = companionRef,
				cell = Cell,
				position = Position
			})
			tes3.playSound{
				reference = tes3.player,
				sound = "mysticism hit"
			}
			if lastCastCost > 0 then
					--Gives XP for successful cast
				local mystSkill = tes3.getSkill(tes3.skill.mysticism)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.mysticism, mystSkill.actions[1])
			end
			timer.delayOneFrame(function()
				if companionRef.mobile.health.current <= 0 then
					table.remove(tes3.player.data.multiMark.markedCompanions, companionid)
					if debug then print("Removed "..companionName.."in slot "..companionid) end
				end
				-- Fix AI, from abot's Smart Companions
				mwse.memory.writeByte({
					address = mwse.memory.convertFrom.tes3mobileObject(companionRef.mobile) + 0xC0,
					byte = 0x00,
				})
			end)
		else
				--Failed recall
			tes3.messageBox("Заклинание Возврат не сработало "..companionName)
			tes3.modStatistic({
				reference = tes3.player,
				name = "magicka",
				current = -cost
			})
			castFailed()
			if (recallMenu) then recallMenu:destroy() end
		end
	end
end

local function RecallToOk(Markid)
	local menu = tes3ui.findMenu(RecallToMenuid)
	local recallMenu = tes3ui.findMenu(RecallMenuid)

	if (menu) then

		local MarkName = tes3.player.data.multiMark.MarkSlots[Markid].Name
		local Cell = tes3.player.data.multiMark.MarkSlots[Markid].Cell
		local Position = tes3.player.data.multiMark.MarkSlots[Markid].Position
		local Orientation = tes3.player.data.multiMark.MarkSlots[Markid].Rotation

		local extLocTable = tes3.player.data.multiMark.MarkSlots[Markid].exteriorLocation
		local exteriorLocation
		if extLocTable then
			exteriorLocation = tes3vector3.new(extLocTable.x, extLocTable.y, extLocTable.z)
		else
			exteriorLocation = nil
		end

		tes3ui.leaveMenuMode()
		menu:destroy()

		local distance = calcRecallDistance(exteriorLocation, Markid)
		local cost = calcRecallCost(distance)
		local recallChance = calcRecallChance(cost)
		if recallChance >= math.random(0, 100) then
						--Success! Teleport player to mark
			tes3.modStatistic({
				reference = tes3.player,
				name = "magicka",
				current = -cost
			})
			if (recallMenu) then recallMenu:destroy() end
			tes3.positionCell({
				reference = tes3.mobilePlayer,
				cell = Cell,
				position = Position,
				orientation = Orientation,
				teleportCompanions = config.teleportCompanions
			})
			tes3.playSound{
				reference = tes3.player,
				sound = "mysticism hit"
			}
			if lastCastCost > 0 then
					--Gives XP for successful cast
				local mystSkill = tes3.getSkill(tes3.skill.mysticism)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.mysticism, mystSkill.actions[1])
			end
		else
				--Failed recall
			tes3.messageBox("Заклинание Возврат не сработало для пометки "..MarkName)
			tes3.modStatistic({
				reference = tes3.player,
				name = "magicka",
				current = -cost
			})
			castFailed()
			if (recallMenu) then recallMenu:destroy() end
			misCast()
		end
	end
end

local function RecallToMark(Markid)

	local extLocTable = tes3.player.data.multiMark.MarkSlots[Markid].exteriorLocation
	local exteriorLocation
	if extLocTable then
		exteriorLocation = tes3vector3.new(extLocTable.x, extLocTable.y, extLocTable.z)
	else
		exteriorLocation = nil
	end

	local distance = calcRecallDistance(exteriorLocation, Markid)
	local cost = calcRecallCost(distance)
	local chance = calcRecallChance(cost)
	if chance > 100 then
		chance = 100
	end
	if (tes3.mobilePlayer.magicka.current >= cost) then
			--Enough magicka.
		if (tes3ui.findMenu(RecallToMenuid) ~= nil) then
			return
		end

		local RecallToMenu = tes3ui.createMenu{ id = RecallToMenuid, fixedFrame = true }
		RecallToMenu.alpha = 1.0
		local RecallToLabel = RecallToMenu:createLabel{ text = "Возврат в "..tes3.player.data.multiMark.MarkSlots[Markid].Name..". Cost: "..math.round(cost, 0).." Шанс: "..math.round(chance, 0) }
		RecallToLabel.borderBottom = 5

		local RecallToBlock = RecallToMenu:createBlock{}
		RecallToBlock.width = 300
		RecallToBlock.autoHeight = true
		RecallToBlock.childAlignX = 0.5

		local buttonBlock = RecallToMenu:createBlock{}
		buttonBlock.widthProportional = 1.0
		buttonBlock.autoHeight = true
		buttonBlock.childAlignX = 1.0

		local buttonDelete = buttonBlock:createButton{ id = NewMarkDeleteButtonid, text = tes3.findGMST("sDelete").value }
		local buttonCancel = buttonBlock:createButton{ id = "V1R_MM_RecallToCancel", text = tes3.findGMST("sCancel").value }
		local buttonOk = buttonBlock:createButton{ id = "V1R_MM_RecallToOk", text = tes3.findGMST("sOK").value }

		buttonDelete:register(
			"mouseClick",
			function()
				DeleteMark(Markid)
			end
		)
		buttonCancel:register("mouseClick", CancelRecallToMark)
		RecallToMenu:register(
			"keyEnter",
			function()
				RecallToOk(Markid)
			end
		)
		buttonOk:register(
			"mouseClick",
			function()
				RecallToOk(Markid)
			end
		)

		RecallToMenu:updateLayout()
		tes3ui.enterMenuMode(RecallToMenuid)
	else
			--Not enough magicka
		tes3.messageBox("У вас недостаточно магии чтобы произнести заклинание Возврат для выбранной пометки.")
	end
end

local function onCastRecall()
	if (tes3ui.findMenu(RecallMenuid) ~= nil) then
		return
	end

--Create Recall Menu
	RecallMenu = tes3ui.createMenu{ id = RecallMenuid, fixedFrame = true }
	local recallMenuBlock = RecallMenu:createBlock{}
	recallMenuBlock.flowDirection = "left_to_right"
	recallMenuBlock.width = 550
	recallMenuBlock.autoHeight = true
	recallMenuBlock.childAlignX = 0.5

	local recallBlock = recallMenuBlock:createBlock{}
	recallBlock.flowDirection = "top_to_bottom"
	recallBlock.width = 300
	recallBlock.autoHeight = true
	recallBlock.childAlignX = 0.5

	local MarksUsed = #tes3.player.data.multiMark.MarkSlots
	local RecallLabel = recallBlock:createLabel{ text = 'У вас '..MarksUsed..' пометок. Какаю из них использовать для возврата?' }
	RecallLabel.borderBottom = 5
	RecallLabel.wrapText = true
	RecallLabel.widthProportional = 1.0

	local recallBorder = recallBlock:createThinBorder{}
	recallBorder.flowDirection = "top_to_bottom"
	recallBorder.width = 300
	recallBorder.height = 500
	recallBorder.childAlignX = 0.5
	recallBorder.childAlignY = 0.5

	local markList = recallBorder:createVerticalScrollPane{}
	markList.widthProportional = 1.0
	markList.height = 400

	local buttonBlock = recallBorder:createBlock{}
	buttonBlock.widthProportional = 1.0
	buttonBlock.autoHeight = true
	buttonBlock.childAlignX = 1.0

--Companion List
	local companionBlock = recallMenuBlock:createBlock{}
	companionBlock.flowDirection = "top_to_bottom"
	companionBlock.width = 250
	companionBlock.autoHeight = true
	companionBlock.childAlignX = 0.5

	local companionLabel = companionBlock:createLabel{ text = 'Возврат компаньонов к вашему местоположению.' }
	companionLabel.borderBottom = 5
	companionLabel.wrapText = true
	companionLabel.widthProportional = 1.0

	local companionBorder = companionBlock:createThinBorder{}
	companionBorder.flowDirection = "top_to_bottom"
	companionBorder.width = 250
	companionBorder.height = 500
	companionBorder.childAlignX = 0.5
	companionBorder.childAlignY = 0.5

	local companionList = companionBorder:createVerticalScrollPane{}
	companionList.widthProportional = 1.0
	companionList.height = 400

--Mark Slots
	if config.sortMarkList then
		table.sort(tes3.player.data.multiMark.MarkSlots, function(a, b)
			return a.Name < b.Name
		end)
	end
	local cost = {}
	local chance = {}
	for i = 1, MarksUsed do
		local MarkName = tes3.player.data.multiMark.MarkSlots[i].Name	--Get Mark Name from table
				--Calculates cost and chance
		local extLocTable = tes3.player.data.multiMark.MarkSlots[i].exteriorLocation
		local exteriorLocation
		if extLocTable then
			exteriorLocation = tes3vector3.new(extLocTable.x, extLocTable.y, extLocTable.z)
		else
			exteriorLocation = nil
		end
		local distance = calcRecallDistance(exteriorLocation, i)

		cost[i] = calcRecallCost(distance)
		cost[i] = math.round(cost[i], 0)

		chance[i] = calcRecallChance(cost[i])
		if chance[i] > 100 then
			chance[i] = 100
		end
		chance[i] = math.round(chance[i], 0)

		local recallSelect = markList:createButton{ id = "V1R_MM_UsedMarkButtons", text = MarkName }
		recallSelect:register(
			"help",
			function()
				local toolTip = tes3ui.createTooltipMenu()
				local chanceM
				if (tes3.mobilePlayer.magicka.current >= cost[i]) then
					chanceM = chance[i]
				else	--Shows 0 chance if not enough magicka
					chanceM = 0
				end

				local header = nil
				local markData = tes3.player.data.multiMark.MarkSlots[i]
				local destination = tes3.getCell({ id = markData.Cell }) or tes3.getCell({ position = markData.Position })
				if (destination) then
					header = toolTip:createLabel({ text = destination.displayName })
				else
					header = toolTip:createLabel({ text = "Unknown Location" })
				end
				header.color = tes3ui.getPalette(tes3.palette.headerColor)

				if (distance > 0) then
					toolTip:createLabel({ text = string.format("Distance: %d", distance) })
				end
				
				toolTip:createLabel({ text = string.format("Cost: %d", cost[i]) })
				toolTip:createLabel({ text = string.format("Chance: %d", chanceM) })
			end
		)
		recallSelect:register(
			"mouseClick",
			function()
				RecallToMark(i)
			end
		)
	end
--Cancel
	local cancelRecall = buttonBlock:createButton{ id = CancelRecallid, text = tes3.findGMST("sCancel").value }
	cancelRecall:register("mouseClick", CancelRecallLocationSelection)
--Companions
	local markedCompanions = tes3.player.data.multiMark.markedCompanions
	local companionCost = {}
	local companionChance = {}
	for i=1, #markedCompanions do
		local companionRef = tes3.getReference(markedCompanions[i])
		if companionRef then
			local companionObject = companionRef.object
			local companionName = companionObject.name
			local disposition =	companionObject.disposition or 100
			local companionCell = companionRef.cell
			local companionPosition = companionRef.position
			local playerCell = tes3.getPlayerCell()
			local playerPosition = tes3.mobilePlayer.position

			if playerCell == companionCell then
				if lastCastCost > 0 then
					companionCost[i] = math.round(lastCastCost, 0)
					companionChance[i] = math.round(lastCastChance, 0)
					if companionChance[i] > 100 then
						companionChance[i] = 100
					end
				else
					companionCost[i] = 0
					companionChance[i] = 100
				end
			else
				if companionCell.isInterior == true then
					companionPosition = findExteriorLocation(companionCell)
				end
				if playerCell.isInterior == true then
					playerPosition = findExteriorLocation(playerCell)
				end

				local companionDistance
				if playerPosition == nil or companionPosition == nil then
					companionDistance = 0
				else
					companionDistance = playerPosition:distance(companionPosition)
				end

				if companionDistance == 0 then
					if lastCastCost > 0 then
						companionCost[i] = math.round(lastCastCost, 0)
						companionChance[i] = math.round(lastCastChance, 0)
						if companionChance[i] > 100 then
							companionChance[i] = 100
						end
					else
						companionCost[i] = 0
						companionChance[i] = 100
					end
				else
					companionCost[i] = calcRecallCost(companionDistance)
					companionCost[i] = math.round(companionCost[i], 0)

					companionChance[i] = calcRecallChance(companionCost[i])
					companionChance[i] = math.round(companionChance[i], 0)
					if companionChance[i] > 100 then
						companionChance[i] = 100
					end
				end
			end

			local companionButton = companionList:createTextSelect{ id = "V1R_MM_CompanionButtons", text = companionName }
			companionButton:register(
				"help",
				function()
					local toolTip = tes3ui.createTooltipMenu()
					local chanceM
					if (tes3.mobilePlayer.magicka.current >= companionCost[i]) then
						chanceM = companionChance[i]
					else	--Shows 0 chance if not enough magicka
						chanceM = 0
					end
					toolTip:createLabel{ text = "Cost: "..companionCost[i].." Chance: "..chanceM }
				end)
			companionButton:register(
				"mouseClick",
				function()
					if (companionObject.objectType == tes3.objectType.npc and disposition < config.dispositionRequired) then
						tes3.messageBox("Компаньон не астолько привязан к вам, чтобы позволить вам телепортировать его.")
					else
						if (tes3.mobilePlayer.magicka.current >= companionCost[i]) then
							if (tes3ui.findMenu(RecallCompanionMenuid) ~= nil) then
								return
							end

							local RecallCompanionMenu = tes3ui.createMenu{ id = RecallCompanionMenuid, fixedFrame = true }
							RecallCompanionMenu.alpha = 1.0
							local RecallCompanionLabel = RecallCompanionMenu:createLabel{ text = "Recall "..companionName.." to your location. Cost: "..companionCost[i].." Chance: "..companionChance[i] }
							RecallCompanionLabel.borderBottom = 5

							local RecallCompanionBlock = RecallCompanionMenu:createBlock{}
							RecallCompanionBlock.width = 300
							RecallCompanionBlock.autoHeight = true
							RecallCompanionBlock.childAlignX = 0.5

							local companionButtonBlock = RecallCompanionBlock:createBlock{}
							companionButtonBlock.widthProportional = 1.0
							companionButtonBlock.autoHeight = true
							companionButtonBlock.childAlignX = 1.0

							local buttonRemove = companionButtonBlock:createButton{ id = "V1R_MM_RecallCompanionRemove", text = "Remove" }
							local buttonCancel = companionButtonBlock:createButton{ id = "V1R_MM_RecallCompanionCancel", text = tes3.findGMST("sCancel").value }
							local buttonOk = companionButtonBlock:createButton{ id = "V1R_MM_RecallCompanionOk", text = tes3.findGMST("sOK").value }

							buttonRemove:register(
								"mouseClick",
								function()
									table.remove(markedCompanions, i)
									if debug then print("Removed "..companionName.."in slot "..i) end
									tes3.messageBox("Удалено "..companionName)
									CancelRecallCompanion()
									CancelRecallLocationSelection()
								end)
							buttonCancel:register("mouseClick", CancelRecallCompanion)
							RecallCompanionBlock:register(
								"keyEnter",
								function()
									RecallCompanion(i, companionCost[i], companionChance[i])
								end)
							buttonOk:register(
								"mouseClick",
								function()
									RecallCompanion(i, companionCost[i], companionChance[i])
								end)

							RecallCompanionMenu:updateLayout()
							tes3ui.enterMenuMode(RecallCompanionMenuid)
						else
							tes3.messageBox("У вас недостаточно магии, чтобы телепортировать этого компаньона к вашему местоположению.")
						end
					end
				end)
		end
	end

	RecallMenu:updateLayout()
	tes3ui.enterMenuMode(RecallMenuid)
end

local function spellCast(e)
	if e.caster ~= tes3.player then return end
	local spell = e.source
	local Recall = false
	local Mark = false
	for i=1, #spell.effects do
		if spell.effects[i].id == tes3.effect.multiRecall then
			Recall = true
			lastCastCost = 18
			if vanillaRecallCost then
				if vanillaRecallCost > 0 then
					lastCastCost = vanillaRecallCost/20
				end
			end
			lastCastChance = e.castChance
		elseif spell.effects[i].id == tes3.effect.multiMark then
			Mark = true
			lastCastCost = 18
			if vanillaMarkCost then
				if vanillaMarkCost > 0 then
					lastCastCost = vanillaMarkCost/20
				end
			end
			lastCastChance = e.castChance
		elseif spell.effects[i].id == tes3.effect.recall then
			if config.limitedRecall then
				local data = tes3.player.data.multiMark
				local day = tes3.worldController.daysPassed.value
				if day == data.lastRecallDay then
					data.RecallsCast = data.RecallsCast + 1
				else
					data.lastRecallDay = day
					data.RecallsCast = 1
				end
			end
		end
	end

	if Recall then
		local chance = e.castChance
		e.castChance = 100
		if tes3.worldController.flagTeleportingDisabled == false then	--Checks if teleportation magic has been disabled
			if config.limitedRecallEnabled == true then
				if getRecallsLeft() <= 0 then	--Limited Recall enabled, out of recalls
				--	tes3.modStatistic({
				--		reference = tes3.player,
				--		name = "magicka",
				--		current = castCost
				--	})
					castFailed()
					tes3.messageBox("Вы слишком устали, чтобы произнести сегодня еще одно заклинание Возврат.")
				elseif config.multiMarkEnabled == true then	--Both enabled, not out of recalls
					local data = tes3.player.data.multiMark
					local day = tes3.worldController.daysPassed.value
					if day == data.lastRecallDay then
						data.RecallsCast = data.RecallsCast + 1
					else
						data.lastRecallDay = day
						data.RecallsCast = 1
					end
				--	tes3.modStatistic({
				--		reference = tes3.player,
				--		name = "magicka",
				--		current = castCost
				--	})
					onCastRecall()
				else	--Only Limited Recall enabled, not out of recalls
					if chance >= math.random(0, 100) then
						local data = tes3.player.data.multiMark
						local day = tes3.worldController.daysPassed.value
						if day == data.lastRecallDay then
							data.RecallsCast = data.RecallsCast + 1
						else
							data.lastRecallDay = day
							data.RecallsCast = 1
						end
						addEffect("vir_mm_recall", tes3.effect.recall)
					else
						castFailed()
						misCast()
					end
				end
			elseif config.multiMarkEnabled == true then	--Only Multi Mark enabled
			--	tes3.modStatistic({
			--		reference = tes3.player,
			--		name = "magicka",
			--		current = castCost
			--	})
				onCastRecall()
			else	--Cast vanilla recall if both are disabled
				if chance >= math.random(0, 100) then
					addEffect("vir_mm_recall", tes3.effect.recall)
				else
					castFailed()
					misCast()
				end
			end
		else
			tes3.messageBox(tes3.findGMST("sTeleportDisabled").value)
			castFailed()
		end
	elseif Mark then
		local chance = e.castChance
		e.castChance = 100
		if config.multiMarkEnabled then
			if chance >= math.random(0, 100) then
			--	tes3.modStatistic({
			--		reference = tes3.player,
			--		name = "magicka",
			--		current = castCost
			--	})
				onCastMark()
			else
			--	e.castChance = 0
				castFailed()
				misCast()
			end
		else
			if chance >= math.random(0, 100) then
				addEffect("vir_mm_mark", tes3.effect.mark)
			else
				castFailed()
				misCast()
			end
		end
	end
end
event.register("spellCast", spellCast)

local function spellCasted(e)
	if e.caster ~= tes3.player then return end
	local spell = e.source
	for i=1, #spell.effects do
		if (spell.effects[i].id == tes3.effect.multiRecall) and (config.multiMarkEnabled == true) then
			e.expGainSchool = tes3.magicSchool.none
		elseif (spell.effects[i].id == tes3.effect.multiMark) and (config.multiMarkEnabled == true) then
			e.expGainSchool = tes3.magicSchool.none
		end
	end
end
event.register("spellCasted", spellCasted)

local intervention
local companions
local function magicCasted(e)	--For alchemy and enchanted items
	if e.caster ~= tes3.player then return end
	local spell = e.source
	local Mark = false
	local Recall = false
	for i=1, #spell.effects do
		if (spell.effects[i].id == tes3.effect.almsiviIntervention) or (spell.effects[i].id == tes3.effect.divineIntervention) then
			companions = {}
			if config.companionIntervention == true then
				intervention = true
				for _, companion in ipairs(tes3.mobilePlayer.friendlyActors) do
					if companion ~= tes3.mobilePlayer then
						if tes3.getCurrentAIPackageId({ reference = companion }) == tes3.aiPackage.follow then
							if isActorInBlacklist(companion) == false then
								local animState = companion.actionData.animationAttackState
								if (companion.health.current > 0 and animState ~= tes3.animationState.dying and animState ~= tes3.animationState.dead) then
									table.insert(companions, companion.reference)
								end
							end
						end
					end
				end
			end
		elseif (spell.effects[i].id == tes3.effect.multiRecall) then
			if (e.sourceInstance.sourceType ~= 1) and (config.enableEnchantedItemAndPotion == true) then
				Recall = true
				lastCastCost = 0
				if e.sourceInstance.source.chargeCost and e.sourceInstance.source.chargeCost <= 1 then
					e.sourceInstance.source.chargeCost = 18
				end
			end
		elseif (spell.effects[i].id == tes3.effect.multiMark) and (config.multiMarkEnabled == true) then
			if (e.sourceInstance.sourceType ~= 1) and (config.enableEnchantedItemAndPotion == true) then
				Mark = true
				lastCastCost = 0
				if e.sourceInstance.source.chargeCost and e.sourceInstance.source.chargeCost <= 1 then
					e.sourceInstance.source.chargeCost = 18
				end
			end
		end
	end
	if Recall then
		if tes3.worldController.flagTeleportingDisabled == false then	--Checks if teleportation magic has been disabled
			if config.limitedRecallEnabled == true then
				if getRecallsLeft() <= 0 then	--Limited Recall enabled, out of recalls
					castFailed()
					tes3.messageBox("Вы слишком устали, чтобы использовать Возврат сегодня.")
				else
					local data = tes3.player.data.multiMark
					local day = tes3.worldController.daysPassed.value
					if day == data.lastRecallDay then
						data.RecallsCast = data.RecallsCast + 1
					else
						data.lastRecallDay = day
						data.RecallsCast = 1
					end

					if config.multiMarkEnabled == true then	--Both enabled, not out of recalls
						onCastRecall()
					else	--Only Limited Recall enabled, not out of recalls
						addEffect("vir_mm_recall", tes3.effect.recall)
					end
				end
			else
				onCastRecall()
			end
		else
			tes3.messageBox(tes3.findGMST("sTeleportDisabled").value)
			castFailed()
		end
	elseif (Mark and config.multiMarkEnabled) then
		onCastMark()
	end
end
event.register("magicCasted", magicCasted)

local function cellChanged()
	timer.delayOneFrame(function()
		if intervention == true then
			local Cell = tes3.getPlayerCell()
			local Position = tes3.player.position:copy()
			for i=1, #companions do
				if companions[i].cell ~= Cell then
					tes3.positionCell({
						reference = companions[i],
						cell = Cell,
						position = Position
					})
				end
			end
			companions = {}
			intervention = false
		end
	end)
end
event.register("cellChanged", cellChanged)

local function updateCost()
		--Replace old Mark and Recall effects with the new ones
--	local objects
--	if config.multiMarkEnabled and config.enableEnchantedItemAndPotion then
--		objects = {tes3.objectType.spell, tes3.objectType.enchantment, tes3.objectType.alchemy}
--	else
--		objects = {tes3.objectType.spell}
--	end
	for object in tes3.iterateObjects({tes3.objectType.spell}) do
		--- @cast object tes3spell
		if (object.effects) then
			for i=1, 8 do
				if (object.effects[i]) then
					if (object.effects[i].id == tes3.effect.mark or object.effects[i].id == tes3.effect.multiMark) then
						object.effects[i].id = tes3.effect.multiMark
						if config.multiMarkEnabled then
							if tes3.player.object.spells:contains(object.id) then
								object.magickaCost = 0
							end
						end
					elseif (object.effects[i].id == tes3.effect.recall or object.effects[i].id == tes3.effect.multiRecall) then
						object.effects[i].id = tes3.effect.multiRecall
						if config.multiMarkEnabled then
							if tes3.player.object.spells:contains(object.id) then
								object.magickaCost = 0
							end
						end
					end
				end
			end
		end
	end
	for object in tes3.iterateObjects({tes3.objectType.enchantment, tes3.objectType.alchemy}) do
		--- @cast object tes3alchemy|tes3enchantment
		if (object.effects) then
			for i=1, 8 do
				if (object.effects[i]) then
					if (object.effects[i].id == tes3.effect.mark or object.effects[i].id == tes3.effect.multiMark) then
						if config.multiMarkEnabled and config.enableEnchantedItemAndPotion then
							object.effects[i].id = tes3.effect.multiMark
						else
							object.effects[i].id = tes3.effect.mark
						end
					elseif (object.effects[i].id == tes3.effect.recall or object.effects[i].id == tes3.effect.multiRecall) then
						if (config.multiMarkEnabled or config.limitedRecallEnabled) and config.enableEnchantedItemAndPotion then
							object.effects[i].id = tes3.effect.multiRecall
						else
							object.effects[i].id = tes3.effect.recall
						end
					end
				end
			end
		end
	end
end

local function delayUpdate()
	timer.delayOneFrame(function()
		updateCost()
	end)
end
event.register("uiActivated", delayUpdate, { filter = "MenuServiceSpells" })

local function loaded()
	tes3.player.data.multiMark = tes3.player.data.multiMark or {}
	local data = tes3.player.data.multiMark

	data.MarkSlots = data.MarkSlots or {}
	data.MarksUsed = nil

	data.RecallsCast = data.RecallsCast or 0
	data.lastRecallDay = data.lastRecallDay or 1

	data.markedCompanions = data.markedCompanions or {}

	updateCost()
end
event.register("loaded", loaded)

---------------------------------------------------------------------
-----------MCM-------------------------------------------------------
---------------------------------------------------------------------

local function registerModConfig()
	local EasyMCM = require("easyMCM.EasyMCM")
	local template = EasyMCM.createTemplate("Multi Mark & Harder Recall")
	template:saveOnClose("multi_mark", config)

	local page = template:createSideBarPage{
		sidebarComponents = {
			EasyMCM.createInfo{ text = "Этот мод позволяет создать несколько пометок и установить ограничение на количество возвратов в день. Вы можете настроить все параметры и включить нужные опции на этой странице." },
			EasyMCM.createHyperlink{
				text = "Поэкспериментируйте с различными значениями настроек мода.",
				url = "https://www.desmos.com/calculator/zbdybousfl"
			}
		}
	}

	local enableCategory = page:createCategory("Основные настройки мода")

	enableCategory:createOnOffButton{
		label = "Включить Multimark",
		description = "Включение или отключение возможности использовать несколько пометок. По умолчанию: Вкл",
		restartRequired = true,
		variable = EasyMCM.createTableVariable{
			id = "multiMarkEnabled",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Включить ограничение возврата",
		description = "Включить или отключить ограничение возврата. По умолчанию: Вкл",
		restartRequired = true,
		variable = EasyMCM.createTableVariable{
			id = "limitedRecallEnabled",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Включить Усложненный возврат",
		description = "Если эта опция включена, Возврат будет затрачивать больше магии и будет иметь меньшие шансы на успех в зависимости от расстояния до пометки, текущего значения навыка мистицизма и вашего текущего процента запаса сил. Требуется включить Multimark. По умолчанию: Выкл",
		variable = EasyMCM.createTableVariable{
			id = "increasedMagickaCostForDistanceTraveled",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Включить Miscast",
		description = "ТРЕБУЕТСЯ МОД MISCAST ENHANCED. Если эта опция включена, есть вероятность, что вы будете телепортированы в случайное место, если заклинания Пометка или Возврат не сработают. Неудача в телепортации компаньона в ваше текущее местоположение не приведет к ошибочной телепортации. По умолчанию: Выкл",
		restartRequired = true,
		variable = EasyMCM.createTableVariable{
			id = "enableMisCast",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Включить телепортацию компаньонов при касте Вмешательства",
		description = "Компаньоны будут телепортироваться к вам при произнесении заклинаний Вмешательство Альмсиви и Божественное вмешательство, если при произношении заклинания они находятся в той же ячейке, что и вы. Также это работает со свитками, зачарованными предметами и зельями. По умолчанию: Выкл",
		variable = EasyMCM.createTableVariable{
			id = "companionIntervention",
			table = config
		}
	}

	local markCategory = page:createCategory("Настройка значений параметров Multimark.")

	markCategory:createSlider{
		label = "Максимальное количество пометок",
		description = "Увеличить или уменьшить максимальное количество пометок. По умолчанию: 16",
		max = 80,
		min = 2,
		step = 1,
		jump = 4,
		variable = EasyMCM.createTableVariable{
			id = "maxNumberOfMarks",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Включить multimark для зачарованных предметов, свитков и зелий.",
		description = "Если эта опция отключена, зелья, свитки и зачарованные предметы будут использовать механику работы Пометки и Возврата по умолчанию. По умолчанию: Вкл",
		restartRequired = true,
		variable = EasyMCM.createTableVariable{
			id = "enableEnchantedItemAndPotion",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Мистицизм влияет на количество доступных пометок",
		description = "Если эта опция включена, ваше значение навыка мистицизм повлияет на количество  пометок, котрые вы можете поставить. В противном случае вы всегда можете поставить максимальное количество пометок. По умолчанию: Вкл",
		variable = EasyMCM.createTableVariable{
			id = "mysticismAffectsMaxMarks",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Использовать текущий мистицизм для рассчета количества пометок",
		description = "Если эта опция включена, ваш текущий мистицизм будет использоваться вместо вашего базового мистицизма для вычисления количества доступных пометок. Требуется, чтобы была включена опция 'Мистицизм влияет на количество доступных пометок'. По умолчанию: Выкл",
		variable = EasyMCM.createTableVariable{
			id = "useCurrentMysticism",
			table = config
		}
	}

	markCategory:createSlider{
		label = "Мистицизм, необходимый для максимального количества пометок",
		description = "Здесь можно измените значение навыка мистицизма, необходимого для использования максимального количества пометок. Требуется, чтобы была включена опция 'Мистицизм влияет на количество доступных пометок'. По умолчанию: 100",
		max = 300,
		min = 40,
		step = 5,
		jump = 20,
		variable = EasyMCM.createTableVariable{
			id = "mysticismRequiredForMaxMarks",
			table = config
		}
	}

	--markCategory:createSlider{
	--	label = "Exponent multiplier",
	--	description = "Setting this to 1 will give you half of your max marks at half of the required mysticism for max marks. A number higher than one will give you less marks at lower mysticism, while giving more at a mysticism value close to your required mysticism for max marks. A lower number will do the opposite, giving you more marks at a lower mysticism value, and less at a mysticism value close to your requred mysticism for max marks. If you change this, please test different values in the desmos graph linked in the sidebar.",
	--	max = 5,
	--	min = 0.01,
	--	step = 0.01,
	--	jump = 0.5,
	--	variable = EasyMCM.createTableVariable{
	--		id = "expMult",
	--		table = config
	--	}
	--}

	markCategory:createTextField{
		label = "Множитель экспоненты",
		description = "Установка этого значения в 1 даст вам возможность использовать половину от максимума пометок при значении мистицизма, равным половине требуемого для максимума пометок. Число, большее единицы, даст вам меньше пометок при более низком мистицизме, в то время как при значении мистицизма, близком к требуемому вам мистицизму для максимума пометок, вы получите возможность использовать больше пометок. Меньшее число приведет к обратному результату, давая вам больше пометок при более низком значении мистицизма и меньше пометок при значении мистицизма, близком к требуемому для их максимума. По умолчанию: 2",
		numbersOnly = true,
		variable = EasyMCM.createTableVariable{
			id = "expMult",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Сортировать список пометок",
		description = "Если этот параметр включен, список пометок в меню Пометка и Возврат будет отсортирован в алфавитном порядке. Обратите внимание, что возврат к предыдущему порядку невозможен. По умолчанию: выкл",
		variable = EasyMCM.createTableVariable {
			id = "sortMarkList",
			table = config,
		},
	}

	local companionCategory = page:createCategory("Настройка параметров, связанных с компаньонами.")

	companionCategory:createOnOffButton{
		label = "Телепортировать компаньонов при использовании Возврата",
		description = "Если эта опция включена, ваши компаньоны будут телепортироваться вместе с вами при использовании заклинания Возврат. По умолчанию: Вкл",
		variable = EasyMCM.createTableVariable{
			id = "teleportCompanions",
			table = config
		}
	}

	companionCategory:createSlider{
		label = "Расстояние, необходимое для призыва компаньона к персонажу игрока",
		description = "Изменить расстояние, необходимое для возможности использования телепортации компаньона к персонажу игрока. По умолчанию: 90",
		max = 100,
		min = -100,
		step = 5,
		jump = 10,
		variable = EasyMCM.createTableVariable{
			id = "dispositionRequired",
			table = config
		}
	}

	local harderRecallCategory = page:createCategory("Настройка параметров Усложненного возврата.")

	harderRecallCategory:createSlider{
		label = "Стоимость Возврата между несвязанными областями",
		description = "Количество магии, необходимое для использования заклинания Возврат для пометок, находящихся в таких районах, как Морнхолд и Вварденфелл, которые не связаны между собой. Требуется чтобы была включена опция 'Усложненный возврат'. По умолчанию: 300",
		max = 1000,
		min = 0,
		step = 1,
		jump = 100,
		variable = EasyMCM.createTableVariable{
			id = "costBetweenUnlinkedAreas",
			table = config
		}
	}

	harderRecallCategory:createTextField{
		label = "Множитель увеличения стоимости возврата",
		description = "Более высокие значения этого параметра увеличивают количество магии для использования заклинания Возврат на больших расстояниях. Требуется чтобы была включена опция 'Усложненный возврат'. По умолчанию: 1.0",
		numbersOnly = true,
		variable = EasyMCM.createTableVariable{
			id = "iMCFDTcostMultiplier",
			table = config
		}
	}

	harderRecallCategory:createTextField{
		label = "Множитель шанса усложнения возврата",
		description = "Более высокие значения этого параметра увеличивают вероятность необходимости повторного каста Возврата. Установите 0 для отключения этой опции. Требуется чтобы была включена опция 'Усложненный возврат'. По умолчанию: 1.0",
		numbersOnly = true,
		variable = EasyMCM.createTableVariable{
			id = "iMCFDTrecallChanceMultiplier",
			table = config
		}
	}

	local limitedRecallCategory = page:createCategory("Настройка ограничений Возврата.")

	limitedRecallCategory:createSlider{
		label = "Возвратов в день",
		description = "Ограничить количество использований заклинания Возврат, которые вы можете выполнить за день, если включена опция 'Включить ограничение возврата'. По умолчанию: 2",
		max = 10,
		min = 1,
		step = 1,
		jump = 1,
		variable = EasyMCM.createTableVariable{
			id = "limitedRecall",
			table = config
		}
	}
	EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)

local function initialized()
	print("[MultiMark] Initialized")

	MarkMenuid = tes3ui.registerID("V1R_MM:MarkMenu")
	RecallMenuid = tes3ui.registerID("V1R_MM:RecallMenu")
	NewMarkButtonid = tes3ui.registerID("V1R_MM:NewMarkButton")

	NewMarkMenuid = tes3ui.registerID("V1R_MM:NewMarkMenu")
	NewMarkNameid = tes3ui.registerID("V1R_MM:NewMarkName")
	NewMarkDeleteButtonid = tes3ui.registerID("V1R_MM:NewMarkDeleteButton")
	NewMarkCancelButtonid = tes3ui.registerID("V1R_MM:NewMarkCancelButton")
	NewMarkOkButtonid = tes3ui.registerID("V1R_MM:NewMarkOkButton")

	RecallToMenuid = tes3ui.registerID("V1R_MM:RecallToMenu")

	CancelMarkid = tes3ui.registerID("V1R_MM:CancelMark")
	CancelRecallid = tes3ui.registerID("V1R_MM:CancelRecall")

	RecallCompanionMenuid = tes3ui.registerID("V1R_MM:RecallCompanionMenu")
end

event.register("initialized", initialized)

local RightClickMenuExit = include("mer.RightClickMenuExit")
if RightClickMenuExit and RightClickMenuExit.registerMenu then
	print("[MultiMark] Registering Right Click Menu Exit for Mark and Recall menus")
    RightClickMenuExit.registerMenu({
        menuId = "V1R_MM:MarkMenu",
        buttonId = "V1R_MM:CancelMark"
    })
    RightClickMenuExit.registerMenu({
        menuId = "V1R_MM:NewMarkMenu",
        buttonId = "V1R_MM:NewMarkCancelButton"
    })
    RightClickMenuExit.registerMenu({
        menuId = "V1R_MM:RecallMenu",
        buttonId = "V1R_MM:CancelRecall"
    })
    RightClickMenuExit.registerMenu({
        menuId = "V1R_MM:RecallToMenu",
        buttonId = "V1R_MM_RecallToCancel"
    })
    RightClickMenuExit.registerMenu({
        menuId = "V1R_MM:RecallCompanionMenu",
        buttonId = "V1R_MM_RecallCompanionCancel"
    })
end
