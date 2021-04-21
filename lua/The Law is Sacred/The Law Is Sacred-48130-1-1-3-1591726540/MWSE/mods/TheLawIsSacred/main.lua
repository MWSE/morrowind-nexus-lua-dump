--[[
    The Law Is Sacred
         v1.1.3
       by JaceyS
]]--
local config = require("TheLawIsSacred.config")
local jailing = false
local function onInfoGetText(e)
    if(e.info.id == config.resistArrestDialogueID) then
        tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + tonumber(config.resistArrestPenalty)
        if (config.messages == true and tonumber(config.resistArrestPenalty) > 0) then
            tes3.messageBox("Resisting arrest has added " .. config.resistArrestPenalty .. " to your bounty.")
        end
    end
end

local function blockSave()
    if (jailing  == true) then
        tes3.messageBox "You can't save right now -- you are being arrested!"
        return false
    end
end

local function jail(perspective)
    if (config.animateKO == true) then
        tes3.mobilePlayer.controlsDisabled = false
        tes3.playAnimation({
            reference = tes3.mobilePlayer,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.immediate
        })
        if (perspective == false) then
            timer.delayOneFrame(function() tes3.force1stPerson() end)
        end
    end
    tes3.fadeIn({duration = 0.5})
    if (tes3.isModActive(config.goToJailModTitle) or tes3.isModActive(config.goToJailModTitleNOM)) then
        if (tes3.mobilePlayer.bounty < config.goToJailModThreshold) then
            mwscript.addTopic({topic = config.goToJailModTopic})
            mwscript.startScript({script = "gtj_main_script"})
        else
            tes3.setGlobal("gtj_global_mine", tes3.mobilePlayer.bounty)
            tes3.mobilePlayer.bounty = 0
            mwscript.startScript({script = "gtj_gotomine_script"})
        end
    else
        tes3.runLegacyScript({command = "GoToJail"})
    end
    jailing = false
end

local function confirm(perspective)
    if (config.confirm == true) then
        tes3.messageBox({
            message = "Do you want to go to jail, or to die?",
            buttons = { "Jail", "Die" },
            callback = function(e)
                if (e.button == 1) then
                    tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
                    jailing = false
                    return
                else
                    jail(perspective)
                end
            end
        })
    else
        jail(perspective)
    end
end

local function endAnimate(perspective)
    tes3.fadeOut({duration = 0.5})
    timer.start({duration = 0.5, callback = function ()
        confirm(perspective)
    end})
end

local function animateKO()
    if (config.animateKO == true) then
        local perspective = tes3.is3rdPerson()
        tes3.force3rdPerson()
        tes3.playAnimation({
            reference = tes3.mobilePlayer,
            group = tes3.animationGroup.knockOut,
            startFlag = tes3.animationStartFlag.immediate
        })
        timer.start({duration = 3, callback = function()
            endAnimate(perspective)
        end})
    else
        tes3.fadeOut({duration = 0.5})
        timer.start({duration = 0.5, callback = confirm})
    end
end

local function onDamage(e)
    if(e.mobile == tes3.mobilePlayer) then
        if(e.attackerReference and e.attackerReference.object.isGuard) then
            if(tes3.mobilePlayer.bounty <= 0) then
                e.damage = 0
                e.attacker:stopCombat(true)
                e.attacker.fight = 30
                return
            end
            if(config.deathWarrant == true and tes3.mobilePlayer.bounty >= tonumber(config.deathWarrantValue)) then
                return
            end
            if(tes3.isAffectedBy({reference = tes3.player, effect = tes3.effect.vampirism})) then
                return
            end
            if(e.mobile.werewolf == true or e.mobile.knownWerewolf.value == 1) then
                return
            end
            local difficulty = tes3.getWorldController().difficulty
            local difficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value
            local difficultyFactor
            if(difficulty > 0) then
                difficultyFactor = 1 + difficultyMult * difficulty
            else
                difficultyFactor = 1 + difficulty / difficultyMult
            end -- If damage is from an attack, apply the difficulty modifier before checking to see if it would kill the player.
            if(e.source == "attack" and (tes3.mobilePlayer.health.current - math.abs(e.damage) * difficultyFactor) <= 1.1) then
                tes3.mobilePlayer.health.current = 1.1 + math.abs(e.damage) * difficultyFactor
                e.claim = true
                if (jailing == false) then
                    jailing = true
                    animateKO()
                end
            elseif (tes3.mobilePlayer.health.current - math.abs(e.damage) <= 1.1) then
                tes3.setStatistic({reference = tes3.mobilePlayer, name = "health", current = tes3.mobilePlayer.health.current + math.abs(e.damage)})
                e.claim = true
                if (jailing == false) then
                    jailing = true
                    animateKO()
                end
            end
        end
    elseif (e.mobile and e.mobile.reference and e.mobile.reference.object.isGuard and e.attackerReference and e.attackerReference == tes3.player) then
        local difficulty = tes3.getWorldController().difficulty
        local difficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value
        local difficultyFactor
        if(difficulty > 0) then
            difficultyFactor = 1 + -1 * difficulty / difficultyMult
        else
            difficultyFactor = 1 + difficultyMult * -1 * difficulty
        end
        if(e.source == "attack" and (e.mobile.health.current - math.abs(e.damage) * difficultyFactor) <= 1) then
            if (config.messages == true and tonumber(config.guardKillPenalty) > 0) then
                tes3.triggerCrime({type = tes3.crimeType.killing, value = tonumber(config.guardKillPenalty), victim = e.mobile})
            end
        elseif (e.mobile.health.current - math.abs(e.damage) <= 1) then
            if (config.messages == true and tonumber(config.guardKillPenalty) > 0) then
                tes3.triggerCrime({type = tes3.crimeType.killing, value = tonumber(config.guardKillPenalty), victim = e.mobile})
            end
        end
    end
end

local function resetVariables()
    jailing = false
    tes3.fadeIn({duration = 0.01})
end

local function onInitialized()
    event.register("damage", onDamage, {priority = -50})
    event.register("infoGetText", onInfoGetText)
    event.register("save", blockSave)
    event.register("loaded", resetVariables)
    --event.register("combatStart", onCombatStart)
    print("[The Law Is Sacred: INFO] The Law Is Sacred Initialized")
end
event.register("initialized", onInitialized)

event.register("modConfigReady", function()
	require("TheLawIsSacred.mcm")
end)