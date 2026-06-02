local npcFilterer = require("tauer.dynamic-conversations.services.npcs.npcFilterer")
local npcStateManager = require("tauer.dynamic-conversations.services.npcs.npcStateManager")
local npcAnimator = require("tauer.dynamic-conversations.services.npcs.NpcAnimator")
local dialogTemplateLoader = require("tauer.dynamic-conversations.services.dialog.dialogTemplateLoader")
local configurationLoader = require("tauer.dynamic-conversations.services.configurations.configurationLoader")
local configurationFilterer = require("tauer.dynamic-conversations.services.configurations.configurationFilterer")
local configurationValidator = require("tauer.dynamic-conversations.services.configurations.configurationValidator")
local conversationHistoryController =
	require("tauer.dynamic-conversations.services.conversations.conversationHistoryController")
local conversationScheduler = require("tauer.dynamic-conversations.services.conversations.conversationScheduler")
local animationTemplateLoader = require("tauer.dynamic-conversations.services.animations.animationTemplateLoader")
local conversationPreparer = require("tauer.dynamic-conversations.services.conversations.conversationPreparer")
local dialogueExchanger = require("tauer.dynamic-conversations.services.dialog.dialogExchanger")
local eventLogger = require("tauer.dynamic-conversations.services.events.eventLogger")
local conversationCircuitBreaker = require(
	"tauer.dynamic-conversations.services.conversations.conversationCircuitBreaker")
local conversationFinalizer = require(
	"tauer.dynamic-conversations.services.conversations.conversationFinalizer")
local configurationSelector = require("tauer.dynamic-conversations.services.configurations.configurationSelector")
local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")
local historyListView = require("tauer.dynamic-conversations.services.mcm.history.historyListView")
local historyDetailsView = require("tauer.dynamic-conversations.services.mcm.history.historyDetailsView")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmInitializer")

local logger = mwse.Logger.new()

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

---@class DynamicConversations
local this = {}

---@package
---@param _ modConfigReadyEventData
function this.initializeMcm(_)
	mcm.initialize()
end

---@package
---@param _ initializedEventData
function this.initializeMod(_)
	logger:info("Initializing...")

	---@type initializedService[]
	local services = {
		timerManager,

		npcFilterer,
		npcStateManager,
		npcAnimator,

		dialogTemplateLoader,
		animationTemplateLoader,

		configurationValidator,
		configurationLoader,
		configurationFilterer,
		configurationSelector,

		conversationScheduler,
		conversationPreparer,
		conversationCircuitBreaker,
		conversationFinalizer,
		conversationHistoryController,

		dialogueExchanger,

		historyListView,
		historyDetailsView,

		eventLogger
	}

	for _, service in ipairs(services) do
		local initialized = service.initialize()
		if not initialized then
			logger:error("Initialization failed!")
			return
		end
	end

	logger:info("Initialized.")
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
