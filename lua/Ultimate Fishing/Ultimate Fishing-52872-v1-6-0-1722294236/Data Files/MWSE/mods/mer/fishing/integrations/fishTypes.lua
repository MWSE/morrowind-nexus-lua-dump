--[[
    Register default fish types
]]
local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("Integrations - fishTypes")
local Interop = require("mer.fishing")

---@class Fishing.Integration.FishConfigs
---@field common Fishing.FishType.new.params[]
---@field uncommon Fishing.FishType.new.params[]
---@field rare Fishing.FishType.new.params[]
---@field legendary Fishing.FishType.new.params[]
local fishConfigs = {
    common = {
        {
            baseId = "mer_fish_trout",
            previewMesh = "mer_fishing\\f\\br_trout.nif",
            description = "The trout is a common freshwater fish found in the shallows of rivers and lakes. They are active during dawn and dusk.",
            speed = 165,
            size = 1.2,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            habitat = {
                times = { "dawn", "dusk" },
                waterType = "freshwater",
            },
        },
        {
            baseId = "mer_fish_mudcrab",
            previewMesh = "mer_fishing\\f\\mudcrab.nif",
            description = "The mudcrab is a common species of crab capable of camouflaging itself as a small rock. While adult mudcrabs are too large to be caught by anglers, juveniles are abundant in shallow waters.",
            speed = 50,
            heightAboveGround = 15,
            size = 1.4,
            difficulty = 15,
            class = "medium",
            habitat = {
                interiors = true,
                exteriors = true,
                maxDepth = 300,
            },
            harvestables = {
                {
                    id = "ingred_crab_meat_01",
                    min = 1,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "mer_crabshell",
                    min = 1,
                    max = 1,
                }
            }
        },
        {
            baseId = "mer_fish_bass",
            previewMesh = "mer_fishing\\f\\bass.nif",
            description = "The bass is a popular freshwater game fish found in lakes, rivers, and ponds. Known for its aggressive behavior and strength, it is a favorite among sport fishermen.",
            speed = 170,
            size = 1.5,
            difficulty = 30,
            class = "medium",
            habitat = {
                climates = {"temperate", "tropical"},
                waterType = "freshwater",
                minDepth = 100,
            },
            harvestables = {
                {
                    id = "mer_meat_bass",
                    min = 1,
                    max = 4,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_seabass",
            previewMesh = "mer_fishing\\f\\seabass.nif",
            description = "The sea bass is a saltwater fish known for its distinctive black stripes and aggressive nature. It is commonly found in the coastal waters of Vvardenfell.",
            speed = 180,
            size = 1.8,
            difficulty = 35,
            class = "medium",
            habitat = {
                climates = {"temperate", "tropical", "swamp"},
                waterType = "saltwater",
                times = { "day" },
            },
            harvestables = {
                {
                    id = "mer_meat_seabass",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_tuna",
            previewMesh = "mer_fishing\\f\\tuna.nif",
            description = "The tuna is a large, fast-swimming fish found in the open ocean. Known for its speed and strength, the tuna is a prized catch among anglers. It is most active during the day.",
            speed = 240,
            size = 4.3,
            difficulty = 56,
            class = "large",
            habitat = {
                climates = {"temperate", "tropical", "swamp"},
                waterType = "saltwater",
                times = { "day" },
                minDepth = 250,
            },
            harvestables = {
                {
                    id = "mer_meat_tuna",
                    min = 4,
                    max = 7,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_goby",
            previewMesh = "mer_fishing\\f\\goby.nif",
            description = "The goby is a small, often colorful fish found in both freshwater and marine environments in warmer regions. They are active during the day.",
            speed = 150,
            size = 1.1,
            difficulty = 20,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"temperate", "tropical"},
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_salmon",
            previewMesh = "mer_fishing\\f\\salmon.nif",
            description = "Salmon are anadromous fish known for their remarkable life cycle, where they hatch in freshwater streams, migrate to the ocean to grow, and return to freshwater to spawn.",
            speed = 200,
            size = 2.1,
            difficulty = 40,
            class = "medium",
            habitat = {
                climates = {"temperate"},
                times = { "day" },
                minDepth = 100,
            },
            harvestables = {
                {
                    id = "mer_meat_salmon",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_slaughter_l",
            previewMesh = "mer_fishing\\f\\sfish_l.nif",
            description = "The slaughterfish is a formidable predator found throughout the waters of Tamriel. Although its meat may be unappetizing, its scales are considered a delicacy.",
            speed = 180,
            size = 3.0,
            difficulty = 50,
            class = "large",
            habitat = {
                interiors = true,
                exteriors = true,
            },
            harvestables = {
                {
                    id = "ab_ingcrea_sfmeat_01",
                    min = 1,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "ingred_scales_01",
                    min = 2,
                    max = 4,
                }
            }
        },
        {
            baseId = "mer_fish_slaughter_sm",
            previewMesh = "mer_fishing\\f\\sfish_sm.nif",
            description = "Juvenile Slaughterfish can be found in waters all over Tamriel. Even in their smaller form, they can put up a spirited fight",
            speed = 170,
            size = 1.1,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            habitat = {
                interiors = true,
                exteriors = true,
            },
        },
        {
            baseId = "mer_fish_trigger",
            previewMesh = "mer_fishing\\f\\trigger.nif",
            description = "The triggerfish is a small saltwater fish known for its bright colors and unique shape. It is found in coral reefs and rocky coastal areas and is known for its strong jaws and aggressive nature.",
            speed = 190,
            size = 1.0,
            difficulty = 15,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical", "swamp"},
                waterType = "saltwater",
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_catfish",
            previewMesh = "mer_fishing\\f\\catfish.nif",
            description = "The catfish is named for its prominent barbels, which resemble a cat's whiskers. It can be found in swamps.",
            speed = 160,
            size = 1.0,
            difficulty = 31,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"swamp"},
                waterType = "freshwater",
                interiors = true,
                exteriors = true
            },
        },
        {
            baseId = "mer_fish_sculpin",
            previewMesh = "mer_fishing\\f\\sculpin.nif",
            description = "The sculpin is a small fish that inhabits both freshwater and saltwater environments. With its unassuming size, the sculpin serves as excellent bait for targeting larger prey.",
            speed = 165,
            size = 1.0,
            difficulty = 22,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"temperate", "arctic"},
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_cod",
            previewMesh = "mer_fishing\\f\\cod.nif",
            description = "The cod is a medium-sized saltwater fish found in the deeper waters of the Inner Sea. Renowned for its delectable meat, the cod is a prized catch among anglers and culinary enthusiasts alike. Its firm, white flesh and mild flavor make it a versatile ingredient in various dishes.",
            speed = 150,
            size = 1.5,
            difficulty = 42,
            class = "medium",
            harvestables = {
                {
                    id = "mer_meat_cod",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            },
            habitat = {
                climates = {"temperate", "arctic", "tropical"},
                waterType = "saltwater",
                times = { "day" },
                minDepth = 200,
            },
        },
    },
    uncommon = {
        {
            baseId = "mer_fish_barracuda",
            previewMesh = "mer_fishing\\f\\barracuda.nif",
            description = "The barracuda is a predatory fish known for its fearsome appearance and aggressive behavior. While edible, meat from adult barracuda can be toxic.",
            speed = 230,
            size = 1.8,
            difficulty = 60,
            class = "medium",
            habitat = {
                climates = {"tropical", "swamp"},
                waterType = "saltwater",
                minDepth = 200,
            },
            harvestables = {
                {
                    id = "mer_meat_barracuda",
                    min = 1,
                    max = 2,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_piranha",
            previewMesh = "mer_fishing\\f\\piranha.nif",
            description = "The piranha is a small, carnivorous fish found in the fresh waters of Vvarrdenfell. With its sharp teeth and aggressive behavior, the piranha is a formidable predator that strikes fear into the hearts of anglers.",
            speed = 185,
            size = 0.9,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
                interiors = true,
                exteriors = true,
                maxDepth = 300,
            }
        },
        {
            baseId = "mer_fish_tambaqui",
            previewMesh = "mer_fishing\\f\\tambaqui.nif",
            description = "The tambaqui is a large freshwater fish. With its impressive size and striking appearance, this species captivates the imaginations of anglers seeking a thrilling challenge in their pursuit.",
            speed = 170,
            size = 2.0,
            difficulty = 43,
            class = "medium",
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
                minDepth = 100,
            },
            harvestables = {
                {
                    id = "mer_meat_tambaqui",
                    min = 2,
                    max = 5,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_arowana",
            previewMesh = "mer_fishing\\f\\arowana.nif",
            description = "Also known as bony tongues, arowanas are uncommon fish found in freshwater during daylight hours.",
            speed = 175,
            size = 1.1,
            difficulty = 35,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
                times = {
                    "day"
                }
            },
        },
        {
            baseId = "mer_fish_angelshark",
            previewMesh = "mer_fishing\\f\\angel.nif",
            description = "The Angelshark is a small yet formidable species of shark that can be found throughout the saltwater shallows of Tamriel. They are most active at night.",
            speed = 180,
            size = 2.1,
            class = "large",
            difficulty = 55,
            habitat = {
                climates = {"temperate", "tropical", "swamp"},
                waterType = "saltwater",
                times = { "night" },
                maxDepth = 400,
            },
            harvestables = {
                {
                    id = "mer_meat_angelshark",
                    min = 1,
                    max = 1,
                    isMeat = true,
                }
            },
            heightAboveGround = 40,
        },
        {
            baseId = "mer_fish_marrow",
            previewMesh = "mer_fishing\\f\\marrow.nif",
            description = "The marrowfish is a peculiar creature with bulging eyes and an oily red body. Its rarity and unique habitat within caves make it a true discovery for adventurous anglers. Beyond its captivating appearance, the marrowfish possesses powerful alchemical properties, making it a sought-after specimen among practitioners of the arcane arts.",
            speed = 180,
            size = 1.8,
            difficulty = 70,
            class = "medium",
            habitat = {
                interiors = true,
                exteriors = false,
            },
            harvestables = {
                {
                    id = "mer_meat_marrow",
                    min = 2,
                    max = 4,
                    isMeat = true,
                },
            }
        },
    },
    rare = {
        {
            baseId = "mer_fish_sturgeon",
            previewMesh = "mer_fishing\\f\\sturgeon.nif",
            description = "The sturgeon is a massive, formidable fish boasting a long, sleek body and a distinctive row of bony plates along its back. These ancient creatures can be foundfreshwater habitats, impressing anglers with their sheer size and strength.",
            speed = 200,
            size = 2.0,
            difficulty = 68,
            class = "large",
            habitat = {
                climates = {"temperate", "arctic"},
                waterType = "freshwater",
                minDepth = 300,
            },
            harvestables = {
                {
                    id = "ab_ingcrea_sturgeonmeat01",
                    min = 3,
                    max = 6,
                    isMeat = true,
                },
                {
                    id = "ab_ingcrea_sturgeonroe",
                    min = 0,
                    max = 1,
                }
            },
            requirements = function(_)
                return tes3.isModActive("OAAB_Data.esm")
            end
        },
        {
            baseId = "mer_fish_discus",
            previewMesh = "mer_fishing\\f\\discus.nif",
            description = "The discus is a visually captivating fish with vibrant colors, inhabiting rivers all over Tamriel. This uncommon species adds a touch of exotic beauty to the waters it calls home, making it a desirable catch for anglers seeking unique and eye-catching specimens.",
            speed = 170,
            size = 1.0,
            difficulty = 47,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
            },
        },
        {
            baseId = "mer_fish_jelly",
            previewMesh = "mer_fishing\\f\\jellyfish.nif",
            description = "The jelly netch represents the larval form of the larger netch creature. These intriguing organisms dwell in the deep oceans and emerge during the night.",
            speed = 100,
            size = 1.2,
            difficulty = 18,
            class = "medium",
            habitat = {
                minDepth = 200,
                waterType = "saltwater",
                times = {
                    "night"
                }
            },
        },

        {
            baseId = "mer_fish_copperscale",
            previewMesh = "mer_fishing\\f\\copper.nif",
            description = "Exclusive to the rivers of the Ascadian Isles, the copperscale is a fish highly coveted scales, sought after by artisans and collectors for their ornamental value.",
            speed = 190,
            size = 2.2,
            difficulty = 65,
            class = "medium",
            habitat = {
                waterType = "freshwater",
                regions = {
                    "Ascadian Isles Region",
                }
            },
            harvestables = {
                {
                    id = "mer_ingred_copperscales",
                    min = 2,
                    max = 4,
                },
                {
                    id = "mer_meat_copper",
                    min = 1,
                    max = 2,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_marlin",
            previewMesh = "mer_fishing\\f\\marlin.nif",
            description = "To engage in a battle of wills with a blue marlin is a testament to one's angling prowess. These powerful and determined creatures, found in the deep seawaters surrounding Vvardenfell during the daylight hours, exhibit strength, speed, and an indomitable spirit.",
            speed = 260,
            size = 4.4,
            difficulty = 75,
            class = "large",
            habitat = {
                climates = {"temperate", "tropical"},
                waterType = "saltwater",
                minDepth = 300,
                times = { "day" },
            },
            harvestables = {
                {
                    id = "mer_trophy_marlin",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_snapper",
            previewMesh = "mer_fishing\\f\\snapper.nif",
            description = "The Ghost Snapper, a nocturnal inhabitant of Morrowind's saltwaters, features pale skin that glows under moonlight. It's a rare catch for anglers, but its meat is considered a delicacy by those who have tasted it.",
            speed = 190,
            size = 1.4,
            difficulty = 45,
            class = "medium",
            harvestables = {
                {
                    id = "mer_meat_snapper",
                    min = 2,
                    max = 4,
                    isMeat = true,
                }
            },
            habitat = {
                waterType = "saltwater",
                times = { "night" }
            },
        },
    },
    legendary = {

        {
            baseId = "mer_fish_shadowfin",
            previewMesh = "mer_fishing\\f\\shadowfin.nif",
            description = "The shadowfin is a mysterious and elusive fish with a translucent body that effortlessly blends into its surroundings. Found in the enigmatic waters of the River Samsi near Gnisis, this species ventures out exclusively under the cover of darkness.",
            speed = 235,
            size = 1.8,
            difficulty = 77,
            class = "large",
            habitat = {
                times = {
                    "night"
                },
                locations = { "riverSamsi"}
            },
            harvestables = {
                {
                    id = "mer_meat_shadowfin",
                    min = 2,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "mer_trophy_shadowfin",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            },
            alphaSwitch = true,
        },
        {
            baseId = "mer_fish_ashclaw",
            previewMesh = "mer_fishing\\f\\ashclaw.nif",
            description = "The ashclaw is a large and intimidating fish with claw-like fins, resides exlusively in Lake Nabia North of Suran. Its formidable appearance and predatory nature create an aura of fear.",
            speed = 230,
            size = 3.4,
            difficulty = 80,
            class = "large",
            habitat = {
                locations = { "lakeNabia" },
            },
            harvestables = {
                {
                    id = "mer_meat_ashclaw",
                    min = 2,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "mer_ingred_ashlegs",
                    min = 1,
                    max = 2,
                },
                {
                    id = "mer_trophy_ashclaw",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_iskal",
            previewMesh = "mer_fishing\\f\\iskal.nif",
            description = "Iskal, a majestic fish adorned with icy blue scales and razor-sharp spines, calls the frigid waters of Sheogorad its home. Surviving in these harsh conditions showcases the Iskal's resilience, capturing the attention of anglers seeking a unique and chilling adventure.",
            speed = 245,
            size = 2.4,
            difficulty = 75,
            class = "large",
            habitat = {
                climates = {"arctic"},
            },
            harvestables = {
                {
                    id = "mer_trophy_iskal",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_swampmaw",
            previewMesh = "mer_fishing\\f\\swampmaw.nif",
            description = "The swampmaw is a colossal eel lurking within the murky swamps of the Bitter Coast. Armed with sharp teeth and an insatiable appetite, this predatory fish preys upon smaller fish and unwary travelers venturing too close to the water's edge. Its sheer size and fearsome reputation make it a formidable adversary for daring anglers.",
            speed = 230,
            size = 3.5,
            difficulty = 90,
            class = "large",
            habitat = {
                climates = {"swamp"},
            },
            harvestables = {
                {
                    id = "mer_meat_swampmaw",
                    min = 3,
                    max = 6,
                    isMeat = true,
                },
                {
                    id = "mer_trophy_swampmaw",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_void",
            previewMesh = "mer_fishing\\f\\void.nif",
            description = "The Void Thresher, a large black fish with four fiery red eyes, dwells deep within Vvardenfell's underground caves. Its shadowy coloration, reminiscent of the Dark Elves, earned it the nickname \"Azura's Curse.\" This elusive predator feeds on cave-dwelling creatures and awaits unsuspecting prey in the darkest corners of its subterranean realm. Its enigmatic presence beckons adventurers to explore the depths and confront the mysteries that lie within.",
            speed = 220,
            size = 3.4,
            difficulty = 85,
            class = "large",
            habitat = {
                interiors = true,
                exteriors = false,
            },
            harvestables = {
                {
                    id = "mer_trophy_void",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_mega",
            previewMesh = "mer_fishing\\f\\megamax.nif",
            description = "The megamaxilla, known colloquially as the \"Mega Jaw,\" is a fearsome oceanic beast that instills awe in all who witness it. Possessing an enormous, hinge-like jaw, this formidable predator is capable of hunting down even large predator fish. It prefers to feed during the twilight hours of dawn and dusk in Azura's Coast, where its scarlet glow provides a striking camouflage. The pursuit of a megamaxilla demands the utmost strength and skill from anglers, as they strive to conquer one of the ocean's most formidable creatures.",
            speed = 260,
            size = 4.5,
            difficulty = 95,
            class = "large",
            habitat = {
                waterType = "saltwater",
                regions = {
                    "Azura's Coast Region",
                },
                times = {
                    "dawn",
                    "dusk",
                },
            },
            harvestables = {
                {
                    id = "mer_trophy_megamax",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        }
    }
}

local Ashfall = include("mer.ashfall.interop")
local function doRegister(fishConfig)
    local fishType = Interop.registerFishType(fishConfig)
    if Ashfall then
        local obj = fishType:getBaseObject()
        if obj ~= nil and obj.objectType == tes3.objectType.ingredient then
            logger:debug("Registering %s as meat", obj.id)
            Ashfall.registerFoods{
                [obj.id] = "meat"
            }
        end
    end
    if config.mcm.enableFishTooltips then
        local tooltipsComplete = include("Tooltips Complete.interop")
        if tooltipsComplete then
            if fishType:getBaseObject() then
                --tooltip showing rarity, class, and description
                tooltipsComplete.addTooltip(fishType:getBaseObject().id,  fishType.description)
            end
        end
    end
end

event.register("initialized", function (e)
    for rarity, fishList in pairs(fishConfigs) do
        for _, fish in ipairs(fishList) do
            fish.rarity = rarity
            logger:debug("Registering common fish %s", fish.baseId)
            doRegister(fish)
        end
    end
end)
