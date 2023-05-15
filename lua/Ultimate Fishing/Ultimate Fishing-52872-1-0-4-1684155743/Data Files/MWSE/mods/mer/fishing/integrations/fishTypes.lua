--[[
    Register default fish types
]]
local common = require("mer.fishing.common")
local logger = common.createLogger("Integrations - fishTypes")
local Interop = require("mer.fishing")

---@type Fishing.FishType.new.params[]
local commonFish = {
    {
        baseId = "misc_com_bottle_10",
        description = "It's a bottle.",
        speed = 30,
        size = 0.5,
        difficulty = 5,
        class = "small",
        niche = {},
    },

    {
        baseId = "mer_fish_bass",
        previewMesh = "mer_fishing\\f\\bass.nif",
        description = "The largemouth bass is a medium sized, carnivourous fish found all throughout Morrowind. They can put up a good fight when hooked, but are prized for their delicious meat.",
        speed = 170,
        size = 2.0,
        difficulty = 30,
        class = "medium",
        niche = {},
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
        baseId = "mer_fish_goby",
        previewMesh = "mer_fishing\\f\\goby.nif",
        description = "The Goby is a small fish found all throughout Morrowind. They make excellent baitfish for catching larger prey.",
        speed = 150,
        size = 1.1,
        difficulty = 20,
        class = "small",
        isBaitFish = true,
        niche = {},
    },
    {
        baseId = "mer_fish_salmon",
        previewMesh = "mer_fishing\\f\\salmon.nif",
        description = "Salmon can be found in the oceans, lakes and rivers of the Ascadian Isles.",
        speed = 180,
        size = 1.4,
        difficulty = 40,
        class = "medium",
        niche = {
            regions = {
                "Ascadian Isles Region",
            },
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
        description = "A large, aggressive fish with sharp teeth and a dorsal fin that runs the length of its body. The Slaughterfish is found throughout Tamriel and is known to attack anything that enters its territory. Slaughterfish meat tastes awful, but their scales are considered a delicacy.",
        speed = 180,
        size = 3.0,
        difficulty = 50,
        class = "large",
        niche = {},
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
        description = "Juvenile Slaughterfish may be small, but they can still put up a fight.",
        speed = 170,
        size = 1.1,
        difficulty = 25,
        class = "small",
        isBaitFish = true,
        niche = {},
    },
    {
        baseId = "mer_fish_trigger",
        previewMesh = "mer_fishing\\f\\trigger.nif",
        description = "The triggerfish is a small tropical fish commonly found in the waters of Azura's Coast. They are known for their aggressive behavior and sharp teeth.",
        speed = 240,
        size = 1.0,
        difficulty = 15,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "Azura's Coast Region",
            }
        },
    },
    {
        baseId = "mer_fish_catfish",
        previewMesh = "mer_fishing\\f\\catfish.nif",
        description = "The catfish is a small, bottom-feeding fish found in the swamps of the Bitter Coast. They are known for their barbels, which resemble a cat's whiskers.",
        speed = 150,
        size = 1.0,
        difficulty = 54,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "Bitter Coast Region",
            }
        },
    },
    {
        baseId = "mer_fish_sculpin",
        previewMesh = "mer_fishing\\f\\sculpin.nif",
        description = "The sculpin is a small fish that lives in both fresh and saltwater. They make excellent baitfish for catching larger prey.",
        speed = 170,
        size = 1.0,
        difficulty = 22,
        class = "small",
        isBaitFish = true,
        niche = {},
    },
    {
        baseId = "mer_fish_cod",
        previewMesh = "mer_fishing\\f\\cod.nif",
        description = "The cod is a medium sized fish found in the deeper waters of the Inner Sea. They are known for their delicious meat.",
        speed = 150,
        size = 1.5,
        difficulty = 33,
        class = "medium",
        harvestables = {
            {
                id = "mer_meat_cod",
                min = 1,
                max = 3,
                isMeat = true,
            }
        },
        niche = {
            minDepth = 200,
        },
    },
}

---@type Fishing.FishType[]
local uncommonFish = {

    {
        baseId = "mer_fish_tambaqui",
        previewMesh = "mer_fishing\\f\\tambaqui.nif",
        description = "The tambaqui is a large tropical fish found along the eastern coast of Vvardenfell.",
        speed = 190,
        size = 2.0,
        difficulty = 43,
        class = "medium",
        niche = {
            regions = {
                "Grazelands Region",
                "Azura's Coast Region",
                "Molag Mar Region",
            }
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
        description = "Arowana, also known as bony tongues, are an uncommon fish found along the coast of the West Gash. They tend to feed only during the day",
        speed = 210,
        size = 1.1,
        difficulty = 35,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "West Gash Region",
            },
            times = {
                "day"
            }
        },
    },
    {
        baseId = "mer_fish_angelshark",
        previewMesh = "mer_fishing\\f\\angel.nif",
        description = "The Angelshark is small for a shark, but still formidable. They are found all throughout the waters of Vvardenfell.",
        speed = 190,
        size = 1.3,
        class = "large",
        difficulty = 55,
        niche = {
            minDepth = 200,
        },
        harvestables = {
            {
                id = "mer_meat_angelshark",
                min = 1,
                max = 1,
                isMeat = true,
            }
        }
    }
}
---@type Fishing.FishType[]
local rareFish = {
    {
        baseId = "mer_fish_discus",
        previewMesh = "mer_fishing\\f\\discus.nif",
        description = "The Discus is an uncommon, colorful fish found in the warmer regions of Morrowind.",
        speed = 200,
        size = 1.0,
        difficulty = 47,
        class = "small",
        isBaitFish = true,
        niche = {
            regions = {
                "Ascadian Isles Region",
                "Azura's Coast Region",
            }
        },
    },
    {
        baseId = "mer_fish_jelly",
        previewMesh = "mer_fishing\\f\\jellyfish.nif",
        description = "The Jelly Netch is the larval form of Netch. They can be found in the deep waters at night.",
        speed = 100,
        size = 1.2,
        difficulty = 18,
        class = "medium",
        niche = {
            minDepth = 400,
            times = {
                "night"
            }
        },
    },

    {
        baseId = "mer_fish_copperscale",
        previewMesh = "mer_fishing\\f\\copper.nif",
        description = "The Copperscale is found only in the Ascadian Isles. It's meat is tough and chewy, but its scales are highly sought after.",
        speed = 200,
        size = 2.2,
        difficulty = 65,
        class = "medium",
        niche = {
            interiors = true,
            exterios = true,
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
        baseId = "mer_fish_marrow",
        previewMesh = "mer_fishing\\f\\marrow.nif",
        description = "The Marrowfish is a strange creature with bulging eyes and an oily red body. This rare fish can only be found in caves, and it's meat has powerful alchemical properties.",
        speed = 180,
        size = 1.8,
        difficulty = 70,
        class = "medium",
        niche = {
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
    {
        baseId = "mer_fish_marlin",
        previewMesh = "mer_fishing\\f\\marlin.nif",
        description = "To win a battle of will against a blue marlin is a sign of a true angler. They are strong, fast, and determined. You'll need all your strength to catch one. The blue marlin is found in the deepest of seawaters, all over Vvardenfell. You'll need live baitfish to catch one.",
        niche = {
            minDepth = 500,
            lures = {
                baitfish = 100,
            }
        },
        speed = 240,
        size = 4.4,
        difficulty = 75,
        class = "large",
        harvestables = {
            {
                id = "mer_trophy_marlin",
                min = 1,
                max = 1,
                isTrophy = true,
            }
        }
    }
}
---@type Fishing.FishType[]
local legendaryFish = {
    {
        baseId = "mer_fish_shadowfin",
        previewMesh = "mer_fishing\\f\\shadowfin.nif",
        description = "The Shadowfin is a dark, elusive fish with a translucent body that blends in with its surroundings. It is found in the West Gash and feeds only at night.",
        speed = 210,
        size = 1.8,
        difficulty = 77,
        class = "large",
        niche = {
            times = {
                "night"
            },
            regions = {
                "West Gash Region"
            },
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
        }
    },
    {
        baseId = "mer_fish_ashclaw",
        previewMesh = "mer_fishing\\f\\ashclaw.nif",
        description = "The Ashclaw is a large, frightening fish with claw-like fins that lives in Lake Nabia, in the Molag Amur Region.",
        speed = 200,
        size = 3.4,
        difficulty = 80,
        class = "large",
        niche = {
            regions = {
                "Molag Mar Region",
            },
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
        description = "Iskal is a large fish with icy blue scales and razor sharp spines running over it's body. It lives in the frigid waters of Sheogorad.",
        speed = 230,
        size = 2.8,
        difficulty = 75,
        class = "large",
        niche = {
            regions = {
                "Sheogorad",
            },
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
        description = "The Swampmaw is a massive eel that lives in the swamps of the Bitter Coast, with sharp teeth and a voracious appetite. It is known to prey on smaller fish and unwary travelers who venture too close to the water's edge at night.",
        speed = 200,
        size = 3.7,
        difficulty = 90,
        class = "large",
        niche = {
            times = {
                "night"
            },
            regions = {
                "Bitter Coast Region",
            },
            lures = {
                glowing = 100,
                iridescent = 80
            },
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
        baseId = "mer_fish_mega",
        previewMesh = "mer_fishing\\f\\megamax.nif",
        description = "The Megamaxilla, or \"Mega Jaw\", is one of the most fearsome beasts in the ocean. It's gigantic, hinge-like jaw allows it to prey even on other large predator fish. It feeds during dawn and dusk in Azura's Coast, where the scarlet glow helps it blend in with the water.",
        speed = 210,
        size = 4.5,
        difficulty = 95,
        class = "large",
        niche = {
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



local Ashfall = include("mer.ashfall.interop")
---@param fish Fishing.FishType
local function registerFood(fish)
    if Ashfall then
       local obj = fish:getBaseObject()
       if obj.objectType == tes3.objectType.ingredient then
            logger:debug("Registering %s as meat", obj.id)
            Ashfall.registerFoods{
                [obj.id] = "meat"
            }
       end
    end
end

local FishType = require("mer.fishing.Fish.FishType")
for _, fish in ipairs(commonFish) do
    fish.rarity = "common"
    logger:debug("Registering common fish %s", fish.baseId)
    fish = Interop.registerFishType(fish)
    registerFood(fish)
end

for _, fish in ipairs(uncommonFish) do
    fish.rarity = "uncommon"
    logger:debug("Registering uncommon fish %s", fish.baseId)
    fish = Interop.registerFishType(fish)
    registerFood(fish)
end

for _, fish in ipairs(rareFish) do
    fish.rarity = "rare"
    logger:debug("Registering rare fish %s", fish.baseId)
    fish = Interop.registerFishType(fish)
    registerFood(fish)
end

for _, fish in ipairs(legendaryFish) do
    fish.rarity = "legendary"
    logger:debug("Registering legendary fish %s", fish.baseId)
    fish = Interop.registerFishType(fish)
    registerFood(fish)
end
