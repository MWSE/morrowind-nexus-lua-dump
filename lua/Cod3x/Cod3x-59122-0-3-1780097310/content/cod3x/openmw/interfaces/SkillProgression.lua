---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").SkillProgression.
-- Source: files/data/scripts/omw/skillhandlers.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: player

---Allows to extend or override built-in skill progression mechanics.
----- Make jail time hurt sneak skill instead of benefitting it
---I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
---end)
----- Forbid increasing destruction skill past 50
---I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
---end)
----- Scale sneak skill progression based on active invisibility effects
---I.SkillProgression.addSkillUsedHandler(function(skillid, params)
---end)
---@class openmw.interfaces.SkillProgression
---@field version number
---@field SKILL_USE_TYPES openmw.interfaces.SkillProgression.SkillUseType Available skill usage types
---@field SKILL_INCREASE_SOURCES openmw.interfaces.SkillProgression.SkillLevelUpSource
local SkillProgression = {}

---Table of all existing sources for skill increases. Any sources not listed below will be treated as equal to Trainer.
---If there are no handlers, then there won't be any effect, so skip calculations
---Make a copy so we don't change the caller's table
---Compute use value if it was not supplied directly
---If there are no handlers, then there won't be any effect, so skip calculations
---@class openmw.interfaces.SkillProgression.SkillLevelUpSource
---@field Book string book
---@field Jail string jail
---@field Trainer string trainer
---@field Usage string usage
local SkillLevelUpSource = {}

---Table of skill use types defined by Morrowind.
---Each entry corresponds to an index into the available skill gain values
---of a openmw.core.SkillRecord
---@class openmw.interfaces.SkillProgression.SkillUseType
---@field Armor_HitByOpponent number 0
---@field Block_Success number 0
---@field Spellcast_Success number 0
---@field Weapon_SuccessfulHit number 0
---@field Alchemy_CreatePotion number 0
---@field Alchemy_UseIngredient number 1
---@field Enchant_Recharge number 0
---@field Enchant_UseMagicItem number 1
---@field Enchant_CreateMagicItem number 2
---@field Enchant_CastOnStrike number 3
---@field Acrobatics_Jump number 0
---@field Acrobatics_Fall number 1
---@field Mercantile_Success number 0
---@field Mercantile_Bribe number 1
---@field Security_DisarmTrap number 0
---@field Security_PickLock number 1
---@field Sneak_AvoidNotice number 0
---@field Sneak_PickPocket number 1
---@field Speechcraft_Success number 0
---@field Speechcraft_Fail number 1
---@field Armorer_Repair number 0
---@field Athletics_RunOneSecond number 0
---@field Athletics_SwimOneSecond number 1
local SkillUseType = {}

---Interface version
---@type number
SkillProgression.version = nil

---These are shared by multiple skills
---Skill-specific use types
---@type openmw.interfaces.SkillProgression.SkillUseType
SkillProgression.SKILL_USE_TYPES = nil

---@type openmw.interfaces.SkillProgression.SkillLevelUpSource
SkillProgression.SKILL_INCREASE_SOURCES = nil

---Add new skill level up handler for this actor.
---For load order consistency, handlers should be added in the body if your script.
---If `handler(skillid, source, options)` returns false, other handlers (including the default skill level up handler)
---will be skipped. Where skillid and source are the parameters passed to openmw.interfaces.SkillProgression.SkillProgression.skillLevelUp, and options is
---a modifiable table of skill level up values, and can be modified to change the behavior of later handlers.
---These values are calculated based on vanilla mechanics. Setting any value to nil will cause that mechanic to be skipped. By default it contains these values:
---  * `skillIncreaseValue` - The numeric amount of skill levels gained. By default this is 1, except when the source is jail in which case it will instead be -1 for all skills except sneak and security.
---  * `levelUpProgress` - The numeric amount of level up progress gained.
---  * `levelUpAttribute` - The string identifying the attribute that should receive points from this skill level up.
---  * `levelUpAttributeIncreaseValue` - The numeric amount of attribute increase points received. This contributes to the amount of each attribute the character receives during a vanilla level up.
---  * `levelUpSpecialization` - The string identifying the specialization that should receive points from this skill level up.
---  * `levelUpSpecializationIncreaseValue` - The numeric amount of specialization increase points received. This contributes to the icon displayed at the level up screen during a vanilla level up.
---@param handler fun(...): any The handler.
function SkillProgression.addSkillLevelUpHandler(handler) end

---Add new skillUsed handler for this actor.
---For load order consistency, handlers should be added in the body of your script.
---If `handler(skillid, options)` returns false, other handlers (including the default skill progress handler)
---will be skipped. Where options is a modifiable table of skill progression values, and can be modified to change the behavior of later handlers.
---Contains a `skillGain` value as well as a shallow copy of the options passed to openmw.interfaces.SkillProgression.SkillProgression.skillUsed.
---@param handler fun(...): any The handler.
function SkillProgression.addSkillUsedHandler(handler) end

---Trigger a skill use, activating relevant handlers
---by handlers to make decisions. See the addSkillUsedHandler example at the top of this page.
---And may contain the following optional parameter:
---Note that a copy of this table is passed to skill used handlers, so any parameters passed to this method will also be passed to the handlers. This can be used to provide additional information to
---custom handlers when making custom skill progressions.
---@param skillid string The ID of the skill that was used
---@param options any A table of parameters. Must contain one of `skillGain` or `useType`. It's best to always include `useType` if applicable, even if you set `skillGain`, as it may be used * `skillGain` - The numeric amount of skill to be gained. * `useType` - #SkillUseType, A number from 0 to 3 (inclusive) representing the way the skill was used, with each use type having a different skill progression rate. Available use types and its effect is skill specific. See openmw.interfaces.SkillProgression.SkillUseType * `scale` - A numeric value used to scale the skill gain. Ignored if the `skillGain` parameter is set.
function SkillProgression.skillUsed(skillid, options) end

---Trigger a skill level up, activating relevant handlers
---@param skillid string The id of the skill to level up.
---@param source openmw.interfaces.SkillProgression.SkillLevelUpSource The source of the skill increase. Note that passing a value of openmw.interfaces.SkillProgression.SkillLevelUpSource.Jail will cause a skill decrease for all skills except sneak and security.
function SkillProgression.skillLevelUp(skillid, source) end

---Construct a table of skill level up options
---@param skillid string The id of the skill to level up
---@param source openmw.interfaces.SkillProgression.SkillLevelUpSource The source of the skill increase
---@return table The options to pass to the skill level up handlers
function SkillProgression.getSkillLevelUpOptions(skillid, source) end

---Compute the total skill gain required to level up a skill based on its current level, and other modifying factors such as major skills and specialization.
---Use the interface in these handlers so any overrides will receive the calls.
---@param skillid string The id of the skill to compute skill progress requirement for
function SkillProgression.getSkillProgressRequirement(skillid) end

return SkillProgression
