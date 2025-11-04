--Initialize------------------------------------------------------------------------------------------------
local config = require("messageBox.config")
local log = mwse.Logger.new()
log.level = config.logLevel
local box = require("messageBox.box")
local func = require("messageBox.common")


local function initialized(e)
    log:info("Initialized.")
end

event.register("initialized", initialized)
-------------------------------------------------------------------------------------------------------------




----------
--Events------------------------------------------------------------------------------------------------
----------

local function onLoad()
	if not tes3ui.findMenu("kl_msgBox_menu") then
		box.createBox()
	end
end
event.register("loaded", onLoad)


event.register("uiActivated", function(e)
	local elem = e.element
	log:trace("MenuNotify1 triggered.")
	log:debug("Text: " .. elem.text .. "")
	if elem.text and elem.text ~= "" then
		box.logMessage(elem.text)
	end
	for i = 1, #elem.children do
		local child = elem.children[i]
		log:debug("Childi " .. i .. ": " .. child.text .. "")
		if child.text and child.text ~= "" then
			box.logMessage(child.text)
		end
		if child.children ~= nil then
			for n = 1, #child.children do
				local smolChild = child.children[n]
				log:debug("Childn " .. n .. ": " .. smolChild.text .. "")
				if smolChild.text and smolChild.text ~= "" then
					box.logMessage(smolChild.text)
				end
				if smolChild.children ~= nil then
					for t = 1, #smolChild.children do
						local tinyChild = smolChild.children[t]
						log:debug("Childt " .. t .. ": " .. tinyChild.text .. "")
						if tinyChild.text and tinyChild.text ~= "" then
							box.logMessage(tinyChild.text)
						end
					end
				end
			end
		end
	end
	if not config.notify then
		elem.visible = false
	end

end, { filter = "MenuNotify1" })


event.register("uiActivated", function(e)
	local elem = e.element
	log:trace("MenuNotify2 triggered.")
	log:debug("Text: " .. elem.text .. "")
	if elem.text and elem.text ~= "" then
		box.logMessage(elem.text)
	end
	for i = 1, #elem.children do
		local child = elem.children[i]
		log:debug("Childi " .. i .. ": " .. child.text .. "")
		if child.text and child.text ~= "" then
			box.logMessage(child.text)
		end
		if child.children ~= nil then
			for n = 1, #child.children do
				local smolChild = child.children[n]
				log:debug("Childn " .. n .. ": " .. smolChild.text .. "")
				if smolChild.text and smolChild.text ~= "" then
					box.logMessage(smolChild.text)
				end
				if smolChild.children ~= nil then
					for t = 1, #smolChild.children do
						local tinyChild = smolChild.children[t]
						log:debug("Childt " .. t .. ": " .. tinyChild.text .. "")
						if tinyChild.text and tinyChild.text ~= "" then
							box.logMessage(tinyChild.text)
						end
					end
				end
			end
		end
	end
	if not config.notify then
		elem.visible = false
	end
end, { filter = "MenuNotify2" })


event.register("uiActivated", function(e)
	local elem = e.element
	log:trace("MenuNotify3 triggered.")
	log:debug("Text: " .. elem.text .. "")
	if elem.text and elem.text ~= "" then
		box.logMessage(elem.text)
	end
	for i = 1, #elem.children do
		local child = elem.children[i]
		log:debug("Childi " .. i .. ": " .. child.text .. "")
		if child.text and child.text ~= "" then
			box.logMessage(child.text)
		end
		if child.children ~= nil then
			for n = 1, #child.children do
				local smolChild = child.children[n]
				log:debug("Childn " .. n .. ": " .. smolChild.text .. "")
				if smolChild.text and smolChild.text ~= "" then
					box.logMessage(smolChild.text)
				end
				if smolChild.children ~= nil then
					for t = 1, #smolChild.children do
						local tinyChild = smolChild.children[t]
						log:debug("Childt " .. t .. ": " .. tinyChild.text .. "")
						if tinyChild.text and tinyChild.text ~= "" then
							box.logMessage(tinyChild.text)
						end
					end
				end
			end
		end
	end
	if not config.notify then
		elem.visible = false
	end

end, { filter = "MenuNotify3" })


event.register("uiActivated", function(e)
	local elem = e.element
	log:trace("MenuMessage triggered.")
	log:debug("Text: " .. elem.text .. "")
	if elem.text and elem.text ~= "" and not elem.widget then
		box.logMessage(elem.text, { config.lastRed, config.lastGreen, config.lastBlue })
	end
	for i = 1, #elem.children do
		local child = elem.children[i]
		log:debug("Childi " .. i .. ": " .. child.text .. "")
		if child.text and child.text ~= "" and not child.widget then
			box.logMessage(child.text, { config.lastRed, config.lastGreen, config.lastBlue })
		end
		if child.children ~= nil then
			for n = 1, #child.children do
				local smolChild = child.children[n]
				log:debug("Childn " .. n .. ": " .. smolChild.text .. "")
				if smolChild.text and smolChild.text ~= "" and not smolChild.widget then
					box.logMessage(smolChild.text, { config.lastRed, config.lastGreen, config.lastBlue })
				end
				if smolChild.children ~= nil then
					for t = 1, #smolChild.children do
						local tinyChild = smolChild.children[t]
						log:debug("Childt " .. t .. ": " .. tinyChild.text .. "")
						if tinyChild.text and tinyChild.text ~= "" and not tinyChild.widget then
							box.logMessage(tinyChild.text, { config.lastRed, config.lastGreen, config.lastBlue })
						end
					end
				end
			end
		end
	end

end, { filter = "MenuMessage" })

--Toggle box on/off.
event.register(tes3.event.keyDown, function(e)
	if e.keyCode ~= config.boxBind.keyCode then return end

	if not tes3ui.findMenu("kl_msgBox_menu") then
		if tes3.player then
			box.createBox()
		else
			log:debug("No player ref. Message Box suppressed.")
			return
		end
	else
		if box.menu.visible then
			box.menu.visible = false
			box.modData.visible = false
		else
			box.time = 0
			box.menu.visible = true
			box.modData.visible = true
			box.menu:updateLayout()
		end
	end
end)


----------
--Logging---------------------------------------------------------------------------------------
----------

local function onCellChanged(e)
	if config.cellLog then
		if not e.previousCell then return end
		if e.cell.displayName ~= e.previousCell.displayName then
			if e.cell.isInterior then
				if e.previousCell.isInterior then
					box.logMessage("" .. func.i18n("msgBox.cellLog.continue") .. " " .. e.cell.displayName .. ".", { config.cellRed, config.cellGreen, config.cellBlue })
				else
					box.logMessage("" .. func.i18n("msgBox.cellLog.enter") .. " " .. e.cell.displayName .. "...", { config.cellRed, config.cellGreen, config.cellBlue })
				end
			else
				if e.previousCell.isInterior then
					box.logMessage("" .. func.i18n("msgBox.cellLog.exit") .. " " .. e.cell.displayName .. "...", { config.cellRed, config.cellGreen, config.cellBlue })
				else
					box.logMessage("" .. func.i18n("msgBox.cellLog.continue") .. " " .. e.cell.displayName .. ".", { config.cellRed, config.cellGreen, config.cellBlue })
				end
			end
		end
	end
end
event.register("cellChanged", onCellChanged)

local function onDamaged(e)
	if config.dmgLog then
		if e.source == "attack" then
			if e.attacker then
				if e.attacker == tes3.mobilePlayer or e.mobile == tes3.mobilePlayer then
					box.logMessage("" .. e.attacker.object.name .. " " .. func.i18n("msgBox.dmgLog.attacks") .. " " .. e.mobile.object.name .. " " .. func.i18n("msgBox.dmgLog.for") .. " " .. math.round(e.damage) .. " " .. tes3.findGMST(tes3.gmst.sDamage).value .. ".", { config.dmgRed, config.dmgGreen, config.dmgBlue })
				end
			end
		elseif e.source == "fall" then
			box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.dmgLog.hitTheGround") .. " " .. func.i18n("msgBox.dmgLog.for") .. " " .. math.round(e.damage) .. " " .. tes3.findGMST(tes3.gmst.sDamage).value .. ".", { config.dmgRed, config.dmgGreen, config.dmgBlue })
		end
	end
end
event.register("damaged", onDamaged)

local function onH2H(e)
	if config.dmgLog and e.source == "attack" then
		if e.attacker then
			if e.attacker == tes3.mobilePlayer or e.mobile == tes3.mobilePlayer then
				box.logMessage("" .. e.attacker.object.name .. " " .. func.i18n("msgBox.dmgLog.strikes") .. " " .. e.mobile.object.name .. " " .. func.i18n("msgBox.dmgLog.for") .. " " .. math.round(e.fatigueDamage) .. " " .. tes3.findGMST(tes3.gmst.sFatigue).value .. ".", { config.dmgRed, config.dmgGreen, config.dmgBlue })
			end
		end
	end
end
event.register(tes3.event.damagedHandToHand, onH2H)

local function onDeath(e)
	if config.deathLog then
		box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.deathLog.dies") .. "", { config.dedRed, config.dedGreen, config.dedBlue })
	end
end
event.register("death", onDeath)

local function onResist(e)
	if config.resistLog then
		if e.source.name then
			box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.resistLog.resisted") .. " " .. e.source.name .. "!", { config.resRed, config.resGreen, config.resBlue })
		end
	end
end
event.register("spellResisted", onResist)

--- @param e magicReflectedEventData
local function magicReflectedCallback(e)
	if config.resistLog then
		if e.source.name then
			box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.resistLog.reflected") .. " " .. e.source.name .. "!", { config.resRed, config.resGreen, config.resBlue })
		else
			box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.resistLog.reflectedSpell") .. "", { config.resRed, config.resGreen, config.resBlue })
		end
	end
end
event.register(tes3.event.magicReflected, magicReflectedCallback)

--- @param e absorbedMagicEventData
local function absorbedMagicCallback(e)
	if config.resistLog then
		if e.source.name then
			box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.resistLog.absorbed") .. " " .. e.source.name .. "!", { config.resRed, config.resGreen, config.resBlue })
		else
			box.logMessage("" .. e.mobile.object.name .. " " .. func.i18n("msgBox.resistLog.absorbedSpell") .. "", { config.resRed, config.resGreen, config.resBlue })
		end
	end
end
event.register(tes3.event.absorbedMagic, absorbedMagicCallback)

local function onChangeMusic(e)
	if config.musicLog then
		if e.context ~= "level" and e.context ~= "death" then
			local idx = 0
			if not config.musicPath then
				idx = string.find(e.music, "/[^/]*$")
			end
			local msg = string.sub(e.music, idx + 1)
			box.logMessage("" .. func.i18n("msgBox.musicLog.nowPlaying") .. " " .. msg .. "", { config.musRed, config.musGreen, config.musBlue })
		end
	end
end
event.register("musicChangeTrack", onChangeMusic)

local function onJournal(e)
	if config.questLog then
		if e.info then
			local msg = string.gsub(e.info.text, "@", "")
			msg = string.gsub(msg, "#", "")
			box.logMessage("" .. msg .. "", { config.queRed, config.queGreen, config.queBlue })
		end
	end
end
event.register("journal", onJournal)

local function onGetInfo(e)
	if config.chatLog then
		if e.info.type == 4 or e.info.type == 1 then return end

		local msg = string.gsub(e:loadOriginalText(), "@", "")
		msg = string.gsub(msg, "#", "")

		local mobileActor = tes3ui.getServiceActor()
		if mobileActor then
			msg = tes3.applyTextDefines({ text = msg, actor = mobileActor.object })
			msg = "" .. mobileActor.object.name .. ": \"" .. msg .. "\""
		else
			if e.info.actor then
				msg = tes3.applyTextDefines({ text = msg, actor = e.info.actor })
				msg = "" .. e.info.actor.name .. ": \"" .. msg .. "\""
			else
				msg = "\"" .. msg .. "\""
				if string.find(msg, "%", 1, true) then
					log:debug("No service actor found.")
					msg = string.gsub(msg, "%%PCRace", tes3.player.object.race.name)
					msg = string.gsub(msg, "%%PCName", tes3.player.object.name)
					msg = string.gsub(msg, "%%PCClass", tes3.player.object.class.name)
					msg = string.gsub(msg, "%%PCCrimeLevel", tes3.mobilePlayer.bounty)
					--PCRank
					--NextPCRank
				end
			end
		end
		box.logMessage("" .. msg .. "", { config.diaRed, config.diaGreen, config.diaBlue })
	end
end
event.register("infoGetText", onGetInfo)

--- @param e dialogueFilteredEventData
local function dialogueFilteredCallback(e)
	if config.showTopic then
		if e.context == tes3.dialogueFilterContext.clickTopic then
			box.logMessage("" .. func.i18n("msgBox.topicLog.topic") .. " " .. e.dialogue.id .. "", { config.topRed, config.topGreen, config.topBlue })
		end
	end
end
event.register(tes3.event.dialogueFiltered, dialogueFilteredCallback)

event.register(tes3.event.uiEvent, function(e)
	if e.property ~= tes3.uiProperty.mouseDown or not config.showTopic then return end
	local elem = e.source
	log:trace("Answer choice triggered.")
	log:debug("Text: " .. elem.text .. "")

	if elem.text and elem.text ~= "" then
		local idx = string.find(elem.text, "([^\\s]+)")
		local msg = string.sub(elem.text, idx + 3)
		msg = "" .. tes3.player.object.name .. ": " .. msg
		box.logMessage("" .. msg, { config.topRed, config.topGreen, config.topBlue })
	end

end, { filter = -239 })

--- @param e magicCastedEventData
local function magicCastedCallback(e)
	if e.source.objectType ~= tes3.objectType.alchemy then
		--Spell
		if config.castLog then
			if e.source.name and not e.source.isDisease then
				box.logMessage("" .. e.caster.object.name .. " " .. func.i18n("msgBox.castLog.casts") .. " " .. e.source.name .. "!", { config.castRed, config.castGreen, config.castBlue })
			end
		end
	else
		--Potion
		if config.useLog then
			box.logMessage("" .. e.caster.object.name .. " " .. func.i18n("msgBox.useLog.uses") .. " " .. e.source.name .. ".", { config.useRed, config.useGreen, config.useBlue })
		end
	end
end
event.register(tes3.event.magicCasted, magicCastedCallback)

--- @param e spellCastEventData
local function spellCastCallback(e)
	if config.cChanceLog then
		if e.source.name and not e.source.isDisease then
			box.logMessage("" .. e.caster.object.name .. " " .. func.i18n("msgBox.castChanceLog.attemptsToCast") .. " " .. e.source.name .. "! (" .. math.round(e.castChance, 2) .. "%)", { config.cChanceRed, config.cChanceGreen, config.cChanceBlue })
		end
	end
end
event.register(tes3.event.spellCast, spellCastCallback)

--- @param e calcHitChanceEventData
local function calcHitChanceCallback(e)
	if config.hitLog then
		if e.targetMobile then
			if e.attackerMobile == tes3.mobilePlayer or e.targetMobile == tes3.mobilePlayer then
				box.logMessage("" .. e.attacker.object.name .. "'s " .. func.i18n("msgBox.hitLog.chanceToHit") .. " " .. e.targetMobile.object.name .. ": " .. math.round(e.hitChance, 2) .. "%.", { config.hitRed, config.hitGreen, config.hitBlue })
			end
		end
	end
end
event.register(tes3.event.calcHitChance, calcHitChanceCallback)

--- @param e barterOfferEventData
local function barterOfferCallback(e)
	if e.success then
		--Bought
		if config.buyLog and #e.buying > 0 then
			box.logMessage("" .. func.i18n("msgBox.barterLog.bought"), { config.buyRed, config.buyGreen, config.buyBlue })
			for i = 1, #e.buying do
				local tile = e.buying[i]
				box.logMessage("x" .. tile.count .. " " .. tile.item.name .. "", { config.buyRed, config.buyGreen, config.buyBlue })
			end
			box.logMessage("*****", { config.buyRed, config.buyGreen, config.buyBlue })
		end
		--Sold
		if config.sellLog and #e.selling > 0 then
			box.logMessage("" .. func.i18n("msgBox.barterLog.sold"), { config.sellRed, config.sellGreen, config.sellBlue })
			for i = 1, #e.selling do
				local tile = e.selling[i]
				box.logMessage("x" .. tile.count .. " " .. tile.item.name .. "", { config.sellRed, config.sellGreen, config.sellBlue })
			end
			box.logMessage("*****", { config.sellRed, config.sellGreen, config.sellBlue })
		end
		--Total
		if config.barterLog then
			if e.value < 0 then
				box.logMessage("" .. func.i18n("msgBox.barterLog.spent") .. " " .. math.abs(e.offer) .. " " .. tes3.findGMST(tes3.gmst.sGold).value .. ".", { config.buyRed, config.buyGreen, config.buyBlue })
			else
				box.logMessage("" .. func.i18n("msgBox.barterLog.profit") .. " " .. e.offer .. " " .. tes3.findGMST(tes3.gmst.sGold).value .. ".", { config.sellRed, config.sellGreen, config.sellBlue })
			end
		end
	end
end
event.register(tes3.event.barterOffer, barterOfferCallback)

--- @param e itemDroppedEventData
local function itemDroppedCallback(e)
	if config.dropLog then
		box.logMessage("" .. func.i18n("msgBox.dropLog.dropped") .. " " .. e.reference.object.name .. ". (" .. tes3.getPlayerCell().displayName .. ")", {config.dropRed, config.dropGreen, config.dropBlue })
	end
end
event.register(tes3.event.itemDropped, itemDroppedCallback)

--- @param e convertReferenceToItemEventData
local function convertReferenceToItemCallback(e)
	if config.grabLog then
		if not e.reference.mobile then
			box.logMessage("" .. e.reference.object.name .. " " .. func.i18n("msgBox.grabLog.picked") .. "", { config.grabRed, config.grabGreen, config.grabBlue })
		else
			box.logMessage("" .. e.reference.object.name .. " " .. func.i18n("msgBox.grabLog.stuck") .. "", { config.grabRed, config.grabGreen, config.grabBlue })
		end
	end
end
event.register(tes3.event.convertReferenceToItem, convertReferenceToItemCallback)

--Config Stuff------------------------------------------------------------------------------------------------------------------------------
event.register("modConfigReady", function()
    require("messageBox.mcm")
    config = require("messageBox.config")
end)