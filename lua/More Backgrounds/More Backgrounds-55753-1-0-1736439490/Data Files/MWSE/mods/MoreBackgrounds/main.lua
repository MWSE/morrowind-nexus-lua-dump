--make sure personality can't be raised on level for Scion of the Sixth House background.
local function scionPersonality()
    tes3.setStatistic({
        reference = tes3.player,
        attribute = tes3.attribute.personality,
        value = 20
    })
end

--increase skill by one extra when a skillbook is read
local function bookraise(e)
    if (e.source == "book") then
        tes3.modStatistic({
        reference = tes3.player,
        skill = e.skill,
        value = 1,
        })
        tes3.messageBox("Because you are a bookworm, your ".. tes3.skillName[e.skill].. " skill went up by one more to ".. e.level+1 .. 
            ".")
    end
end

--make guar and scrib aggressive
local function woodlandaggro(e)
    local animal1 = string.sub(e.reference.id, 1, 5)
    local animal2 = string.sub(e.reference.id, 1, 4)
    if (animal1 == "scrib") then
        e.reference.mobile.fight = 100
    end
    if (animal2 == "guar") then
        e.reference.mobile.fight = 100
    end
end

--check the hight of the bounty and if the spells have alredy been removed
local function bountyAmount()
    local removal
    if (tes3.hasSpell({reference =tes3.mobilePlayer, spell = "MB_Tr_Favor"}) == true) then
        removal = true
    else
        removal = false
    end
    if (removal == true) then
        if (tes3.mobilePlayer.bounty >= 40)  then
            tes3.removeSpell({
                reference = tes3.player,
                spell = "MB_Tr_Favor"
            })
            tes3.removeSpell({
                reference = tes3.player,
                spell = "MB_shield_of_honor"
            })
            tes3.messageBox("Because of your crimes you have forfeited your honor. Trinimac withdraws his protection from you.")
        end
    end
end

--check if the blade is still in inventory and if reputation is high enough
local function akaviriFame()
    local hasblade
    if (tes3.getItemCount({reference = tes3.mobilePlayer, item = "MB_akaviri_blade"}) >= 1) then
        hasblade = true
    else
        hasblade = false
    end
    if (tes3.player.object.reputation >= 20) then
        if (hasblade == true) then
            tes3.removeItem({
                reference = tes3.player,
                item = "MB_akaviri_blade",
                playSound = false
            })
            tes3.addItem({
                reference = tes3.player,
                item ="MB_akaviri_blade_rep",
                playSound = false
            })
            tes3.messageBox({message ="Your fame has made your sword more agreeable to you. It will now help instead of harm you.", 
            buttons ={"Finally!"}})
        end
    end
end

local function akaviriCallback()
    event.register(tes3.event.journal, akaviriFame)
end    

--register bounty check for echoes of trinimac
local function trinimacCallback()
    event.register(tes3.event.crimeWitnessed, bountyAmount)
end

--register guar and scrib as hostile each time a new area is loaded for denying the green
local function denyCallback()
    event.register(tes3.event.mobileActivated, woodlandaggro)
end

--register the extra skill up for Bookworm
local function bookwormCallback()
    event.register(tes3.event.skillRaised, bookraise)
end

--register the effecr for Scion of the Sixth House
local function scionCallback()
    event.register(tes3.event.levelUp, scionPersonality)
end

--make sure the effects don't happen on other saves
local function endevent()
    event.unregister(tes3.event.levelUp, scionPersonality)
    event.unregister(tes3.event.skillRaised, bookraise)
    event.unregister(tes3.event.mobileActivated, woodlandaggro)
    event.unregister(tes3.event.crimeWitnessed, bountyAmount)
    event.unregister(tes3.event.journal, akaviriFame)
end

local function newbackgrounds ()
local interop = require("mer.characterBackgrounds.interop")

--Make sure the MoreBackgrounds.ESP is active
if not tes3.isModActive("MoreBackgrounds.ESP") then
    tes3.messageBox("Activate MoreBackgrounds to get access to the new backgrounds.")
    return
end

local Legionnaire = {
    id = "legionnaire",
    name = "Ex-Legionnaire",
    description = ("Long marches and fighting in a shield-wall have honed your skills and made you tough. "..
        "Unfortunately, a lifetime of following orders has critically impacted your decison-making skills. "..
        "(+10 to Endurance, Athletics, Block, Heavy Armor and Long Blade. -20 to Willpower.)"),
    doOnce = function()
    tes3.modStatistic({
        reference = tes3.player,
        attribute = tes3.attribute.endurance,
        value = 10
        })

    tes3.modStatistic({
        reference = tes3.player,
        skill = tes3.skill.heavyArmor,
        value = 10
        })

    tes3.modStatistic({
        reference = tes3.player,
        skill = tes3.skill.athletics,
        value = 10
        })

    tes3.modStatistic({
        reference = tes3.player,
        skill = tes3.skill.block,
        value = 10
        })

    tes3.modStatistic({
        reference = tes3.player,
        skill = tes3.skill.longBlade,
        value = 10
        })
    
    tes3.modStatistic({
        reference = tes3.player,
        attribute = tes3.attribute.willpower,
        value = -20
        })

    end,
    }
interop.addBackground(Legionnaire)
    
local KnowItAll = {
    id = "knowitall",
    name = "Know-It-All",
    description = ("You are the smartest person in the room, and you're not afraid to let people know it. "..
                    "Somehow, this doesn't endear you to them. (+ 30 Intelligence, -30 Personality.)"),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = 30
            })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -30
            })
    end,
    }
interop.addBackground(KnowItAll)

local Lucky = {
    id = "lucky",
    name = "Lucky",
    description = ("You have always been incredibly lucky. Unfortunately this has left you to coast by on your luck alone and "..
                "neglect everything else. (Luck set to 100, all other pre-birthsign attributes to 10, all skills to 5.)"),
    doOnce = function()
        tes3.setStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck,
            value = 100
            })

        local index = 0  
        local diff = { (tes3.mobilePlayer.strength.base - tes3.player.object.attributes[1]), 
            (tes3.mobilePlayer.intelligence.base - tes3.player.object.attributes[2]),
            (tes3.mobilePlayer.willpower.base - tes3.player.object.attributes[3]), 
            (tes3.mobilePlayer.agility.base - tes3.player.object.attributes[4]), 
            (tes3.mobilePlayer.speed.base - tes3.player.object.attributes[5]),
            (tes3.mobilePlayer.endurance.base - tes3.player.object.attributes[6]), 
            (tes3.mobilePlayer.personality.base - tes3.player.object.attributes[7])}
	    while ( index < 7 ) do
		    tes3.setStatistic({
		    	reference = tes3.player,
			    attribute = index,
			    value = ( 10 + diff[index+1]),
		    })
		    index = index + 1
	    end

        index = 0
	    while ( index < 27 ) do
		    tes3.setStatistic({
			    reference = tes3.player,
			    skill = index,
			    value = 5,
		    })
		    index = index + 1
	    end
    end,
    }
interop.addBackground(Lucky)

local WarpedMind={
    id = "warpedmind",
    name = "Warped Mind",
    description = ("You witnessed the Warp in the West. All times of it. This has driven you irrevocably insane. "..
    "You have strange knowledge, but neither the will, nor the ability to express it. "..
    "(+40 Intelligence, Mysticism, -25 Personality, Willpower, Speechcraft. Sight of Madness: Detect Animal, Key and Enchantment Spell)"..
    "\n\nRequirements: Bretons only"
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Breton"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = 40
            })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -25
            })
        
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower,
            value = -25
            })

        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism,
            value = 40
            })

        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = -25
            })
            
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_mad_sight"
        })
    end,
}
interop.addBackground(WarpedMind)

local SixthScion = {
    id = "sixthscion",
    name = "Scion of the Sixth House",
    description = ("Unbeknownst to you, you are a descendant of a member of the Sixth House. "..
    "You are more susceptible to blight disease, and people are instinctively wary of you, ".. 
    "but you have incredible powers of manipulation. (75% vulnerability to Blight, Personality permanently limited to 20. "..
    "Calm, Charm, Demoralize, and Frenzy Powers.)\n\nRequirements: Dark Elf Only"),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function ()
        tes3.setStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = 20 
            })
        
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_blighted"
        })

        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_scion_calm"
        })

        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_scion_charm"
        })

        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_scion_fear"
        })

        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_scion_frenzy"
        })
    end,
    callback = scionCallback
}
interop.addBackground(SixthScion)

local ClawDancer ={
    id = "clawdancer",
    name = "Claw-Dancer",
    description = ("You have studied your people's martial arts in the monasteries in Elsweyr, and have grown skilled in them. "..
        "However, because of this you have no skills in fighting in any kind of armor (+10 Speed and Agility, "..
        "+25 Hand-to-Hand, Unarmored, Acrobatics and Athletics, all Armor skills 0. Claw-Dance: Fortify Attack, Agility, "..
        "Hand-to-Hand, Acrobatics Power.)\n\nRequirements: Khajiit only,"),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Khajiit"
    end,
    doOnce = function ()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed,
            value = 10
            })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility,
            value = 10
            })

        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.handToHand,
            value = 25
            })
            
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored,
            value = 25
            })
        
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics,
            value = 25
            })

        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics,
            value = 25
            })

        tes3.setStatistic({
            reference = tes3.player,
            skill = tes3.skill.lightArmor,
            value = 0
            })

        tes3.setStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor,
            value = 0
            })
        
        tes3.setStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor,
            value = 0
            })
            
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_claw_dance"
        })
    end
}
interop.addBackground(ClawDancer)

local SwordSinger ={
    id = "swordsinger",
    name = "Sword-Singer",
    description = ("You dedicated your life to the path of the Sword-Singer and have learnt to manifest your spirit sword. "..
        "However, this dedication to a singular path has left your other combat skills to atrophy. "..
        "(+20 to Long Blade, +20 to Agility, all weapon plus block skills set to 0. Spirit Sword: Bound Sword and Fortify Attack Spell.)"..
        "\n\nRequirements: Redguard only."),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function ()
        local weaponskills ={
            tes3.skill.axe,
            tes3.skill.bluntWeapon,
            tes3.skill.handToHand,
            tes3.skill.marksman,
            tes3.skill.spear,
            tes3.skill.shortBlade,
            tes3.skill.block,
        }
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility,
            value = 20
            }) 
            
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade,
            value = 20
            })
        
        for _, skill in ipairs(weaponskills) do
            tes3.setStatistic({
                reference = tes3.player,
                skill = skill,
                value = 0
                })
        end
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_spirit_sword"
        })
    end
}
interop.addBackground(SwordSinger)

local ApprenticeGreybeard = {
    id = "apprenticeGreybeard",
    name = "Apprentice Greybeard",
    description =("You studied with the Greybeards at the Throat of the World. You learned many things and the cold made you hardy "..
        "and not easily paralyzed by its bite, but it also crept in your bones and the isolation didn't do your social skills much good."..
        "( +20 Endurance, 30% Paralysis Resistance, -20 Agility, Speed, and Personality, Speechcraft set to 0. 6 Shout-themed Powers.)"..
        "\n\nRequirements: Nord only"),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Nord"
    end,
    doOnce = function ()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance,
            value = 20
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility,
            value = -20
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed,
            value = -20
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -20
        })
        tes3.setStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 0
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_mountain"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_breath_north"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_scale_dragon"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_shors_bones"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_stormcrown"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_thundering_voice"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_voice_of_kyne"
        })
    end
}

interop.addBackground(ApprenticeGreybeard)
local FailedPsijic ={
    id = "failedpsijic",
    name = "Failed Psijic",
    description = ("You were expelled from the Psijic Order for studying forbidden knowledge. You still have the knowledge, "..
        "but the shame of your expulsion weighs heavily on you. (+10 Intelligence, -20 Willpower, +10, Mysticism and Conjuration "..
        "Whisper of the Worm King: Summon Bonlord and Greater Bonewalker Power, Psjjjj: Fortfy Int and Mysticism spell.)"..
        "\n\nRequirements: High Elf only."),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "High Elf"
    end,
    doOnce = function ()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower,
            value = -20
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration,
            value = 10
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_worm_king"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_Psj"
        })
    end
}
interop.addBackground(FailedPsijic)

local Bookworm ={
    id = "bookworm",
    name ="Bookworm",
    description = ("You have spent your life inside with your nose in a book. This made you physically weak, but lets you learn better "..
        "from books. (-10 Strength, and Endurance. Double skills from skillbooks.)"),
    doOnce= function ()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance,
            value = -10
        })
    end,
    callback = bookwormCallback
}
interop.addBackground(Bookworm)

local CutoffHist = {
    id = "cutoffHist",
    name = "Cut off from the Hist",
    description = ("Unlike the rest of your people, you have no connection to the Hist. This means you don't have the ancestral "..
        "resistance to disease and poison, but you seem somehow less connected to the Earthbones. Some days you think you "..
        "can just jump and never come down, but you haven't given in to temptation...yet. (No Poison Immunity and Disease "..
        "Resistance, 5 pts constant Jump effect, Reach for the Stars: Fortify Acrobatics Power.)\n\nRequirements: Argonian only"),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function ()
        tes3.removeEffects({
            reference = tes3.player,
            effect = 94
        })

        tes3.removeEffects({
            reference = tes3.player,
            effect = 97
        })

        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_release"
        })

        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_reach_stars"
        })
    end,
}
interop.addBackground(CutoffHist)

local TrinimacEchoes ={
    id ="trinimacEchoes",
    name = "Echoes of Trinimac",
    description = ("From a young age echoes of the Ancestral Warrior God whispered to you, strengthening your convictions "..
        "and guarding your honor. You have denounced the skills of the dishonorable and intend to make your way as a noble warrior."..
        " Though you know that should you falter on your path Trinimac will forsake you (+10 Willpower, +5 Weapon and Armor Skills."..
        " Sneak, Security, and Illusion set to 0. Shield of Honor: Bound Shield and Shield Spell."..
        " Trinimac's Favor: Fortify Attack 5 Ability. Both are lost permanently on bounty 0f 40 or higher.)\n\nRequirements: Orc only."),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function ()
        local trinimacSkills = {
            tes3.skill.axe,
            tes3.skill.bluntWeapon,
            tes3.skill.lightArmor,
            tes3.skill.marksman,
            tes3.skill.spear,
            tes3.skill.shortBlade,
            tes3.skill.block,
            tes3.skill.mediumArmor,
            tes3.skill.heavyArmor,
        }
        local sneakSkills = {
            tes3.skill.sneak,
            tes3.skill.security,
            tes3.skill.illusion,
        }
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower,
            value = 10
        })
        for _, skill in ipairs(sneakSkills) do
            tes3.setStatistic({
                reference = tes3.player,
                skill = skill,
                value = 0
                })
        end
        for _, skill in ipairs(trinimacSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = 5
                })
        end
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_shield_of_honor"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_Tr_Favor"
        })
    end,
    callback = trinimacCallback
}
interop.addBackground(TrinimacEchoes)

local AkaviriAncestry = {
    id = "akaviriancestry",
    name = "Akaviri Ancestry",
    description = ("You are in part descended from the Akaviri who invaded Cyrodiil during the Reman Empire. You carry an "..
        "ancestral Akaviri blade of great power, but unfortunately because you are no true Akaviri, using it cuts you almost ".. 
        "as deeply as your enemy. Though, you feel that if you get famous enough, the blade might overlook that."..
        " However, your blood does protect you from poison somewhat. (Resist Poison Ability, Katana, at Reputation 20 the katana gets"..
        " switched to one with a healing enchantment.)\n\nRequirements: Imperial only."),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Imperial"
    end,
    doOnce = function ()
        tes3.addItem({
            reference = tes3.player,
            item = "MB_akaviri_blade",
            playSound = false
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_akaviri_sanctuary"
        })
    end,
    callback = akaviriCallback
}
interop.addBackground(AkaviriAncestry)

local DenyingGreen ={
    id = "denyinggreen",
    name = "Denying the Green",
    description = ("You were born far from Valenwood, and you think the Green Pact is superstitious nonsense. You like "..
        "vegetables, and anyways, plants are useful for alchemy. You're certainly not more susceptible to disease than your "..
        "fellow Wood Elves and it is just coincidence that otherwise peaceful animals keep attacking you."..
        " (+10 Alchemy, 25% weakness to disease instead of resistance. (Un)Healthy Scepticism: Reflect Spell. Stir the Green: Frenzy Power. "..
        "Guar and Scrib are hostile.)\n\nRequirements: Wood Elf only"),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function ()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy,
            value = 10
        })
        tes3.removeEffects({
            reference = tes3.player,
            effect = 94
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_denial"
        })
        tes3.addSpell({
            reference = tes3.player,
            spell = "MB_sceptic"
        })
    end,
    callback = denyCallback
}
interop.addBackground(DenyingGreen)

event.register(tes3.event.loaded, endevent, { priority = 99 })
print("[MoreBackgrounds] MoreBackgrounds Initialized")

end
event.register(tes3.event.initialized, newbackgrounds)

