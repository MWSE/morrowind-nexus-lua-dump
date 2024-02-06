---@class PPE.interop
---@field block_next table<tes3.skill, boolean> if a `skill` is set to `true`, the next xp gain event for that skill will be blocked
---@field calc_xp_modifier fun(id: tes3.skill): number calculates the xp modifier for the given skill
---@field calc_skills_module_xp_modifier fun(skill: SkillsModule.Skill): number calculates the xp modifier for the given skill
---@field change_profile fun(profile_name: string): boolean tries to change to a profile with the given name. return `true` if it succeeds, false otherwise.
local interop = {block_next = {}}




return interop