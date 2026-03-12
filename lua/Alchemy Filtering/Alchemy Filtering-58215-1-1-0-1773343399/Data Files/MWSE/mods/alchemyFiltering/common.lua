local log = mwse.Logger.new()
log.level = "DEBUG"

local common = {}

function common:getVisibleEffectsCount()
    local skill = tes3.mobilePlayer.alchemy.current
    local gmst = tes3.findGMST(tes3.gmst.fWortChanceValue)
    return math.clamp(math.floor(skill / gmst.value), 0, 4)
end

--- Split the string in two at the first instance of the delimiter
local function splitString(str, delimiter)
    local startIndex, endIndex = string.find(str, delimiter, 1, true)

    if startIndex then
        -- Extract the part before the delimiter (from 1 to start_index - 1)
        local part1 = string.sub(str, 1, startIndex - 1)
        -- Extract the part after the delimiter (from end_index + 1 to the end)
        local part2 = string.sub(str, endIndex + 1)
        return part1, part2
    else
        -- Delimiter not found
        return str, nil
    end
end

--- Get a set of effects which also have additional IDs,
--- such as Attributes or Skills
local function getCompoundEffects(effectType)
    local effects = {}
    for name, effect in pairs(tes3.effect) do
        if string.match(name, effectType) then
            effects[effect] = true
        end
    end
    return effects
end

local attributeEffects = getCompoundEffects("Attribute")
local skillEffects = getCompoundEffects("Skill")

local FullEffect = {}
FullEffect.__index = FullEffect
common.FullEffect = FullEffect

function FullEffect:new(effectId, attributeId, skillId)
    local effect = {}
    setmetatable(effect, self)
    effect.effectId = effectId
    effect.attributeId = attributeId
    effect.skillId = skillId
    effect.id = effectId

    effect.magicEffect = tes3.getMagicEffect(effectId)

    effect.name1, effect.name2 = splitString(effect.magicEffect.name, " ")
    if effect.name2 then
        if attributeEffects[effectId] then
            effect.name2 = tes3.attributeName[attributeId]
            effect.id = effect.id + attributeId * 1000000
        elseif skillEffects[effectId] then
            effect.name2 = tes3.skillName[skillId]
            effect.id = effect.id + skillId * 1000000
        end
        effect.name2 = effect.name2:gsub("^%l", string.upper)
        effect.name = effect.name1 .. " " .. effect.name2
    else
        effect.name = effect.magicEffect.name
    end
    return effect
end

function FullEffect:fromIngredient(ingredient, i)
    return FullEffect:new(ingredient.effects[i], ingredient.effectAttributeIds[i], ingredient.effectSkillIds[i])
end

function FullEffect.ingredientIter(ingredient, state)
    state.i = state.i + 1
    if state.i > state.visibleCount then
        return nil
    end
    if ingredient.effects[state.i] < 0 then
        return nil
    end

    return state, FullEffect:fromIngredient(ingredient, state.i)
end

function FullEffect:visibleEffects(ingredient)
    if ingredient then
        return FullEffect.ingredientIter, ingredient, {i = 0, visibleCount = common:getVisibleEffectsCount()}
    else
        return function() return nil end
    end
end

IconText = {}
IconText.__index = IconText
common.IconText = IconText

--- Create a new layout holding Icon and Text elements
---
--- The argument is a table holding various settings
--- * parent -  (required) the block in which the IconText will be created
--- * id - (optional) the registerd ID of the layout element
--- * isButton- (optional) if true, the text element is a Button, otherwise a borderless button
---     * mutually exclusive with isLabel
--- * isLabel - (optional) if true, the text element is a Label, otherwise a borderless button
---     * mutually exclusive with isButton
--- * paddingInner - (optional) the padding between the icon and text elements
--- * path - (optional) the path to the Icon
--- * text - (optional) the text of the text element
function IconText:create(args)
    if not args.parent then
        assert(nil, "IconText argument parent is required")
    end
    if args.isButton and args.isLabel then
        assert(nil, "IconText arguments isButton and isLabel are mutually exclusive")
    end
    local element = {}
    setmetatable(element, self)
    element.paddingInner = args.paddingInner or 6
    if args.isLabel then
        element.block = args.parent:createBlock{id = args.id}
        element.block.autoHeight = true
        element.block.autoWidth = true
        element.block.childAlignX = 0.5
        element.block.childAlignY = 0.5
        element.block.flowDirection = tes3.flowDirection.leftToRight
    else
        element.block = args.parent:createButton{id = args.id}
    end
    if not args.isButton then
        element.block.contentPath = nil
        element.block.paddingTop = nil
        element.block.paddingBottom = nil
        element.block.paddingLeft = nil
        element.block.paddingRight = nil
        element.block.paddingAllSides = 0
        element.block.borderAllSides = 0
    end

    element.icon = element.block:createImage()
    if args.isLabel then
        element.text = element.block:createLabel()
        element.widget = element.text.widget
    else
        element.text = element.block.children[1]
        element.widget = element.block.widget
        element.icon:reorder{before = element.text}
    end

    if args.isButton then
        element.text.borderTop = 2
        element.icon.borderTop = 4
        element.icon.borderBottom = 2
        element.icon.borderLeft = 4
    end

    element.text.borderLeft = element.paddingInner

    element:setPath(args.path)
    element:setText(args.text)
    return element
end

--- Sets the path to the Icon
---
--- If path is nil, then the Icon is hidden. The border will be updated
--- appropriately to maintain text alignment
function IconText:setPath(path)
    if path then
        self.icon.contentPath = "Icons\\" .. path
        self.icon.visible = true
        self.block.paddingLeft = 0
    else
        self.icon.visible = false
        self.block.paddingLeft = 16
    end
end

--- Sets the text to be displayed
---
--- Also sets the text of the block, which is not visible, but allows
--- for the block itself to be sorted based on the text value.
function IconText:setText(text)
    self.block.text = text
    self.text.text = text
end

function IconText:register(eventID, callback)
    self.block:register(eventID, callback)
end

function IconText:destroy()
    self.block:destroy()
end

function common:destroyAll(items)
    for _, item in pairs(items) do
        if item then
            item:destroy()
        end
    end
end

--- Print out all the children recursively to examine the arrangement of UI elements
function common:logTree(parent, indent)
    indent = indent or ""
    for _, c in ipairs(parent.children) do
        local t = c.text or "_"
        local p = c.contentPath or "_"
        local ty = c.type
        log:debug("" .. indent .. ty .. " " .. c.name .. " " .. c.id .. " " .. t .. " " .. p)

        for _, k in pairs({"name", "absolutePosAlignX", "absolutePosAlignY", "autoHeight", "autoWidth",
        "height", "width", "flowDirection", "minHeight", "minWidth", "maxHeight", "maxWidth",
        "ignoreLayoutX", "ignoreLayoutY", "heightProportional", "widthProportional",
        "positionX", "positionY",
        "childAlignX", "childAlignY", "childOffsetX", "childOffsetY", "paddingAllSides",
        "paddingBottom", "paddingLeft", "paddingRight", "paddingTop",
        "borderAllSides", "borderBottom", "borderLeft", "borderRight", "borderTop"}) do
            if c[k] then
                -- log:debug("  " .. indent .. "child[" .. k .. "] = " .. tostring(c[k]))
            end
        end

        self:logTree(c, indent .. "  ")
    end
end

return common
