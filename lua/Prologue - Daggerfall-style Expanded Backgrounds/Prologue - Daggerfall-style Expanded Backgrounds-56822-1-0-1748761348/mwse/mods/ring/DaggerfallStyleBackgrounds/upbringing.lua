--[[
    - What province did you grow up in? +10 Disposition with native race
    - What environment did you grow up in? +10 Disposition with associated factions and classes, -/+5 attribute bonuses
        - Wilderness (+Endurance, +Willpower, -Personality)
        - Village (+Strength, +Personality, -Intelligence)
        - City (+Agility, +Intelligence, -Strength)
        - Metropolitan (+Speed, +Luck, -Willpower)
    - What social class are you? +10 Disposition with associated social classes, affects starting gold
        - Vagrant 0 
        - Commoner 50
        - Wealthy 250
        - Nobility 500
    - Which of your skills would you say you've spent the longest training in? +5 to chosen Major skill
    - Your mother was a %playerRace, but what race was your father? 1 random skill and attribute bonus, +5 Disposition with chosen race

    You grew up in a/the [environment] of [province] as a [socialClass],
    raised by
        (a [playerRace] and [fatherRace])
        OR (two [playerRace]s)
        OR (your [playerRace] mother alone with an unknown father)
        OR (the streets/wilds as an urchin).
    You trained extensively in [majorSkill] under [mentor], and have displayed a natural affinity for it.
    When you came of age, you chose the life of a [class] in search of [motivation].
    Your journey has brought you to the land of Morrowind, where your fate has yet to be decided...

]]

local upbringing = {}
local doOnce = false

event.register("loaded", function (e)
    if e.newGame then
        doOnce = false
    end
end)

upbringing.data = {}

upbringing.current = {
    province = {
        name = "None",
        value = "None",
    },
    environment = {
        name = "Wilderness",
        value = "Wilderness",
    },
    socialClass = {
        name = "Commoner",
        value = 50,
    },
    majorSkill = {
        name = nil,
        value = nil,
    },
    mentor = {
        name = "Your Mother",
        value = "your mother",
    },
    motivation = {
        name = "Riches",
        value = "riches",
    },
}

upbringing.currentClass = nil
upbringing.currentRace = nil

function upbringing.initData()
    if doOnce then
        return upbringing.data
    end
    doOnce = true
    upbringing.current.fatherRace = {
        name = tes3.dataHandler.nonDynamicData.races[1].name,
        value = tes3.dataHandler.nonDynamicData.races[1].id,
    }
    upbringing.data = {
        province = {
            description = "What province did you grow up in?",
            options = {
                ["None"] = {
                    description = "You are a traveler who has no specific province to call home.",
                },
                ["Black Marsh"] = {
                    description = "You grew up in the swamps and marshes of Black Marsh amongst the Argonians.",
                    race = "Argonian"
                },
                ["Cyrodiil"] = {
                    description = "You grew up in the heart of the Empire, surrounded by Imperial culture and traditions.",
                    race = "Imperial"
                },
                ["Elsweyr"] = {
                    description = "You grew up in the arid deserts and lush jungles of Elsweyr, home of the Khajiit and their sacred Moon Sugar.",
                    race = "Khajiit"
                },
                ["Hammerfell"] = {
                    description = "You grew up in the rugged deserts and mountains of Hammerfell, land of the Redguard.",
                    race = "Redguard"
                },
                ["High Rock"] = {
                    description = "You grew up in the feudal lands of High Rock, known for its Bretons and their magical prowess.",
                    race = "Breton"
                },
                ["Skyrim"] = {
                    description = "You grew up in the cold and mountainous province of Skyrim, land of the Nords.",
                    race = "Nord"
                },
                ["Summerset Isles"] = {
                    description = "You grew up in the beautiful and mystical Summerset Isles, home of the Altmer and birthplace of elvenkind.",
                    race = "Altmer"
                },
                ["Valenwood"] = {
                    description = "You grew up in the dense forests of Valenwood, home of the Bosmer and the migratory trees they live in.",
                    race = "Bosmer"
                },
                ["Orsinium"] = {
                    description = "You grew up in the mountainous strongholds of Orsinium, the battle-worn sanctuary for Orcs.",
                    race = "Orc"
                }
            },
            tooltip = {
                header = "Province",
                description = "Provides +10 disposition with that region's native race."
            }
        },
        environment = {
            description = "What environment did you grow up in?",
            options = {
                ["Wilderness"] = {
                    description = "You grew up in the wilds, learning to survive in the harshest of conditions.",
                    bonuses = {
                        { attribute = tes3.attribute.endurance, value = 5 },
                        { attribute = tes3.attribute.willpower, value = 5 },
                        { attribute = tes3.attribute.personality, value = -5 }
                    }
                },
                ["Village"] = {
                    description = "You grew up in a small village, surrounded by nature and close-knit communities.",
                    bonuses = {
                        { attribute = tes3.attribute.strength, value = 5 },
                        { attribute = tes3.attribute.personality, value = 5 },
                        { attribute = tes3.attribute.intelligence, value = -5 }
                    }
                },
                ["City"] = {
                    description = "You grew up in a bustling city, filled with opportunities and challenges.",
                    bonuses = {
                        { attribute = tes3.attribute.agility, value = 5 },
                        { attribute = tes3.attribute.intelligence, value = 5 },
                        { attribute = tes3.attribute.strength, value = -5 }
                    }
                },
                ["Metropolitan"] = {
                    description = "You grew up in a large metropolitan area, exposed to diverse cultures and lifestyles.",
                    bonuses = {
                        { attribute = tes3.attribute.speed, value = 5 },
                        { attribute = tes3.attribute.luck, value = 5 },
                        { attribute = tes3.attribute.willpower, value = -5 }
                    }
                }
            },
            tooltip = {
                header = "Environment",
                description = "Affects your attribute bonuses."
            }
        },
        socialClass = {
            description = "What social class did you belong to?",
            options = {
                ["Vagrant"] = {
                    description = "You grew up with nothing, learning to fend for yourself in a harsh world.",
                    startingGold = 0
                },
                ["Commoner"] = {
                    description = "You grew up in a modest household, with enough to get by.",
                    startingGold = 50
                },
                ["Wealthy"] = {
                    description = "You grew up in a wealthy family, never wanting for much.",
                    startingGold = 250
                },
                ["Nobility"] = {
                    description = "You grew up in the lap of luxury, with all the privileges of a royal.",
                    startingGold = 1250
                }
            },
            tooltip = {
                header = "Social Class",
                description = "Affects your starting gold."
            }
        },
        fatherRace = {
            description = "Your mother was a " ..tes3.player.object.race.name.. ", but what race was your father?",
            options = {},
            tooltip = {
                header = "Father's Race",
                description = "Grants a random skill and attribute bonus, and a +5 disposition bonus with the chosen race. Or be an orphan!"
            },
        },
        majorSkill = {
            description = "Which of your major skills would you say you've spent the longest training in?",
            options = {},
            tooltip = {
                header = "Best Skill",
                description = "Gives you a +5 bonus to that skill."
            }
        },
        mentor = {
            description = "Who mentored you?",
            options = {
                ["Your mother"] = "your mother",
                ["Your father"] = "your father",
                ["A family friend"] = "a family friend",
                ["A local hero"] = "a local hero",
                ["A wandering adventurer"] = "a wandering adventurer",
                ["A wise elder"] = "a wise elder"
            },
            tooltip = {
                header = "Mentor",
                description = "Select who mentored you in your upbringing. This will provide a narrative context for your character's background."
            },
        },
        motivation = {
            description = "What motivated you to become a "..tes3.player.object.class.name.."?",
            options = {
                ["Riches"] = "riches",
                ["Fame"] = "fame",
                ["Knowledge"] = "knowledge",
                ["Fun"] = "fun",
                ["Purpose"] = "purpose",
                ["Adventure"] = "adventure",
                ["Revenge"] = "revenge",
                ["Redemption"] = "redemption",
                ["Power"] = "power",
                ["Freedom"] = "freedom",
                ["Love"] = "love",
                ["Honor"] = "honor",
                ["Glory"] = "glory",
                ["Wisdom"] = "wisdom",
                ["Wealth"] = "wealth",
                ["Fate"] = "fate",
                ["Justice"] = "justice",
                ["Discovery"] = "discovery",
                ["Spirituality"] = "spirituality"
            },
            tooltip = {
                header = "Motivation",
                description = "This will provide a narrative context for your character goals."
            }
        }
    }
    upbringing.data.fatherRace.options["Unknown"] = {
        description = "Your mother was a " .. tes3.player.object.race.name .. ", like you, but you don't know who your father was. Provides no bonuses.",
    }
    upbringing.data.fatherRace.options["Orphaned"] = {
        description = "You were orphaned at a young age, with no parents to speak of. Provides no bonuses.",
    }

    for _, value in ipairs(tes3.dataHandler.nonDynamicData.races) do
        if not (value.description == nil or value.description == "(nil)") then
            upbringing.data.fatherRace.options[value.id] = {
                description = value.description,
                name = value.name,
            }
        end
    end
    upbringing.current.majorSkill.name = tes3.getSkillName(tes3.player.object.class.majorSkills[1])
    upbringing.current.majorSkill.value = tes3.player.object.class.majorSkills[1]
    for i, skill in ipairs(tes3.player.object.class.majorSkills) do
        upbringing.data.majorSkill.options[tes3.getSkillName(skill)] = {
            description = "You have trained extensively in " .. skill .. ".",
            id = skill
        }
    end
    return upbringing.data
end

function upbringing.flavorText(isJournal)
    local text = "Born under "..tes3.mobilePlayer.birthsign.name .." sign, you grew up in "
    if upbringing.current.environment.name == "Wilderness" then
        text = text .. "the wilds of "
    elseif upbringing.current.environment.name == "Metropolitan" then
        text = text .. "a bustling metropolis in "
    else
        text = text .. "a " .. upbringing.current.environment.name:lower().." in "
    end
    text = text..upbringing.current.province.name .. " as a "..upbringing.current.socialClass.name:lower() .. ", raised by "
    if upbringing.current.fatherRace == "Unknown" then
        text = text .. "your " .. tes3.player.object.race.name .. " mother alone with an unknown father."
    elseif upbringing.current.fatherRace.name == "Orphaned" then
        if upbringing.current.environment.name == "Wilderness" then
            text = text .. "the wilds as an urchin."
        else
            text = text .. "the streets as an urchin."
        end
    else
        if upbringing.current.fatherRace.name == tes3.player.object.race.name then
            text = text .. "your " .. tes3.player.object.race.name .. " mother and father."
        else
            text = text .. "a " .. tes3.player.object.race.name .. " mother and " .. upbringing.current.fatherRace.name .. " father."
        end
    end
    text = text .. " You trained extensively in " .. upbringing.current.majorSkill.name .. " under " .. upbringing.current.mentor.value .. ", and have displayed a natural affinity for it."
    text = text .. " When you came of age, you chose the life of a " .. upbringing.currentClass.name .. " in search of " .. upbringing.current.motivation.name:lower() .. "."
    if isJournal then
        text = text.."<BR><BR> "
    else
        text = text.."\n\n"
    end
    text = text.."Your journey has brought you to the land of Morrowind, where your "..upbringing.current.motivation.name:lower().." may yet be found..."
    return text
end

return upbringing