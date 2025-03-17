local JoyOfPainting = require("mer.joyOfPainting")
local Dye = require("mer.joyOfPainting.items.Dye")
local OilPaints = require("mer.joyOfPainting.items.OilPaints")
local Palette = require("mer.joyOfPainting.items.Palette")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Refill")

local emptyMapping = {
    t_com_paintpoty_01 = "t_com_paintpot_01",
    t_com_paintpoty_02 = "t_com_paintpot_01",
    t_com_paintpotb_01 = "t_com_paintpot_01",
    t_com_paintpotb_02 = "t_com_paintpot_01",
    t_com_paintpotr_01 = "t_com_paintpot_01",
    t_com_paintpotr_02 = "t_com_paintpot_01",
    t_com_paintpotg_01 = "t_com_paintpot_01",
    t_com_paintpotg_02 = "t_com_paintpot_01",
}

---@type JOP.Refill.data[]
local refills = {
    {
        --Ashfall - crush plant dyes and mix with water
        paintType = "watercolor",
        recipe = {
            name = "Plant Dyes",
            previewMesh = "n\\ingred_gold_kanet_01.nif",
            previewScale = 1.5,
            id = "jop_watercolor_refill_ashfall",
            description = "Refill the palette by mixing water with red, blue and yellow dye made by crushing plants and flowers.",
            materials = {
                {
                    material = "red_dye",
                    count = 1,
                },
                {
                    material = "blue_dye",
                    count = 1,
                },
                {
                    material = "yellow_dye",
                    count = 1,
                },
            },
            knowledgeRequirement = function()
                --check that ashfall is installed
                return tes3.isModActive("Ashfall.esp")
            end,
            customRequirements = Dye.customRequirements,
            noResult = true,
            craftCallback = function()
                Dye.craftCallback()
                local paletteToRefill = Palette.getPaletteToRefill()
                if paletteToRefill then
                    paletteToRefill:doRefill()
                end
            end,
        }
    },
    {
        paintType = "watercolor",
        recipe = {
            name = "Pigments",
            previewMesh = "jop\\dye\\dye_red.nif",
            id = "jop_watercolor_refill_pigment",
            description = "Refill the palette with red, blue and yellow pigments. Pigment can be purchased from a painting merchant.",
            materials = {
                {
                    material = "red_pigment",
                    count = 1,
                },
                {
                    material = "blue_pigment",
                    count = 1,
                },
                {
                    material = "yellow_pigment",
                    count = 1,
                },
            },
            noResult = true,
            craftCallback = function()
                Dye.craftCallback()
                local paletteToRefill = Palette.getPaletteToRefill()
                if paletteToRefill then
                    paletteToRefill:doRefill()
                end
            end,
        }
    },
    {
        paintType = "oil",
        recipe = OilPaints.getRecipe(),
    },
    {
        --Red, blue and yellow paint
        paintType = "oil",
        recipe = {
            name = "Oil Paints (TR)",
            id = "jop_oil_refill",
            description = "Refill the palette using red, blue and yellow paint.",
            materials = {
                {
                    material = "red_paint",
                    count = 1,
                },
                {
                    material = "blue_paint",
                    count = 1,
                },
                {
                    material = "yellow_paint",
                    count = 1,
                },
            },
            knowledgeRequirement = function(self)
                --check that TR is installed
                return tes3.isModActive("Tamriel_Data.esm")
            end,
            noResult = true,
            previewMesh = "pc\\m\\pc_misc_p_pot.nif",
            craftCallback = function(_craftable, data)
                local materialsUsed = data.materialsUsed
                for materialId, count in pairs(materialsUsed) do
                    local emptyId = emptyMapping[materialId]
                    if emptyId and count > 0 then
                        local empty = tes3.getObject(emptyId) --[[@as tes3misc]]
                        if empty then
                            logger:debug("Adding %d %s", count, emptyId)
                            tes3.addItem{
                                reference = tes3.player,
                                item = empty,
                                count = count,
                                playSound = false
                            }
                        end
                    end
                end

                local paletteToRefill = Palette.getPaletteToRefill()
                if paletteToRefill then
                    paletteToRefill:doRefill()
                end
            end,
        }
    },
    --Refill ink pot using a mix of charcoal and resin
    {
        paintType = "ink",
        recipe = {
            name = "Ink",
            previewMesh = "misc\\inkwell.nif",
            id = "jop_ink_refill",
            description = "Refill the ink pot using an ink made of charcoal and resin.",
            materials = {
                {
                    material = "coal",
                    count = 1,
                },
                {
                    material = "resin",
                    count = 1,
                },
            },
            knowledgeRequirement = function()
                --check that ashfall is installed
                return tes3.isModActive("Ashfall.esp")
            end,
            noResult = true,
            craftCallback = function(self)
                local paletteToRefill = Palette.getPaletteToRefill()
                if paletteToRefill then
                    paletteToRefill:doRefill()
                end
            end
        }
    },
}
event.register(tes3.event.initialized, function()
    for _, refill in ipairs(refills) do
        JoyOfPainting.Refill.registerRefill(refill)
    end
end)



local materials = {
    {
        id = "red_pigment",
        name = "Red Pigment",
        ids = {
            "jop_dye_red",
        },
        registerAsRefillItems = true
    },
    {
        id = "blue_pigment",
        name = "Blue Pigment",
        ids = {
            "jop_dye_blue",
        },
        registerAsRefillItems = true
    },
    {
        id = "yellow_pigment",
        name = "Yellow Pigment",
        ids = {
            "jop_dye_yellow",
        },
        registerAsRefillItems = true
    },

    {
        id = "red_dye",
        name = "Red Dye",
        ids = {
            "ingred_fire_petal_01",
            "ingred_heather_01",
            "ingred_holly_01",
            "ingred_red_lichen_01",
            "ab_ingflor_bloodgrass_01",
            "ab_ingflor_bloodgrass_02",
            "mr_berries",
            "ingred_comberry_01",
            "Ingred_timsa-come-by_01",
            "Ingred_noble_sedge_01",
        },
    },
    {
        id = "blue_dye",
        name = "Blue Dye",
        ids = {
            "ingred_bc_coda_flower",
            "ingred_belladonna_01",
            "ingred_stoneflower_petals_01",
            "t_ingflor_lavender_01",
            "ab_ingflor_bluekanet_01",
            "ingred_wolfsbane_01",
            "Ingred_meadow_rye_01",
        },
    },
    {
        id = "yellow_dye",
        name = "Yellow Dye",
        ids = {
            "ingred_bittergreen_petals_01",
            "ingred_gold_kanet_01",
            "ingred_golden_sedge_01",
            "ingred_timsa-come-by_01",
            "ingred_wickwheat_01",
            "ingred_willow_anther_01",
        },
    },

    {
        id = "red_paint",
        name = "Red Paint",
        ids = {
            "t_com_paintpotr_01",
            "t_com_paintpotr_02",
        },
        registerAsRefillItems = true
    },
    {
        id = "blue_paint",
        name = "Blue Paint",
        ids = {
            "t_com_paintpotb_01",
            "t_com_paintpotb_02",
        },
        registerAsRefillItems = true
    },
    {
        id = "yellow_paint",
        name = "Yellow Paint",
        ids = {
            "t_com_paintpoty_01",
            "t_com_paintpoty_02",
        },
        registerAsRefillItems = true
    },
}
event.register(tes3.event.initialized, function()
    local CraftingFramework = include("CraftingFramework")
    if CraftingFramework then
        CraftingFramework.Material:registerMaterials(materials)
        for _, material in ipairs(materials) do
            if material.registerAsRefillItems then
                for _, id in ipairs(material.ids) do
                    JoyOfPainting.Refill.registerRefillItem{
                        id = id,
                    }
                end
            end
        end
        JoyOfPainting.Refill.registerRefillItem{ id = "jop_oil_paints_01"}
    end
end)