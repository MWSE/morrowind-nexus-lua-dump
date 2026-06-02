local configurationLoader = require("tauer.dynamic-conversations.services.configurations.configurationLoader")
local configurationFilterer = require("tauer.dynamic-conversations.services.configurations.configurationFilterer")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

--- Responsible for selecting the most appropriate conversation configuration from a list
---@class configurationSelector : initializedService
local this = {}

---@private
this.beta = math.log(2)

---@private
---@type conversationId|nil
this.lastConversationId = nil

---@public
---@return boolean
function this.initialize()
	event.register(EVENTS.conversationEnded, this.onConversationEnded)
	return true
end

--- Selects the highest priority conversation configuration from the provided list
---@public
---@param npcs tes3npcInstance[] The NPC candidates for conversations
---@return conversationConfiguration|nil configuration The selected conversation configuration or nil if none found
function this.select(npcs)
	local configurations = configurationLoader.getAll()

	local filtered = configurationFilterer.filter(configurations, npcs)
	if not filtered then
		return nil
	end

	local maxPriority = this.getMaxPriority(filtered)
	if not maxPriority then
		return this.pickRandom(filtered)
	end

	local scores, total = this.calculateScores(filtered, maxPriority)

	if total <= 0 then
		return this.pickRandom(filtered)
	end

	return this.weightedPick(filtered, scores, total)
end

---@private
---@param configurations conversationConfiguration[]
---@return number|nil
function this.getMaxPriority(configurations)
	local maxPriority = nil
	for _, configuration in ipairs(configurations) do
		if not this.isLastConversation(configuration) then
			local priority = configuration.priority and configuration.priority.value
			if priority and (not maxPriority or priority > maxPriority) then
				maxPriority = priority
			end
		end
	end
	return maxPriority
end

---@private
---@param configurations conversationConfiguration[]
---@return conversationConfiguration
function this.pickRandom(configurations)
	local size = table.size(configurations)
	local index = math.random(size)
	if this.isLastConversation(configurations[index]) then
		return configurations[(index % size) + 1]
	end
	return configurations[index]
end

---@private
---@param configuration conversationConfiguration
---@param maxPriority number
---@return number
function this.score(configuration, maxPriority)
	local priority = configuration.priority and configuration.priority.value or 0
	local weight = configuration.priority and configuration.priority.weight or 1

	weight = math.clamp(weight, 0, 1)
	return weight * math.exp(this.beta * (priority - maxPriority))
end

---@private
---@param configurations conversationConfiguration[]
---@param maxPriority number
---@return { integer: number }, number
function this.calculateScores(configurations, maxPriority)
	---@type { integer: number }
	local scores = {}
	---@type number
	local total = 0

	for i, configuration in ipairs(configurations) do
		if this.isLastConversation(configuration) then
			scores[i] = 0
		else
			local score = this.score(configuration, maxPriority)
			scores[i] = score
			total = total + score
		end
	end

	return scores, total
end

---@private
---@param configurations conversationConfiguration[]
---@param scores { integer: number }
---@param total number
---@return conversationConfiguration|nil
function this.weightedPick(configurations, scores, total)
	local r = math.random() * total
	local acc = 0
	local last = nil

	for i, configuration in ipairs(configurations) do
		acc = acc + scores[i]
		if r < acc then
			return configuration
		end
		last = configuration
	end

	return last
end

---@private
---@param configuration conversationConfiguration
function this.isLastConversation(configuration)
	return this.lastConversationId and configuration.id == this.lastConversationId
end

---@private
---@param eventData conversationEndedEventData
function this.onConversationEnded(eventData)
	this.lastConversationId = eventData.conversation.configuration.id
end

return this
