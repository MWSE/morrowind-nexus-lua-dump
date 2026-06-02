local disabledIndicators = {}
local replacementTextures = {}
local overrideTextures = {}
local overrideColors = {}
local overrideScales = {}
local interop = {}

-- Make enum table and make sure it's not editable
local function readOnly (t)
    return setmetatable(t, {
        __newindex = function()
            error("No modification possible. List is readonly", 2)
        end,
        __metatable = false
    })
end

---@class IndicatorEnum
---@field DefaultIndicator 0
---@field OwnershipIndicator 1
---@field SneakIndicator 2
---@field EssentialNPCIndicator 3
---@field QuestgiverIndicator 4
---@field QuestItemIndicator 5

---@type IndicatorEnum
interop.indicatorEnum = readOnly({
    DefaultIndicator = 0, -- The ordinary crosshair
    OwnershipIndicator = 1, -- equivalent to ownershipTarget
    SneakIndicator = 2, -- equivalent to sneakTarget
    EssentialNPCIndicator = 3, -- equivalent to npcTarget
    QuestgiverIndicator = 4, -- equivalent to sideTarget
    QuestItemIndicator = 5, -- equivalent to itemTarget
})

---@class TextureEnum
---@field DefaultTexture 0 
---@field HiddenTexture 1 
---@field DetectedTexture 2  

---@type TextureEnum
interop.textureEnum = readOnly({
    DefaultTexture = 0, -- The ordinary crosshair
    HiddenTexture = 1, -- equivalent to ownershipTarget
    DetectedTexture = 2, -- equivalent to sneakTarget
})

---@class ScaleTypeEnum
---@field DefaultIndicatorScale 0 -- Scale of the ordinary indicator
---@field SneakIndicatorScale 1 -- Scale of the sneak indicator

---@type ScaleTypeEnum
interop.scaleTypeEnum = readOnly({
    DefaultIndicatorScale = 0, -- The ordinary crosshair
    SneakIndicatorScale = 1, -- equivalent to ownershipTarget
})

--- Registers information that is later used in Essential Indicators. More than one mod can add rules, and the indicator behavior will be disabeled, and / or the indicator invisible as long as there is at least one mod that registers that behavior.
---@param indicator integer Enum using interop.indicatorEnum for all available indicator states in Essential Indicators
---@param disabled boolean If the indicator behavior should be disabled or not. Disabled = true -> Color changes, and sprite changes will not trigger from Essential Indicator
---@param invisible boolean If the indicator should be visible or not. Invisible = true -> Crosshair will be hidden while in this state
---@param id string Your chosen name to identify the source mod disabling the indicator. Use the same name all the time when disabling and enabling indicators using interop, and other sources will work along side your mods interactions.
function interop.registerDisabledIndicator (indicator, disabled, invisible, id)
    disabledIndicators[indicator] = disabledIndicators[indicator] or {}
    disabledIndicators[indicator][id] = disabledIndicators[indicator][id] or {}

    disabledIndicators[indicator][id].disabled = disabled
    disabledIndicators[indicator][id].invisible = invisible
end

--- Helper function to check if the behavior of an indicator should be disabled.
---@param indicator integer Enum using interop.indicatorEnum for all available indicators in Essential Indicators
function interop.isIndicatorDisabled (indicator)
    local sources = disabledIndicators[indicator]
    if not sources then return false end
    for _, entry in pairs(sources) do
        if entry.disabled == true then
            return true
        end
    end
    return false
end

--- Helper function to check if an indicator should be invisible during a specific state.
---@param indicator integer Enum using interop.indicatorEnum for all available indicators in Essential Indicators
function interop.isIndicatorInvisible (indicator)
    local sources = disabledIndicators[indicator]
    if not sources then return false end
    for _, entry in pairs(sources) do
        if entry.invisible == true then
            return true
        end
    end
    return false
end

--- Debug feature. If your indicator is not showing for some reason, you can use this function to find all sources acting on the indicators.
---@param indicator integer Enum using interop.indicatorEnum for all available indicators in Essential Indicators
function interop.getDisabledSources(indicator)
    return disabledIndicators[indicator]
end

---Register a texture to a list of replacements. The crosshair is rebuilt when this function is called, meaning you can update the texture during gameplay and get a change directly.
---@param texture integer Enum using interop.textureEnum for the differnt types of textures you can override.
---@param path string File path to the texture you want to override the mods one
---@param id string Your chosen name to identify the registered texture. By using the same name again, you can deregister an override texture using deregisterReplacementTexture().
---@param priority integer If several mods try to override with textures at the same time, only the one with the highest priority will be shown. Larger number means higher priority.
function interop.registerReplacementTexture(texture, path, id, priority)
    replacementTextures[texture] = replacementTextures[texture] or {}
    replacementTextures[texture][id] = replacementTextures[texture][id] or {}

    replacementTextures[texture][id].path = path
    replacementTextures[texture][id].priority = priority

    interop.recreateCrosshair()
end

--- Helper function to fetch an override texture if there is one
---@param texture integer Enum using interop.textureEnum for all available textures in Essential Indicators
function interop.getReplacementTexture(texture)
    local sources = replacementTextures[texture]
    if not sources then return false end

    local highestPrio = -math.huge
    local prioritizedTexturePath = nil
    for _, entry in pairs(sources) do
        if entry.priority > highestPrio then
            highestPrio = entry.priority
            prioritizedTexturePath = entry.path
        end
    end
    return prioritizedTexturePath
end

---Remove a replacement texture. Use the same ID you used to register the texture to make sure it is removed.
---@param texture integer Enum using interop.textureEnum for the differnt types of textures that can be overridden. Chose the one you want to unregister.
---@param id string Your chosen name to identify the registered texture. Use the same name as you registered the texture with using registerReplacementTexture().
function interop.deregisterReplacementTexture(texture, id)
    if replacementTextures[texture] then
        replacementTextures[texture][id] = nil
    end
    interop.recreateCrosshair()
end

---Register a texture to a list of overrides. If there are any registered override textures, the cursor will immediately change texture to the one registred with the highest priority.
---@param path string File path to the texture you want to override the mods one
---@param id string Your chosen name to identify the registered texture. By using the same name again, you can deregister an override texture using deregisterOverrideTexture().
---@param priority integer If several mods try to override with textures at the same time, only the one with the highest priority will be shown. Larger number means higher priority.
function interop.registerOverrideTexture(path, id, priority)
    overrideTextures[id] = overrideTextures[id] or {}
    overrideTextures[id].path = path
    overrideTextures[id].priority = priority

    interop.recreateCrosshair()
end

--- Helper function to fetch an override texture if there is one
function interop.getOverrideTexture()
    local sources = overrideTextures
    if not sources then return false end

    local highestPrio = -math.huge
    local prioritizedTexturePath = nil
    for _, entry in pairs(sources) do
        if entry.priority > highestPrio then
            highestPrio = entry.priority
            prioritizedTexturePath = entry.path
        end
    end
    return prioritizedTexturePath
end

---Remove an override texture. Use the same ID you used to register the texture to make sure it is removed.
---@param id string Your chosen name to identify the registered texture. Use the same name as you registered the texture with using registerOverrideTexture().
function interop.deregisterOverrideTexture(id)
    overrideTextures[id]  = nil
    interop.recreateCrosshair()
end

function interop.recreateCrosshair() end

---Register a color to a list of overrides. The color is set directly, meaning you can update the color during gameplay and get a change directly. You can use this to create new indicator scenarios, separate from what's covered in this mod already.
---@param r number Red, value between 0.00 - 1.00 
---@param g number Green, value between 0.00 - 1.00 
---@param b number Blue, value between 0.00 - 1.00 
---@param a number Alpha, value between 0.00 - 1.00. Default is 1.
---@param id string Your chosen name to identify the registered color. By using the same name again, you can deregister an override color using deregisterColorOverride().
---@param priority integer If several mods try to override the color at the same time, only the one with the highest priority will be shown. Larger number means higher priority.
function interop.registerColorOverride(r, g, b, a, id, priority)
    overrideColors[id] = overrideColors[id] or {}
    overrideColors[id].color =
    {
        r = r,
        g = g,
        b = b,
        a = a,
    }
    overrideColors[id].priority = priority
end

---Remove an override color. Use the same ID you used to register the color to make sure it is removed.
---@param id string Your chosen name to identify the registered color. Use the same name as you registered the color with using registerColorOverride().
function interop.deregisterColorOverride(id)
    overrideColors[id] = nil
end

--- Helper function to fetch an override color if there is one. Gets the highest priority registered color.
function interop.getOverrideColor()
    local sources = overrideColors
    if not sources then return false end

    local highestPrio = -math.huge
    local prioritizedColor = nil
    for _, entry in pairs(sources) do
        if entry.priority > highestPrio then
            highestPrio = entry.priority
            prioritizedColor = entry.color
        end
    end
    return prioritizedColor
end

---Register a scale to a list of overrides. The scale is set directly, meaning you can update the scale during gameplay and get a change directly.
---@param type integer Enum using interop.scaleTypeEnum for scaling the different types of indicators
---@param scale number 100 means 100%. Should be a positive value.
---@param id string Your chosen name to identify the registered scale. By using the same name again, you can deregister an override scale using deregisterScaleOverride().
---@param priority integer If several mods try to override the scale at the same time, only the one with the highest priority will be shown. Larger number means higher priority.
function interop.registerScaleOverride(type, scale, id, priority)
    overrideScales[type] = overrideScales[type] or {}
    overrideScales[type][id] = overrideScales[type][id] or {}

    overrideScales[type][id].scale = scale
    overrideScales[type][id].priority = priority

    interop.recreateCrosshair()
end

---Remove an override scale. Use the same ID you used to register the scale to make sure it is removed.
---@param type integer Enum using interop.scaleTypeEnum for scaling the different types of indicators
---@param id string Your chosen name to identify the registered scale. Use the same name as you registered the scale with using registerScaleOverride().
function interop.deregisterScaleOverride(type, id)
    overrideScales[type][id] = nil
    
    interop.recreateCrosshair()
end

--- Helper function to fetch an override scale if there is one. Gets the highest priority registered scale. Override textures use the default type override scale.
---@param type integer Enum using interop.scaleTypeEnum
function interop.getOverrideScale(type)
    local sources = overrideScales[type]
    if not sources then return false end

    local highestPrio = -math.huge
    local prioritizedScale = nil
    for _, entry in pairs(sources) do
        if entry.priority > highestPrio then
            highestPrio = entry.priority
            prioritizedScale = entry.scale
        end
    end
    return prioritizedScale
end

return interop