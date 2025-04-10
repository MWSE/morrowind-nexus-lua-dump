local Palette = require("mer.joyOfPainting.items.Palette")
local config = require("mer.joyOfPainting.config")
local SkillService = require("mer.joyOfPainting.services.SkillService")
event.register("UIEXP:sandboxConsole", function(e)

    local shaders = {}
    for id, shaderConfig in pairs(config.shaders) do
        shaders[id] =  mge.shaders.find{ name = shaderConfig.id }
    end

    e.sandbox.jop = {
        shaders = shaders,
        skills = SkillService.skills,
        setSkill = function(value)
            SkillService.skills.painting.base = value
        end,
        giveSupplies = function()
            local supplies = {
                jop_canvas_wide_01 = 4,
                jop_canvas_tall_01 = 4,
                jop_canvas_square_01 = 4,
                ['sc_paper plain'] = 4,
                jop_parchment_01 = 4,
                jop_brush_01 = 1,
                jop_oil_palette_01 = 1,
                jop_water_palette_01 = 1,
                misc_inkwell = 1,
                misc_quill = 1,
                jop_coal_sticks_01 = 1,
                jop_sketchbook_01 = 1,
                jop_frame_sq_02 = 1,
                jop_frame_w_02 = 1,
                jop_frame_t_02 = 1,
            }

            ---@type table<string, { name: string, count: number }>
            local addedItems = {}
            for id, count in pairs(supplies) do
                local currentCount = tes3.player.object.inventory:getItemCount(id)
                local amountToAdd = count - currentCount
                if amountToAdd > 0 then
                    local item = tes3.getObject(id)
                    if item then
                        tes3.addItem{
                            reference = tes3.player,
                            item = item,
                            count = amountToAdd,
                            playSound = false
                        }
                        addedItems[id] = {name = item.name, count = amountToAdd}
                    end
                end
            end
            if table.size(addedItems) > 0 then
                local message = "Добавлены расходные материалы:"
                for _, item in pairs(addedItems) do
                    message = message .. string.format("\n%s x %d", item.name, item.count)
                end
            else
                tes3.messageBox("Расходных материалов не добавлено.")
            end

            --Add paint level itemData to palettes

            local palettes = {
                jop_oil_palette_01 = true,
                jop_water_palette_01 = true,
            }
            for paletteId in pairs(palettes) do
                if addedItems[paletteId] then
                    ---@type JOP.Palette
                    local oilPalette = Palette:new{
                        item = tes3.getObject(paletteId),
                    }
                    oilPalette:doRefill()
                end
            end
        end
    }

end)