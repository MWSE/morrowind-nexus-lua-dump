--- This event is invoked whenever the player gains experience in a SkillsModule skill. The event can be blocked to prevent progress. Additionally, the progress gained can be changed.
---@class SkillsModule.exerciseSkillEventData
---@field skill SkillsModule.Skill The SkillsModule skill object that is gaining experience.
---@field progress number The amount of experience that skill is gaining. Note that for skills using the v2 Skills Module API, experience is not on a scale of 1 to 100 and instead uses the vanilla scaling. This value is modifiable.
---@field claim boolean If set to true, any lower-priority event callbacks will be skipped. Returning false will set this to true.
---@field block boolean If set to true, the skill will not be progressed. Returning false will set this to true.

--- This event is invoked whenever a SkillsModule skill has been leveled up.
---@class SkillsModule.skillRaisedEventData
---@field skill SkillsModule.Skill The SkillsModule skill object that has gained a new level.
---@field level number *Read only*. The new level of the skill.
---@field source tes3.skillRaiseSource *Read only*. The source of the skill raise.
---@field claim boolean If set to true, any lower-priority event callbacks will be skipped. Returning false will set this to true.

--- This event is invoked whenever a SkillsModule skill has changed active state.
---@class SkillsModule.skillActiveChangedEventData
---@field skill SkillsModule.Skill The SkillsModule skill object that has changed active state.
---@field isActive boolean *Read only*. Whether the skill is active or not.