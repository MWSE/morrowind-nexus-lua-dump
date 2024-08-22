
--[[Tooltips Complete
Tooltips Complete provides helpful and lore-friendly flavour texts for nearly every item in
Morrowind, Tribunal, Bloodmoon, and the Official Plugins.
 ]]

local tooltipData = require("Tooltips Complete.data")

local config = require("Tooltips Complete.mcm").config
mwse.log("[Tooltips Complete] Initialized")
-- mwse.log(json.encode(config, {indent=true}))

local mcmMapping = {
    { descriptionTable = tooltipData.keyTable, mcm = "keyTooltips" },
    { descriptionTable = tooltipData.questTable, mcm = "questTooltips" },
    { descriptionTable = tooltipData.uniqueTable, mcm = "uniqueTooltips" },
    { descriptionTable = tooltipData.artifactTable, mcm = "artifactTooltips" },
    { descriptionTable = tooltipData.armorTable, mcm = "armorTooltips" },
    { descriptionTable = tooltipData.weaponTable, mcm = "weaponTooltips" },
    { descriptionTable = tooltipData.toolTable, mcm = "toolTooltips" },
    { descriptionTable = tooltipData.miscTable, mcm = "miscTooltips" },
    { descriptionTable = tooltipData.bookTable, mcm = "bookTooltips" },
    { descriptionTable = tooltipData.clothingTable, mcm = "clothingTooltips" },
    { descriptionTable = tooltipData.soulgemTable, mcm = "soulgemTooltips" },
    { descriptionTable = tooltipData.lightTable, mcm = "lightTooltips" },
    { descriptionTable = tooltipData.potionTable, mcm = "potionTooltips" },
    { descriptionTable = tooltipData.ingredientTable, mcm = "ingredientTooltips" },
    { descriptionTable = tooltipData.scrollTable, mcm = "scrollTooltips" },
}

local function tooltip(e)

	if config.menuOnly and not tes3.menuMode() then
		return
	end

	local file = e.object.sourceMod

	if file and config.blocked[file:lower()] then
		return
	elseif config.blocked[e.object.id:lower()] then
		return
	end

    for _, data in ipairs(mcmMapping) do
        local description = data.descriptionTable[e.object.id:lower()]
        if config[data.mcm] and description then
            local keyBlock = e.tooltip:createBlock{ id = tes3ui.registerID("Tooltips_Complete_Keys") }
            keyBlock.minWidth = 1
            keyBlock.maxWidth = 310
            keyBlock.autoWidth = true
            keyBlock.autoHeight = true
            keyBlock.paddingAllSides = 6
            local keyLabel= keyBlock:createLabel{ id = tes3ui.registerID("Tooltips_Complete_Keys"), text = description }
            keyLabel.wrapText = true

            --soul gem item data
            if (e.object.isSoulGem and e.itemData and e.itemData.soul) then
                if config.blocked[e.itemData.soul.id:lower()] then
                    return
				end
				if (e.itemData.soul.id == nil) then
					return
                end
                keyLabel.text = tooltipData.filledTable[e.itemData.soul.id:lower()] or ""
            end
        end
    end
end

local function initialized(e)
    event.register("uiObjectTooltip", tooltip)

    print("Initialized TooltipsComplete v0.00")
end

event.register("initialized", initialized)
