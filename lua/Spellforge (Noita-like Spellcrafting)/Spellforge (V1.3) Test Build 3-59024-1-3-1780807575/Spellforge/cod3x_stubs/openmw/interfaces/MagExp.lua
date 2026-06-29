---@meta

-- Sidecar LuaLS stub for Spell Framework Plus' public MagExp interface.

---@class openmw.interfaces
---@field MagExp openmw.interfaces.MagExp

---@class openmw.interfaces.MagExp
local MagExp = {}

---@class openmw.interfaces.MagExp.LaunchData
---@field attacker any?
---@field spellId string?
---@field itemObject any?
---@field casterLinked boolean?
---@field startPos any?
---@field direction any?
---@field hitObject any?
---@field isFree boolean?
---@field userData table?
---@field muteAudio boolean?
---@field muteLight boolean?
---@field speed number?
---@field maxSpeed number?
---@field minSpeed number?
---@field accelerationExp number?
---@field forceVec any?
---@field maxLifetime number?
---@field spawnOffset any?
---@field isPaused boolean?
---@field bounceEnabled boolean?
---@field bounceMax number?
---@field bouncePower number?
---@field piercing boolean?
---@field pierceLimit number?
---@field detonateOnActorHit boolean?
---@field impactImpulse number?
---@field areaVfxRecId string?
---@field areaVfxScale number?
---@field vfxRecId string?
---@field boltModel string?
---@field hitModel string?
---@field boltSound string?
---@field boltLightId string?
---@field spinSpeed number?
---@field muteCastGlow boolean?
---@field continuousVfx boolean?
---@field excludeTarget any?
---@field forcedEffects table?
---@field spellType string|number?
---@field area number?
---@field unreflectable boolean?
---@field nonRecastable boolean?
---@field itemRequirements table?

---@class openmw.interfaces.MagExp.PhysicsData
---@field speed number?
---@field maxSpeed number?
---@field minSpeed number?
---@field accelerationExp number?
---@field forceVec any?
---@field maxLifetime number?
---@field bounceEnabled boolean?
---@field bounceMax number?
---@field bouncePower number?
---@field piercing boolean?
---@field pierceLimit number?
---@field detonateOnActorHit boolean?

---@class openmw.interfaces.MagExp.MagicHitInfo
---@field projectile any?
---@field proj any?
---@field spellProjectile any?
---@field projectile_id string|number?
---@field projectileId string|number?
---@field proj_id string|number?
---@field projId string|number?
---@field spellId string?
---@field attacker any?
---@field victim any?
---@field hitPos any?
---@field position any?
---@field cell any?
---@field userData table?
---@field impactSpeed number?
---@field maxSpeed number?
---@field velocity any?
---@field magMin number?
---@field magMax number?
---@field casterLinked boolean?
---@field stackLimit number?
---@field stackCount number?

---@class openmw.interfaces.MagExp.ProjectileBounceInfo
---@field projectile any?
---@field projectile_id string|number?
---@field projectileId string|number?
---@field proj_id string|number?
---@field projId string|number?
---@field position any?
---@field normal any?
---@field hitObject any?
---@field bounceCount number?
---@field userData table?

---@class openmw.interfaces.MagExp.ProjectilePierceInfo
---@field projectile any?
---@field projectile_id string|number?
---@field projectileId string|number?
---@field proj_id string|number?
---@field projId string|number?
---@field hitObject any?
---@field pierceCount number?
---@field pierceLimit number?
---@field userData table?

---@param data openmw.interfaces.MagExp.LaunchData
---@return any
function MagExp.launchSpell(data) end

---@param data openmw.interfaces.MagExp.LaunchData
---@return any
function MagExp.emitProjectileFromObject(data) end

---@param spellId string
---@param caster any
---@param target any
---@param hitPos any?
---@param isAoe boolean?
---@param item any?
---@return any
function MagExp.applySpellToActor(spellId, caster, target, hitPos, isAoe, item) end

---@param spellId string
---@param caster any
---@param position any
---@param cell any
---@param itemObject any?
---@param forcedEffects table?
---@param unreflectable boolean?
---@param casterLinked boolean?
---@param vfxOverride string?
---@param impactSpeed number?
---@param maxSpeed number?
---@param areaVfxScale number?
---@param excludeTarget any?
---@param userData table?
---@param muteAudio boolean?
---@param muteLight boolean?
---@return any
function MagExp.detonateSpellAtPos(spellId, caster, position, cell, itemObject, forcedEffects, unreflectable, casterLinked, vfxOverride, impactSpeed, maxSpeed, areaVfxScale, excludeTarget, userData, muteAudio, muteLight) end

---@return table
function MagExp.getActiveSpellIds() end

---@param projId string|number
---@param tag string?
---@return any
function MagExp.getSpellState(projId, tag) end

---@param projId string|number
---@param data openmw.interfaces.MagExp.PhysicsData
---@return any
function MagExp.setSpellPhysics(projId, data) end

---@param projId string|number
---@param direction any
---@return any
function MagExp.redirectSpell(projId, direction) end

---@param projId string|number
---@param speed number
---@return any
function MagExp.setSpellSpeed(projId, speed) end

---@param projId string|number
---@param paused boolean
---@return any
function MagExp.setSpellPaused(projId, paused) end

---@param projId string|number
---@return any
function MagExp.cancelSpell(projId) end

---@param projId string|number
---@param enabled boolean
---@param max number?
---@param power number?
---@return any
function MagExp.setSpellBounce(projId, enabled, max, power) end

---@param projId string|number
---@param enabled boolean
---@param newLimit number?
---@return any
function MagExp.setSpellPiercing(projId, enabled, newLimit) end

---@param projId string|number
---@param enabled boolean
---@return any
function MagExp.setSpellDetonateOnActor(projId, enabled) end

---@param fn fun(...): any
---@return any
function MagExp.addTargetFilter(fn) end

---@param fn fun(...): any
---@return any
function MagExp.setTargetFilter(fn) end

return MagExp
