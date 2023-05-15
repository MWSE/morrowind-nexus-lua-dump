--Initialize--
local config = require("aquaticAscendancy.config")
local logger = require("logging.logger")

local log = logger.new {
    name = "Aquatic Ascendancy",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized()
    log:info("Initialized.")
end

event.register("initialized", initialized)





--Update Player Values-----------------------------------------------------------------------------------
local function updatePlayer()
    local breathing = tes3.isAffectedBy({ reference = tes3.player, effect = 0 })
    local swift = tes3.isAffectedBy({ reference = tes3.player, effect = 1 })
    local breathFlag = false
    local swiftFlag = false


    if config.onlyArgonians == true then
        if tes3.player.object.race.id == "Argonian" then
            log:debug("" .. tes3.player.object.name .. " is an Argonian.")
            breathFlag = true
            swiftFlag = true
        else
            log:debug("" .. tes3.player.object.name .. " is not an Argonian.")
            breathFlag = false
            swiftFlag = false
        end
    else
        log:debug("" .. tes3.player.object.name .. " does not need to be an Argonian.")
        breathFlag = true
        swiftFlag = true
    end

    if config.affectVampires == true then
        local affected = tes3.isAffectedBy({ reference = tes3.player, effect = 133 })
        if affected then
            log:debug("" .. tes3.player.object.name .. " is a Vampire.")
            breathFlag = true
        end
    end


    if (config.waterBreathing == true and breathFlag == true) then
        tes3.mobilePlayer.waterBreathing = 1
        log:debug("" .. tes3.player.object.name .. " was given Water Breathing.")
    else
        if not breathing then
            tes3.mobilePlayer.waterBreathing = 0
            log:debug("" .. tes3.player.object.name .. "'s Water Breathing set to 0.")
        end
    end

    if (config.swiftSwim == true and swiftFlag == true) then
        if not swift then
            tes3.mobilePlayer.swiftSwim = config.swimValue
            log:debug("" .. tes3.player.object.name .. " was given Swift Swim. Total: " .. tes3.mobilePlayer.swiftSwim .. "")
        else
            local effectiveMagnitude = tes3.getEffectMagnitude({reference = tes3.player, effect = tes3.effect.swiftSwim })
            log:debug(string.format("Effective Swift Swim: %f", effectiveMagnitude))

            tes3.mobilePlayer.swiftSwim = config.swimValue + effectiveMagnitude
            log:debug("" .. tes3.player.object.name .. " was given Swift Swim. Total: " .. tes3.mobilePlayer.swiftSwim .. ", Effective: " .. effectiveMagnitude .. "")
        end
    else
        if not swift then
            tes3.mobilePlayer.swiftSwim = 0
            log:debug("" .. tes3.player.object.name .. "'s Swift Swim set to 0.")
        else
            local effectiveMagnitude = tes3.getEffectMagnitude({reference = tes3.player, effect = tes3.effect.swiftSwim })
            log:debug(string.format("Effective Swift Swim: %f", effectiveMagnitude))

            tes3.mobilePlayer.swiftSwim = effectiveMagnitude
            log:debug("" .. tes3.player.object.name .. " Swift Swim bonus removed. Total: " .. tes3.mobilePlayer.swiftSwim .. ", Effective: " .. effectiveMagnitude .. "")
        end
    end
end


--Char Gen
local function newBreath()
    log:trace("Player check on " .. tes3.player.object.name .. ". (CharGenFinished)")
    updatePlayer()
end
event.register("charGenFinished", newBreath)


--On Load
local function oldBreath()
    log:trace("Player check on " .. tes3.player.object.name .. ". (Game Loaded)")
    updatePlayer()
end
event.register("loaded", oldBreath)


--Aquatic Resting
local function restKey(e)
    if config.restUnderwater == false then return end
    if (not e.result) then
        return
    end
    log:trace("Aquatic rest check on " .. tes3.player.object.name .. ".")
    local restable = tes3.canRest()
    local restFlag = false


    if not restable then
        if config.onlyArgonians == true then
            if tes3.player.object.race.id == "Argonian" then
                restFlag = true
            else
                restFlag = false
            end
        else
            restFlag = true
        end

        if config.affectVampires == true then
            local affected = tes3.isAffectedBy({ reference = tes3.player, effect = 133 })
            if affected then
                restFlag = true
            end
        end


        if restFlag == true then
            local gmst = tes3.findGMST(tes3.gmst.sNotifyMessage1).value

            tes3.findGMST(tes3.gmst.sNotifyMessage1).value = ""

            if tes3.mobilePlayer.isFalling == false and tes3.mobilePlayer.isJumping == false and tes3.mobilePlayer.isFlying == false then
                tes3.showRestMenu({ checkForSolidGround = false, showMessage = false })
                timer.delayOneFrame(function() tes3.findGMST(tes3.gmst.sNotifyMessage1).value = gmst end)
            else
                tes3.findGMST(tes3.gmst.sNotifyMessage1).value = gmst
            end
        end
    end
end
event.register(tes3.event.keybindTested, restKey, { filter = tes3.keybind.rest })


--Water Ambush Spawns
local function restInterrupt(e)
    if config.restUnderwater == false then return end

    local restable = tes3.canRest()

    if not restable then
        local newCreature

        repeat
            newCreature = tes3.getObject("h2o_all_lev+0"):pickFrom()
        until(newCreature ~= nil)

        e.creature = newCreature

        log:debug("Aquatic ambush! " .. newCreature.name .. " chosen.")
    end


end
event.register(tes3.event.restInterrupt, restInterrupt)


--Update NPC
local function updateNPC(e)
    if config.npcBenefits == false then return end
	if e.reference.object.objectType ~= tes3.objectType.npc then return end
    log:trace("NPC check on " .. e.reference.object.name .. ". (Activated)")

    local breathing = tes3.isAffectedBy({ reference = e.reference, effect = 0 })
    local swift = tes3.isAffectedBy({ reference = e.reference, effect = 1 })
    local breathFlag = false
    local swiftFlag = false


    if config.onlyArgonians == true then
        if e.reference.object.race.id == "Argonian" then
            log:debug("" .. e.reference.object.name .. " is an Argonian.")
            breathFlag = true
            swiftFlag = true
        else
            log:debug("" .. e.reference.object.name .. " is not an Argonian.")
            breathFlag = false
            swiftFlag = false
        end
    else
        log:debug("" .. e.reference.object.name .. " does not need to be an Argonian.")
        breathFlag = true
        swiftFlag = true
    end

    if config.affectVampires == true then
        local affected = tes3.isAffectedBy({ reference = e.reference, effect = 133 })
        if affected then
            log:debug("" .. e.reference.object.name .. " is a Vampire.")
            breathFlag = true
        end
    end


    if (config.waterBreathing == true and breathFlag == true) then
        e.reference.mobile.waterBreathing = 1
        log:debug("" .. e.reference.object.name .. " was given Water Breathing.")
    else
        if not breathing then
            e.reference.mobile.waterBreathing = 0
            log:debug("" .. e.reference.object.name .. "'s Water Breathing set to 0.")
        end
    end

    if (config.swiftSwim == true and swiftFlag == true) then
        if not swift then
            e.reference.mobile.swiftSwim = config.swimValue
            log:debug("" .. e.reference.object.name .. " was given Swift Swim. Total: " .. e.reference.mobile.swiftSwim .. "")
        else
            local effectiveMagnitude = tes3.getEffectMagnitude({reference = e.reference, effect = tes3.effect.swiftSwim })
            log:debug(string.format("Effective Swift Swim: %f", effectiveMagnitude))

            e.reference.mobile.swiftSwim = config.swimValue + effectiveMagnitude
            log:debug("" .. e.reference.object.name .. " was given Swift Swim. Total: " .. e.reference.mobile.swiftSwim .. ", Effective: " .. effectiveMagnitude .. "")
        end
    else
        if not swift then
            e.reference.mobile.swiftSwim = 0
            log:debug("" .. e.reference.object.name .. "'s Swift Swim set to 0.")
        else
            local effectiveMagnitude = tes3.getEffectMagnitude({reference = e.reference, effect = tes3.effect.swiftSwim })
            log:debug(string.format("Effective Swift Swim: %f", effectiveMagnitude))

            e.reference.mobile.swiftSwim = effectiveMagnitude
            log:debug("" .. e.reference.object.name .. " Swift Swim bonus removed. Total: " .. e.reference.mobile.swiftSwim .. ", Effective: " .. effectiveMagnitude .. "")
        end
    end
end
event.register("mobileActivated", updateNPC)


local function cellChanged(e)
    log:trace("Player check on " .. tes3.player.object.name .. ". (Cell Changed)")
    updatePlayer()

    --Puzzle Canal Pilgrimage Fix
    if e.cell.id == "Vivec, Puzzle Canal, Center" then
        tes3.mobilePlayer.waterBreathing = 0
        tes3.messageBox("A mysterious force seems to draw the breath from you...")
    end
end
event.register(tes3.event.cellChanged, cellChanged)





--Config Stuff--
event.register("modConfigReady", function()
    require("aquaticAscendancy.mcm")
    config = require("aquaticAscendancy.config")
end)