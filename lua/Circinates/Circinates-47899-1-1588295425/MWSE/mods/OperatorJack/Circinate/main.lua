
----------------------------
local function getCircinateForSpell(spell)
    local cost = spell.magickaCost
    
    if (cost <= 25) then
        return 1
    elseif (cost <= 50) then
        return 2
    elseif (cost <= 80) then
        return 3
    elseif (cost <= 115) then
        return 4
    elseif (cost <= 150) then
        return 5
    elseif (cost <= 200) then
        return 6
    elseif (cost < 300) then
        return 7
    else
        return 8
    end
end

local circinates = {
    [1] = "First Circinate",
    [2] = "Second Circinate",
    [3] = "Third Circinate",
    [4] = "Fourth Circinate",
    [5] = "Fifth Circinate",
    [6] = "Sixth Circinate",
    [7] = "Seventh Circinate",
    [8] = "Arch-Circinate"
}
local function getCircinateTextForSpell(spell)
    local circinate = getCircinateForSpell(spell)
    return circinates[circinate]
end

local function onUiSpellTooltip(e)
    local circinate = getCircinateTextForSpell(e.spell)

    local outerBlock = e.tooltip:createBlock()
	outerBlock.flowDirection = "top_to_bottom"
    outerBlock.widthProportional = 1
    outerBlock.autoHeight = true
    outerBlock.borderAllSides = 4

    outerBlock:createDivider()

    local innerBlock = outerBlock:createBlock()
	innerBlock.flowDirection = "left_to_right"
    innerBlock.widthProportional = 1
    innerBlock.autoHeight = true
    innerBlock.borderAllSides = 0

        local tierLabel = innerBlock:createLabel({ text = circinate })
        tierLabel.borderAllSides = 4
end
event.register("uiSpellTooltip", onUiSpellTooltip)


local function initialized()
    print("[Circinates: INFO] Circinates Initialized")
end

event.register("initialized", initialized)