local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Provides functionality to track and manage the history of conversations
---@class conversationHistoryController : initializedService
local this = {}

---@public
---@return boolean
function this.initialize()
	event.register(tes3.event.loaded, this.onLoaded)
	event.register(EVENTS.conversationEnded, this.onConversationEnded)
	return true
end

--- Checks if a conversation has already occurred
---@public
---@param configurationId string The ID of the conversation configuration to check
---@return boolean exists True if the conversation has occurred, false otherwise
function this.exists(configurationId)
	return tes3.player.data.conversationHistory[configurationId]
end

--- Clears the conversation history
---@public
function this.clear()
	logger:debug("Resetting conversation history...")
	tes3.player.data.conversationHistory = {}
end

--- Retrieves the entire conversation history
--- @public
--- @return { [conversationId]: boolean } conversationHistory The conversation history
function this.getAll()
	return tes3.player and tes3.player.data.conversationHistory or {}
end

--- Deletes a specific conversation from the history
--- @public
--- @param configurationId string The ID of the conversation configuration to delete
function this.delete(configurationId)
	logger:debug("Deleting conversation '%s' from history", configurationId)
	tes3.player.data.conversationHistory[configurationId] = nil
end

---@private
---@param _ loadedEventData
function this.onLoaded(_)
	logger:debug("Loading conversation history...")

	local data = tes3.player.data
	data.conversationHistory = data.conversationHistory or {}

	logger:debug("Loaded conversation history, found %d entries", table.size(data.conversationHistory))
end

---@private
---@param eventData conversationEndedEventData
function this.onConversationEnded(eventData)
	local configuration = eventData.conversation.configuration
	if not configuration.repeatable then
		this.add(configuration)
	end
end

---@private
---@param configuration conversationConfiguration
function this.add(configuration)
	logger:debug("Adding conversation '%s' (ID: '%s') to history", configuration.name, configuration.id)
	tes3.player.data.conversationHistory[configuration.id] = true
end

return this
