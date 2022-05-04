local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
-- Check Magicka Expanded framework.
if (framework == nil) then
	local function warning()
		tes3.messageBox(
			"[MultiMark ERROR] Magicka Expanded framework is not installed!"
			.. " You will need to install it to use this mod."
		)
	end
	event.register("initialized", warning)
	event.register("loaded", warning)
	return
end

tes3.claimSpellEffectId("multiMark", 701)
tes3.claimSpellEffectId("multiRecall", 702)

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
local Marked
local Recalled

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
					"[MultiMark ERROR] Miscast Enhanced is not installed!"
					.. " You will need to install it to use the Miscast feature."
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
	local mark = tes3.getMagicEffect(tes3.effect.mark)
	local recall = tes3.getMagicEffect(tes3.effect.recall)

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
		name = "Mark",
		description = "This effect allows the subject to establish target locations for the Recall spell. The location is established directly at the position of the caster when the spell is cast. The caster can also create links between creatures and friendly humanoids, allowing the caster to recall them to their location by using the Recall spell.",

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
		name = "Recall",
		description = "The subject of this spell can instantaneously teleport to a recall marker set by the Mark spell effect. The subject can also Recall companions that have been linked with the Mark spell to their current location.",

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
				functions.gatedMessageBox("Your failed attempt to cast the spell triggered a miscast.")
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

local function addEffect(id, effect)
	local potion = tes3.getObject(id) or tes3alchemy.create{
		id = id,
		effects = {{
			id = effect,
			duration = 1
		}}
	}

	mwscript.addItem({
		reference = tes3.mobilePlayer,
		item = potion
	})
	mwscript.equip({
		reference = tes3.mobilePlayer,
		item = potion
	})
	timer.delayOneFrame(function()
		tes3.removeSound{
			reference = tes3.player,
			sound = "Drink"
		}
	end)
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

local function findExteriorLocation(cell)
	local linkedInteriors = {}
	local cellsChecked = {}
		--Checks current cell for doors leading to exteriors
	for door in tes3.iterate(cell.activators) do
		local doorObject = door.object
		if doorObject then
			if doorObject.objectType == tes3.objectType.door then
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
	end
	table.insert(cellsChecked, cell.name)
			--If no exteriors were found from the doors in the current cell, check the interiors found
	while #linkedInteriors > 0 do		--Repeat until all interiors have been checked
		local interiorCell = linkedInteriors[1]
		for door in tes3.iterate(interiorCell.activators) do
			local doorObject = door.object
			if doorObject then
				if doorObject.objectType == tes3.objectType.door then
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
			end
		end
			--Removes the checked interior from the list
		table.remove(linkedInteriors, 1)
	end
	return nil
end

local function linkedInternalLocations(cell, target)
	local linkedInteriors = {}
	local cellsChecked = {}
	table.insert(linkedInteriors, cell)
	table.insert(cellsChecked, cell.name)
			--If no exteriors were found from the doors in the current cell, check the interiors found
	while #linkedInteriors > 0 do		--Repeat until all interiors have been checked
		local interiorCell = linkedInteriors[1]
		if interiorCell.id == target then
			return true
		end
		for door in tes3.iterate(interiorCell.activators) do
			local doorObject = door.object
			if doorObject then
				if doorObject.objectType == tes3.objectType.door then
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
		Marked = false
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
		Recalled = "false"
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

	tes3.messageBox("Deleted Mark "..tes3.player.data.multiMark.MarkSlots[id].Name)
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
		markMenu:destroy()

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
			tes3.messageBox("Replaced previous mark with "..MarkName)
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
			tes3.messageBox("Created mark "..MarkName)
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
		Marked = true
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
			NewMarkLabel = NewMarkMenu:createLabel{ text = 'Replace mark '..tes3.player.data.multiMark.MarkSlots[MarkNumber].Name..' with:' }
		else					--Creating New Mark
			NewMarkLabel = NewMarkMenu:createLabel{ text = 'Create a new mark' }
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

		if playerMysticism >= MystForMaxMarks then
			MarksTotal = maxMarks
		else
			MarksTotal = ((playerMysticism / MystForMaxMarks * 100) ^ expMult) / ((100 ^ expMult) / maxMarks)
		end
	else
		MarksTotal = config.maxNumberOfMarks
	end

	MarksTotal = math.floor(MarksTotal)
	if MarksTotal < 1 then	--Min 1 Mark
		MarksTotal = 1
	end

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
	local MarkLabel = markBlock:createLabel{ text = 'You have '..MarksLeft..'/'..MarksTotal..' Marks left. Where do you want to mark your current location?' }
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

	local companionLabel = companionBlock:createLabel{ text = 'Add companions to Recall them to you later.' }
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
		NewMarkButton = buttonBlock:createButton{ id = NewMarkButtonid, text = 'Create a new Mark' }
		NewMarkButton:register(
			"mouseClick",
			function ()
				NewMarkName(0)
			end
		)
	end
--Used Mark Slots
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
	for companion in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		local companionName = companion.reference.object.name
		if debug then print("Found Friendly Actor: "..companionName) end
		if companion ~= tes3.mobilePlayer then
			if tes3.getCurrentAIPackageId(companion) == tes3.aiPackage.follow then
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
										tes3.messageBox("The companion doesn't like you enough to let you teleport them.")
									else
										table.insert(markedCompanions, companionid)
										tes3.messageBox("Added "..companionName)
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
			recallMenu:destroy()
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
			end)
			Recalled = "true"
		else
				--Failed recall
			tes3.messageBox("You failed recalling "..companionName)
			tes3.modStatistic({
				reference = tes3.player,
				name = "magicka",
				current = -cost
			})
			castFailed()
			recallMenu:destroy()
			Recalled = "failed"
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
			recallMenu:destroy()
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
			Recalled = "true"
		else
				--Failed recall
			tes3.messageBox("You failed recalling to "..MarkName)
			tes3.modStatistic({
				reference = tes3.player,
				name = "magicka",
				current = -cost
			})
			castFailed()
			recallMenu:destroy()
			Recalled = "failed"
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
		local RecallToLabel = RecallToMenu:createLabel{ text = "Recall to "..tes3.player.data.multiMark.MarkSlots[Markid].Name..". Cost: "..math.round(cost, 0).." Chance: "..math.round(chance, 0) }
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
		tes3.messageBox("You do not have enough magicka to recall there.")
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
	local RecallLabel = recallBlock:createLabel{ text = 'You have '..MarksUsed..' Marks placed. Where do you want to recall?' }
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

	local companionLabel = companionBlock:createLabel{ text = 'Recall companions to your location.' }
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
				toolTip:createLabel{ text = "Cost: "..cost[i].." Chance: "..chanceM }
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
						tes3.messageBox("The companion doesn't like you enough to let you teleport them.")
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
									tes3.messageBox("Removed "..companionName)
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
							tes3.messageBox("You do not have enough magicka to recall that companion to your location.")
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
					tes3.messageBox("You are too tired to cast another recall spell today.")
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

local function recallDone(e)
	timer.delayOneFrame(function()
		while tes3.menuMode == true do
		end
		timer.delayOneFrame(function()
			if ( Recalled == "false" ) or ( Recalled == "failed" ) then
				tes3.removeSound{
					reference = tes3.player,
					sound = "mysticism hit"
				}
			end
		--	timer.delayOneFrame(function()
		--		if Recalled == "false" then
		--			local itemData = e.sourceInstance.itemData
		--			if itemData then
		--				if itemData.charge then
		--					itemData.charge = itemData.charge + e.sourceInstance.source.chargeCost
		--				end
		--			end
		--		end
		--	end)
		end)
	end)
end

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
				for companion in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
					if companion ~= tes3.mobilePlayer then
						if tes3.getCurrentAIPackageId(companion) == tes3.aiPackage.follow then
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
		elseif (spell.effects[i].id == tes3.effect.multiRecall) and (config.multiMarkEnabled == true) then
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
			onCastRecall()
			recallDone(e)
		else
			tes3.messageBox(tes3.findGMST("sTeleportDisabled").value)
			Recalled = "false"
			castFailed()
			recallDone(e)
		end
	elseif (Mark and config.multiMarkEnabled) then
		onCastMark()
		timer.delayOneFrame(function()
			while tes3.menuMode == true do
			end
			timer.delayOneFrame(function()
				if Marked == false then
					tes3.removeSound{
						reference = tes3.player,
						sound = "mysticism hit"
					}
				--	local itemData = e.sourceInstance.itemData
				--	if itemData then
				--		if itemData.charge then
				--			itemData.charge = itemData.charge + e.sourceInstance.source.chargeCost
				--		end
				--	end
				end
			end)
		end)
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
						if config.multiMarkEnabled and config.enableEnchantedItemAndPotion then
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
			EasyMCM.createInfo{ text = "This mod allows marking multiple locations and limiting daily recalls. You can customize all numbers and toggle features on this page." },
			EasyMCM.createHyperLink{
				text = "Experiment with different values here.",
				exec = "start https://www.desmos.com/calculator/zbdybousfl"
			}
		}
	}

	local enableCategory = page:createCategory("Toggle mod functions")

	enableCategory:createOnOffButton{
		label = "Enable Multimark",
		description = "Enable or disable multiple marks. Default: On",
		restartRequired = true,
		variable = EasyMCM:createTableVariable{
			id = "multiMarkEnabled",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Enable Limited Recall",
		description = "Enable or disable limited recall. Default: On",
		variable = EasyMCM:createTableVariable{
			id = "limitedRecallEnabled",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Enable Harder Recall",
		description = "If enabled, recalling will cost more magicka and have lower chance of success based on distance to mark, current mysticism and your current fatigue percent. Requires multi mark enabled. Default: Off",
		variable = EasyMCM:createTableVariable{
			id = "increasedMagickaCostForDistanceTraveled",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Enable Miscast",
		description = "REQUIRES MISCAST ENHANCED If enabled there is a chance that you will be teleported to a random location when failing to create mark or failing to recall. Failing to teleport a companion to your location won't have a chance of Miscast. Default: Off",
		restartRequired = true,
		variable = EasyMCM:createTableVariable{
			id = "enableMisCast",
			table = config
		}
	}

	enableCategory:createOnOffButton{
		label = "Enable companion teleportation when casting intervention",
		description = "Companions will teleport to you when casting Almsivi or Divine Intervention, if they are in the same cell as you when casting the spell. Also works with scrolls, enchanted items and potions. Default: Off",
		variable = EasyMCM:createTableVariable{
			id = "companionIntervention",
			table = config
		}
	}

	local markCategory = page:createCategory("Customize Multimark values.")

	markCategory:createSlider{
		label = "Maximum number of marks",
		description = "Increase or decrease the maximum number of marks. Default: 16",
		max = 80,
		min = 2,
		step = 1,
		jump = 4,
		variable = EasyMCM:createTableVariable{
			id = "maxNumberOfMarks",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Enable multimark for enchanted items, scrolls and potions.",
		description = "If disabled, potions, scrolls and enchanted items will use default mark and recall function. Default: On",
		restartRequired = true,
		variable = EasyMCM:createTableVariable{
			id = "enableEnchantedItemAndPotion",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Mysticism affects number of marks available",
		description = "If enabled, your mysticism will affect how many marks you have. Otherwise you will always have the maximum number of marks. Default: On",
		variable = EasyMCM:createTableVariable{
			id = "mysticismAffectsMaxMarks",
			table = config
		}
	}

	markCategory:createOnOffButton{
		label = "Use current mysticism to calculate number of marks",
		description = "If enabled, your current mysticism will be used for calculating number of marks available instead of your base mysticism. Requires that 'Mysticism affects number of marks available' has been enabled. Default: Off",
		variable = EasyMCM:createTableVariable{
			id = "useCurrentMysticism",
			table = config
		}
	}

	markCategory:createSlider{
		label = "Mysticism required for maximum number of marks",
		description = "Change the mysticism required to have the maximum number of marks. Requires that 'Mysticism affects number of marks available' has been enabled. Default: 100",
		max = 300,
		min = 40,
		step = 5,
		jump = 20,
		variable = EasyMCM:createTableVariable{
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
	--	variable = EasyMCM:createTableVariable{
	--		id = "expMult",
	--		table = config
	--	}
	--}

	markCategory:createTextField{
		label = "Exponent multiplier",
		description = "Setting this to 1 will give you half of your max marks at half of the required mysticism for max marks. A number higher than one will give you less marks at lower mysticism, while giving more at a mysticism value close to your required mysticism for max marks. A lower number will do the opposite, giving you more marks at a lower mysticism value, and less at a mysticism value close to your requred mysticism for max marks. If you change this, please test different values in the desmos graph linked in the sidebar. Default: 2",
		numbersOnly = true,
		variable = EasyMCM:createTableVariable{
			id = "expMult",
			table = config
		}
	}

	local companionCategory = page:createCategory("Customize companion related settings.")

	companionCategory:createOnOffButton{
		label = "Teleport companions when recalling",
		description = "If enabled, your companions will teleport with you when recalling. Default: On",
		variable = EasyMCM:createTableVariable{
			id = "teleportCompanions",
			table = config
		}
	}

	companionCategory:createSlider{
		label = "Disposition required to recall a companion to your location",
		description = "Change the disposition required to recall a companion to your location. Default: 90",
		max = 100,
		min = 0,
		step = 5,
		jump = 10,
		variable = EasyMCM:createTableVariable{
			id = "dispositionRequired",
			table = config
		}
	}

	local harderRecallCategory = page:createCategory("Customize Harder Recall values.")

	harderRecallCategory:createSlider{
		label = "Cost for Recalling between unlinked areas",
		description = "Cost when Recalling between areas like Mournhold and Vvardenfell that aren't linked. Requires that 'Harder recall' has been enabled. Default: 300",
		max = 1000,
		min = 0,
		step = 1,
		jump = 100,
		variable = EasyMCM:createTableVariable{
			id = "costBetweenUnlinkedAreas",
			table = config
		}
	}

	harderRecallCategory:createTextField{
		label = "Harder recall Cost multiplier",
		description = "Higher values increase the magicka cost for recalling long distances. Requires that 'Harder recall' has been enabled. Default: 1.0",
		numbersOnly = true,
		variable = EasyMCM:createTableVariable{
			id = "iMCFDTcostMultiplier",
			table = config
		}
	}

	harderRecallCategory:createTextField{
		label = "Harder recall Chance Multiplier",
		description = "Higher values increase your recall cast chance. Set to 0 to disable. Requires that 'Harder recall' has been enabled. Default: 1.0",
		numbersOnly = true,
		variable = EasyMCM:createTableVariable{
			id = "iMCFDTrecallChanceMultiplier",
			table = config
		}
	}

	local limitedRecallCategory = page:createCategory("Customize Limited Recall values.")

	limitedRecallCategory:createSlider{
		label = "Recalls per day",
		description = "Limits the number of recalls you can cast in a day if Limited Recall has been enabled. Default: 2",
		max = 10,
		min = 1,
		step = 1,
		jump = 1,
		variable = EasyMCM:createTableVariable{
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