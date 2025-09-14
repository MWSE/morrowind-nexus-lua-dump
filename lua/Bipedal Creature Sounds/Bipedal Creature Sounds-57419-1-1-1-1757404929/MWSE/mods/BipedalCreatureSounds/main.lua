--[[
	Bipedal Creature Sounds v1.1
	By Kynesifnar
]]

local config = require("BipedalCreatureSounds.config")

local bipedTimers = {}

---@returns number
local function randomDuration()
	local difference = config.maximumWait - config.minimumWait
	return (math.random() * config.minimumWait) + difference
end

-- Some bipedal creatures (such as Gothren's dremora) will never play idle3 or idle4 because of how their AI is set up. This function allows them to play a sound anyways.
---@param e mwseTimerCallbackData
local function randomlyPlayMoan(e)
	if e.timer.data.reference and not (e.timer.data.reference.mobile.inCombat or e.timer.data.reference.mobile.isDead or e.timer.data.reference.mobile.isParalyzed) then
		if math.random() < (config.chance / 100) then tes3.playSound({ sound = tes3.getSoundGenerator(e.timer.data.reference.baseObject.id, tes3.soundGenType.moan).sound, reference = e.timer.data.reference }) end
		local timerInstance = timer.start({ duration = randomDuration(), iterations = 1, type = timer.simulate, callback = randomlyPlayMoan, persist = false, data = {reference = e.timer.data.reference} })
		bipedTimers[e.timer.data.reference.id] = timerInstance
	end
end

---@param e mobileDeactivatedEventData
local function onMobileDeactivated(e)
	if e.reference.tempData then
		e.reference.tempData.bipedWillPlaySound = nil
	end

	if e.reference.baseObject.objectType == tes3.objectType.creature and e.reference.baseObject.biped  then		-- Might as well perform two easy checks before going through the entire table
		if bipedTimers[e.reference.id] then
			bipedTimers[e.reference.id]:cancel()
			bipedTimers[e.reference.id] = nil
		end
	end
end

-- This function ensures that reentering a cell with an NPC that was about to play a sound will allow for it to still be affected by the addon
---@param e mobileActivatedEventData
local function onMobileActivated(e)
	if e.reference.tempData then
		e.reference.tempData.bipedWillPlaySound = nil
	end

	if e.reference.baseObject.objectType == tes3.objectType.creature and e.reference.baseObject.biped and not config.blacklist[e.reference.baseObject.id:lower()] then
		local referenceHandle = tes3.makeSafeObjectHandle(e.reference)
		timer.delayOneFrame(function()
			timer.delayOneFrame(function()						-- Waiting two frames gives time for Morrowind to run scripts on creatures that might change their behavior in a way that matters to this addon, such as Project Cyrodiil's Nacarat follower
				if not referenceHandle or not referenceHandle:valid() then
					return
				end

				local reference = referenceHandle:getObject()
				if not reference.mobile.aiPlanner or not reference.mobile.aiPlanner:getActivePackage().idles then
					if tes3.getSoundGenerator(reference.baseObject.id, tes3.soundGenType.moan) then
						local timerInstance = timer.start({ duration = randomDuration(), iterations = 1, type = timer.simulate, callback = randomlyPlayMoan, persist = false, data = {reference = reference} })
						bipedTimers[reference.id] = timerInstance
					end
				end
			end)
		end)
	end
end

-- mobileActivated is not triggered when loading a game, so another function is needed to cover that case
---@param e cellChangedEventData
local function checkMobilesOnLoad(e)
	if not e.previousCell then
		for _,cell in pairs(tes3.getActiveCells()) do
			for creature in cell:iterateReferences(tes3.objectType.creature, false) do
				if creature.baseObject.objectType == tes3.objectType.creature and creature.baseObject.biped and not config.blacklist[creature.baseObject.id:lower()] then
					local referenceHandle = tes3.makeSafeObjectHandle(creature)
					timer.delayOneFrame(function()
						timer.delayOneFrame(function()
							if not referenceHandle or not referenceHandle:valid() then
								return
							end

							local reference = referenceHandle:getObject()
							if not reference.mobile.aiPlanner or not reference.mobile.aiPlanner:getActivePackage().idles then
								if tes3.getSoundGenerator(reference.baseObject.id, tes3.soundGenType.moan) then
									local timerInstance = timer.start({ duration = randomDuration(), iterations = 1, type = timer.simulate, callback = randomlyPlayMoan, persist = false, data = {reference = reference} })
									bipedTimers[reference.id] = timerInstance
								end
							end
						end)
					end)
				end
			end
		end
	end
end

---@param e attackEventData
local function playAttackRoar(e)
	if e.reference.mobile and e.reference.mobile.actorType == tes3.actorType.creature and e.reference.baseObject.biped and not config.blacklist[e.reference.baseObject.id:lower()] then
		if (e.reference.animationData and e.reference.animationData.animGroupSoundGenCounts[tes3.animationGroup.weaponOneHand + 1] == 0 and e.reference.animationData.animGroupSoundGenCounts[tes3.animationGroup.weaponTwoHand + 1] == 0 and e.reference.animationData.animGroupSoundGenCounts[tes3.animationGroup.weaponTwoWide + 1] == 0 and e.reference.animationData.animGroupSoundGenCounts[tes3.animationGroup.handToHand + 1] == 0) then
			local roarSoundGen = tes3.getSoundGenerator(e.reference.baseObject.id, tes3.soundGenType.roar)
			if roarSoundGen and roarSoundGen.sound and math.random() < (config.roarChance / 100) then tes3.playSound({ sound = roarSoundGen.sound, reference = e.reference }) end
		end
	end
end

---@param e playGroupEventData
local function playIdleMoan(e)
	if e.reference.mobile and e.reference.mobile.actorType == tes3.actorType.creature and e.reference.baseObject.biped and not config.blacklist[e.reference.baseObject.id:lower()] then
		if (e.group == tes3.animationGroup.idle3 and e.animationData.animGroupSoundGenCounts[tes3.animationGroup.idle3 + 1] == 0) or (e.group == tes3.animationGroup.idle4 and e.animationData.animGroupSoundGenCounts[tes3.animationGroup.idle4 + 1] == 0 and e.reference.mobile.aiPlanner:getActivePackage().idles[2].chance == 0) then	-- idle4 is used as a fallback if there is no chance of idle3
			local groupNumber
			if e.group == tes3.animationGroup.idle3 then groupNumber = tes3.animationGroup.idle3 else groupNumber = tes3.animationGroup.idle4 end

			local moanSoundGen = tes3.getSoundGenerator(e.reference.baseObject.id, tes3.soundGenType.moan)
			if moanSoundGen and moanSoundGen.sound then
				if e.reference.tempData.bipedWillPlaySound then return end	-- This prevents a creature from playing a sound multiple times in a single loop of the animation, which could happen in some cases (e.g. it briefly attacks and is then calmed)
				e.reference.tempData.bipedWillPlaySound = true

				local animationGroup = e.animationData.animationGroups[groupNumber + 1]
				local referenceHandle = tes3.makeSafeObjectHandle(e.reference)

				timer.start({ duration = (animationGroup.actionTimings[animationGroup.actionCount] - animationGroup.actionTimings[1]) / 2, persist = false, callback = function(t)
					if not referenceHandle or not referenceHandle:valid() then
						return
					end

					local reference = referenceHandle:getObject()
					e.reference.tempData.bipedWillPlaySound = nil
					if table.contains(e.animationData.currentAnimGroups, groupNumber) and not reference.mobile.isParalyzed then	-- I'm not certain whether paralysis needs to be checked fpr, but I might as well do so
						tes3.playSound({ sound = moanSoundGen.sound, reference = reference })		-- Ensures that the creature is still loaded and playing an acceptable idle
					end
				end})
			end
		end
	end
end

dofile("BipedalCreatureSounds.mcm")

event.register(tes3.event.loaded, function()
	if config.enabled == true then
		event.register(tes3.event.mobileDeactivated, onMobileDeactivated, { unregisterOnLoad = true })
		event.register(tes3.event.mobileActivated, onMobileActivated, { unregisterOnLoad = true })
		event.register(tes3.event.cellChanged, checkMobilesOnLoad, { unregisterOnLoad = true })
		event.register(tes3.event.attack, playAttackRoar, { unregisterOnLoad = true })
		event.register(tes3.event.playGroup, playIdleMoan, { unregisterOnLoad = true })
	end
end)