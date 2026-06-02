if world then return end
if not S_USE_CRAFTING_SKILL then return end -- Turn this off in the settings
if not I.SkillFramework then return end

local skillId = "crafting_skill"

-- swap armorer for crafting_skill on every recipe, unless opted out
for _, categories in pairs(allProfessions) do
	for _, recipes in pairs(categories) do
		for _, recipe in ipairs(recipes) do
			if not (recipe.userData and recipe.userData.craftingFramework_dontPatch) then
				if not recipe.skill or recipe.skill:lower() == "armorer" then
					recipe.skill = skillId
				end
				if recipe.secondLevel and recipe.secondSkill and recipe.secondSkill:lower() == "armorer" then
					recipe.secondSkill = skillId
				end
			end
		end
	end
end
