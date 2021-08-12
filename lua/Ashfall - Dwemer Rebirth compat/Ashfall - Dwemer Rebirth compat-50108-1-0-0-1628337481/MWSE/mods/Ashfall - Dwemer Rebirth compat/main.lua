--[[

	Ashfall - Dwemer Rebirth compat
	An MWSE-lua mod for Morrowind
	
	@version      v1.0.0
	@author       Isnan
	@last-update  August 7, 2021
	@changelog
		v1.0.0
        - Initial release
        - Adding tooltips emulating ashfall's text style for a handful of dwemer rebirth items
        - Adding some dwemer rebirth items as water containers.
        - Adding some dwemer rebirth statics as dirty water sources.

]]

mwse.log( "Ashfall - Dwemer Rebirth Interop loaded" )

local ashfall          = include("mer.ashfall.interop")
local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData      = {
    { id = "AB_Misc_DwrvCup00", itemType = "tool", description = "Embellished Dwemer cup presumably fashioned from brass. " },
    { id = "dwrv_dinner_bowl",  itemtype = "tool", description = "A Dwemer bowl fashioned from an unknown material." },
    { id = "dwrv_dinner_cup",   itemType = "tool", description = "A Dwemer cup fashioned from an unknown material. Most likely used as a drinking vessel." },
    { id = "dwrv_dinner_jug",   itemType = "tool", description = "A large Dwemer bottle fashioned from an unknown material. Probably used to store water, spirits, or oil." },
    { id = "dwrv_frying_pan",   itemType = "tool", description = "A large frying pan fashioned from an unknown material. Use at a campfire to cook meat or vegetables." },
    { id = "dwrv_pan2",         itemType = "tool", description = "A cooking pot fashioned from an unknown material. Use at a campfire to boil water and cook stews" },
    { id = "dwrv_pan",          itemType = "tool", description = "This cooking pot is made of an unknown material. A crack along the bottom makes it currently unusuable." },
}

local function onInitialized()

    -- add ashfall interop if available.
    if ashfall then

        ashfall.registerWaterSource{
            name = "Well (Dirty)",
            isDirty = true,
            ids = {
                "furn_dwrv_well00",
            }
        }

        ashfall.registerActivators{
            --furn_dwrv_well00 = "water", -- wishlist "Well (Dirty)"
            sturdumz_leak    = "water",
        }
        ashfall.registerWaterContainers{
            AB_Misc_DwrvCup00 = "cup",
            dwrv_dinner_cup   = "cup",
            dwrv_dinner_jug   = "jug",
        }
    end

    -- add tooltip interop if both tooltip complete and ashfall is available.
    if tooltipsComplete and ashfall then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end

end

event.register( "initialized", onInitialized )
