local this = {}

this.modName = "More Choppin' Axes"
this.author = "Celediel"
this.version = "1.0.0"
-- this.configString = string.gsub(this.modName, "%s+", "") -- ! could be bad with '
this.configString = "MoreChoppinAxes"

this.fixTypesDescription =
    "Boost minimum: Set minimum chop damage to +1 minimum slash damage. If slash damage is much higher " ..
        "than chop damage, this won't effect the default attack. Use a different fix method in that case.\n" ..
        "Side effect: boosts minimum damage, so more damage potential overall.\n\n" ..
        "Boost maximum: Sets chop damage to equal slash damage, then reduce maximum slash damage by 1.\n" ..
        "Side effect: boosts maximum chop to match maximum slash, so if slash damage and chop damage " ..
        "differ greatly, then this wildly changes chop.\n\n" ..
        "Swap: Swaps slash damage with chop damage.\nSide effect: No effect if slash and chop damages are " ..
        "the same.\nTo remedy this, if they are the same, slash damage is reduced by one.\n" ..
        "Side effect of that: maximum slash damage is reduced by 1, so lower overall damage output.\n\n" ..
        "If \"Always Use Best Attack\" is on," ..
        " then the overall damage output isn't changed, and these side effects are pretty much moot anyway."
this.fixTypes = {boostMin = 0, boostMax = 1, swap = 2}
this.fixes = {
    [this.fixTypes.boostMin] = "boost minimum",
    [this.fixTypes.boostMax] = "boost maximum",
    [this.fixTypes.swap] = "swap"
}
this.modInfo =
    "Modifies axe damage values so that chop is used by default if \"Always Use Best Attack\" is on." ..
        "\n\nBecause axes should chop, right? (Especially when cutting wood in Ashfall)" ..
        "\n\nWhat each fix does:\n" .. this.fixTypesDescription

this.logLevelsDescription = [[None = no logging
Small = only log changes
Medium = log before and after changes
Large = log all axes found
]]
this.logLevels = {none = 0, small = 1, medium = 2, large = 3}

this.axes = {
    [tes3.weaponType.axeOneHand] = true,
    [tes3.weaponType.axeTwoHand] = true
}

function this.log(str) mwse.log("[%s] %s", this.modName, str) end

local function fixDamageValues(axe, fixType, logLevel)
    if (axe.thrustMin and axe.chopMin) and -- nil check
        (axe.chopMin < axe.thrustMin and axe.chopMax < axe.thrustMax) then
        -- ? this should never happen right ? why would an axe ever thrust ?
        if logLevel >= this.logLevels.small then
            this.log(string.format("Maybe %s isn't really an axe...", axe.name))
        end
    elseif (axe.slashMin and axe.chopMin) and -- nil check
        (axe.slashMin >= axe.chopMin and axe.chopMax <= axe.slashMax) then
        if logLevel == this.logLevels.medium then
            this.log(string.format(
                         "-> %s - slash: %s - %s, chop: %s - %s, thrust: %s - %s",
                         axe.name, axe.slashMin, axe.slashMax, axe.chopMin,
                         axe.chopMax, axe.thrustMin, axe.thrustMax))
        end

        -- ! this is where the fixing begins ! --
        if fixType == this.fixTypes.boostMin then
            axe.chopMin = axe.slashMin + 1
        elseif fixType == this.fixTypes.boostMax then
            axe.chopMin = axe.slashMin
            axe.chopMax = axe.slashMax
            axe.slashMax = axe.slashMax - 1
        elseif fixType == this.fixTypes.swap then
            local tempMax = axe.chopMax
            local tempMin = axe.chopMin
            axe.chopMax = axe.slashMax
            axe.chopMin = axe.slashMin
            axe.slashMax = tempMax
            axe.slashMin = tempMin

            -- if they're the same, then slash will get picked
            if axe.slashMax == axe.chopMax then
                axe.slashMax = axe.slashMax - 1
            end
        end

        if logLevel >= this.logLevels.small then
            this.log(string.format(
                         "<- %s - slash: %s - %s, chop: %s - %s, thrust: %s - %s",
                         axe.name, axe.slashMin, axe.slashMax, axe.chopMin,
                         axe.chopMax, axe.thrustMin, axe.thrustMax))
        end
    end
end

function this.applyFixes(fixType, logLevel)
    for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
        -- only axes
        if this.axes[weapon.type] then
            if logLevel == this.logLevels.large then
                this.log(string.format(
                             "-> %s - slash: %s - %s, chop: %s - %s, thrust: %s - %s",
                             weapon.name, weapon.slashMin, weapon.slashMax,
                             weapon.chopMin, weapon.chopMax, weapon.thrustMin,
                             weapon.thrustMax))
            end
            fixDamageValues(weapon, fixType, logLevel)
        end
    end
end

return this
