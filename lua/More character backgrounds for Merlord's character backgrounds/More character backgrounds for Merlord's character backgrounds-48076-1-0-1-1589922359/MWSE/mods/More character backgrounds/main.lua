--[[

	More character backgrounds for Merlord's character backgrounds.
    An MWSE-lua mod for Morrowind
    
    Note: This mod requires "Merlord's character backgrounds" to work.
           https://www.nexusmods.com/morrowind/mods/46795
    
	@version      v1.0.1
	@author       Isnan
	@last-update  May 19, 2020
	@changelog
		v1.0.1
		- Fixed a typo in death mage's apprentice's description.
		v1.0.0
		- Initial release

]]

-- prevents spells from a magic school
local function preventSchool(e, school )
	local spell = e.source
	
	for i=1, #e.source.effects do
		local effect = e.source.effects[i]
		if effect and effect.id ~= -1 then
			
			if effect.object.school == tes3.magicSchool[ school ] then
				e.castChance = 0
			end
		end
	end	
end

-- get the current merBackgrounds data
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

-- start the mod
local function onInit(e)
	local interop = require("mer.characterBackgrounds.interop")

	-- init chapel mage's apprentice
	local chapelApprenticeDoOnce
    local chapelApprenticeBackground = {
        id = "chapel_apprentice",
        name = "Chapel mage's apprentice",
        description = "Your master taught you humility and honor and the ways of living " ..
					  "in tune with all life. (Restoration +14, learn spells: Rest of St. " ..
                      "Merris, Rilm's Cure, Restore Strength) " ..
                      "\n" ..
                      "As your master did not care for the entropy of the current world, " ..
                      "you lack important knowledge in tearing the world apart. " ..
                      "(All destruction spells disabled)",
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.restoration, 
				value = 14
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "rest of st. merris"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "rilm's cure"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "restore strength"
			})
        end,

		callback = function()
			
			-- filter out destruction spells
			local function onSpellCast(e)
				local data = getData()
				if data.currentBackground == "chapel_apprentice" then
					preventSchool(e, 'destruction' )
				end
			end
			
			if chapelApprenticeDoOnce then
				return false
			end
			
			chapelApprenticeDoOnce = true
			event.register( "spellCast", onSpellCast )
        end
    }
	interop.addBackground(chapelApprenticeBackground)
	
	-- init portal mage's apprentice
	local portalApprenticeDoOnce
	local portalApprenticeBackground = {
		id = "portal_apprentice",
		name = "Portal mage's apprentice",
		description = "Your master travelled quickly for years with you at their side. " ..
					"You've mastered the ways of the mystic, and the art of setting a temporary home. " ..
                    "(Mysticism +14, learn spells: Mark, Recall, and Soultrap) " ..
                    "\n" ..
                    "Your journeys and experiences have faded you so far out " ..
					"of this world you may never attempt to restore it. (All restoration spells disabled)",

		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.mysticism, 
				value = 14
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "mark"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "recall"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "soul trap"
			})
		end,

		callback = function()
			
			-- filter out restoration spells
			local function onSpellCast(e)
				local data = getData()
				if data.currentBackground == "portal_apprentice" then
					preventSchool(e, 'restoration' )
				end
			end
			
			if portalApprenticeDoOnce then
				return false
			end
			
			portalApprenticeDoOnce = true
			event.register( "spellCast", onSpellCast )
		end
	}
	interop.addBackground(portalApprenticeBackground)
	

	-- init death mage's apprentice
	local deathApprenticeDoOnce
    local deathApprenticeBackground = {
        id = "death_apprentice",
        name = "Death mage's apprentice",
		description = "Early you were taught to kill, and to savor in the feeling " ..
					  "of besting creatures small and large. You've learned much from "..
					  "your master\'s cold and cruel tutelage. (Destruction +14, gain " ..
                      "spells: Doze, Weakness to Poison and Poisonous Touch), " ..
                      "\n" ..
                      "The indoctrination however, has left you incapable of creation. " ..
                      "(All conjuration spells disabled)",
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.destruction, 
				value = 14
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "doze"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "weakness to poison"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "poisonous touch"
			})
        end,

		callback = function()
			
			-- filter out conjuration spells
			local function onSpellCast(e)
				local data = getData()
				if data.currentBackground == "death_apprentice" then
					preventSchool(e, 'conjuration' )
				end
			end
			
			if deathApprenticeDoOnce then
				return false
			end
			
			deathApprenticeDoOnce = true
			event.register( "spellCast", onSpellCast )
        end
    }
	interop.addBackground(deathApprenticeBackground)

	
	-- init court mage's apprentice
	local courtApprenticeDoOnce
	local courtApprenticeBackground = {
		id = "court_apprentice",
		name = "Court mage's apprentice",
		description = "You quickly became enthranced by the fancy glamor of the illusionist's " ..
		"trickery, and learned to enjoy the hedonistic lifestyle that comes with it. (Illusion +14, " ..
        "learn spells: Calm Humanoid, Paralysis, and Brevusa's Averted Eyes) " ..
        "\n" ..
        "Your master did however never care much for physical trickery. " ..
        "(All mysticism spells disabled)",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.illusion, 
				value = 14
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "calm humanoid"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "paralysis"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "brevusa's averted eyes"
			})
		end,

		callback = function()
			
			-- filter out mysticism spells
			local function onSpellCast(e)
				local data = getData()
				if data.currentBackground == "court_apprentice" then
					preventSchool(e, 'mysticism' )
				end
			end
			
			if courtApprenticeDoOnce then
				return false
			end
			
			courtApprenticeDoOnce = true
			event.register( "spellCast", onSpellCast )
		end
	}
	interop.addBackground(courtApprenticeBackground)



	-- init tactical mage's apprentice
	local tacticalApprenticeDoOnce
    local tacticalApprenticeBackground = {
        id = "tactical_apprentice",
        name = "Tactical mage's apprentice",
		description = "Your master enforced the necessity of good logistics when supporting "..
		"armies and expeditions. (Alteration +14, learn spells: Strong Feather, Tinur's hoptoad, " ..
        "and Ondusi's Open Door) " ..
        "\n" ..
        "The logistics department did not care much for obscurity or fancy displays. "..
		"(All illusion spells disabled)",
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.alteration, 
				value = 14
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "strong feather"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "tinur's hoptoad"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "ondusi's open door"
			})
        end,

		callback = function()
			
			-- filter out illusion spells
			local function onSpellCast(e)
				local data = getData()
				if data.currentBackground == "tactical_apprentice" then
					preventSchool(e, 'illusion' )
				end
			end
			
			if tacticalApprenticeDoOnce then
				return false
			end
			
			tacticalApprenticeDoOnce = true
			event.register( "spellCast", onSpellCast )
        end
    }
	interop.addBackground(tacticalApprenticeBackground)



	-- init necromancer's apprentice
	local necroApprenticeDoOnce
    local necroApprenticeBackground = {
        id = "necro_apprentice",
        name = "Necromancer's apprentice",
		description = "Silently you worked with your master for years learning the trade " ..
		"of preserving and reanimating the dead. (Conjuration +14, learn spells: Summon Skeletal " ..
        "Minion, Summon Least Bonewalker, Turn Undead) " ..
        "\n" ..
        "Even after all these years you still hear  your masters voice. " ..
        "\"In true death, nothing ever changes.\" (All alteration spells disabled)",
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.conjuration, 
				value = 14
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "summon skeletal minion"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "summon least bonewalker"
			})
			mwscript.addSpell({
				reference = tes3.player, 
				spell = "turn undead"
			})
        end,

		callback = function()
			
			-- filter out alteration spells
			local function onSpellCast(e)
				local data = getData()
				if data.currentBackground == "necro_apprentice" then
					preventSchool(e, 'alteration' )
				end
			end
			
			if necroApprenticeDoOnce then
				return false
			end
			
			necroApprenticeDoOnce = true
			event.register( "spellCast", onSpellCast )
        end
    }
	interop.addBackground(necroApprenticeBackground)


	-- init axe murderer
	local axeMurdererDoOnce
    local axeMurdererBackground = {
        id = "axe_murderer",
        name = "Axe murderer",
		description = "You are known throughout the realm as a " ..
		"notorious axe murderer. Guards will attack you on sight, " ..
		"and many of the people you meet will despise you for what " ..
		"you've done. (Axe +29, Equipment: Steel Battle Axe, Skillbook: " ..
		"The Axe Man, Bounty: 10000 ) If you manage to pay off the " ..
		"bounty, it will return after a short while. " ..
		"\n\n" ..
		"The bounty will trigger approximately 1 minute after being let go, " ..
		"which should be sufficient for you to get out of Seyda Neen. " ..
		"\n\n" ..
		"Not recommended for new players.",
        doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.axe, 
				value = 29
			})
			mwscript.addItem({
				reference = tes3.player,
				item = "steel battle axe",
				count = 1
			})
			mwscript.addItem({
				reference = tes3.player,
				item = "bookskill_axe2",
				count = 1
			})
        end,

		callback = function()
            
            -- set bounty at minimum 10k
            local function setBounty()
                local data = getData()
                if data.currentBackground == "axe_murderer" then
                    if ( tes3.mobilePlayer.bounty < 10000 ) then
                        tes3.mobilePlayer.bounty = 10000
                    end
                end
            end
            
            -- set bounty once per minute
            local function startTimer()
                timer.start({
                    duration =  60,
                    callback = setBounty,
                    iterations = -1
                })
            end
            
			if axeMurdererDoOnce then
				return false
			end
            
            axeMurdererDoOnce = true
            startTimer()
        end
    }
    interop.addBackground(axeMurdererBackground)

end

event.register("initialized", onInit)
