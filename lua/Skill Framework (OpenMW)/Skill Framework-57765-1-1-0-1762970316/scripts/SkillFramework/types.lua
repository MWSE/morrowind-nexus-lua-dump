---@meta

--- A table of properties for a custom skill.
--- @class SkillProps
--- @field name string localized name of the skill
--- @field description? string localized description of the skill (default: nil)
--- @field icon {bgr: string, bgrColor: Color, fgr: string, fgrColor: Color} icon information for the skill (default: default icon based on specialization)
--- @field attribute? string the id of the skill's governing attribute (default: nil)
--- @field specialization? Specialization the skill's specialization (default: nil)
--- @field skillGain table<any, number> a table mapping `SkillUseOptions.useType` keys to XP gain amounts (default: empty table)
--- @field startLevel number the starting level for this skill (default: 5)
--- @field maxLevel number the maximum level for this skill (default: 100; if < 0, no max)
--- @field xpCurve fun(currentLevel:number):number a function that takes the current level and returns the XP needed for the next level (default: vanilla formula)
--- @field statsWindowProps SkillStatsWindowProps properties for Stats Window Extender integration

--- A table of properties for a custom skill's Stats Window Extender integration.
--- @class SkillStatsWindowProps
--- @field subsection? StatsWindowSubsection|string|nil localized subsection name to group the skill under in 'Other Skills' (default: nil)
--- @field shortenedName? string|nil a localized shortened name used when the skill is grouped under its subsection (default: full name)
--- @field visible boolean|fun():boolean whether the skill should be visible in the stats window (default: true)
--- @field onClick? function|nil called when the skill is clicked in the stats window (default: nil)

--- A table of properties for a custom skill book.
--- @class SkillBookProps
--- @field skillIncrease number the amount the book increases this skill by (default: 1)
--- @field grantSkill boolean|fun():boolean,string? whether the book should grant this skill increase (default: true). A string can optionally be returned to provide a custom failure message.

--- Information about a skill's current level.
--- @class SkillStat
--- @field base number current base level of the skill (without modifiers)
--- @field modifier number current modifier applied to the skill
--- @field modified number current level of the skill with modifiers applied (read-only)
--- @field progress number \[0-1] current progress towards the next level

--- A table of parameters for when a skill is used. Must contain one of `skillGain` or `useType`.
--- 
--- It's best to always include `useType` if applicable, even if you set `skillGain`, as it may be used by handlers to make decisions.
--- @class SkillUseOptions
--- @field skillGain? number the numeric amount of skill to be gained
--- @field useType? any an index into the skill's `SkillProps.skillGain` table; must first be set there to have an effect
--- @field scale? number a multiplier to apply to the skill gain; ignored if `skillGain` is set

--- A modifiable table of skill level up values. Can be modified to change the behavior of later handlers.
--- 
--- These values are calculated based on vanilla mechanics. Setting any value to nil will cause that mechanic to be skipped.
--- @class SkillLevelUpOptions
--- @field skillIncreaseValue? number The numeric amount of skill levels gained. By default this is 1, except when the source is jail in which case it will instead be -1
--- @field levelUpProgress? number The numeric amount of level up progress gained.
--- @field levelUpAttribute? string The string identifying the attribute that should receive points from this skill level up.
--- @field levelUpAttributeIncreaseValue? number The numeric amount of attribute increase points received. This contributes to the amount of each attribute the character receives during a vanilla level up.
--- @field levelUpSpecialization? string The string identifying the specialization that should receive points from this skill level up.
--- @field levelUpSpecializationIncreaseValue? number The numeric amount of specialization increase points received. This contributes to the icon displayed at the level up screen during a vanilla level up.

--- A handler function to be called when a new skill is registered.
--- @alias SkillRegisteredHandler fun(skillId: string, props: SkillProps)

--- A handler function to be called when a skill is used via `API.skillUsed`.
--- @alias SkillUsedHandler fun(skillId: string, options: SkillUseOptions): boolean?

--- A handler function to be called when a skill would level up via `API.skillUsed` or `API.skillLevelUp`.
--- @alias SkillLevelUpHandler fun(skillId: string, source: SkillIncreaseSource, options: SkillLevelUpOptions): boolean?

--- A handler function to be called when a skill's stat would change by any means, including direct modification.
--- @alias SkillStatChangedHandler fun(skillId: string, oldStat: SkillStat, newStat: SkillStat)