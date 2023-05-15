local skillModule = include("OtherSkills.skillModule")
local common = require("mer.fishing.common")
local logger = common.createLogger("FishingSkill")

---@class Fishing.FishingSkill
local FishingSkill = {
    config = {
        id = "fishing",
        name = "Fishing",
        value = 20,
        description = "The Fishing skill determines your effectiveness at catching fish.",
        icon = "icons/mer_fishing/skill.dds",
        attribute = tes3.attribute.agility,
        specialization = tes3.specialization.stealth,
    },
    progressValues = {
        landLure = 5,
        fish = {
            common = 10,
            uncommon = 30,
            rare = 50,
            legendary = 60
        }
    }
}

--- Get the fishing skill object
function FishingSkill.get()
    return skillModule.getSkill(FishingSkill.config.id)
end

--- Get the current value of the fishing skill
function FishingSkill.getCurrent()
    return FishingSkill.get().value
end

--- Progress the fishing skill by the given amount
function FishingSkill.progress(amount)
    local skill = FishingSkill.get()
    skill:progressSkill(amount)
end

--- Progress the fishing skill by the amount for landing a lure
function FishingSkill.landLure()
    local skill = FishingSkill.get()
    logger:debug("Progressing Fishing skill by %s", FishingSkill.progressValues.landLure)
    skill:progressSkill(FishingSkill.progressValues.landLure)
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
    skill:progressSkill(value)
end


return FishingSkill