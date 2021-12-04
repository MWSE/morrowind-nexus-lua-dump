local this = {
    playerCurrentlyFullDrawn = false,
    playerFullDrawTimer = nil,
    fullDrawDrainFatigueTimer = nil,
}

local common = require("ngc.common")

local function denockArrow()
    tes3.addItem({ reference = tes3.player, item = "chitin arrow", count = 1 })
    mwscript.equip({ reference = tes3.player, item = "chitin arrow" })
    tes3.removeItem({ reference = tes3.player, item = "chitin arrow", count = 1 })
end

local function cancelFullDraw()
    if this.fullDrawDrainFatigueTimer then
        this.fullDrawDrainFatigueTimer:cancel()
        this.fullDrawDrainFatigueTimer = nil
    end
end

local function doFullDraw(player)
    this.playerCurrentlyFullDrawn = true
    if player.isSneaking then
        mge.setZoom({ amount = common.config.bowZoomLevel })
    end
    if common.config.showMessages then
        tes3.messageBox({ message = "Full draw!" })
    end

    local maxFatigue = tes3.mobilePlayer.fatigue.base
    local fatigueLossPerTick = maxFatigue * common.config.fullDrawFatigueDrainPercent
    local fatigueMin = maxFatigue * common.config.fullDrawFatigueMin
    local fatigueLossIterations = maxFatigue / fatigueLossPerTick
    if this.fullDrawDrainFatigueTimer and this.fullDrawDrainFatigueTimer.state ~= timer.expired then
        -- we shouldn't have a timer on guard up, so it hasn't been cancelled/cleared properly
        this.fullDrawDrainFatigueTimer:cancel()
        this.fullDrawDrainFatigueTimer = nil
    end
    this.fullDrawDrainFatigueTimer = timer.start({
        duration = 1,
        callback = function ()
            local currentFatigue = tes3.mobilePlayer.fatigue.current
            if currentFatigue < fatigueMin then
                -- turn off blocking and timer
                this.playerCurrentlyFullDrawn = false
                cancelFullDraw()
                denockArrow()
            else
                if common.config.showDebugMessages then
                    tes3.messageBox({ message = "Fatigue drain: " .. fatigueLossPerTick })
                end
                tes3.mobilePlayer.fatigue.current = currentFatigue - fatigueLossPerTick
            end
        end,
        iterations = fatigueLossIterations * 10 -- lets give it enough iterations to make sure it will drain fatigue 10 times over
    })
end

function this.attackPressed(e)
    if tes3.menuMode() then
        return
    end

    local player = tes3.mobilePlayer
    local weapon = player.readiedWeapon

    if (weapon and weapon.object.type == 9 and player.actionData.attackSwing > 0) then
        -- only for bows during an attack
        if common.config.showDebugMessages then
            tes3.messageBox({ message = "Start full draw!" })
        end
        this.playerFullDrawTimer = timer.start({
            duration = 3,
            callback = function ()
                doFullDraw(player)
            end,
            iterations = 1
        })
    end
end

function this.attackReleased(e)
    cancelFullDraw()
    -- we delay this a bit so the attack event has time to track it
    timer.start({
        duration = 1,
        callback = function ()
            this.playerCurrentlyFullDrawn = false
        end,
        iterations = 1
    })
    mge.setZoom({ amount = 0 })
    if this.playerFullDrawTimer then
        this.playerFullDrawTimer:cancel()
        this.playerFullDrawTimer = nil
    end
end

function this.playerFullDrawBonus(weaponSkill)
    local bonusMultiplier

    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier4.bowFullDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier3.bowFullDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier2.bowFullDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier1.bowFullDrawMultiplier
    end

    return bonusMultiplier
end

function this.NPCFullDrawBonus(weaponSkill)
    local bonusMultiplier

    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier4.bowNPCDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier3.bowNPCDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier2.bowNPCDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier1.bowNPCDrawMultiplier
    end

    return bonusMultiplier
end

local function setTargetHamstring(source, target)
    if (common.config.showMessages and source == tes3.player) then
        tes3.messageBox({ message = "Hamstrung!" })
    end
    if (common.currentlyHamstrung[target.id] == nil) then
        common.currentlyHamstrung[target.id] = timer.start({
            duration = 3,
            callback = function ()
                common.currentlyHamstrung[target.id] = nil
            end,
            iterations = 1
        })
    elseif common.currentlyHamstrung[target.id].state == timer.expired then
        common.currentlyHamstrung[target.id] = timer.start({
            duration = 3,
            callback = function ()
                common.currentlyHamstrung[target.id] = nil
            end,
            iterations = 1
        })
    else
        common.currentlyHamstrung[target.id]:reset()
    end
end

function this.performHamstring(weaponSkill, source, target)
    local hamstringChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.hamstringChance >= hamstringChanceRoll then
            setTargetHamstring(source, target)
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.hamstringChance >= hamstringChanceRoll then
            setTargetHamstring(source, target)
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.hamstringChance >= hamstringChanceRoll then
            setTargetHamstring(source, target)
        end
    end
end

return this