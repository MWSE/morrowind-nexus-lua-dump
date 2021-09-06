local modInfo = require("RationalNames.modInfo")
local config = require("RationalNames.config")
local data = require("RationalNames.data")
local common = require("RationalNames.common")
local rename = require("RationalNames.rename")
local ui = require("RationalNames.ui")

local function onInitialized()
    local buildDate = mwse.buildDate

    -- This mod takes advantage of a few recent fixes to MWSE, and won't work properly with an old version.
    if not buildDate
    or buildDate < 20210708 then
        local tooOld = string.format("%s MWSE is too out of date. Update MWSE to use this mod.", modInfo.modVersion)
        tes3.messageBox(tooOld)
        mwse.log(tooOld)
        return
    end

    if not config.enable then
        mwse.log("%s Mod disabled.", modInfo.modVersion)
        return
    end

    mwse.log("%s Initialized.", modInfo.modVersion)
    rename.onInitialized()

    -- Log a list of the display names of all objects when those names differ from the actual object names, if logging
    -- enabled. Also log the "objectNameToID" reverse lookup table.
    common.logTable(data.displayNames, "displayNames")
    common.logTable(data.displayNamesNoPrefix, "displayNamesNoPrefix")
    common.logTable(data.objectNameToID, "objectNameToID")

    ui.onInitialized()

    event.register("enchantedItemCreated", rename.onEnchantedItemCreated)
    -- Player-brewed potions are mostly unaffected by this mod, but they'll be processed during the next game load
    -- anyway, so we might as well process them when they're created and save their base names in player data.
    event.register("potionBrewed", rename.onEnchantedItemCreated)
    event.register("loaded", rename.onLoaded, { priority = -10 })
    -- High priority so Book Worm can add its "(Read)" indicator afterward.
    event.register("uiObjectTooltip", ui.onTooltip, { priority = 10 })
    event.register("uiActivated", ui.menuMagicActivated, { filter = "MenuMagic" })
    event.register("uiActivated", ui.menuMagSelActivated, { filter = "MenuMagicSelect" })
    event.register("uiActivated", ui.menuInvSelActivated, { filter = "MenuInventorySelect" })
    -- This event is triggered whenever UI Expansion updates its filters in the inventory select menu (which overrides
    -- our name display changes, so we have to make our changes again every time).
    event.register("UIEXP:updatedInventorySelectTiles", ui.menuInvSelActivated)
    event.register("uiActivated", ui.menuRepairActivated, { filter = "MenuRepair" })
    event.register("uiActivated", ui.menuServiceRepairActivated, { filter = "MenuServiceRepair" })
    event.register("uiActivated", ui.hudActivated, { filter = "MenuMulti" })
    event.register("uiActivated", ui.onDialogActivated, { filter = "MenuDialog" })
    event.register("uiActivated", ui.enchantMenuActivated, { filter = "MenuEnchantment" })
    event.register("equipped", ui.onEquipmentChanged)
    event.register("unequipped", ui.onEquipmentChanged)
    event.register("enterFrame", ui.checkMagic)
    -- Low priority to make sure ui.checkMagic runs first (though it doesn't matter much - the HUD text would change the
    -- next frame anyway).
    event.register("enterFrame", ui.updateHudText, { priority = -10 })
    event.register("lockPick", ui.onPickProbe)
    event.register("trapDisarm", ui.onPickProbe)
    event.register("equip", ui.onEquip)
    -- This has to happen after rename.onLoaded, in case the player has a player-created enchanted item equipped as
    -- weapon or magic, so the correct name will display in the HUD when the game is loaded.
    event.register("loaded", ui.onLoaded, { priority = -20 })
end

-- Low priority to ensure other mods make their changes first.
event.register("initialized", onInitialized, { priority = -100 })

local function onModConfigReady()
    dofile("RationalNames.mcm")
end

event.register("modConfigReady", onModConfigReady)