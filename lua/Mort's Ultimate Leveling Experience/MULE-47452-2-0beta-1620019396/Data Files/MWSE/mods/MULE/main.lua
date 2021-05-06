--[[
	Mod Initialization: Mort's Ultimate Leveling Experience
	v1.7

	Take the load off of leveling and let your pal mort do the work
]] --

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20191220) then
	mwse.log("[MULE] Build date of %s does not meet minimum build date of 20191220.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("MULE requires a newer version of MWSE. Please run MWSE-Update.exe.")
		end
	)
	return
end

local configPath = "mortLeveling.config"

local config = mwse.loadConfig("mortLeveling", {
    majorSkillRate = 50,
    minorSkillRate = 50,
    modEnabled = true,
	skillDecay = false,
	skillDecayMessage = true,
	skillDecayUseBase = false,
	skillDecayMin = 15,
	skillDecayTime = 15,
    attributeMaximum = 200,
	luckPerLevel = 10,
    acrobaticsMod = 50,
    miscSkillThreshold=30,
    alternateHealthSystem=true,
    minorSkillThreshold=0,
    miscLevelThreshold=3,
    miscSkillRate=30,
    majorSkillThreshold=0,
	flatHealthPerLevel = 5,
})

local majors
local minors

local levelUpMessage = {
	[2] = "You realize that all your life you have been coasting along as if you were in a dream. Suddenly, facing the trials of the last few days, you have come alive.",
	[3] = "You realize that you are catching on to the secret of success. It's just a matter of concentration.",
	[4] = "It's all suddenly obvious to you. You just have to concentrate. All the energy and time you've wasted -- it's a sin. But without the experience you've gained, taking risks, taking responsibility for failure, how could you have understood?",
	[5] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[6] = "You sense yourself more aware, more open to new ideas. You've learned a lot about Morrowind. It's hard to believe how ignorant you were -- but now you have so much more to learn.",
	[7] = "You resolve to continue pushing yourself. Perhaps there's more to you than you thought.",
	[8] = "The secret does seem to be hard work, yes, but it's also a kind of blind passion, an inspiration.",
	[9] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[10] = "You woke today with a new sense of purpose. You're no longer afraid of failure. Failure is just an opportunity to learn something new.",
	[11] = "Being smart doesn't hurt. And a little luck now and then is nice. But the key is patience and hard work. And when it pays off, it's SWEET!",
	[12] = "You can't believe how easy it is. You just have to go -- a little crazy. And then, suddenly, it all makes sense, and everything you do turns to gold.",
	[13] = "It's the most amazing thing. Yesterday it was hard, and today it is easy. Just a good night's sleep, and yesterday's mysteries are today's masteries.",
	[14] = "Today you wake up, full of energy and ideas, and you know, somehow, that overnight everything has changed. What a difference a day makes.",
	[15] = "Today you suddenly realized the life you've been living, the punishment your body has taken -- there are limits to what the body can do, and perhaps you have reached them. You've wondered what it is like to grow old. Well, now you know.",
	[16] = "You've been trying too hard, thinking too much. Relax. Trust your instincts. Just be yourself. Do the little things, and the big things take care of themselves.",
	[17] = "Life isn't over. You can still get smarter, or cleverer, or more experienced, or meaner -- but your body and soul just aren't going to get any younger.",
	[18] = "The challenge now is to stay at the peak as long as you can. You may be as strong today as any mortal who has ever walked the earth, but there's always someone younger, a new challenger.",
	[19] = "You're really good. Maybe the best. And that's why it's so hard to get better. But you just keep trying, because that's the way you are.",
	[20] = "You'll never be better than you are today. If you are lucky, by superhuman effort, you can avoid slipping backwards for a while. But sooner or later, you're going to lose a step, or drop a beat, or miss a detail -- and you'll be gone forever.",
	[21] = "The results of hard work and dedication always look like luck to saps. But you know you've earned every ounce of your success."
	}

local function setLevel(ref, lvl)
    mwscript.setLevel{reference=ref, level=lvl}
    if ref == tes3.player then
        local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
        local elem = menu:findChild(tes3ui.registerID("MenuStat_level"))
        elem.text = tostring(lvl)
        menu:updateLayout()
    end
end

local function drainSkill(skillCode,amount)
	local skillName = tes3.getSkill(skillCode).name
	if config.skillDecayMessage then
		tes3.messageBox("You have lost " .. skillName)
	end
	tes3.modStatistic{reference=tes3.player,skill=skillCode,value=amount}
	--tes3.modStatistic{reference=tes3.player,attribute=tes3.getSkill(skillCode).attribute,value=-1}
end

local function setInitialStats()
	
end

local function incrementSkill(skill,amount)
	local path = tes3.player.data.mortLeveling
	
	if skill == 777 then --luck special case
		path.luckProgress = (path.luckProgress + amount)
		if path.luckProgress >= 1.0 and tes3.mobilePlayer.luck.base < config.attributeMaximum then
			path.luckProgress = (path.luckProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=7,value=1}
		end
		return
	end
	
	if tes3.attributeName[tes3.getSkill(skill).attribute] == nil then
		return
	end
	
	if skill == 20 then --acrobatics special case
		path.strengthProgress = (path.strengthProgress + (config.acrobaticsMod*0.01)*amount)
		if path.strengthProgress >= 1.0 and tes3.mobilePlayer.strength.base < config.attributeMaximum then
			path.strengthProgress = (path.strengthProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=0,value=1}
			tes3.messageBox("Your strength has improved.")
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "strength" then 
		path.strengthProgress = (path.strengthProgress + amount)
		if path.strengthProgress >= 1.0 and tes3.mobilePlayer.strength.base < config.attributeMaximum then
			path.strengthProgress = (path.strengthProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=0,value=1}
			tes3.messageBox("Your strength has improved.")
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "intelligence" then
		path.intelligenceProgress = (path.intelligenceProgress + amount)
		if path.intelligenceProgress >= 1.0 and tes3.mobilePlayer.intelligence.base < config.attributeMaximum then
			path.intelligenceProgress = (path.intelligenceProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=1,value=1}
			tes3.messageBox("Your intelligence has improved.")
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "willpower" then
		path.willpowerProgress = (path.willpowerProgress + amount)
		if path.willpowerProgress >= 1.0 and tes3.mobilePlayer.willpower.base < config.attributeMaximum  then
			path.willpowerProgress = (path.willpowerProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=2,value=1}
			tes3.messageBox("Your willpower has improved.")
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "agility" then
		path.agilityProgress = (path.agilityProgress + amount)
		if path.agilityProgress >= 1.0 and tes3.mobilePlayer.agility.base < config.attributeMaximum then
			path.agilityProgress = (path.agilityProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=3,value=1}
			tes3.messageBox("Your agility has improved.")
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "speed" then
		path.speedProgress = (path.speedProgress + amount)
		if path.speedProgress >= 1.0 and tes3.mobilePlayer.speed.base < config.attributeMaximum then
			path.speedProgress = (path.speedProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=4,value=1}
			tes3.messageBox("Your speed has improved.")
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "endurance" then
		path.enduranceProgress = (path.enduranceProgress + amount)
		if path.enduranceProgress >= 1.0 and tes3.mobilePlayer.endurance.base < config.attributeMaximum then
			path.enduranceProgress = (path.enduranceProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=5,value=1}
			tes3.messageBox("Your endurance has improved.")
			if config.alternateHealthSystem == true then
				local healthGain = 2
				if config.healthPerEndurance ~= nil then
					healthGain = config.healthPerEndurance
				end
				tes3.modStatistic{reference=tes3.player,name='health',value=healthGain}
			end
		end
	elseif tes3.attributeName[tes3.getSkill(skill).attribute] == "personality" then
		path.personalityProgress = (path.personalityProgress + amount)
		if path.personalityProgress >= 1.0 and tes3.mobilePlayer.personality.base < config.attributeMaximum then
			path.personalityProgress = (path.personalityProgress - 1)
			tes3.modStatistic{reference=tes3.player,attribute=6,value=1}
			tes3.messageBox("Your personality has improved.")
		end
	end
end

local function onSkillUp(e)
	if config.modEnabled == false then
		return
	end
	
	--these should probably just be global to script
	local path = tes3.player.data.mortLeveling
	--local majors = tes3.player.object.class.majorSkills
	--local minors = tes3.player.object.class.minorSkills
	local threshold = 10 -- test 10 [9 for major/minor, 10 for misc, this affects how many skills levels you up]
	local skillType = "misc" --default code for skills, will get set to major/minor
	local skillName = tes3.getSkill(e.skill).name
	
	if config.skillDecay then
		local decayTable = tes3.player.data.mortSkillDecay
		local baseTable = tes3.player.data.mortBaseStats
		local daysPassed = tes3.worldController.daysPassed.value
		
		decayTable[e.skill] = daysPassed
		
		for k,_ in pairs(decayTable) do
		--mwse.log(k .. " " .. tes3.getSkill(k).name .. " " .. decayTable[k] .. " " .. tes3.mobilePlayer.skills[k+1].base .. ">" .. baseTable[k])
			if decayTable[k] < (daysPassed - config.skillDecayTime) then
				if (tes3.mobilePlayer.skills[k+1].base > config.skillDecayMin) then
					decayTable[k] = daysPassed
					drainSkill(k,-1)
				elseif config.skillDecayUseBase and (tes3.mobilePlayer.skills[k+1].base > baseTable[k]) then
					decayTable[k] = daysPassed
					drainSkill(k,-1)
				end
			end
		end
		
	end
	--print(tes3.player.data.mortSkillDecay[skillName])
	
	for _,skill in pairs(majors) do
		if skill == e.skill then
			skillType = "major"
		end
	end
	
	for _,skill in pairs(minors) do
		if skill == e.skill then
			skillType = "minor"
		end
	end
	
	if (skillType == "major") and (e.level >= config.majorSkillThreshold) then 
		local skillRate = config.majorSkillRate * 0.01
		incrementSkill(e.skill,skillRate)
	elseif (skillType == "minor") and (e.level >= config.minorSkillThreshold) then
		local skillRate = config.minorSkillRate * 0.01
		incrementSkill(e.skill,skillRate)
	elseif (skillType == "misc") and (e.level >= config.miscSkillThreshold) then
		local skillRate = config.miscSkillRate * 0.01
		incrementSkill(e.skill,skillRate)
	end
	
	if skillType == "misc" then
		path.miscSkillsRaised = path.miscSkillsRaised + 1
		if path.miscSkillsRaised >= config.miscLevelThreshold then
			path.miscSkillsRaised = 0
			if config.miscLevelThreshold ~= 0 then
				tes3.mobilePlayer.levelUpProgress = tes3.mobilePlayer.levelUpProgress + 1
			end
		end
	end
	
	-- if skillType == "major" or skillType == "minor" then
		-- threshold = 10 --test, was 9
	-- else
		-- threshold = 10
	-- end
	
	--failsafe if things go crazy and levelupprogress becomes -1, it wraps back around
	if tes3.mobilePlayer.levelUpProgress > 200 then
		tes3.mobilePlayer.levelUpProgress = 0
	end
	
	if tes3.mobilePlayer.levelUpProgress >= threshold then
		local healthToAdd = 5
		if config.flatHealthPerLevel ~= nil then
			healthToAdd = config.flatHealthPerLevel
		end
		
		if skillType == "misc" then
			tes3.mobilePlayer.levelUpProgress = 0
		else
			if e.source == "training" then
				tes3.mobilePlayer.levelUpProgress = 0 --test, was -1
			else
				tes3.mobilePlayer.levelUpProgress = 0
			end
		end
		
		local next_level = (tes3.player.object.level + 1)
		setLevel(tes3.player, next_level)
		tes3.messageBox("You have gained an additional level.")
		if (next_level > 21) then
			next_level = 21
		end
		tes3.messageBox(levelUpMessage[next_level])
		tes3.streamMusic{path="Special/MW_Triumph.mp3"}
		
		--add luck per level
		--need to add limit here real quick
		--this is all fucky, luck progress not taken into account, cant add 0.5 luck
		local luckProgressToAdd = 0.1 * config.luckPerLevel
		incrementSkill(777,luckProgressToAdd)
		--tes3.modStatistic{reference=tes3.player,attribute=7,value=luckProgressToAdd}
		
		if config.alternateHealthSystem == false then
			local healthMultiplier = tes3.findGMST(1035)
			healthToAdd = (healthMultiplier.value * tes3.mobilePlayer.endurance.base)
		end
		tes3.modStatistic{reference=tes3.player,name='health',value=healthToAdd}
	end
end

local function setupMULE(e)
	local path = tes3.player.data.mortLeveling
	local decayTable = tes3.player.data.mortSkillDecay
	local baseTable = tes3.player.data.mortBaseStats
	
	majors = tes3.player.object.class.majorSkills
	minors = tes3.player.object.class.minorSkills

	if path == nil then
		tes3.player.data.mortLeveling = {}
		path = tes3.player.data.mortLeveling
		path.strengthProgress = 0
		path.enduranceProgress = 0
		path.intelligenceProgress = 0
		path.willpowerProgress = 0
		path.luckProgress = 0
		path.speedProgress = 0
		path.agilityProgress = 0
		path.personalityProgress = 0
		path.miscSkillsRaised = 0
	end
	
	--new feature, keeps compatibility
	if decayTable == nil then
		tes3.player.data.mortSkillDecay = {}
		decayTable = tes3.player.data.mortSkillDecay
	end
	
	-- generate decay base stats only once, store them on the character
	if baseTable == nil then
		mwse.log("[MULE] Generating base stats")
		tes3.player.data.mortBaseStats = {}
		baseTable = tes3.player.data.mortBaseStats
		for k,v in pairs(tes3.mobilePlayer.skills) do
			baseTable[k-1] = v.base
		end
	end

end

-- local function changeEndurance(e)
	-- if config.stateBasedHealth ~= false then
		-- local healthTotal = (((tes3.mobilePlayer.strength.current + tes3.mobilePlayer.endurance.current) / 2)
							-- + ((tes3.mobilePlayer.endurance.current / 10) * (tes3.player.object.level - 1)))
							
		-- if tes3.player.object.health > healthTotal then
			-- tes3.setStatistic{reference=tes3.player,name='health',current=healthTotal}
		-- end
		-- tes3.setStatistic{reference=tes3.player,name='health',base=healthTotal}
		-- tes3.modStatistic{reference=tes3.player,name='health',value=0}
		-- --refreshHealthUI()
	-- end
-- end

local function onInitialized()
	event.register("skillRaised", onSkillUp, {priority = 3000})
	--event.register("simulate", changeEndurance)
	event.register("loaded", setupMULE)
	mwse.log("[MULE] Initialized.")
end
event.register("initialized", onInitialized)

---
--- Mod Config
---

local function createplayerVar(id, default)
	return mwse.mcm.createPlayerData{
		id = id,
		path = "mortLeveling",
		defaultSetting = default
	}  
end

local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}  
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("MULE")
	template:saveOnClose("mortLeveling", config)
	
	
    local page = template:createPage()
    local categoryMain = page:createCategory("Settings")
    categoryMain:createYesNoButton{ label = "Enable MULE",
								variable = createtableVar("modEnabled"),
								defaultSetting = true}
								
	categoryMain:createYesNoButton{ label = "Use alternative flatrate HP gain system?", 
								variable = createtableVar("alternateHealthSystem"),
								defaultSetting = true}
								
	categoryMain:createYesNoButton{ label = "Skill Decay", 
								variable = createtableVar("skillDecay"),
								defaultSetting = true}

	categoryMain:createYesNoButton{ label = "Display Skill Decay Messagebox", 
								variable = createtableVar("skillDecayMessage"),
								defaultSetting = true}
								
	categoryMain:createYesNoButton{ label = "Use base stats as decay minimum (only valid on new characters)", 
								variable = createtableVar("skillDecayUseBase"),
								defaultSetting = false}
								
	categoryMain:createSlider{ label = "Days of no use before a skill decays",
							variable = createtableVar("skillDecayTime"),
							min = 1,
							max = 50,
							jump = 15,
							defaultSetting = 15}
							
	categoryMain:createSlider{ label = "Minimum a skill can decay to",
							variable = createtableVar("skillDecayMin"),
							min = 0,
							max = 100,
							jump = 5,
							defaultSetting = 15}
							
	-- categoryMain:createYesNoButton{ label = "[Experimental] State-based Health? Overrides above setting!", 
								-- variable = createtableVar("stateBasedHealth"),
								-- defaultSetting = false}
								
	categoryMain:createSlider{ label = "Attribute Maximum",
							variable = createtableVar("attributeMaximum"),
							max = 500,
							jump = 10,
							defaultSetting = 200}
							
	categoryMain:createSlider{ label = "Luck gain per level (*0.1)",
							variable = createtableVar("luckPerLevel"),
							max = 20,
							defaultSetting = 10}
							
	categoryMain:createSlider{ label = "Health Per Level (using flatrate HP gain system)",
							variable = createtableVar("flatHealthPerLevel"),
							max = 10,
							defaultSetting = 5}
							
	categoryMain:createSlider{ label = "Health Per Endurance gain (using flatrate HP gain system)",
						variable = createtableVar("healthPerEndurance"),
						max = 10,
						defaultSetting = 2}
								
	local categoryMajor = page:createCategory("Major Skills")
								
	categoryMajor:createSlider{ label = "Percentage of attribute point to gain from major skill (default 50%)",
							variable = createtableVar("majorSkillRate"),
							max = 200,
							jump = 10,
							defaultSetting = 50}
							
	categoryMajor:createSlider{ label = "Minimum level to gain attributes from major skills (default 0)",
							variable = createtableVar("majorSkillThreshold"),
							max = 100,
							jump = 10,
							defaultSetting = 0}
							
	local categoryMinor = page:createCategory("Minor Skills")
							
	categoryMinor:createSlider{ label = "Percentage of attribute point to gain from minor skill (default 50%)",
							variable = createtableVar("minorSkillRate"),
							max = 200,
							jump = 10,
							defaultSetting = 50}
							
	categoryMinor:createSlider{ label = "Minimum level to gain attributes from minor skills (default 0)",
							variable = createtableVar("minorSkillThreshold"),
							max = 100,
							jump = 10,
							defaultSetting = 0}
							
	local categoryMisc = page:createCategory("Misc Skills")

	categoryMisc:createSlider{ label = "Percentage of attribute point to gain from misc skill (default 30%)",
							variable = createtableVar("miscSkillRate"),
							max = 200,
							jump = 10,
							defaultSetting = 30}
							
	categoryMisc:createSlider{ label = "Minimum level to gain attributes from misc skills (default 30)",
							variable = createtableVar("miscSkillThreshold"),
							max = 100,
							jump = 10,
							defaultSetting = 30}
							
	categoryMisc:createSlider{ label = "Misc skills required for one level point (default 3)",
							variable = createtableVar("miscLevelThreshold"),
							max = 10,
							defaultSetting = 3}
							
	
	categoryMain:createSlider{ label = "Acrobatics attribute modifier (default 50%)",
							variable = createtableVar("acrobaticsMod"),
							max = 100,
							jump = 10,
							defaultSetting = 50}
	
    mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)