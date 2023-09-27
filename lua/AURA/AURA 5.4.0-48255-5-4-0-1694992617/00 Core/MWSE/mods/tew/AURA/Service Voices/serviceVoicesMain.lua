local serviceVoicesData = require("tew.AURA.Service Voices.serviceVoicesData")
local config = require("tew.AURA.config")
local common = require("tew.AURA.common")

local UI_VOLUME_MULTIPLIER = 0.2

local moduleUI = config.moduleUI

local raceNames = serviceVoicesData.raceNames
local commonVoices = serviceVoicesData.commonVoices
local travelVoices = serviceVoicesData.travelVoices
local spellVoices = serviceVoicesData.spellVoices
local trainingVoices = serviceVoicesData.trainingVoices

local UISpells = config.UISpells

local debugLog = common.debugLog

local lastVoice = "init"

local function getServiceVoiceData(e, voiceData)
	local npcId = tes3ui.getServiceActor(e)
	local raceId = npcId.object.race.id
	local raceLet = raceNames[raceId]
	local sexLet = npcId.object.female and "f" or "m"

	return voiceData[raceLet] and voiceData[raceLet][sexLet]
end

local function playServiceVoice(npcId, raceLet, sexLet, serviceFeed)
	if #serviceFeed > 0 then
		local newVoice
		if #serviceFeed > 1 then
			repeat
				newVoice = serviceFeed[math.random(1, #serviceFeed)]
			until newVoice ~= lastVoice
		else
			newVoice = serviceFeed[1]
		end

		tes3.removeSound { reference = npcId }
		tes3.say {
			volume = config.volumes.misc.SVvol / 100,
			soundPath = string.format("Vo\\%s\\%s\\%s.mp3", raceLet, sexLet, newVoice),
			reference = npcId
		}
		lastVoice = newVoice
		debugLog("NPC says a comment for the service.")
	end
end

local function handleServiceGreet(e, voiceData, flag, closeButtonName, playMysticGateSound, playMenuClickSound)
	local closeButton = e.element:findChild(tes3ui.registerID(closeButtonName))
	if closeButton then
		closeButton:register("mouseDown", function()
			if playMenuClickSound then
				tes3.playSound { sound = "Menu Click", reference = tes3.player }
			end
		end)
	end

	local npcId = tes3ui.getServiceActor(e)
	if not (npcId) or (npcId and not npcId.race) then return end
	local raceId = npcId.object.race.id
	local raceLet = raceNames[raceId]
	local sexLet = npcId.object.female and "f" or "m"

	local serviceFeed = getServiceVoiceData(e, voiceData) or {}

	playServiceVoice(npcId, raceLet, sexLet, serviceFeed)

	debugLog("NPC says a comment for the service.")

	if playMysticGateSound and UISpells and moduleUI then
		tes3.playSound { soundPath = "FX\\MysticGate.wav", reference = tes3.player, volume = UI_VOLUME_MULTIPLIER * config.volumes.misc.UIvol / 100, pitch = 1.8 }
		debugLog("Opening spell menu sound played.")
	end
end

local function registerGreetEvent(params)
	local serviceFlag = params.serviceFlag
	local greetFunction = params.greetFunction
	local filter = params.filter
	local closeButtonName = params.closeButtonName
	local playMysticGateSound = params.playMysticGateSound
	local playMenuClickSound = params.playMenuClickSound

	if config[serviceFlag] then
		event.register("uiActivated", function(e)
			handleServiceGreet(e, greetFunction, serviceFlag, closeButtonName, playMysticGateSound, playMenuClickSound)
		end, { filter = filter, priority = -10 })
	end
end

local function playCommentForService(params)
	local serviceFlag = params.serviceFlag
	local greetFunction = params.greetFunction
	local filter = params.filter
	local closeButtonName = params.closeButtonName
	local playMysticGateSound = params.playMysticGateSound
	local playMenuClickSound = params.playMenuClickSound
	local chanceToPlay = params.chanceToPlay or 100

	if math.random(1, 100) <= chanceToPlay then
		registerGreetEvent({
			serviceFlag = serviceFlag,
			greetFunction = greetFunction,
			filter = filter,
			closeButtonName = closeButtonName,
			playMysticGateSound = playMysticGateSound,
			playMenuClickSound = playMenuClickSound,
		})
	end
end

playCommentForService({
	serviceFlag = "serviceTravel",
	greetFunction = travelVoices,
	filter = "MenuServiceTravel",
	playMenuClickSound = true
})

playCommentForService({
	serviceFlag = "serviceBarter",
	greetFunction = commonVoices,
	filter = "MenuBarter",
	playMenuClickSound = true
})

playCommentForService({
	serviceFlag = "serviceTraining",
	greetFunction = trainingVoices,
	filter = "MenuServiceTraining",
	closeButtonName = "MenuServiceTraining_Okbutton",
	playMenuClickSound = true
})

playCommentForService({
	serviceFlag = "serviceEnchantment",
	greetFunction = commonVoices,
	filter = "MenuEnchantment",
	playMenuClickSound = true
})

playCommentForService({
	serviceFlag = "serviceSpellmaking",
	greetFunction = spellVoices,
	filter = "MenuSpellmaking",
	closeButtonName = "MenuSpellmaking_Cancelbutton",
	playMenuClickSound = true
})

playCommentForService({
	serviceFlag = "serviceSpells",
	greetFunction = spellVoices,
	filter = "MenuServiceSpells",
	closeButtonName = "MenuServiceSpells_Okbutton",
	playMysticGateSound = true,
	playMenuClickSound = true
})

playCommentForService({
	serviceFlag = "serviceRepair",
	greetFunction = commonVoices,
	filter = "MenuServiceRepair",
	closeButtonName = "MenuServiceRepair_Okbutton",
	playMenuClickSound = true
})
