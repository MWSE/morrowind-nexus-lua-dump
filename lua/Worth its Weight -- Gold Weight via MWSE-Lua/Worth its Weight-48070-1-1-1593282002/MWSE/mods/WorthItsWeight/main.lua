--[[
    Worth its Weight: Gold Weight via MWSE
    by JaceyS
    v1.1
]]
local defaultConfig = {
    goldWeight = 0.02,
    goldTooltip = true,
    enabled = true,
    hardDisabled = false
}
local config = mwse.loadConfig("WorthItsWeight", defaultConfig)


local function onItemTileUpdated(e)
    if(config.hardDisabled) then
        return
    end

    if (not tes3.player.data.JaceyS) then
        tes3.player.data.JaceyS = {}
    end
    if (not tes3.player.data.JaceyS.WiW) then
        tes3.player.data.JaceyS.WiW = {}
    end
    if (not tes3.player.data.JaceyS.WiW.goldWeight) then
        tes3.player.data.JaceyS.WiW.goldWeight = 0
    end
    if (tes3.player.data.JaceyS.WiW.goldWeight ~= tes3.getPlayerGold() * math.abs(tonumber(config.goldWeight))) then
        --print("Player's Gold Weight has changed from " .. playerGoldWeight .. " to ".. tes3.getPlayerGold() * math.abs(tonumber(config.goldWeight)))
        tes3.modStatistic({reference = tes3.mobilePlayer, name = "encumbrance", current =  -1 * tes3.player.data.JaceyS.WiW.goldWeight})
        --print(playerGoldWeight .. " subtracted from player encumbrance")
        tes3.player.data.JaceyS.WiW.goldWeight = tes3.getPlayerGold() * math.abs(tonumber(config.goldWeight))
        tes3.modStatistic({reference = tes3.mobilePlayer, name = "encumbrance", current = tes3.player.data.JaceyS.WiW.goldWeight})
        --print(playerGoldWeight .. " added to player encumbrance")
        --print("Player's Encumbrance Now Equal to " .. tes3.mobilePlayer.encumbrance.current)
        local inventoryMenuID = tes3ui.registerID("MenuInventory")
        local inventoryMenu = tes3ui.findMenu(inventoryMenuID)
        local encumbranceBarID = tes3ui.registerID("MenuInventory_Weightbar")
        local encumbranceBar = inventoryMenu:findChild(encumbranceBarID)
        encumbranceBar.widget.current = tes3.mobilePlayer.encumbrance.current
        encumbranceBar:updateLayout()
        inventoryMenu:updateLayout()
    end
    local containerMenuID = tes3ui.registerID("MenuContents")
    local containerMenu = tes3ui.findMenu(containerMenuID)
    if (containerMenu) then
        local mobile = containerMenu:getPropertyObject("MenuContents_Actor")
        if(not mobile) then
            return
        end
        local goldCount
        for _, itemStack in pairs(mobile.object.inventory.iterator) do
            if (itemStack.object.id == "Gold_001") then
                goldCount = itemStack.count
            end
        end
        if( not mobile.reference.data.JaceyS) then
            mobile.reference.data.JaceyS = {}
        end
        if (not mobile.reference.data.JaceyS.WiW) then
            mobile.reference.data.JaceyS.WiW = {}
        end
        if (not mobile.reference.data.JaceyS.WiW.goldWeight) then
            mobile.reference.data.JaceyS.WiW.goldWeight = 0
        end
        if (mobile.reference.data.JaceyS.WiW.goldWeight ~= goldCount * math.abs(tonumber(config.goldWeight))) then
            tes3.modStatistic({reference = mobile, name = "encumbrance", current = -1 * mobile.reference.data.JaceyS.WiW.goldWeight})
            mobile.reference.data.JaceyS.WiW.goldWeight = goldCount * math.abs(tonumber(config.goldWeight))
            tes3.modStatistic({reference = mobile, name = "encumbrance", current = mobile.reference.data.JaceyS.WiW.goldWeight})
            local containerEncumbranceBarID = tes3ui.registerID("MenuContents_EncumbranceBar")
            local containerEncumbranceBar = containerMenu:findChild(containerEncumbranceBarID)
            if (containerEncumbranceBar) then
                containerEncumbranceBar.widget.current = mobile.encumbrance.current
                containerEncumbranceBar:updateLayout()
                containerMenu:updateLayout()
                --tes3.messageBox("Encumbrance Bar updated")
            end
        end
    end
end

local function onLoad()
    event.unregister("uiEvent", onItemTileUpdated)
end
local function onLoaded()
    event.register("uiEvent", onItemTileUpdated)
end

local function onSave() -- clear the goldweight  when the player goes to save
    --print(os.time() .. ": Player is about to save.")
    tes3.modStatistic({reference = tes3.mobilePlayer, name = "encumbrance", current =  -1 * tes3.player.data.JaceyS.WiW.goldWeight})
    tes3.player.data.JaceyS.WiW.goldWeight = 0
    local inventoryMenuID = tes3ui.registerID("MenuInventory")
    local inventoryMenu = tes3ui.findMenu(inventoryMenuID)
    local encumbranceBarID = tes3ui.registerID("MenuInventory_Weightbar")
    local encumbranceBar = inventoryMenu:findChild(encumbranceBarID)
    encumbranceBar.widget.current = tes3.mobilePlayer.encumbrance.current
    encumbranceBar:updateLayout()
    inventoryMenu:updateLayout()
end

local function onUIObjectTooltip(e)
    if(config.hardDisabled or not config.enabled) then
        return
    end
    if (config.goldTooltip == true) then
        if(string.startswith(e.object.id, "Gold_")) then
            local block = e.tooltip:createBlock{}
            block.minWidth = 1
            block.maxWidth = 440
            block.autoWidth = true
            block.autoHeight = true
            block.paddingAllSides = 4
            local label
            if(e.reference == nil) then
                if(e.count == 0) then
                    local containerMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
                    local object = containerMenu:getPropertyObject("MenuContents_ObjectContainer")
                    local goldCount
                    for _, itemStack in pairs(object.inventory.iterator) do
                        if (itemStack.object.id == "Gold_001") then
                            goldCount = itemStack.count
                        end
                    end
                    label = block:createLabel({text = "Stack Weight: " .. goldCount * math.abs(tonumber(config.goldWeight))})
                else
                    label = block:createLabel({text = "Stack Weight: " .. e.count * math.abs(tonumber(config.goldWeight))})
                end
            else
                label = block:createLabel({text = "Stack Weight: " .. e.reference.stackSize * math.abs(tonumber(config.goldWeight))})
            end
            label.wrapText = true
        end
    end
end

local function onInitialized()
    event.register("itemTileUpdated", onItemTileUpdated)
    event.register("itemDropped", onItemTileUpdated)
    event.register("save", onSave)
    event.register("loaded", onLoaded)
    event.register("load", onLoad)
    event.register("uiObjectTooltip", onUIObjectTooltip)
    print("[Worth its Weight: Gold Weight MWSE: INFO] Gold Weight MWSE Initialized")
end

event.register("initialized", onInitialized)

-- MCM
local function registerMCM()
    local template = mwse.mcm.createTemplate("Worth its Weight")
    template.headerImagePath = "MWSE/mods/WorthItsWeight/Worth Its Weight Logo.tga"
    template:saveOnClose("WorthItsWeight", config)

    local page = template:createSideBarPage()
    page.label = "Settings"
    page.description = "Worth its Weight, v1.1"

    local category = page:createCategory("Settings")

    local toolTipButton = category:createYesNoButton()
    toolTipButton.label = "Display Gold Weight Tooltip"
    toolTipButton.description = "Toggle to show the weight of a stack of gold in the tooltip, both in your inventory and in the world."
    toolTipButton.variable = mwse.mcm:createTableVariable{id = "goldTooltip", table = config}

    local goldWeightField = category:createTextField()
    goldWeightField.numbersOnly = true
    goldWeightField.label = "Gold Weight"
    goldWeightField.description = "The weight per coin."
    goldWeightField.variable = mwse.mcm:createTableVariable{id = "goldWeight", table = config}

    category:createYesNoButton({
        label = "Enable",
        description = "Toggle the mod on and off. This is a \"soft\" disable, still allowing the mod to fix encumbrances it has changed as they come up.",
        variable = mwse.mcm:createTableVariable{id = "enabled", table = config},
        callback = function() config.goldWeight = 0 end
    })

    category:createYesNoButton({
        label = "Hard Disable",
        description = "Completely stops the behavior of the mod, meaning that it cannot fix encumbrances it previously changed.",
        variable = mwse.mcm:createTableVariable{id = "hardDisabled", table = config}
    })

    mwse.mcm.register(template)
end



event.register("modConfigReady", registerMCM)