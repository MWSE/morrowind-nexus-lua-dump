local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

tes3.claimSpellEffectId("slowTime", 402)
tes3.claimSpellEffectId("annihilate", 403)
tes3.claimSpellEffectId("firesOfOblivion", 404)
tes3.claimSpellEffectId("spawnChair", 405)

-- Slow Time Effect --
local timeShift = false
local function onSimulate()
    if (timeShift) then
        tes3.worldController.deltaTime = tes3.worldController.deltaTime * timeShift
    end
end

local function onSlowTimeTick(e)
	-- Trigger into the spell system.
	if (not e:trigger()) then
		return
	end

	if (timeShift ~= false  and e.effectInstance.state == tes3.spellState.cast) then
		tes3.messageBox("A time manipulation effect is already active.")
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	if (timeShift == false) then
		common.debug("Slow Time Effect: Slowing time.")

		local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.slowTime)
		local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)

		event.register("simulate", onSimulate)
		timeShift = 1.01 - (magnitude / 100)
	end

	if (e.effectInstance.state == tes3.spellState.ending) then		
		common.debug("Slow Time Effect: Removing Slow time.")
		event.unregister("simulate", onSimulate)
		timeShift = false
	end
end

local function addSlowTimeEffect()
	framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.slowTime,
		name = "Slow Time",
		description = "Slows time by 50%.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = false,
        allowSpellmaking = false,
        canCastSelf = true,
        nonRecastable = false,

		-- Graphics/sounds.
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSlowTimeTick,
	})
end
-------------------------------------------------

-- Annihilate Effect --
local function onAnnihilateTick(e)
	-- Trigger into the spell system.
	if (not e:trigger()) then
		return
	end

	e.effectInstance.target.mobile:applyHealthDamage(999999)
	
    e.effectInstance.state = tes3.spellState.retired
end

local function addAnnihilateEffect()
	framework.effects.destruction.createBasicEffect({
		-- Base information.
		id = tes3.effect.annihilate,
		name = "Annihilate",
		description = "Instantly kills anything that it touches.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = false,
        allowSpellmaking = false,
		hasNoMagnitude = true,
		hasNoDuration = true,
		canCastTouch = true,
		canCastTarget = true,
        nonRecastable = false,

		-- Graphics/sounds.
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onAnnihilateTick,
	})
end
-------------------------------------------------

-- Fires of Oblivion Effect --
local function onFiresOfOblivionCollision(e)
	if (e.collision) then
		local caster = e.sourceInstance.caster
		local distance = e.collision.point:distance(caster.position)
		local iterations = distance / 30

		local currentPosition = caster.position:copy()
		local targetPosition = e.collision.point:copy()

		local fires = {}
		timer.start({
			iterations = iterations,
			duration = .1,
			callback = function()
				local fire = tes3.createReference({
					object = common.data.objectIds.firesOfOblivion,
					position = currentPosition,
					cell = caster.cell
				})

				fires[fire] = true

				for activeFire, state in pairs(fires) do
					if (state) then
						local actors = common.getActorsNearTargetPosition(caster.cell, activeFire.position, 150)

						for _, actor in pairs(actors) do
							if (actor ~= caster) then
								tes3.messageBox("Fires of Oblivion: Damaging Actor.")
								actor.mobile:applyHealthDamage(50)
							end
						end

						if (tes3.player ~= caster and tes3.player:distance(caster.position) <= 150) then
							tes3.messageBox("Fires of Oblivion: Damaging Player.")
							tes3.mobilePlayer:applyHealthDamage(50)
						end
					end
				end

				currentPosition = currentPosition + ((targetPosition - currentPosition):normalized() * 30)

				timer.start({
					iterations = 1,
					duration = 1,
					callback = function()
						fires[fire] = nil

						fire:disable()

						timer.delayOneFrame({
							callback = function()
								fire.deleted = true
							end
						})
					end
				})
			end
		})
	end
end

local function addFiresOfOblivionEffect()
	framework.effects.destruction.createBasicEffect({
		-- Base information.
		id = tes3.effect.firesOfOblivion,
		name = "Fires of Oblivion",
		description = "Sends fires from Oblivion exploding from the ground towards the target.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		canCastTouch = true,
		canCastTarget = true,
		nonRecastable = false,
		isHarmful = true,
		hasContinuousVFX = true,

		-- Graphics/sounds.
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onCollision = onFiresOfOblivionCollision,
	})
end
-------------------------------------------------

-- Fires of Oblivion Effect --
local function onSpawnChairCollision(e)
	if (e.collision) then
		local caster = e.sourceInstance.caster
		local targetPosition = e.collision.point:copy()

		tes3.createReference({
			object = "furn_de_r_chair_03",
			position = targetPosition,
			cell = caster.cell
		})
	end
end

local function addSpawnChairEffect()
	framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.spawnChair,
		name = "Spawn Chair",
		description = "Through the power of CHIM, spawns a chair on target.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = false,
        allowSpellmaking = false,
		hasNoMagnitude = true,
		hasNoDuration = true,
		canCastTouch = true,
		canCastTarget = true,
        nonRecastable = false,

		-- Graphics/sounds.
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onCollision = onSpawnChairCollision,
	})
end
-------------------------------------------------
event.register("magicEffectsResolved", addSlowTimeEffect)
event.register("magicEffectsResolved", addAnnihilateEffect)
event.register("magicEffectsResolved", addFiresOfOblivionEffect)
event.register("magicEffectsResolved", addSpawnChairEffect)