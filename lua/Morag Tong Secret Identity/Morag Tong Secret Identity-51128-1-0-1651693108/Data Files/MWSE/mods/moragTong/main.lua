local common = require("moragTong.common")

event.register("modConfigReady", function()
    require("moragTong.mcm")
	common.config  = require("moragTong.config")
end)

local strings = common.dictionary

local dialogueId = {
	["2978719872133784745"] = true,
	["286538470143286423"] = true,
	["30720953138123300"] = true,
	["3953214983021829582"] = true,
	["27268823331843134"] = true,
	["375111226211453250"] = true,
	["2545120377597030349"] = true,
	["42861608154112508"] = true,
	["18027327602606020970"] = true,
	["1864589583235217734"] = true,
	["321336148199691427"] = true,
	["243065022205014868"] = true,
	["1935914985132526094"] = true,
	["2363816523715520806"] = true,
	["1478925705354615614"] = true,
	["74942758379332376"] = true,
	["2891024981631431983"] = true,
	["30280283662079432101"] = true,
	["1186073741515428430"] = true,
	["2425636923061727085"] = true,
	["20583315131013811726"] = true,
	["897030800310681173"] = true,
	["21068238711129631302"] = true,
	["5978126236608624"] = true,
	["6812526555353372"] = true,
	["184181963819476965"] = true,
	["14367256971364129203"] = true,
	["1593114301531216394"] = true,
	["169451442863529418"] = true,
	["26139704971782004"] = true,
	["302946901316717399"] = true,
	["25275185601460422327"] = true,
	["264877156181401916"] = true,
	["1580118447388516444"] = true,
}

local crimeTimestamp
local valid = false
local identity = strings.concealed
local moragTong

local function addWitness(witness)

	if tes3.player.data.moragTong.identityWitness[witness.id] then
		return
	end

	if witness.object.faction == moragTong then
		return
	end

	--tes3.messageBox("You were witnessed by %s", witness.id)

	tes3.player.data.moragTong.identityWitness[witness.id] = true
	tes3.player.data.moragTong.revelation = tes3.player.data.moragTong.revelation + 1

	if tes3.player.data.moragTong.revelation >= common.config.revelationCount*2 then
		if identity ~= strings.revealed then
			tes3.messageBox(strings.fullyRevealed)
			if moragTong.playerRank < common.config.privilegedRank then
				common.setExpelled(moragTong, true)
			end
			identity = strings.revealed
		end
	elseif tes3.player.data.moragTong.revelation >= common.config.revelationCount then
		if identity == strings.concealed then
			tes3.messageBox(strings.beingRevealed)
		end
		identity = strings.speculated
	end
end

local function isWritTarget(reference)
	local journal = common.config.writTargets[reference.baseObject.id]

	--mwse.log(journal)

	if journal then
		local index = tes3.getJournalIndex{id = journal}
		--mwse.log(index)
		if index and index > 0 then
			return true
		end
	end
	return false
end

local function onDamage(e)
	if e.attacker ~= tes3.mobilePlayer then return end

	if isWritTarget(e.reference) then
		valid = true
		crimeTimestamp = tes3.getSimulationTimestamp()
	else
		valid = false
	end
end

local function onAttack(e)
	if e.mobile ~= tes3.mobilePlayer then return end
	if not e.targetReference then return end

	if isWritTarget(e.targetReference) then
		valid = true
		crimeTimestamp = tes3.getSimulationTimestamp()
	else
		valid = false
	end
end

local validCrimeTypes = {
	killing = true,
	attack = true,
}

local function onCrimeWitnessed(e)

	if not crimeTimestamp then
		if moragTong.playerRank < common.config.privilegedRank or identity ~= strings.concealed then
			common.setExpelled(moragTong, true)
			return
		end
	end

	if tes3.getSimulationTimestamp() > crimeTimestamp + 0.02 then
		valid = false
	end

	if not valid or not validCrimeTypes[e.type] then
		if moragTong.playerRank < common.config.privilegedRank or identity ~= strings.concealed then
			common.setExpelled(moragTong, true)
		end
	elseif e.type == 'killing' and valid and not tes3.player.data.moragTong.appearance then
		addWitness(e.witness)
	end

end

local function onMTFactionTooltip(e)
	--e.source:forwardEvent(e)
	local tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
	local child = tooltip:findChild()
	local identityLabel = child:createLabel{text=strings.identity..identity}
	if identity == strings.concealed then
		identityLabel.color = tes3ui.getPalette("header_color")
	elseif identity == strings.speculated then
		identityLabel.color = tes3ui.getPalette("normal_color")
	elseif identity == strings.revealed then
		identityLabel.color = tes3ui.getPalette("negative_color")
	end
	identityLabel.borderBottom = 10
	child:reorderChildren(2, 7, 1)
end

local function onDetect(e)

	if e.target ~= tes3.mobilePlayer or not e.isDetected or tes3.player.data.moragTong.masked then
		return
	end

	if e.detector.reference.baseObject.objectType ~= tes3.objectType.npc then
		return
	end

	 addWitness(e.detector.reference)

end

local function removeWitness(e)
	if tes3.player.data.moragTong.identityWitness[e.reference.id] then
		tes3.player.data.moragTong.identityWitness[e.reference.id] = nil
		tes3.player.data.moragTong.revelation = tes3.player.data.moragTong.revelation - 1
		if tes3.player.data.moragTong.revelation >= common.config.revelationCount*2 then
			identity = strings.revealed
		elseif tes3.player.data.moragTong.revelation >= common.config.revelationCount then
			identity = strings.speculated
		else
			identity = strings.concealed
		end
	end
end

local menuEnterMaskedStatus
local menuEnterAppearanceStatus
local menuEnterTimestamp = 0

local function onMenuExit()

	if not tes3.player.data.moragTong then
		return
	end

	if tes3.player.data.moragTong.masked then
		if menuEnterMaskedStatus == false  then
			tes3.player.data.moragTong.masked = false
			timer.start{
				duration = 1,
				callback = function() tes3.player.data.moragTong.masked = true end
			}
		end
	end

	if not tes3.player.data.moragTong.appearance then
		if menuEnterAppearanceStatus == true  then
			tes3.player.data.moragTong.appearance = true
			event.unregister("detectSneak", onDetect)
			event.register("detectSneak", onDetect)
			timer.start{
				duration = 1,
				callback = function() 
					tes3.player.data.moragTong.appearance = false
					event.unregister("detectSneak", onDetect)
				end
			}
		end
	end
end

local function onMenuEnter(e)

	local menu = tes3ui.findMenu("MenuStat")

	menuEnterAppearanceStatus = common.hasRevealingItems()
	menuEnterMaskedStatus = tes3.player.data.moragTong.masked or false
	menuEnterTimestamp = tes3.getSimulationTimestamp()

	if not menu then return end
	local scrollPaneChildren = menu:findChild(tes3ui.registerID("PartScrollPane_pane")).children
	for _, element in pairs(scrollPaneChildren) do
		if  element.id == tes3ui.registerID("MenuStat_faction_layout") and element.text and element.text == "Morag Tong" then
			element.consumeMouseEvents = true
			element:registerAfter("help", onMTFactionTooltip)
		end
	end
end

local function equipmentChange(e, status)
	if e.actor.id ~= tes3.player.id then
		return
	end

	local newEquipmentTimestamp = tes3.getSimulationTimestamp()

	if common.config.closedHelmets[e.item.id] then
		if menuEnterTimestamp == newEquipmentTimestamp or not status then
			tes3.player.data.moragTong.masked = status
		else
			timer.start{
				duration = 1,
				callback = function() tes3.player.data.moragTong.masked = status end
			}
		end
	end

	tes3.player.data.moragTong.appearance = common.hasRevealingItems()

	if tes3.player.data.moragTong.appearance then
		event.unregister("detectSneak", onDetect)
		event.register("detectSneak", onDetect)
	elseif menuEnterTimestamp == newEquipmentTimestamp then
		--mwse.log("No revealing items and in menu mode detect sneak stopped immediately")
		event.unregister("detectSneak", onDetect)
	else
		timer.start{
			duration = 1,
			callback = function()
				--mwse.log("No revealing items detect sneak stopped")
				event.unregister("detectSneak", onDetect)
			end
		}
	end
end

local function onEquipped(e)
	equipmentChange(e, true)
end

local function onUnequipped(e)
	equipmentChange(e, false)
end

local responseCommand = nil
local infoActor = nil

local function onInfoResponse(e)
	responseCommand = string.lower(e.command)
end

local function onInfoGetText(e)

	if not tes3.player.data.moragTong or not (tes3.player.data.moragTong.masked and tes3.player.data.moragTong.appearance) then
		return
	end

	if dialogueId[e.info.id] then
		return
	end

	responseCommand = nil

	if infoActor and infoActor.faction == moragTong then
		infoActor = nil
		return
	end

	if tes3.player.data.moragTong.identityWitness[infoActor.id] then
		return
	end

	infoActor = nil
	e.text = e:loadOriginalText()
	e.text = string.gsub(e.text, "%%[Pp][Cc][Nn][Aa][Mm][Ee]", strings.moragTong)

	timer.frame.delayOneFrame(function()
		if not responseCommand or ( not string.find(responseCommand, "choice") and not string.find(responseCommand, "goodbye") ) then
			--tes3ui.showDialogueMessage({ text = "\n" })
			tes3.runLegacyScript{ command = 'Goodbye' }
		end
	end)
end

local function onInfoFilter(e)
	if not e.passes then return end

	infoActor = e.actor

	if identity == strings.revealed then return end

	if e.actor.faction == moragTong or tes3.player.data.moragTong.identityWitness[e.actor.id] then
		return
	end

	if tes3.player.data.moragTong.appearance then return end
	
	if e.info.pcFaction == moragTong then
		e.passes = false 
	elseif dialogueId[e.info.id] then
		e.passes = false
	end
end

local function updateIdentity()
	if tes3.player.data.moragTong.revelation >= common.config.revelationCount*2 then
		identity = strings.revealed
	elseif tes3.player.data.moragTong.revelation >= common.config.revelationCount then
		identity = strings.speculated
	else
		identity = strings.concealed
	end
end

local function onMoragTongJoined()
	tes3.player.data.moragTong = tes3.player.data.moragTong or {}
	tes3.player.data.moragTong.revelation = tes3.player.data.moragTong.revelation or 0
	tes3.player.data.moragTong.identityWitness = tes3.player.data.moragTong.identityWitness or {}
	tes3.player.data.moragTong.appearance = common.hasRevealingItems()

	menuEnterMaskedStatus = tes3.player.data.moragTong.masked
	menuEnterAppearanceStatus = tes3.player.data.moragTong.appearance
	menuEnterTimestamp = 0

	updateIdentity()

	if tes3.player.data.moragTong.appearance then
		event.unregister("detectSneak", onDetect)
		event.register("detectSneak", onDetect)
	else
		event.unregister("detectSneak", onDetect)
	end
end

local function onLoaded(e)
	updateIdentity()
end

local status = false

local function checkFactionStatus(e)

	-- mwse.log("player masked status: %s", tes3.player.data.moragTong.masked)
	-- tes3.messageBox("player masked status: %s", tes3.player.data.moragTong.masked)

	if status == moragTong.playerJoined then
		return
	end

	status = moragTong.playerJoined

	if status then
		event.register("loaded", onLoaded)
		event.register("damage", onDamage)
		event.register("attack", onAttack)
		event.register("menuEnter", onMenuEnter)
		event.register("menuExit", onMenuExit)
		event.register("equipped", onEquipped)
		event.register("unequipped", onUnequipped)
		event.register("crimeWitnessed", onCrimeWitnessed)
		event.register("death", removeWitness)
		event.register("infoFilter", onInfoFilter)
		event.register("infoGetText", onInfoGetText)
		event.register("infoResponse", onInfoResponse)
		onMoragTongJoined()
	else
		event.unregister("loaded", onLoaded)
		event.unregister("damage", onDamage)
		event.unregister("attack", onAttack)
		event.unregister("menuEnter", onMenuEnter)
		event.unregister("menuExit", onMenuExit)
		event.unregister("equipped", onEquipped)
		event.unregister("unequipped", onUnequipped)
		event.unregister("crimeWitnessed", onCrimeWitnessed)
		event.unregister("death", removeWitness)
		event.unregister("infoFilter", onInfoFilter)
		event.unregister("infoGetText", onInfoGetText)
		event.unregister("infoResponse", onInfoResponse)
		event.unregister("detectSneak", onDetect)
	end
end

local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log("[Morag Tong Secret Identity]: enabled")
		moragTong = tes3.getFaction("Morag Tong")
		event.register("simulate", checkFactionStatus)
	else
		event.unregister("simulate", checkFactionStatus)
		mwse.log("[Morag Tong Secret Identity]: disabled")
	end
end

event.register("initialized", onInitialized)