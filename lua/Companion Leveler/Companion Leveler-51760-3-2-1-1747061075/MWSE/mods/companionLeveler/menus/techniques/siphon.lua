local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local siphon = {}


function siphon.createWindow(ref, type)
    siphon.id_menu = tes3ui.registerID("kl_siphon_menu")
	siphon.id_comBar = tes3ui.registerID("kl_siphon_comBar")
	siphon.id_pcBar = tes3ui.registerID("kl_siphon_pcBar")
	siphon.id_plus = tes3ui.registerID("kl_siphon_plus")
	siphon.id_interval = tes3ui.registerID("kl_siphon_interval")
	siphon.id_minus = tes3ui.registerID("kl_siphon_minus")

    log = logger.getLogger("Companion Leveler")
    log:debug("Siphon menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")

    siphon.ref = ref
	siphon.type = type
	siphon.interval = 1

    local menu = tes3ui.createMenu { id = siphon.id_menu, fixedFrame = true }


    --Content Block--------------------------------------------------------------------------------------------------------
	local siphon_block = menu:createBlock { id = "kl_siphon_block" }
    siphon_block.flowDirection = "top_to_bottom"
    siphon_block.autoHeight = true
    siphon_block.autoWidth = true
    siphon_block.paddingLeft = 10
    siphon_block.paddingRight = 10
    siphon_block.widthProportional = 1.0
	siphon_block.childAlignX = 0.5

	--Title
    local title = siphon_block:createLabel { text = "" }
    local divider = siphon_block:createDivider{}
    divider.borderBottom = 28

	--Companion Values
    local comLabel = siphon_block:createLabel { text = "" .. ref.object.name .. "" }
    local comBar
	local color
	if type == 1 then
		comBar = siphon_block:createFillBar({ current = ref.mobile.magicka.current, max = ref.mobile.magicka.base, id = siphon.id_comBar })
		color = "blue"
	else
		comBar = siphon_block:createFillBar({ current = ref.mobile.health.current, max = ref.mobile.health.base, id = siphon.id_comBar })
		color = "red"
	end
	func.configureBar(comBar, "standard", color)
    comBar.borderBottom = 20
	comBar.borderTop = 3

	--Controls
	local comPlus = siphon_block:createButton {text = "+", id = siphon.id_plus}
	local interval = siphon_block:createButton {text = "Rate: 1pt", id = siphon.id_interval}
	local comMinus = siphon_block:createButton {text = "-", id = siphon.id_minus}

	--Player Values
    local pcLabel = siphon_block:createLabel { text = "" .. tes3.player.object.name .. "" }
	pcLabel.borderTop = 20
	local pcBar
	if type == 1 then
		pcBar = siphon_block:createFillBar({ current = tes3.player.mobile.magicka.current, max = tes3.player.mobile.magicka.base, id = siphon.id_pcBar })
		color = "blue"
	elseif type == 2 then
		pcBar = siphon_block:createFillBar({ current = tes3.player.mobile.health.current, max = tes3.player.mobile.health.base, id = siphon.id_pcBar })
		color = "red"
	elseif type == 3 then
		pcBar = siphon_block:createFillBar({ current = ref.mobile.magicka.current, max = ref.mobile.magicka.base, id = siphon.id_pcBar })
		color = "blue"
	end
   	func.configureBar(pcBar, "standard", color)
    pcBar.borderBottom = 20
	pcBar.borderTop = 3


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }

	--Events
	comPlus:register("mouseClick", function() siphon.onPlus() end)
	interval:register("mouseClick", function() siphon.onInterval() end)
	comMinus:register("mouseClick", function() siphon.onMinus() end)
	button_ok:register("mouseClick", function() menu:destroy() tes3.playSound({sound = "mysticism cast"}) tech.createWindow(ref) end)


    --Final setup
	if type == 1 then
		title.text = "Siphon Magicka"
	elseif type == 2 then
		title.text = "Blood Rite"
	elseif type == 3 then
		title.text = "Life Tap"
		comPlus:destroy()
		pcLabel.text = "" .. ref.object.name .. ""
	end

    menu:updateLayout()
    tes3ui.enterMenuMode(siphon.id_menu)
end

function siphon.onPlus()
	local menu = tes3ui.findMenu(siphon.id_menu)

	if menu then
		--Arcanist
		local comValue = siphon.ref.mobile.magicka
		local pcValue = tes3.mobilePlayer.magicka
		local comBar = menu:findChild(siphon.id_comBar)
		local pcBar = menu:findChild(siphon.id_pcBar)
		local resource = "magicka"

		if siphon.type == 2 then
			--Undead
			comValue = siphon.ref.mobile.health
			pcValue = tes3.mobilePlayer.health
			resource = "health"
		end

		if ((comValue.current + siphon.interval) <= comValue.base and pcValue.current >= siphon.interval) then
			--Success
			if siphon.type == 1 or siphon.type == 2 then
				tes3.modStatistic({ name = resource, reference = tes3.player, current = (siphon.interval * -1) })
			end
			tes3.modStatistic({ name = resource, reference = siphon.ref, current = siphon.interval })
			comBar.widget.current = comValue.current
			pcBar.widget.current = pcValue.current
			log:trace("" .. siphon.ref.object.name .. " took " .. siphon.interval .. " " .. resource .. " from " .. tes3.player.object.name .. ".")
		else
			--Failure
			tes3.playSound({ sound = "Spell Failure Mysticism" })
		end
		menu:updateLayout()
	end
end

function siphon.onMinus()
	local menu = tes3ui.findMenu(siphon.id_menu)

	if menu then
		--Arcanist
		local comValue = siphon.ref.mobile.magicka
		local pcValue = tes3.mobilePlayer.magicka
		local comBar = menu:findChild(siphon.id_comBar)
		local pcBar = menu:findChild(siphon.id_pcBar)
		local resource = "magicka"
		local msg = "" .. siphon.ref.object.name .. " gave " .. siphon.interval .. " " .. resource .. " to " .. tes3.player.object.name .. "."

		if siphon.type == 2 then
			--Undead
			comValue = siphon.ref.mobile.health
			pcValue = tes3.mobilePlayer.health
			resource = "health"
		elseif siphon.type == 3 then
			comValue = siphon.ref.mobile.health
			pcValue = siphon.ref.mobile.magicka
			resource = "health"
			msg = "" .. siphon.ref.object.name .. " sacrificed " .. siphon.interval .. " " .. resource .. " for " .. siphon.interval .. " magicka."
		end

		if ((pcValue.current  + siphon.interval) <= pcValue.base and comValue.current >= siphon.interval) then
			--Success
			tes3.modStatistic({ name = resource, reference = siphon.ref, current = (siphon.interval * -1) })
			if siphon.type == 1 or siphon.type == 2 then
				tes3.modStatistic({ name = resource, reference = tes3.player, current = siphon.interval })
			elseif siphon.type == 3 then
				tes3.modStatistic({ name = "magicka", reference = siphon.ref, current = siphon.interval * 0.5 })
			end
			comBar.widget.current = comValue.current
			pcBar.widget.current = pcValue.current
			log:trace(msg)
		else
			--Failure
			tes3.playSound({ sound = "Spell Failure Mysticism" })
		end
		menu:updateLayout()
	end
end

function siphon.onInterval()
	local menu = tes3ui.findMenu(siphon.id_menu)

	if menu then
		local button = menu:findChild(siphon.id_interval)

		if string.match(button.text, "1pt") then
            button.text = string.gsub(button.text, "1pt", "5pts")
            siphon.interval = 5
        elseif string.match(button.text, "5pts") then
            button.text = string.gsub(button.text, "5pts", "10pts")
            siphon.interval = 10
		elseif string.match(button.text, "10pts") then
			button.text = string.gsub(button.text, "10pts", "50pts")
            siphon.interval = 50
		elseif string.match(button.text, "50pts") then
			button.text = string.gsub(button.text, "50pts", "100pts")
            siphon.interval = 100
		elseif string.match(button.text, "100pts") then
			button.text = string.gsub(button.text, "100pts", "1pt")
			siphon.interval = 1
		end
		menu:updateLayout()
	end
end


return siphon