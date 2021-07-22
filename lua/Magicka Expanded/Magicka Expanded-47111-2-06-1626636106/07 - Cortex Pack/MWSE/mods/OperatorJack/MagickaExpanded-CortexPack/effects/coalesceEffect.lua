local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("coalesce", 333)

local function isProjectileUsingCoalesceFunc(spellInstance)
	local isProjectileUsingCoalesce = false

	for i = 0, 6 do
		if (spellInstance.source.effects[i] and spellInstance.source.effects[i].id == tes3.effect.coalesce) then
			isProjectileUsingCoalesce = true
		end
	end

	return isProjectileUsingCoalesce
end

local actives = {}
local function projectileTimerCallback()
	for reference, _ in pairs(actives) do
		local mobile = reference.mobile
		if (mobile) then
			if (mobile.flags ~= 108) then
				mobile.position = mobile.position + tes3.getPlayerEyeVector() * 15
			end
		end
    end
end

local projectileTimer = nil
local function onLoaded(e)
	projectileTimer = timer.start({
		iterations = -1,
		duration = .01,
		callback = projectileTimerCallback
	})
end
event.register("loaded", onLoaded)

local function onObjectInvalidated(e)
    actives[e.object] = nil
end
event.register("objectInvalidated", onObjectInvalidated)

local function onMobileActivated(e)
	local mobile = e.mobile
	if (mobile == nil) then
		return
	end

	local spellInstance = mobile.spellInstance
	if (spellInstance == nil) then
		return
	end

	if (isProjectileUsingCoalesceFunc(spellInstance) == true) then
		actives[e.reference] = true
	end
end
event.register("mobileActivated", onMobileActivated)

local function Coalesce()
	framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.coalesce,
		name = "Coalesce",
		description = "When present in a spell, gives the caster control over the spell projectile during projectile flight.",

		-- Basic dials.
		baseCost = 5.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastTouch = true,
        canCastTarget = true,
        hasNoMagnitude = true,
		hasNoDuration = true,
		appliesOnce = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_crt_coalesce.dds",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
end

event.register("magicEffectsResolved", Coalesce)