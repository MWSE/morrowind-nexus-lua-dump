---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").Combat.
-- Source: files/data/scripts/omw/combat/interface.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

---Basic combat interface
---I.Combat.addOnHitHandler(function(attack)
---end)
---@class openmw.interfaces.Combat
---@field version number
---@field ATTACK_SOURCE_TYPES openmw.interfaces.Combat.AttackSourceType Available attack source types
---@field ATTACK_TYPES openmw.interfaces.Combat.AttackType Available attack types
local Combat = {}

---@class openmw.interfaces.Combat.AttackInfo
---@field damage table A table mapping a stat name (health, fatigue, or magicka) to a number. For example, {health = 50, fatigue = 10} will cause 50 damage to health and 10 to fatigue (before adjusting for armor and difficulty). This field is ignored for failed attacks.
---@field strength number A number between 0 and 1 representing the attack strength. This field is ignored for failed attacks.
---@field successful boolean Whether the attack was successful or not.
---@field sourceType openmw.interfaces.Combat.AttackSourceType What class of attack this is.
---@field type openmw.interfaces.Combat.AttackType|nil (Optional) Attack variant if applicable. For melee attacks this represents chop vs thrust vs slash. For unarmed creatures this implies which of its 3 possible attacks were used. For other attacks this field can be ignored.
---@field attacker openmw.Object|nil (Optional) Attacking actor
---@field weapon openmw.Object|nil (Optional) Attacking weapon
---@field ammo string|nil (Optional) Ammo record ID
---@field hitPos openmw.util.Vector3|nil (Optional) Where on the victim the attack is landing. Used to spawn blood effects. Blood effects are skipped if nil.
---@field ignoreArmor boolean|nil (Optional) Whether to ignore armor.
---@field ignoreDifficulty boolean|nil (Optional) Whether to ignore difficulty scaling.
---@field muteSound boolean|nil (Optional) If true, does not play miss or damage sounds.
local AttackInfo = {}

---Table of possible attack source types
---@class openmw.interfaces.Combat.AttackSourceType
---@field Magic string
---@field Melee string
---@field Ranged string
---@field Unspecified string
local AttackSourceType = {}

---Table of possible attack types
---@class openmw.interfaces.Combat.AttackType
---@field Chop number
---@field Slash number
---@field Thrust number
local AttackType = {}

---Interface version
---@type number
Combat.version = nil

---@type openmw.interfaces.Combat.AttackSourceType
Combat.ATTACK_SOURCE_TYPES = nil

---@type openmw.interfaces.Combat.AttackType
Combat.ATTACK_TYPES = nil

---Add new onHit handler for this actor
---If `handler(attack)` returns false, other handlers for
---the call will be skipped. Where attack is the same openmw.interfaces.Combat.AttackInfo passed to #Combat.onHit
---@param handler fun(...): any The handler.
function Combat.addOnHitHandler(handler) end

---Calculates the character's armor rating and adjusts damage accordingly.
---Note that this function only adjusts the number, use #Combat.applyArmor
---to include other side effects.
---@param Damage number The numeric damage to adjust
---@param actor? openmw.Object (Optional) The actor to calculate the armor rating for. Defaults to self.
---@return number Damage adjusted for armor
function Combat.adjustDamageForArmor(Damage, actor) end

---Calculates a difficulty multiplier based on the current difficulty settings
---and adjusts damage accordingly. Has no effect if both this actor and the
---attacker are NPCs, or if both are Players.
---@param attack openmw.interfaces.Combat.AttackInfo The attack to adjust
---@param defendant? openmw.Object (Optional) The defendant to make the difficulty adjustment for. Defaults to self.
function Combat.adjustDamageForDifficulty(attack, defendant) end

---Applies this character's armor to the attack. Adjusts damage, reduces item
---condition accordingly, progresses armor skill, and plays the armor appropriate
---hit sound.
---@param attack openmw.interfaces.Combat.AttackInfo
function Combat.applyArmor(attack) end

---Computes this character's armor rating.
---Note that this interface function is read by the engine to update the UI.
---This function can still be overridden same as any other interface, but must not call any functions or interfaces that modify anything.
---@param actor? openmw.Object (Optional) The actor to calculate the armor rating for. Defaults to self.
---@return number
function Combat.getArmorRating(actor) end

---Computes this item's armor skill.
---You can override this to return any skill you wish (including non-armor skills, if you so wish).
---Note that this interface function is read by the engine to update the UI.
---This function can still be overridden same as any other interface, but must not call any functions or interfaces that modify anything.
---@param item openmw.Object The item
---@return string|nil The armor skill identifier, or unarmored if the item was nil or not an instance of openmw.types.Armor. Can return nil if unimplemented.
function Combat.getArmorSkill(item) end

---Computes the armor rating of a single piece of openmw.types.Armor, adjusted for skill
---Note that this interface function is read by the engine to update the UI.
---This function can still be overridden same as any other interface, but must not call any functions or interfaces that modify anything.
---@param item openmw.Object The item
---@param actor? openmw.Object (Optional) The actor, defaults to self
---@return number
function Combat.getSkillAdjustedArmorRating(item, actor) end

---Computes the effective armor rating of a single piece of openmw.types.Armor, adjusted for skill and item condition
---@param item openmw.Object The item
---@param actor? openmw.Object (Optional) The actor, defaults to self
---@return number
function Combat.getEffectiveArmorRating(item, actor) end

---Spawns a random blood effect at the given position
---@param position openmw.util.Vector3
function Combat.spawnBloodEffect(position) end

---Hit this actor. Normally called as Hit event from the attacking actor, with the same parameters.
---@param attackInfo openmw.interfaces.Combat.AttackInfo
function Combat.onHit(attackInfo) end

---Picks a random armor slot and returns the item equipped in that slot.
---Used to pick which armor to damage / skill to increase when hit during combat.
---@param actor? openmw.Object (Optional) The actor to pick armor from, defaults to self
---@return openmw.Object|nil The armor equipped in the chosen slot. nil if nothing was equipped in that slot.
function Combat.pickRandomArmor(actor) end

return Combat
