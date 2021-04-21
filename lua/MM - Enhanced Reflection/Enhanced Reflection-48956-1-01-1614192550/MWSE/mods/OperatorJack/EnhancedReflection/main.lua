local config = require("OperatorJack.EnhancedReflection.config")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\OperatorJack\\EnhancedReflection\\mcm.lua")
end)

local ReflectionTypes = {
  Reflect = 1,
  Normalize = 2,
}

local function log(str)
  if (config.debug == false) then return end

  str = string.format("[Enhanced Reflection Debug: %s", str)
  mwse.log(str)
  tes3.messageBox(str)
end

local function getActorsNearTargetPosition (targetPosition, distanceLimit)
  local actors = {}
  local cells = tes3.getActiveCells()

  for _, cell in pairs(cells) do
    -- Iterate through the references in the cell.
    for ref in cell:iterateReferences() do
      -- Check that the reference is a creature or NPC.
      if (ref.object.objectType == tes3.objectType.npc or
        ref.object.objectType == tes3.objectType.creature) then
        -- Check that the distance between the reference and the target point is within the distance limit. If so, save the reference.
        local distance = targetPosition:distance(ref.position)
        if (distance <= distanceLimit) then
          table.insert(actors, ref)
        end
      end
    end
  end

  return actors
end

local function isReflectingActor(reflectingActor, effect)
  log(string.format("%s is being checked for reflect.", reflectingActor))
  local isReflecting = tes3.isAffectedBy({
    reference = reflectingActor,
    effect = effect
  })

  if (isReflecting == true) then
    log(string.format("%s is reflecting.", reflectingActor))
    return true, reflectingActor, tes3.getEffectMagnitude({
      reference = reflectingActor,
      effect = effect
    })
  end
end

local function isNearReflectingActor(projectileMobile, effect)
  local distance = 160
  if (projectileMobile.position:distance(tes3.player.position) <= distance and
      projectileMobile.firingMobile ~= tes3.mobilePlayer) then
    local isReflectingActor, actor, magnitude = isReflectingActor(tes3.player, effect)
    if (isReflectingActor == true) then
      return isReflectingActor, actor, magnitude
    end
  end

  local actors = getActorsNearTargetPosition(projectileMobile.position, distance)
  for _, actor in pairs(actors) do
    if (projectileMobile.firingMobile ~= actor.mobile) then
      local isReflectingActor, actor, magnitude = isReflectingActor(actor, effect)
      if (isReflectingActor == true) then
        return isReflectingActor, actor, magnitude
      end
    end
  end

  return false
end


local projectiles = {}
local function projectileSimulate()
  for projectile, data in pairs(projectiles) do
    if (data.reflected == false) then
      local mobile = projectile.mobile
      log(string.format("%s is being processed.", mobile.reference))
      if (mobile) then
        for effect, reflectionType in pairs(data.effects) do
          local isReflecting, actor, magnitude = isNearReflectingActor(mobile, effect)
          if (isReflecting == true and config.magnitudeBasedChance == true and math.random(100) > magnitude) then
            break
          end

          if (isReflecting == true) then
            if (reflectionType == ReflectionTypes.Normalize) then
              local referencePos = actor.sceneNode.worldBoundOrigin
              local direction = (projectile.position - referencePos):normalized()
              local magnitude = projectile.sceneNode.velocity:length()
              projectiles[projectile] = {
                reversed = true,
                velocity = direction * magnitude
              }
              break  
            elseif (reflectionType == ReflectionTypes.Reflect) then
              projectiles[projectile] = {
                reversed = true,
                velocity = projectile.sceneNode.velocity * -1
              }
              break
            end
          end
        end
      end
    elseif (data.reversed == true) then
        projectile.sceneNode.velocity = data.velocity
    end
  end
end

local function onLoaded(e)
    projectiles = {}

    event.unregister("simulate", projectileSimulate)
    event.register("simulate", projectileSimulate)

    mwse.log("[Magic Mechanics - Enhanced Reflection: INFO] Initialized.")
end
event.register("loaded", onLoaded)

local function onObjectInvalidated(e)
    projectiles[e.object] = nil
end
event.register("objectInvalidated", onObjectInvalidated)

local function onMobileActivated(e)
	local mobile = e.mobile
	if (mobile == nil) then
		return
	end

  -- Is it a spell projectile? Hope so.
  local isSpell
  local continue = false

  local effects = {}
	local spellInstance = mobile.spellInstance
	if (spellInstance ~= nil) then
		isSpell = true
  end

  if (config.reflectReflects == true and isSpell == true) then
    effects[tes3.effect.reflect] = ReflectionTypes.Reflect
    continue = true
  end
  if (config.shieldReflects == true and isSpell == true) then
    effects[tes3.effect.shield] = ReflectionTypes.Normalize
    continue = true
  end
  if (config.fireShieldReflects == true and isSpell == true) then
    for _, effect in ipairs(spellInstance.source.effects) do
      if (effect.id == tes3.effect.fireDamage) then
        effects[tes3.effect.fireShield] = ReflectionTypes.Normalize
        continue = true
      end
    end
  end
  if (config.frostShieldReflects == true and isSpell == true) then
    for _, effect in ipairs(spellInstance.source.effects) do
      if (effect.id == tes3.effect.frostDamage) then
        effects[tes3.effect.frostShield] = ReflectionTypes.Normalize
        continue = true
      end
    end
  end
  if (config.shockShieldReflects == true and isSpell == true) then
    for _, effect in ipairs(spellInstance.source.effects) do
      if (effect.id == tes3.effect.shockDamage) then
        effects[tes3.effect.lightningShield] = ReflectionTypes.Normalize
        continue = true
      end
    end
  end

  if (continue == false) then
    return
  end

  log(string.format("%s mobile activated!", e.reference))
	projectiles[e.reference] = {
    reversed = false,
    reflected = false,
    effects = effects
  }
end
event.register("mobileActivated", onMobileActivated)