local i18n = mwse.loadTranslations("Pirate.PaperLanternRecipe")
local Palette = require("mer.joyOfPainting.items.Palette")
local CraftingFramework = include("CraftingFramework")

local DyedPaper = {}

local brushIds = {
    ["jop_brush_01"] = true,
    ["ab_misc_compaintbrush01"] = true,
    ["t_com_paintbrush_01"] = true,
    ["t_com_paintbrush_02"] = true,
    ["t_com_paintbrush_03"] = true,
}

DyedPaper.customRequirements = {
    {
        getLabel = function() return i18n("material.WatercolorPalette") end,
        check = function()
            for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
                local stack = result.stack
                local ownerRef = result.ownerRef

                if stack.variables then
                    for _, itemData in ipairs(stack.variables) do
                        local palette = Palette:new{
                            item = stack.object,
                            itemData = itemData,
                            ownerRef = ownerRef,
                        }
                        if palette 
                            and palette.paletteItem 
                            and palette.paletteItem.paintType == "watercolor"
                            and palette:getRemainingUses() >= 1 then
                            return true
                        end
                    end
                end

                local palette = Palette:new{
                    item = stack.object,
                    ownerRef = ownerRef,
                }
                if palette 
                    and palette.paletteItem 
                    and palette.paletteItem.paintType == "watercolor"
                    and palette.paletteItem.fullByDefault then
                    local numVariables = stack.variables and #stack.variables or 0
                    if stack.count > numVariables then
                        return true
                    end
                end
            end
            return false
        end
    },
    {
        getLabel = function() return i18n("material.Brush") end,
        check = function()
            for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
                local stack = result.stack
                if brushIds[stack.object.id:lower()] then
                    return true
                end
            end
            return false
        end
    }
}

DyedPaper.craftCallback = function()
    for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
        local stack = result.stack
        local ownerRef = result.ownerRef
        -- Сначала пытаемся использовать частично использованную палитру
        if stack.variables then
            for _, itemData in ipairs(stack.variables) do
                local palette = Palette:new{
                    item = stack.object,
                    itemData = itemData,
                    ownerRef = ownerRef,
                }
                if palette 
                    and palette.paletteItem 
                    and palette.paletteItem.paintType == "watercolor"
                    and palette:getRemainingUses() >= 1 then
                    palette:use(ownerRef)
                    return
                end
            end
        end
        -- Если нет частично использованных, берём полную палитру
        local palette = Palette:new{
            item = stack.object,
            ownerRef = ownerRef,
        }
        if palette 
            and palette.paletteItem 
            and palette.paletteItem.paintType == "watercolor"
            and palette.paletteItem.fullByDefault then
            local numVariables = stack.variables and #stack.variables or 0
            if stack.count > numVariables then
                palette:use(ownerRef)
                return
            end
        end
    end
end

return DyedPaper