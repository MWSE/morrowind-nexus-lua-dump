local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local settings = storage.playerSection("SettingsVoshondsQuickSelect")
local textSettings = storage.playerSection("SettingsVoshondsQuickSelectText")
local Debug = require("scripts.voshondsquickselect.qs_debug")
local magicChargeSettings = storage.playerSection("SettingsVoshondsQuickSelectMagicCharges")
local itemCountThresholdSettings = storage.playerSection("SettingsVoshondsQuickSelectItemCountThresholds")

-- Variables for periodic UI refresh
local REFRESH_INTERVAL = 0.5       -- Refresh every 0.5 seconds
local activeEnchantedItems = {}    -- Track active enchanted items in hotbar
local enchantmentChargeCache = {}  -- Simple cache for last known charges
local lastTextStyleRefreshTime = 0 -- Track when text styles were last refreshed
local refreshTimerActive = false   -- Flag to prevent multiple timers

-- Forward declarations
local startRefreshTimer
local refreshEnchantedItems

-- Helper function to get item charge (called directly when needed)
local function getItemCharge(item)
    if not item or not item.type or not item.recordId then
        return nil
    end

    local record = item.type.records[item.recordId]
    local enchantmentId = record and record.enchant

    if not enchantmentId or enchantmentId == "" then
        return nil
    end

    local charge = nil

    -- Try to get charge using the proper API method
    if types.Item.getEnchantmentCharge then
        charge = types.Item.getEnchantmentCharge(item)
        -- Fallback to older methods
    elseif types.Item.itemData and types.Item.itemData(item) and types.Item.itemData(item).charge ~= nil then
        charge = types.Item.itemData(item).charge
    elseif types.Item.charge then
        charge = types.Item.charge(item)
    end

    if charge ~= nil then
        -- Store in cache for future reference
        local itemKey = item.recordId .. "_" .. (item.id or "")
        local oldCharge = enchantmentChargeCache[itemKey]
        local newCharge = math.floor(charge)

        -- Only update cache if charge actually changed
        if oldCharge ~= newCharge then
            enchantmentChargeCache[itemKey] = newCharge
            Debug.frameLog("EnchantCharge", "Charge changed for " .. item.recordId .. ": " ..
                tostring(oldCharge) .. " -> " .. tostring(newCharge))
        end
    end

    return charge
end

-- Function to register an enchanted item for periodic updates
local function registerEnchantedItem(item, slotNumber)
    if item and item.type and item.recordId then
        local record = item.type.records[item.recordId]
        local enchantmentId = record and record.enchant

        if enchantmentId and enchantmentId ~= "" then
            local enchantment = core.magic.enchantments.records[enchantmentId]

            if enchantment then
                local usesCharge = (
                    enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or
                    enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike or
                    enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce
                )

                if usesCharge then
                    -- Add to active enchanted items list
                    activeEnchantedItems[slotNumber] = {
                        item = item,
                        enchantmentId = enchantmentId
                    }
                    Debug.frameLog("EnchantCharge", "Registered enchanted item in slot " ..
                        tostring(slotNumber) .. ": " .. item.recordId)

                    -- Start the refresh timer if not already running
                    startRefreshTimer()

                    return true
                end
            end
        end
    end
    return false
end

-- Function to start the refresh timer
startRefreshTimer = function()
    if refreshTimerActive then
        return -- Timer already running
    end

    refreshTimerActive = true

    -- Create a timer that runs every REFRESH_INTERVAL seconds
    async:newUnsavableSimulationTimer(REFRESH_INTERVAL, function()
        refreshEnchantedItems()

        -- Always restart the timer to ensure continuous updates
        refreshTimerActive = false
        startRefreshTimer()
    end)
end

-- Function to refresh enchanted items
refreshEnchantedItems = function()
    Debug.frameLog("EnchantCharge", "Checking enchanted items for updates...")
    local updatedCount = 0
    local anyEnchantedItems = false

    -- Check all active enchanted items for charge updates
    for slotNumber, data in pairs(activeEnchantedItems) do
        local item = data.item
        if item then
            anyEnchantedItems = true
            local charge = getItemCharge(item)
            if charge then
                updatedCount = updatedCount + 1
            end
        end
    end

    -- If we have any enchanted items, always refresh the UI at the specified interval
    -- This ensures continuous updates for enchanted items
    if anyEnchantedItems then
        Debug.frameLog("EnchantCharge", "Found " .. updatedCount .. " enchanted items, refreshing UI")

        -- Use the QuickSelect_Hotbar interface to trigger a UI refresh
        if I.QuickSelect_Hotbar and I.QuickSelect_Hotbar.isHotbarVisible and I.QuickSelect_Hotbar.isHotbarVisible() then
            Debug.frameLog("EnchantCharge", "Calling QuickSelect_Hotbar.drawHotbar() (hotbar is visible)")
            local success, err = pcall(function()
                I.QuickSelect_Hotbar.drawHotbar(false)
            end)
            if not success then
                Debug.error("EnchantCharge", "Error refreshing UI: " .. tostring(err))
            end
        else
            Debug.frameLog("EnchantCharge", "Hotbar not visible, skipping UI refresh")
        end
    end
end

-- Function to get text appearance settings
local function getTextStyles()
    -- Get color settings or use defaults
    local textColor = textSettings:get("slotTextColor") or util.color.rgba(0.792, 0.647, 0.376, 1.0)
    local shadowColor = textSettings:get("slotTextShadowColor") or util.color.rgba(0, 0, 0, 1.0)

    -- Get alpha settings (0-100) and convert to 0-1 range
    local textAlpha = (textSettings:get("slotTextAlpha") or 100) / 100
    local shadowAlpha = (textSettings:get("slotTextShadowAlpha") or 100) / 100

    -- Apply alpha values to colors
    local finalTextColor = util.color.rgba(textColor.r, textColor.g, textColor.b, textAlpha)
    local finalShadowColor = util.color.rgba(shadowColor.r, shadowColor.g, shadowColor.b, shadowAlpha)

    -- Check if shadow is enabled
    local shadowEnabled = textSettings:get("enableTextShadow")
    if shadowEnabled == nil then shadowEnabled = true end -- Default to true if not set

    -- Check if slot numbers and item counts should be shown
    local showSlotNumbers = textSettings:get("showSlotNumbers")
    if showSlotNumbers == nil then showSlotNumbers = true end -- Default to true if not set

    local showItemCounts = textSettings:get("showItemCounts")
    if showItemCounts == nil then showItemCounts = true end -- Default to true if not set

    -- Get text sizes
    local slotNumberTextSize = textSettings:get("slotNumberTextSize") or 14
    local itemCountTextSize = textSettings:get("itemCountTextSize") or 12

    return {
        textColor = finalTextColor,
        shadowColor = finalShadowColor,
        shadowEnabled = shadowEnabled,
        showSlotNumbers = showSlotNumbers,
        showItemCounts = showItemCounts,
        slotNumberTextSize = slotNumberTextSize,
        itemCountTextSize = itemCountTextSize
    }
end

-- Define reusable text style variables
local TEXT_COLORS = {
    itemCount = nil, -- Will be set dynamically
    slotNumber = nil -- Will be set dynamically
}

local TEXT_SHADOWS = {
    enabled = true, -- Will be set dynamically
    color = nil     -- Will be set dynamically
}

-- Function to refresh text style settings
local function refreshTextStyles()
    local styles = getTextStyles()

    TEXT_COLORS.itemCount = styles.textColor
    TEXT_COLORS.slotNumber = styles.textColor

    TEXT_SHADOWS.enabled = styles.shadowEnabled
    TEXT_SHADOWS.color = styles.shadowColor
end

-- Initialize text styles
refreshTextStyles()

local function getIconSize()
    return settings:get("iconSize") or 40
end

local savedTextures = {}
local function getPerTypeThresholdColor(itemType, count)
    local textAlpha = (textSettings:get("slotTextAlpha") or 100) / 100
    local baseColor = textSettings:get("slotTextColor") or util.color.rgba(0.792, 0.647, 0.376, 1.0)
    local warningColor = util.color.rgba(0.95, 0.15, 0.0, textAlpha)
    local criticalColor = util.color.rgba(1.0, 0.1, 0.1, textAlpha)
    local enable, critical, warning

    if itemType == types.Potion then
        enable = itemCountThresholdSettings:get("enablePotionThresholdColor")
        critical = itemCountThresholdSettings:get("potionCriticalThreshold") or 1
        warning = itemCountThresholdSettings:get("potionWarningThreshold") or 5
    elseif itemType == types.Repair then
        enable = itemCountThresholdSettings:get("enableRepairThresholdColor")
        critical = itemCountThresholdSettings:get("repairCriticalThreshold") or 1
        warning = itemCountThresholdSettings:get("repairWarningThreshold") or 5
    elseif itemType == types.Probe then
        enable = itemCountThresholdSettings:get("enableProbeThresholdColor")
        critical = itemCountThresholdSettings:get("probeCriticalThreshold") or 1
        warning = itemCountThresholdSettings:get("probeWarningThreshold") or 5
    elseif itemType == types.Lockpick then
        enable = itemCountThresholdSettings:get("enableLockpickThresholdColor")
        critical = itemCountThresholdSettings:get("lockpickCriticalThreshold") or 1
        warning = itemCountThresholdSettings:get("lockpickWarningThreshold") or 5
    elseif itemType == types.Weapon then
        -- Ammo: Weapon type, but only for arrows/bolts
        -- We'll check for ammo type below
        enable = itemCountThresholdSettings:get("enableAmmoThresholdColor")
        critical = itemCountThresholdSettings:get("ammoCriticalThreshold") or 1
        warning = itemCountThresholdSettings:get("ammoWarningThreshold") or 5
    end

    -- Special handling for ammo: only apply to arrows/bolts
    if itemType == types.Weapon then
        -- Weapon type, but only for arrows/bolts
        -- We'll check for ammo type below
        return nil -- handled in getThresholdItemCountColor
    end

    if not enable then
        return baseColor
    end
    if count <= critical then
        return criticalColor
    elseif count <= warning then
        local t = (count - critical) / math.max(1, (warning - critical))
        return util.color.rgba(
            warningColor.r * (1 - t) + baseColor.r * t,
            warningColor.g * (1 - t) + baseColor.g * t,
            warningColor.b * (1 - t) + baseColor.b * t,
            textAlpha
        )
    else
        return baseColor
    end
end

-- Updated getThresholdItemCountColor to use per-type settings
local function getThresholdItemCountColor(count, item)
    if not item or not item.type then
        return getTextStyles().textColor
    end
    -- Ammo: only color for arrows/bolts
    if item.type == types.Weapon then
        local record = item.type.records[item.recordId]
        local ammoTypes = {
            [types.Weapon.TYPE.Arrow] = true,
            [types.Weapon.TYPE.Bolt] = true
        }
        if ammoTypes[record.type] then
            local textAlpha = (textSettings:get("slotTextAlpha") or 100) / 100
            local baseColor = textSettings:get("slotTextColor") or util.color.rgba(0.792, 0.647, 0.376, 1.0)
            local warningColor = util.color.rgba(0.95, 0.15, 0.0, textAlpha)
            local criticalColor = util.color.rgba(1.0, 0.1, 0.1, textAlpha)
            local enable = itemCountThresholdSettings:get("enableAmmoThresholdColor")
            local critical = itemCountThresholdSettings:get("ammoCriticalThreshold") or 1
            local warning = itemCountThresholdSettings:get("ammoWarningThreshold") or 5
            if not enable then
                return baseColor
            end
            if count <= critical then
                return criticalColor
            elseif count <= warning then
                local t = (count - critical) / math.max(1, (warning - critical))
                return util.color.rgba(
                    warningColor.r * (1 - t) + baseColor.r * t,
                    warningColor.g * (1 - t) + baseColor.g * t,
                    warningColor.b * (1 - t) + baseColor.b * t,
                    textAlpha
                )
            else
                return baseColor
            end
        end
    end
    -- All other types
    return getPerTypeThresholdColor(item.type, count)
end

local function getMagicChargeStyles()
    local showMagicCharges = magicChargeSettings:get("showMagicCharges")
    if showMagicCharges == nil then showMagicCharges = true end
    local showMaxMagicCharges = magicChargeSettings:get("showMaxMagicCharges")
    if showMaxMagicCharges == nil then showMaxMagicCharges = true end
    local textSize = magicChargeSettings:get("magicChargeTextSize") or 14
    local textColor = magicChargeSettings:get("magicChargeTextColor") or util.color.rgba(0.2, 0.6, 1, 1)
    local textAlpha = (magicChargeSettings:get("magicChargeTextAlpha") or 100) / 100
    local finalTextColor = util.color.rgba(textColor.r, textColor.g, textColor.b, textAlpha)
    local shadowEnabled = magicChargeSettings:get("magicChargeTextShadow")
    if shadowEnabled == nil then shadowEnabled = true end
    local shadowColor = magicChargeSettings:get("magicChargeTextShadowColor") or util.color.rgba(0, 0, 0, 1.0)
    return {
        showMagicCharges = showMagicCharges,
        showMaxMagicCharges = showMaxMagicCharges,
        textSize = textSize,
        textColor = finalTextColor,
        shadowEnabled = shadowEnabled,
        shadowColor = shadowColor
    }
end

local function getEnchantmentChargeColor(charge, maxCharge)
    local enableThresholdColor = magicChargeSettings:get("enableChargeThresholdColor")
    Debug.log("EnchantCharge", "getEnchantmentChargeColor called - charge: " .. tostring(charge) ..
        ", maxCharge: " .. tostring(maxCharge) ..
        ", enableThresholdColor: " .. tostring(enableThresholdColor))

    if not enableThresholdColor or not charge or not maxCharge or maxCharge <= 0 then
        Debug.log("EnchantCharge", "Using default color: thresholds disabled or invalid charge values")
        return getMagicChargeStyles().textColor
    end

    local textAlpha = (magicChargeSettings:get("magicChargeTextAlpha") or 100) / 100
    local baseColor = magicChargeSettings:get("magicChargeTextColor") or util.color.rgba(0.2, 0.6, 1, 1)
    local baseColorWithAlpha = util.color.rgba(baseColor.r, baseColor.g, baseColor.b, textAlpha)

    -- Critical threshold (10% or less)
    local criticalColor = util.color.rgba(1.0, 0.1, 0.1, textAlpha) -- red

    -- Warning threshold (30% or less)
    local warningColor = util.color.rgba(0.95, 0.65, 0.0, textAlpha) -- orange

    local percentage = charge / maxCharge
    Debug.log("EnchantCharge", "Charge percentage: " .. tostring(percentage * 100) .. "%")

    if percentage <= 0.1 then
        Debug.log("EnchantCharge", "Using critical color (<=10%)")
        return criticalColor
    elseif percentage <= 0.3 then
        Debug.log("EnchantCharge", "Using warning color (<=30%)")
        return warningColor
    else
        Debug.log("EnchantCharge", "Using normal color (>30%)")
        return baseColorWithAlpha
    end
end

local function textContent(text, isCharge, maxCharge, item)
    if not text or text == "" then
        return {}
    end
    refreshTextStyles()
    -- Always show charge values for enchanted items, only check showItemCounts for regular item counts
    local styles = getTextStyles()
    if not isCharge and not styles.showItemCounts then
        return {}
    end
    local count = tonumber(text)
    local color = styles.textColor
    local position = util.vector2(0.1, 0.05) -- Default position (upper left)
    -- Special handling for charge values
    if isCharge then
        local magicStyles = getMagicChargeStyles()
        if not magicStyles.showMagicCharges then
            return {}
        end

        -- Determine color based on charge percentage if maxCharge is available
        if maxCharge and tonumber(text) and tonumber(maxCharge) then
            color = getEnchantmentChargeColor(tonumber(text), tonumber(maxCharge))
        else
            color = magicStyles.textColor
        end

        local displayText = text
        if maxCharge and magicStyles.showMaxMagicCharges then
            displayText = tostring(text) .. "/" .. tostring(maxCharge)
        end
        return {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = displayText,
                textSize = magicStyles.textSize,
                relativePosition = position,
                anchor = position,
                arrange = ui.ALIGNMENT.Start,
                align = ui.ALIGNMENT.Start,
                textShadow = magicStyles.shadowEnabled,
                textShadowColor = magicStyles.shadowColor,
                textColor = color
            }
        }
    elseif count then
        color = getThresholdItemCountColor(count, item)
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            textSize = styles.itemCountTextSize,
            relativePosition = position,
            anchor = position,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start,
            textShadow = TEXT_SHADOWS.enabled,
            textShadowColor = TEXT_SHADOWS.color,
            textColor = color
        }
    }
end

local function imageContent(resource, half, customOpacity)
    local size = getIconSize()
    local opacity = customOpacity or 1
    if half and customOpacity == nil then
        opacity = 0.5
    end

    -- Create a consistent size for all images
    -- Reduce by 2 pixels to prevent cropping on edges
    local sizeX = size - 0.1
    local sizeY = size - 0.1

    if half then
        sizeY = sizeY / 2
    end

    if not resource then
        return {}
    end

    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(sizeX, sizeY),
            alpha = opacity,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center
        }
    }
end
local function getTexture(path)
    if not savedTextures[path] and path then
        savedTextures[path] = ui.texture({ path = path })
    end
    return savedTextures[path]
end
local function formatNumber(num)
    local threshold = 1000
    local millionThreshold = 1000000

    if num >= millionThreshold then
        local formattedNum = math.floor(num / millionThreshold)
        return string.format("%dm", formattedNum)
    elseif num >= threshold then
        local formattedNum = math.floor(num / threshold)
        return string.format("%dk", formattedNum)
    else
        return tostring(num)
    end
end
local function FindEnchant(item)
    if not item or not item.id then
        return nil
    end
    if item.enchant then
        return item.enchant
    end
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "") then
        return nil
    end
    return item.type.records[item.recordId].enchant
end

-- Helper to check if a table is empty
local function isEmptyTable(t)
    return type(t) == 'table' and next(t) == nil
end

-- Helper to get the currently equipped item of a given type (Lockpick, Probe, Repair)
local function getEquippedItemOfType(itemType)
    local equip = types.Actor.equipment(self)
    for _, equippedItem in pairs(equip) do
        if equippedItem and equippedItem.type == itemType then
            return equippedItem
        end
    end
    return nil
end

-- Helper to get the total count of items of the same type and recordId in inventory (regardless of condition)
local function getTotalItemCount(item)
    if not item or not item.type or not item.recordId then return 0 end
    local total = 0
    for _, invItem in ipairs(types.Actor.inventory(self):getAll()) do
        if invItem.type == item.type and invItem.recordId == item.recordId then
            total = total + (invItem.count or 1)
        end
    end
    return total
end

local function getItemIcon(item, half, selected, slotNumber, slotPrefix, slotData)
    Debug.log("QuickSelect",
        "getItemIcon called for item: " ..
        tostring(item) ..
        ", type: " .. tostring(item and item.type) .. ", recordId: " .. tostring(item and item.recordId))
    if item and item.type and item.recordId then
        local record = item.type.records[item.recordId]
        Debug.log("QuickSelect",
            "Item record: " .. tostring(record and record.id) .. ", enchant: " .. tostring(record and record.enchant))
    end
    local itemIcon = nil

    local selectionResource
    local drawFavoriteStar = true
    selectionResource = getTexture("textures/voshondsQuickSelect/selected.tga")

    -- Get magic icon with reduced opacity (0.7)
    local magicIconOpacity = 0.3
    local magicIcon = FindEnchant(item) and FindEnchant(item) ~= "" and getTexture("textures/menu_icon_magic_mini.dds")
    local text = ""
    local chargeText = {}    -- Ensure chargeText is always defined
    local itemCountText = {} -- Ensure itemCountText is always defined
    local usesText = nil
    if item and item.type then
        local record = item.type.records[item.recordId]
        local enchantmentId = record and record.enchant
        if not record then
            Debug.error("ci_icon_render", "No record for " .. item.recordId)
        else
            Debug.log("ci_icon_render", "Icon: " .. tostring(record.icon))
        end
        -- Use total count for lockpicks, probes, repair items, potions, ammo; otherwise use stack count
        local alwaysShowCount = false
        if item.type == types.Lockpick or item.type == types.Probe or item.type == types.Repair or item.type == types.Potion then
            alwaysShowCount = true
        elseif item.type == types.Weapon then
            local ammoTypes = {
                [types.Weapon.TYPE.Arrow] = true,
                [types.Weapon.TYPE.Bolt] = true
            }
            if ammoTypes[record.type] then
                alwaysShowCount = true
            end
        end
        if alwaysShowCount then
            text = formatNumber(getTotalItemCount(item))
        elseif item.count > 1 then
            text = formatNumber(item.count)
        end
        itemIcon = getTexture(record.icon)

        -- Add enchanted item charge display (upper left, replaces item count if enchanted)
        if enchantmentId and enchantmentId ~= "" then
            Debug.log("QuickSelect",
                "Found enchantmentId: " .. tostring(enchantmentId) .. " for item: " .. tostring(item.recordId))
            local enchantment = core.magic.enchantments.records[enchantmentId]

            -- Register this enchanted item for periodic updates
            registerEnchantedItem(item, slotNumber)

            -- Get charge directly when rendering the item
            local charge = getItemCharge(item)

            -- If direct charge retrieval failed, try to use cached or slot data value
            if charge == nil then
                local itemKey = item.recordId .. "_" .. (item.id or "")
                if enchantmentChargeCache[itemKey] then
                    charge = enchantmentChargeCache[itemKey]
                elseif slotData and slotData.lastKnownCharge then
                    charge = slotData.lastKnownCharge
                end
            end

            Debug.log("QuickSelect", "Final charge value: " .. tostring(charge))

            if enchantment then
                Debug.log("QuickSelect", "Enchantment type: " .. tostring(enchantment.type))

                -- Only show charge for enchantments that use charges
                local usesCharge = (
                    enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or
                    enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike or
                    enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce
                )

                Debug.log("QuickSelect", "usesCharge: " .. tostring(usesCharge) .. ", charge: " .. tostring(charge))

                if usesCharge and charge ~= nil then
                    charge = math.floor(charge)
                    local maxCharge = enchantment and enchantment.charge and math.floor(enchantment.charge) or "?"
                    Debug.log("QuickSelect",
                        "Displaying charge: " ..
                        tostring(charge) .. "/" .. tostring(maxCharge) .. " for item: " .. tostring(item.recordId))
                    chargeText = textContent(tostring(charge), true, maxCharge, item)
                    Debug.log("QuickSelect",
                        "chargeText from textContent: " .. tostring(chargeText.props and chargeText.props.text))

                    -- Update slotData with the current charge for future reference
                    if slotData then
                        slotData.lastKnownCharge = charge
                    end
                elseif usesCharge and charge == nil then
                    Debug.log("QuickSelect",
                        "Enchanted item has no charge property (even after fallback): " .. tostring(item.recordId))
                end
            end
        end
        if item and item.type and (item.type == types.Lockpick or item.type == types.Probe or item.type == types.Repair) then
            local equipped = getEquippedItemOfType(item.type)
            if equipped then
                local itemData = types.Item.itemData(equipped)
                local currentUses = itemData and itemData.condition or nil
                local maxUses = item.type.records[equipped.recordId] and
                    item.type.records[equipped.recordId].maxCondition
                if currentUses and maxUses then
                    usesText = tostring(currentUses) .. "/" .. tostring(maxUses)
                end
            end
        end
    end

    local selectedContent = {}
    if selected then
        selectedContent = imageContent(selectionResource)
    end

    -- Save item count text for the upper left
    itemCountText = textContent(tostring(text), false, nil, item)

    -- Format the slot number with the prefix if available
    local slotText = slotNumber
    if slotPrefix and slotPrefix ~= "" then
        -- Calculate the slot's position within its bar (1-10)
        local slotPosition = ((slotNumber - 1) % 10) + 1
        -- Display slot number with prefix
        slotText = slotPrefix .. slotPosition
    else
        -- For the first bar, just show the slot position (1-10)
        local slotPosition = ((slotNumber - 1) % 10) + 1
        slotText = slotPosition
    end

    -- Refresh text styles to ensure we have the latest settings
    refreshTextStyles()

    -- Create slot number content only if enabled
    local slotNumberContent = {}
    local styles = getTextStyles()

    if styles.showSlotNumbers and slotNumber then
        slotNumberContent = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = tostring(slotText),
                textSize = styles.slotNumberTextSize,
                relativePosition = util.vector2(0.85, 0.9),
                anchor = util.vector2(0.85, 0.9),
                arrange = ui.ALIGNMENT.End,
                align = ui.ALIGNMENT.End,
                textShadow = TEXT_SHADOWS.enabled,
                textShadowColor = TEXT_SHADOWS.color,
                textColor = TEXT_COLORS.slotNumber
            }
        }
    end

    -- Compose UI content
    local uiContent = { selectedContent, imageContent(magicIcon, half, magicIconOpacity), imageContent(itemIcon, half) }
    -- Insert chargeText if present, otherwise itemCountText
    if not isEmptyTable(chargeText) then
        Debug.log("QuickSelect",
            "Inserting chargeText into UI content array: " .. tostring(chargeText.props and chargeText.props.text))
        table.insert(uiContent, chargeText)
    elseif not isEmptyTable(itemCountText) then
        table.insert(uiContent, itemCountText)
    end
    -- Add uses/condition as a second line for Lockpick, Probe, Repair
    if usesText then
        table.insert(uiContent, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = usesText,
                textSize = styles.itemCountTextSize,
                relativePosition = util.vector2(0.2, 0.44), -- slightly lower than the count
                anchor = util.vector2(0.2, 0.44),
                arrange = ui.ALIGNMENT.Start,
                align = ui.ALIGNMENT.Start,
                textShadow = TEXT_SHADOWS.enabled,
                textShadowColor = TEXT_SHADOWS.color,
                textColor = styles.textColor
            }
        })
    end
    -- Render the slot number as before
    if slotNumberContent and not isEmptyTable(slotNumberContent) then
        table.insert(uiContent, slotNumberContent)
    end
    Debug.log("QuickSelect",
        "Final UI content: " .. tostring(#uiContent) .. " elements, content: " .. tostring(uiContent))
    return ui.content(uiContent)
end
local function getSpellIcon(iconPath, half, selected, slotNumber, slotPrefix)
    local itemIcon = nil

    local selectionResource
    selectionResource = getTexture("textures/voshondsQuickSelect/selected.tga")

    local selectedContent = {}
    if selected then
        selectedContent = imageContent(selectionResource)
    end
    itemIcon = getTexture(iconPath)

    -- Format the slot number with the prefix if available
    local slotText = slotNumber
    if slotPrefix and slotPrefix ~= "" then
        -- Calculate the slot's position within its bar (1-10)
        local slotPosition = ((slotNumber - 1) % 10) + 1
        -- Display slot number with prefix
        slotText = slotPrefix .. slotPosition
    else
        -- For the first bar, just show the slot position (1-10)
        local slotPosition = ((slotNumber - 1) % 10) + 1
        slotText = slotPosition
    end

    -- Refresh text styles to ensure we have the latest settings
    refreshTextStyles()

    -- Create slot number content only if enabled
    local slotNumberContent = {}
    local styles = getTextStyles()

    if styles.showSlotNumbers and slotNumber then
        slotNumberContent = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = tostring(slotText),
                textSize = styles.slotNumberTextSize,
                relativePosition = util.vector2(0.85, 0.9),
                anchor = util.vector2(0.85, 0.9),
                arrange = ui.ALIGNMENT.End,
                align = ui.ALIGNMENT.End,
                textShadow = TEXT_SHADOWS.enabled,
                textShadowColor = TEXT_SHADOWS.color,
                textColor = TEXT_COLORS.slotNumber
            }
        }
    end

    local context = ui.content {
        imageContent(itemIcon, half),
        selectedContent,
        -- Add slot number to bottom right if we have it and it's enabled
        slotNumberContent
    }

    return context
end
local function getEmptyIcon(half, num, selected, useNumber, slotPrefix)
    local size = getIconSize()
    local selectionResource
    local drawFavoriteStar = true
    selectionResource = getTexture("textures/voshondsQuickSelect/selected.tga")

    local selectedContent = {}
    if selected then
        selectedContent = imageContent(selectionResource)
    end

    -- Format the slot number with the prefix if available
    local text = num
    if slotPrefix and slotPrefix ~= "" then
        -- Calculate the slot's position within its bar (1-10)
        local slotPosition = ((num - 1) % 10) + 1
        -- Display slot number with prefix
        text = slotPrefix .. slotPosition
    else
        -- For the first bar, just show the slot position (1-10)
        local slotPosition = ((num - 1) % 10) + 1
        text = slotPosition
    end

    -- Calculate proper size for the text, matching the icon size
    local textSize = 14 -- Smaller size for slot numbers
    if half then
        textSize = textSize / 1.5
    end

    -- Refresh text styles to ensure we have the latest settings
    refreshTextStyles()

    -- Only show number if slot numbers are enabled
    local styles = getTextStyles()
    if not styles.showSlotNumbers then
        return ui.content { selectedContent }
    end

    return ui.content {
        selectedContent,
        {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = tostring(text),
                textSize = styles.slotNumberTextSize,
                relativePosition = util.vector2(0.85, 0.9),
                anchor = util.vector2(0.85, 0.9),
                arrange = ui.ALIGNMENT.End,
                align = ui.ALIGNMENT.End,
                textShadow = TEXT_SHADOWS.enabled,
                textShadowColor = TEXT_SHADOWS.color,
                textColor = TEXT_COLORS.slotNumber
            },
            num = num,
            events = {
                --          mouseMove = async:callback(mouseMove),
            },
        }
    }
end

return {
    interfaceName = "Controller_Icon_QS",
    interface = {
        version = 1,
        getItemIcon = getItemIcon,
        getSpellIcon = getSpellIcon,
        getEmptyIcon = getEmptyIcon,
        refreshTextStyles = refreshTextStyles,        -- Export this so it can be called when settings change
        refreshEnchantedItems = refreshEnchantedItems -- Export the refresh function
    },
    eventHandlers = {
    },
    engineHandlers = {
        onInit = function()
            -- Initialize the timer system
            Debug.log("EnchantCharge", "Initializing enchantment charge tracking system")

            -- Start with a clean state
            activeEnchantedItems = {}
            enchantmentChargeCache = {}
            refreshTimerActive = false

            -- Start the refresh timer after a short delay to allow other systems to initialize
            async:newUnsavableSimulationTimer(1.0, function()
                startRefreshTimer()
            end)
        end,
        onFrame = function()
            -- Only refresh text styles once per second at most
            local currentTime = core.getGameTime()
            if not lastTextStyleRefreshTime or currentTime - lastTextStyleRefreshTime >= 1.0 then
                refreshTextStyles()
                lastTextStyleRefreshTime = currentTime
            end

            -- We no longer refresh enchanted items every frame
            -- Instead, we use a timer that runs every REFRESH_INTERVAL seconds
        end
    }
}
