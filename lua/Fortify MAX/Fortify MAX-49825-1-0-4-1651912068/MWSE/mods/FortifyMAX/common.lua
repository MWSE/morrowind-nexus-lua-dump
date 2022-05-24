local modInfo = require("FortifyMAX.modInfo")
local config = require("FortifyMAX.config")
local interop = require("FortifyMAX.interop")
local this = {}

local statMenuId = tes3ui.registerID("MenuStat")
local hudMenuId = tes3ui.registerID("MenuMulti")

local barIds = {
    magicka = tes3ui.registerID("MenuStat_magic_fillbar"),
    fatigue = tes3ui.registerID("MenuStat_fatigue_fillbar"),
}

this.playerRace = nil
this.playerBirthsign = nil
this.raceSpells = {}
this.birthsignSpells = {}

function this.logMsg(component, message)
    if config.logging then
        mwse.log("[%s %s] [%s] %s", modInfo.mod, modInfo.version, component, message)
    end
end

local function setCurrentStat(stat, amount)
    tes3.setStatistic{
        reference = tes3.player,
        name = stat,
        current = amount,
    }
end

local function modMaxStat(stat, amount)
    tes3.modStatistic{
        reference = tes3.player,
        name = stat,
        base = amount,
    }
end

--[[ Cycles through all magic effects on the player and adds up the total magnitude of a particular effect with a source
that's a permanent ability, but only if the ability is not on the player's race or birthsign). This isn't ideal because
it can happen every frame under some circumstances. If anyone knows a better way to do this, please let me know. ]]--
local function getAbilityMag(effect)
    local mag = 0
    local activeEffect = tes3.mobilePlayer.activeMagicEffects

    for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
        local instance, source
        activeEffect = activeEffect.next

        if activeEffect.effectId ~= effect then
            goto continue
        end

        instance = activeEffect.instance

        if instance.sourceType ~= tes3.magicSourceType.spell then
            goto continue
        end

        source = instance.source

        if source.castType ~= tes3.spellType.ability then
            goto continue
        end

        if this.raceSpells:contains(source)
        or this.birthsignSpells:contains(source) then
            goto continue
        end

        mag = mag + activeEffect.magnitude

        ::continue::
    end

    return mag
end

function this.getEffectMag(effect)
    return tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = effect,
    }
end

-- Returns two effect magnitudes: the Fortify Magicka/Fatigue magnitude *not* caused by script-added abilities, and the
-- total magnitude.
function this.getEffectMagNoScriptAbl(effect)
    local totalEffectMag = this.getEffectMag(effect)
    local effectMag

    if totalEffectMag > 0
    and this.playerRace
    and this.playerBirthsign then
        local scriptAblEffectMag = getAbilityMag(effect)
        effectMag = totalEffectMag - scriptAblEffectMag
    else
        effectMag = totalEffectMag
    end

    return effectMag, totalEffectMag
end

function this.recordStat(stat)
    return tes3.mobilePlayer[stat].baseRaw, tes3.mobilePlayer[stat].currentRaw
end

-- Sometimes when max magicka/fatigue is changed the game won't actually update the display unless we force it to.
local function updateMenu(stat, menu)
    if menu then
        local statMax, statCurrent = this.recordStat(stat)

        local barId = barIds[stat]
        local bar = menu:findChild(barId)

        if bar then
            bar.widget.current = statCurrent
            bar.widget.max = statMax

            bar:updateLayout()
            menu:updateLayout()
        end
    end
end

local function updateDisplay(stat)
    local statMenu = tes3ui.findMenu(statMenuId)
    local hudMenu = tes3ui.findMenu(hudMenuId)

    updateMenu(stat, statMenu)
    updateMenu(stat, hudMenu)
end

local function safeGetRatio(numerator, denominator)
    if denominator == 0 then
        return 0
    else
        return numerator / denominator
    end
end

--[[ Called from onAtrChange, but only when there is a Fortify Magicka/Fatigue magnitude or there was one on the
previous frame, and only after any FM/FF magnitude has been tacked on to max magicka/fatigue. The purpose is to set
current magicka/fatigue to where it needs to be such that, once any FM/FF magnitude has expired, the ratio will be the
same as it would have been last frame had there been no FM/FF magnitude last frame. ]]--
local function maintainCorrectRatio(stat, newFort, oldFort, previousMaxStat, previousCurStat)
    local statCap = string.gsub(stat, "%l", string.upper, 1)
    local currentMaxStat, currentCurStat = this.recordStat(stat)

    local maxStatWouldBe = previousMaxStat - oldFort
    local curStatWouldBe = previousCurStat - oldFort
    local ratioWouldBe = safeGetRatio(curStatWouldBe, maxStatWouldBe)

    local maxStatWillBe = currentMaxStat - newFort
    local curStatAfterFortWearsOff = maxStatWillBe * ratioWouldBe
    local curStatRightNowShouldBe

    --[[ If any of the values calculated for what the current/max stat would/will be without Fortify Magicka/Fatigue are
    negative (or 0 in the case of the max stat), the results are really weird and very incorrect. (This can happen, for
    example, if the stat is damaged such that the current stat is less than the fortify magnitude.) In this case,
    nevermind, just maintain the existing ratio. ]]--
    if maxStatWouldBe > 0
    and curStatWouldBe >= 0
    and maxStatWillBe > 0 then
        curStatRightNowShouldBe = curStatAfterFortWearsOff + newFort
    else
        local ratioToMaintain = safeGetRatio(previousCurStat, previousMaxStat)
        curStatRightNowShouldBe = currentMaxStat * ratioToMaintain
    end

    this.logMsg(statCap, string.format("A relevant attribute has changed while there is (or was on the previous frame) a Fortify %s magnitude. Maintaining correct %s ratio.", statCap, stat))
    this.logMsg(statCap, string.format("Max %s is now (before correction): %f", stat, currentMaxStat))
    this.logMsg(statCap, string.format("Current %s is now (before correction): %f", stat, currentCurStat))
    this.logMsg(statCap, string.format("Old Fortify %s magnitude: %f", statCap, oldFort))
    this.logMsg(statCap, string.format("New Fortify %s magnitude: %f", statCap, newFort))
    this.logMsg(statCap, string.format("Max %s was last frame: %f", stat, previousMaxStat))
    this.logMsg(statCap, string.format("Current %s was last frame: %f", stat, previousCurStat))
    this.logMsg(statCap, string.format("Max %s would have been last frame without Fortify %s: %f", stat, statCap, maxStatWouldBe))
    this.logMsg(statCap, string.format("Current %s would have been last frame without Fortify %s: %f", stat, statCap, curStatWouldBe))
    this.logMsg(statCap, string.format("%s ratio would have been last frame without Fortify %s: %f", statCap, statCap, ratioWouldBe))
    this.logMsg(statCap, string.format("Max %s will be once Fortify %s wears off: %f", stat, statCap, maxStatWillBe))
    this.logMsg(statCap, string.format("Current %s needs to be once Fortify %s wears off: %f", stat, statCap, curStatAfterFortWearsOff))
    this.logMsg(statCap, string.format("Current %s needs to be to account for Fortify %s: %f", stat, statCap, curStatRightNowShouldBe))

    --[[ There's a problem that can happen when the following two things both happen in the same frame: (1) a relevant
    attribute changes while under a Fortify Magicka/Fatigue effect, and (2) there is a gain/loss of current magicka/
    fatigue due to some other cause, such as spellcasting or jumping. This mod knows what ratio to maintain based on the
    current/max magicka/fatigue on the previous frame, before the magicka/fatigue change from the other cause. If
    there's been some change in current magicka/fatigue, we need to compensate for that; otherwise, that change would
    basically be reverted (causing, for example, the player to be able to cast a spell for free). ]]--
    local diff = 0

    --[[ And there's another problem. We can only compensate for the above when the Fortify Magicka/Fatigue magnitude
    has not also changed this frame. If it has (in other words, add "(3) Fortify Magicka/Fatigue magnitude has changed"
    to the list above of things that all have to happen in the same frame for this to be a problem), we can't compensate
    for that because the outcome will be different depending on what order the game applies the attribute and FM/FF
    magnitude change in, and we don't know what that order is. This is why we check to make sure FM/FF magnitude hasn't
    changed here, to avoid unpredictable results.

    What this means is that, for example, in the unlikely event that the player casts a spell and, in the exact same
    frame that they lose current magicka due to the spellcast, their intelligence and FM magnitude both also change, the
    player will get the spell for free, with no magicka cost.

    Fortunately, the loss of magicka from casting a spell and the effects of that spell don't happen on the same frame,
    so it would be very difficult to intentionally exploit this - it would require extremely precise timing. However, it
    could still happen very rarely by accident. ]]--
    if newFort == oldFort then
        -- What the ratio actually was last frame. This is the same as what it *should* be right now, assuming no gain/
        -- loss of magicka/fatigue this frame.
        local ratioShouldBe = safeGetRatio(previousCurStat, previousMaxStat)

        -- What current magicka/fatigue should be right now if there were no gain/loss in the past frame. Note that
        -- maxStatWillBe is just present max magicka/fatigue minus FM/FF magnitude, which is what the game set max
        -- magicka/fatigue to before this mod tacked on the FM/FF magnitude earlier.
        local curStatShouldBe = maxStatWillBe * ratioShouldBe
        diff = currentCurStat - curStatShouldBe

        this.logMsg(statCap, string.format("There is a Fortify %s magnitude and it has not changed since the last frame. Compensating for any gain/loss of current %s in the past frame.", statCap, stat))
        this.logMsg(statCap, string.format("%s ratio was last frame: %f", statCap, ratioShouldBe))
        this.logMsg(statCap, string.format("Current %s is now (before correction): %f", stat, currentCurStat))
        this.logMsg(statCap, string.format("Current %s should be now (before correction) if there were no %s gain/loss in the past frame: %f", stat, stat, curStatShouldBe))
        this.logMsg(statCap, string.format("Difference: %f", diff))
    end

    -- Sometimes there will be an extremely small difference (something like 0.000002) when there shouldn't be. This
    -- check allows us to ignore those tiny differences.
    if math.abs(diff) > 0.01 then
        curStatRightNowShouldBe = curStatRightNowShouldBe + diff

        this.logMsg(statCap, string.format("There is a difference between what current %s is and what it should be, indicating %s gain/loss in the past frame.", stat, stat))
        this.logMsg(statCap, string.format("Current %s needs to be to account for this difference: %f", stat, curStatRightNowShouldBe))
    end

    setCurrentStat(stat, curStatRightNowShouldBe)
    updateDisplay(stat)
end

local function addFortToMaxOnAtrChange(stat, newFort, oldFort)
    local statCap = string.gsub(stat, "%l", string.upper, 1)
    local currentMaxStat, currentCurStat = this.recordStat(stat)
    local newMaxStat = currentMaxStat + newFort
    local normalizedStat = tes3.mobilePlayer[stat].normalized

    modMaxStat(stat, newFort)

    this.logMsg(statCap, string.format("Adding Fortify %s magnitude to max %s on relevant attribute change.", statCap, stat))
    this.logMsg(statCap, string.format("Old Fortify %s magnitude: %f", statCap, oldFort))
    this.logMsg(statCap, string.format("New Fortify %s magnitude: %f", statCap, newFort))
    this.logMsg(statCap, string.format("Old current %s: %f", stat, currentCurStat))
    this.logMsg(statCap, string.format("Old max %s: %f", stat, currentMaxStat))
    this.logMsg(statCap, string.format("%s ratio: %f", statCap, normalizedStat))
    this.logMsg(statCap, string.format("New max %s: %f", stat, newMaxStat))
end

-- When Fortify Magicka/Fatigue magnitude changes (and none of the relevant attributes also change at the same time),
-- the game does not recalculate magicka/fatigue, so we only have to tack on the magnitude difference here, instead of
-- the full magnitude as we do after an attribute change.
function this.onFortChange(stat, newFort, oldFort)
    local statCap = string.gsub(stat, "%l", string.upper, 1)
    local diff = newFort - oldFort
    local currentMaxStat = tes3.mobilePlayer[stat].baseRaw
    local newMaxStat = currentMaxStat + diff

    modMaxStat(stat, diff)
    updateDisplay(stat)

    this.logMsg(statCap, string.format("Fortify %s magnitude has changed.", statCap))
    this.logMsg(statCap, string.format("Old Fortify %s magnitude: %f", statCap, oldFort))
    this.logMsg(statCap, string.format("New Fortify %s magnitude: %f", statCap, newFort))
    this.logMsg(statCap, string.format("Difference: %f", diff))
    this.logMsg(statCap, string.format("Old max %s: %f", stat, currentMaxStat))
    this.logMsg(statCap, string.format("New max %s: %f", stat, newMaxStat))
end

-- Runs whenever a relevant attribute has changed, or another mod has set the relevant interop.recalc variable to true.
-- In the first case, the game has redone its vanilla magicka/fatigue calculations, and that needs to be fixed. In the
-- second case, the other mod has recalculated magicka/fatigue itself and it needs us to compensate for FM/FF.
function this.onAtrChange(stat, newFort, oldFort, previousMaxStat, previousCurStat)
    local statCap = string.gsub(stat, "%l", string.upper, 1)
    this.logMsg(statCap, string.format("interop.recalc.%s: %s", stat, interop.recalc[stat]))

    -- If there is currently a Fortify Magicka/Fatigue magnitude, we need to tack that on to max magicka/fatigue, then
    -- we need to correct for it in determining what ratio to maintain.
    if newFort > 0 then
        addFortToMaxOnAtrChange(stat, newFort, oldFort)
        maintainCorrectRatio(stat, newFort, oldFort, previousMaxStat, previousCurStat)

    -- There's not currently any FM/FF magnitude, but there was last frame. In this case we don't need to adjust max
    -- magicka/fatigue, but we do need to account for last frame's FM/FF magnitude in setting current magicka/fatigue,
    -- so the correct ratio is maintained.
    elseif oldFort > 0 then
        maintainCorrectRatio(stat, newFort, oldFort, previousMaxStat, previousCurStat)

    -- There's no FM/FF magnitude now or in the last frame, which means the game's (or other mod's) calculations are
    -- correct and we don't need to do anything except update the magicka/fatigue bars just in case.
    else
        updateDisplay(stat)
    end

    interop.recalc[stat] = false
end

-- Morrowind recalculates magicka/fatigue on game load, so we need to add back any FM/FF magnitude each time.
local function addFortToMaxOnLoad(stat, amount)
    local statCap = string.gsub(stat, "%l", string.upper, 1)
    local currentMaxStat, currentCurStat = this.recordStat(stat)
    local newMaxStat = currentMaxStat + amount
    local normalizedStat = tes3.mobilePlayer[stat].normalized

    modMaxStat(stat, amount)

    --[[ When the game recalculates magicka/fatigue on load, the FM/FF magnitude will be removed from max, and the game
    will adjust current magicka/fatigue to maintain the existing ratio. Now that we've added FM/FF magnitude back to
    max, we can use that ratio (which is correct) to set current magicka/fatigue back to what it was when the game was
    saved. ]]--
    local newCurStat = newMaxStat * normalizedStat

    setCurrentStat(stat, newCurStat)
    updateDisplay(stat)

    this.logMsg(statCap, string.format("Adding Fortify %s magnitude to max %s on game load.", statCap, stat))
    this.logMsg(statCap, string.format("Fortify %s magnitude: %f", statCap, amount))
    this.logMsg(statCap, string.format("Old current %s: %f", stat, currentCurStat))
    this.logMsg(statCap, string.format("Old max %s: %f", stat, currentMaxStat))
    this.logMsg(statCap, string.format("%s ratio: %f", statCap, normalizedStat))
    this.logMsg(statCap, string.format("New current %s: %f", stat, newCurStat))
    this.logMsg(statCap, string.format("New max %s: %f", stat, newMaxStat))
end

function this.onLoaded(stat, fort)
    local statCap = string.gsub(stat, "%l", string.upper, 1)
    this.logMsg(statCap, string.format("Game loaded. Current Fortify %s magnitude: %f", statCap, fort))

    if fort > 0 then
        addFortToMaxOnLoad(stat, fort)
    end
end

return this