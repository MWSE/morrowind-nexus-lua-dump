local config = require("Syanide.ShowSeptims.config")
local hudCustomizerInterop = include("seph.hudCustomizer.interop")

local goldBlockId = "MyMod:GoldHUD"
local goldBlock

-- Create HUD element if not already present
local function createGoldHUD()
    local hudMenu = tes3ui.findMenu("MenuMulti")
    if not hudMenu then return end

    goldBlock = hudMenu:findChild(goldBlockId)
    if goldBlock then
        return -- Already created, don't overwrite (HUD Customizer manages it)
    end

    -- Create new block
    goldBlock = hudMenu:createBlock({ id = goldBlockId })
    goldBlock.autoWidth = true
    goldBlock.autoHeight = true
    goldBlock.flowDirection = "left_to_right"
    goldBlock.paddingAllSides = 6
    goldBlock.color = { 0.1, 0.1, 0.1 }
    goldBlock.alpha = 0.8
    goldBlock.borderAllSides = 2

    -- Do NOT set position here — HUD Customizer manages it!

    goldBlock:createLabel({ id = "MyMod:GoldLabel", text = "Septims: 0" })
    goldBlock:updateLayout()
end

-- Register element with HUD Customizer (one-time registration)
local function registerWithHUDCustomizer()
    if not hudCustomizerInterop then return end

    -- Register the block ID for customization
    hudCustomizerInterop:registerElement(
        goldBlockId,
        "Show Septims",
        {
            positionX = 0.0,  -- Default only (used if user hasn’t moved it)
            positionY = 1.0,
            visible = true
        },
        {
            position = true,
            size = false,
            visibility = true
        }
    )
end

-- Update gold label every frame
local function updateGold()
    if not goldBlock then return end
    local label = goldBlock:findChild("MyMod:GoldLabel")
    if label then
        local gold = tes3.getPlayerGold()
        local preference = config.currencyPreference

        if preference == "Septims" then
            label.text = string.format("Septims: %d", gold)
        elseif preference == "Drakes" then
            label.text = string.format("Drakes: %d", gold)
        elseif preference == "None" then
            label.text = string.format("%d", gold)
        else -- default fallback
            label.text = string.format("Gold: %d", gold)
        end
    end
end


-- On menu ready (not just loaded), create once
event.register("uiActivated", function(e)
    if e.element.name == "MenuMulti" then
        createGoldHUD()
    end
end, { priority = 500 })

-- Register HUD Customizer element once at mod init
event.register("initialized", function()
    registerWithHUDCustomizer()
end)

-- Update value every frame
event.register("simulate", function()
    updateGold()
end)
