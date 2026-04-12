if SHOW_LEGACY_OPTION or USING_LEGACY_UNCAPPER then
	local function restoreSkills()
		for id, diff in pairs(saveData.storedSkills) do
			dbg(id, stats[id].base, "->", stats[id].base + diff)
			stats[id].base = stats[id].base + diff
		end
		saveData.storedSkills = {}
	end
	
	------------------------------------------------------------- Legacy skill book handler -------------------------------------------------------------
	local currentBook
	function legacy_UiModeChanged(data)
		if S_enableSkillUncapper and USING_LEGACY_UNCAPPER then
			if data.arg == currentBook then return end
			currentBook = data.arg
			if data.newMode == "Book" and data.arg then
				local record = data.arg.type.record(data.arg)
				local bookSkill = record and record.skill
				if bookSkill then
					if stats[bookSkill].base >= 100 then
						local diff = stats[bookSkill].base - 99
						saveData.storedSkills[bookSkill] = (saveData.storedSkills[bookSkill] or 0) + diff
						dbg("opened book", bookSkill, stats[bookSkill].base, "->", stats[bookSkill].base - diff)
						stats[bookSkill].base = stats[bookSkill].base - diff
					end
				end
			elseif data.oldMode == "Book" then
				restoreSkills()
			end
		end
	end
	
	function Uncapper_roundtrip(msg)
		ui.showMessage("")
		ui.showMessage("")
		ui.showMessage(msg)
	end
	
	------------------------------------------------------------- Legacy skill level up handler -------------------------------------------------------------
	local skillLevelUpRegistered = false
	function registerSkillLevelUp()
		if skillLevelUpRegistered then return end
		if not S_enableSkillUncapper or not USING_LEGACY_UNCAPPER then return end
		skillLevelUpRegistered = true
	
		I.SkillProgression.addSkillLevelUpHandler(function(skillId, source, options)
			if not S_enableSkillUncapper or not USING_LEGACY_UNCAPPER then return end
			for a,b in pairs(options) do print(a,b) end
			local cap = capTable[skillId]
			local hardCap = cap and cap.hardCap or math.huge
			if source ~= I.SkillProgression.SKILL_INCREASE_SOURCES.Jail then
				if stats[skillId].base >= 100 and stats[skillId].base < hardCap then
					local attribute = core.stats.Skill.records[skillId]
						and core.stats.Skill.records[skillId].attribute
					if attribute then
						local attrInc = options.levelUpAttributeIncreaseValue or 1
						stats.level.skillIncreasesForAttribute[attribute]
							= stats.level.skillIncreasesForAttribute[attribute] + attrInc
					end
					stats[skillId].progress = stats[skillId].progress % 1
					stats[skillId].base = stats[skillId].base + 1
					stats.level.progress = stats.level.progress + options.levelUpProgress
					local spec = options.levelUpSpecialization or "combat"
					stats.level.skillIncreasesForSpecialization[spec]
						= stats.level.skillIncreasesForSpecialization[spec]
						+ options.levelUpSpecializationIncreaseValue
	
					dbg("Uncapper: +1 " .. skillId .. " = " .. stats[skillId].base
						.. " [+" .. tostring(stats.level.skillIncreasesForAttribute[attribute])
						.. " " .. tostring(attribute) .. "]")
	
					ambient.playSound("skillraise")
					ui.showMessage(string.format(
						core.getGMST("sNotifyMessage39"),
						statNames[skillId] or skillId, stats[skillId].base))
				end
			end
			
			-- 2 frames delayed message
			if saveData.storedSkills[skillId] then
				local realLevel = stats[skillId].base + 1 + saveData.storedSkills[skillId]
				core.sendGlobalEvent("Uncapper_roundtrip", {
					self,
					core.getGMST("sBookSkillMessage")
						.. string.format(core.getGMST("sNotifyMessage39"),
							statNames[skillId] or skillId, realLevel),
				})
			end
		end)
	end
	registerSkillLevelUp()
	
	------------------------------------------------------------- Legacy skill used handler -------------------------------------------------------------
	local skillUsedRegistered = false
	function registerSkillUsed()
		if skillUsedRegistered then return end
		if not USING_LEGACY_UNCAPPER then return end
		if not S_enableSkillUncapper and not S_enableXPMult then return end
		skillUsedRegistered = true
		
		I.SkillProgression.addSkillUsedHandler(function(skillId, params)
			if not USING_LEGACY_UNCAPPER then return end
				if S_enableXPMult then
					local skillMult = _G["S_SKILL_MULT_"..skillId] or 1
					if skillMult ~= 1 then
						params.skillGain = params.skillGain * skillMult
					end
					if S_globalXPMult ~= 1 then
						params.skillGain = params.skillGain * S_globalXPMult
					end
					if S_CATCH_UP_SPEED > 1 then
						local level = stats.level.current
						local expected = math.max(1, level * 2)
						local speedMult = math.max(1, S_CATCH_UP_SPEED * (1 - stats[skillId].base / expected) + stats[skillId].base / expected)
						if speedMult > 1 then
							params.skillGain = params.skillGain * speedMult
						end
					end
				end

			-- soft cap XP penalty
			if S_enableSkillUncapper then
				local cap = capTable[skillId]
				if cap and stats[skillId].base >= cap.softCap then
					params.skillGain = params.skillGain * cap.xpMultAtSoftCap
				end
			end

			local cap = capTable[skillId]
			local hardCap = cap and cap.hardCap or math.huge
			if S_enableSkillUncapper and stats[skillId].base >= 100 and stats[skillId].base < hardCap and core.API_REVISION > 97 then
				stats[skillId].progress = stats[skillId].progress
					+ params.skillGain / I.SkillProgression.getSkillProgressRequirement(skillId)
				if stats[skillId].progress >= 1 then
					I.SkillProgression.skillLevelUp(skillId, I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
				end
			end
		end)
	end
	registerSkillUsed()
end