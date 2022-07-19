local magic = require("NecroCraft.magic")
local soulGemLib = require("NecroCraft.soulgem")
local skillModule = require("OtherSkills.skillModule")
local strings = require("NecroCraft.strings")
local utility = require("NecroCraft.utility")

local quests = {}

local function hasSoul(reference, soul)
	for _, stack in pairs(reference.object.inventory) do
		if stack.object.isSoulGem and stack.variables then
			local itemData = stack.variables[1]
			if itemData and itemData.soul == soul then
				return true
			end
		end
	end
	return false
end

local tooltipMenu

local function isNight()
    local hour =  tes3.worldController.hour.value
    if hour < 4 or hour > 22 then return true end
    return false
end

local function isTelescope(rayHit)
	if not rayHit then return false end
	local telescopeMesh = rayHit.reference and rayHit.reference.baseObject and rayHit.reference.baseObject.id:lower() == "in_dwrv_scope00"
	local orientation = rayHit.reference  and rayHit.reference.orientation and rayHit.reference.orientation.x == 0 and rayHit.reference.orientation.y == 0
	return telescopeMesh and tes3.getPlayerCell().id ~= "Dagon Fel, Sorkvild's Tower" and orientation
end

local function findTelescope(e)
    local rayHit = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
		ignore = { tes3.player },
        maxDistance = tes3.getPlayerActivationDistance(),
    }

	if isTelescope(rayHit) then
		local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
		tooltipMenu = MenuMulti:findChild(tes3ui.registerID("NC:telescopeTooltip"))
		if tooltipMenu then return end
		tooltipMenu = MenuMulti:createBlock{ id = tes3ui.registerID("NC:telescopeTooltip") }
		tooltipMenu.visible = true
		tooltipMenu:destroyChildren()
		tooltipMenu.absolutePosAlignX = 0.5
		tooltipMenu.absolutePosAlignY = 0.03
		tooltipMenu.autoHeight = true
		tooltipMenu.autoWidth = true
		local labelBackground = tooltipMenu:createRect({color = {0, 0, 0}})
		labelBackground.autoHeight = true
		labelBackground.autoWidth = true
		local labelBorder = labelBackground:createThinBorder()
		labelBorder.autoHeight = true
		labelBorder.autoWidth = true
		labelBorder.childAlignX = 0.5
		labelBorder.paddingAllSides = 10
		labelBorder.flowDirection = "top_to_bottom"
		local headerBlock = labelBorder:createBlock()
		headerBlock.autoHeight = true
		headerBlock.autoWidth = true
		headerBlock.flowDirection = "left_to_right"
		headerBlock.childAlignY = 0.5
		local header = headerBlock:createLabel{ text = strings.telescope }
		header.autoHeight = true
		header.autoWidth = true
		header.color = tes3ui.getPalette("header_color")
		event.register("mouseButtonUp", quests.onActivateButton)
		event.register("keyDown", quests.onActivateKey)
	elseif tooltipMenu then
		event.unregister("mouseButtonUp", quests.onActivateButton)
		event.unregister("keyDown", quests.onActivateKey)
		tooltipMenu:destroy()
		tooltipMenu = nil
	end
end

local function onTelescopeUse()
	if not tes3.canRest({checkForSolidGround = false}) then
		tes3.messageBox(strings.telescopeEnemy)
		timer.start{
			duration = 0.1,
			callback = function ()
				tooltipMenu.visible = true
			end
		}
        return
	end
    local timestamp = tes3.getSimulationTimestamp()
    if timestamp < tes3.player.data.necroCraft.telescopeTimestamp + 12 then
        tes3.messageBox(strings.telescopeAgain)
		timer.start{
			duration = 0.1,
			callback = function ()
				tooltipMenu.visible = true
			end
		}
		return
	end
	if not isNight() then
        tes3.messageBox(strings.telescopeDay)
		timer.start{
			duration = 0.1,
			callback = function ()
				tooltipMenu.visible = true
			end
		}
        return
    end
	tes3.player.data.necroCraft.telescopeTimestamp = timestamp
    tes3.setPlayerControlState({enabled = false})
    tes3.fadeOut()
    timer.start{
        type = timer.real, 
        duration = 1,
        callback = function() 
            tes3.advanceTime{ hours = 3 }
            tes3.fadeIn()
            tes3.setPlayerControlState({enabled = true})
            if utility.isShade() then
                tes3.updateJournal{id = "NC_HelpBelvayn", index = 50, showMessage = true}
				event.unregister("simulate", findTelescope)
				event.unregister("mouseButtonUp", quests.onActivateButton)
				event.unregister("keyDown", quests.onActivateKey)
				tooltipMenu:destroy()
				tooltipMenu = nil
				tes3.player.data.necroCraft.telescopeTimestamp = nil
			else
				tooltipMenu.visible = true
				tes3.updateJournal{id = "NC_HelpBelvayn", index = 20, showMessage = true}
            end
        end
    }
end

quests.onActivateKey = function(e)
	if not tes3.mobilePlayer then return end
    if tes3ui.menuMode() then
        return
    end
    if (e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 0) then
        tooltipMenu.visible = false
		onTelescopeUse()
    end
end

quests.onActivateButton = function(e)
    if tes3ui.menuMode() then
        return
    end
    if (e.button == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 1) then
        tooltipMenu.visible = false
		onTelescopeUse()
    end
end

local WHMages = {
	["procyon nigilius"] = {-745,350,-94},
	skinkintreesshade = {-70,255,-94},
	tusamircil = {-240,-95,-94},
	["arielle phiencel"] = {-825,110,-94},
	["dabienne mornardl"] = {315,445,-94}
}

local function startMagesVsSkeletonsCombat(cell)
	for creature in cell:iterateReferences(tes3.objectType.creature) do
		if creature.baseObject.id:lower() == "nc_skeleton_prank" then
			for mageID, position in pairs(WHMages) do
				mage = tes3.getReference(mageID)
				--creature.mobile:startCombat(mage)
				mage.mobile:startCombat(creature.mobile)
			end
		end
	end
end

local function killSkeletons(cell)
	for creature in cell:iterateReferences(tes3.objectType.creature) do
		if creature.baseObject.id:lower() == "nc_skeleton_prank" then
			creature.mobile:kill()
		end
	end
end

local function moveMagesBack()
	for mageID, position in pairs(WHMages) do
		local mage = tes3.getReference(mageID)
		if mage and not mage.isDead  then
			local position = mage.data.necroCraft.position
			tes3.positionCell{reference = mage.id, position = position, cell = "Sadrith Mora, Wolverine Hall: Mage's Guild"}
			mage.data.necroCraft = nil
		end
	end
	local mage = tes3.getReference("uleni heleran")
	if mage and not mage.isDead  then
		tes3.positionCell{reference = mage.id, position = {381, 902, 66}, cell = "Sadrith Mora, Wolverine Hall: Mage's Guild"}
	end
end



local function moveMagesToImperialCult()
	for mageID, position in pairs(WHMages) do
		local mage = tes3.getReference(mageID)
		if mage and not mage.isDead  then
			mage.data.necroCraft = {}
			mage.data.necroCraft.position = {mage.position.x, mage.position.y, mage.position.z}
			tes3.positionCell{reference = mage.id, position = position, cell = "Sadrith Mora, Wolverine Hall: Imperial Shrine"}
		end
	end
end

local function onCellChanged(e)
	if tes3.player.data.necroCraft.questStage == nil then
		moveMagesToImperialCult()
		tes3.player.data.necroCraft.questStage = 1
	elseif tes3.player.data.necroCraft.questStage == 1 then
		if e.cell.id == "Sadrith Mora, Wolverine Hall: Imperial Shrine" then
			startMagesVsSkeletonsCombat(e.cell)
			tes3.player.data.necroCraft.questStage = 2
		end
	elseif tes3.player.data.necroCraft.questStage == 2 then
		if tes3.getJournalIndex{id="NC_HelpUlverC"} == 100 then 
			if e.cell.id == "Sadrith Mora, Wolverine Hall: Imperial Shrine" then
					killSkeletons(e.cell)
			elseif e.previousCell.id == "Sadrith Mora, Wolverine Hall: Imperial Shrine" then
				killSkeletons(e.previousCell)
				moveMagesBack()
				tes3.player.data.necroCraft.questStage = -1
				event.unregister("cellChanged", onCellChanged)
			end
		end
	end
end

local function onOthrilResist(e)
	if e.target.object.baseObject.id ~= "vedelea othril" or e.source.id ~= "nc_sc_faramexperiment_en" then
		return
	end
	e.resistedPercent = 0
	mwscript.stopCombat{reference = e.target}
	tes3.updateJournal{id = "NC_HelpFaram", index = 20, showMessage = true}
	event.unregister("spellResist", onOthrilResist)
end

local function onMenuRestWait(e)
	local menu = e.element
	local parent = menu:findChild("PartNonDragMenu_main")
	local daysToShade = (8 - tes3.worldController.daysPassed.value%8)%8
	local text
	local color
	if daysToShade == 0 then
		text = strings.shadeTonight
		color = tes3ui.getPalette("big_link_color")
	else
		color = {0.4+0.0037*(tes3.worldController.daysPassed.value%8), 0.4+0.0089*(tes3.worldController.daysPassed.value%8), 0.4+0.0392*(tes3.worldController.daysPassed.value%8)}
		if daysToShade == 1 then
			text = strings.shadeTomorrow
		else
			text=string.format(strings.shadeInDays, daysToShade)
		end
	end
	local shadeLabel = parent:createLabel({text=text})
	shadeLabel.color = color
	parent:reorderChildren(1, -1, 1)
	menu:updateLayout()
end



quests.journal = function(e)
	if e.topic.id == "NC_HelpFaram" and e.index == 10 then
		event.unregister("spellResist", onOthrilResist)
		event.register("spellResist", onOthrilResist)
	end

	if e.topic.id == "NC_HelpBelvayn" then
		if e.index == 100 then
			event.unregister("uiActivated", onMenuRestWait, { filter = "MenuRestWait" })
			event.register("uiActivated", onMenuRestWait, { filter = "MenuRestWait" })
		elseif e.index == 10 then
			event.unregister("simulate", findTelescope)
			event.register("simulate", findTelescope)
			tes3.player.data.necroCraft.telescopeTimestamp = 0
		end
	end

	if e.topic.id == "NC_HelpSharn" then
		if e.index == 10 then
			soulGemLib.captureSoul{reference = tes3.player, gem = "AB_Misc_SoulGemBlack", soul = "NC_LlevuleAndrano"}
		elseif e.index == 100 then
			if soulGemLib.releaseSoul{reference = tes3.player, gem = "AB_Misc_SoulGemBlack", soul = "NC_LlevuleAndrano"} then
				tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage62).value, tes3.getObject("AB_Misc_SoulGemBlack").name)
			end
		end
	end

	if e.topic.id == "NC_HelpUlver" then
		if e.index == 50 then
			for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.activator) do
				if ref.baseObject.id == "Furn_imp_altar_cure_01" then
					tes3.cast({
						target = ref,
						reference = ref,
						spell = "Restore Mage",
					})
				end
			end
			tes3.say{reference="aunius autrus", soundPath="Vo\\i\\m\\Fle_IM004.mp3"}
			event.register("cellChanged", onCellChanged)
		end
	end
end



quests.loaded = function()
	event.unregister("journal", magic.edit.sharn)
	if tes3.getJournalIndex{id="MG_Sharn_Necro"} < 10 then
		event.register("journal", magic.edit.sharn)
	end
	if tes3.getJournalIndex{id="NC_HelpSorkvildT"} < 100 then
		mwscript.disable{reference = "nc_sc_theranasload"}
	end
	if tes3.getJournalIndex{id="NC_HelpDelvam"} < 10 then
		mwscript.disable{reference = "nc_chest_vsl_dest"}
	end
	event.unregister("spellResist", onOthrilResist)
	if tes3.getJournalIndex{id="NC_HelpFaram"} == 10 then
		event.register("spellResist", onOthrilResist)
	end
	event.unregister("uiActivated", onMenuRestWait, { filter = "MenuRestWait" })
	event.unregister("simulate", findTelescope)
	if tes3.getJournalIndex{id="NC_HelpBelvayn"} >= 100 then
		event.register("uiActivated", onMenuRestWait, { filter = "MenuRestWait" })
		event.register("simulate", findTelescope)
		tes3.player.data.necroCraft.telescopeTimestamp = nil
	elseif tes3.getJournalIndex{id="NC_HelpBelvayn"} >= 10 then
		event.register("simulate", findTelescope)
	end
	event.unregister("cellChanged", onCellChanged)
	if tes3.getJournalIndex{id="NC_HelpUlver"} >= 50 then
		if tes3.player.data.necroCraft and tes3.player.data.necroCraft.questStage ~= -1 then
			event.register("cellChanged", onCellChanged)
		end
	end
end

local function onInfoFilter(e)
	if not e.passes then return end
	local actorId = e.actor.baseObject.id
	local global = tes3.findGlobal("NC_HasSoulgem")
	if actorId == "treras dres" then
		if hasSoul(tes3.player, tes3.getObject("Nona")) then
			global.value = 1
		end
	elseif actorId == "dratha" then
		if hasSoul(tes3.player, tes3.getObject("treras dres")) then
			global.value = 1
		end
	else
		global.value = 0
	end
end

local function onInfoResponse(e)
	local responseCommand = string.lower(e.command)
	if string.find(responseCommand, "journal nc_helpdres 100") or string.find(responseCommand, "journal nc_helpdres 105") then
		local skill = skillModule.getSkill("NC:CorpsePreparation")
		skill:levelUpSkill(5)
	end
end

event.register("journal", quests.journal)
event.register("infoFilter", onInfoFilter)
event.register("infoResponse", onInfoResponse)

return quests