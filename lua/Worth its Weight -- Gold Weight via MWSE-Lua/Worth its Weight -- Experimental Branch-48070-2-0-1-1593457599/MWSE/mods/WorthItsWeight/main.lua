--[[
    Worth its Weight: Gold Weight via MWSE
    by JaceyS
    v2.0.1
]]
local defaultConfig = {
    goldWeight = 0.02,
    goldTooltip = true,
    enabled = true,
    hardDisabled = false
}
local config = mwse.loadConfig("WorthItsWeight", defaultConfig)


local function onItemTileUpdated()
    if (config.hardDisabled) then
        return
    end
    local oldWeight = tes3.mobilePlayer.encumbrance.current
    local weight = tes3.player.object.inventory:calculateWeight()
    if(tes3.isAffectedBy({reference = tes3.player, effect = tes3.effect.burden})) then
        local burden = tes3.getEffectMagnitude({reference = tes3.player, effect = tes3.effect.burden})
        weight = weight + burden
    end
    if(tes3.isAffectedBy({reference = tes3.player, effect = tes3.effect.feather})) then
        local feather = tes3.getEffectMagnitude({reference = tes3.player, effect = tes3.effect.feather})
        weight = math.max(weight - feather, 0)
    end
    if (oldWeight ~= weight) then
        tes3.setStatistic({reference = tes3.mobilePlayer, name = "encumbrance", current = weight})
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
    if(containerMenu) then
        local mobile = containerMenu:getPropertyObject("MenuContents_Actor")
        if(not mobile) then
            return
        end
        local oldContainerWeight = mobile.encumbrance.current
        local containerWeight = mobile.reference.object.inventory:calculateWeight()
        --tes3.messageBox("Container Weight: " ..containerWeight)
        if(tes3.isAffectedBy({reference = mobile.reference, effect = tes3.effect.burden})) then
            local containerBurden = tes3.getEffectMagnitude({reference = mobile.reference, effect = tes3.effect.burden})
            containerWeight = containerWeight + containerBurden
        end
        if(tes3.isAffectedBy({reference = mobile.reference, effect = tes3.effect.feather})) then
            local containerFeather = tes3.getEffectMagnitude({reference = mobile.reference, effect = tes3.effect.feather})
            containerWeight = math.max(containerWeight - containerFeather, 0)
        end
        if (oldContainerWeight ~= containerWeight) then
            tes3.setStatistic({reference = mobile, name = "encumbrance", current = containerWeight})
            local containerEncumbranceBarID = tes3ui.registerID("MenuContents_EncumbranceBar")
            local containerEncumbranceBar = containerMenu:findChild(containerEncumbranceBarID)
            if (containerEncumbranceBar) then
                containerEncumbranceBar.widget.current = mobile.encumbrance.current
                containerEncumbranceBar:updateLayout()
                containerMenu:updateLayout()
            end
        end
    end
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

local function onLoaded()
    event.register("uiEvent", onItemTileUpdated)
end

local function onInitialized()
    event.register("itemTileUpdated", onItemTileUpdated)
    event.register("itemDropped", onItemTileUpdated)
    event.register("uiObjectTooltip", onUIObjectTooltip)
    event.register("loaded", onLoaded)
    print("[Worth its Weight: Gold Weight MWSE: INFO] Gold Weight MWSE Initialized")
    local gold_001 = tes3.getObject("Gold_001")
    if(config.enabled) then
        gold_001.weight = config.goldWeight
    else
        gold_001.weight = 0
    end
end

event.register("initialized", onInitialized)

-- MCM
local function registerMCM()
    local template = mwse.mcm.createTemplate("Worth its Weight")
    template.headerImagePath = "MWSE/mods/WorthItsWeight/Worth Its Weight Logo.tga"
    template:saveOnClose("WorthItsWeight", config)

    local page = template:createSideBarPage()
    page.label = "Settings"
    page.description = "Worth its Weight, v2.0"

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
        variable = mwse.mcm:createTableVariable{id = "enabled", table = config}
    })

    category:createYesNoButton({
        label = "Hard Disable",
        description = "Completely stops the behavior of the mod, meaning that it cannot fix encumbrances it previously changed.",
        variable = mwse.mcm:createTableVariable{id = "hardDisabled", table = config}
    })

    mwse.mcm.register(template)
end



event.register("modConfigReady", registerMCM)