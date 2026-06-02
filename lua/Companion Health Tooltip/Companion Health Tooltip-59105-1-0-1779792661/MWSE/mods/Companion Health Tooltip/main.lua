local logPrefix = "[Companion Health Tooltip] "

local GUI_ID_CompanionHealthBlock = tes3ui.registerID("CHT_CompanionHealthBlock")
local GUI_ID_CompanionHealthBar = tes3ui.registerID("CHT_CompanionHealthBar")

local function isPlayerFriendlyActor(actor)
    if tes3.mobilePlayer == nil or tes3.mobilePlayer.friendlyActors == nil then
        return false
    end

    for friendlyActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if friendlyActor == actor then
            return true
        end
    end

    return false
end

local function isDeadOrDying(actor)
    if actor == nil or actor.health == nil then
        return true
    end

    if actor.health.current <= 0 then
        return true
    end

    if actor.actionData ~= nil then
        local animState = actor.actionData.animationAttackState
        if animState == tes3.animationState.dying or animState == tes3.animationState.dead then
            return true
        end
    end

    return false
end

local function isValidFocusedCompanion(actor)
    if actor == nil then
        return false
    end

    -- The player should not count as their own companion.
    if actor == tes3.mobilePlayer then
        return false
    end

    if not isPlayerFriendlyActor(actor) then
        return false
    end

    if isDeadOrDying(actor) then
        return false
    end

    return true
end

local function addCompanionHealthBar(tooltip, actor)
    local content = tooltip:getContentElement()
    if content == nil then
        return
    end

    -- Destroy normal tooltip and rebuild from scratch
    while #content.children > 0 do
        content.children[1]:destroy()
    end

    local reference = actor.reference
    local name = reference.object.name

    local title = content:createLabel({ text = name })
    title.autoWidth = true
    title.autoHeight = true
    title.borderLeft = 4
    title.borderRight = 4
    title.borderTop = 3
    title.borderBottom = 2

    local maxHealth = actor.health.base
    local currentHealth = actor.health.current

    local block = content:createBlock({ id = GUI_ID_CompanionHealthBlock })
    block.autoWidth = true
    block.autoHeight = true
    block.widthProportional = 1.0
    block.minWidth = 160
    block.maxWidth = 240
    block.paddingLeft = 4
    block.paddingRight = 4
    block.paddingTop = 1
    block.paddingBottom = 4

    local bar = block:createFillBar({
        id = GUI_ID_CompanionHealthBar,
        current = currentHealth,
        max = maxHealth,
    })

    bar.widthProportional = 1.0
    bar.minHeight = 12
    bar.widget.fillColor = { 0.906, 0.302, 0.235 }
end

--- Adds a health bar to the currently focused companion's in-world tooltip.
--- @param e uiObjectTooltipEventData
local function onObjectTooltip(e)
    -- Inventory item tooltips have no reference. We only want in-world tooltips.
    if e.reference == nil or e.reference.mobile == nil then
        return
    end

    local actor = e.reference.mobile

    if not isValidFocusedCompanion(actor) then
        return
    end

    addCompanionHealthBar(e.tooltip, actor)
    e.tooltip:updateLayout()
end

event.register(tes3.event.uiObjectTooltip, onObjectTooltip)

mwse.log("%sInitialized.", logPrefix)
