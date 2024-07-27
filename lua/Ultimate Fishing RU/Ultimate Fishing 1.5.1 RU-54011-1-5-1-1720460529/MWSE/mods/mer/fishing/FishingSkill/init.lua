local SkillsModule = include("SkillsModule")
local common = require("mer.fishing.common")
local logger = common.createLogger("FishingSkill")

---@class Fishing.FishingSkill
local FishingSkill = {
    ---@type SkillsModule.Skill.constructorParams
    config = {
        id = "fishing",
        name = "Рыбная ловля",
        value = 20,
        description = "Навык рыбной ловли связан с выуживанием рыбы из водоемов с помощью удочки и различных приманок.",
        icon = "icons/mer_fishing/skill.dds",
        attribute = tes3.attribute.agility,
        specialization = tes3.specialization.stealth,
    },
    progressValues = {
        landLure = 2,
        fish = {
            common = 5,
            uncommon = 10,
            rare = 20,
            legendary = 50
        }
    },
    modifiers = {
        { class = "t_mw_fisherman", amount = 20 },
        { class = "t_glb_fisherman", amount = 20 }
    }
}

--- Get the fishing skill object
---@return SkillsModule.Skill
function FishingSkill.get()
    return SkillsModule.skills[FishingSkill.config.id]
end

--- Get the current value of the fishing skill
function FishingSkill.getCurrent()
    return FishingSkill.get().current
end

--- Progress the fishing skill by the given amount
function FishingSkill.progress(amount)
    local skill = FishingSkill.get()
    skill:exercise(amount)
end

--- Progress the fishing skill by the amount for landing a lure
function FishingSkill.landLure()
    local skill = FishingSkill.get()
    logger:debug("Progressing Fishing skill by %s", FishingSkill.progressValues.landLure)
    skill:exercise(FishingSkill.progressValues.landLure)
end

--- Progress the fishing skill by the amount for catching a fish
---@param fishType Fishing.FishType
function FishingSkill.catchFish(fishType)
    local skill = FishingSkill.get()
    local classValue = FishingSkill.progressValues.fish[fishType.class]
        or FishingSkill.progressValues.fish["common"]
    logger:debug("Fish class: %s. Class value: %s", fishType.class, classValue)
    local difficultyEffect = math.remap(fishType.difficulty,
        0, 100,
        1, 5
    )
    logger:debug("Difficulty: %s. Effect: %s", fishType.difficulty, difficultyEffect)
    local value = classValue * difficultyEffect
    logger:debug("Progressing Fishing skill by %s", value)
    skill:exercise(value)
end


return FishingSkill