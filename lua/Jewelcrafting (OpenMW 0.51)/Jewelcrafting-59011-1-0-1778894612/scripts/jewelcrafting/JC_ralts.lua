-- skill registration, console command, pliers->crafting-window event

G_eventHandlers.Jewelcrafting_openCraftingUI = function()
	I.CraftingFramework.openCraftingWindow("Jewelcrafting")
end

G_engineHandlers.onConsoleCommand = function(_, command)
	local cmd = command:gsub("^%s*[Ll][Uu][Aa]%s+", "")
	local prefix, arg = cmd:match("^(%S+)%s*(%S*)")
	if not prefix or prefix:lower() ~= "jewelcrafting" then return end
	if not G_skillStat then return end
	local level = tonumber(arg)
	if level then
		G_skillStat.base = math.max(0, math.floor(level))
		core.sendGlobalEvent("Jewelcrafting_syncSkill", { player = self, skill = G_skillStat.base })
		ui.showMessage("Jewelcrafting skill set to " .. level)
	else
		ui.showMessage(string.format("Jewelcrafting skill: base=%d modified=%d",
			G_skillStat.base, G_skillStat.modified))
	end
end

------------------------------ register skill + profession ------------------------------

table.insert(G_onActiveJobs, 1, function()
	I.SkillFramework.registerSkill(G_skillId, {
		name           = "Jewelcrafting",
		description    = "Governing Skill: Enchanting",
		icon           = {
			fgr      = "icons/jewelcrafting/skill_icon.png",
			fgrColor = util.color.rgb(0, 0, 0),
		},
		attribute      = "willpower",
		specialization = I.SkillFramework.SPECIALIZATION.Magic,
		skillGain      = { craft = 1.0 },
		startLevel     = 5,
		maxLevel       = 100,
		-- base 1.1x; relevant class skills reduce it (major: -2%*w, minor: -1%*w)
		xpCurve        = function(level)
			if not G_classFactor then
				local skillWeights = {
					armorer    = 1.5,
					enchant    = 1.2,
					shortblade = 0.7,
					sneak = 0.7,
				}
				local class = types.NPC.classes.record(types.NPC.record(self).class)
				local factor = 1.1
				for _, s in ipairs(class.majorSkills) do
					if skillWeights[s] then factor = factor - 0.02 * skillWeights[s] end
				end
				for _, s in ipairs(class.minorSkills) do
					if skillWeights[s] then factor = factor - 0.01 * skillWeights[s] end
				end
				G_classFactor = factor
			end
			return (level + 1) * G_classFactor
		end,
		statsWindowProps = {
			visible    = true,
			subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Crafts,
		},
	})
	
	I.CraftingFramework.registerProfession{
		name    = "Jewelcrafting",
		skillId = G_skillId,
		version = 1,
		solo    = true,
	}

	G_skillStat = I.SkillFramework.getSkillStat(G_skillId)
	
	core.sendGlobalEvent("Jewelcrafting_syncSkill", { player = self, skill = G_skillStat.modified })
	I.SkillFramework.addSkillStatChangedHandler(function(skillId)
		if skillId == G_skillId then
			core.sendGlobalEvent("Jewelcrafting_syncSkill", { player = self, skill = G_skillStat.modified })
		end
	end)
	
	--local prev = saveData.skillStat and saveData.skillStat.base or 0
	--if prev > G_skillStat.base then
	--	G_skillStat.base = prev
	--	G_skillStat.modified = prev + G_skillStat.modifier
	--end
	--saveData.skillStat = {
	--	base = G_skillStat.base,
	--	modifier = G_skillStat.modifier,
	--	modified = G_skillStat.modified,
	--	progress = G_skillStat.progress or 0,
	--}
	--I.SkillFramework.bindGlobal('jewelcraftlvl', G_skillId)
	--
	--I.CraftingFramework.getGlobals().professionSolo.Jewelcrafting = true
	--
end)
