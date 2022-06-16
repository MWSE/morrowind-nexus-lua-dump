local mod = "Accurate Thrown Weapon Tooltips"
local version = "1.0"

-- Thrown weapons always use chop for their attack type, despite this element having "thrust" in its ID.
local tooltipDamage = tes3ui.registerID("HelpMenu_thrust")

local function onTooltip(e)
    local object = e.object

    if object.objectType ~= tes3.objectType.weapon then
        return
    end

    if object.type ~= tes3.weaponType.marksmanThrown then
        return
    end

    local damageElement = e.tooltip:findChild(tooltipDamage)

    if not damageElement then
        return
    end

    local minDamage = 2 * object.chopMin
    local maxDamage = 2 * object.chopMax
    local newText = string.format("Attack: %d - %d", minDamage, maxDamage)

    if damageElement.text == newText then
        return
    end

    damageElement.text = newText
end

local function onInitialized()
    event.register("uiObjectTooltip", onTooltip)
    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)