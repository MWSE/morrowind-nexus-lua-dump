local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local anim = require('openmw.animation')
local I = require('openmw.interfaces')
local Actor = types.Actor
local Player = types.Player
local time = require('openmw_aux.time')

-- Cached actor references
local actorEffects = Actor.activeEffects(self)
local actorSpells = Actor.activeSpells(self)
local actorFatigue = Actor.stats.dynamic.fatigue(self)
local actorLuck = Actor.stats.attributes.luck(self)
local fMinWalkSpeed
local fMaxWalkSpeed
local fMinWalkSpeedCreature
local fMaxWalkSpeedCreature

-- Element definitions
local ELEMENTS = {
	fire = {
		shield = 'fireshield',
		vfx = 'meshes/kurp/s/vfx_k_h_sfire.nif',
		castVfx = 'meshes/kurp/s/vfx_k_c_sfire.nif',
		castVfxRev = 'meshes/kurp/s/vfx_k_c_sfire_rev.nif',
	},
	frost = {
		shield = 'frostshield',
		vfx = 'meshes/kurp/s/vfx_k_h_sice.nif',
		castVfx = 'meshes/kurp/s/vfx_k_c_sice.nif',
		castVfxRev = 'meshes/kurp/s/vfx_k_c_sice_rev.nif',
	},
	lightning = {
		shield = 'lightningshield',
		vfx = 'meshes/kurp/s/vfx_k_h_ssho.nif',
		castVfx = 'meshes/kurp/s/vfx_k_c_ssho.nif',
		castVfxRev = 'meshes/kurp/s/vfx_k_c_ssho_rev.nif',
	},
	normal = {
		shield = 'shield',
		vfx = 'meshes/kurp/s2/ShieldHit.nif',
		hitVfx = 'meshes/kurp/s2/h/hand01_pshield.nif',
		castVfx = nil,
		castVfxRev = 'meshes/kurp/s2/ShieldOnHit.nif',
	},
}



-- Track active VFX
local activeVfx = {}
for _, element in pairs(ELEMENTS) do
	activeVfx[element.shield] = false
end

local fatigueBeforeKnockdown
local fatigueRevertTimerStopFunction

local slowMagnitude
local slowTimerStopFunction
local oldSlow = 0

-- Calculate how much to subtract from Speed attribute to reduce movement speed
local function calculateSpeedReduction(actor, reductionPercent)
    local isNpc = actor.type == types.NPC
    local currentSpeed = types.Actor.stats.attributes.speed(actor).modified + oldSlow
    local minSpeed = 5
    local reducibleSpeed = math.max(0, currentSpeed - minSpeed)
	
    fMinWalkSpeed = fMinWalkSpeed or core.getGMST("fMinWalkSpeed")
    fMaxWalkSpeed = fMaxWalkSpeed or core.getGMST("fMaxWalkSpeed")
    fMinWalkSpeedCreature = fMinWalkSpeedCreature or core.getGMST("fMinWalkSpeedCreature")
    fMaxWalkSpeedCreature = fMaxWalkSpeedCreature or core.getGMST("fMaxWalkSpeedCreature")
	
    local fMin, fMax
    if isNpc then
        fMin = fMinWalkSpeed
        fMax = fMaxWalkSpeed
    else
        fMin = fMinWalkSpeedCreature
        fMax = fMaxWalkSpeedCreature
    end
	
    local reduction = (reductionPercent / 100) * reducibleSpeed + reductionPercent * fMin / (fMax - fMin)
	
    return math.min(math.floor(reduction), reducibleSpeed)
end

local function addStackedEffect(effects, spellId, magnitude, name)
    if math.random() < magnitude % 1 then
        magnitude = magnitude + 1
    end
    magnitude = math.floor(magnitude)
    
    if magnitude < 1 then return end
    
    local effectIndexes = {}
    while magnitude >= 1 do
        local effectIndex = math.max(0, math.min(19, magnitude - 1))
        table.insert(effectIndexes, effectIndex)
        magnitude = magnitude - 20
    end
    
    table.insert(effects, {
        id = spellId,
        effects = effectIndexes,
        stackable = true,
        name = name,
    })
end

local function repeatedSlowApplication()
	if not slowMagnitude then
		slowTimerStopFunction()
		slowTimerStopFunction = nil
		return
	end
	
	-- remove old effects
	local foundSlow = false
	for _, spell in pairs(actorSpells) do
		if spell.id == 'bes_eleshield_slow' then
			actorSpells:remove(spell.activeSpellId)
			foundSlow = true
		end
	end
	if not foundSlow then
		oldSlow = 0
	end
	
	-- add fresh effects
	local effects = {}
	local newSlow = calculateSpeedReduction(self, slowMagnitude)

	addStackedEffect(effects, 'BES_eleshield_slow', newSlow, 'Elemental Shield Slow')
	for _, effect in pairs(effects) do
		actorSpells:add(effect)
	end
	oldSlow = newSlow
	slowMagnitude = nil
end

-- Check AI packages for hostile intent towards player
local function isHostile()
	local hostile = false
	I.AI.forEachPackage(function(p)
		if p.target and Player.objectIsInstance(p.target)
		and (p.type == "Combat" or p.type == "Pursue") then
			hostile = true
		end
	end)
	return hostile
end

local function revertFatigue()
	if fatigueBeforeKnockdown then
		actorFatigue.current = fatigueBeforeKnockdown
		fatigueBeforeKnockdown = nil
	end
	if fatigueRevertTimerStopFunction then
		fatigueRevertTimerStopFunction()
		fatigueRevertTimerStopFunction = nil
	end
end

-- Handle receiving elemental shield damage from a player we attacked
local function onElementalShieldDamage(data)
	-- If onlyHostile is set, only apply damage if this actor is hostile
	if data.onlyHostile and not fatigueRevertTimerStopFunction and not isHostile() then
		return
	end
	
	if data.stun then
		local term = math.max(0, actorEffects:getEffect("resistshock").magnitude / 100 
			+ actorEffects:getEffect("lightningshield").magnitude / 100 
			- data.stun / 20) -- magnitude of the shield
		local chance = 0.5^term
		chance = chance - (actorLuck.modified - 35) / 150
		chance = chance + (data.luck - 35) / 100
		if math.random() < chance then
			if fatigueRevertTimerStopFunction then
				fatigueRevertTimerStopFunction()
			else
				fatigueBeforeKnockdown = actorFatigue.current
			end
			actorFatigue.current = -100
			fatigueRevertTimerStopFunction = time.runRepeatedly(revertFatigue, 2 * time.second, { 
				type = time.SimulationTime, 
				initialDelay = 2 * time.second 
			})
		end
	end
	slowMagnitude = slowMagnitude or data.slow
	if slowMagnitude and not slowTimerStopFunction then
		slowTimerStopFunction = time.runRepeatedly(repeatedSlowApplication, 1 * time.second, { 
			type = time.SimulationTime, 
			initialDelay = 0.1 * time.second 
		})
	end
	-- Add the damage spell as an active effect on this actor
	for _, effect in pairs(data.effects) do
		actorSpells:add(effect)
	end
	
	-- Play VFX on the attacker if provided
	if data.vfx then
		anim.addVfx(self, data.vfx)
	end
end

local function removeAllVfx()
	for _, element in pairs(ELEMENTS) do
		if activeVfx[element.shield] then
			anim.removeVfx(self, 'eleshield_' .. element.shield)
			activeVfx[element.shield] = false
		end
	end
end

local function updateVfx()
	for _, element in pairs(ELEMENTS) do
		local effect = actorEffects:getEffect(element.shield)
		local hasShield = effect.magnitude > 0
		
		if hasShield and not activeVfx[element.shield] then
			local vfxId = 'eleshield_' .. element.shield
			if element.castVfx then
				anim.addVfx(self, element.castVfx, {})
			end
			anim.addVfx(self, element.vfx, {
				loop = true,
				vfxId = vfxId,
			})
			activeVfx[element.shield] = true
		elseif not hasShield and activeVfx[element.shield] then
			local vfxId = 'eleshield_' .. element.shield
			anim.removeVfx(self, vfxId)
			if element.castVfxRev then
				anim.addVfx(self, element.castVfxRev, {})
			end
			activeVfx[element.shield] = false
		end
	end
end

-- Called when this actor becomes inactive (leaves active cell)
local function onInactive()
	revertFatigue()
	removeAllVfx()
	core.sendGlobalEvent('ElementalShields_unhookActor', {
		actor = self
	})
end

local function onLoad()
	stopTimerFn2 = time.runRepeatedly(updateVfx, 1 * time.second, {
		type = time.SimulationTime,
		initialDelay = 0.25 + math.random()
	})
end

return {
	engineHandlers = {
		onInactive = onInactive,
		onLoad = onLoad,
		onInit = onLoad,
	},
	eventHandlers = {
		ElementalShields_damage = onElementalShieldDamage,
	}
}