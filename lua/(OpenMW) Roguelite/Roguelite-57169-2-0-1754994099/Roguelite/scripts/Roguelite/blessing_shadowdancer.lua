sneakThrottle = 0
useFlipFlop = false


-- SHADOW DANCER
local function calculateSpeedIncrease(npc)
    -- GMST Werte holen
    local fMinWalkSpeed = core.getGMST("fMinWalkSpeed")
    local fMaxWalkSpeed = core.getGMST("fMaxWalkSpeed")
    local fEncumberedMoveEffect = core.getGMST("fEncumberedMoveEffect")
    local fSneakSpeedMultiplier = core.getGMST("fSneakSpeedMultiplier")
    local fAthleticsRunBonus = core.getGMST("fAthleticsRunBonus")
    local fBaseRunMultiplier = core.getGMST("fBaseRunMultiplier")
    local fEncumbranceStrMult = core.getGMST("fEncumbranceStrMult")
    
    -- Aktuelle Werte
    local currentSpeed = types.NPC.stats.attributes.speed(npc).modified
    local athletics = types.NPC.stats.skills.athletics(npc).modified
    local strength = types.NPC.stats.attributes.strength(npc).modified
    local encumbrance = types.Actor.getEncumbrance(npc)
    
    -- Encumbrance berechnen (wie im C++ Code)
    local fEncumbranceStrMult = core.getGMST("fEncumbranceStrMult")
    local capacity = strength * fEncumbranceStrMult
    
    local normalizedEncumbrance = 0
    if encumbrance > 0 and capacity > 0 then
        normalizedEncumbrance = encumbrance / capacity
    elseif encumbrance > 0 and capacity == 0 then
        normalizedEncumbrance = 1.0
    end
    
    local sneaking = true -- Sneaking aktiviert für Sneak-zu-Run Vergleich
    
    -- Aktuelle walkSpeed berechnen
    local function calculateWalkSpeed(speedAttribute)
        local walkSpeed = fMinWalkSpeed + 0.01 * speedAttribute * (fMaxWalkSpeed - fMinWalkSpeed)
        walkSpeed = walkSpeed * (1.0 - fEncumberedMoveEffect * normalizedEncumbrance)
        walkSpeed = math.max(0.0, walkSpeed)
        if sneaking then
            walkSpeed = walkSpeed * fSneakSpeedMultiplier
        end
        return walkSpeed
    end
    
    -- Für die RunSpeed-Berechnung wird NICHT geschlichen
    local function calculateRunSpeed(speedAttribute)
        local walkSpeed = fMinWalkSpeed + 0.01 * speedAttribute * (fMaxWalkSpeed - fMinWalkSpeed)
        walkSpeed = walkSpeed * (1.0 - fEncumberedMoveEffect * normalizedEncumbrance)
        walkSpeed = math.max(0.0, walkSpeed)
        -- KEIN Sneaking-Multiplikator hier!
        return walkSpeed * (0.01 * athletics * fAthleticsRunBonus + fBaseRunMultiplier)
    end
    
    -- Ziel: sneakSpeed(newSpeed) = runSpeed(currentSpeed) 
    -- Aber runSpeed wird OHNE Sneaking berechnet!
    local targetRunSpeed = calculateRunSpeed(currentSpeed)
    
    -- Gleichung lösen für Sneaking:
    -- sneakSpeed = walkSpeed * fSneakSpeedMultiplier = targetRunSpeed
    -- walkSpeed = targetRunSpeed / fSneakSpeedMultiplier
    -- fMinWalkSpeed + 0.01 * newSpeed * (fMaxWalkSpeed - fMinWalkSpeed) = targetRunSpeed / fSneakSpeedMultiplier
    
    local targetWalkSpeed = targetRunSpeed / fSneakSpeedMultiplier
    local requiredSpeed = (targetWalkSpeed - fMinWalkSpeed) / (0.01 * (fMaxWalkSpeed - fMinWalkSpeed))
    
    -- Encumbrance berücksichtigen (walkSpeed wird durch Encumbrance reduziert)
    if normalizedEncumbrance > 0 then
        requiredSpeed = requiredSpeed / (1.0 - fEncumberedMoveEffect * normalizedEncumbrance)
    end
    
    local speedIncrease = requiredSpeed - currentSpeed
    return speedIncrease
end
local lastFatigueTick = nil

-- SHADOW DANCER
table.insert(onFrameJobs, function(dt)
	if saveData.runId then
		if saveData.blessings and saveData.blessings.sneak then
			local now = core.getRealTime()
			local isSneaking = self.controls.sneak
			local isSwimming = types.Actor.isSwimming(self)
			if isSneaking and not isSwimming and lastFatigueTick then
				local movement = math.abs(math.max(self.controls.movement, self.controls.sideMovement))
				types.Actor.stats.dynamic.fatigue(self).current = math.max(0,types.Actor.stats.dynamic.fatigue(self).current -2*(now-lastFatigueTick)*movement)
			end
			if isSneaking and not saveData.speedMod and not isSwimming then
				if core.getRealTime() > sneakThrottle then
					local speedMod = calculateSpeedIncrease(self)
					--print(speedMod)
					types.NPC.stats.attributes.speed(self).base = types.NPC.stats.attributes.speed(self).base + speedMod
					saveData.speedMod = speedMod
				end
			elseif (isSwimming or not isSneaking) and saveData.speedMod then
				types.NPC.stats.attributes.speed(self).base = types.NPC.stats.attributes.speed(self).base - saveData.speedMod
				saveData.speedMod = nil
			end
			lastFatigueTick = now
		end
	end
end)

-- SHADOW DANCER
input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	if saveData.blessings and saveData.blessings.sneak then
		if useFlipFlop and not use and types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
			sneakThrottle = core.getRealTime()+1
			if saveData.speedMod then
				types.NPC.stats.attributes.speed(self).base = types.NPC.stats.attributes.speed(self).base - saveData.speedMod
				saveData.speedMod = nil
			end
		end
		useFlipFlop = use
	end
	return use
end), {  })