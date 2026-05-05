-- Distract: pulls non-player actors away from their position toward a far-side destination and returns them safely

if isPlayer then return end

local FEET_TO_UNITS = 22.1

local DISTRACT_EFFECTS = {
	["t_illusion_distractcreature"] = "creature",
	["t_illusion_distracthumanoid"] = "humanoid",
}

local DISTRACT_VOICES = {
	["Argonian"] = {
		male   = { startLines = { "sound\\vo\\a\\m\\Idl_AM001.mp3", "sound\\vo\\a\\m\\Hlo_AM056.mp3" }, endLines = { "sound\\vo\\a\\m\\Idl_AM008.mp3" } },
		female = { startLines = { "sound\\vo\\a\\f\\Idl_AF007.mp3", "sound\\vo\\a\\f\\Idl_AF004.mp3" }, endLines = { "sound\\vo\\a\\f\\Idl_AF002.mp3" } },
	},
	["Breton"] = {
		male   = { startLines = {}, endLines = {} },
		female = { startLines = { "sound\\vo\\b\\f\\Idl_BF001.mp3", "sound\\vo\\b\\f\\Idl_BF005.mp3" }, endLines = { "sound\\vo\\b\\f\\Idl_BF003.mp3" } },
	},
	["Dark Elf"] = {
		male   = { startLines = { "sound\\vo\\d\\m\\Idl_DM006.mp3", "sound\\vo\\d\\m\\Idl_DM007.mp3" }, endLines = { "sound\\vo\\d\\m\\Idl_DM008.mp3" } },
		female = { startLines = { "sound\\vo\\d\\f\\Idl_DF006.mp3" }, endLines = { "sound\\vo\\d\\f\\Idl_DF003.mp3" } },
	},
	["High Elf"] = {
		male   = { startLines = { "sound\\vo\\h\\m\\Hlo_HM056.mp3" }, endLines = { "sound\\vo\\i\\m\\Idl_HF007.mp3" } },
		female = { startLines = { "sound\\vo\\h\\f\\Hlo_HF056.mp3" }, endLines = { "sound\\vo\\i\\f\\Idl_HF007.mp3" } },
	},
	["Imperial"] = {
		male   = { startLines = { "sound\\vo\\i\\m\\Idl_IM008.mp3", "sound\\vo\\i\\m\\Idl_IM003.mp3" }, endLines = { "sound\\vo\\i\\m\\Idl_IM005.mp3" } },
		female = { startLines = { "sound\\vo\\i\\f\\Idl_IF001.mp3" }, endLines = { "sound\\vo\\i\\f\\Idl_IF009.mp3" } },
	},
	["Khajiit"] = {
		male   = { startLines = { "sound\\vo\\k\\m\\Idl_KM005.mp3", "sound\\vo\\k\\m\\Idl_KM006.mp3", "sound\\vo\\k\\m\\Idl_KM007.mp3" }, endLines = { "sound\\vo\\k\\m\\Idl_KM002.mp3", "sound\\vo\\k\\m\\Idl_KM003.mp3" } },
		female = { startLines = { "sound\\vo\\k\\f\\Idl_KF005.mp3", "sound\\vo\\k\\f\\Idl_KF006.mp3", "sound\\vo\\k\\f\\Idl_KF007.mp3" }, endLines = { "sound\\vo\\k\\f\\Idl_KF002.mp3", "sound\\vo\\k\\f\\Idl_KF003.mp3" } },
	},
	["Nord"] = {
		male   = { startLines = { "sound\\vo\\n\\m\\Idl_NM001.mp3" }, endLines = { "sound\\vo\\n\\m\\Idl_NM009.mp3" } },
		female = { startLines = { "sound\\vo\\n\\f\\Idl_NF002.mp3", "sound\\vo\\n\\f\\Idl_NF004.mp3" }, endLines = { "sound\\vo\\n\\f\\Idl_NM008.mp3" } },
	},
	["Orc"] = {
		male   = { startLines = { "sound\\vo\\o\\m\\Idl_OM001.mp3", "sound\\vo\\o\\m\\Idl_OM002.mp3" }, endLines = { "sound\\vo\\o\\m\\Idl_OM004.mp3", "sound\\vo\\o\\m\\Idl_OM009.mp3" } },
		female = { startLines = { "sound\\vo\\o\\f\\Idl_OF009.mp3" }, endLines = {} },
	},
	["Redguard"] = {
		male   = { startLines = {}, endLines = {} },
		female = { startLines = { "sound\\vo\\r\\f\\Idl_RF002.mp3", "sound\\vo\\r\\f\\Idl_RF008.mp3" }, endLines = { "sound\\vo\\r\\f\\Idl_RF003.mp3", "sound\\vo\\r\\f\\Idl_RF007.mp3" } },
	},
	["Wood Elf"] = {
		male   = { startLines = { "sound\\vo\\w\\m\\Idl_WM009.mp3" }, endLines = { "sound\\vo\\w\\m\\Idl_WM006.mp3", "sound\\vo\\w\\m\\Idl_WM007.mp3" } },
		female = { startLines = { "sound\\vo\\w\\f\\Idl_WF006.mp3", "sound\\vo\\w\\f\\Idl_WF009.mp3" }, endLines = { "sound\\vo\\w\\f\\Idl_WF003.mp3", "sound\\vo\\w\\f\\Idl_WF007.mp3" } },
	},
}


------------------------- Validity / pathing -------------------------

local function isValidTarget(effectType)
	if types.Actor.isDead(self) then return false end
	
	--if effectType == "creature" and not types.Creature.objectIsInstance(self) then return false end
	--if effectType == "humanoid" and not types.NPC.objectIsInstance(self) then return false end
	
	if saveData.distract and saveData.distract.distracted then return false end
	
	local combatTarget = I.AI.getActiveTarget("Combat")
	if combatTarget then return false end
	
	local pkg = I.AI.getActivePackage()
	if pkg and pkg.type ~= "Wander" then return false end
	
	return true
end

local function findDestination(range)
	local player = nearby.players[1]
	if not player then return nil end
	
	local agentBounds = types.Actor.getPathfindingAgentBounds(self)
	local bestPos = nil
	local bestScore = 0
	local SAMPLES = 12
	
	for i = 1, SAMPLES do
		local candidate = nearby.findRandomPointAroundCircle(self.position, range, {
			agentBounds = agentBounds,
		})
		if candidate then
			if math.abs(candidate.z - self.position.z) < 384 then
				local playerDist = (candidate - player.position):length()
				local selfDist = (candidate - self.position):length()
				
				local preScore = playerDist + selfDist * 0.25
				if preScore > bestScore * 0.8 then
					local status, path = nearby.findPath(self.position, candidate, {
						agentBounds = agentBounds,
					})
					if status == nearby.FIND_PATH_STATUS.Success then
						local minPathPlayerDist = math.huge
						for _, pt in ipairs(path) do
							local d = (pt - player.position):length()
							if d < minPathPlayerDist then minPathPlayerDist = d end
						end
						local score = playerDist * 0.25 + selfDist * 0.5 + minPathPlayerDist
						if score > bestScore then
							bestScore = score
							bestPos = candidate
						end
					end
				end
			end
		end
	end
	return bestPos
end

local function playVoiceLine(isEnd)
	if not types.NPC.objectIsInstance(self) then return end
	
	local rec = types.NPC.records[self.recordId]
	local raceRec = types.NPC.races.record(rec.race)
	local lines = DISTRACT_VOICES[raceRec.name]
	if not lines then return end
	
	local genderLines = rec.isMale and lines.male or lines.female
	if not genderLines then return end
	
	local pool = isEnd and genderLines.endLines or genderLines.startLines
	if not pool or #pool == 0 then return end
	
	local path = pool[math.random(#pool)]
	if path then
		core.sound.playSoundFile3d(path, self)
	end
end

------------------------- Distract lifecycle -------------------------

local function applyDistract(range)
	local destination = findDestination(range)
	if not destination then return end
	
	local pkg = I.AI.getActivePackage()
	local wanderIdle = nil
	if pkg and pkg.idle then
		wanderIdle = {}
		for k, v in pairs(pkg.idle) do
			wanderIdle[k] = v
		end
	end
	
	saveData.distract = {
		distracted   = true,
		returning    = false,
		originCell   = self.cell.name,
		originPos    = { self.position.x, self.position.y, self.position.z },
		originYaw    = self.rotation:getYaw(),
		hello        = types.Actor.stats.ai.hello(self).base,
		wanderDist   = pkg and pkg.distance or 0,
		wanderDur    = pkg and pkg.duration or 0,
		wanderIdle   = wanderIdle,
		wanderRepeat = pkg and pkg.isRepeat or false,
	}
	
	types.Actor.stats.ai.hello(self).base = 0
	
	if math.random() < 0.45 then playVoiceLine(false) end
	
	I.AI.startPackage{
		type = 'Travel',
		destPosition = destination,
		cancelOther = true,
		isRepeat = false,
	}
end

local function beginReturn()
	if not (saveData.distract and saveData.distract.distracted) then return end
	
	if math.random() < 0.45 then playVoiceLine(true) end
	
	local o = saveData.distract.originPos
	I.AI.startPackage{
		type = 'Travel',
		destPosition = v3(o[1], o[2], o[3]),
		cancelOther = true,
		isRepeat = false,
	}
	
	saveData.distract.returning = true
end

local function finishReturn()
	if not (saveData.distract and saveData.distract.distracted) then return end
	
	types.Actor.stats.ai.hello(self).base = saveData.distract.hello
	
	local d = saveData.distract
	local wanderOpts = {
		type = 'Wander',
		distance = d.wanderDist,
		isRepeat = d.wanderRepeat,
	}
	if d.wanderIdle then
		wanderOpts.idle = d.wanderIdle
	end
	I.AI.startPackage(wanderOpts)
	
	saveData.distract = nil
end

local function tryApply(activeSpell, entry)
	if saveData.distract and saveData.distract.distracted then return end
	if not isValidTarget(effectType) then return end
	applyDistract(entry.avgMagnitude * FEET_TO_UNITS)
end

local function pollReturn()
	if not (saveData.distract and saveData.distract.distracted) then return end
	local pkg = I.AI.getActivePackage()
	if not pkg or pkg.type ~= "Travel" then
		finishReturn()
	else
		G.scheduleJob(pollReturn, 1.0)
	end
end

if DISTRACT_EFFECTS then
	local isHuman = types.NPC.objectIsInstance(self) or self.type.record(self).type == types.Creature.TYPE.Humanoid
	for effectId, targetType in pairs(DISTRACT_EFFECTS) do
		if isHuman and targetType == "humanoid"
		or not isHuman and targetType == "creature"
		then
			G.onMgefAdded[effectId] = function(key, eff, activeSpell, entry)
				tryApply(activeSpell, entry)
			end
			
			G.onMgefTick[effectId] = function(key, eff, activeSpell, entry, dt)
				tryApply(activeSpell, entry)
			end
			
			G.onMgefRemoved[effectId] = function(key, entry)
				if not (saveData.distract and saveData.distract.distracted) then return end
				if saveData.distract.returning then return end
				beginReturn()
				G.scheduleJob(pollReturn, 1.0)
			end
		end
	end
end

G.onInactiveJobs[#G.onInactiveJobs + 1] = function()
	if not (saveData.distract and saveData.distract.distracted) then return end
	
	types.Actor.stats.ai.hello(self).base = saveData.distract.hello
	if saveData.distract then
		I.AI.startPackage({
			type = 'Wander',
			distance = saveData.distract.wanderDist,
			isRepeat = saveData.distract.wanderRepeat,
		})
	end
	local o = saveData.distract.originPos
	core.sendGlobalEvent('TD_DistractTeleportBack', {
		actor    = self.object,
		cell     = saveData.distract.originCell,
		position = v3(o[1], o[2], o[3]),
	})
	
	saveData.distract = nil
end