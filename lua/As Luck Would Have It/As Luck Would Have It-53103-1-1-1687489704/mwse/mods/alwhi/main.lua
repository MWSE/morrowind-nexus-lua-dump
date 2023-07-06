-- Add new fortify luck spell
local fortifySpell

-- Add new drain luck spell
local drainSpell

local function dailyTimerCallback() 
    local newluck = math.random(100)
    local luckDiff = (tes3.mobilePlayer.luck.base - newluck) * -1
    local message

    if (luckDiff == 0) then
        message = "You feel neither lucky or unlucky today."
    else
        if (newluck <= 25) then
            message = "Today is not your day. You feel extrememly unlucky."
        end
        if (newluck > 25 and newluck <= 50) then
            message = "Your luck has been better, but it's also been worse."
        end
        if (newluck > 50 and newluck <= 75) then
            message = "You feel luckier than average."
        end
        if (newluck > 75) then
            message = "Luck is on your side. You're confident that today, things will go your way."
        end
    end

    tes3.removeSpell({
        reference = tes3.player,
        spell = fortifySpell
    })
    tes3.removeSpell({
        reference = tes3.player,
        spell = drainSpell
    })

    if (luckDiff > 0) then 
        fortifySpell.effects[1].min = luckDiff
        fortifySpell.effects[1].max = luckDiff

        tes3.addSpell({
            reference = tes3.player,
            spell = fortifySpell
        })
    elseif (luckDiff < 0) then
        luckDiff = luckDiff * -1
        drainSpell.effects[1].min = luckDiff
        drainSpell.effects[1].min = luckDiff

        tes3.addSpell({
            reference = tes3.player,
            spell = drainSpell
        })
    end

    tes3.messageBox({
        message = message,
        showInDialog = false
    })
end

local function charGenFinishedCallback(e)
    dailyTimerCallback()
    timer.start({
        type = timer.game,
        duration = 24,
        iterations = -1,
        callback = "alwhi:DailyTimer"
    })
end

local function initializedCallback()
    fortifySpell = tes3.createObject({
        objectType = tes3.objectType.spell,
        castType = tes3.spellType.ability,
        id = "dailyFortifyLuck",
        name = "Lucky",
        effects = {
            {
                attribute = tes3.attribute.luck,
                id = tes3.effect.fortifyAttribute,
                max = luckDiff,
                min = luckDiff,
                rangeType = tes3.effectRange.self,
            }
        }
    })

    drainSpell = tes3.createObject({
        objectType = tes3.objectType.spell,
        castType = tes3.spellType.ability,
        id = "dailyDrainLuck",
        name = "Unlucky",
        effects = {
            {
                attribute = tes3.attribute.luck,
                id = tes3.effect.drainAttribute,
                max = luckDiff,
                min = luckDiff,
                rangeType = tes3.effectRange.self,
            }
        }
    })
    timer.register("alwhi:DailyTimer", dailyTimerCallback)
end

event.register(tes3.event.charGenFinished, charGenFinishedCallback)
event.register(tes3.event.initialized, initializedCallback)