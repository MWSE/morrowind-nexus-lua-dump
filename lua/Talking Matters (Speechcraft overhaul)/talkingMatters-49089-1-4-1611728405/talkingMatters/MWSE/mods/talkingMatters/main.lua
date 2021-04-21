local talkativeness = require("talkingMatters.talkativeness")
local data
local config
local dialogMenu
local GUI_ID_MenuPersuasion
local failedPersuasionInfos = {}
local successfulPersuasionInfos = {}

local function checkRepetition(npcRefe, idInfo)
    local infoSpokenAbout = data.npcData[npcRefe.id].info
    if infoSpokenAbout == nil then
        data.npcData[npcRefe.id].info = {}

    else
        for _, info in pairs(infoSpokenAbout) do
            if info == idInfo then
                return true
            end
        end
    end

    table.insert(data.npcData[npcRefe.id].info, idInfo)
    return false
end

local function refreshRepeatedTopicsList(npcRefe)
    data.npcData[npcRefe.id].info = nil
end

local function calculateTalkSlots(character, dateToday) 

    local registeredCharacter = data.npcData[character.id]
    local pClass = tes3.player.object.class.id
    local pSpeechcraft = tes3.mobilePlayer.speechcraft.current
    local pFatiga = tes3.mobilePlayer.fatigue.normalized

    local slotsBase = (pSpeechcraft / 10) * pFatiga
    slotsBase = (math.floor(slotsBase+0.5))

    local class = character.object.class.id
    local npcDisposition = character.object.disposition

    if (npcDisposition > 100) then
        npcDisposition = 100
    end

    local classModif = talkativeness[class]
    local npcFaction = character.object.faction

    --tes3ui.logToConsole(string.format("Clase = %s", pClass))
    --tes3ui.logToConsole(string.format("Clase = %s", class))    
    
    if string.find(class, 'Service') then
        classModif = 2
        class = class:gsub(" Service", "")
    elseif not classModif then
        classModif = 1
    end

    local contextSlots = 0

    if pClass == class then
        contextSlots = contextSlots + 3
        data.colleague = true
    else
        data.colleague = false
    end
    if (npcFaction ~= nil) and (npcFaction.playerJoined == true) then
        contextSlots = contextSlots + npcFaction.playerRank + 1
    end 

    local npcSpeech = character.mobile.speechcraft.current

    local slotsRelativos = (npcDisposition - 50) /5 + classModif * ( npcSpeech/10 ) + contextSlots

    local totalSlots = (math.floor(slotsBase + slotsRelativos)) 
    local minSlots = config.minimumTopics
    if totalSlots < minSlots then
        totalSlots = minSlots
    end
    local remainingSlots = totalSlots
    --tes3ui.logToConsole(string.format("Total slots: %s", totalSlots))

    local dateLastSpoken = ''
    if data.npcData[character.id] ~= nil then
        dateLastSpoken = data.npcData[character.id].date
    end

    data.npcData[character.id] = {
        ["persuasionTotal"] = 3,
        ["remainingSlots"] = remainingSlots,
        ["date"] = dateToday,
        ["offended"] = false
    }

    --tes3ui.logToConsole(string.format("Date last spoken = %s", data.npcData[character.id].date))
    --tes3ui.logToConsole(string.format("Month last spoken = %s", string.sub(dateLastSpoken, 4, 5)))

    if (config.repetitionReset == 2 and dateLastSpoken ~= dateToday) or (config.repetitionReset == 3 and Month ~= string.sub(dateLastSpoken, 4, 5)) then
        
        refreshRepeatedTopicsList(character)
    end
end

local function learnSomething(npcRefe)

    local class = npcRefe.object.class
    local pIntelligence = tes3.mobilePlayer.intelligence.current

    if pIntelligence < 60 and data.colleague == true then 
        return false
    end
    
    local skills = class.majorSkills
    local value = math.random(1,#skills)
    local trainedSkill = skills[value]
    local trainedSkillName = tes3.getSkill(trainedSkill)

    local pSkill = tes3.mobilePlayer:getSkillValue(trainedSkill)
    local npcSkill = npcRefe.mobile:getSkillValue(trainedSkill)

    local chanceOfLearning = math.random() * pIntelligence / 40

    --tes3.messageBox(string.format("Chance of learning: %d", chanceOfLearning))

    if chanceOfLearning < 1 then return false 
    else

        local amountSkillIncrease = npcSkill/20
        tes3.mobilePlayer:exerciseSkill(trainedSkill, amountSkillIncrease)
        return trainedSkill
    end
    
end

local function checkResponse(e)

    local command = e.command
    local npcRefe = data.talkingTo

    --tes3.messageBox(string.format("command: %s", command));

    if (string.match(command, "Choice") or string.match(command, "Goodbye")) then
        --tes3ui.logToConsole(string.format("SETEADO ANSWER"))
        data.answerRound = true
    end

end

local function advanceTime(totalTopics)

    local minutesxTopic = config.advanceTime_minutesxtopic
    local maxConvTime = config.advanceTime_maxtime
    local advancedTime = totalTopics * minutesxTopic / 60 

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
        tes3.runLegacyScript{ command = 'Goodbye' }
    end)
end

local function checkPersuasion(npcRefe, idInfo)

    if failedPersuasionInfos[idInfo] then
        --tes3ui.logToConsole(string.format("detectado fail!"))
        data.npcData[npcRefe.id].persuasionTotal = data.npcData[npcRefe.id].persuasionTotal - 1

        if  data.npcData[npcRefe.id].persuasionTotal < 1 then
            data.npcData[npcRefe.id].offended = true

            offenseTimer = timer.start {
                type = timer.real,
                duration = 0.1,
                callback = offendedGoodbye
            }                    

        end
    elseif successfulPersuasionInfos[idInfo] then
        --tes3ui.logToConsole(string.format("detectado success!"))
        local remainingSlots = data.npcData[npcRefe.id].remainingSlots
        data.npcData[npcRefe.id].remainingSlots = remainingSlots + 1 
    end

end

local function topicSelected(e) 
    timer.frame.delayOneFrame(function()
        local npcRefe = data.talkingTo
        local remainingSlots = data.npcData[npcRefe.id].remainingSlots
        local idInfo = e.info.id
            
        if e.info.type ~= 0 then 
            if e.info.type == 4 then 
                data.npcData[npcRefe.id].remainingSlots = remainingSlots + 1
            end
            if e.info.type == 3 then 
                if data.npcData[npcRefe.id].persuasionTotal == nil then --this piece of data wasn't around before, so I'm declaring it here to make this "backwards compatible" for a while
                    data.npcData[npcRefe.id].persuasionTotal = 3
                    data.npcData[npcRefe.id].offended = false
                end
                if config.persuasionLimit then
                    checkPersuasion(npcRefe, idInfo)
                end
            end
            return 
        end


        data.amountTopics = data.amountTopics + 1

        local isAnswer = data.answerRound
        --tes3ui.logToConsole(string.format("LEIDO ANSWER"))

        if isAnswer then
            data.answerRound = false
            return
        end

        local npcName = npcRefe.object.name
        if config.blackList[npcName:lower()] then
            --tes3ui.logToConsole(string.format("Blacklisted npc!"))
            return
        end

        --tes3ui.logToConsole(string.format("Topics talked: %s", data.amountTopics))

        if config.repetition == true then
            --tes3ui.logToConsole(string.format("Checking repetition"))
            if checkRepetition(npcRefe, idInfo) then
                --tes3ui.logToConsole(string.format("Topic repeats"))
                return
            end
        end

        local disposition = npcRefe.object.disposition
        local npcFaction = npcRefe.object.faction
        local npcRank = npcRefe.object.factionRank
        remainingSlots = remainingSlots - 1
        data.npcData[npcRefe.id].remainingSlots = remainingSlots

        --tes3ui.logToConsole(string.format("%s", npcFaction))
        --tes3ui.logToConsole(string.format("%s", npcRank))

    
        if config.limitedTopics then
            if (remainingSlots == 0) and (not isAnswer) then
                --e.text = string.format('%s%s', e:loadOriginalText(), '\n\nNow, please, excuse me. I must go back to my own business.')
                npcRefe.object.baseDisposition = npcRefe.object.baseDisposition - 1
                timer.frame.delayOneFrame(function()
                    tes3ui.showDialogueMessage({ text = '\n\nNow, please, excuse me. I must go back to my own business.' })
                    tes3.runLegacyScript{ command = 'Goodbye' }
                end)
                return

            elseif (remainingSlots == 2) then
                timer.frame.delayOneFrame(function()
                    tes3.messageBox(string.format("[%s seems to be getting ready to leave]", npcName))
                end)        
            
            elseif (remainingSlots < 0) then

                local lostDisposition = math.floor((remainingSlots/5)*-1) + 1
                npcRefe.object.baseDisposition = npcRefe.object.baseDisposition - lostDisposition
                --[[
                if tes3.getFaction(npcFaction).ranks[npcRank] > 7 then -- and npcFaction.id ~= tes3.getFaction('Blades') then

                    tes3.messageBox(string.format("[%s]", npcFaction.id))
                    if (lostDisposition * (math.random() - 0.5)) > 1 then
                        data.npcData[npcRefe.id].offended = true;
                        timer.frame.delayOneFrame(function()
                            tes3ui.showDialogueMessage({ text = '\n\nI have to go, now. Right now.' })
                            tes3.runLegacyScript{ command = 'Goodbye' }
                        end)
                    end
                end]]
            end
        end


        if config.dispositionIncrease and remainingSlots > 0 then
            local chanceDispIncrease = (math.random() + (tes3.mobilePlayer.luck.current - 50) /100) + (tes3.mobilePlayer.speechcraft.current/100)

            if (chanceDispIncrease >= 1) then
                npcRefe.object.baseDisposition = npcRefe.object.baseDisposition + 1
            end

        end

        if config.speechcraftLeveling then
            local npcSpeech = npcRefe.mobile.speechcraft.current
            local pIntelligence = tes3.mobilePlayer.intelligence.current
            local amountSpeechIncrease = (npcSpeech/300) * (pIntelligence/30)

            tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, amountSpeechIncrease)
        end


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
        --tes3.messageBox(string.format("Slots restantes %d", remainingSlots))
    end)
end

local function menuActivado(e)

    dialogMenu = e.element.id
    if config.modEnabled == false then return end

    local mobileActor = e.element:getPropertyObject("PartHyperText_actor")
    --local actor = mobileActor.reference.object.baseObject
    local npcRefe = mobileActor.reference

    data.talkingTo = npcRefe
    data.amountTopics = 0
    local npcDisposition = npcRefe.object.disposition
    local isFriend = npcDisposition > 85 

    local Day = tes3.getGlobal("Day")
    local Month = tes3.getGlobal("Month")
    local Year = tes3.getGlobal("Year")

    local dateToday = string.format("%d-%d-%d", Day, Month, Year)
    
    if ((data.npcData[npcRefe.id] == nil) or (data.npcData[npcRefe.id].date ~= dateToday)) then
        calculateTalkSlots(npcRefe, dateToday)
    else 
        local remainingSlots = data.npcData[npcRefe.id].remainingSlots
        if remainingSlots < 3 then
            if isFriend then
                --data.npcData[npcRefe.id].remainingSlots = 4
            else 
                timer.frame.delayOneFrame(function()
                    tes3.messageBox(string.format("%s looks impatient and probably will not want to speak much right now.", npcRefe.object.name))
                end)
            end
        end
    end

    if config.persuasionLimit then
        if data.npcData[npcRefe.id].offended then
            goAwayMessage = '\n\nI\'ve had enough of you today. Go away.'
            if isFriend then
                goAwayMessage = '\n\nLook, we may be friends, but you acted like an idiot today. Just leave me alone right now.'
            end
            offenseTimer = timer.start {
                type = timer.real,
                duration = 0.1,
                callback = (function()
                    tes3ui.showDialogueMessage({ text = goAwayMessage })
                    --data.npcData[npcRefe.id].persuasionTotal = data.npcData[npcRefe.id].persuasionTotal - 1
                    tes3.runLegacyScript{ command = 'Goodbye' }
                end)
            }  
        end
    end

    event.register("infoResponse", checkResponse)
    event.register("infoGetText", topicSelected)

end

local function salirMenu(e)

    if not dialogMenu then return end

    local totalTopics = data.amountTopics
    local npcRefe = data.talkingTo

    if config.advanceTime == true then
        if totalTopics ~= nil then
            advanceTime(totalTopics)
        end
    end

    if npcRefe ~= nil then
        if config.repetitionReset == 1 then
            refreshRepeatedTopicsList(npcRefe)
        end
    end

    event.unregister("infoGetText", topicSelected)
    event.unregister("infoResponse", checkResponse)
    data.talkingTo = nil
    data.amountTopics = nil
   
end

local function initData()

    print("Talking Matters data initialized")
    tes3.player.data.talkingMatters = tes3.player.data.talkingMatters or {}
    data = tes3.player.data.talkingMatters
    data.npcData = data.npcData or {}


        --[[ dialogue pages:
        0: Info Refusal
        1: Admire Success
        2: Admire Fail
        3: Intimidate Success
        4: Intimidate Fail
        5: Taunt Success
        6: Taunt Fail
        7: Service Refusal
        8: Bribe Success
        9: Bribe Fail
    ]]

    local persuasionFailCollection = {
        ['dialogueAdmireFail'] = tes3.findDialogue({ type = 3, page = 2 }).info,
        ['dialogueIntimidateFail'] = tes3.findDialogue({ type = 3, page = 4 }).info,
        ['dialogueTauntFail'] = tes3.findDialogue({ type = 3, page = 6 }).info,
        ['dialogueBribeFail'] = tes3.findDialogue({ type = 3, page = 9 }).info,
    }
    for _, failCollection in pairs(persuasionFailCollection) do
        for _, info in pairs(failCollection) do
            failedPersuasionInfos[info.id] = true
        end
    end

    local persuasionSuccessCollection = {
        ['dialogueAdmireSuccess'] = tes3.findDialogue({ type = 3, page = 1 }).info,
        ['dialogueBribeSuccess'] = tes3.findDialogue({ type = 3, page = 8 }).info,
    }
    for _, successCollection in pairs(persuasionSuccessCollection) do
        for _, info in pairs(successCollection) do
            successfulPersuasionInfos[info.id] = true
        end
    end
    

end
event.register("loaded", initData)

event.register("modConfigReady", function()
    require("talkingMatters.mcm")
	config = require("talkingMatters.config")
end)


local function initializeST(e)

    event.register("uiActivated", menuActivado, { filter = "MenuDialog" } )
    event.register("menuExit", salirMenu )   
    GUI_ID_MenuPersuasion = tes3ui.registerID("MenuPersuasion") 
    print("[Talking Matters] initialized")

    math.randomseed( os.time() );

end
event.register("initialized", initializeST)

