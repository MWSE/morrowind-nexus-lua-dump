--Initialize--
local config = require("timeConsumer.config")
local strings = require("timeConsumer.strings")
local logger = require("logging.logger")

local log = logger.new {
    name = "Time Consumer",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized(e)
    log:info("Initialized.")
end

event.register("initialized", initialized)


--Used to ensure repair attempts aren't triggered in MenuMessage
local repairTrigger = 1





--Enchanting---------------------------------------------------------------------------------------------------------------

local function enchantSuccessAttempt(e)
    log:trace("enchantSuccessAttempt function triggered.")
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
        log:info("Enchantment Success. Enchant skill: " ..
            tes3.mobilePlayer.enchant.current ..
            ". Time Reduction: " ..
            (enchantOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

event.register(tes3.event.enchantedItemCreated, enchantSuccessAttempt)

local function enchantFailAttempt(e)
    log:trace("enchantFailAttempt function triggered.")
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
        log:info("Enchantment Failed. Enchant skill: " ..
            tes3.mobilePlayer.enchant.current ..
            ". Time Reduction: " ..
            (enchantOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

event.register(tes3.event.enchantedItemCreateFailed, enchantFailAttempt)

local function enchantByNPC(e)
    log:trace("enchantByNPC function triggered.")
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
            local pFatigue = tes3.player.mobile.fatigue
            local fortifyEffect = tes3.getEffectMagnitude({
                reference = tes3.player,
                effect = tes3.effect.fortifyFatigue,
            })
            log:debug("Fortify Fatigue magnitude: " .. fortifyEffect .. ".")
            local fatigueMax = (pFatigue.base + fortifyEffect)
            local percentRest = (math.round(((fatigueMax * 0.01) * (enchantTime * 100)), 0))
            local fatigueFinal = (pFatigue.current + percentRest)
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
                    tes3.messageBox(strings.enchFlavor[math.random(1, #strings.enchFlavor)])
                end
            end
        end
        log:info("Enchantment services rendered by " ..
            npcRef.object.name ..
            ". Enchant skill: " ..
            npcRef.mobile.enchant.current ..
            ". Time Reduction: " ..
            (enchantOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

event.register(tes3.event.enchantedItemCreated, enchantByNPC)

local function enchantRecharge(e)
    log:trace("enchantRecharge function triggered.")
    if not tes3ui.menuMode() then return end
    --local topMenu = tes3ui.getMenuOnTop()
    --if topMenu.name ~= "MenuInventorySelect" then return end
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
    log:info("Enchantment recharged. Enchant skill: " ..
        tes3.mobilePlayer.enchant.current ..
        ". Time Reduction: " .. (enchantOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
end

--Player Repairs--------------------------------------------------------------------------------------------------------------------

local function onRepairAttempt(e)
    log:trace("onRepairAttempt function triggered.")
    if not tes3ui.menuMode() then return end
    local topMenu = tes3ui.getMenuOnTop()
    if topMenu.name ~= "MenuRepair" then return end
    if repairTrigger == 0 then repairTrigger = 1 return end
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
    log:info("Repair Attempted. Armorer skill: " ..
        tes3.mobilePlayer.armorer.current ..
        ". Time Reduction: " .. (armorerOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
end

--NPC Repairs-------------------------------------------------------------------------------------------------------------

local function onRepairService(e)
    log:trace("onRepairService function triggered.")
    if config.advanceTimeNPCrepair == true then
        local npcMob = tes3ui.getServiceActor()
        local baseNPCrepair = (config.repairNPC_Modifier * 0.1)
        local armorerOffset = (npcMob.armorer.current / 125)
        local repairTime = (baseNPCrepair * (1 - armorerOffset))
        local gameHour = tes3.getGlobal('GameHour')
        if repairTime < 0.02 then
            repairTime = 0.02
        end
        gameHour = (gameHour + repairTime)
        tes3.setGlobal('GameHour', gameHour)
        if config.restMode == true then
            local pFatigue = tes3.player.mobile.fatigue
            local fortifyEffect = tes3.getEffectMagnitude({
                reference = tes3.player,
                effect = tes3.effect.fortifyFatigue,
            })
            log:debug("Fortify Fatigue magnitude: " .. fortifyEffect .. ".")
            local fatigueMax = (pFatigue.base + fortifyEffect)
            local percentRest = (math.round(((fatigueMax * 0.01) * (repairTime * 100)), 0))
            local fatigueFinal = (pFatigue.current + percentRest)
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
                    tes3.messageBox(strings.repairFlavor[math.random(1, #strings.repairFlavor)])
                end
            end
        end
        log:info("Repair Services rendered. NPC Armorer skill: " ..
            npcMob.armorer.current ..
            ". Time Reduction: " ..
            (armorerOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

--Alchemy-------------------------------------------------------------------------------------------------------------------

local function potionSuccessAttempt(e)
    log:trace("potionSuccessAttempt function triggered.")
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
        log:info("Alchemy Succeeded. Alchemy skill: " ..
            tes3.mobilePlayer.alchemy.current ..
            ". Time Reduction: " ..
            (alchemyOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

event.register(tes3.event.potionBrewed, potionSuccessAttempt)

local function potionFailAttempt(e)
    log:trace("potionFailAttempt function triggered.")
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
        log:info("Alchemy Failed. Alchemy skill: " ..
            tes3.mobilePlayer.alchemy.current ..
            ". Time Reduction: " ..
            (alchemyOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

event.register(tes3.event.potionBrewFailed, potionFailAttempt)



--Spellmaking--------------------------------------------------------------------------------------------------------------------------

local function npcSpellmaker(e)
    log:trace("npcSpellmaker function triggered.")
    if config.advanceTimeNPCspellmaker ~= true then return end
    if e.source ~= tes3.spellSource.service then return end
    local npcMob = tes3ui.getServiceActor()
    log:trace("Current NPC Intelligence: " .. npcMob.intelligence.current .. ".")
    local npcSpellMakeBase = (config.npcSpellTime_Modifier * 0.1)
    local intelligenceOffsetNPC = (npcMob.intelligence.current / 500)
    local intelligenceOffset = (tes3.mobilePlayer.intelligence.current / 500)
    local gameHour = tes3.getGlobal('GameHour')
    local spellmakeTime = (npcSpellMakeBase * (1 - (intelligenceOffset + intelligenceOffsetNPC)))
    if spellmakeTime < 0.02 then
        spellmakeTime = 0.02
    end
    gameHour = (gameHour + spellmakeTime)
    tes3.setGlobal('GameHour', gameHour)
    if config.restMode == true then
        local pFatigue = tes3.player.mobile.fatigue
        local fortifyEffect = tes3.getEffectMagnitude({
            reference = tes3.player,
            effect = tes3.effect.fortifyFatigue,
        })
        log:debug("Fortify Fatigue magnitude: " .. fortifyEffect .. ".")
        local fatigueMax = (pFatigue.base + fortifyEffect)
        local percentRest = (math.round(((fatigueMax * 0.01) * (spellmakeTime * 100)), 0))
        local fatigueFinal = (pFatigue.current + percentRest)
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
        if (
            spEffect[1].id == 85 or spEffect[1].id == 86 or spEffect[1].id == 87 or spEffect[1].id == 88 or
                spEffect[1].id == 89 or spEffect[1].id == 63 or spEffect[1].id == 64 or spEffect[1].id == 65 or
                spEffect[1].id == 66 or spEffect[1].id == 57 or spEffect[1].id == 62 or spEffect[1].id == 60 or
                spEffect[1].id == 61 or spEffect[1].id == 68 or spEffect[1].id == 58 or spEffect[1].id == 67 or
                spEffect[1].id == 59) then
            local mysticism = tes3.player.mobile.mysticism.base
            if mysticism < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(14, 1)
                    tes3.messageBox(strings.mystFlavor[math.random(1, #strings.mystFlavor)])
                end
            end
        end
        --Destruction Spell Created--
        if (
            spEffect[1].id == 22 or spEffect[1].id == 23 or spEffect[1].id == 24 or spEffect[1].id == 25 or
                spEffect[1].id == 26 or spEffect[1].id == 38 or spEffect[1].id == 37 or spEffect[1].id == 17 or
                spEffect[1].id == 20 or spEffect[1].id == 18 or spEffect[1].id == 19 or spEffect[1].id == 21 or
                spEffect[1].id == 14 or spEffect[1].id == 16 or spEffect[1].id == 27 or spEffect[1].id == 15 or
                spEffect[1].id == 33 or spEffect[1].id == 32 or spEffect[1].id == 34 or spEffect[1].id == 28 or
                spEffect[1].id == 29 or spEffect[1].id == 30 or spEffect[1].id == 31 or spEffect[1].id == 35 or
                spEffect[1].id == 36) then
            local destruction = tes3.player.mobile.destruction.base
            if destruction < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(10, 1)
                    tes3.messageBox(strings.destFlavor[math.random(1, #strings.destFlavor)])
                end
            end
        end
        --Alteration Spell Created--
        if (
            spEffect[1].id == 7 or spEffect[1].id == 8 or spEffect[1].id == 4 or spEffect[1].id == 6 or
                spEffect[1].id == 9 or spEffect[1].id == 10 or spEffect[1].id == 5 or spEffect[1].id == 12 or
                spEffect[1].id == 13 or spEffect[1].id == 3 or spEffect[1].id == 11 or spEffect[1].id == 1 or
                spEffect[1].id == 0 or spEffect[1].id == 2) then
            local alteration = tes3.player.mobile.alteration.base
            if alteration < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(11, 1)
                    tes3.messageBox(strings.altFlavor[math.random(1, #strings.altFlavor)])
                end
            end
        end
        --Restoration Spell Created--
        if (
            spEffect[1].id == 70 or spEffect[1].id == 69 or spEffect[1].id == 71 or spEffect[1].id == 72 or
                spEffect[1].id == 73 or spEffect[1].id == 117 or spEffect[1].id == 79 or spEffect[1].id == 80 or
                spEffect[1].id == 81 or spEffect[1].id == 82 or spEffect[1].id == 83 or spEffect[1].id == 84 or
                spEffect[1].id == 94 or spEffect[1].id == 95 or spEffect[1].id == 96 or spEffect[1].id == 90 or
                spEffect[1].id == 91 or spEffect[1].id == 92 or spEffect[1].id == 93 or spEffect[1].id == 98 or
                spEffect[1].id == 99 or spEffect[1].id == 97 or spEffect[1].id == 74 or spEffect[1].id == 75 or
                spEffect[1].id == 76 or spEffect[1].id == 77 or spEffect[1].id == 78) then
            local restoration = tes3.player.mobile.restoration.base
            if restoration < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(15, 1)
                    tes3.messageBox(strings.restFlavor[math.random(1, #strings.restFlavor)])
                end
            end
        end
        --Illusion Spell Created--
        if (
            spEffect[1].id == 47 or spEffect[1].id == 50 or spEffect[1].id == 49 or spEffect[1].id == 40 or
                spEffect[1].id == 44 or spEffect[1].id == 54 or spEffect[1].id == 53 or spEffect[1].id == 52 or
                spEffect[1].id == 51 or spEffect[1].id == 39 or spEffect[1].id == 41 or spEffect[1].id == 43 or
                spEffect[1].id == 45 or spEffect[1].id == 56 or spEffect[1].id == 55 or spEffect[1].id == 42 or
                spEffect[1].id == 46 or spEffect[1].id == 48) then
            local illusion = tes3.player.mobile.illusion.base
            if illusion < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(12, 1)
                    tes3.messageBox(strings.illFlavor[math.random(1, #strings.illFlavor)])
                end
            end
        end
        --Conjuration Spell Created--
        if (
            spEffect[1].id == 123 or spEffect[1].id == 129 or spEffect[1].id == 127 or spEffect[1].id == 120 or
                spEffect[1].id == 131 or spEffect[1].id == 128 or spEffect[1].id == 125 or spEffect[1].id == 121 or
                spEffect[1].id == 122 or spEffect[1].id == 130 or spEffect[1].id == 124 or spEffect[1].id == 118 or
                spEffect[1].id == 119 or spEffect[1].id == 110 or spEffect[1].id == 108 or spEffect[1].id == 134 or
                spEffect[1].id == 103 or spEffect[1].id == 104 or spEffect[1].id == 105 or spEffect[1].id == 114 or
                spEffect[1].id == 115 or spEffect[1].id == 113 or spEffect[1].id == 109 or spEffect[1].id == 112 or
                spEffect[1].id == 102 or spEffect[1].id == 107 or spEffect[1].id == 116 or spEffect[1].id == 111 or
                spEffect[1].id == 101) then
            local conjuration = tes3.player.mobile.conjuration.base
            if conjuration < 25 then
                local chance = math.random(1, 100)
                if chance <= 40 then
                    tes3.player.mobile:exerciseSkill(13, 1)
                    tes3.messageBox(strings.conjFlavor[math.random(1, #strings.conjFlavor)])
                end
            end
        end
    end
    log:info("Spellmaking services rendered. Player Intelligence: " ..
        tes3.mobilePlayer.intelligence.current ..
        ". NPC Intelligence: " ..
        npcMob.intelligence.current ..
        ". Time Reduction: " ..
        ((intelligenceOffset + intelligenceOffsetNPC) * 100) ..
        " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
end

event.register(tes3.event.spellCreated, npcSpellmaker)

--Spell Purchasing-----------------------------------------------------------------------------------------------------------

local function onSpellService(e)
    log:trace("onSpellService function triggered.")
    if config.advanceTimeNPCspell == true then
        local baseNPCspell = (config.spellNPC_Modifier * 0.1)
        local npcMob = tes3ui.getServiceActor()
        local intelligenceOffsetNPC = (npcMob.intelligence.current / 500)
        local intelligenceOffsetPlayer = (tes3.mobilePlayer.intelligence.current / 200)
        local totalOffset = intelligenceOffsetNPC + intelligenceOffsetPlayer
        local gameHour = tes3.getGlobal('GameHour')
        local spellTime = (baseNPCspell * (1 - totalOffset))
        if spellTime < 0.02 then
            spellTime = 0.02
        end
        gameHour = (gameHour + spellTime)
        tes3.setGlobal('GameHour', gameHour)
        if config.restMode == true then
            local pFatigue = tes3.player.mobile.fatigue
            local fortifyEffect = tes3.getEffectMagnitude({
                reference = tes3.player,
                effect = tes3.effect.fortifyFatigue,
            })
            log:debug("Fortify Fatigue magnitude: " .. fortifyEffect .. ".")
            local fatigueMax = (pFatigue.base + fortifyEffect)
            local percentRest = (math.round(((fatigueMax * 0.01) * (spellTime * 100)), 0))
            local fatigueFinal = (pFatigue.current + percentRest)
            if fatigueFinal > fatigueMax then
                fatigueFinal = fatigueMax
            end
            tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
            log:debug("Resting while NPC teaches spell. " .. percentRest .. " fatigue restored.")
        end
        log:info("Spell purchased. Player Intelligence: " ..
            tes3.mobilePlayer.intelligence.current ..
            ". NPC Intelligence: " .. npcMob.intelligence.current .. ". Time Reduction: " ..
            (totalOffset * 100) .. " percent. Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

--Bartering----------------------------------------------------------------------------------------------------------

local function npcBarter(e)
    log:trace("npcBarter function triggered.")
    if config.advanceTimeBarter ~= true then return end
    if tes3.menuMode() == false then log:debug("Menu Mode check failed.") return end
    log:debug("Menu Mode check succeeded.")

    local topMenu = tes3ui.getMenuOnTop()
    if topMenu.name ~= "MenuBarter" then log:debug("Barter Menu check failed.") return end
    log:debug("Barter Menu check succeeded.")

    local gameHour = tes3.getGlobal('GameHour')
    gameHour = gameHour + (1 / 60)
    tes3.setGlobal('GameHour', gameHour)
    log:info("Bartering. Time passed to " .. math.round(gameHour, 2) .. ".")

    if config.restMode == true then
        local pFatigue = tes3.player.mobile.fatigue
        local fortifyEffect = tes3.getEffectMagnitude({
            reference = tes3.player,
            effect = tes3.effect.fortifyFatigue,
        })
        log:debug("Fortify Fatigue magnitude: " .. fortifyEffect .. ".")
        local fatigueMax = (pFatigue.base + fortifyEffect)
        local percentRest = (math.round((fatigueMax * 0.02), 0))
        local fatigueFinal = (pFatigue.current + percentRest)
        if fatigueFinal > fatigueMax then
            fatigueFinal = fatigueMax
        end
        tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
        log:info("Resting while bartering. " .. percentRest .. " fatigue restored.")
    end
end

event.register(tes3.event.calcBarterPrice, npcBarter)
event.register(tes3.event.barterOffer, npcBarter)



--Talking--------------------------------------------------------------------------------------------------------------------

local function npcChatter(e)
    log:trace("npcChatter function triggered.")
    if (e.info.type == 1 or e.info.type == 2 or e.info.type == 4) then return end
    if config.advanceTimeChat ~= true then return end
    local gameHour = tes3.getGlobal('GameHour')
    if config.chatMin > config.chatMax then
        config.chatMin = config.chatMax
    end
    local randNum = math.random(config.chatMin, config.chatMax)
    gameHour = (gameHour + (randNum / 60))
    tes3.setGlobal('GameHour', gameHour)
    if config.restMode == true then
        local pFatigue = tes3.player.mobile.fatigue
        local fortifyEffect = tes3.getEffectMagnitude({
            reference = tes3.player,
            effect = tes3.effect.fortifyFatigue,
        })
        log:debug("Fortify Fatigue magnitude: " .. fortifyEffect .. ".")
        local fatigueMax = (pFatigue.base + fortifyEffect)
        local percentRest = (math.round(((fatigueMax * 0.02) * randNum), 0))
        local fatigueFinal = (pFatigue.current + percentRest)
        if fatigueFinal > fatigueMax then
            fatigueFinal = fatigueMax
        end
        tes3.setStatistic({ name = "fatigue", current = fatigueFinal, reference = tes3.mobilePlayer })
        log:info("Resting while chatting. " .. percentRest .. " fatigue restored.")
    end
    log:info("Chatting for " .. randNum .. " minute(s). Time passed to " .. math.round(gameHour, 2) .. ".")
end

local function npcChatterRegister()
    log:trace("npcChatterRegister function triggered.")
    if event.isRegistered(tes3.event.infoGetText, npcChatter) then return end
    event.register(tes3.event.infoGetText, npcChatter)
end

event.register("uiActivated", npcChatterRegister, { filter = "MenuDialog" })


--Searching Containers----------------------------------------------------------------------------------------------------------------

local function rummage()
    log:trace("rummage function triggered.")
    if tes3ui.menuMode() then
        local menu = tes3ui.getMenuOnTop()
        if menu.name ~= "MenuContents" then return end
        local gameHour = tes3.getGlobal('GameHour')
        gameHour = (gameHour + (1 / 60))
        tes3.setGlobal('GameHour', gameHour)
        log:info("Time passed while searching container! Time passed to " .. math.round(gameHour, 2) .. ".")
    end
end

local function onSearch(e)
    log:trace("onSearch function triggered.")
    if e.activator ~= tes3.player then return end
    local objRef = e.target
    local switch = 0
    if config.lootTime == true then
        if objRef.object.objectType == tes3.objectType.container then
            switch = 1
        end
    end
    if config.bodyTime == true then
        if (objRef.object.objectType == tes3.objectType.npc or objRef.object.objectType == tes3.objectType.creature) then
            switch = 1
        end
    end
    if (switch == 0 or objRef.isEmpty == true) then return end
    timer.start({ type = timer.real, duration = 0.6, callback = rummage })
    log:debug("Container search timer began.")
end

event.register(tes3.event.activate, onSearch)

--Right Click Menu Exit Compatibility-------------------------------------------------------------------------------------------------------------

local function menuCheck()
    log:trace("menuCheck function triggered.")
    local topMenu = tes3ui.getMenuOnTop()
    if topMenu.name ~= "MenuRepair" then
        if event.isRegistered(tes3.event.uiActivated, onRepairAttempt) then
            log:trace("onRepairAttempt function is registered. Unregistering.")
            event.unregister(tes3.event.uiActivated, onRepairAttempt)
        end
    end
    if topMenu.name ~= "MenuServiceRepair" then
        if event.isRegistered(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" }) then
            log:trace("onRepairService function is registered. Unregistering.")
            event.unregister(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" })
        end
    end
    if topMenu.name ~= "MenuServiceSpells" then
        if event.isRegistered(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" }) then
            log:trace("onSpellService function is registered. Unregistering.")
            event.unregister(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" })
        end
    end
end

local function onMouseButtonDown(e)
    log:trace("onMouseButtonDown function triggered.")
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
        timer.start({ duration = 0.6, callback = menuCheck, type = timer.real })
    end
end

--Register Switches--------------------------------------------------------------------------------------------------------------------

--Player Repairs--
local function repairAttemptBridge(e)
    log:trace("repairAttemptBridge function triggered.")
    if event.isRegistered(tes3.event.uiActivated, onRepairAttempt) then return end
    log:trace("onRepairAttempt function unregistered. Registering.")
    event.register(tes3.event.uiActivated, onRepairAttempt)
end

local function repairAttemptRegister(e)
    log:trace("repairAttemptRegister function triggered.")
    local closeRButton = e.element:findChild(tes3ui.registerID("MenuRepair_Okbutton"))
    closeRButton:registerAfter("mouseDown", function()
        log:trace("repairAttemptCloseButton function triggered.")
        if event.isRegistered(tes3.event.exerciseSkill, enchantRecharge) then
            log:trace("enchantRecharge function is registered. Unregistering.")
            event.unregister(tes3.event.exerciseSkill, enchantRecharge)
        end
        if event.isRegistered(tes3.event.uiActivated, onRepairAttempt) then
            log:trace("onRepairAttempt function is registered. Unregistering.")
            event.unregister(tes3.event.uiActivated, onRepairAttempt)
        end
        if event.isRegistered("mouseButtonDown", onMouseButtonDown) then
            log:trace("mouseButtonDown function registered. Unregistering.")
            event.unregister("mouseButtonDown", onMouseButtonDown)
        end
        repairTrigger = 1
    end)
    timer.start({ duration = 0.6, callback = repairAttemptBridge, type = timer.real })
    repairTrigger = 1
    if event.isRegistered("mouseButtonDown", onMouseButtonDown) == false then
        log:trace("mouseButtonDown function unregistered. Registering.")
        event.register("mouseButtonDown", onMouseButtonDown)
    end
    if event.isRegistered(tes3.event.exerciseSkill, enchantRecharge) then return end
    event.register(tes3.event.exerciseSkill, enchantRecharge)
end

event.register(tes3.event.uiActivated, repairAttemptRegister, { filter = "MenuRepair" })

local function menuMessage(e)
    log:trace("menuMessage function triggered.")
    repairTrigger = 0
end

event.register(tes3.event.uiActivated, menuMessage, { filter = "MenuMessage" })

--NPC Repairs--
local function repairServiceRegister(e)
    log:trace("repairServiceRegister function triggered.")
    local closeButton = e.element:findChild(tes3ui.registerID("MenuServiceRepair_Okbutton"))
    closeButton:registerAfter("mouseDown", function()
        if event.isRegistered(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" }) then
            log:trace("onRepairService function is registered. Unregistering.")
            event.unregister(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" })
        end
        if event.isRegistered("mouseButtonDown", onMouseButtonDown) then
            log:trace("mouseButtonDown function registered. Unregistering.")
            event.unregister("mouseButtonDown", onMouseButtonDown)
        end
    end)
    if event.isRegistered(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" }) == false then
        log:trace("onRepairService function unregistered. Registering.")
        event.register(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" })
    end
    if event.isRegistered("mouseButtonDown", onMouseButtonDown) == false then
        log:trace("mouseButtonDown function unregistered. Registering.")
        event.register("mouseButtonDown", onMouseButtonDown)
    end
end

event.register(tes3.event.uiActivated, repairServiceRegister, { filter = "MenuServiceRepair" })

--NPC Spell Service--
local function spellServiceRegister(e)
    log:trace("spellServiceRegister function triggered.")
    local closeButton = e.element:findChild(tes3ui.registerID("MenuServiceSpells_Okbutton"))
    closeButton:registerAfter("mouseDown", function()
        if event.isRegistered(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" }) then
            log:trace("onSpellService function registered. Unregistering.")
            event.unregister(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" })
        end
        if event.isRegistered("mouseButtonDown", onMouseButtonDown) then
            log:trace("mouseButtonDown function registered. Unregistering.")
            event.unregister("mouseButtonDown", onMouseButtonDown)
        end
    end)
    if event.isRegistered(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" }) == false then
        log:trace("onSpellService function unregistered. Registering.")
        event.register(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" })
    end
    if event.isRegistered("mouseButtonDown", onMouseButtonDown) == false then
        log:trace("mouseButtonDown function unregistered. Registering.")
        event.register("mouseButtonDown", onMouseButtonDown)
    end
end

event.register(tes3.event.uiActivated, spellServiceRegister, { filter = "MenuServiceSpells" })

--Menu Exit--
local function onMenuExit(e)
    log:trace("onMenuExit function triggered.")
    repairTrigger = 1
    if event.isRegistered(tes3.event.exerciseSkill, enchantRecharge) then
        log:trace("enchantRecharge function is registered. Unregistering.")
        event.unregister(tes3.event.exerciseSkill, enchantRecharge)
    end
    if event.isRegistered(tes3.event.uiActivated, onRepairAttempt) then
        log:trace("onRepairAttempt function is registered. Unregistering.")
        event.unregister(tes3.event.uiActivated, onRepairAttempt)
    end
    if event.isRegistered(tes3.event.infoGetText, npcChatter) then
        log:trace("npcChatter function is registered. Unregistering.")
        event.unregister(tes3.event.infoGetText, npcChatter)
    end
    if event.isRegistered(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" }) then
        log:trace("onRepairService function is registered. Unregistering.")
        event.unregister(tes3.event.uiActivated, onRepairService, { filter = "MenuServiceRepair" })
    end
    if event.isRegistered(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" }) then
        log:trace("onSpellService function registered. Unregistering.")
        event.unregister(tes3.event.uiActivated, onSpellService, { filter = "MenuServiceSpells" })
    end
    if event.isRegistered("mouseButtonDown", onMouseButtonDown) then
        log:trace("mouseButtonDown function is registered. Unregistering.")
        event.unregister("mouseButtonDown", onMouseButtonDown)
    end
end

event.register(tes3.event.menuExit, onMenuExit)





--Config Stuff--

event.register("modConfigReady", function()
    require("timeConsumer.mcm")
    config = require("timeConsumer.config")
end)