local id = require("NecroCraft.magic.id")
local utility = require("NecroCraft.utility")
local soulGemLib = require("NecroCraft.soulgem")
local strings = require("NecroCraft.strings")

local lichdom = {}

local changedRaces = {}

local function createPlayerCorpse()
	local corpse
	if tes3.findGlobal("NC_Lichdom").value == 0 then
		corpse = tes3.getObject("NC_PlayerCorpse")
		corpse.race = tes3.player.object.race
		corpse.head = tes3.player.object.baseObject.head
		corpse.hair = tes3.player.object.baseObject.hair
		corpse.modified = true
	else
		corpse = tes3.getObject("NC_SkeletonCorpse")
	end
	tes3.removeEffects{
		reference = tes3.player,
		effect = tes3.effect.concealUndead
	}
	corpse.name = tes3.player.object.name
	corpse = tes3.createReference{object=corpse.id, position=tes3.player.position, orientation=tes3.player.orientation, cell=tes3.getPlayerCell()}
	for _, stack in pairs(tes3.player.object.inventory) do
		local equipped = mwscript.hasItemEquipped{reference = tes3.player, item = stack.object.id}
		local item = stack.object.id
		tes3.transferItem{
			from = tes3.player,
			to = corpse,
			item = item,
			count = stack.count,
			playSound = false,
			reevaluateEquipment = false
		}
		if equipped then
			corpse.mobile:equip{item=item}
		end
	end
	return corpse
end

lichdom.setPhylactery = function(reference)
	if reference.data.necroCraft and reference.data.necroCraft.phylactery then 
		return 
	end
	for _, stack in pairs(reference.object.inventory) do
		if stack.variables then
			local enchantment = stack.object.enchantment
			if enchantment and enchantment.castType == tes3.enchantmentType.constant then
				for _, effect in pairs(enchantment.effects) do
					if effect.id == tes3.effect.deathPact and effect.rangeType == tes3.effectRange.self then
						stack.variables[1].data.necroCraft = stack.variables[1].data.necroCraft or {}
						stack.variables[1].data.necroCraft.isPhylactery = true
						reference.data.necroCraft = reference.data.necroCraft or {}
						return stack.object.id
					end
				end
			end
		end
	end
end

local getPhylactery = function(reference)
	for _, stack in pairs(reference.object.inventory) do
		if stack.variables and stack.variables[1].data.necroCraft and stack.variables[1].data.necroCraft.isPhylactery then
			return stack.object.id
		end
	end
end

lichdom.ritualInterrupted = function()
	tes3.messageBox(strings.ritualInterrupted)
	local damage = -tes3.mobilePlayer.health.current
	tes3.modStatistic{reference = tes3.player, name = "health", current = damage}
end

local function updateContainer(e)
	if getPhylactery(e.reference) then
		tes3.player.data.necroCraft.phylactery.container = e.reference.id
		tes3.player.data.necroCraft.phylactery.position = {tes3.player.position.x, tes3.player.position.y, tes3.player.position.z}
		tes3.player.data.necroCraft.phylactery.cell = tostring(tes3.getPlayerCell())
		--tes3.messageBox("Phylactery container:%s", e.reference.id)
	elseif e.reference.id == tes3.player.data.necroCraft.container then
		tes3.player.data.necroCraft.phylactery.container = nil
		tes3.player.data.necroCraft.phylactery.position = nil
		tes3.player.data.necroCraft.phylactery.cell = nil
	end
end

local function onMenuExit(e)
	if not getPhylactery(tes3.player) then
		lichdom.ritualInterrupted()
	end
end

lichdom.ritualStopped = function()
	event.unregister("menuExit", onMenuExit)
end

lichdom.ritualDone = function()
	event.unregister("menuExit", onMenuExit)
	event.unregister("containerClosed", updateContainer)
	event.register("containerClosed", updateContainer)
end

lichdom.ritualBegan = function()
	event.unregister("menuExit", onMenuExit)
	event.register("menuExit", onMenuExit)
end

lichdom.changeRaceToSkeleton = function()
	for _, race in pairs(tes3.dataHandler.nonDynamicData.races) do
		if race.id == "skeletonrace" then
			tes3.player.baseObject.race = race
			tes3.player.baseObject.head = tes3.getObject("b_n_skeletonrace_m_head_01")
			tes3.player.baseObject.hair = race.maleBody.hair
			tes3.mobilePlayer.firstPersonReference.baseObject.race = race
			tes3.mobilePlayer.firstPersonReference:updateEquipment()
			tes3.player:updateEquipment()
			tes3.mobilePlayer:equip{item="nc_inventory_updater"}
			break
		end
	end
end

lichdom.changeRaceBack = function()
	local oldBody = tes3.getObject("NC_PlayerCorpse")
	tes3.player.baseObject.race = oldBody.race
	tes3.mobilePlayer.firstPersonReference.baseObject.race = oldBody.race
	tes3.player.baseObject.head = oldBody.head
	tes3.player.baseObject.hair = oldBody.hair
	tes3.mobilePlayer.firstPersonReference:updateEquipment()
	tes3.player:updateEquipment()
	tes3.mobilePlayer:equip{item="nc_inventory_updater"}
end

lichdom.playerResurrection = function()
	local cell = tes3.getCell{id = tes3.player.data.necroCraft.phylactery.cell}
	local position = tes3.player.data.necroCraft.phylactery.position
	local container = tes3.getObject(tes3.player.data.necroCraft.phylactery.container)
	tes3.positionCell{cell = cell, position = position, reference = tes3.player, teleportCompanions = false, orientation = {0,0,0}}
	mwse.log(container.id)
	tes3.mobilePlayer.chameleon = 0
	if container.inventory:contains("NC_skeleton_champ_misc") and soulGemLib.releaseSoul{reference = container, gem = "AB_Misc_SoulGemBlack"} then
		tes3.messageBox("Your resurrection started")
		tes3.removeItem{reference=container.id, item="NC_skeleton_champ_misc", playSound=false}
		local bonepile = tes3.createReference{object="NC_skeleton_war_pile", position=position, orientation=tes3.player.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = bonepile, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
		bonepile.mobile.paralyze = 1
		tes3.cast{reference = container.id, target = bonepile.id, spell = id.spell.lichResurrection}
		timer.start{
			duration = 3.09,
			callback = function()
				--tes3.runLegacyScript{command = "EnableRaceMenu"}
				timer.start{
					duration = 0.1,
					callback = function() 
						utility.safeDelete(bonepile)
						tes3.mobilePlayer.controlsDisabled = false
						--tes3.mobilePlayer.mouseLookDisabled = false
						tes3.player.scale = 1
						tes3.runLegacyScript{command = "tm"}
						tes3.runLegacyScript{command = "tgm"}
						if tes3.player.baseObject.race.id ~= "skeletonrace" then
							lichdom.changeRaceToSkeleton()
							tes3.findGlobal("NC_Lichdom").value = 1
							--[[mwscript.addSpell{reference=tes3.player, spell="NC_LichdomAbility"}
							mwscript.addSpell{reference=tes3.player, spell="NC_UndeadAbility"}]]
							mwscript.addSpell{reference=tes3.player, spell="immune to frost"}
							mwscript.addSpell{reference=tes3.player, spell="immune to poison"}
							mwscript.addSpell{reference=tes3.player, spell="immune to disease"}
							mwscript.addSpell{reference=tes3.player, spell="resist magicka_50"}
							mwscript.addSpell{reference=tes3.player, spell="resist shock_50"}
							mwscript.addSpell{reference=tes3.player, spell="resist normal weapons_50"}
							mwscript.addSpell{reference=tes3.player, spell="NC_Lich_fmm"}
							mwscript.addSpell{reference=tes3.player, spell="NC_Lich_rm"}
							mwscript.addSpell{reference=tes3.player, spell="NC_Lich_wb"}
						end
					end
				}
			end
		}
	else
		tes3.runLegacyScript{command = "tgm"}
		tes3.messageBox(strings.noMaterial)
		tes3.modStatistic{reference = tes3.player, name = "health", current = -99999}
	end
end

lichdom.playerDeath = function()
	tes3.force3rdPerson()
	local corpse = createPlayerCorpse()
	tes3.runLegacyScript{command = "tm"}
	tes3.runLegacyScript{command = "tgm"}
	timer.delayOneFrame(function() tes3.player.scale = 0 end)
	tes3.mobilePlayer.controlsDisabled = true
	tes3.removeEffects{reference = tes3.player, castType = tes3.spellType.spell}
	tes3.mobilePlayer.chameleon = 500
	timer.start{
		duration = 3,
		callback = function() lichdom.playerResurrection() end
	}
end

return lichdom