
---@class ModAssistance
local this = {}

local settings = require("InspectIt.settings")

--- Right Click Menu Exit https://www.nexusmods.com/morrowind/mods/48458
function this.RegisterRightClickMenuExit()
    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        RightClickMenuExit.registerMenu({
            menuId = settings.guideMenu,
            buttonId = settings.returnButtonName,
        })
    end
end

-- Weapon Sheathing https://www.nexusmods.com/morrowind/mods/46069
---@param mesh string
---@return string?
function this.FindWeaponSheathingMesh(mesh)
    if mesh then
        local sheathMesh = mesh:sub(1, -5) .. "_sh.nif"
        if tes3.getFileExists("meshes\\" .. sheathMesh) then
            return sheathMesh
        end
    end
    return nil
end

--- Tooltips Complete https://www.nexusmods.com/morrowind/mods/46842
---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@param itemData tes3itemData?
---@return string?
function this.FindTooltipsComplete(object, itemData)
    local tooltipData = include("Tooltips Complete.data")
    if not tooltipData then
        return nil
    end
    -- If this is run here before the original mod the first time, an invalid config will be generated.
    -- But since it is executed in the original mod's main, it is usually not in that order.
    local config = mwse.loadConfig("tooltipsComplete")
    if not config then
        return nil
    end
    local mcmMapping = {
        { descriptionTable = tooltipData.keyTable,        mcm = "keyTooltips" },
        { descriptionTable = tooltipData.questTable,      mcm = "questTooltips" },
        { descriptionTable = tooltipData.uniqueTable,     mcm = "uniqueTooltips" },
        { descriptionTable = tooltipData.artifactTable,   mcm = "artifactTooltips" },
        { descriptionTable = tooltipData.armorTable,      mcm = "armorTooltips" },
        { descriptionTable = tooltipData.weaponTable,     mcm = "weaponTooltips" },
        { descriptionTable = tooltipData.toolTable,       mcm = "toolTooltips" },
        { descriptionTable = tooltipData.miscTable,       mcm = "miscTooltips" },
        { descriptionTable = tooltipData.bookTable,       mcm = "bookTooltips" },
        { descriptionTable = tooltipData.clothingTable,   mcm = "clothingTooltips" },
        { descriptionTable = tooltipData.soulgemTable,    mcm = "soulgemTooltips" },
        { descriptionTable = tooltipData.lightTable,      mcm = "lightTooltips" },
        { descriptionTable = tooltipData.potionTable,     mcm = "potionTooltips" },
        { descriptionTable = tooltipData.ingredientTable, mcm = "ingredientTooltips" },
        { descriptionTable = tooltipData.scrollTable,     mcm = "scrollTooltips" },
    }
    if config.menuOnly then
        -- return nil
    end

    local file = object.sourceMod
    if file and config.blocked[file:lower()] then
        return
    elseif config.blocked[object.id:lower()] then
        return
    end

    for _, data in ipairs(mcmMapping) do
        local description = data.descriptionTable[object.id:lower()]
        if config[data.mcm] and description then
            --soul gem item data
            if (object.isSoulGem and itemData and itemData.soul) then
                if config.blocked[itemData.soul.id:lower()] then
                    return description
                end
                if (itemData.soul.id == nil) then
                    return description
                end
                description = tooltipData.filledTable[itemData.soul.id:lower()] or ""
            end
            return description
        end
    end
    return nil
end

return this
