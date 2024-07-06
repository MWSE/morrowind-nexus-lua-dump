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

---@type JOP.Refill[]
local refills = {
    {
        --Ashfall - crush plant dyes and mix with water
        paintType = "watercolor",
        recipe = {
            name = "Растительные красители",
            previewMesh = "n\\ingred_gold_kanet_01.nif",
            previewScale = 1.5,
            id = "jop_watercolor_refill_ashfall",
            description = "Пополните палитру, смешав воду с красным, синим и желтым красителем, полученным путем измельчения растений и цветов.",
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
            name = "Пигменты",
            previewMesh = "jop\\dye\\dye_red.nif",
            id = "jop_watercolor_refill_pigment",
            description = "Пополните палитру красным, синим и желтым пигментами. Пигмент можно приобрести у торговцев.",
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
            name = "Масляные краски (TR)",
            id = "jop_oil_refill",
            description = "Пополните палитру красной, синей и желтой краской.",
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
    }
}
event.register(tes3.event.initialized, function()
    for _, refill in ipairs(refills) do
        JoyOfPainting.Refill.registerRefill(refill)
    end
end)

local materials = {
    {
        id = "red_pigment",
        name = "Красный пигмент",
        ids = {
            "jop_dye_red",
        },
    },
    {
        id = "blue_pigment",
        name = "Синий пигмент",
        ids = {
            "jop_dye_blue",
        },
    },
    {
        id = "yellow_pigment",
        name = "Желтый пигмент",
        ids = {
            "jop_dye_yellow",
        },
    },

    {
        id = "red_dye",
        name = "Красный краситель",
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
        name = "Синий краситель",
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
        name = "Желтый краситель",
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
        name = "Красная краска",
        ids = {
            "t_com_paintpotr_01",
            "t_com_paintpotr_02",
        }
    },
    {
        id = "blue_paint",
        name = "Синяя краска",
        ids = {
            "t_com_paintpotb_01",
            "t_com_paintpotb_02",
        }
    },
    {
        id = "yellow_paint",
        name = "Желтая краска",
        ids = {
            "t_com_paintpoty_01",
            "t_com_paintpoty_02",
        }
    },
}
event.register(tes3.event.initialized, function()
    local CraftingFramework = include("CraftingFramework")
    if CraftingFramework then
        CraftingFramework.Material:registerMaterials(materials)
    end
end)