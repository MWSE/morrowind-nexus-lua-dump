local undead = require("NecroCraft.undead")
local id = require("NecroCraft.magic.id")
local utility = require("NecroCraft.utility")

local aiAction = {}

local function prepareCorpse(ref)
	local utype = undead.getType(ref.object.baseObject)
	local cell = tes3.getPlayerCell()
	local new = nil
	if utype == "npc" then
		utype = "bonewalker"
	end
	if utype == "skeletonCripple" then
		new = tes3.createReference{object = "NC_skeleton_weak_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	elseif utype == "skeletonWarrior" or utype == "skeletonChampion" then
		new = tes3.createReference{object = "NC_skeleton_war_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	elseif utype == "bonewalker" then 
		new = tes3.createReference{object="NC_bonewalker_corpse", position=ref.position, orientation=ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.deathKnockOut, startFlag = tes3.animationStartFlag.immediate}
		new.data.necroCraft = {}
		new.data.necroCraft.name = ref.data.necroCraft and ref.data.necroCraft.name or ref.object.name
		if ref.data.necroCraft and ref.data.necroCraft.resurrectionCount then
			new.data.necroCraft.resurrectionCount = ref.data.necroCraft.resurrectionCount + 1
		else
			new.data.necroCraft.resurrectionCount = 0
		end
	elseif utype == "greaterBonewalker" then
		new = tes3.createReference{object="NC_bonewalkerG_corpse", position=ref.position, orientation=ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.deathKnockOut, startFlag = tes3.animationStartFlag.immediate}
		new.data.necroCraft = {}
		new.data.necroCraft.name = ref.data.necroCraft and ref.data.necroCraft.name or ref.object.name
		if ref.data.necroCraft and ref.data.necroCraft.resurrectionCount then
			new.data.necroCraft.resurrectionCount = ref.data.necroCraft.resurrectionCount + 1
		else
			new.data.necroCraft.resurrectionCount = 0
		end
	elseif utype == "bonespider" then
		new = tes3.createReference{object = "NC_bonespider_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
	elseif utype == "bonelord" then
		new = tes3.createReference{object = "NC_bonelord_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	elseif utype == "boneoverlord" then
		new = tes3.createReference{object = "NC_boneoverlord_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	end
	if new then
		new.mobile.paralyze = 1
		for _, stack in pairs(ref.object.inventory) do
			tes3.transferItem{from=ref, to=new, item=stack.object, count=stack.count, playSound=false}
		end
		utility.safeDelete(ref)
		return new
	end
end

local function prepareSkeleton(ref)
	local utype = undead.getType(ref.object.baseObject)
	local cell = tes3.getPlayerCell()
	local new = nil
	if utype == "npc" then
		utype = "skeleton"
	end
	if utype == "bonelord" then
		utype = "bonespider"
	end
	if utype == "skeletonCripple" then
		new = tes3.createReference{object = "NC_skeleton_weak_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	elseif utype == "skeletonWarrior" or utype == "skeletonChampion" then
		new = tes3.createReference{object = "NC_skeleton_war_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
	elseif utype == "bonespider" then
		new = tes3.createReference{object = "NC_bonespider_pile", position = ref.position, orientation = ref.orientation, cell=tes3.getPlayerCell()}
		-- tes3.playAnimation{reference = new, group = tes3.animationGroup.knockOut, startFlag = tes3.animationStartFlag.immediateLoop}
		tes3.playAnimation{reference = new, group=tes3.animationGroup.idle, startFlag=tes3.animationStartFlag.normal}
	end
	if new then
		new.mobile.paralyze = 1
		for _, stack in pairs(ref.object.inventory) do
			tes3.transferItem{from=ref, to=new, item=stack.object, count=stack.count, playSound=false}
		end
		utility.safeDelete(ref)
		return new
	end
end

local function getSpellToRaise(necromancer, creature)
	local utype = undead.getType(undead.pileToRaised(creature)) or undead.getType(undead.corpseToRaised(creature))
	if utype == "skeletonCripple" then
		if necromancer.object.spells:contains(id.spell.raiseSkeleton1) then
			return id.spell.raiseSkeleton1
		elseif necromancer.object.spells:contains(id.spell.raiseSkeleton2) then
			return id.spell.raiseSkeleton2
		elseif necromancer.object.spells:contains(id.spell.raiseSkeleton3) then
			return id.spell.raiseSkeleton3
		end
	elseif utype == "skeletonWarrior" then
		if necromancer.object.spells:contains(id.spell.raiseSkeleton2) then
			return id.spell.raiseSkeleton2
		elseif necromancer.object.spells:contains(id.spell.raiseSkeleton3) then
			return id.spell.raiseSkeleton3
		end
	elseif utype == "skeletonChampion" then
		if necromancer.object.spells:contains(id.spell.raiseSkeleton3) then
			return id.spell.raiseSkeleton3
		end
	elseif utype == "bonewalker" then
		if necromancer.object.spells:contains(id.spell.raiseCorpse1) then
			return id.spell.raiseCorpse1
		elseif necromancer.object.spells:contains(id.spell.raiseCorpse2) then
			return id.spell.raiseCorpse2
		elseif necromancer.object.spells:contains(id.spell.raiseCorpse3) then
			return id.spell.raiseCorpse3
		end
	elseif utype == "greaterBonewalker" then
		if necromancer.object.spells:contains(id.spell.raiseCorpse2) then
			return id.spell.raiseCorpse2
		elseif necromancer.object.spells:contains(id.spell.raiseCorpse3) then
			return id.spell.raiseCorpse3
		end
	elseif utype == "bonespider" then
		if necromancer.object.spells:contains(id.spell.raiseBonespider) then
			return id.spell.raiseBonespider
		elseif necromancer.object.spells:contains(id.spell.raiseBonelord) then
			return id.spell.raiseBonelord
		elseif necromancer.object.spells:contains(id.spell.raiseBoneoverlord) then
			return id.spell.raiseBoneoverlord
		end
	elseif utype == "bonelord" then
		if necromancer.object.spells:contains(id.spell.raiseBonelord) then
			return id.spell.raiseBonelord
		elseif necromancer.object.spells:contains(id.spell.raiseBoneoverlord) then
			return id.spell.raiseBoneoverlord
		end
	elseif utype == "boneoverlord" then
		if necromancer.object.spells:contains(id.spell.raiseBoneoverlord) then
			return id.spell.raiseBoneoverlord
		end
	end
end

local function deepCopy (to, from)
	for k, v in pairs(from) do
		to[k] = v
	end
end

local function restoreCombat(reference, actors)
	for _, actor in pairs(actors) do
		actor = actor.object.id
		mwscript.startCombat{reference = actor, target = reference}
	end
end

aiAction.cast = function(params)
	caster = params.caster
	spell = params.spell
	target = params.target
	if not caster.data.necroCraft then
		caster.data.necroCraft = {}
	end
	spell = spell.id and spell or tes3.getObject(spell)
	if tes3.isAffectedBy{reference = caster, effect = tes3.effect.silence} or caster.mobile.magicka.current < spell.magickaCost then
		return
	end
	caster.data.necroCraft.fightCasting = caster.mobile.fight
	local hostileActors = {}
	deepCopy(hostileActors, caster.mobile.hostileActors)
	caster.mobile.fight = 0
	timer.start{
		duration = 0.1,
		callback = function()
			mwscript.stopCombat{reference = caster}
			timer.start{
				duration = 0.4,
				callback = function()
					if target then
						tes3.cast{reference = caster, target = target, spell = spell}
					else
						mwscript.explodeSpell{reference = caster, spell = spell}
					end
				end
			}
			timer.start{
				duration = 0.5,
				callback = function()
					if target then
						tes3.cast{reference = caster, target = target, spell = spell}
					else
						mwscript.explodeSpell{reference = caster, spell = spell}
					end
				end
			}
			timer.start{
				duration = 0.6,
				callback = function()
					if target then
						tes3.cast{reference = caster, target = target, spell = spell}
					else
						mwscript.explodeSpell{reference = caster, spell = spell}
					end
					tes3.modStatistic{reference = caster, name = "magicka", current = (-1 * spell.magickaCost)}
					timer.start{
						duration = 0.9,
						callback = function()
							caster.mobile.fight = caster.data.necroCraft.fightCasting
							caster.data.necroCraft.fightCasting = nil
							restoreCombat(caster, hostileActors)
						end
					}
				end
			}
		end
	}
end

aiAction.raiseAll = function(necromancer)
	local found = nil
	for npc in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
		if npc.mobile.isDead then
			if mwscript.getDistance{reference = necromancer, target = npc} < 500 then
				prepareCorpse(npc)
			end
		end
	end
	for cr in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do
		if cr.mobile.isDead then
			if mwscript.getDistance{reference = necromancer, target = cr} < 500 then
				prepareCorpse(cr)
			end
		elseif undead.isReadyToBeRaised(cr) then
			if mwscript.getDistance{reference = necromancer, target = cr} < 1000 then
				if not found then
					found = cr
				end
			end
		end
	end
	if found then
		aiAction.cast{caster = necromancer, spell = id.spell.massReanimation}
	end
end

aiAction.raiseAllSkeletons = function(necromancer)
	local found = nil
	for cr in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do
		if cr.mobile and cr.mobile.isDead then
			if mwscript.getDistance{reference = necromancer, target = cr} < 500 then
				prepareSkeleton(cr)
			end
		elseif undead.isReadyToBeRaised(cr) then
			if mwscript.getDistance{reference = necromancer, target = cr} < 1000 then
				local utype = undead.getType(undead.pileToRaised(cr))
				if utype == "skeletonWarrior" or utype == "skeletonChampion" or utype == "skeletonCripple" or utype == "bonespider" then
					if not found then
						found = cr
					end
				end
			end
		end
	end
	if found then
		aiAction.cast{caster = necromancer, spell = id.spell.massSkeletal}
	end
end

aiAction.raiseSkeleton = function(necromancer)
	local found = nil
	local spell = nil
	for cr in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do
		if undead.isReadyToBeRaised(cr) then
			if mwscript.getDistance{reference = necromancer, target = cr} < 200 then
				spell = getSpellToRaise(necromancer, cr)
				if spell then
					found = cr
					break
				else
					mwse.log("[NecroCraft]: AI Action: No valid spell was found to raise %s by %s", cr, necromancer)
				end
			end
		elseif cr.mobile.isDead then
			if mwscript.getDistance{reference = necromancer, target = cr} < 200 then
				found = prepareSkeleton(cr)
				if found then
					spell = getSpellToRaise(necromancer, found)
					if not spell then
						found = nil
						mwse.log("[NecroCraft]: AI Action: No valid spell was found to raise %s by %s", cr, necromancer)
					end
					break
				end
			end
		end
	end
	if found then
		aiAction.cast{caster = necromancer, spell = spell, target = found}
	end
end

aiAction.raise = function(necromancer)
	local found = nil
	local spell = nil
	for npc in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
		if npc.mobile and npc.mobile.isDead then
			if mwscript.getDistance{reference = necromancer, target = npc} < 200 then
				prepareCorpse(npc)
			end
		end
	end
	for cr in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do
		if cr.mobile and cr.mobile.isDead then
			if mwscript.getDistance{reference = necromancer, target = cr} < 200 then
				found = prepareCorpse(cr)
				if found then
					spell = getSpellToRaise(necromancer, found)
					if not spell then
						found = nil
						mwse.log("[NecroCraft]: AI Action: No valid spell was found to raise %s by %s", cr, necromancer)
					end
					break
				end
			end
		elseif undead.isReadyToBeRaised(cr) then
			if mwscript.getDistance{reference = necromancer, target = cr} < 200 then
				spell = getSpellToRaise(necromancer, cr)
				if spell then
					found = cr
					break
				else
					mwse.log("[NecroCraft]: AI Action: No valid spell was found to raise %s by %s", cr, necromancer)
				end
			end
		end
	end
	if found then
		aiAction.cast{caster = necromancer, spell = spell, target = found}
	end
end

return aiAction