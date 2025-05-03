local acti = require("openmw.interfaces").Activation
local types = require('openmw.types')
local disabledPlayers = {}
local activateNextUpdate = {}
local activateSecondNextUpdate = {}
local deleteSecondNextUpdate = {}
local world = require('openmw.world')
local I = require("openmw.interfaces")
local actuallyActivateTable = {}
local openedGUIs = {}
local getSound = require("scripts.OwnlysQuickLoot.ql_getSound")
local util = require('openmw.util')
local organicContainers = {
	barrel_01_ahnassi_drink=true,
	barrel_01_ahnassi_food =true,
	com_chest_02_fg_supply =true,
	com_chest_02_mg_supply =true,
	flora_treestump_unique =true,
}
local onActivateStuff = {
["TR_m4_Sathasa Andas"] = true,
["Assi Serimilk"] = true,
["TR_m1_q_ArgonianHitman2"] = true,
["chargen class"] = true,
["TR_m4_HautharmoKollop"] = true,
["TR_m4_And_Temple_Coffer"] = true,
["TR_m3_Vontus"] = true,
["TR_m2_q_9_DreynisDummy"] = true,
["TR_m4_Rivyn_Dalvani"] = true,
["TR_m3_Iveru Falaal"] = true,
["TR_m3_Kha_Chest_01"] = true,
["TR_m1_Lish"] = true,
["com_chest_Daed_cursed"] = true,
["TR_m3_OE_MG_RdgrdPaint"] = true,
["TR_m4_TT_TempleCoffersB"] = true,
["TR_m2_Temis Lorthus_d"] = true,
["TR_m4_UshuKur_D_Milur"] = true,
["TR_m4_d_veers-in-brine"] = true,
["TR_m4_Morio_Stulti_Dead"] = true,
["TR_m3_q_5_ind_guard"] = true,
["chargen dock guard"] = true,
["Vivyne Andrano"] = true,
["TR_m4_d_Salrym Helseri"] = true,
["TR_m4_q_AABstash"] = true,
["TR_m4_UshuKur_D_Folcard"] = true,
["de_p_closet_02_nuncius"] = true,
["TR_m1_Claudine Hesault"] = true,
["Dravasa Andrethi"] = true,
["TR_m2_Erena Raneth"] = true,
["TR_m3_Kha_Chest_03"] = true,
["TR_m7_Dalin Kren"] = true,
["BM_greedyman"] = true,
["BM_WindBag"] = true,
["T_MwDe_Furn_CardHortB02"] = true,
["TR_m3_q_sack_wooden"] = true,
["TR_m4_UshuKur_D_Jubal"] = true,
["TR_m3_Edryon Rorvan"] = true,
["TR_m1_q_ArgonianHitman1"] = true,
["TR_m4_HH_HearingChest"] = true,
["TR_m1_treasurehunt_5"] = true,
["TR_m3_Yannib Nassirasu"] = true,
["TR_i2_303_barrel_poison"] = true,
["TR_m3_Treram_Odalyn"] = true,
["TR_m4_Rolis Hlor"] = true,
["Neldris Llervu"] = true,
["T_CyrImp_FurnR_Display2"] = true,
["TR_m4_q_AlynuChest"] = true,
["TR_m3_Reynant Alciente"] = true,
["T_MwDe_Furn_CardHortB01"] = true,
["de_p_desk_nuncius"] = true,
["T_CyrImp_FurnR_Display1"] = true,
["TR_m4_TT_Ulmon_Dead"] = true,
["TR_m3_Garvs Ovav"] = true,
["chest_ClawFang_UNIQUE"] = true,
["TR_m3_q_sack_brass"] = true,
["TR_m1_treasurehunt_3"] = true,
["TR_m7_Mervs Herano"] = true,
["TR_m4_TT_OrcVivec"] = true,
["TR_m1_q_YishiniVampDead"] = true,
["TR_m2_S_Jeela"] = true,
["TR_m2_q_38_favryn"] = true,
["TR_m7_Gnaeus Barossa"] = true,
["chargen name"] = true,
["TR_m4_Ando_NevusaBarrel"] = true,
["TR_m4_Gavros_Falas_dead"] = true,
["chargen boat guard 2"] = true,
["TR_m4_And_GavrosDesk"] = true,
["TR_m3_Bartolomaeus"] = true,
["TR_m1_Doves_Athryon"] = true,
["TR_m2_q_A9_3_Doril"] = true,
["TR_m4_Vanith Garos DEAD"] = true,
["TR_m4_UshuKur_D_Tryr"] = true,
["TR_m4_UshuKur_D_Nivis"] = true,
["TR_m4_UshuKur_D_Kassius"] = true,
["TR_m4_UshuKur_D_Gildar"] = true,
["TR_m4_UshuKur_D_Gelvu"] = true,
["TR_m4_UshuKur_D_Algus"] = true,
["TR_m1_Khifzah_Dead"] = true,
["TR_m4_TT_Ravur_Othravel"] = true,
["Vireveri Darethran"] = true,
["TR_m4_Synell_Gioranus"] = true,
["TR_m3_D_Jebyn"] = true,
["TR_m3_q_hideseektrap"] = true,
["TR_m2_q_27_heelkur"] = true,
["TR_m3_Antio Florane2"] = true,
["TR_m1_treasurehunt_4"] = true,
["TR_m3-531_crate_01_eggb"] = true,
["chargen boat guard 3"] = true,
["TR_m1_Q59_PR_Basket_1"] = true,
["Nelmil Hler"] = true,
["TR_m1_SilverSerpentKeg"] = true,
["com_chest_01_hircine2"] = true,
["TR_m4_q_TMM_chest"] = true,
["Dralas Gilu"] = true,
["TR_m3_pilgrimsupplies"] = true,
["TR_m1_Gritnol"] = true,
["TR_m2_Uviri Olmen"] = true,
["Relur Faryon"] = true,
["Daynasa Telandas"] = true,
["TR_m2_q_36_ArvsChest"] = true,
["TR_m3_EbonTowerIL_Dummy"] = true,
["TR_m3_Kha_10_Chest_Gold"] = true,
["Tadera Andules"] = true,
["TR_m2_q_14_NalethChest"] = true,
["TR_m1_fishermancorpse"] = true,
["TR_m1_treasurehunt_1"] = true,
["Dovor Oren"] = true,
["com_chest_02_maryn"] = true,
["com_chest_02_jeanne_u"] = true,
["Rararyn Radarys"] = true,
["TR_m4_D_Armun_Caravan_2"] = true,
["chargen boat guard 1"] = true,
["TR_m4_HH_Ulvo3_Chest"] = true,
["TR_m3_ManielSylbenitte"] = true,
["chest_tomb_Sandas"] = true,
["TR_m4_AA_SehutuMummy"] = true,
["TR_m4_AndoHH_LiqCrate"] = true,
["TR_m2_q_9_Barrel_uni"] = true,
["TR_m4_d_smugglerteyn"] = true,
["TR_m4_D_KhirakaiBandit2"] = true,
["TR_m4_D_KhirakaiBandit1"] = true,
["TR_m4_D_Joscus"] = true,
["TR_m4_D_Armun_Caravan_3"] = true,
["TR_m4_D_Armun_Caravan_1"] = true,
["TR_m7_Q_DivingForArns"] = true,
["TR_m6_LA3_Dae_Chest"] = true,
["TR_m4_Aro Helseri"] = true,
["TR_m7_q_Uls Herano_slp"] = true,
["TR_m3_q_A5_crate_01"] = true,
["TR_m3-239_cont_box_tap"] = true,
["Alvura Othrenim"] = true,
["TR_m4_Olvys Omayn"] = true,
["TR_m3_PilgrimStranded"] = true,
["TR_m3_Tindalos Miranus"] = true,
["TR_m3_Sadryn Seles"] = true,
["TR_m1_treasurehunt_2"] = true,
["Endris Dilmyn"] = true,
["TR_m1_orchest_curse_i62"] = true,
["TR_m3_Ralam_Othravel"] = true,
["TR_m3_Nerlis"] = true,
["Llandras Belaal"] = true,
["TR_m4_UshuKur_D_Guard01"] = true,
["ashamanu"] = true,
["TR_m1_FW_BrazenCrate"] = true,
["TR_m3_Aillijar"] = true,
["flora_treestump_unique"] = true,
["TR_m3_Karandia Corrux"] = true,
["TR_m3_Foedus Locutius"] = true,
["TR_m4-349_WaterTrap_Cst"] = true,
["TR_m4_dolg_gro-madrag"] = true,
["TR_m2_Kaye"] = true,
["TR_m1_Q59_PR_Urn"] = true,
["TR_m2_Ilmeni Benamamat"] = true,
["TR_m4_Treram_chest"] = true,
["TR_m3_DilavesaIndoran"] = true,
["TR_m2_Eifid"] = true,
["TR_m4_Hlavora Tilvur"] = true,
["processus vitellius"] = true,
["Eralane Hledas"] = true,
["TR_m1_dead_Alvar_O"] = true,
["TR_m3_OE_fiendchest2"] = true,
["TR_m3_OE_raathim_urn_1"] = true,
["TR_m4_TG_ElarFandasBook"] = true,
["TR_m2_Arfil"] = true,
["TR_m2_q_9_MithasDead"] = true,
["TR_m4_Nivis Dalomo"] = true,
["TR_m2_q_A8_2_Seinda"] = true,
["TR_m3-239_cont_box_rug"] = true,
["TR_m2_q_12_Rianele_Sele"] = true,
["TR_m1_Q_chest_rgirth"] = true,
["TR_m3_Addamarys Saldro"] = true,
["TR_m1_dead_Redram_Oran"] = true,
["TR_m3_OE_fiendchest1"] = true,
["TR_m3_Enix Caripus"] = true,
["TR_m1_q_MorvinGirith"] = true,
["TR_m3_Folms Hiralas"] = true,
["TR_m4_Ando_FaulerChest"] = true,
["Contain_BM_stalhrim_01"] = true,
["TR_m1_Q59_PR_basket_2"] = true,
["TR_m3_Ulvo Telvor"] = true,
["chargen captain"] = true,
["TR_m3_Kha_Chest_06"] = true,
["TR_m3_Kha_Chest_05"] = true,
["TR_m3_q_hideseekchest"] = true,
["rigmor halfhand"] = true,
["TR_m3_Kha_Chest_00"] = true,
["TR_m3_q_EP_sack"] = true,
["TR_m3_OE_fiendchest3"] = true,
["TR_m3_Kha_Chest_04"] = true,
["TR_m3_Kha_Chest_02"] = true,
["TR_m3_sarvayn_chest"] = true,
["ralen hlaalo"] = true,
}
onActivateStuffOnce = {}


local function removeInvisibility(player)
	for a,b in pairs(types.Actor.activeSpells(player)) do
		for c,d in pairs(b.effects) do
			if d.duration and d.id == "invisibility" then--and (d.id == "fortifyhealth" or d.id == "fortifyfatigue" or d.id == "fortifymagicka") then
				types.Actor.activeSpells(player):remove(b.activeSpellId)
			end
		end
	end
end

function triggerMwscriptTrap(obj, player)
	local script = world.mwscript.getLocalScript(obj, player)
	--print(world.mwscript.getLocalScript(obj, player).scriptText)
	--print(world.mwscript.getGlobalScript(recordId, player).scriptText)
	if script then
		if script.variables.setonce == 0 
		or script.variables.done == 0 
		or script.variables.doOnce == 0
		then
			player:sendEvent("OwnlysQuickLoot_fellForTrap", obj)
			obj:activateBy(player)
			--world._runStandardActivationAction(obj, world.players[1])
			return true
		
		elseif not script.variables.setonce
		and not script.variables.done
		and not script.variables.doOnce
		and onActivateStuff[obj.recordId]
		and not onActivateStuffOnce[obj.recordId] then
			onActivateStuffOnce[obj.recordId] = true
			player:sendEvent("OwnlysQuickLoot_fellForTrap", obj)
			obj:activateBy(player)
			--world._runStandardActivationAction(obj, world.players[1])
			return true
		end
	end
end



local function activateContainer(cont, player)
	removeInvisibility(player)
	if not disabledPlayers[player.id] and not actuallyActivateTable[player.id] then
		--world._runStandardActivationAction(cont, world.players[1])
		triggerMwscriptTrap(cont,player)
		if not types.Lockable.isLocked(cont)
		and not types.Lockable.getTrapSpell(cont)
		and (not cont.type.record(cont).isOrganic or organicContainers[cont.recordId])
		then
			player:sendEvent("OwnlysQuickLoot_activatedContainer", {cont})
			return false
		end
	end
end

local function activateActor(actor,player)
	--if not disabledPlayers[player.id] and not actuallyActivateTable[player.id] and not actor.type.isDead(actor) then
	--	player:sendEvent("OwnlysQuickLoot_activatedContainer", {actor, not actor.type.isDead(actor)})
	--	return false
	--end
	if not disabledPlayers[player.id] and not actuallyActivateTable[player.id] and 
	(	actor.type.isDead(actor) 
		or (
			openedGUIs[player.id] -- sneaking		
		)
	)
	then
		triggerMwscriptTrap(actor,player)
		player:sendEvent("OwnlysQuickLoot_activatedContainer", {actor, not actor.type.isDead(actor)})
		
		return false
	end
	return true
end

local function resolve(cont)
	types.Container.inventory(cont):resolve()
end

local function take(data)
	local player = data[1]
	local container = data[2]
	local thing = data[3]
	local isPickpocketing = data[4]
	local experimentalLooting = data[5]
	
	if isPickpocketing then
		thing:moveInto(types.Player.inventory(player))
	elseif thing.type == types.Book or experimentalLooting and container.owner.factionId == nil and container.owner.recordId == nil then
		thing:moveInto(types.Player.inventory(player))
		player:sendEvent("OwnlysQuickLoot_playSound",getSound(thing))
	elseif thing.recordId == "gold_001" or thing.recordId == "gold_005" or thing.recordId == "gold_010" or thing.recordId == "gold_025" or thing.recordId == "gold_100" then --90% sure its just gold_001
		thing:teleport(player.cell, player.position, player.rotation)
		table.insert(activateSecondNextUpdate,{thing,player,container}) -- gold takes 2 ticks to become valid and allow owner changes
	else
		thing:teleport(player.cell, player.position, player.rotation)
		thing.owner.factionId = container.owner.factionId
		thing.owner.factionRank = container.owner.factionRank
		thing.owner.recordId = container.owner.recordId
		table.insert(activateNextUpdate,{thing,player})
	end
	--thing:activateBy(player)
--moveInto(types.Player.inventory(player))
	--player:sendEvent("TakeAll_closeUI")
end

local function takeAll(data)
	local player = data[1]
	local container = data[2]
	local disposeCorpse = data[3]
	local isCorpse = data[4]
	local experimentalLooting = data[5]
	local i =0
	types.Container.inventory(container):resolve()
	if not triggerMwscriptTrap(container,player) then
		--print(container,container.type,types.Container.inventory(container):isResolved())
		for _, thing in pairs(types.Container.inventory(container):getAll()) do
			local thingRecord = thing.type.records[thing.recordId]
			if not thingRecord.name or thingRecord.name == "" or not types.Item.isCarriable(thing) then
				--ignore
			elseif thing.type == types.Book then
				thing:moveInto(types.Player.inventory(player))
				i=i+1
			elseif thing.recordId == "gold_001" or thing.recordId == "gold_005" or thing.recordId == "gold_010" or thing.recordId == "gold_025" or thing.recordId == "gold_100" then --90% sure its just gold_001
				thing:teleport(player.cell, player.position, player.rotation)
				table.insert(activateSecondNextUpdate,{thing,player,container}) -- gold takes 2 ticks to become valid and allow owner changes
			else
				thing:teleport(player.cell, player.position, player.rotation)
				thing.owner.factionId = container.owner.factionId
				thing.owner.factionRank = container.owner.factionRank
				thing.owner.recordId = container.owner.recordId
				table.insert(activateNextUpdate,{thing,player})
				
				i=i+1
			end
			--thing:activateBy(player)
		--moveInto(types.Player.inventory(player))
		end
		if disposeCorpse and types.Actor.objectIsInstance(container) and types.Actor.isDead(container) then
			table.insert(deleteSecondNextUpdate,{container,2})
		end
		if i>0 then
			--player:sendEvent("TakeAll_PlaySound","Item Ingredient Up")
		end
	end
end


acti.addHandlerForType(types.Container, activateContainer)
acti.addHandlerForType(types.NPC, activateActor)
acti.addHandlerForType(types.Creature, activateActor)

local function onUpdate(dt)
	for _, t in pairs(activateNextUpdate) do
		if t[3] then
			t[1].owner.factionId = t[3].owner.factionId
			t[1].owner.factionRank = t[3].owner.factionRank
			t[1].owner.recordId = t[3].owner.recordId
		end
		t[1]:activateBy(t[2])
	end
	--for a,b in pairs(actuallyActivateTable) do
	--	actuallyActivateTable[a] = b-1
	--	if b == 0 then 
	--		actuallyActivateTable[a] = nil
	--	end
	--end
	for i, t in pairs(deleteSecondNextUpdate) do
		if t[2]>1 then
			t[2] = 1
		else
			t[1]:remove(1)
			table.remove(deleteSecondNextUpdate,i)
		end
	end
	activateNextUpdate = activateSecondNextUpdate
	activateSecondNextUpdate = {}
end
local function playerToggledMod(arg)
	local player = arg[1]
	local toggle = arg[2]
	disabledPlayers[player.id] = not toggle
end

local function actuallyActivate(arg)
	local player = arg[1]
	local obj = arg[2]
	--actuallyActivateTable[player.id] = 2
	--world._runStandardActivationAction(obj, player)
	removeInvisibility(player)
	obj:activateBy(player)
end

local function freshLoot(arg)
	local player = arg[1]
	local obj = arg[2]
	--actuallyActivateTable[player.id] = 2
	--world._runStandardActivationAction(obj, player)
	if I.FreshLoot then
		if I.FreshLoot.processLoot then
			I.FreshLoot.processLoot(obj, player)
		else
			print("PLEASE UPDATE FRESHLOOT")
		end
	end
end

function test(tbl)
	local player = tbl[1]
	local item = tbl[2]
	
	local originalRecord = types.Weapon.records[item.recordId]
		
		local itemTable = {name = originalRecord.name, template = originalRecord, enchantCapacity = originalRecord.enchantCapacity * 1.25}
		
		--local newRecordDraft = item.type.createRecordDraft{itemTable}
		local newRecordDraft = types.Weapon.createRecordDraft(itemTable)
	
		--add to world
		local newRecord = world.createRecord(newRecordDraft)
		print(newRecord.id)
		
		local upgradedItem = world.createObject(newRecord.id, 1)
		print(upgradedItem.id)
		
		local cell = world.getCellById(player.cell.id)
	
		--moves to altar
		--upgradedItem:teleport(player.cell, player.position, player.rotation)
		upgradedItem:teleport(player.cell, player.position, player.rotation)
end

local function openGUI(playerObject)
	openedGUIs[playerObject.id] = world.getGameTime()
end

local function closeGUI(playerObject)
	openedGUIs[playerObject.id] = nil
end

local function getCrimesVersion(player)
	player:sendEvent("OwnlysQuickLoot_receiveCrimesVersion", I.Crimes.version)
end

local function commitCrime(data)
	local player = data[1]
	local container = data[2]
	local price = data[3]
	local commitCrimeOutputs = I.Crimes.commitCrime(player,{
		type = types.Player.OFFENSE_TYPE.Pickpocket,
		victim = container,
		arg = price,
		victimAware = true
	})
end

local function rotateNpc(data)
	local player = data[1]
	local npc = data[2]
	
	local directionToPlayer = player.position - npc.position
	local targetYaw = math.atan2(directionToPlayer.y, directionToPlayer.x)
	npc:teleport(npc.cell, npc.position, util.transform.rotateZ(-targetYaw+math.pi/2))
end

local function modDisposition(data)
	local player = data[1]
	local target = data[2]
	local value = data[3]
	types.NPC.modifyBaseDisposition(target, player, value)
end

return {
	eventHandlers = {
		OwnlysQuickLoot_freshLoot = freshLoot,
		OwnlysQuickLoot_take = take,
		OwnlysQuickLoot_takeAll = takeAll,
		OwnlysQuickLoot_takeBook = takeBook,
		OwnlysQuickLoot_resolve = resolve,
		OwnlysQuickLoot_actuallyActivate = actuallyActivate,
		OwnlysQuickLoot_playerToggledMod = playerToggledMod,
		OwnlysQuickLoot_test = test,
		OwnlysQuickLoot_openGUI = openGUI,
		OwnlysQuickLoot_closeGUI = closeGUI,
		OwnlysQuickLoot_getCrimesVersion = getCrimesVersion,
		OwnlysQuickLoot_commitCrime = commitCrime,
		OwnlysQuickLoot_rotateNpc = rotateNpc,
		OwnlysQuickLoot_modDisposition = modDisposition,
	},
	engineHandlers = {
		onUpdate = onUpdate,
	}
}