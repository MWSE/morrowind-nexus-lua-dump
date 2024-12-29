local Tapestry = require("mer.joyOfPainting.items.Tapestry")
local config = require("mer.joyOfPainting.config")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("TapestryActivator")

local tapestries = {
    { id = "furn_com_tapestry_01" },
    { id = "furn_com_tapestry_02" },
    { id = "furn_com_tapestry_03" },
    { id = "furn_com_tapestry_04" },
    { id = "furn_com_tapestry_05" },
    { id = "furn_de_tapestry_01" },
    { id = "furn_de_tapestry_02" },
    { id = "furn_de_tapestry_03" },
    { id = "furn_de_tapestry_04" },
    { id = "furn_de_tapestry_05" },
    { id = "furn_de_tapestry_06" },
    { id = "furn_de_tapestry_07" },
    { id = "furn_de_tapestry_08" },
    { id = "furn_de_tapestry_09" },
    { id = "furn_de_tapestry_10" },
    { id = "furn_de_tapestry_11" },
    { id = "furn_de_tapestry_12" },
    { id = "furn_de_tapestry_13" },
    { id = "furn_de_tapestry_m_01" },
    { id = "furn_s_tapestry" },
    { id = "furn_s_tapestry02" },
    { id = "furn_s_tapestry03" },
}
event.register(tes3.event.initialized, function()
    for _, tapestry in ipairs(tapestries) do
        Tapestry.registerTapestry(tapestry)
    end
end)

local function registerTapestry(tapestry)
    logger:debug("Registering tapestry %s", tapestry.id)
    ---@type CraftingFramework
    local CraftingFramework = include("CraftingFramework")
    if CraftingFramework then
        if CraftingFramework.StaticActivator.registeredObjects[tapestry.id:lower()] then
            logger:warn("%s already registered as a static activator, skipping", tapestry.id)
            return
        end
        CraftingFramework.StaticActivator.register{
            objectId = tapestry.id,
            name = config.mcm.showTapestryTooltip and "Гобелен" or nil,
            craftedOnly = false,

            onActivate = function(reference)
                logger:debug("Activated tapestry")
                if not reference then return end
                --if config.tapestries[reference.object.id:lower()] == nil then return end
                if not config.mcm.enableTapestryRemoval then
                    logger:debug("Tapestry removal disabled")
                    return
                end
                logger:debug("Showing tapestry menu")
                tes3ui.showMessageMenu{
                    message = "Гобелен",
                    buttons = {
                        {
                            text = "Убрать",
                            callback = function()
                                reference:delete()
                                tes3.playSound{
                                    sound = "Item Misc Up",
                                }
                            end
                        }
                    },
                    cancels = true
                }
            end,
        }
    end
end

event.register("initialized", function()
    for _, tapestry in ipairs(tapestries) do
        registerTapestry(tapestry)
    end
end, { priority = -10 })
