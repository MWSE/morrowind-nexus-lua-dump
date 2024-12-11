local common = require("mer.fishing.common")
local logger = common.createLogger("Interop - Bait")

local Interop = require("mer.fishing")

---@alias Fishing.Bait.type
---| '"lure"'            # Default lure.
---| '"spinner"'         # Used for catching small baitfish.
---| '"bait"'            # Used for catching medium sized fish.
---| '"baitfish"'        # Used for catching large fish.
---| '"shiny"'           # More effective during the daytime.
---| '"glowing"'         # More effective at nighttime.
---| '"sinker"'          # Increases chance of catching random loot.

---@type Fishing.BaitType[]
local BaitTypes = {
    {
        id = "lure",
        name = "Lure",
    },
    {
        id = "glowing",
        name = "Glowing Lure",
        description = "More effective at nighttime.",
        classCatchChances = {
            small = 0.5,
            medium = 0.3,
            large = 0.1,
            loot = 0.1,
        },
        getHookChance = function(self)
            local time = tes3.worldController.hour.value
            if time >= 18 or time <= 6 then
                return 1.5
            end
            return 0.75
        end
    },
    {
        id = "shiny",
        name = "Shiny Lure",
        description = "More effective during the daytime.",
        classCatchChances = {
            small = 0.5,
            medium = 0.3,
            large = 0.1,
            loot = 0.1,
        },
        getHookChance = function(self)
            local time = tes3.worldController.hour.value
            if time >= 6 and time <= 18 then
                return 1.5
            end
            return 0.75
        end
    },
    {
        id = "spinner",
        name = "Spinner",
        description = "Most effective at catching small baitfish.",
        classCatchChances = {
            small = 0.8,
            medium = 0.1,
            large = 0,
            loot = 0.1,
        },
    },
    {
        id = "bait",
        name = "Bait",
        description = "Most effective at catching medium sized fish.",
        classCatchChances = {
            small = 0.1,
            medium = 0.7,
            large = 0.15,
            loot = 0.05,
        },
    },
    {
        id = "baitfish",
        name = "Baitfish",
        description = "Most effective at catching large fish.",
        classCatchChances = {
            small = 0,
            medium = 0.15,
            large = 0.8,
            loot = 0.05,
        },
    },
    {
        id = "sinker",
        name = "Sinker",
        description = "Increases chance of catching random loot.",
        classCatchChances = {
            small = 0.25,
            medium = 0.05,
            large = 0.0,
            loot = 0.7,
        },
    },
}
for _, baitType in ipairs(BaitTypes) do
    logger:debug("Registering bait type %s", baitType.id)
    Interop.registerBaitType(baitType)
end

---@type Fishing.Bait[]
local baits = {
    {
        id = "mer_lure_01",
        type = "lure",
    },
    {
        id = "ingred_racer_plumes_01",
        type = "spinner",
        uses = 10,
    },
    {
        id = "mer_bug_spinner",
        type = "spinner",
    },
    {
        id = "mer_bug_spinner2",
        type = "spinner",
    },
    {
        id = "mer_silver_lure",
        type = "shiny",
    },
    {
        id = "ingred_crab_meat_01",
        type = "bait",
        uses = 10,
    },
    {
        id = "ingred_pearl_01",
        type = "shiny",
        uses = 10,
    },
    {
        id = "ingred_scales_01",
        type = "shiny",
        uses = 10,
    },
    {
        id = "ab_ingcrea_glowbugthorax",
        type = "glowing",
        uses = 10,
    },
    {
        id = "ab_ingcrea_glowbugthoraxred",
        type = "glowing",
        uses = 10,
    },
    {
        id = "ab_ingcrea_glowbugthoraxgreen",
        type = "glowing",
        uses = 10,
    },
    {
        id = "ab_ingcrea_glowbugthoraxviol",
        type = "glowing",
        uses = 10,
    },
    {
        id = "ab_ingcrea_glowbugthoraxblue",
        type = "glowing",
        uses = 10,
    },
    {
        id = "ingred_scrap_metal_01",
        type = "sinker",
        uses = 50,
    }

}
event.register("initialized", function (e)
    for _, bait in ipairs(baits) do
        logger:debug("Registering bait %s", bait.id)
        Interop.registerBait(bait)
    end
end)

