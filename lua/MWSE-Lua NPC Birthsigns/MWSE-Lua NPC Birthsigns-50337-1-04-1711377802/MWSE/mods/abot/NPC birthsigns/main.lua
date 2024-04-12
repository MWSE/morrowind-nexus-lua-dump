--[[
Gives birthsign abilities to NPCs, on combat start/when a follower is activated by player
as this should cover any NPC potentially using them
]]

local author = 'abot'
local modName = "NPC birthsigns"
local modPrefix = author .. '/'.. modName

local logLevel = 0 -- set it to 1 or 2 for debug logging

local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2

local blacklist = {['merz_skeleton_summon'] = 1,}

-- cached
local birthsigns
local numBirthsigns
local birthsignIndex

local tes3_spellType_spell = tes3.spellType.spell
local tes3_actorType_npc = tes3.actorType.npc

local function giveBirthsign(ref)
	local mobile = ref.mobile
	if not (mobile.actorType == tes3_actorType_npc) then
		-- 0 = creature, 1 = NPC, 2 = player
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
	local funcPrefix = string.format('%s: giveBirthsign("%s")', modPrefix, ref.id)
	if blacklist[lcId] then
		if bsi then
			ref.data.ab01BSI = nil
		end
		if logLevel1 then
			mwse.log("%s, blacklisted, skipping", funcPrefix)
		end
		return
	end
	if string.find(lcId, 'summon', 1, true)	then
		if not string.find(lcId, 'summoner', 1, true)	then
			if bsi then
				ref.data.ab01BSI = nil
			end
			if logLevel1 then
				mwse.log("%s, summon, skipping", funcPrefix)
			end
			return -- skip summons set with npc/race body
		end
	end
	if string.find(lcId, '_child', 1, true)	then
		if bsi then
			ref.data.ab01BSI = nil
		end
		if logLevel1 then
			mwse.log("%s, _child, skipping", funcPrefix)
		end
		return -- skip morrowind children
	end

	if not birthsigns then
		birthsigns = tes3.dataHandler.nonDynamicData.birthsigns
		---assert(birthsigns)
		numBirthsigns = #birthsigns
		---assert(numBirthsigns)
		---assert(numBirthsigns > 0)
	end

-- skip reference with already assigned birthsign index.
-- I know player could in theory change birthsigns midgame,
-- but oh well old valid spells will stay
	if bsi then
		birthsign = birthsigns[bsi]
		if birthsign then
			if logLevel2 then
				mwse.log('%s: "%s" birthsign already assigned',
					funcPrefix, birthsign.name)
			end
		end
		return
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
	if logLevel2 then
		mwse.log("%s", funcPrefix)
	end
	local ok = true
	local count = 0
	for _, spl in pairs(spells) do -- needs pairs
		if spl then
			if not spl.blocked then -- so you can easily block them in CS
				ok = true
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
					---if tes3.addSpell({reference = ref, spell = spl}) then
					if mwscript.addSpell({reference = ref, spell = spl}) then
						count = count + 1
						if logLevel1 then
							mwse.log('%s: "%s" birthsign spell "%s" assigned',
								funcPrefix, birthsign.name, spl.id)
						end
					elseif logLevel1 then
						mwse.log('"%s": unable to assign "%s" birthsign spell "%s"',
							funcPrefix, birthsign.name, spl.id)
					end
				end
			end
		end
	end
	if count > 0 then
		if not ref.data then
			ref.data = {}
		end
		if ref.data.birthsignIndex then
			ref.data.birthsignIndex = nil -- clean old index if any
		end
		ref.data.ab01BSI = birthsignIndex -- store assigned reference birthsign index
		ref.modified = true
		---mobile.birthsign = birthsign -- read only for now
	end
end

local function combatStart(e)
	local mobile = e.actor
	if not mobile then
		return
	end
	local ref = mobile.reference
	if ref then
		giveBirthsign(ref)
	end
end


local tes3_animationState_dead = tes3.animationState.dead
local tes3_animationState_dying = tes3.animationState.dying

local function isDead(mobile)
	if mobile.isDead then
		return true
	end
	local health = mobile.health
	if health then
		if health.current then
			if health.current < 3 then
				if health.normalized <= 0.025 then
					if health.normalized > 0 then
						health.current = 0 -- kill when nearly dead, could be a glitch
					end
				end
				if health.current <= 0 then
					return true
				end
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then -- it may happen
		return false
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == tes3_animationState_dead)
	or (animState == tes3_animationState_dying) then
		return true
	end
	return false
end

---local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

-- mobile.inCombat alone is not reliable /abot
local function inCombat(mobile)
	if mobile.inCombat then
		return true
	end
	if mobile.combatSession then
		return true
	end
	if mobile.actionData then
		if mobile.actionData.target then
			return true
		end
	end
	--[[if mobile.isAttackingOrCasting then
		return true
	end]]
	return false
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort

local function getRefVariable(ref, variableId)
	local script = ref.object.script
	if not script then
		return nil
	end
	local context = ref.context
	if not context then
		return nil
	end
	local value = context[variableId]
	if value then
		if logLevel2 then
			mwse.log('%s: getRefVariable("%s", "%s") context["%s"] = %s)',
				modPrefix, ref.id, variableId, variableId, value)
		end
		return value
	end
	return nil
end

local function getCompanion(ref)
	return getRefVariable(ref, 'companion')
end

local function isCompanion(mobRef)
	local companion = getCompanion(mobRef)
	if companion
	and (companion == 1) then
		return true
	end
	return false
end

local function activate(e)
	if not (e.activator == tes3.player) then
		return
	end
	local ref = e.target
	if not ref then
		return
	end
	local mobile = ref.mobile
	if not mobile then
		return
	end

	local actorType = mobile.actorType
	if not actorType then
		return
	end
	if not (actorType == tes3_actorType_npc) then -- 0 = creature, 1 = NPC, 2 = player
		return -- skip creatures and player
	end

	--[[ nope else scripted companions could not work
	if not ref:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- skip if use potentially blocked by script onactivate
	end
	]]

	if isDead(mobile) then
		return
	end

	if inCombat(mobile) then
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
		ok = isCompanion(ref)
	end
	if ok then
		giveBirthsign(ref)
	end

end

event.register('combatStart', combatStart, {priority = 1000})
event.register('activate', activate)
