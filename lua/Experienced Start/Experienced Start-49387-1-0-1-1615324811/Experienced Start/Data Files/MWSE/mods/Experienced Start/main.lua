local config

event.register("modConfigReady", function()
    require("Experienced Start.mcm")
	config  = require("Experienced Start.config")
end)

 -- The function to call on the addtopic "duties" event.
 local function updateSkillsOnTopicAdded(e)
     -- Locally store the dialogue topic being added in the event.
     local topicName = e.topic

     -- Check that the topic is background
     if (topicName.id == "Background") then

	local pcClass = tes3.player.object.class
	local pcObject = tes3.mobilePlayer
	local levelUp = config.level - 1
	local modifier = 0.4
	local pcAttr = {[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0}
	if config.luckyPlayer then pcAttr[7] = levelUp end
	local attributeSkills = {
	 [0] = 3,	-- Block	:Agility
	 [1] = 0,	-- Armorer	:Strength
	 [2] = 5,	-- Medium Armor	:Endurance
	 [3] = 5,	-- Heavy Armor	:Endurance
	 [4] = 0,	-- Blunt Weapon	:Strength
	 [5] = 0,	-- Long Blade	:Strength
	 [6] = 0,	-- Axe		:Strength
	 [7] = 5,	-- Spear	:Endurance
	 [8] = 4,	-- Athletics	:Speed
	 [9] = 1,	-- Enchant	:Intelligence
	 [10] = 2,	-- Destruction	:Willpower
	 [11] = 2,	-- Alteration	:Willpower
	 [12] = 6,	-- Illusion	:Personality
	 [13] = 1,	-- Conjuration	:Intelligence
	 [14] = 2,	-- Mysticism	:Willpower
	 [15] = 2,	-- Restoration	:Willpower
	 [16] = 1,	-- Alchemy	:Intelligence
	 [17] = 4,	-- Unarmored	:Speed
	 [18] = 1,	-- Security	:Intelligence
	 [19] = 3,	-- Sneak	:Agility
	 [20] = 0,	-- Acrobatics	:Strength
	 [21] = 3,	-- Light Armor	:Agility
	 [22] = 4,	-- Short Blade	:Speed
	 [23] = 3,	-- Marksman	:Agility
	 [24] = 6,	-- Mercantile	:Personality
	 [25] = 6,	-- Speechcraft	:Personality
	 [26] = 4	-- Hand to Hand	:Speed
	}


	-- Determine skill points increase for major and minor skills
	local majorPoints = math.round((levelUp * 10 * config.majorFocus / 100), 0)
	local minorPoints = (levelUp * 10) - majorPoints

	   -- Display skill points available for debugging
	   -- tes3.messageBox("Major skill points " .. majorPoints)
	   -- tes3.messageBox("Minor skill points " .. minorPoints)

	local majorRemainder = majorPoints - (math.floor(majorPoints / 5) * 5)
	local minorRemainder = minorPoints - (math.floor(minorPoints / 5) * 5)
	local skillInc = 0

	-- Update major skills
	for name, skill in pairs(pcClass.majorSkills) do
		if (majorRemainder > 0) then
			majorRemainder = majorRemainder - 1
			skillInc = math.floor(majorPoints / 5) + 1
		else
			skillInc = math.floor(majorPoints / 5)	
		end

		tes3.modStatistic({
			reference = pcObject,
			skill = skill,
			value = skillInc
		})
		pcAttr[attributeSkills[skill]] = pcAttr[attributeSkills[skill]] + skillInc
	end

	-- Update minor skills
	for name, skill in pairs(pcClass.minorSkills) do
		if (minorRemainder > 0) then
			minorRemainder = minorRemainder - 1
			skillInc = math.floor(minorPoints / 5) + 1
		else
			skillInc = math.floor(minorPoints / 5)	
		end

		tes3.modStatistic({
			reference = pcObject,
			skill = skill,
			value = skillInc
		})
		pcAttr[attributeSkills[skill]] = pcAttr[attributeSkills[skill]] + skillInc
	end

	-- Update attributes
	for name, i in pairs(pcAttr) do
		-- set the modifier according to config
		if (name == 7) then
			modifier = 1
		elseif config.luckyPlayer then
			modifier = 0.35
		else
			modifier = 0.4
		end

		-- modify the attribute
		tes3.modStatistic({
			reference = pcObject,
			attribute = name,
			value = math.floor(i * modifier)
		})	
	end

	-- Update health
	tes3.modStatistic({
		reference = pcObject,
		name = 'health',
		value = pcObject.endurance.base * 0.1 * levelUp
	})

	-- set the player level
	mwscript.setLevel{reference=tes3.player, level=config.level}
         local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
         local elem = menu:findChild(tes3ui.registerID("MenuStat_level"))
         elem.text = tostring(config.level)
         menu:updateLayout()

	-- inform the player that they have been levelled up
	tes3.messageBox("You are now level " .. config.level .. ".")
     end
 end

 -- The function to call on the initialized event.
 local function initialized()
     -- Register our function to the topicAdded event if mod is enabled.
	if config.modEnabled then
		event.register("topicAdded", updateSkillsOnTopicAdded)
		mwse.log("[Experienced Start: Enabled]")
	else
		mwse.log("[Experienced Start: Disabled]")
	end
 end

 -- Register our initialized function to the initialized event.
 event.register("initialized", initialized)