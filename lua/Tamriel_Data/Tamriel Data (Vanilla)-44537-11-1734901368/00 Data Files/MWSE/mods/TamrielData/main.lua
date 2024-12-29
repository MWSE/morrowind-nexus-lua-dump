--[[
	Tamriel Data MWSE-Lua Addon v2.0
	By Kynesifnar, mort, and Rakanishu
]]

local common = require("tamrielData.common")
local config = require("tamrielData.config")
local magic = require("tamrielData.magic")
local reputation = require("tamrielData.reputation")
local weather = require("tamrielData.weather")

-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20241219) then
    event.register(tes3.event.initialized, function()
        tes3ui.showNotifyMenu(common.i18n("main.mwseDate"))
    end)
    return
end

mwse.log("[Tamriel Data MWSE-Lua] Initialized Version 2.0")

-- item id, pickup sound id, putdown sound id, equip sound id
local item_sounds = {	
	{ "T_Imp_Subst_Blackdrake_01", "Item Misc Up", "Item Misc Down", "T_SndObj_DrugSniff"},
	{ "T_De_Subst_Greydust_01", "Item Misc Up", "Item Misc Down", "T_SndObj_DrugSniff"},
	{ "T_Nor_Subst_WasabiPaste_01", "Item Misc Up", "Item Misc Down", "Swallow"},
	{ "T_Imp_Subst_Aegrotat_01", "Item Misc Up", "Item Misc Down", "Swallow"},
	{ "T_De_Drink_PunavitResin_01", "Item Misc Up", "Item Misc Down", "Swallow"},
	{ "T_Com_Subst_Perfume_01", "Item Potion Up", "Item Potion Down", "T_SndObj_SprayBottle"},
	{ "T_Com_Subst_Perfume_02", "Item Potion Up", "Item Potion Down", "T_SndObj_SprayBottle"},
	{ "T_Com_Subst_Perfume_03", "Item Potion Up", "Item Potion Down", "T_SndObj_SprayBottle"},
	{ "T_Com_Subst_Perfume_04", "Item Potion Up", "Item Potion Down", "T_SndObj_SprayBottle"},
	{ "T_Com_Subst_Perfume_05", "Item Potion Up", "Item Potion Down", "T_SndObj_SprayBottle"},
	{ "T_Com_Subst_Perfume_06", "Item Potion Up", "Item Potion Down", "T_SndObj_SprayBottle"},
	{ "T_Imp_Subst_IndulcetPreserve_01", "Item Potion Up", "Item Potion Down", "Swallow"},
	{ "T_Imp_Subst_QuaestoVil_01", "Item Potion Up", "Item Potion Down", "Item Potion Down"},
	{ "T_Imp_Subst_QuaestoVil_02", "Item Potion Up", "Item Potion Down", "Item Potion Down"},

	{ "T_IngSpice_OliveOil_01", "Item Potion Up", "Item Potion Down", "Drink"},
	{ "T_IngFood_Vinegar_01", "Item Potion Up", "Item Potion Down", "Drink"},
	{ "T_IngCrea_OrcBlood_01", "Item Potion Up", "Item Potion Down", "Drink"},

	{ "misc_dwrv_coin00", "Item Gold Up", "Item Gold Down", "" },
	{ "misc_dwrv_cursed_coin00", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Ayl_CoinBig_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Ayl_CoinGold_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Ayl_CoinSquare_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_He_DirenniCoin_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Imp_CoinAlessian_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Imp_CoinReman_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Ayl_CoinSquare_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Nor_CoinBarrowCopper_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Nor_CoinBarrowIron_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_Nor_CoinBarrowSilver_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_De_HlaaluCompanyScrip_01", "Item Gold Up", "Item Gold Down", "" },
	{ "T_De_HlaaluCompanyScrip_02", "Item Gold Up", "Item Gold Down", "" }
}

-- region id, xcell left bound, xcell right bound, ycell top bound, ycell bottom bound
local almsivi_intervention_regions = {
	{ "Aanthirin Region", nil, nil, nil, nil },
	{ "Alt Orethan Region", nil, nil, nil, nil },
	{ "Armun Ashlands Region", nil, nil, nil, nil },
	{ "Arnesian Jungle Region", nil, nil, nil, nil },
	{ "Ascadian Isles Region", nil, nil, nil, nil },
	{ "Ashlands Region", nil, nil, nil, nil },
	{ "Azura's Coast Region", nil, nil, nil, nil },
	{ "Bitter Coast Region", nil, nil, nil, nil },
	{ "Boethiah's Spine Region", nil, nil, nil, nil },
	{ "Clambering Moor Region", nil, nil, nil, nil },
	{ "Dagon Urul Region", nil, nil, nil, nil },
	{ "Deshaan Plains Region", nil, nil, nil, nil },
	{ "Grazelands Region", nil, nil, nil, nil },
	{ "Grey Meadows Region", nil, nil, nil, nil },
	{ "Julan-Shar Region", nil, nil, nil, nil },
	{ "Lan Orethan Region", nil, nil, nil, nil },
	{ "Mephalan Vales Region", nil, nil, nil, nil },
	{ "Molag Mar Region", nil, nil, nil, nil },
	{ "Molag Ruhn Region", nil, nil, nil, nil },
	{ "Molagreahd Region", nil, nil, nil, nil },
	{ "Mournhold Region", nil, nil, nil, nil },
	{ "Mudflats Region", nil, nil, nil, nil },
	{ "Nedothril Region", nil, nil, nil, nil },
	{ "Old Ebonheart Region", nil, nil, nil, nil },
	{ "Othreleth Woods Region", nil, nil, nil, nil },
	{ "Red Mountain Region", nil, nil, nil, nil },
	{ "Roth Roryn Region", nil, nil, nil, nil },
	{ "Sacred Lands Region", nil, nil, nil, nil },
	{ "Salt Marsh Region", nil, nil, nil, nil },
	{ "Sheogorad", nil, nil, nil, nil },
	{ "Shipal-Shin Region", nil, nil, nil, nil },
	{ "Sundered Scar Region", nil, nil, nil, nil },
	{ "Telvanni Isles Region", nil, nil, nil, nil },
	{ "Thirr Valley Region", nil, nil, nil, nil },
	{ "Uld Vraech Region", nil, nil, nil, nil },
	{ "Velothi Mountains Region", nil, nil, nil, nil },
	{ "West Gash Region", nil, nil, nil, nil },
	{ "Sea of Ghosts Region", -40, 58, 17, 33 },
	{ "Padomaic Ocean Region", 30, 58, -61, 30 },
	{ nil, -40, 58 , -61, 33 },
	{ "Brodir Grove Region", nil, nil, nil, nil },
	{ "Felsaad Coast Region", nil, nil, nil, nil },
	{ "Hirstaang Forest Region", nil, nil, nil, nil },
	{ "Moesring Mountains Region", nil, nil, nil, nil },
	{ "Isinfier Plains Region", nil, nil, nil, nil },
	{ "Thirsk Region", nil, nil, nil, nil }
}

-- region id, xcell left bound, xcell right bound, ycell top bound, ycell bottom bound
local kyne_intervention_regions = {
	{ "Colovian Barrowlands Region", nil, nil, nil, nil },
	{ "Drajkmyr Marsh Region", nil, nil, nil, nil },
	{ "Druadach Highlands Region", nil, nil, nil, nil },
	{ "Falkheim Region", nil, nil, nil, nil },
	{ "Gorvigh Mountains Region", nil, nil, nil, nil },
	{ "Hrimbald Plateau Region", nil, nil, nil, nil },
	{ "Hirsing Forest Region", nil, nil, nil, nil },
	{ "Jerall Mountains Region", nil, nil, nil, nil },
	{ "Kilkreath Mountains Region", nil, nil, nil, nil },
	{ "Kreathi Vale Region", nil, nil, nil, nil },
	{ "Lorchwuir Heath Region", nil, nil, nil, nil },
	{ "Mhorkren Hills Region", nil, nil, nil, nil },
	{ "Midkarth Region", nil, nil, nil, nil },
	{ "Northshore Region", nil, nil, nil, nil },
	{ "Reaver's Shore Region", nil, nil, nil, nil },
	{ "Rift Valley Region", nil, nil, nil, nil },
	{ "Skaldring Mountains Region", nil, nil, nil, nil },
	{ "Solitude Forest Region", nil, nil, nil, nil },
	{ "Solitude Forest Region S", nil, nil, nil, nil },
	{ "Sundered Hills Region", nil, nil, nil, nil },	
	{ "Throat of the World Region", nil, nil, nil, nil },
	{ "Troll's Teeth Mountains Region", nil, nil, nil, nil },
	{ "Uld Vraech Region", nil, nil, nil, nil },
	{ "Valstaag Highlands Region", nil, nil, nil, nil },
	{ "Velothi Mountains Region", -41, -29, -8, 20 },
	{ "Vorndgad Forest Region", nil, nil, nil, nil },
	{ "White Plains Region", nil, nil, nil, nil },
	{ "Wuurthal Dale Region", nil, nil, nil, nil },
	{ "Ysheim Region", nil, nil, nil, nil },
	{ "Sea of Ghosts Region", -116, -20, 21, 40 },
	{ "Sea of Ghosts Region N", -116, -10, 21, 40 },
	{ nil, -116, -20, 21, 40 },
	{ "Brodir Grove Region", nil, nil, nil, nil },
	{ "Felsaad Coast Region", nil, nil, nil, nil },
	{ "Hirstaang Forest Region", nil, nil, nil, nil },
	{ "Moesring Mountains Region", nil, nil, nil, nil },
	{ "Isinfier Plains Region", nil, nil, nil, nil },
	{ "Thirsk Region", nil, nil, nil, nil }
}

-- xcell coordinate, ycell coordinate
local kyne_intervention_cells = {
	--{-112, 11} -- Taurus Hall, as an example
}

-- actor id, destination cell id, factor to multiply baseprice by
local travel_actor_prices = {
	{ "TR_m1_DaedrothGindaman", nil, 5},
	{ "Sky_xRe_DSE_Arvund", "Karthwasten", 2.273},		-- 22 to 50
	{ "Sky_xRe_KW_Aurius", "Dragonstar East", 2.273},		-- Markarth to DS/KW prices will probably need to be gone over too
}

---@param e playGroupEventData
local function loopStridentRunnerNesting(e)
	if e.reference.baseObject.id == "T_Cyr_Fau_BirdStridN_01" and e.group == tes3.animationGroup.idle6 then
		e.loopCount = -1	-- Ordinarily idles don't loop correctly (see: Vivec) and a MWScript solution (like for Vivec) doesn't work well on a hostile creature such as the Strident Runners, but this does.
	end
end

---@param e equipEventData
local function restrictEquip(e)
	if e.reference.mobile.object.race.id == "T_Val_Imga" then
		if e.item.objectType == tes3.objectType.armor then
			if e.item.slot == tes3.armorSlot.boots then
				if e.reference.mobile == tes3.mobilePlayer then
					tes3ui.showNotifyMenu(common.i18n("main.imgaShoes"))
				end
				
				return false
			end
			
			if e.item.slot == tes3.armorSlot.helmet then
				if e.reference.mobile.object.female == false then
					if e.reference.mobile == tes3.mobilePlayer then
						tes3ui.showNotifyMenu(common.i18n("main.imgaHelm"))
					end
					
					return false
				end
			end
		end
		
		if e.item.objectType == tes3.objectType.clothing then
			if e.item.slot == tes3.clothingSlot.shoes then
				if e.reference.mobile == tes3.mobilePlayer then
					tes3ui.showNotifyMenu(common.i18n("main.imgaShoes"))
				end
				
				return false
			end
		end
	elseif e.reference.mobile.object.race.id == "T_Aka_Tsaesci" then
		if e.item.objectType == tes3.objectType.armor then
			if e.item.slot == tes3.armorSlot.boots then
				if e.reference.mobile == tes3.mobilePlayer then
					tes3ui.showNotifyMenu(common.i18n("main.tsaesciShoes"))
				end
				
				return false
			end
			
			if e.item.slot == tes3.armorSlot.greaves then
				if e.reference.mobile == tes3.mobilePlayer then
					tes3ui.showNotifyMenu(common.i18n("main.tsaesciPants"))
				end
				
				return false
			end
		end
		
		if e.item.objectType == tes3.objectType.clothing then
			if e.item.slot == tes3.clothingSlot.shoes then
				if e.reference.mobile == tes3.mobilePlayer then
					tes3ui.showNotifyMenu(common.i18n("main.tsaesciShoes"))
				end
				
				return false
			end	
			
			if e.item.slot == tes3.clothingSlot.pants then
				if e.reference.mobile == tes3.mobilePlayer then
					tes3ui.showNotifyMenu(common.i18n("main.tsaesciPants"))
				end
				
				return false
			end
		end
	end
end

---@param e bodyPartAssignedEventData
local function fixVampireHeadAssignment(e)
	if e.index == tes3.activeBodyPart.head then
		if not e.object or e.object.objectType ~= tes3.objectType.armor then
			if e.reference.mobile then
				if e.reference.mobile.object then
					if e.reference.mobile.object.baseObject.head.id == "T_B_De_UNI_HeadOrlukhTR" then	-- Handles the unique head for Varos of the Orlukh bloodline
							e.bodyPart = e.reference.mobile.object.baseObject.head
					elseif e.reference.mobile.object.baseObject.head.id == "T_B_Imp_UNI_HeadHerrius2PC" then	-- Handles the unique head for Herrius Thimistrel when he is openly a vampire
							e.bodyPart = e.reference.mobile.object.baseObject.head
					elseif e.reference.mobile.object.baseObject.head.id == "T_B_Imp_UNI_HeadHerriusPC" then	-- Handles the unique head for Herrius Thimistrel
						if e.reference.mobile.inCombat or e.reference.mobile.isDead then
							e.bodyPart = tes3.getObject("T_B_Imp_UNI_HeadHerrius2PC")
						else
							e.bodyPart = tes3.getObject("T_B_Imp_UNI_HeadHerriusPC")
						end
					end
					
					if e.reference.mobile == tes3.mobilePlayer then										-- Handles the player's head when wearing Namira's Shroud						
						if tes3.player.object:hasItemEquipped("T_Dae_UNI_RobeShroud") then		
							e.bodyPart = e.reference.mobile.object.baseObject.head
						end
					end
				end
			end
		end
	end

	if e.index == tes3.activeBodyPart.hair then
		if not e.object or e.object.objectType ~= tes3.objectType.armor then
			if e.reference.mobile then
				if e.reference.mobile.object then
					if e.reference.mobile.object.baseObject.hair.id == "T_B_Imp_UNI_HairHerriusPC" then	-- Handles the unique hair for Herrius Thimistrel
						if e.reference.mobile.inCombat or e.reference.mobile.isDead then
							e.bodyPart = tes3.getObject("T_B_Imp_UNI_HairHerrius2PC")
						else
							e.bodyPart = tes3.getObject("T_B_Imp_UNI_HairHerriusPC")
						end
					end
				end
			end
		end
	end
end

---@param e combatStartedEventData
local function vampireHeadCombatStarted(e)
	if e.actor.reference.bodyPartManager then
		if e.actor.reference.bodyPartManager:getActiveBodyPart(0, 0).bodyPart.id == "T_B_Imp_UNI_HeadHerriusPC" then
			e.actor.reference:updateEquipment()		-- Will trigger fixVampireHeadAssignment via the bodyPartAssigned event
		end
	end
end

---@param e playItemSoundEventData
local function improveItemSounds(e)
	for k,v in pairs(item_sounds) do
		local itemID, upSound, downSound, useSound = unpack(v)
		
		if e.item.id == itemID then
			if e.state == tes3.itemSoundState.up then
				tes3.playSound{ sound = upSound }
			elseif e.state == tes3.itemSoundState.down then
				tes3.playSound{ sound = downSound }
			elseif e.state == tes3.itemSoundState.consume then
				tes3.playSound{ sound = useSound }
			end
			
			return false	-- Block the vanilla behavior and stop iterating through item_sounds 
		end
	end
end

---@param e calcTravelPriceEventData
local function adjustTravelPrices(e)
	for _,v in pairs(travel_actor_prices) do
		local actorID, destinationID, factor = unpack(v, 1, 3)
		if e.reference.baseObject.id == actorID and (not destinationID or e.destination.cell.id == destinationID) then
			e.price = math.round(e.price * factor)	-- The price seems to work regardless, but I'm paranoid
			return
		end
	end
	
	if e.reference.mobile.objectType == tes3.objectType.mobileNPC then
		local providerInstance = e.reference.mobile.object
		if providerInstance.faction and string.find(providerInstance.faction.id, "Mages") and providerInstance.factionRank > 3 then	-- Increase price of teleporting between MG networks
			e.price = e.price * 5;
		end
	end
end

---@param cell tes3cell
local function isInterventionCell(cell, regionTable)
	for k,v in pairs(regionTable) do
		local regionID, xLeft, xRight, yBottom, yTop = unpack(v, 1, 5)
			if (cell.region and cell.region.id == regionID) or cell.region == regionID then
				if not xLeft then -- Checks whether cell boundaries are being used; if xLeft is nil, then all of the others should be too
					return true
				else
					if (cell.gridX >= xLeft) and (cell.gridX <= xRight) and (cell.gridY >= yBottom) and (cell.gridY <= yTop) then
						return true
					else
						return false
					end
				end
			end
	end
	
	return false
end

---@param e magicCastedEventData
local function limitInterventionMessage(e)
	for k,v in pairs(e.source.effects) do
		if v.id == tes3.effect.almsiviIntervention then
			local extCell = common.getExteriorCell(e.caster.cell)

			if not extCell or not isInterventionCell(extCell, almsivi_intervention_regions) then
				tes3ui.showNotifyMenu(common.i18n("main.rangeAlmsivi"))
			end
		elseif v.id == tes3.effect.T_intervention_Kyne then
			local extCell = common.getExteriorCell(e.caster.cell)

			if not extCell or not isInterventionCell(extCell, kyne_intervention_regions) then
				tes3ui.showNotifyMenu(common.i18n("main.rangeKyne"))
			end
		end
	end
end

---@param e spellTickEventData
local function limitIntervention(e)
	for k,v in pairs(e.source.effects) do
		if v.id == tes3.effect.almsiviIntervention then
			local cellVisitTable = { e.caster.cell }
			local extCell = common.getExteriorCell(e.caster.cell, cellVisitTable)
			
			if not extCell or not isInterventionCell(extCell, almsivi_intervention_regions) then
				return false
			end
		elseif v.id == tes3.effect.T_intervention_Kyne then
			local cellVisitTable = { e.caster.cell }
			local extCell = common.getExteriorCell(e.caster.cell, cellVisitTable)
			
			if not extCell or not isInterventionCell(extCell, kyne_intervention_regions) then
				return false
			end
		end
	end
end

-- Checks the player's race and replaces it with an animation file if one is needed. Should eventually be expanded for races such as Tsaesci, Minotaurs, etc.
local function fixPlayerAnimations()
	if tes3.player.object.race.id == "T_Els_Ohmes-raht" or tes3.player.object.race.id == "T_Els_Suthay" then
		if tes3.player.object.female == true then
			tes3.loadAnimation({ reference = tes3.player, file = "epos_kha_upr_anim_f.nif" })
		else
			tes3.loadAnimation({ reference = tes3.player, file = "epos_kha_upr_anim_m.nif" })
		end
	--elseif tes3.player.object.race.id == "T_Aka_Tsaesci"
		--tes3.loadAnimation({ reference = tes3.player, file = "pi_tsa_base_anim.nif" })
	end
end

-- Setup MCM
dofile("TamrielData.mcm")

event.register(tes3.event.loaded, function()

	event.unregister(tes3.event.determinedAction, magic.useCustomSpell)
	event.unregister(tes3.event.leveledItemPicked, magic.insightEffect)
	--event.unregister(tes3.event.magicEffectRemoved, magic.wabbajackRemovedEffect)
	--event.unregister(tes3.event.spellTick, magic.wabbajackAppliedEffect)
	event.unregister(tes3.event.spellResist, magic.radiantShieldSpellResistEffect)
	event.unregister(tes3.event.damaged, magic.radiantShieldDamagedEffect)
	event.unregister(tes3.event.magicEffectRemoved, magic.radiantShieldRemovedEffect)
	event.unregister(tes3.event.spellTick, magic.radiantShieldAppliedEffect)
	event.unregister(tes3.event.damaged, magic.reflectDamageStun)
	event.unregister(tes3.event.damagedHandToHand, magic.reflectDamageStun)
	event.unregister(tes3.event.damage, magic.reflectDamageEffect)
	event.unregister(tes3.event.damageHandToHand, magic.reflectDamageHHEffect)
	event.unregister(tes3.event.cellChanged, magic.banishDaedraCleanup)
	event.unregister(tes3.event.containerClosed, magic.deleteBanishDaedraContainer)
	event.unregister(tes3.event.magicCasted, magic.passwallEffect)

	event.unregister(tes3.event.menuEnter, reputation.switchReputation, {filter = "MenuDialog"})
	event.unregister(tes3.event.menuExit, reputation.switchReputation)
	event.unregister(tes3.event.cellChanged, reputation.travelSwitchReputation)
	event.unregister(tes3.event.uiRefreshed, reputation.uiRefreshedCallback, {filter = "MenuStat_scroll_pane"})
	event.unregister(tes3.event.menuEnter, function(e) tes3ui.updateStatsPane() end)
	
	event.unregister(tes3.event.cellChanged, weather.manageWeathers)
	event.unregister(tes3.event.weatherChangedImmediate, weather.manageWeathers)
	event.unregister(tes3.event.weatherTransitionStarted, weather.manageWeathers)
	event.unregister(tes3.event.cellChanged, weather.changeStormOrigin)
	event.unregister(tes3.event.weatherChangedImmediate, weather.changeStormOrigin)
	event.unregister(tes3.event.weatherTransitionStarted, weather.changeStormOrigin)
	event.unregister(tes3.event.soundObjectPlay, weather.silenceCreatures)
	
	event.unregister(tes3.event.playGroup, loopStridentRunnerNesting)

	event.unregister(tes3.event.equip, restrictEquip)
	event.unregister(tes3.event.bodyPartAssigned, fixVampireHeadAssignment)
	event.unregister(tes3.event.combatStarted, vampireHeadCombatStarted)
	event.unregister(tes3.event.playItemSound, improveItemSounds)
	event.unregister(tes3.event.calcTravelPrice, adjustTravelPrices)
	event.unregister(tes3.event.magicCasted, limitInterventionMessage)
	event.unregister(tes3.event.spellTick, limitIntervention)

	if config.summoningSpells == true then
		event.register(tes3.event.determinedAction, magic.useCustomSpell)
	end

	if config.interventionSpells == true then
		magic.replaceInterventionMarkers(kyne_intervention_cells, "T_Aid_KyneInterventionMarker")
	end

	if config.miscSpells == true then
		event.register(tes3.event.leveledItemPicked, magic.insightEffect)
		
		--event.register(tes3.event.magicEffectRemoved, magic.wabbajackRemovedEffect)
		--event.register(tes3.event.spellTick, magic.wabbajackAppliedEffect)

		event.register(tes3.event.spellResist, magic.radiantShieldSpellResistEffect)
		event.register(tes3.event.damaged, magic.radiantShieldDamagedEffect)
		event.register(tes3.event.magicEffectRemoved, magic.radiantShieldRemovedEffect)
		event.register(tes3.event.spellTick, magic.radiantShieldAppliedEffect)

		event.register(tes3.event.damaged, magic.reflectDamageStun)
		event.register(tes3.event.damagedHandToHand, magic.reflectDamageStun)
		event.register(tes3.event.damage, magic.reflectDamageEffect)
		event.register(tes3.event.damageHandToHand, magic.reflectDamageHHEffect)

		event.register(tes3.event.cellChanged, magic.banishDaedraCleanup)
		event.register(tes3.event.containerClosed, magic.deleteBanishDaedraContainer)
		
		event.register(tes3.event.magicCasted, magic.passwallEffect)
	end
	
	if config.provincialReputation == true then
		event.register(tes3.event.menuEnter, reputation.switchReputation, {filter = "MenuDialog"})
		event.register(tes3.event.menuExit, reputation.switchReputation)
		event.register(tes3.event.cellChanged, reputation.travelSwitchReputation)
		
		event.register(tes3.event.uiRefreshed, reputation.uiRefreshedCallback, {filter = "MenuStat_scroll_pane"})
		event.register(tes3.event.menuEnter, function(e) tes3ui.updateStatsPane() end)
	end
	
	if config.weatherChanges == true then
		weather.changeRegionWeatherChances()
		
		event.register(tes3.event.cellChanged, weather.manageWeathers)
		event.register(tes3.event.weatherChangedImmediate, weather.manageWeathers)
		event.register(tes3.event.weatherTransitionStarted, weather.manageWeathers)

		event.register(tes3.event.cellChanged, weather.changeStormOrigin)
		event.register(tes3.event.weatherChangedImmediate, weather.changeStormOrigin)
		event.register(tes3.event.weatherTransitionStarted, weather.changeStormOrigin)

		event.register(tes3.event.soundObjectPlay, weather.silenceCreatures)
	end
	
	if config.creatureBehaviors == true then
		event.register(tes3.event.playGroup, loopStridentRunnerNesting)
	end

	if config.fixPlayerRaceAnimations == true then
		fixPlayerAnimations()
	end

	if config.restrictEquipment == true then
		event.register(tes3.event.equip, restrictEquip)
	end
	
	if config.fixVampireHeads == true then
		event.register(tes3.event.bodyPartAssigned, fixVampireHeadAssignment)
		event.register(tes3.event.combatStarted, vampireHeadCombatStarted)
	end
	
	if config.improveItemSounds == true then
		event.register(tes3.event.playItemSound, improveItemSounds)
	end

	if config.adjustTravelPrices == true then
		event.register(tes3.event.calcTravelPrice, adjustTravelPrices)
	end
	
	if config.limitIntervention == true then
		event.register(tes3.event.magicCasted, limitInterventionMessage)
		event.register(tes3.event.spellTick, limitIntervention)
	end
end)