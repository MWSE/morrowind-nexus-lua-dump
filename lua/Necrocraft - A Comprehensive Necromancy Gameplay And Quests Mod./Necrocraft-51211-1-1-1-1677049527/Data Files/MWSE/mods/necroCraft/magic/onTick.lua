local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")
local utility = require("NecroCraft.utility")
local undead = require("NecroCraft.undead")
local soulGemLib = require("NecroCraft.soulgem")
local strings = require("NecroCraft.strings")
local lichdom = require("NecroCraft.lichdom")
local common = require("NecroCraft.common")

local onTick = {}


local function feintDeathEnd(target)
	target.mobile.paralyze = 0
	tes3.playAnimation{reference = target, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	tes3.playAnimation{reference = target, group = tes3.animationGroup.idle2}
	target.data.necroCraft.feintDeath = nil
	timer.start{
		duration = 1.7,
		callback = function()
			tes3.playAnimation{reference = target, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal} 
		end
	}
end 

local function feintDeathBegin(target)
	target.data.necroCraft = target.data.necroCraft or {}
	if target.data.necroCraft.feintDeath == nil then
		target.data.necroCraft.feintDeath = target.mobile.health.current
		tes3.playAnimation{reference=target, group=tes3.animationGroup.death1, startFlag = tes3.animationStartFlag.immediate}
		target.mobile.paralyze = 1
	end
end

onTick.feintDeath = function(e)
	local target = e.effectInstance.target
	if e.effectInstance.state == tes3.spellState.beginning then
		timer.delayOneFrame(function() feintDeathBegin(target) end)
	elseif e.effectInstance.state == tes3.spellState.ending then
		feintDeathEnd(target)
	end
	if (not e:trigger()) then
		return
	end
end

onTick.concealUndead = function(e)
	local target = e.effectInstance.target
	if target.mobile == tes3.mobilePlayer then
		-- Only setting and unsetting global variable for dialogues and visuals for player
		-- All the other behaviour is in onDetectUndead
		local lichdomStatus = tes3.findGlobal("NC_Lichdom")
		if e.effectInstance.state == tes3.spellState.beginning then
			if lichdomStatus.value == 1 then
				lichdomStatus.value = -1
				lichdom.changeRaceBack()
			else
				return
			end
		elseif e.effectInstance.state == tes3.spellState.ending then
			if lichdomStatus.value == -1 then
				lichdomStatus.value = 1
				lichdom.changeRaceToSkeleton()
			end
		end
	end
	if (not e:trigger()) then
		return
	end
end

onTick.darkRitual = function(e)
	local caster = e.sourceInstance.caster
	local target = e.effectInstance.target
	if e.effectInstance.state == tes3.spellState.beginning then
		tes3.playAnimation{reference=target, group=tes3.animationGroup.knockDown, startFlag = tes3.animationStartFlag.immediate}
		timer.start{
			duration = 3.5,
			callback = function()
				tes3.playAnimation{reference=target} 
			end
		}
		local phylactery = lichdom.setPhylactery(target)
		if phylactery then
			tes3.messageBox(strings.ritualBegan, tes3.getObject(phylactery).name)
			lichdom.ritualBegan()
		else
			tes3.messageBox(strings.ritualFailed)
			e.effectInstance.state = tes3.spellState.retired
		end
	elseif e.effectInstance.state == tes3.spellState.ending then
		local effect = magickaExpanded.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.darkRitual)
		if e.effectInstance.timeActive == effect.duration then
			tes3.messageBox(strings.ritualEnd)
			tes3.player.data.necroCraft.phylactery = {}
			lichdom.ritualDone()
		else
			lichdom.ritualInterrupted()
		end
	end
	if (not e:trigger()) then
		return
	end
end


local function communeFromGem(reference, soulgem, soulData)
	tes3.findGlobal("NC_DeadTalk").value = 1
	local soul = soulData.data.soulGemLib and soulData.data.soulGemLib.id or soulData.soul
	local npcRef = tes3.createReference{object = soul, position = {0,0,0}, orientation={0,0,0}, cell="toddtest"}
	npcRef.mobile:startDialogue()
	timer.start{
		duration = 0.1,
		callback = function()
			tes3.findGlobal("NC_DeadTalk").value = 0
			tes3.addItem{reference=reference, soul=soul, item=soulgem}
			utility.safeDelete(npcRef)
		end
	}
end

onTick.communeDead = function(e)
	local target = e.effectInstance.target
	local caster = e.sourceInstance.caster
	if (not e:trigger()) then
		return
	end
	local soulData = soulGemLib.releaseSoul{reference=target, restoreGem=false, gem="NC_SoulGem_AzuraB"}
	if soulData then
		communeFromGem(target, "NC_SoulGem_AzuraB", soulData)
	else
		local soulData = soulGemLib.releaseSoul{reference=target, restoreGem=false, gem="AB_Misc_SoulGemBlack"}
		if soulData then
			communeFromGem(target, "AB_Misc_SoulGemBlack", soulData)
		else
			tes3.messageBox(strings.noBlackGem)
		end
	end
	e.effectInstance.state = tes3.spellState.retired
end

onTick.spreadDisease = function(e)
	-- Trigger into the spell system.
	local target = e.effectInstance.target
	local caster = e.sourceInstance.caster
	local diseasesTable = {
		"swamp fever",
		"yellow tick",
		"wither",
		"witbane",
		"swamp fever",
		"serpiginous dementia",
		"rust chancre",
		"rockjoint",
		"rattles",
		"helljoint",
		"greenspore",
		"droops",
		"dampworm",
		"collywobbles",
		"crimson_plague",
		"chills",
		"brown rot",
		"ataxia"
	}
	if (not e:trigger()) then
		return
	end
	local resistance = target.mobile.resistCommonDisease
	local rand = math.random(1, 100)
	if rand > resistance then
		rand = math.random(1, #diseasesTable)
		local disease = tes3.getObject(diseasesTable[rand])
		if not target.object.spells:contains(disease) then
			if target == tes3.player then 
				tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicContractDisease).value, disease.name)
			else
				tes3.messageBox(strings.contractDisease, target.object.name, disease.name)
			end
		end
		mwscript.addSpell{reference=target, spell=disease}
	else
		tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicTargetResisted).value)
	end
	e.effectInstance.state = tes3.spellState.retired
end

local function callMinion(params)

	local e = params.e
	local utype = params.type
	local failMessage = params.failMessage
	
	local target = e.effectInstance.target
	local caster = e.sourceInstance.caster
	if (not e:trigger()) then
		return
	end
	
	local found = nil
	
	for minion, _ in pairs(tes3.player.data.necroCraft.minions[utype]) do
		minion = tes3.getReference(minion)
		if minion then
			if minion.mobile then
				if minion.mobile.playerDistance > 2000 or tes3.getCurrentAIPackageId(minion.mobile) < 1 then --mwscript.getDistance{reference = minion, target = caster}
					found = minion
					break
				end
			else
				found = minion
				break
			end
		end
	end
	
	if found then
		tes3.triggerCrime({
            criminal = caster,
            type = tes3.crimeType.killing,
            value = common.config.bountyValue
        })
		local appearEffect = utility.placeInFront(caster, "NC_Appear_Effect", 150)
		tes3.positionCell{cell = tes3.getPlayerCell(), position = appearEffect.position, reference = found, orientation = {0, 0, 0}}
		tes3.setAIFollow{reference = found, target = caster}
	else
	  tes3.messageBox(failMessage)
	end
	e.effectInstance.state = tes3.spellState.retired

end

local function raiseSkeleton(caster, target, raised)
	local cell = tes3.getPlayerCell()
	target.mobile.paralyze = 0
	tes3.modStatistic{reference = target, name = "fatigue", current = -2000}
	timer.start({
		duration = 0.1,
		callback = function()
			tes3.modStatistic{reference = target, name = "fatigue", current = 2000}
			tes3.playAnimation{reference = target, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
			--tes3.runLegacyScript{command = "playGroup Idle", reference=target}
			--tes3.playSound{sound = "UN_SKeletonArise", reference = e.effectInstance.target.object}
			timer.start{
				duration = 3.1, 
				callback = function()
					raised = utility.replace(target, raised, cell)
					if caster then
						undead.handleFollow(caster, raised)
					end
				end
			}
		end
	})
end

local function raiseBoneconstruct(caster, target, raised)
	local cell = tes3.getPlayerCell()
	tes3.playAnimation{reference=target, group=tes3.animationGroup.idle3, startFlag=tes3.animationStartFlag.normal}
	timer.start{
		duration = 3, 
		callback = function()
			if string.endswith(raised.id, "lord") then
				utility.placeInFront(target, "NC_Appear_Effect", 0)
			end
			raised = utility.replace(target, raised, cell)
			if caster then
				undead.handleFollow(caster, raised)
			end
		end
	}
end

local function raiseCorpse(caster, target, raised)
	local cell = tes3.getPlayerCell()
	tes3.playAnimation{reference = target, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	timer.start {
		duration = 0.5,
		callback = function()
			tes3.playAnimation{reference = target, group = tes3.animationGroup.idle2, startFlag=tes3.animationStartFlag.normal}
			timer.start{
				duration = 3.1, 
				callback = function()
					raised = utility.replace(target, raised, cell)
					if caster then
						undead.handleFollow(caster, raised)
					end
				end
			}
		end
	}
end

local function raiseUndead(params)
	local e = params.e
	local effect = params.effect
	local utype = params.type
	local func = params.func
	local effect
	
	local target = e.effectInstance.target
	local caster = e.sourceInstance.caster
	local cell = tes3.getPlayerCell()
	local raised = nil
	
	if (not e:trigger()) then
		return
	end
	
	if (e.effectInstance.target.object.type ~= tes3.creatureType.undead) then
		e.effectInstance.state = tes3.spellState.retired
		return
	end
	
	if utype == "corpse" then
		raised = undead.corpseToRaised(target)
		effect = tes3.effect.raiseCorpse
	else
		raised = undead.pileToRaised(target)
		if utype == "boneconstruct" then
			effect = tes3.effect.raiseBoneConstruct
		else
			effect = tes3.effect.raiseSkeleton
		end
	end
	
	if not raised or (string.startswith(utype, "skeleton") and not string.startswith(raised.id, "NC_skeleton")) or (utype == "boneconstruct" and not string.startswith(raised.id, "NC_bone")) then
		e.effectInstance.state = tes3.spellState.retired
		return
	end
	
	effect = magickaExpanded.functions.getEffectFromEffectOnEffectEvent(e, effect)
	local magnitude = magickaExpanded.functions.getCalculatedMagnitudeFromEffect(effect)
	
	if not target.data.necroCraft then
		target.data.necroCraft = {}
	end
	
	local rC = target.data.necroCraft.resurrectionCount or 0
	
	if (e.effectInstance.target.object.level + rC > magnitude) then
		tes3.messageBox(strings.raiseFail.."%s", e.effectInstance.target.baseObject.name)
		e.effectInstance.state = tes3.spellState.retired
		return
	end
	
	if e.effectInstance.target.object.level >= 8 then
		if not soulGemLib.releaseSoul{reference=caster, gem="AB_Misc_SoulGemBlack"} and not soulGemLib.releaseSoul{reference=caster, gem="NC_SoulGem_AzuraB"} then
			tes3.messageBox(strings.noBlackGem)
			e.effectInstance.state = tes3.spellState.retired
			return
		end
	end
	
	tes3.triggerCrime({
		criminal = caster,
		type = tes3.crimeType.killing,
		value = common.config.bountyValue
	})
	if caster then
		target.data.necroCraft.isBeingRaised = caster.id
	end

	target.orientation = tes3vector3.new(0, 0, target.orientation.z)
	target:updateSceneGraph()

	func(caster, target, raised)

end

onTick.callSkeletonCripple = function(e)
	callMinion{e = e, type = "skeletonCripple", failMessage = strings.noSkeletonCripple}
end

onTick.callSkeletonWarrior = function(e)
	callMinion{e = e, type = "skeletonWarrior", failMessage = strings.noSkeletonWarrior}
end

onTick.callSkeletonChampion = function(e)
	callMinion{e = e, type = "skeletonChampion", failMessage = strings.noSkeletonChampion}
end

onTick.callBoneSpider = function(e)
	callMinion{e = e, type = "bonespider", failMessage = strings.noBonespider}
end

onTick.callBonelord = function(e)
	callMinion{e = e, type = "bonelord", failMessage = strings.noBonelord}
end

onTick.callBoneoverlord = function(e)
	callMinion{e = e, type = "boneoverlord", failMessage = strings.noBoneoverlord}
end

onTick.callBonewalker = function(e)
	callMinion{e = e, type = "bonewalker", failMessage = strings.noBonewalker}
end

onTick.callGreaterBonewalker = function(e)
	callMinion{e = e, type = "greaterBonewalker", failMessage = strings.noGreaterBonewalker}
end

onTick.raiseSkeleton = function(e)
	raiseUndead{e=e, type = "skeleton", func = raiseSkeleton}
end

onTick.raiseBoneConstruct = function(e)
	raiseUndead{e=e, type = "boneconstruct", func = raiseBoneconstruct}
end

onTick.raiseCorpse = function(e)
	raiseUndead{e=e, type = "corpse", func = raiseCorpse}
end

return onTick