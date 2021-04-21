local modName = "Quick Equip"
local configPath = "shiftEquip"
local logger = require("mer.shiftEquip.logger")
local config = mwse.loadConfig(configPath, {
    enabled = true,
    hotkey = { keyCode = tes3.scanCode.lShift },
    logLevel = logger.logLevel.INFO
})
local log = logger.new{
    name = modName,
    logLevel = config.logLevel
}


local unequipSounds = {
    [tes3.objectType.armor] = {
        "Item Armor Light Up",
        "Item Armor Medium Up",
        "Item Armor Heavy Up"
    },
    [tes3.objectType.weapon] = {
        bluntOneHand = "Item Weapon Blunt Up",
        bluntTwoClose = "Item Weapon Blunt Up",
        bluntTwoWide = "Item Weapon Blunt Up",
        marksmanBow = "Item Weapon Bow Up",
        marksmanCrossbow = "Item Weapon Crossbow Up",
        longBladeOneHand = "Item Weapon Longblade Up",
        longBladeTwoClose = "Item Weapon Longblade Up",
        shortBladeOneHand = "Item Weapon Shortblade Up",
        spearTwoWide = "Item Weapon Spear Up"
    },
    [tes3.objectType.ammunition] = "Item Ammo Up",
    [tes3.objectType.clothing] = {
        default = "Item Clothes Up",
        ring = "Item Ring Up"
    },
    [tes3.objectType.lockpick] = "Item Lockpick Up",
    [tes3.objectType.probe] = "Item Probe Up",
}
local defaultUnequipSound = "Item Misc Up"

local function getUnequipSound(obj)
    local objType = obj.objectType
    local soundData = unequipSounds[objType]
    if soundData == nil then
        return defaultUnequipSound
    elseif objType == tes3.objectType.armor then
        return soundData[obj.weightClass + 1]
    elseif objType == tes3.objectType.weapon then
        return soundData[obj.type] or defaultUnequipSound
    elseif objType == tes3.objectType.clothing then
        return obj.slot == tes3.clothingSlot.ring and soundData.ring or soundData.default
    else
        return soundData
    end
end

local function onTileClick(e)
    if config.enabled ~= true then 
        log:debug("Mod disabled")
        return 
    end
    local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    if contentsMenu and contentsMenu.visible == true then
        return
    end
    local barterMenu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
    if barterMenu and barterMenu.visible == true then
        return
    end
    local inputController = tes3.worldController.inputController
    local holdingShift = (inputController:isKeyDown(config.hotkey.keyCode))
    if holdingShift then
        if e.tile.isEquipped then
            log:debug("Unequipping %s", e.item.id)
            tes3.mobilePlayer:unequip{ item = e.item, playSound = true }
            tes3.playSound{ reference = tes3.player, sound = getUnequipSound(e.item)}
        else
            local eventData = {
                item = e.item,
                itemData = e.itemData,
                reference = tes3.player
            }
            local response = event.trigger( "equip", eventData, { filter = tes3.player })
            if response.block ~= true then
                log:debug("Equipping %s", e.item.id)
                tes3.mobilePlayer:equip{
                    item = e.item,
                    itemData = e.itemData
                }

            end
        end
        return { block = true }
    end
end

event.register("UIEX:InventoryTileClicked", onTileClick)




local function registerMCM()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(configPath, config)
    template:register()
    local page = template:createSideBarPage{
        label = "Settings",
        description = "Hold down shift (or another configured key) to equip items in your inventory when you click on them."
    }
    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

    page:createKeyBinder{
        label = "Assign Keybind for Equipping Items",
        description = "Use this option to set the key to be held down for equipping/unequipping items.",
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable{
            id = "hotkey",
            table = config,
        }
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level. Keep on INFO unless you are debugging.",
        options = {
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
        callback = function(self)
            log:setLogLevel(self.variable.value)
        end
    }
    log:debug("MCM registered")
end

event.register("modConfigReady", registerMCM)