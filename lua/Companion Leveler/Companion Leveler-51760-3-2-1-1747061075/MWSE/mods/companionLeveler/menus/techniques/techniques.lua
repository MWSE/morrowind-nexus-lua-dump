local logger = require("logging.logger")
local func = require("companionLeveler.functions.common")
local tables = require("companionLeveler.tables")
local siphon = require("companionLeveler.menus.techniques.siphon")
local artifice = require("companionLeveler.menus.techniques.artifice")
local necro = require("companionLeveler.menus.techniques.necro")
local daedra = require("companionLeveler.menus.techniques.daedra")
local rez = require("companionLeveler.menus.techniques.resurrect")
local beast = require("companionLeveler.menus.techniques.beast")
local train = require("companionLeveler.menus.techniques.train")
local gem = require("companionLeveler.menus.techniques.gem")
local sabo = require("companionLeveler.menus.techniques.sabo")
local safe = require("companionLeveler.menus.techniques.safe")
local molag = require("companionLeveler.menus.techniques.molagGift")
local drugs = require("companionLeveler.menus.techniques.drugs")

local tech = {}

--Main Menu
function tech.createWindow(ref)
    tech.id_menu = tes3ui.registerID("kl_tech_menu")
    tech.id_label = tes3ui.registerID("kl_tech_label")
	tech.id_tp = tes3ui.registerID("kl_tech_tp_bar")
	tech.id_rite = tes3ui.registerID("kl_tech_rite_btn")
	tech.id_sun = tes3ui.registerID("kl_tech_sun_btn")
	tech.id_ash = tes3ui.registerID("kl_tech_ash_btn")
    tech.id_storm = tes3ui.registerID("kl_tech_storm_btn")
    tech.id_smoke = tes3ui.registerID("kl_tech_smoke_btn")
    tech.id_siphon = tes3ui.registerID("kl_tech_siphon_btn")
	tech.id_artifice = tes3ui.registerID("kl_tech_artifice_btn")
	tech.id_necro = tes3ui.registerID("kl_tech_necro_btn")
	tech.id_rez = tes3ui.registerID("kl_tech_rez_btn")
	tech.id_alch = tes3ui.registerID("kl_tech_alch_btn")
	tech.id_ench = tes3ui.registerID("kl_tech_ench_btn")
	tech.id_gem = tes3ui.registerID("kl_tech_gem_btn")
	tech.id_dig = tes3ui.registerID("kl_tech_dig_btn")
	tech.id_beast = tes3ui.registerID("kl_tech_beast_btn")
	tech.id_train = tes3ui.registerID("kl_tech_train_btn")
	tech.id_daedra = tes3ui.registerID("kl_tech_daedra_btn")
	tech.id_scampson = tes3ui.registerID("kl_tech_scamp_btn")
	tech.id_safe = tes3ui.registerID("kl_tech_safe_btn")
	tech.id_sabo = tes3ui.registerID("kl_tech_sabo_btn")
	tech.id_transform = tes3ui.registerID("kl_tech_xform_btn")
	tech.id_drugs = tes3ui.registerID("kl_tech_drugs_btn")


    tech.log = logger.getLogger("Companion Leveler")
    tech.log:debug("Technique menu initialized.")

	local root = require("companionLeveler.menus.root")

    tech.ref = ref

    tech.menu = tes3ui.createMenu { id = tech.id_menu, fixedFrame = true }
    tech.modData = func.getModData(ref)


    --Labels
    local label = tech.menu:createLabel { text = "Techniques", id = tech.id_label }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 14


    --Main Block----------------------------------------------------------------------------------------------
    local tech_block = tech.menu:createBlock { id = "kl_tech_block" }
    tech_block.flowDirection = "top_to_bottom"
    tech_block.autoHeight = true
	tech_block.minHeight = 200
    tech_block.autoWidth = true
    tech_block.paddingLeft = 10
    tech_block.paddingRight = 10
    tech_block.widthProportional = 1.0
	tech_block.autoHeight = true
	tech_block.childAlignX = 0.5

	--TP Bar
	tech.tp = tech_block:createFillBar({ current = tech.modData.tp_current, max = tech.modData.tp_max, id = tech.id_tp })
	func.configureBar(tech.tp, "standard", "purple")
    tech.tp.height = 21
	tech.tp.borderBottom = 20

	--Blood Karma Bar
	if tech.modData.bloodKarma then
		tech.bk = tech_block:createFillBar({ current = tech.modData.bloodKarma, max = 100, id = "kl_tech_karma_bar" })
		func.configureBar(tech.bk, "small", "crimson")
		tech.bk.borderBottom = 20
		tech.tp.borderBottom = 12
	end

	--Lycanthropic Power Bar
	if tech.modData.lycanthropicPower then
		tech.lp = tech_block:createFillBar({ current = tech.modData.lycanthropicPower, max = 300, id = "kl_tech_lycan_bar" })
		func.configureBar(tech.lp, "small", "bloodmoon")
		tech.lp.borderBottom = 20
		tech.tp.borderBottom = 12
	end

	--Order Streak Bar
	if tech.modData.orderStreak then
		tech.osLabel = tech_block:createLabel({ text = "" .. tes3.findClass(tech.modData.lastClass).name .. " -> " .. tes3.findClass(tech.modData.class).name .. "" })
		tech.osLabel.borderBottom = 5
		if tech.modData.class ~= tech.modData.lastClass then
			tech.osLabel.color = tables.colors["silver"]
		else
			tech.osLabel.color = tables.colors["white"]
		end
		tech.os = tech_block:createFillBar({ current = tech.modData.orderStreak, max = 5, id = "kl_tech_order_bar" })
		func.configureBar(tech.os, "small", "silver")
		tech.os.borderBottom = 20
		tech.tp.borderBottom = 12
	end

	--Soul Energy Bar
	if tech.modData.soulEnergy then
		tech.se = tech_block:createFillBar({ current = tech.modData.soulEnergy, max = tech.modData.level * 100, id = "kl_tech_soul_energy_bar" })
		func.configureBar(tech.se, "small", "azure")
		tech.se.borderBottom = 20
		tech.se.borderBottom = 12
	end


    -- Main Buttons
	if ref.object.objectType == tes3.objectType.creature then
		--Creature Techniques
		if tech.modData.abilities[1] == true then
			--Normal Level 5
			local button_dig = tech_block:createButton { id = tech.id_dig, text = "Dig" }
			button_dig:register("mouseClick", function() tech.onDig("normal") end)
		end
		if tech.modData.abilities[10] == true then
			--Undead Level 10
			local msg = "Perform a Rite of Blood?\nTP Cost: 3"
			local button_rite = tech_block:createButton { id = tech.id_rite, text = "Blood Rite" }
			button_rite:register("mouseClick", function() tech.onSiphon(msg, 2) end)
		end
		if tech.modData.abilities[15] == true then
			--Humanoid Level 15
			local msg = "Have " .. tech.ref.object.name .. " conjure an ash storm?\nTP Cost: 2"
			local button_ash = tech_block:createButton { id = tech.id_ash, text = "Conjure Ash Storm" }
			button_ash:register("mouseClick", function() tech.onWeather(6, msg) end)
		end
		if tech.modData.abilities[23] == true then
			--Spriggan Level 15
			local msg = "Have " .. tech.ref.object.name .. " clear the skies?\nTP Cost: 2"
			local button_sun = tech_block:createButton { id = tech.id_sun, text = "Clear Skies" }
			button_sun:register("mouseClick", function() tech.onWeather(0, msg) end)
		end
		if tech.modData.abilities[36] == true then
			--Spectral Level 20
			local button_rez = tech_block:createButton { id = tech.id_rez, text = "Spectral Resurrection" }
			button_rez:register("mouseClick", function() tech.menu:destroy() rez.createWindow(ref, "spectral") end)
		end
		if tech.modData.abilities[67] == true then
			--Fiery Level 15
			local id = "kl_spell_fiery_aspect"
			local aspect = tes3.getObject(id)
			local msg = "Draw out the " .. aspect.name .. "?\nTP Cost: 3"
			local button_fire = tech_block:createButton { id = tech.id_fire, text = "" .. aspect.name .. ""}
			button_fire:register("help", function(e)
				local tooltip = tes3ui.createTooltipMenu { spell = aspect }
	
				local contentElement = tooltip:getContentElement()
				contentElement.paddingAllSides = 12
				contentElement.childAlignX = 0.5
				contentElement.childAlignY = 0.5
			end)
			button_fire:register("mouseClick", function() tech.onAspect(id, msg) end)
		end
		if tech.modData.abilities[71] == true then
			--Frozen Level 15
			local id = "kl_spell_frozen_aspect"
			local aspect = tes3.getObject(id)
			local msg = "Manifest the " .. aspect.name .. "?\nTP Cost: 3"
			local button_fire = tech_block:createButton { id = tech.id_fire, text = "" .. aspect.name .. ""}
			button_fire:register("help", function(e)
				local tooltip = tes3ui.createTooltipMenu { spell = aspect }
	
				local contentElement = tooltip:getContentElement()
				contentElement.paddingAllSides = 12
				contentElement.childAlignX = 0.5
				contentElement.childAlignY = 0.5
			end)
			button_fire:register("mouseClick", function() tech.onAspect(id, msg) end)
		end
		if tech.modData.abilities[75] == true then
			--Galvanic Level 15
			local id = "kl_spell_galvanic_aspect"
			local aspect = tes3.getObject(id)
			local msg = "Channel the " .. aspect.name .. "?\nTP Cost: 3"
			local button_fire = tech_block:createButton { id = tech.id_fire, text = "" .. aspect.name .. ""}
			button_fire:register("help", function(e)
				local tooltip = tes3ui.createTooltipMenu { spell = aspect }
	
				local contentElement = tooltip:getContentElement()
				contentElement.paddingAllSides = 12
				contentElement.childAlignX = 0.5
				contentElement.childAlignY = 0.5
			end)
			button_fire:register("mouseClick", function() tech.onAspect(id, msg) end)
		end
		if tech.modData.abilities[79] == true then
			--Poisonous Level 15
			local id = "kl_spell_poisonous_aspect"
			local aspect = tes3.getObject(id)
			local msg = "Unleash the " .. aspect.name .. "?\nTP Cost: 3"
			local button_fire = tech_block:createButton { id = tech.id_fire, text = "" .. aspect.name .. ""}
			button_fire:register("help", function(e)
				local tooltip = tes3ui.createTooltipMenu { spell = aspect }
	
				local contentElement = tooltip:getContentElement()
				contentElement.paddingAllSides = 12
				contentElement.childAlignX = 0.5
				contentElement.childAlignY = 0.5
			end)
			button_fire:register("mouseClick", function() tech.onAspect(id, msg) end)
		end
	else
		--NPC Techniques-------------------------------------------------------------------------------------------------------------------------
		if tech.modData.abilities[22] == true then
			--Alchemist
			local button_alch = tech_block:createButton { id = tech.id_alch, text = tes3.findGMST("sSkillAlchemy").value}
			button_alch:register("mouseClick", function() tech.menu:destroy() tech.onService("Alchemy") end)
		end

		if tech.modData.abilities[26] == true then
			--Enchanter
			local button_ench = tech_block:createButton { id = tech.id_ench, text = tes3.findGMST("sEnchanting").value}
			button_ench:register("mouseClick", function() tech.onService("Enchanting") end)

			local button_gem = tech_block:createButton { id = tech.id_gem, text = "Soul Gem Synthesis"}
			button_gem:register("mouseClick", function() tech.menu:destroy() gem.createWindow(ref) end)
		end

		if tech.modData.abilities[30] == true then
			--Necromancer
			local button_necro = tech_block:createButton { id = tech.id_necro, text = "Raise Undead" }
			button_necro:register("mouseClick", function() tech.menu:destroy() necro.createWindow(ref) end)
		end

		if tech.modData.abilities[41] == true then
			--Archeologist
			local button_dig = tech_block:createButton { id = tech.id_dig, text = "Archeological Dig" }
			button_dig:register("mouseClick", function() tech.onDig("archeologist") end)
		end

		if tech.modData.abilities[42] == true then
			--Artificer
			local button_artifice = tech_block:createButton { id = tech.id_artifice, text = "Construct Golem"}
			button_artifice:register("mouseClick", function() tech.menu:destroy() artifice.createWindow(ref) end)
		end

		if tech.modData.abilities[48] == true then
			--Beastmaster
			local button_beast = tech_block:createButton { id = tech.id_beast, text = "Train Creature" }
			button_beast:register("mouseClick", function() tech.menu:destroy() beast.createWindow(ref) end)
		end

		for i = 1, #tables.abTypeNPC do
			if tables.abTypeNPC[i] == "[TECHNIQUE]: TRAINING" and tech.modData.abilities[i] == true then
				--Training Classes
				local button_train = tech_block:createButton { id = tech.id_train, text = "Training" }
				button_train:register("mouseClick", function() tech.menu:destroy() train.createWindow(ref) end)
				break
			end
		end

		if tech.modData.abilities[86] == true then
			--Stormcaller
			local msg = "Have " .. tech.ref.object.name .. " summon a storm?\nTP Cost: 2"
			local button_storm = tech_block:createButton { id = tech.id_storm, text = "Call Storm" }
			button_storm:register("mouseClick", function() tech.onWeather(5, msg) end)
		end

		if tech.modData.abilities[113] == true or tech.modData.abilities[126] == true then
			--Ninja/Shadow Warrior
			local button_smoke = tech_block:createButton { id = tech.id_smoke, text = "Smoke Bomb" }
			local msg = "Use a Smoke Bomb?\nThis will drain " .. tech.ref.object.name .. "'s stamina.\nTP Cost: 3"
			if tech.modData.abilities[126] == true then
				button_smoke.text = "Shadowstep"
				msg = "Perform a Shadowstep?\nThis will drain " .. tech.ref.object.name .. "'s stamina.\nTP Cost: 3"
			end
			button_smoke:register("mouseClick", function() tech.onSmoke(msg) end)
		end

		if tech.modData.abilities[115] == true then
			--Arcanist
			local msg = "Siphon Magicka?\nTP Cost: 3"
			local button_siphon = tech_block:createButton { id = tech.id_siphon, text = "Siphon Magicka" }
			button_siphon:register("mouseClick", function() tech.onSiphon(msg, 1) end)
		end

		if tech.modData.abilities[118] == true then
			--Daedrologist
			local button_daedra = tech_block:createButton { id = tech.id_daedra, text = "Summon Daedra" }
			button_daedra:register("mouseClick", function() tech.menu:destroy() daedra.createWindow(ref) end)
		end

		if tech.modData.abilities[121] == true then
			--Dark Knight
			local msg = "Life Tap?\nTP Cost: 3"
			local button_siphon = tech_block:createButton { id = tech.id_siphon, text = "Life Tap" }
			button_siphon:register("mouseClick", function() tech.onSiphon(msg, 3) end)
		end

		if tech.modData.abilities[127] == true then
			--Saboteur
			local button_sabo = tech_block:createButton { id = tech.id_sabo, text = "Set Trap" }
			button_sabo:register("mouseClick", function() tech.menu:destroy() sabo.createWindow(ref) end)
		end

		if tech.modData.abilities[128] == true then
			--Safecracker
			local button_safe = tech_block:createButton { id = tech.id_safe, text = "Remove Lock/Trap" }
			button_safe:register("mouseClick", function() tech.menu:destroy() safe.createWindow(ref) end)
		end

		if tech.modData.abilities[139] == true then
			--Cleric: Clavicus Vile
			if tech.modData.patron == 12 then
				local button_scampson = tech_block:createButton { id = tech.id_scampson, text = "Call Scampson" }
				button_scampson:register("mouseClick", function() tech.onScampson() end)
			end
			--Cleric: Hircine
			if tech.modData.patron == 14 then
				local button_transform = tech_block:createButton { id = tech.id_transform, text = "Transform" }
				button_transform:register("mouseClick", function() tech.onTransform() end)
				if tech.modData.tributePaid == false then
					button_transform.widget.state = 2
					button_transform.disabled = true
					button_transform:register("help", function(e)
						local tooltip = tes3ui.createTooltipMenu()

						local contentElement = tooltip:getContentElement()
						contentElement.flowDirection = tes3.flowDirection.leftToRight
						contentElement.paddingAllSides = 10

						local ttLabel = tooltip:createLabel { text = "Complete the current hunt to regain control." }
					end)
				end
			end
			--Cleric: Molag Bal
			if tech.modData.patron == 20 then
				local button_molag = tech_block:createButton { id = tech.id_molag, text = "Soul Manipulation" }
				button_molag:register("mouseClick", function() tech.menu:destroy() molag.createWindow(ref) end)
			end
		end

		if tech.modData.abilities[140] == true then
			--Skooma Cook
			local button_drugs = tech_block:createButton { id = tech.id_drugs, text = "Skooma Refining"}
			button_drugs:register("mouseClick", function() tech.menu:destroy() drugs.createWindow(ref) end)
		end
	end

	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = tech.menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 1.0
	button_block.borderTop = 20

	local button_root = button_block:createButton { text = "Main Menu" }
	button_root.borderRight = 30

	local button_cancel = button_block:createButton { id = tech.id_cancel, text = tes3.findGMST("sCancel").value }

	button_root:register("mouseClick", function() tech.menu:destroy() root.createWindow(ref) end)
    button_cancel:register("mouseClick", function() tes3ui.leaveMenuMode() tech.menu:destroy() end)

    -- Final setup
    tech.menu:updateLayout()
    tes3ui.enterMenuMode(tech.id_menu)
end

--Alchemist/Enchanter
function tech.onService(type)
	if type == "Alchemy" then
		tech.log:trace("Alchemy Service triggered on " .. tech.ref.object.name ..".")

		--Time Consumer Compatibility
		tech.pcAlchemy = tes3.player.mobile.alchemy.current
		tech.pcInt = tes3.player.mobile.attributes[2].current
		tech.pcLuck = tes3.player.mobile.attributes[8].current

		tech.comAlchemy = tech.ref.mobile.alchemy.current
		tech.comInt = tech.ref.mobile.attributes[2].current
		tech.comLuck = tech.ref.mobile.attributes[8].current

		tes3.setStatistic({ reference = tes3.player, skill = 16, current = tech.comAlchemy })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.intelligence, current = tech.comInt })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.luck, current = tech.comLuck })

		tes3.showAlchemyMenu()
		event.register("menuExit", tech.onServiceExit, { doOnce = true })
		event.register("exerciseSkill", tech.onServiceExercise)
	elseif type == "Enchanting" then
		tes3ui.showInventorySelectMenu({ title = tes3.findGMST("sSoulGemsWithSouls").value, filter = "soulgemFilled", callback = tech.showEnchantMenu })
	end

	tech.service = type
end

function tech.showEnchantMenu(e)
	if e.item then
		tech.log:trace("Enchanting Service triggered on " .. tech.ref.object.name ..".")

		tes3.mobilePlayer:equip{ item = e.item }
		tech.menu:destroy()


		--Time Consumer Compatibility
		tech.pcEnchant = tes3.player.mobile.enchant.current
		tech.pcInt = tes3.player.mobile.attributes[2].current
		tech.pcLuck = tes3.player.mobile.attributes[8].current

		tech.comEnchant = tech.ref.mobile.enchant.current
		tech.comInt = tech.ref.mobile.attributes[2].current
		tech.comLuck = tech.ref.mobile.attributes[8].current

		tes3.setStatistic({ reference = tes3.player, skill = tes3.skill.enchant, current = tech.comEnchant })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.intelligence, current = tech.comInt })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.luck, current = tech.comLuck })

		event.register("menuExit", tech.onServiceExit, { doOnce = true })
		event.register("exerciseSkill", tech.onServiceExercise)
	end
end

function tech.onServiceExercise(e)
	e.progress = e.progress * 0.25
end

function tech.onServiceExit()
	if tech.service == "Alchemy" then
		tech.log:trace("Alchemy exit check triggered on " .. tech.ref.object.name ..".")

		--Time Consumer Compatibility
		tes3.setStatistic({ reference = tes3.player, skill = 16, current = tech.pcAlchemy })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.intelligence, current = tech.pcInt })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.luck, current = tech.pcLuck })
	elseif tech.service == "Enchanting" then
		tech.log:trace("Enchanting exit check triggered on " .. tech.ref.object.name ..".")

		tes3.setStatistic({ reference = tes3.player, skill = tes3.skill.enchant, current = tech.pcEnchant })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.intelligence, current = tech.pcInt })
		tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.luck, current = tech.pcLuck })
	end

	if event.isRegistered("exerciseSkill", tech.onServiceExercise) then
		event.unregister("exerciseSkill", tech.onServiceExercise)
	end
end

--Archeologist/Normal Type
function tech.onDig(type)
	if tech.menu then
		tech.digtype = type
		if type == "archeologist" then
			tes3.messageBox({ message = "Dig for artifacts?\nTP Cost: 3",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = tech.onDigConfirm })
		else
			tes3.messageBox({ message = "Dig for items?\nTP Cost: 3",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = tech.onDigConfirm })
		end
    end
end

function tech.onDigConfirm(e)
	if e.button == 0 then
		tech.log:trace("Dig Technique triggered.")

		if tes3.player.cell.restingIsIllegal == false then
			if func.spendTP(tech.ref, 3) == false then
				return
			end

			--Dig
			tech.menu:destroy()
			tes3.fadeOut()
			tech.fakeMenu = tes3ui.createMenu { id = "kl_fake_menu", fixedFrame = true }
			tech.fakeMenu:createLabel({ text = "Digging..." })
			tes3ui.enterMenuMode("kl_fake_menu")
			timer.start({ type = timer.real, duration = 2, callback = tech.digResult })
			timer.start({ type = timer.real, duration = 1, callback = function()
				tes3.playSound({ soundPath = "companionLeveler\\rock_shatter.wav" })
			end })
		else
			tes3.messageBox("" .. tech.ref.object.name .. " cannot dig here.")
        end
	end
end

function tech.digResult()
	local randNum
	local gameHour = tes3.getGlobal('GameHour')

	gameHour = gameHour + math.random(0.4, 1.0)
	tes3.setGlobal('GameHour', gameHour)

	if tech.digtype == "normal" then
		if math.random(1, 10) > 7 then
			tes3.messageBox("" .. tech.ref.object.name .. " couldn't find anything.")
			tech.log:debug("Dig roll failed.")
		else
			randNum = math.random(1, #tables.digList)
			if randNum == 3 then
				--Re roll once
				randNum = math.random(1, #tables.digList)
			end
			local list = tables.digList[randNum]
			local item = list[math.random(1, #list)]

			--Dig Up Random Items
			tes3.addItem({ item = item, reference = tes3.player })

			local spoils = tes3.getObject(item)
			tes3.messageBox("" .. tech.ref.object.name .. " dug something up for you. (" .. spoils.name .. ")")
		end
	else
		if tes3.player.cell.isOrBehavesAsExterior then
			--Roughly 60% Chance: Exterior
			randNum = math.random(1, 45)
			tech.log:debug("Exterior digsite detected.")
		else
			local cell = tes3.getPlayerCell()
			local dwemer = 0
			local other = 1

			--Check for Dwemeri Statics
			for sta in cell:iterateReferences(tes3.objectType.static) do
				if string.match(sta.id, "dwrv") or string.match(sta.id, "_dwe_") then
					dwemer = dwemer + 1
				else
					other = other + 1
				end
			end

			if dwemer > other then
				--Roughly 93% Chance + Increased Dwemeri Item Chance
				randNum = math.random(13, 28)
				tech.log:debug("Dwemer digsite detected.")
			else
				--Roughly 87% Chance: Interior
				randNum = math.random(1, 31)
				tech.log:debug("Interior digsite detected.")
			end
		end

		--Dig
		if randNum > 27 then
			tes3.messageBox("" .. tech.ref.object.name .. " couldn't find anything.")
			tech.log:debug("Dig roll failed.")
		else
			--Find random artifacts
			tes3.addItem({ item = tables.unearthedObjects[randNum], reference = tech.ref })

			local spoils = tes3.getObject(tables.unearthedObjects[randNum])
			tes3.messageBox("" .. tech.ref.object.name .. " dug something up. (" .. spoils.name .. ")")
			tech.log:debug("Dig roll succeeded.")
		end
	end

	--Finish
	tes3.fadeIn()
	tech.fakeMenu:destroy()
	tech.createWindow(tech.ref)
end

--Arcanist / Undead Level 10
function tech.onSiphon(msg, type)
	if tech.menu then
		tech.type = type
        tes3.messageBox({ message = msg,
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = tech.onSiphonConfirm })
    end
end

function tech.onSiphonConfirm(e)
	if e.button == 0 then
		if func.spendTP(tech.ref, 3) == false then return end

		tech.menu:destroy()
		siphon.createWindow(tech.ref, tech.type)
	end
end

--Stormcaller / Humanoid Level 15 / Spriggan Level 15
function tech.onWeather(type, msg)
    if tech.menu then
		tech.weatherType = type
		tes3.messageBox({ message = msg, buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value }, callback = tech.onWeatherConfirm })
    end
end

function tech.onWeatherConfirm(e)
    if (tech.menu) then
		if e.button == 0 then
			local cell = tes3.player.cell

			if cell.isOrBehavesAsExterior then
				--Change Weather
				if func.spendTP(tech.ref, 2) == false then return end

				tes3ui.leaveMenuMode()
				tech.menu:destroy()

				local region = cell.region
				region:changeWeather(tech.weatherType)
				tes3.playSound({ sound = "alteration hit", reference = tech.ref })

				if tech.weatherType == 0 then
					tes3.messageBox("" .. tech.ref.object.name .. " cleared the skies!")
				elseif tech.weatherType == 5 then
					tes3.messageBox("" .. tech.ref.object.name .. " called forth storm clouds.")
				elseif tech.weatherType == 6 then
					tes3.messageBox("" .. tech.ref.object.name .. " dreamt of ash...")
				end
			else
				--Inside
				if tech.weatherType == 0 then
					tes3.messageBox("" .. tech.ref.object.name .. " cannot reach the skies from here.")
				elseif tech.weatherType == 5 then
					tes3.messageBox("" .. tech.ref.object.name .. " cannot call storms here.")
				elseif tech.weatherType == 6 then
					tes3.messageBox("" .. tech.ref.object.name .. " cannot manifest ash storms here.")
				end
			end
		end
    end
end

--Ninja/Shadow Warrior
function tech.onSmoke(msg)
    if tech.menu then
        tes3.messageBox({ message = msg,
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = tech.onSmokeConfirm })
    end
end

function tech.onSmokeConfirm(e)
	tech.log:trace("Smoke Bomb triggered on " .. tech.ref.object.name ..".")

    if (tech.menu) then
		if e.button == 0 then
			local cell = tes3.player.cell

			if cell.isInterior then
				if tes3.worldController.flagTeleportingDisabled == true then
					--Teleportation Disabled
					tes3.messageBox("A strange force prevents " .. tech.ref.object.name .. " your party from escaping this way...")
					tech.log:debug("Teleportation is currently disabled. Smoke Bomb failed.")
				else
					--Escape Interior
					if func.spendTP(tech.ref, 3) == false then return end

					local modDataP = func.getModDataP()
					local lastExterior = tes3.getDataHandler().lastExteriorCell
					tech.log:debug("Last Exterior Cell: " .. lastExterior.displayName .. ", Last Exterior Position: " .. tostring(modDataP.lastExteriorPosition) .. "")

					tes3ui.leaveMenuMode()
					tech.menu:destroy()

					tes3.playSound({ sound = "Steam", volume = 0.7 })
					tes3.createVisualEffect({ object = "VFX_IllusionArea", scale = 50, lifespan = 4, reference = tech.ref })
					timer.start({ duration = 2, type = timer.simulate, callback = function()
						tes3.positionCell({ reference = tes3.player, cell = lastExterior, position = modDataP.lastExteriorPosition })
						tes3.setStatistic({ name = "fatigue", current = 0, reference = tech.ref })
						tech.log:debug("Smoke Bomb succeeded.")
					end})
				end
			else
				--Already Outside
				tes3.messageBox("You are already outside.")
				tech.log:debug("You are already outside. Smoke Bomb failed.")
			end
		end
    end
end

--Elemental Types Level 15
function tech.onAspect(id, msg)
    if tech.menu then
		tech.aspectID = id
		tes3.messageBox({ message = msg, buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value }, callback = tech.onAspectConfirm })
    end
end

function tech.onAspectConfirm(e)
	if (tech.menu) then
		if e.button == 0 then
			if func.spendTP(tech.ref, 3) == false then return end

			tes3ui.leaveMenuMode()
			tech.menu:destroy()

			tes3.cast({ reference = tes3.player, spell = tech.aspectID, instant = true, bypassResistances = true })
			tes3.cast({ reference = tech.ref, target = tech.ref, spell = tech.aspectID, instant = true, bypassResistances = true })
		end
    end
end

--Scampson
function tech.onScampson()
    if tech.menu then
		tes3.messageBox({ message = "Call Scampson?\nTP Cost: 1\nGold Cost: 500g", buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value }, callback = tech.onScampsonConfirm })
    end
end

function tech.onScampsonConfirm(e)
	if (tech.menu) then
		if e.button == 0 then
			if func.spendTP(tech.ref, 1) == false then return end
			if not func.checkReq(false, "Gold_001", 500, tes3.player) then
				tes3.messageBox("Not enough Gold.")
				return
			end

			local cell = tes3.getPlayerCell()
			local pos = func.calculatePosition()
			local scampson = tes3.getReference("kl_scamp_scampson")

			tes3ui.leaveMenuMode()
			tech.menu:destroy()

			if not scampson then
				scampson = tes3.createReference({ object = "kl_scamp_scampson", cell = cell, position = pos, orientation = tes3.getPlayerEyeVector()})
				tech.log:debug("Scampson created and summoned.")
			else
				scampson:enable()
				tes3.positionCell({ reference = scampson, cell = cell, position = pos })
				tech.log:debug("Scampson summoned.")
			end

			tes3.createVisualEffect({ object = "VFX_DefaultHit", lifespan = 1, reference = scampson })
			tes3.playSound({ sound = "conjuration hit", reference = scampson })
			local angle = scampson.mobile:getViewToActor(tes3.mobilePlayer)
			scampson.facing = scampson.facing + math.rad(math.clamp(angle, -90, 90))
			timer.delayOneFrame(function()
				timer.delayOneFrame(function()
					timer.delayOneFrame(function()
						tes3.player:activate(scampson)
					end)
				end)
			end)

			timer.start({ type = timer.simulate, duration = 1, callback = function() tes3.getReference("kl_scamp_scampson"):disable() end })
		end
    end
end

--Transform
function tech.onTransform()
    if tech.menu then
		tes3.messageBox({ message = "Transform into a werewolf?\nThe act of transformation is a crime!\nTransformation Time: " .. (15 + tech.modData.level + (tech.modData.lycanthropicPower * 6)) .. "s\nTP Cost: 5", buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value }, callback = tech.onTransformConfirm })
    end
end

function tech.onTransformConfirm(e)
	if (tech.menu) then
		if e.button == 0 then
			if func.spendTP(tech.ref, 5) == false then return end

			local cell = tes3.getPlayerCell()
			local pos = func.calculatePosition()
			local werewolf = tes3.getReference("kl_werewolf_companion")

			tes3ui.leaveMenuMode()
			tech.menu:destroy()

			tech.ref:disable()

			if not werewolf or werewolf.isDead then
				tes3.getObject("kl_werewolf_companion").name = tech.ref.object.name
				werewolf = tes3.createReference({ object = "kl_werewolf_companion", cell = cell, position = pos, orientation = tes3.getPlayerEyeVector()})
				--Werewolf Attributes are NPC base + 40 in STR/AGI/SPD/END
				for i = 0, 7 do
					local att = tech.ref.mobile.attributes[i + 1].base
					tes3.modStatistic({ attribute = i, value = att, reference = werewolf })
				end
				--2x Werewolf Health
				tes3.setStatistic({ name = "health", value = tech.ref.mobile.health.base * 2, reference = werewolf })
				tes3.setAIFollow({ reference = werewolf, target = tes3.player })
				--mod data
				local md = func.getModData(werewolf)
				md["lycanthropicPower"] = tech.modData.lycanthropicPower
				md["hircineHunt"] = tech.modData.hircineHunt
				md["npcID"] = tech.ref.baseObject.id
				tech.log:debug("Werewolf alter ego created.")
			else
				werewolf:enable()
				tes3.positionCell({ reference = werewolf, cell = cell, position = pos })
				tes3.setAIFollow({ reference = werewolf, target = tes3.player })
				local md = func.getModData(werewolf)
				md.lycanthropicPower = tech.modData.lycanthropicPower
				md.hircineHunt = tech.modData.hircineHunt
				tech.log:debug("Werewolf transformed.")
			end

			tes3.createVisualEffect({ object = "VFX_DefaultHit", lifespan = 1, reference = werewolf })
			tes3.playSound({ sound = "conjuration hit", reference = werewolf })

			local num = math.random(1, 5)

			if num == 1 then
				tes3.playSound({ sound = "WolfItem2", reference = werewolf })
			elseif num == 2 then
				tes3.playSound({ sound = "WolfEquip2", reference = werewolf })
			elseif num == 3 then
				tes3.playSound({ sound = "WolfActivator1", reference = werewolf })
			elseif num == 4 then
				tes3.playSound({ sound = "WolfNPC2", reference = werewolf })
			else
				tes3.playSound({ sound = "WolfItem3", reference = werewolf })
			end

			local angle = werewolf.mobile:getViewToActor(tes3.mobilePlayer)
			werewolf.facing = werewolf.facing + math.rad(math.clamp(angle, -90, 90))

			tes3.triggerCrime({ type = tes3.crimeType.werewolf })

			timer.start({ type = timer.simulate, duration = (15 + tech.modData.level + (tech.modData.lycanthropicPower * 6)), iterations = 1, callback = "companionLeveler:wereTimer" })
		end
    end
end


return tech