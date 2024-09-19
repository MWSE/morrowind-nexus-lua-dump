
---@class SkillsModule.SkillOwner.register.params
---@field skillId string The id of the skill to register the owner for.
---@field actorId string The id of the actor object to register as the owner.
---@field value number The starting value of the skill for the owner.

---A class for registering NPCs and creatures as skill owners.
---Being skilled in an Other Skill allows an NPC to be a trainer in that skill
---@class SkillsModule.SkillOwner
---@field registeredOwners table<string, table<string, number>> A table of skill ids to a table of actor ids to skill values.
---@field skillId string The id of the skill to register the owner for.
---@field actorId string The id of the actor object to register as the owner.
---@field value number The current value of the skill for the owner.
local SkillOwner = {
    registeredOwners = {}
}

function SkillOwner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


return SkillOwner