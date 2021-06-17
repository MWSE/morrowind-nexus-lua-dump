local defaultConfig = {
	fiveSeconds = 5,
	fiveSecondRule = {
		[0] = 3, -- Block
		[1] = 10, -- Armorer
		[2] = 4, -- Medium Armor
		[3] = 4, -- Heavy Armor
		[4] = 3, -- Blunt Weapon
		[5] = 3, -- Long Blade
		[6] = 3, -- Axe
		[7] = 3, -- Spear
		[8] = 0, -- Athletics
		[9] = 3, -- Enchant
		[10] = 3, -- Destruction
		[11] = 3, -- Alteration
		[12] = 3, -- Illusion
		[13] = 3, -- Conjuration
		[14] = 3, -- Mysticism
		[15] = 3, -- Restoration
		[16] = 5, -- Alchemy
		[17] = 4, -- Unarmored
		[18] = 3, -- Security
		[19] = 0, -- Sneak
		[20] = 3, -- Acrobatics
		[21] = 4, -- Light Armor
		[22] = 4, -- Short Blade
		[23] = 3, -- Marksman
		[24] = 3, -- Mercantile
		[25] = 3, -- Speechcraft
		[26] = 4  -- Hand-to-Hand
	},
	rateRecovery = 10,
	notifications = true
}
local config = mwse.loadConfig("diminishingSkillReturns", defaultConfig)

event.register("modConfigReady", function()
	mwse.saveConfig("diminishingSkillReturns", config)
	require("diminishingSkillReturns.mcm")
end)

-- Log verbose messages to MWSE.log
-- CAUTION: Can make your MWSE.log huge! Don't play the game with this
-- set to true for very long.
local verbose = false


local skillCoolDowns = {}

-- The levels of skill XP return per stage:
	-- 128% (capped at 100%)
	--  64%
	--  32%
	--  16%
	--   8%
	--   4%
	--   2%
	--   1%


local function onGameLoaded(e)

	-- Get the current time
	local timeNow = os.time(os.date("!*t"))

	-- Make sure we start with 100% skill XP rate
	local s = config.rateRecovery * 8

	skillCoolDowns = {
		[0] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Block
		[1] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Armorer
		[2] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Medium Armor
		[3] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Heavy Armor
		[4] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Blunt Weapon
		[5] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Long Blade
		[6] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Axe
		[7] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Spear
		[8] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Athletics
		[9] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Enchant
		[10] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Destruction
		[11] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Alteration
		[12] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Illusion
		[13] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Conjuration
		[14] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Mysticism
		[15] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Restoration
		[16] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Alchemy
		[17] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Unarmored
		[18] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Security
		[19] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Sneak
		[20] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Acrobatics
		[21] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Light Armor
		[22] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Short Blade
		[23] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Marksman
		[24] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Mercantile
		[25] = { last = timeNow - s, fsr = {}, hit = 128 }, -- Speechcraft
		[26] = { last = timeNow - s, fsr = {}, hit = 128 }  -- Hand-to-Hand
	}

end


local function onExerciseSkill(e)

	-- Make sure we have the latest config info if the user changed it in
	-- the MCM
	config = mwse.loadConfig("diminishingSkillReturns", config)

	if (config.fiveSecondRule[e.skill] > 0) then

		if (verbose) then
			mwse.log("----------------- "..tes3.getSkillName(e.skill).." was exercised! -----------------")
			mwse.log("Default value of this skill gain: "..e.progress)
		end

		local timeNow = os.time(os.date("!*t"))
		local timeSince = timeNow - skillCoolDowns[e.skill].last

		if (verbose) then
			mwse.log("It has been "..timeSince.." seconds since you last exercised this skill.")
		end

		-- Remove any entries from the five second rule array that are
		-- older than config.fiveSeconds seconds
		while (skillCoolDowns[e.skill].fsr[1] ~= nil and skillCoolDowns[e.skill].fsr[1] + config.fiveSeconds < timeNow)
		do
			table.remove(skillCoolDowns[e.skill].fsr, 1)
		end

		-- Add this entry to the five second rule array
		table.insert(skillCoolDowns[e.skill].fsr, timeNow)

		-- If there are config.fiveSecondRule[e.skill] or more items in the
		-- five second rule array
		if (table.getn(skillCoolDowns[e.skill].fsr) >= config.fiveSecondRule[e.skill]) then

			-- If the hit multiplier is greater than 1
			if (skillCoolDowns[e.skill].hit > 1) then

				-- Divide the hit multiplier by 2
				skillCoolDowns[e.skill].hit = skillCoolDowns[e.skill].hit / 2

				-- Notify the player that this has happened
				if (config.notifications) then
					tes3.messageBox("Skill XP gain rate in "..tes3.getSkillName(e.skill).." has been reduced to "..skillCoolDowns[e.skill].hit.."%% for "..config.rateRecovery.." seconds.")
				end
			end

			-- Clear the five second rule array - do this?
			skillCoolDowns[e.skill].fsr = {}

		-- Else there are fewer than config.fiveSecondRule entries in the
		-- five second rule array
		else

			-- Divide the seconds since we last used this skill by
			-- config.rateRecovery and get the floor
			local hitLevels = math.floor(timeSince / config.rateRecovery)

			if (verbose) then
				mwse.log("It has been "..hitLevels.." doubling periods since you last exercised this skill.")
			end

			if (hitLevels >= 1) then

				local hitRatePrevious = skillCoolDowns[e.skill].hit

				-- loop up to hitLevels times
				for i = 1, hitLevels, 1
				do

					-- if the hit multiplier is less than 128
					if (skillCoolDowns[e.skill].hit < 128) then

						-- Double the hit multipler
						skillCoolDowns[e.skill].hit = skillCoolDowns[e.skill].hit * 2

					end
				end

				if (config.notifications and hitRatePrevious ~= skillCoolDowns[e.skill].hit) then
					tes3.messageBox("Skill XP gain rate in "..tes3.getSkillName(e.skill).." has been restored to "..math.min(100, skillCoolDowns[e.skill].hit).."%%.")
				end
			end
		end

		-- Update the last-used-this-skill time to now
		skillCoolDowns[e.skill].last = timeNow

		-- Multiply the progress value by math.min(100, the hit multiplier) / 100
		local percentHit = math.min(100, skillCoolDowns[e.skill].hit)
		e.progress = e.progress * percentHit / 100

		if (verbose) then
			mwse.log("You earned "..percentHit.."%% of the skill gain for this action.")
		end
	end
end


event.register("initialized", function(e)
	event.register("loaded", onGameLoaded)
	event.register("exerciseSkill", onExerciseSkill)
	mwse.log("[Diminishing Skill Returns: Enabled]")
end)