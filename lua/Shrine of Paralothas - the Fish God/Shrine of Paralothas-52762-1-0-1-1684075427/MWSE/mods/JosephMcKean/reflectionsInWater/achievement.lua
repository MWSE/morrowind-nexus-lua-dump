local sbAchievements = include("sb_achievements.interop")
if not sbAchievements then
	return
end

local category = "reflections in water"
local categoryId = sbAchievements.registerCategory(category)

---@type achievement
local achievement = {
	id = "jsmk_rw_zenMaster",
	colour = sbAchievements.colours.blue,
	---@diagnostic disable-next-line: assign-type-mismatch
	category = categoryId,
	condition = function()
		return tes3.player.data.reflectionsInWater.pilgrimageComplete
	end,
	icon = "Icons\\jsmk\\rw\\achievement.dds",
	title = "Zen Master",
	desc = "Meditate at the Shrine of Paralothas for 60 seconds.",
}

sbAchievements.registerAchievement(achievement)
