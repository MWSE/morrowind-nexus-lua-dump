local ashfall = include("mer.ashfall.interop")
if not ashfall then return end
local Easel = require("mer.joyOfPainting.items.Easel")
local Dye = require("mer.joyOfPainting.items.Dye")
local PaperMold = require("mer.joyOfPainting.items.PaperMold")
local Sketchbook = require("mer.joyOfPainting.items.Sketchbook")

---@type CraftingFramework.Recipe.data[]
local recipes = {
    {
        id = "jop_frame_sq_01",
        description = "A square wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
    },
    {
        id = "jop_frame_w_01",
        description = "A wide wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
    },
    {
        id = "jop_frame_t_01",
        description = "A tall wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
    },
    {
        id = "jop_easel_01",
        description = "A crude wooden easel. Can be used to paint a canvas.",
        materials = {
            { material = "wood", count = 6 },
            { material = "rope", count = 4}
        },
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        destroyCallback = function(_recipe, e)
            local easel = Easel:new(e.reference)
            if easel and easel:hasCanvas() then
                easel.painting:takeCanvas{blockSound = true}
            end
        end,
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
        additionalMenuOptions = Easel.getActivationButtons(),
    },
    {
        id = "jop_easel_misc",
        placedObject = "jop_easel_02",
        description = "A finely crafted, portable wooden easel.",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1},
        },
        skillRequirements = {ashfall.bushcrafting.survivalTiers.expert},
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
        additionalMenuOptions = Easel.getActivationButtons(),
        destroyCallback = function(_recipe, e)
            local easel = Easel:new(e.reference)
            if easel and easel:hasCanvas() then
                easel.painting:takeCanvas{blockSound = true}
            end
        end,
        pickUp = function(craftable, reference)
            local easel = Easel:new(reference)
            if easel then
                easel:pickUp()
            end
        end
    },
    {
        id = "jop_canvas_square_01",
        description = "A square canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "fabric", count = 2 },
            { material = "wood", count = 4 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_canvas_wide_01",
        description = "A wide canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "fabric", count = 2 },
            { material = "wood", count = 4 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_sketchbook_01",
        description = "A sketchbook to store drawings and sketches.",
        category = "Painting",
        soundType = "leather",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "leather", count = 1 },
            { material = "paper", count = 2 }
        },
        rotationAxis = 'y',
        craftedOnly = false,
    },
    {
        id = "jop_brush_01",
        description = "A brush for painting.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        materials = {
            { material = "wood", count = 1 },
            { material = "fibre", count = 1 },
        },
        rotationAxis = 'x'
    },

    {
        id = "jop_oil_palette_01",
        description = "A palette for storing and mixing oil paints.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        materials = {
            { material = "wood", count = 2 },
        },
        rotationAxis = 'x',
    },

    {
        id = "jop_water_palette_01",
        description = "A palette for storing and mixing watercolor paints.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        materials = {
            { material = "wood", count = 2 },
        },
        rotationAxis = 'x',
    },
    {
        id = "jop_paper_pulp",
        description = "A pile of paper pulp. Use with a paper mold to craft sheets of paper.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "fibre", count = 4 },
        },
        customRequirements = {
            {
                getLabel = function() return "Water: 10 units" end,
                check = function()
                    ---@param stack tes3itemStack
                    for _, stack in pairs(tes3.player.object.inventory) do
                        if stack.variables then
                            for _, itemData in ipairs(stack.variables) do
                                local liquidContainer = ashfall.LiquidContainer.createFromInventory(stack.object, itemData)
                                local hasEnoughWater = liquidContainer ~= nil
                                    and liquidContainer:hasWater()
                                    and liquidContainer:isWater()
                                    and liquidContainer.waterAmount >= 10
                                if hasEnoughWater then
                                    return true
                                end
                            end
                        end
                    end
                    return false
                end
            },
        },
        craftCallback = function(e)
            ---@param stack tes3itemStack
            for _, stack in pairs(tes3.player.object.inventory) do
                if stack.variables then
                    for _, itemData in ipairs(stack.variables) do
                        local liquidContainer = ashfall.LiquidContainer.createFromInventory(stack.object, itemData)
                        local hasEnoughWater = liquidContainer ~= nil
                            and liquidContainer:hasWater()
                            and liquidContainer:isWater()
                            and liquidContainer.waterAmount >= 10
                        if liquidContainer ~= nil and hasEnoughWater then
                            liquidContainer:reduce(10)
                            return
                        end
                    end
                end
            end
        end
    },
    {
        id = "jop_paper_mold",
        description = "A mold for crafting sheets of paper.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "wood", count = 2 },
            { material = "fibre", count = 1 },
        },
    }
}

local materials = {
    {
        id = "paper",
        name = "Paper",
        ids = {
            "sc_paper plain",
            "jop_parchment_01",
            "jop_parchment_h_01",
            "jop_paper_01",
        }
    },
}
event.register(tes3.event.initialized, function()
    local CraftingFramework = include("CraftingFramework")
    if CraftingFramework then
        CraftingFramework.Material:registerMaterials(materials)
    end
end)

---@param e CraftingFramework.MenuActivator.RegisteredEvent
local function registerAshfallRecipes(e)
    local activator = e.menuActivator
    if activator then
        activator:registerRecipes(recipes)
    end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)

local function registerTanningRackRecipes(e)
    local activator = e.menuActivator
    if activator then
        activator:registerRecipes({
            {
                id = "jop_parchment_01",
                description = "Blank parchment made from animal hide, used for sketching.",
                materials = {
                    { material = "hide", count = 1 },
                },
                category = "Painting",
                soundType = "leather",
                skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
                toolRequirements = {
                    {
                        tool = "knife",
                        conditionPerUse = 1
                    }
                },
                rotationAxis = "y",
                resultAmount = 4,
            }
        })
    end
end
event.register("Ashfall:ActivateTanningRack:Registered", registerTanningRackRecipes)