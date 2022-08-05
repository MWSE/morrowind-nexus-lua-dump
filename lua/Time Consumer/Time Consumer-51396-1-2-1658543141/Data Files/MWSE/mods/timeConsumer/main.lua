--Initialize--
local function initialized(e)
    print ("[Time Consumer]: Initialized.")
end
event.register ("initialized", initialized)

local config = require("timeConsumer.config")

local logger = require("logging.logger")
local log = logger.new{
    name = "Time Consumer",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)


local initialTrigger = false
local initialSTrigger = false
local spellFlag = 1
local repairFlag = 1
local repairNPCflag = 1
local repairTrigger = 1





--Enchanting--

local function enchantSuccessAttempt(e)
    if e.enchanter ~= tes3.mobilePlayer then return end
    if config.advanceTimeEnchantSuccess == true then
        local baseEsuccess = (config.enchantSuccess_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local enchantOffset = (tes3.mobilePlayer.enchant.current / 250)
        local enchantTime = (baseEsuccess * (1 - enchantOffset))
        if enchantTime < 0.02 then
            enchantTime = 0.02
        end
        gameHour = (gameHour + enchantTime)
        tes3.setGlobal('GameHour', gameHour)
        log:info("Enchantment Success. Enchant skill: " .. tes3.mobilePlayer.enchant.current .. ". Time Reduction: %" .. (enchantOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
	end
end
event.register (tes3.event.enchantedItemCreated, enchantSuccessAttempt)

local function enchantFailAttempt(e)
    if e.enchanter ~= tes3.mobilePlayer then return end
    if config.advanceTimeEnchantFail == true then
        local baseEfail = (config.enchantFail_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local enchantOffset = (tes3.mobilePlayer.enchant.current / 250)
        local enchantTime = (baseEfail * (1 - enchantOffset))
        if enchantTime < 0.02 then
            enchantTime = 0.02
        end
        gameHour = (gameHour + enchantTime)
        tes3.setGlobal('GameHour', gameHour)
        log:info("Enchantment Failed. Enchant skill: " .. tes3.mobilePlayer.enchant.current .. ". Time Reduction: %" .. (enchantOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end
event.register (tes3.event.enchantedItemCreateFailed, enchantFailAttempt)

local function enchantByNPC(e)
    if e.enchanter == tes3.mobilePlayer then return end
    local npcRef = e.enchanterReference
    if config.advanceTimeNPCenchant == true then
        local baseNPCenchant = (config.enchantNPC_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local enchantOffset = (npcRef.mobile.enchant.current / 250)
        local enchantTime = (baseNPCenchant * (1 - enchantOffset))
        if enchantTime < 0.02 then
            enchantTime = 0.02
        end
        gameHour = (gameHour + enchantTime)
        tes3.setGlobal('GameHour', gameHour)
        if config.restMode == true then
            local fatigue = tes3.player.mobile.fatigue.current
            local fatigueMax = tes3.player.mobile.fatigue.base
            local percentRest = (math.round(((fatigueMax * 0.01) * (enchantTime * 100)), 0))
            local fatigueFinal = (fatigue + percentRest)
            if fatigueFinal > fatigueMax then
                fatigueFinal = fatigueMax
            end
            tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
            log:debug("Resting while NPC enchants. " .. percentRest .. " fatigue restored.")
        end
        if config.trainSkill == true then
            local enchant = tes3.player.mobile.enchant.base
            if enchant < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(9, 1)
                    tes3.messageBox("You observed " .. npcRef.object.name .. " at work, and learned a bit about Enchanting.")
                end
            end
        end
        log:info("Enchantment services rendered by " .. npcRef.object.name .. ". Enchant skill: " .. npcRef.mobile.enchant.current .. ". Time Reduction: %" .. (enchantOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end
event.register (tes3.event.enchantedItemCreated, enchantByNPC)

local function enchantRecharge(e)
    if e.skill ~= tes3.skill.enchant then return end
    if config.advanceTimeRecharge ~= true then return end
    local baseRecharge = (config.recharge_Modifier * 0.1)
    local gameHour = tes3.getGlobal('GameHour')
    local enchantOffset = (tes3.mobilePlayer.enchant.current / 150)
    local rechargeTime = (baseRecharge * (1 - enchantOffset))
    if rechargeTime < 0.02 then
        rechargeTime = 0.02
    end
    gameHour = (gameHour + rechargeTime)
    tes3.setGlobal('GameHour', gameHour)
    log:info("Enchantment recharged. Enchant skill: " .. tes3.mobilePlayer.enchant.current .. ". Time Reduction: %" .. (enchantOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
end



--Repairs--

local function repairAttemptReal(e)
    if repairFlag == 0 then return end
    if repairTrigger == 0 then return end
    if config.advanceTimeRepairAttempt ~= true then return end
    local baseRattempt = (config.repairAttempt_Modifier * 0.1)
    local gameHour = tes3.getGlobal('GameHour')
    local armorerOffset = (tes3.mobilePlayer.armorer.current / 125)
    local repairTime = (baseRattempt * (1 - armorerOffset))
    if repairTime < 0.02 then
        repairTime = 0.02
    end
    gameHour = (gameHour + repairTime)
    tes3.setGlobal('GameHour', gameHour)
    log:info("Repair Attempted. Armorer skill: " .. tes3.mobilePlayer.armorer.current .. ". Time Reduction: %" .. (armorerOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
end

local function repairAttemptBridge(e)
    if config.advanceTimeRepairAttempt == true then
        repairFlag=1
        if event.isRegistered(tes3.event.uiActivated, repairAttemptReal) then return end
        event.register (tes3.event.uiActivated, repairAttemptReal)
    end
end

local function repairAttempt(e)
    local closeRButton=e.element:findChild(tes3ui.registerID("MenuRepair_Okbutton"))
        closeRButton:registerAfter("mouseDown", function()
            event.unregister (tes3.event.exerciseSkill, enchantRecharge)
           repairFlag=0
           repairTrigger=1
        end)
    if config.advanceTimeRepairAttempt == true then
        timer.start({duration = 1, callback = repairAttemptBridge, type = timer.real })
    end
    if event.isRegistered(tes3.event.exerciseSkill, enchantRecharge) then return end
    event.register(tes3.event.exerciseSkill, enchantRecharge)
end
event.register(tes3.event.uiActivated, repairAttempt, {filter="MenuRepair"})

local function menuMessage(e)
    repairTrigger = 0
end
event.register(tes3.event.uiActivated, menuMessage, {filter="MenuMessage"})

local function repairEnable(e)
    repairTrigger = 1
    if event.isRegistered(tes3.event.exerciseSkill, enchantRecharge) then
        event.unregister(tes3.event.exerciseSkill, enchantRecharge)
    end
end
event.register(tes3.event.menuExit, repairEnable)

---------------------------------------------------------------------------------------------------------------

local function haltTrigger(e)
    initialTrigger = false
end

local function repairByNPCreal(e)
    if repairNPCflag == 0 then return end
    if config.advanceTimeNPCrepair == true then
        if not initialTrigger then
            initialTrigger = true
            local baseNPCrepair = (config.repairNPC_Modifier * 0.1)
            local gameHour = tes3.getGlobal('GameHour')
            gameHour = gameHour + baseNPCrepair
            tes3.setGlobal('GameHour', gameHour)
            if config.restMode == true then
                local fatigue = tes3.player.mobile.fatigue.current
                local fatigueMax = tes3.player.mobile.fatigue.base
                local percentRest = (math.round(((fatigueMax * 0.01) * (baseNPCrepair * 100)), 0))
                local fatigueFinal = (fatigue + percentRest)
                if fatigueFinal > fatigueMax then
                    fatigueFinal = fatigueMax
                end
                tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
                log:debug("Resting while NPC repairs gear. " .. percentRest .. " fatigue restored.")
            end
            if config.trainSkill == true then
                local armorer = tes3.player.mobile.armorer.base
                if armorer < 25 then
                    local chance = math.random(1, 100)
                    if chance <= 10 then
                        tes3.player.mobile:exerciseSkill(1, 1)
                        tes3.messageBox("You watch how the smith tends to your gear, and learn a bit about being an Armorer.")
                    end
                end
            end
            timer.delayOneFrame(haltTrigger, timer.real)
            log:info("Repair services rendered. Time passed to " .. math.round(gameHour, 2) .. ".")
        end
    end
end

local function repairByNPCbridge(e)
    repairNPCflag = 1
    if event.isRegistered (tes3.event.uiActivated, repairByNPCreal, {filter="MenuServiceRepair"}) then return end
    if config.advanceTimeNPCrepair == true then
        event.register (tes3.event.uiActivated, repairByNPCreal, {filter="MenuServiceRepair"})
    end
end

local function repairByNPC(e)
    local closeButton=e.element:findChild(tes3ui.registerID("MenuServiceRepair_Okbutton"))
        closeButton:registerAfter("mouseDown", function()
           repairNPCflag=0
        end)
    if config.advanceTimeNPCrepair == true then
        timer.start({duration = 1, callback = repairByNPCbridge, type = timer.real })
    end
end
event.register (tes3.event.uiActivated, repairByNPC, {filter="MenuServiceRepair"})



--Alchemy--

local function potionSuccessAttempt(e)
    if config.advanceTimePotionSuccess == true then
        local baseAsuccess = (config.potionSuccess_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local alchemyOffset = (tes3.mobilePlayer.alchemy.current / 150)
        local alchemyTime = (baseAsuccess * (1 - alchemyOffset))
        if alchemyTime < 0.02 then
            alchemyTime = 0.02
        end
        gameHour = (gameHour + alchemyTime)
        tes3.setGlobal('GameHour', gameHour)
        log:info("Alchemy Succeeded. Alchemy skill: " .. tes3.mobilePlayer.alchemy.current .. ". Time Reduction: %" .. (alchemyOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end
event.register (tes3.event.potionBrewed, potionSuccessAttempt)

local function potionFailAttempt(e)
    if config.advanceTimePotionFail == true then
        local baseAfail = (config.potionFail_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local alchemyOffset = (tes3.mobilePlayer.alchemy.current / 150)
        local alchemyTime = (baseAfail * (1 - alchemyOffset))
        if alchemyTime < 0.02 then
            alchemyTime = 0.02
        end
        gameHour = (gameHour + alchemyTime)
        tes3.setGlobal('GameHour', gameHour)
        log:info("Alchemy Failed. Alchemy skill: " .. tes3.mobilePlayer.alchemy.current .. ". Time Reduction: %" .. (alchemyOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end
event.register (tes3.event.potionBrewFailed, potionFailAttempt)



--Spellmaking--

local function npcSpellmaker(e)
    if config.advanceTimeNPCspellmaker ~= true then return end
    if e.source ~= tes3.spellSource.service then return end
    local npcSpellMake = (config.npcSpellTime_Modifier * 0.1)
    local intelligenceOffset = (tes3.mobilePlayer.intelligence.current / 400)
    local gameHour = tes3.getGlobal('GameHour')
    local spellmakeTime = (npcSpellMake * (1 - intelligenceOffset))
    if spellmakeTime < 0.02 then
        spellmakeTime = 0.02
    end
    gameHour = (gameHour + spellmakeTime)
    tes3.setGlobal('GameHour', gameHour)
    if config.restMode == true then
        local fatigue = tes3.player.mobile.fatigue.current
        local fatigueMax = tes3.player.mobile.fatigue.base
        local percentRest = (math.round(((fatigueMax * 0.01) * (spellmakeTime * 100)), 0))
        local fatigueFinal = (fatigue + percentRest)
        if fatigueFinal > fatigueMax then
            fatigueFinal = fatigueMax
        end
        tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
        log:debug("Resting while NPC creates spell. " .. percentRest .. " fatigue restored.")
    end
    if config.trainSkill == true then
        local spell = e.spell
        local spEffect = spell.effects
        --Mysticism Spell Created--
        if (spEffect[1].id == 85 or spEffect[1].id == 86 or spEffect[1].id == 87 or spEffect[1].id == 88 or spEffect[1].id == 89 or spEffect[1].id == 63 or spEffect[1].id == 64 or spEffect[1].id == 65 or spEffect[1].id == 66 or spEffect[1].id == 57 or spEffect[1].id == 62 or spEffect[1].id == 60 or spEffect[1].id == 61 or spEffect[1].id == 68 or spEffect[1].id == 58 or spEffect[1].id == 67 or spEffect[1].id == 59) then
            local mysticism = tes3.player.mobile.mysticism.base
            if mysticism < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(14, 1)
                    tes3.messageBox("You watch as the spellmaker enacts their ritual. It seemed to give you some small insight into Mysticism.")
                end
            end
        end
        --Destruction Spell Created--
        if (spEffect[1].id == 22 or spEffect[1].id == 23 or spEffect[1].id == 24 or spEffect[1].id == 25 or spEffect[1].id == 26 or spEffect[1].id == 38 or spEffect[1].id == 37 or spEffect[1].id == 17 or spEffect[1].id == 20 or spEffect[1].id == 18 or spEffect[1].id == 19 or spEffect[1].id == 21 or spEffect[1].id == 14 or spEffect[1].id == 16 or spEffect[1].id == 27 or spEffect[1].id == 15 or spEffect[1].id == 33 or spEffect[1].id == 32 or spEffect[1].id == 34 or spEffect[1].id == 28 or spEffect[1].id == 29 or spEffect[1].id == 30 or spEffect[1].id == 31 or spEffect[1].id == 35 or spEffect[1].id == 36) then
            local destruction = tes3.player.mobile.destruction.base
            if destruction < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(10, 1)
                    tes3.messageBox("You watch as the spellmaker gives form to ruinous energies. It taught you something about how Destruction works.")
                end
            end
        end
        --Alteration Spell Created--
        if (spEffect[1].id == 7 or spEffect[1].id == 8 or spEffect[1].id == 4 or spEffect[1].id == 6 or spEffect[1].id == 9 or spEffect[1].id == 10 or spEffect[1].id == 5 or spEffect[1].id == 12 or spEffect[1].id == 13 or spEffect[1].id == 3 or spEffect[1].id == 11 or spEffect[1].id == 1 or spEffect[1].id == 0 or spEffect[1].id == 2) then
            local alteration = tes3.player.mobile.alteration.base
            if alteration < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(11, 1)
                    tes3.messageBox("You watch as the spellmaker bends reality to their will. You perceive a change in your Alteration capability.")
                end
            end
        end
        --Restoration Spell Created--
        if (spEffect[1].id == 70 or spEffect[1].id == 69 or spEffect[1].id == 71 or spEffect[1].id == 72 or spEffect[1].id == 73 or spEffect[1].id == 117 or spEffect[1].id == 79 or spEffect[1].id == 80 or spEffect[1].id == 81 or spEffect[1].id == 82 or spEffect[1].id == 83 or spEffect[1].id == 84 or spEffect[1].id == 94 or spEffect[1].id == 95 or spEffect[1].id == 96 or spEffect[1].id == 90 or spEffect[1].id == 91 or spEffect[1].id == 92 or spEffect[1].id == 93 or spEffect[1].id == 98 or spEffect[1].id == 99 or spEffect[1].id == 97 or spEffect[1].id == 74 or spEffect[1].id == 75 or spEffect[1].id == 76 or spEffect[1].id == 77 or spEffect[1].id == 78) then
            local restoration = tes3.player.mobile.restoration.base
            if restoration < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(15, 1)
                    tes3.messageBox("You observe the spellmaker generating raw energy to weave into the spell. It occurs to you that this is a facet of Restoration.")
                end
            end
        end
        --Illusion Spell Created--
        if (spEffect[1].id == 47 or spEffect[1].id == 50 or spEffect[1].id == 49 or spEffect[1].id == 40 or spEffect[1].id == 44 or spEffect[1].id == 54 or spEffect[1].id == 53 or spEffect[1].id == 52 or spEffect[1].id == 51 or spEffect[1].id == 39 or spEffect[1].id == 41 or spEffect[1].id == 43 or spEffect[1].id == 45 or spEffect[1].id == 56 or spEffect[1].id == 55 or spEffect[1].id == 42 or spEffect[1].id == 46 or spEffect[1].id == 48) then
            local illusion = tes3.player.mobile.illusion.base
            if illusion < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(12, 1)
                    tes3.messageBox("The spellmaker performs actions indecipherable to you. It only serves to make you realize it was an Illusion all along.")
                end
            end
        end
        --Conjuration Spell Created--
        if (spEffect[1].id == 123 or spEffect[1].id == 129 or spEffect[1].id == 127 or spEffect[1].id == 120 or spEffect[1].id == 131 or spEffect[1].id == 128 or spEffect[1].id == 125 or spEffect[1].id == 121 or spEffect[1].id == 122 or spEffect[1].id == 130 or spEffect[1].id == 124 or spEffect[1].id == 118 or spEffect[1].id == 119 or spEffect[1].id == 110 or spEffect[1].id == 108 or spEffect[1].id == 134 or spEffect[1].id == 103 or spEffect[1].id == 104 or spEffect[1].id == 105 or spEffect[1].id == 114 or spEffect[1].id == 115 or spEffect[1].id == 113 or spEffect[1].id == 109 or spEffect[1].id == 112 or spEffect[1].id == 102 or spEffect[1].id == 107 or spEffect[1].id == 116 or spEffect[1].id == 111 or spEffect[1].id == 101) then
            local conjuration = tes3.player.mobile.conjuration.base
            if conjuration < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(13, 1)
                    tes3.messageBox("The spellmaker scribbles some math regarding the dimensions of a portal. A certain equation calls to mind a new technnique in portal Conjuration.")
                end
            end
        end
    end
    log:info("Spellmaking services rendered. Player Intelligence: " .. tes3.mobilePlayer.intelligence.current .. ". Time Reduction: %" .. (intelligenceOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
end
event.register (tes3.event.spellCreated, npcSpellmaker)

-------------------------------------------------------------------------------------------------------------

local function haltSTrigger(e)
    initialSTrigger = false
end

local function spellByNPCreal(e)
    if spellFlag == 0 then return end
    if config.advanceTimeNPCspell == true then
        if not initialSTrigger then
            initialSTrigger = true
            local baseNPCspell = (config.spellNPC_Modifier * 0.1)
            local intelligenceOffset = (tes3.mobilePlayer.intelligence.current / 150)
            local gameHour = tes3.getGlobal('GameHour')
            local spellTime = (baseNPCspell * (1- intelligenceOffset))
            if spellTime < 0.02 then
                spellTime = 0.02
            end
            gameHour = (gameHour + spellTime)
            tes3.setGlobal('GameHour', gameHour)
            if config.restMode == true then
                local fatigue = tes3.player.mobile.fatigue.current
                local fatigueMax = tes3.player.mobile.fatigue.base
                local percentRest = (math.round(((fatigueMax * 0.01) * (spellTime * 100)), 0))
                local fatigueFinal = (fatigue + percentRest)
                if fatigueFinal > fatigueMax then
                    fatigueFinal = fatigueMax
                end
                tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
                log:debug("Resting while NPC teaches spell. " .. percentRest .. " fatigue restored.")
            end
            timer.delayOneFrame(haltSTrigger, timer.real)
            log:info("Spell purchased. Player Intelligence: " .. tes3.mobilePlayer.intelligence.current .. ". Time Reduction: %" .. (intelligenceOffset * 100) .. ". Time passed to " .. math.round(gameHour, 2) .. ".")
        end
    end
end

local function spellByNPCbridge(e)
    spellFlag=1
    if event.isRegistered (tes3.event.uiActivated, spellByNPCreal, {filter="MenuServiceSpells"}) then return end
    if config.advanceTimeNPCspell == true then
        event.register (tes3.event.uiActivated, spellByNPCreal, {filter="MenuServiceSpells"})
    end
end

local function spellByNPC(e)
    local closeButton=e.element:findChild(tes3ui.registerID("MenuServiceSpells_Okbutton"))
        closeButton:registerAfter("mouseDown", function()
           spellFlag=0
        end)
    if config.advanceTimeNPCspell == true then
        timer.start({duration = 1, callback = spellByNPCbridge, type = timer.real })
    end
end
event.register (tes3.event.uiActivated, spellByNPC, {filter="MenuServiceSpells"})



--Bartering--

local function npcBarter(e)
    if config.advanceTimeBarter ~= true then return end
    local gameHour = tes3.getGlobal('GameHour')
    gameHour = gameHour + (1 / 60)
    tes3.setGlobal('GameHour', gameHour)
    if config.restMode == true then
        local fatigue = tes3.player.mobile.fatigue.current
        local fatigueMax = tes3.player.mobile.fatigue.base
        local percentRest = (math.round((fatigueMax * 0.02), 0))
        local fatigueFinal = (fatigue + percentRest)
        if fatigueFinal > fatigueMax then
            fatigueFinal = fatigueMax
        end
        tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
        log:info("Resting while bartering. " .. percentRest .. " fatigue restored.")
    end
    log:info("Bartering. Time passed to " .. math.round(gameHour, 2) .. ".")
end
event.register (tes3.event.calcBarterPrice, npcBarter)
event.register (tes3.event.barterOffer, npcBarter)



--Talking--

local function npcChatter(e)
    if (e.info.type == 1 or e.info.type == 2 or e.info.type == 4) then return end
    if config.advanceTimeChat ~= true then return end
    local gameHour = tes3.getGlobal('GameHour')
    local randNum = math.random(config.chatMin, config.chatMax)
    gameHour = (gameHour + (randNum / 60))
    tes3.setGlobal('GameHour', gameHour)
    if config.restMode == true then
        local fatigue = tes3.player.mobile.fatigue.current
        local fatigueMax = tes3.player.mobile.fatigue.base
        local percentRest = (math.round(((fatigueMax * 0.02) * randNum), 0))
        local fatigueFinal = (fatigue + percentRest)
        if fatigueFinal > fatigueMax then
            fatigueFinal = fatigueMax
        end
        tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
        log:info("Resting while chatting. " .. percentRest .. " fatigue restored.")
    end
    log:info("Chatting for " .. randNum .. " minute(s). Time passed to " .. math.round(gameHour, 2) .. ".")
end
event.register (tes3.event.infoGetText, npcChatter)



--Config Stuff--

event.register("modConfigReady", function()
    require("timeConsumer.mcm")
	config = require("timeConsumer.config")
end)