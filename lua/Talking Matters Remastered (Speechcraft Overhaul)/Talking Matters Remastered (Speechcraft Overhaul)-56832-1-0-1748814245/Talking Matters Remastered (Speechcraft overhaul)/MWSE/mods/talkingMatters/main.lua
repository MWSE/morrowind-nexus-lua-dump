local talkativeness = require("talkingMatters.talkativeness")
local data
local config
local dialogMenu
local GUI_ID_MenuPersuasion
local failedPersuasionInfos = {}
local successfulPersuasionInfos = {}
local log = mwse.Logger.new()

local function getTodaysDate()
    local day = tes3.getGlobal("Day")
    local month = tes3.getGlobal("Month")
    local year = tes3.getGlobal("Year")

    local todaysDate = {
        day = day,
        month = month,
        year = year
    }

    return todaysDate
end

-- Check if current topic matches with any previous ones, and register the current topic if can't find a match
-- This means that no topic will be registered unless the option for allowing repetition is on
local function checkRepetition(npcRefe, idInfo)
    local infoSpokenAbout = data.npcData[npcRefe.id].repetitionInfo

    if config.debugEnabled then
        log:debug(string.format("CHECK REPETITION: The NPC reference is: %s", npcRefe))
        log:debug(string.format("CHECK REPETITION: The idInfo is: %s", idInfo))
        log:debug(string.format("CHECK REPETITION: The ID of the saved down table info spoken about is: %s", infoSpokenAbout))
    end

    if infoSpokenAbout == nil then
        data.npcData[npcRefe.id].repetitionInfo = {}
    else
        for _, info in pairs(infoSpokenAbout) do
            if info == idInfo then
                return true
            end
        end
    end
    table.insert(data.npcData[npcRefe.id].repetitionInfo, idInfo)
    return false
end

-- Erase all topics saved for checking repetition
local function refreshRepeatedTopicsList(npcRefe)
    if data.npcData[npcRefe.id] ~= nil then
         data.npcData[npcRefe.id].repetitionInfo = nil
         if config.debugEnabled then
            log:debug(string.format("REPETITION RESET: Repeating topic lists for %s has been reset.", npcRefe.object.name))
         end
    end
end

local function resetNpcAndCalculateTalkSlots(npcRefe, dateToday) 

    local playerClass = tes3.player.object.class.id
    local playerSpeechcraft = tes3.mobilePlayer.speechcraft.current
    local playerFatigue = tes3.mobilePlayer.fatigue.normalized

    -- Set up base amount of slots based on players speechcraft and fatigue
    local slotsBase = (playerSpeechcraft / 10) * playerFatigue
    slotsBase = (math.floor(slotsBase+0.5))

    local npcClass = npcRefe.object.class.id
    npcClass = string.lower(npcClass)
    local npcDisposition = npcRefe.object.disposition

    if (npcDisposition > 100) then
        npcDisposition = 100
    end

    -- Check up predesigned talkativeness per class
    local classModif = talkativeness.talkativeness[npcClass]
    if config.debugEnabled then
            log:debug(string.format("The NPCs class is: %s", npcClass))
            log:debug(string.format("The class modifier is: %d", classModif))
    end
    local npcFaction = npcRefe.object.faction
    
    if string.find(npcClass, 'service') then
        classModif = 2
        npcClass = npcClass:gsub(" service", "")
    elseif not classModif then
        classModif = 1
    end

    -- Add slots based on if same class
    local contextSlots = 0

    if playerClass == npcClass then
        contextSlots = contextSlots + 3
        data.colleague = true
    else
        data.colleague = false
    end

    -- Add slots based on if same faction
    if (npcFaction ~= nil) and (npcFaction.playerJoined == true) then
        contextSlots = contextSlots + npcFaction.playerRank + 1
    end

    -- Add slots based on how much the NPC likes you
    local dispositionSlots = (npcDisposition-40)/8

    -- Sum it all up
    local npcSpeechcraft = npcRefe.mobile.speechcraft.current
    local relativeSlots =  dispositionSlots + (classModif * ( (npcSpeechcraft-10)/10 )) + contextSlots

    -- Add some extra if you are friends!
    local friendDispositionLimit = config.friendDispositionLimit
    if npcDisposition > friendDispositionLimit then
        relativeSlots = relativeSlots + 5
    end

    -- Make sure there is never less than minimum amount of topics you can ask
    local totalSlots = (math.floor(slotsBase + relativeSlots)) 
    local minSlots = config.minimumTopics
    if totalSlots < minSlots then
        totalSlots = minSlots
    end

    local remainingSlots = totalSlots
    local persusasionTotal = config.allowedPersuasionFailures

    local dateLastSpoken
    local repetitionInfo
    if data.npcData[npcRefe.id] ~= nil then
        repetitionInfo = data.npcData[npcRefe.id].repetitionInfo
        dateLastSpoken = data.npcData[npcRefe.id].date
    else
        repetitionInfo = {}
        dateLastSpoken = {}
    end

    
     

    data.npcData[npcRefe.id] = {
        ["persuasionTotal"] = persusasionTotal,
        ["remainingSlots"] = remainingSlots,
        ["date"] = dateToday,
        ["weariedFriend"] = false,
        ["offended"] = false,
        ["repetitionInfo"] = repetitionInfo
    }

    -- If we use repetition, check if we should reset repeated topics
    if config.repetition then
        if config.repetitionReset == 2 then
            if dateLastSpoken.day ~= dateToday.day or dateLastSpoken.month ~= dateToday.month or dateLastSpoken.year ~= dateToday.year then
                refreshRepeatedTopicsList(npcRefe)
                if config.debugEnabled then
                    log:debug("Reset repeated topics (daily)")
                end
            end
        elseif config.repetitionReset == 3 then
            if dateLastSpoken.month ~= dateToday.month or dateLastSpoken.year ~= dateToday.year then
                refreshRepeatedTopicsList(npcRefe)
                if config.debugEnabled then
                    log:debug("Reset repeated topics (monthly)")
                end
            end
        end
    end
end



local function learnSomething(npcRefe)

    local npcClass = npcRefe.object.class
    local pIntelligence = tes3.mobilePlayer.intelligence.current

    if pIntelligence < 60 then 
        return false
    end

    if data.colleague == true and config.colleagueLearning == false then
        return false
    end
    
    local npcSkills = npcClass.majorSkills
    local value = math.random(1,#npcSkills)
    local trainedSkill = npcSkills[value]

    local npcSkill = npcRefe.mobile:getSkillValue(trainedSkill)

    local chanceOfLearning = math.random() * pIntelligence / 40

    if config.debugEnabled then
        tes3.messageBox(string.format("Chance of learning: %d", chanceOfLearning))
    end

    if chanceOfLearning < 1 then
        return false 
    else
        local amountSkillIncrease = npcSkill/20
        tes3.mobilePlayer:exerciseSkill(trainedSkill, amountSkillIncrease)
        return trainedSkill
    end
end

local function checkResponse(e)

    local command = e.command

    if config.debugEnabled then
        log:debug("DIALOGUE CHOICE: Checking for choice round")
    end
    
    command = string.lower(command)
    
    if (string.match(command, "choice") or string.match(command, "goodbye")) then
        data.answerRound = true
        if config.debugEnabled then
            log:debug("DIALOGUE CHOICE: Choice round detected")
        end  
    end
end

local function advanceTime(totalTopics)

    local minutesxTopic = config.advanceTime_minutesxtopic
    local maxConvTime = config.advanceTime_maxtime
    local advancedTime = (totalTopics * minutesxTopic) / 60

    local Endurance = tes3.mobilePlayer.endurance.current
    local currentFatigue = tes3.mobilePlayer.fatigue.current
    local maxFatigue = tes3.mobilePlayer.fatigue.base
    
    local recoveryRate = math.floor(2 + (0.02 * Endurance))
    local totalRecovery = totalTopics * minutesxTopic * recoveryRate

    local totalFatigue = currentFatigue + totalRecovery

    if totalFatigue > maxFatigue then
        totalFatigue = maxFatigue
    end

    if advancedTime > maxConvTime then
        advancedTime = maxConvTime
    end

    local gameHour = tes3.getGlobal('GameHour')
	gameHour = gameHour + advancedTime
    tes3.setGlobal('GameHour', gameHour)
    tes3.mobilePlayer.fatigue.current = totalFatigue
end

local function offendedGoodbye()
    local MenuPersuasion = tes3ui.findMenu(GUI_ID_MenuPersuasion)
    MenuPersuasion:destroy()
    timer.frame.delayOneFrame(function()
        tes3ui.showDialogueMessage({ text = "\nI don't want to hear another word! Leave me alone." })
        tes3.runLegacyScript{ command = 'Goodbye' }
    end)
end

local function checkPersuasion(npcRefe, idInfo)
    -- Check to see if it was a persuasion failure or success
    if failedPersuasionInfos[idInfo] then
        
        if config.debugEnabled then
            log:debug("PERSUASION CHECK: Detected a FAILED persuasion")
        end

        data.npcData[npcRefe.id].persuasionTotal = data.npcData[npcRefe.id].persuasionTotal - 1

        if config.limitedTopics then
            local remainingSlots = data.npcData[npcRefe.id].remainingSlots
            data.npcData[npcRefe.id].remainingSlots = remainingSlots - 1 
        end

        if  data.npcData[npcRefe.id].persuasionTotal < 1 then
            data.npcData[npcRefe.id].offended = true
            offendedGoodbye()  
        end
    elseif successfulPersuasionInfos[idInfo] then
        if config.debugEnabled then
            log:debug("PERSUASION CHECK: Detected a SUCCESSFUL persuasion")
        end
        if config.limitedTopics then
            local remainingSlots = data.npcData[npcRefe.id].remainingSlots
            data.npcData[npcRefe.id].remainingSlots = remainingSlots + config.topicsGainedPerPersuasionSuccess 
            if config.debugEnabled then
                log:debug(string.format("PERSUASION CHECK: Added %d new dialogue slot(s).", config.topicsGainedPerPersuasionSuccess))
            end
        end
    end
end

local function responseLoaded(e) 
    if config.debugEnabled then
        log:debug("PICKED A TOPIC: New topic selected")
    end

    math.randomseed( os.time() );
    local npcRefe = data.talkingTo
    local idInfo = e.info.id

    if config.debugEnabled then
        log:debug(string.format("PICKED A TOPIC: The ID of the topic is: %s", tostring(idInfo)))
    end

    -- This is used to calculate time later on, not for anything else. Do it before we check blacklist, to make sure we keep tab on time spent in dialogue even with blacklisted characters.
    data.amountTopics = data.amountTopics + 1
  
    -- If we add someone to the Blacklist mid conversation, it should still work.
    local npcName = npcRefe.object.name
    if config.blackList[npcName:lower()] then
        if config.debugEnabled then
            log:debug("PICKED A TOPIC: Exiting function due to BLACKLISTED NPC")
        end
        return
    end

    if npcRefe.mobile.actorType ~= tes3.actorType.npc then
        return
    end

    -- Check if we use the repetition setting (i.e., do we allow people to see the same topic again without using a slot)
    if config.repetition then
        if checkRepetition(npcRefe, idInfo) then
            if config.debugEnabled then
                log:debug("PICKED A TOPIC: Exiting function due to REPEATING TOPIC")
            end
            return
        end
    end

    if e.info.type == tes3.dialogueType.journal then 
        if config.limitedTopics then
            if data.npcData[npcRefe.id].remainingSlots < config.minimumTopics then
            -- It feels weird when an NPC dismisses the player right after they have said something so important that the player character writes in their journal.
                data.npcData[npcRefe.id].remainingSlots = config.minimumTopics
                if config.debugEnabled then
                    log:debug(string.format("PICKED A TOPIC: Too few remaning slots detected after journal entry, adding minimum topics"))
                    lod:debug("PICKED A TOPIC: Exiting function due to NOT A TOPIC")
                end
            end
        end
        return
    end

    timer.frame.delayOneFrame(function()
        local remainingSlots = data.npcData[npcRefe.id].remainingSlots

        -- If the player has a dialogue choice, do not count it towards remaining slots and do not end the dialogue if the NPC is tired of you
        local isAnswer = data.answerRound
        if isAnswer then
            data.answerRound = false
            --Compensate one to allow for the answer to also not count towards the slots
            data.npcData[npcRefe.id].remainingSlots = remainingSlots + 1
            if config.debugEnabled then
                log:debug("PICKED A TOPIC: Exiting function due to IN AN ANSWER ROUND")
            end
            return
        end

        if e.info.type ~= tes3.dialogueType.topic then 
            if e.info.type == tes3.dialogueType.service then 
                if config.persuasionLimit then
                    checkPersuasion(npcRefe, idInfo)
                end
            end
            if config.debugEnabled then
                log:debug("PICKED A TOPIC: Exiting function due to NOT A TOPIC")
            end
            return
        end

        local disposition = npcRefe.object.disposition
        local isFriend = disposition > config.friendDispositionLimit

        -- If we use the limited topics feature, then run through all steps needed for that
        if config.limitedTopics then
            remainingSlots = remainingSlots - 1
            data.npcData[npcRefe.id].remainingSlots = remainingSlots
            if (remainingSlots == 2) then
                timer.frame.delayOneFrame ( function()
                    tes3.messageBox(string.format("%s seems to be getting ready to leave", npcName))
                end)
            elseif (remainingSlots == 0) then
                npcRefe.object.baseDisposition = npcRefe.object.baseDisposition - 1
                local response = '\n\nNow, please, excuse me. I must go back to my own business.'
                if isFriend then
                    response = '\n\nI am sorry my friend, but I have to go back to my own business now.'
                end
                timer.frame.delayOneFrame ( function()
                    tes3ui.showDialogueMessage({ text = response })
                    tes3.runLegacyScript{ command = 'Goodbye' }
                end)
                if config.debugEnabled then
                    log:debug("PICKED A TOPIC: Exiting function due to OUT OF TOPIC SLOTS (normal)")
                end
                return
            elseif (remainingSlots < 0) then
                local lostDisposition = math.floor((remainingSlots/5)*-1) + 1
                npcRefe.object.baseDisposition = npcRefe.object.baseDisposition - lostDisposition
                local response = '\n\nPlease, do leave me alone now!'
                if isFriend then
                    response = '\n\nI am sorry, but I am tired, and I really don\'t feel like talking right now. Come back tomorrow and I will gladly discuss whatever you have on your mind.'
                end
                timer.frame.delayOneFrame ( function()
                    tes3ui.showDialogueMessage({ text = response })
                    tes3.runLegacyScript{ command = 'Goodbye' }
                end)
                if config.debugEnabled then
                    log:debug("PICKED A TOPIC: Exiting function due to OUT OF TOPIC SLOTS (less than 0)")
                end
                return
            end
        end

        -- If we use the disposition increase feature, calculate a random chance to see if we will increase disposition.
        if config.dispositionIncrease and remainingSlots > 0 then
            local chanceDispIncrease = math.random() + ((tes3.mobilePlayer.luck.current - 50) /200) + (tes3.mobilePlayer.speechcraft.current/200)
            if (chanceDispIncrease >= 1) then
                npcRefe.object.baseDisposition = npcRefe.object.baseDisposition + 1
            end
        end

        if config.speechcraftLeveling then
            -- Calculate amount to train speechcraft based on the speakers speechcraft level and the players intelligence
            local amountToTrainSpeechcraft = (npcRefe.mobile.speechcraft.current/300) * (tes3.mobilePlayer.intelligence.current/30) * (config.speechcraftTrainingRate/100)
            tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, amountToTrainSpeechcraft)
        end

        -- Everything about handling learning from others. This is off by default
        if config.classLearning then
            if e.info.npcClass ~= nil then
                local skill = learnSomething(npcRefe)
                if skill ~= false then
                    local responseBySpecialization = {
                        ['Combat'] = 'The way %s moves while speaking makes you think a few tricks that could improve your %s skill.',
                        ['Magic'] = 'Your conversation with %s has given you some insight on how %s works.',
                        ['Stealth'] = 'You watch %s\'s smoothness in conversation and it makes you think of a way to improve your technique in %s'
                    }
                    local spec = 'Magic'
                    if skill < 9 then 
                        spec = 'Combat' 
                    elseif skill > 16 then
                        spec = 'Stealth'
                    end
                    timer.frame.delayOneFrame(function()
                        tes3.messageBox(string.format(responseBySpecialization[spec], npcName, tes3.getSkillName(skill)))
                    end)
                end
            end
        end
        if config.debugEnabled then
            tes3.messageBox(string.format("Slots remaining %d", remainingSlots))
            log:debug(string.format("Slots remaining %d", remainingSlots))
        end
        if config.debugEnabled then
            log:debug("Exiting function due to: END OF FUNCTION")
        end
    end)
end

local function exitMenu(e)

    -- If we are not in a dialogue menu, don't run the code
    if not dialogMenu then 
        return 
    end

    if config.debugEnabled then
        log:debug("Now closing the dialogue menu")
    end


    local totalTopics = data.amountTopics
    local npcRefe = data.talkingTo

    -- If we should advance time, advance time based on amount of dialogues options chosen
    if config.advanceTime == true then
        if totalTopics ~= nil then
            advanceTime(totalTopics)
        end
    end

    if npcRefe ~= nil then
        if config.repetitionReset == 1 then
            refreshRepeatedTopicsList(npcRefe)
            if config.debugEnabled then
                log:debug("Reset repeated topics (at closing dialogue window)")
            end
        end
    end

    event.unregister(tes3.event.infoGetText, responseLoaded)
    event.unregister(tes3.event.infoResponse, checkResponse)
    event.unregister(tes3.event.menuExit, exitMenu)
    data.talkingTo = nil
    data.amountTopics = nil
    dialogMenu = nil
end

local function menuActivated(e)

    if config.modEnabled == false then
         return
     end

    local mobileActor = e.element:getPropertyObject("PartHyperText_actor")
    local npcRefe = mobileActor.reference

    data.talkingTo = npcRefe
    -- Used for time calculation later
    data.amountTopics = 0

    dialogMenu = e.element.id
    event.register(tes3.event.menuExit, exitMenu)
    event.register(tes3.event.infoResponse, checkResponse)
    event.register(tes3.event.infoGetText, responseLoaded)

    -- If the talking character is not an NPC don't run the code (would be weird if a Dagoth just started looking impatient and stop talking to you) - NOT TESTED
    if npcRefe.mobile.actorType ~= tes3.actorType.npc then
        return
    end

    -- If the NPC is blacklisted, don't run the code. By default all essential NPCs are on the blacklist to make sure no shennanigans happen with the main quest
    local npcName = npcRefe.object.name
    if config.blackList[npcName:lower()] then
        return
    end

    local npcDisposition = npcRefe.object.disposition
    local isFriend = npcDisposition > config.friendDispositionLimit 

    local weariedFriend = false
    if data.npcData[npcRefe.id] ~= nil then
        weariedFriend = data.npcData[npcRefe.id].weariedFriend
    end

    local dateToday = getTodaysDate()

    if config.debugEnabled then
        log:debug(string.format("The day today is: %s", dateToday.day))
        log:debug(string.format("The month today is: %s", dateToday.month))
        log:debug(string.format("The year today is: %s", dateToday.year))
    end

    math.randomseed( os.time() );

    -- Check if you have talked to the character today or not
    if (data.npcData[npcRefe.id] == nil or data.npcData[npcRefe.id].date.day ~= dateToday.day or data.npcData[npcRefe.id].date.month ~= dateToday.month or data.npcData[npcRefe.id].date.year ~= dateToday.year) then
        -- Set or reset data for the NPC if needed
        resetNpcAndCalculateTalkSlots(npcRefe, dateToday)
    end

    if data.npcData[npcRefe.id].offended ~= nil and config.debugEnabled then
        log:debug(string.format("Is %s offended?", npcRefe.object.name))
        log:debug(tostring(data.npcData[npcRefe.id].offended))
    end

    -- If we use persuasion limit, we check that first as it closes down the dialogue.
    if config.persuasionLimit then
        if data.npcData[npcRefe.id].offended then
            goAwayMessage = '\n\nI\'ve had enough of you today. Go away.'
            if isFriend then
                goAwayMessage = '\n\nLook, we may be friends, but you acted like an idiot today. Just leave me alone right now.'
            end
            timer.frame.delayOneFrame ( function()
                    tes3ui.showDialogueMessage({ text = goAwayMessage })
                    tes3.runLegacyScript{ command = 'Goodbye' }
                end) 
            return
        end
    end

    -- If we use the limited topics part of the mod, give some info based on the NPCs current patience
    if config.limitedTopics then
        local remainingSlots = data.npcData[npcRefe.id].remainingSlots
        
        if remainingSlots < 3 then
            local initialRead = string.format("%s looks impatient and probably will not want to speak much right now.", npcRefe.object.name)
            local beforeGreetingInitialResponse = nil
            --local afterGreetingInitialResponse = nil

            if isFriend then
                initialRead = string.format("Even though %s looks happy to see you, you notice their weariness. They will probably not want to speak much right now.", npcRefe.object.name)
                if weariedFriend then
                    --afterGreetingInitialResponse = string.format("\nHi %s. I really don't have time right now.", tes3.mobilePlayer.object.name)
                else
                    beforeGreetingInitialResponse = "I am a bit tired, but I will make some time for you.\n"
                    data.npcData[npcRefe.id].remainingSlots = config.minimumTopics
                    data.npcData[npcRefe.id].weariedFriend = true
                end
            end
            if beforeGreetingInitialResponse ~= nil then
                tes3ui.showDialogueMessage({text = beforeGreetingInitialResponse})
            end
            timer.frame.delayOneFrame(function()
                tes3.messageBox(initialRead)
                --if afterGreetingInitialResponse ~= nil then
                    --tes3ui.showDialogueMessage({text = afterGreetingInitialResponse})
                --end
            end)
        end
    end
end



local function initData()
    tes3.player.data.talkingMatters = tes3.player.data.talkingMatters or {}
    data = tes3.player.data.talkingMatters
    data.npcData = data.npcData or {}


    -- Documentation reference for the different dialogue pages
        --[[ dialogue pages:
        0: Info Refusal
        1: Admire Success
        2: Admire Fail
        3: Intimidate Success
        4: Intimidate Fail
        5: Taunt Success
        6: Taunt Fail
        7: Service Refusals
        8: Bribe Success
        9: Bribe Fail
    ]]

    local persuasionFailCollection = {
        ["dialogueAdmireFail"] = tes3.findDialogue({ type = 3, page = 2 }).info,
        ["dialogueIntimidateFail"] = tes3.findDialogue({ type = 3, page = 4 }).info,
        ["dialogueTauntFail"] = tes3.findDialogue({ type = 3, page = 6 }).info,
        ["dialogueBribeFail"] = tes3.findDialogue({ type = 3, page = 9 }).info,
    }
    for _, failCollection in pairs(persuasionFailCollection) do
        for _, info in pairs(failCollection) do
            failedPersuasionInfos[info.id] = true
        end
    end

    local persuasionSuccessCollection = {
        ["dialogueAdmireSuccess"] = tes3.findDialogue({ type = 3, page = 1 }).info,
        ["dialogueBribeSuccess"] = tes3.findDialogue({ type = 3, page = 8 }).info,
    }

    for _, successCollection in pairs(persuasionSuccessCollection) do
        for _, info in pairs(successCollection) do
            successfulPersuasionInfos[info.id] = true
        end
    end
end


-- Initialize when the game has loaded (new game or load saved game)
event.register(tes3.event.loaded, initData)

-- Set up the config file and Mod Configuration Menu (MCM)
event.register(tes3.event.modConfigReady, function()
    require("talkingMatters.mcm")
	config = require("talkingMatters.config").loaded
end)

-- Initialize Talking Matters (triggers on entering Main menu)
local function initialize(e)

    log.level = "DEBUG"
    log.includeTimestamp = true

    event.register(tes3.event.uiActivated, menuActivated, { filter = "MenuDialog" } )
    GUI_ID_MenuPersuasion = tes3ui.registerID("MenuPersuasion")

    event.unregister(tes3.event.initialized, initialize)
    print("[Talking Matters] initialized")
end
event.register(tes3.event.initialized, initialize)