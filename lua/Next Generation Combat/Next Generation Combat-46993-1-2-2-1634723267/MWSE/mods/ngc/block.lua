local this = {
    minBlockDefault = 10,
    maxBlockDefault = 50,
    currentlyActiveBlocking = false,
    drainFatigueTimer = nil,
    activeBlockFrame = nil,
}

local common = require("ngc.common")

function this.setMaxBlock()
    local blockMaxGMST = tes3.findGMST("iBlockMaxChance")
    local blockMinGMST = tes3.findGMST("iBlockMinChance")
    blockMaxGMST.value = 100
    blockMinGMST.value = 100
end

function this.resetMaxBlock()
    local blockMaxGMST = tes3.findGMST("iBlockMaxChance")
    local blockMinGMST = tes3.findGMST("iBlockMinChance")
    blockMaxGMST.value = this.maxBlockDefault
    blockMinGMST.value = this.minBlockDefault
end

function this.activeBlockingOff()
    if this.currentlyActiveBlocking then
        if common.config.showActiveBlockMessages then
            tes3.messageBox({ message = "Guard down!" })
        end
        this.currentlyActiveBlocking = false
        this.resetMaxBlock()
        if this.drainFatigueTimer then
            this.drainFatigueTimer:cancel()
            this.drainFatigueTimer = nil
        end
        if this.activeBlockFrame then
            this.activeBlockFrame.visible = false
        end
    end
end

-- Block events
function this.keyPressed(e)
    if (not common.config.toggleActiveBlockingMouse2 and
        not common.keybindTest(common.config.activeBlockKey, e)) then
        return
    end

    if common.config.toggleActiveBlockingMouse2 then
        if e.button ~= 1 then
            return
        end
    end

    if tes3.menuMode() then
        return
    end

    local player = tes3.mobilePlayer
    local readiedShield = player.readiedShield

    if readiedShield then
        if common.config.showActiveBlockMessages then
            tes3.messageBox({ message = "Guard up!" })
        end
        this.currentlyActiveBlocking = true
        if this.activeBlockFrame then
            this.activeBlockFrame.visible = true
        end

        local maxFatigue = tes3.mobilePlayer.fatigue.base
        local blockLevel = tes3.mobilePlayer.block.current
        local fatigueLossPerTick = maxFatigue * common.config.activeBlockingFatiguePercentBase
        if blockLevel >= common.config.weaponTier4.weaponSkillMin then
            fatigueLossPerTick = maxFatigue * common.config.weaponTier4.activeBlockingFatiguePercent
        elseif blockLevel >= common.config.weaponTier3.weaponSkillMin then
            fatigueLossPerTick = maxFatigue * common.config.weaponTier3.activeBlockingFatiguePercent
        elseif blockLevel >= common.config.weaponTier2.weaponSkillMin then
            fatigueLossPerTick = maxFatigue * common.config.weaponTier2.activeBlockingFatiguePercent
        elseif blockLevel >= common.config.weaponTier1.weaponSkillMin then
            fatigueLossPerTick = maxFatigue * common.config.weaponTier1.activeBlockingFatiguePercent
        end

        local fatigueMin = maxFatigue * common.config.activeBlockingFatigueMin
        local fatigueLossIterations = maxFatigue / fatigueLossPerTick
        if this.drainFatigueTimer and this.drainFatigueTimer.state ~= timer.expired then
            -- we shouldn't have a timer on guard up, so it hasn't been cancelled/cleared properly
            this.drainFatigueTimer:cancel()
            this.drainFatigueTimer = nil
        end
        -- we shouldn't have a timer
        this.drainFatigueTimer = timer.start({
            duration = 1,
            callback = function ()
                local currentFatigue = tes3.mobilePlayer.fatigue.current
                if currentFatigue < fatigueMin then
                    -- turn off blocking and timer
                    this.activeBlockingOff()
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
end

function this.keyReleased(e)
   this.activeBlockingOff()
end

function this.createBlockUI(e)
    local multiMenu = e.element

    -- Find the UI element that holds the sneak icon indicator.
    local bottomLeftBar = multiMenu:findChild(tes3ui.registerID("MenuMulti_sneak_icon")).parent

    -- Create an icon that matches the sneak icon's look.
    local blockFrame = bottomLeftBar:createThinBorder({})
    blockFrame.visible = false
    blockFrame.autoHeight = true
    blockFrame.autoWidth = true
    blockFrame.paddingAllSides = 2
    blockFrame.borderAllSides = 2
    blockFrame:createImage({ path = "icons/ngc/active_block.tga" })

    this.activeBlockFrame = blockFrame
    blockFrame:register("destroy", function()
        this.activeBlockFrame = nil
    end)
end

return this