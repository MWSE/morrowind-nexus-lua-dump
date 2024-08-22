local cfg = require("BeefStranger.Experience Overflow.config")

local skillProgress = {}

---On level up, Re add left over xp
--- @param e skillRaisedEventData
local function skillRaisedCallback(e)
    if not cfg.enabled or not skillProgress[e.skill] then return end
    if skillProgress[e.skill] > 0 then
        -- debug.log(skillProgress[e.skill])
        local overflow = skillProgress[e.skill] * cfg.modifier
        -- debug.log(overflow)
        tes3.mobilePlayer:exerciseSkill(e.skill, overflow)
        skillProgress[e.skill] = 0
        -- debug.log(skillProgress[e.skill])
    end
end
event.register(tes3.event.skillRaised, skillRaisedCallback)

--- @param e exerciseSkillEventData
local function exerciseSkillCallback(e)
    if not cfg.enabled then return end
    local progressGain = e.progress
    local requirement = tes3.mobilePlayer:getSkillProgressRequirement(e.skill)
    local currentProgress = tes3.mobilePlayer.skillProgress[e.skill + 1]
    local newProgress = progressGain + currentProgress

    if newProgress > requirement then
        -- debug.log(newProgress - requirement)
        skillProgress[e.skill] = newProgress - requirement
        -- debug.log(requirement)
    end
end
event.register(tes3.event.exerciseSkill, exerciseSkillCallback)

event.register("initialized", function()
    print("[MWSE:Experience Overflow] initialized")
end)