--[[
Gives birthsign abilities to NPCs, on combat start/when a follower is activated by player
as this should cover any NPC potentially using them
]]

local author = 'abot'
local modName = "NPC birthsigns"
local modPrefix = author .. '/'.. modName

local logLevel = 0 -- 0 = disabled, 1 = enabled

local blacklist = {
['merz_skeleton_summon'] = 1,
}

-- cached
local birthsigns
local numBirthsigns
local birthsignIndex

local tes3_spellType_spell = tes3.spellType.spell

local function giveBirthsign(ref)
	assert(ref)
	local mobile = ref.mobile
	assert(mobile)
	---assert(mobile.actorType)
	if not (mobile.actorType == 1) then -- 0 = creature, 1 = NPC, 2 = player
		return -- skip creatures and player
	end
	local birthsign = mobile.birthsign
	if birthsign then
		return
	end
	local lcId = string.lower(ref.id)
	local bsi
	if ref.data then
		bsi = ref.data.ab01BSI
	end
	if blacklist[lcId] then
		if bsi then
			ref.data.ab01BSI = nil
		end
		if logLevel > 0 then
			mwse.log("%s: giveBirthsign() ref = %s, blacklisted, skipping", modPrefix, ref.id)
		end
		return
	end
	if string.find(lcId, 'summon', 1, true)	then
		if not string.find(lcId, 'summoner', 1, true)	then
			if bsi then
				ref.data.ab01BSI = nil
			end
			if logLevel > 0 then
				mwse.log("%s: giveBirthsign() ref = %s, summon, skipping", modPrefix, ref.id)
			end
			return -- skip summons set with npc/race body
		end
	end
	if string.find(lcId, '_child', 1, true)	then
		if bsi then
			ref.data.ab01BSI = nil
		end
		if logLevel > 0 then
			mwse.log("%s: giveBirthsign() ref = %s, child, skipping", modPrefix, ref.id)
		end
		return -- skip morrowind children
	end

-- skip reference with already assigned birthsign index. I know player could in theory
-- change birthsigns midgame, but oh well old valid spells will stay
	if bsi then
		return
	end

	if not birthsigns then
		birthsigns = tes3.dataHandler.nonDynamicData.birthsigns
		---assert(birthsigns)
		numBirthsigns = table.size(birthsigns)
		---assert(numBirthsigns)
		---assert(numBirthsigns > 0)
	end

	if birthsignIndex then
		if birthsignIndex < numBirthsigns then
			birthsignIndex = birthsignIndex + 1
		else
			birthsignIndex = 1
		end
	else
		birthsignIndex = math.random(numBirthsigns)
	end
	birthsign = birthsigns[birthsignIndex]
	local spells = birthsign.spells
	---assert(spells)
	if logLevel > 0 then
		mwse.log("%s: giveBirthsign() ref = %s", modPrefix, ref.id)
	end
	local ok
	for spl in tes3.iterate(spells.iterator) do
		if not spl.blocked then -- so you can easily block them in CS
			if spl.castType == tes3_spellType_spell then
				if spl.alwaysSucceeds then
					if spl.name == "Beggar's Nose" then
						ok = false
					---elseif spl.magickaCost == 5 then
						---spl.magickaCost = 35
					end
				end
			end
			if ok then
				if logLevel > 0 then
					mwse.log("%s: %s birthsign spell %s assigned to %s", modPrefix, birthsign.name, spl.id, ref.id)
				end
				mwscript.addSpell({reference = ref, spell = spl})
			end
		end
	end
	local data = ref.data
	if data then
		if data.birthsignIndex then
			ref.data.birthsignIndex = nil -- clean old index if any
		end
		ref.data.ab01BSI = birthsignIndex -- store assigned reference birthsign index
	end
	---mobile.birthsign = birthsign -- read only for now
end

local function combatStart(e)
	giveBirthsign(e.actor.reference)
end


local AS_DEAD = tes3.animationState.dead
local AS_DYING = tes3.animationState.dying

local function isMobileDead(mobile)
	local health = mobile.health
	if health then
		if health.current then
			if health.current <= 0 then
				return true
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then
		return false -- it may happen
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == AS_DEAD)
	or (animState == AS_DYING) then
		return true
	end
	return false
end

---local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort

local function activate(e)
	if not (tes3.player == e.activator) then
		return -- skip if not activated by player
	end
	local ref = e.target
	local mobile = ref.mobile
	if not mobile then
		return
	end

	local actorType = mobile.actorType
	if not actorType then
		return
	end
	if not (actorType == 1) then -- 0 = creature, 1 = NPC, 2 = player
		return -- skip creatures and player
	end

	--[[ nope else scripted companions could not work
	if not ref:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- skip if use potentially blocked by script onactivate
	end
	]]

	if isMobileDead(mobile) then
		return
	end

	if mobile.inCombat then
		return
	end

	local ai = tes3.getCurrentAIPackageId(mobile)
	if not ai then
		return
	end

	local ok = false
	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		ok = true
	else
		local context = ref.context
		if context then
			local companion = context.companion
			if companion then
				ok = true
			end
		end
	end
	if ok then
		giveBirthsign(ref)
	end

end

event.register('combatStart', combatStart)
event.register('activate', activate)

