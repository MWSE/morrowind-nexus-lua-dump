-- labelRenderer_native.lua: Native Morrowind-style label rendering
-- Matches the exact appearance of vanilla tooltips and hover text

local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')

local M = {}

-- Helper for creating colors
local col = util.color.rgb

-- Morrowind's native tooltip style constants
local NATIVE_STYLE = {
    -- Background color: dark blue-gray (matches MW tooltips)
    backgroundColor = col(0.075, 0.09, 0.11, 0.95),  -- Nearly opaque
    
    -- Border color: lighter blue-gray 
    borderColor = col(0.15, 0.18, 0.22, 1.0),
    borderSize = 1,
    
    -- Text color: yellowish white (MW's signature text)
    textColor = col(0.87, 0.87, 0.76, 1.0),
    
    -- Padding matches vanilla tooltips
    padding = {
        horizontal = 8,
        vertical = 4
    },
    
    -- Font: Magic Cards (default MW font)
    -- Text size follows UI scaling
    baseTextSize = 16  -- Will be scaled by UI settings
}

-- Get user's UI scaling factor
function M.getUIScale()
    -- This would ideally read from OpenMW settings
    -- For now, return 1.0
    return 1.0
end

-- Create a native Morrowind-style label
function M.createNativeLabel(text, options)
    options = options or {}
    
    local scale = M.getUIScale()
    local textSize = NATIVE_STYLE.baseTextSize * scale
    
    -- Apply distance-based sizing if requested
    if options.distanceScale then
        textSize = textSize * options.distanceScale
    end
    
    -- Debug logging
    local logger = require('scripts.TwentyTwentyObjects.util.logger')
    logger.debug(string.format('Creating label: text="%s", pos=%s, alpha=%s', 
        text, tostring(options.position), tostring(options.alpha)))
    
    -- Create the tooltip-style container
    local labelLayout = {
        layer = 'HUD',
        type = ui.TYPE.Container,
        props = {
            -- Positioning
            anchor = util.vector2(0.5, 0.5),  -- Center-center anchor
            position = options.position or util.vector2(0, 0),
            
            -- Native tooltip appearance
            backgroundColor = NATIVE_STYLE.backgroundColor,
            borderColor = NATIVE_STYLE.borderColor, 
            borderSize = NATIVE_STYLE.borderSize,
            
            -- Padding
            padding = {
                horizontal = NATIVE_STYLE.padding.horizontal,
                vertical = NATIVE_STYLE.padding.vertical
            },
            
            -- Visibility - start visible for debugging
            visible = true,  -- Always visible for now
            alpha = options.alpha or 1.0
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = text,
                    textSize = textSize,
                    textColor = NATIVE_STYLE.textColor,
                    -- Use the same font as Morrowind tooltips
                    font = "Magic_Cards_Regular"  -- If available
                }
            }
        })
    }
    
    local element = ui.create(labelLayout)
    logger.debug(string.format('Label created: %s', tostring(element)))
    return element
end

-- Create label with connecting line to object
function M.createLabelWithLine(text, screenPos, objectPos, options)
    options = options or {}
    
    -- Create main label
    local label = M.createNativeLabel(text, options)
    
    -- Create line connecting label to object
    -- Line starts from bottom-center of label (where anchor is)
    local line = ui.create({
        layer = 'HUD',
        type = ui.TYPE.Container,
        props = {
            -- Line is drawn as a thin stretched box
            backgroundColor = col(0.5, 0.5, 0.5, 0.3),  -- Semi-transparent gray
            
            -- Position at object point
            position = objectPos,
            
            -- Size and rotation to connect points
            size = util.vector2(1, 0),  -- Will be calculated
            
            visible = options.showLine ~= false
        }
    })
    
    -- Calculate line geometry
    local delta = screenPos - objectPos
    local length = delta:length()
    local angle = math.atan2(delta.y, delta.x)
    
    -- Update line properties
    line.layout.props.size = util.vector2(length, 1)  -- 1 pixel thick
    line.layout.props.rotation = angle
    
    -- Group label and line together
    return {
        label = label,
        line = line,
        update = function(self, newScreenPos, newObjectPos)
            -- Update positions
            self.label.layout.props.position = newScreenPos
            
            -- Recalculate line
            local newDelta = newScreenPos - newObjectPos
            local newLength = newDelta:length()
            local newAngle = math.atan2(newDelta.y, newDelta.x)
            
            self.line.layout.props.position = newObjectPos
            self.line.layout.props.size = util.vector2(newLength, 1)
            self.line.layout.props.rotation = newAngle
            
            self.label:update()
            self.line:update()
        end,
        destroy = function(self)
            self.label:destroy()
            self.line:destroy()
        end
    }
end

-- Match exact Morrowind tooltip behavior for special cases
function M.formatItemLabel(item)
    local text = item.name
    
    -- Add count for stacked items (e.g., "Gold (127)")
    if item.count and item.count > 1 then
        text = string.format("%s (%d)", text, item.count)
    end
    
    -- Add ownership indicator if stolen
    if item.isStolen then
        text = text .. " (Stolen)"
    end
    
    -- Match MW's enchanted item coloring (future feature)
    -- if item.isEnchanted then
    --     -- Would need different text color
    -- end
    
    return text
end

-- Create multi-line label for grouped items (MW style)
function M.createGroupLabel(items, position, options)
    -- Build multi-line text like MW containers
    local lines = {}
    
    -- Group by type and show counts
    local typeGroups = {}
    for _, item in ipairs(items) do
        local typeName = item.type or "Items"
        if not typeGroups[typeName] then
            typeGroups[typeName] = {count = 0, examples = {}}
        end
        typeGroups[typeName].count = typeGroups[typeName].count + 1
        if #typeGroups[typeName].examples < 3 then
            table.insert(typeGroups[typeName].examples, item.name)
        end
    end
    
    -- Format like Morrowind container tooltips
    for typeName, group in pairs(typeGroups) do
        if group.count > 3 then
            -- "Weapons (7)"
            table.insert(lines, string.format("%s (%d)", typeName, group.count))
        else
            -- List individual items
            for _, name in ipairs(group.examples) do
                table.insert(lines, name)
            end
        end
    end
    
    local text = table.concat(lines, "\n")
    return M.createNativeLabel(text, options)
end

-- Create health bar in MW style (for NPCs/Creatures)
function M.addHealthBar(labelElement, healthPercent)
    -- Morrowind uses a simple red bar
    local healthBar = ui.create({
        type = ui.TYPE.Container,
        props = {
            -- Dark background
            backgroundColor = col(0.1, 0.0, 0.0, 0.8),
            size = util.vector2(60, 4),
            position = util.vector2(0, labelElement.layout.size.y + 2),
            
            -- Border like MW
            borderColor = NATIVE_STYLE.borderColor,
            borderSize = 1
        },
        content = ui.content({
            {
                type = ui.TYPE.Container,
                props = {
                    -- Red health fill
                    backgroundColor = col(0.8, 0.1, 0.1, 1.0),
                    size = util.vector2(58 * healthPercent, 2),
                    position = util.vector2(1, 1)
                }
            }
        })
    })
    
    return healthBar
end

-- Preload native style (called once on init)
function M.init()
    -- Cache any native UI resources if needed
    -- This ensures consistent performance
end

return M