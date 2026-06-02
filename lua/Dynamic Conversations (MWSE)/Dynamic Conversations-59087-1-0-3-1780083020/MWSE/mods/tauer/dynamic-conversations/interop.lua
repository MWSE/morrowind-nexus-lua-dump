local configurationLoader = require("tauer.dynamic-conversations.services.configurations.configurationLoader")
local npcClassifier = require("tauer.dynamic-conversations.services.npcs.npcClassifier")
local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")

local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

--- Provides interop functions for other mods to interact with Dynamic Conversations
---@class dynamicConversationsInterop
local this = {}

--- Start a conversation between two NPCs using a specified configuration file
---@public
---@param params startConversationInteropParams Parameters for starting the conversation
---@see startConversationInteropParams
function this.startConversation(params)
    if not params then
        logger:error("No parameters provided for starting conversation")
        return
    end

    local configurationPath = params.configurationPath
    local firstParticipant = params.firstParticipant
    local secondParticipant = params.secondParticipant

    if not configurationPath then
        logger:error("No configurationPath provided for starting conversation")
        return
    end

    if not firstParticipant or not secondParticipant then
        logger:error("Both firstParticipant and secondParticipant must be provided to start a conversation")
        return
    end

    local configuration = configurationLoader.loadConfiguration(configurationPath)
    if not configuration then
        logger:error("Failed to load configuration '%s'", configurationPath)
        return
    end

    if not this.validate(configuration, firstParticipant, secondParticipant) then
        return
    end

    event.trigger(EVENTS.conversationInteropStarted)

    ---@type conversationScheduledEventData
    local payload = {
        conversation = {
            configuration = configuration,
            firstParticipant = firstParticipant,
            secondParticipant = secondParticipant,
        }
    }
    event.trigger(EVENTS.conversationScheduled, payload)
end

---@private
---@param configuration conversationConfiguration
---@param firstParticipant tes3npcInstance
---@param secondParticipant tes3npcInstance
---@return boolean
function this.validate(configuration, firstParticipant, secondParticipant)
    local participants = configuration.participants
    if participants then
        if not arrays.contains(participants, firstParticipant.baseObject.name) then
            logger:error("First participant '%s' is not valid for this conversation", firstParticipant.baseObject.name)
            return false
        end

        if not arrays.contains(participants, secondParticipant.baseObject.name) then
            logger:error("Second participant '%s' is not valid for this conversation", secondParticipant.baseObject.name)
            return false
        end
    end

    local raceAndSex = configuration.conditions and configuration.conditions.raceAndSex
    if raceAndSex then
        local firstRace = npcClassifier.getRace(firstParticipant)
        local firstSex = npcClassifier.getSex(firstParticipant)

        if not arrays.contains(raceAndSex, string.format("%s %s", firstRace, firstSex)) then
            logger:error("First participant '%s' is not valid for this conversation", firstParticipant.baseObject.name)
            return false
        end

        local secondRace = npcClassifier.getRace(secondParticipant)
        local secondSex = npcClassifier.getSex(secondParticipant)

        if not arrays.contains(raceAndSex, string.format("%s %s", secondRace, secondSex)) then
            logger:error("Second participant '%s' is not valid for this conversation", secondParticipant.baseObject.name)
            return false
        end
    end

    return true
end

return this
