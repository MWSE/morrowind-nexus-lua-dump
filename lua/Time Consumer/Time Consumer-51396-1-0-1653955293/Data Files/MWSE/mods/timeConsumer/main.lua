--Initialize--

local config
local initialTrigger = false
local initialSTrigger = false
local spellFlag = 1
local repairFlag = 1
local repairNPCflag = 1
local repairTrigger = 1

local function initialized(e)
    print ("[Time Consumer]: Initialized.")
end
event.register ("initialized", initialized)



--Enchanting--

local function enchantSuccessAttempt(e)
    if e.enchanter ~= tes3.mobilePlayer then return end
        if config.advanceTimeEnchantSuccess == true then
            local baseEsuccess = (config.enchantSuccess_Modifier * 0.1)
            local gameHour = tes3.getGlobal('GameHour')
            local enchantOffset = (tes3.mobilePlayer.enchant.current + 10) / 2
            gameHour = gameHour + (baseEsuccess / ((enchantOffset + 12.5) / 25))
            tes3.setGlobal('GameHour', gameHour)
            if config.debugMode == false then return end
            print("[Time Consumer]: Enchantment Success. Time Passed.")
		end
    end
event.register (tes3.event.enchantedItemCreated, enchantSuccessAttempt)

local function enchantFailAttempt(e)
    if config.advanceTimeEnchantFail == true then
        local baseEfail = (config.enchantFail_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local enchantOffset = (tes3.mobilePlayer.enchant.current + 10) / 2
        gameHour = gameHour + (baseEfail / ((enchantOffset + 12.5) / 25))
        tes3.setGlobal('GameHour', gameHour)
        if config.debugMode == false then return end
        print("[Time Consumer]: Enchantment Failed. Time Passed.")
    end
end
event.register (tes3.event.enchantedItemCreateFailed, enchantFailAttempt)

local function enchantByNPC(e)
    if config.advanceTimeNPCenchant == true then
        local baseNPCenchant = (config.enchantNPC_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        gameHour = gameHour + baseNPCenchant
        tes3.setGlobal('GameHour', gameHour)
        if config.debugMode == false then return end
        print("[Time Consumer]: Enchantment services rendered. Time Passed.")
    end
end
event.register (tes3.event.enchantedItemCreated, enchantByNPC)

local function enchantRecharge(e)
    if e.skill ~= tes3.skill.enchant then return end
    if config.advanceTimeRecharge ~= true then return end
    local baseRecharge = (config.recharge_Modifier * 0.1)
    local gameHour = tes3.getGlobal('GameHour')
    local enchantOffset = (tes3.mobilePlayer.enchant.current +10)
    gameHour = gameHour + (baseRecharge / (enchantOffset * 0.1))
    tes3.setGlobal('GameHour', gameHour)
    if config.debugMode == false then return end
    print("[Time Consumer]: Enchantment recharged. Time passed.")
end



--Repairs--

local function repairAttemptReal(e)
    if repairFlag == 0 then return end
    if repairTrigger == 0 then return end
    if config.advanceTimeRepairAttempt ~= true then return end
    local baseRattempt = (config.repairAttempt_Modifier * 0.1)
    local gameHour = tes3.getGlobal('GameHour')
    local armorerOffset = (tes3.mobilePlayer.armorer.current +10)
    gameHour = gameHour + (baseRattempt / (armorerOffset * 0.1))
    tes3.setGlobal('GameHour', gameHour)
    if config.debugMode == false then return end
    print("[Time Consumer]: Repair Attempted. Time passed.")
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
            timer.delayOneFrame(haltTrigger, timer.real)
            if config.debugMode == false then return end
            print("[Time Consumer]: Repair services rendered. Time Passed.")
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
        local alchemyOffset = (tes3.mobilePlayer.alchemy.current +10)
        gameHour = gameHour + (baseAsuccess / (alchemyOffset * 0.1))
        tes3.setGlobal('GameHour', gameHour)
        if config.debugMode == false then return end
        print("[Time Consumer]: Alchemy Succeeded. Time Passed.")
    end
end
event.register (tes3.event.potionBrewed, potionSuccessAttempt)

local function potionFailAttempt(e)
    if config.advanceTimePotionFail == true then
        local baseAfail = (config.potionFail_Modifier * 0.1)
        local gameHour = tes3.getGlobal('GameHour')
        local alchemyOffset = (tes3.mobilePlayer.alchemy.current +10)
        gameHour = gameHour + (baseAfail / (alchemyOffset * 0.1))
        tes3.setGlobal('GameHour', gameHour)
        if config.debugMode == false then return end
        print("[Time Consumer]: Alchemy Failed. Time Passed.")
    end
end
event.register (tes3.event.potionBrewFailed, potionFailAttempt)



--Spellmaking--

local function npcSpellmaker(e)
    if config.advanceTimeNPCspellmaker ~= true then return end
    if e.source ~= tes3.spellSource.service then return end
    local npcSpellMake = (config.spellmakeNPC_Modifier * 0.1)
    local intelligenceOffset = ((tes3.mobilePlayer.intelligence.current + 5) * 0.2)
    local gameHour = tes3.getGlobal('GameHour')
    gameHour = gameHour + (npcSpellMake - (intelligenceOffset * 0.1))
    tes3.setGlobal('GameHour', gameHour)
    if config.debugMode == false then return end
    print("[Time Consumer]: Spellmaking services rendered. Time Passed.")
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
            local intelligenceOffset = (tes3.mobilePlayer.intelligence.current + 10)
            local gameHour = tes3.getGlobal('GameHour')
            gameHour = gameHour + (baseNPCspell / (intelligenceOffset * 0.1))
            tes3.setGlobal('GameHour', gameHour)
            timer.delayOneFrame(haltSTrigger, timer.real)
            if config.debugMode == false then return end
            print("[Time Consumer]: Spell purchased. Time Passed.")
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
    if config.debugMode == false then return end
    print("[Time Consumer]: Bartering. Time passed.")
end
event.register (tes3.event.calcBarterPrice, npcBarter)
event.register (tes3.event.barterOffer, npcBarter)



--Config Stuff--

event.register("modConfigReady", function()
    require("timeConsumer.mcm")
	config = require("timeConsumer.config")
end)



--Feature Ideas--

--container looting?
--taking off/putting on armor?