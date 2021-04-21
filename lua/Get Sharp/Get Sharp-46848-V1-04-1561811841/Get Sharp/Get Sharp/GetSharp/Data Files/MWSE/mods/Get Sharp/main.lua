--[[
    Get Sharp
    By Greatness7 & RubberMan
--]]

-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20190529) then
    event.register("initialized", function()
        tes3.messageBox(
            "[Get Sharp] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end)
    return
end


local activatorData = {
    ["RM_GrindWheel"] = {sound="grinder", onlyEdged=true},
    ["RM_Quench"] = {sound='hothiss', onlyBlunt=true},
}


-------------
-- UTILITY --
-------------
local function getSuccessChance(mobile)
    local a = mobile.armorer.current
    local s = mobile.strength.current
    local l = mobile.luck.current
    return 0.1 * (s + l) + a
end

local function isBluntWeapon(object)
    return (object.type >= 3) and (object.type <= 5)
end

local function getModifiedDamageColor(multiplier)
    if multiplier >= 1.0 then
        return tes3ui.getPalette("positive_color")
    else
        return tes3ui.getPalette("negative_color")
    end
end

local function getModifiedDamageText(text, multiplier)
    local min = multiplier * text:match("%d+")
    local max = multiplier * text:match("%d+$")
    return text:gsub("%d+", "%%d"):format(min, max)
end


------------
-- EVENTS --
------------
local function onActivate(e)
    if not activatorData[e.target.id] then
        return
    elseif e.activator ~= tes3.player then
        return
    end

    local weapon = tes3.mobilePlayer.readiedWeapon
    if not (weapon and weapon.object.isMelee) then
        tes3.messageBox("You must have a melee weapon equipped to use this.")
        return false
    end

    local condition = weapon.itemData.condition
    local maxCondition = weapon.object.maxCondition
    if condition < maxCondition then
        tes3.messageBox("Your weapon must be fully repaired to use this.")
       return false
    end

    local ratio = condition / (maxCondition * 1.25)
    if ratio >= 1.0 then
        tes3.messageBox("Your weapon cannot be improved any further")
        return false
    end

    local data = activatorData[e.target.id]
    if data.onlyBlunt and not isBluntWeapon(weapon.object) then
        tes3.messageBox("You must have a blunt weapon equipped to use this.")
        return false
    elseif data.onlyEdged and isBluntWeapon(weapon.object) then
        tes3.messageBox("You must have an edged weapon equipped to use this.")
        return false
    end

    local chance = getSuccessChance(tes3.mobilePlayer)
    if chance < math.random(100) then
        weapon.itemData.condition = maxCondition * 0.50
        timer.start{type=timer.frame, duration=2, callback=function()
            tes3.messageBox("You failed to improve %s.", weapon.object.name)
            tes3.playSound{sound="repair fail"}
        end}
    else
        weapon.itemData.condition = maxCondition * 1.25
        timer.start{type=timer.frame, duration=2, callback=function()
            tes3.messageBox("You successfully improved %s.", weapon.object.name)
            tes3.playSound{sound="repair"}
        end}
    end

    tes3.playSound{sound=data.sound}
end

local function onTooltipDrawn(e)
    if e.object.objectType ~= tes3.objectType.weapon then
        return
    end

    local itemData = e.itemData or (e.reference and e.reference.itemData)
    if not (itemData and itemData.condition) then
        return
    end

    local multiplier = itemData.condition / e.object.maxCondition
    if multiplier == 1.0 then
        return
    end

    local name = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if name and (multiplier > 1.0) then
        name.text = name.text .. (isBluntWeapon(e.object) and " (Tempered)" or " (Sharpened)")
    end

    local chop = e.tooltip:findChild(tes3ui.registerID("HelpMenu_chop"))
    if chop then
        chop.text = getModifiedDamageText(chop.text, multiplier)
        chop.color = getModifiedDamageColor(multiplier)
    end

    local slash = e.tooltip:findChild(tes3ui.registerID("HelpMenu_slash"))
    if slash then
        slash.text = getModifiedDamageText(slash.text, multiplier)
        slash.color = getModifiedDamageColor(multiplier)
    end

    local thrust = e.tooltip:findChild(tes3ui.registerID("HelpMenu_thrust"))
    if thrust then
        thrust.text = getModifiedDamageText(thrust.text, multiplier)
        thrust.color = getModifiedDamageColor(multiplier)
    end
end

event.register("initialized", function()
    if tes3.isModActive("GetSharp.esp") then
        mwse.log("[Get Sharp] Initialized Version 1.0")
        event.register("activate", onActivate, {priority = 400})
        event.register("uiObjectTooltip", onTooltipDrawn, {priority = 400})
    end
end)
