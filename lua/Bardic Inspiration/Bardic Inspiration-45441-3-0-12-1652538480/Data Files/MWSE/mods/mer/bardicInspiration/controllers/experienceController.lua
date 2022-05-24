local common = require("mer.bardicInspiration.common")
local function onLoad()
    timer.start{
        duration = 1,
        type = timer.simulate,
        iterations = -1,
        callback = function()
            if common.data.songPlaying then
                if not common.skills.performance then return end
                local difficulty = common.data.currentSongDifficulty or "beginner"
                local difficultyMulti = common.staticData.difficulties[difficulty].expMulti

                local skillLevel = common.skills.performance.value
                local minLevelMulti = common.staticData.skillLevelMultis.min
                local maxLevelMulti = common.staticData.skillLevelMultis.max
                local skillLevelMulti = math.clamp(math.remap(skillLevel, 0,100, minLevelMulti, maxLevelMulti),0,100)
                common.log:trace("Performance experience gain")
                common.log:trace("difficultyMulti: %s", difficultyMulti)
                common.log:trace("skillLevelMulti: %s", skillLevelMulti)
                common.log:trace("performSkillProgress: %s", common.staticData.performExperiencePerSecond)

                local progress = difficultyMulti * skillLevelMulti * common.staticData.performExperiencePerSecond

                common.log:trace("Progressing skill by %s", progress)
                common.skills.performance:progressSkill(progress)
                common.log:trace("Current progress: %s", common.skills.performance.progress)
            end

            if common.data.travelPlay then
                local skillLevel = common.skills.performance.value
                local minLevelMulti = common.staticData.skillLevelMultis.min
                local maxLevelMulti = common.staticData.skillLevelMultis.max
                local skillLevelMulti = math.clamp(math.remap(skillLevel, 0,100, minLevelMulti, maxLevelMulti),0,100)

                local progress = common.staticData.travelPlayExperiencePerSecond * skillLevelMulti
                common.skills.performance:progressSkill(progress)
                common.log:trace("Travel play experience gained: %s", progress)
            end
        end
    }
end
event.register("BardicInspiration:DataLoaded", onLoad)