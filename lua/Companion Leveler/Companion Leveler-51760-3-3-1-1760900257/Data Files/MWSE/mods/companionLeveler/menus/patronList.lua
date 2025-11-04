local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")



local pat = {}


function pat.pickPatron(ref, aID)
	--Initialize IDs
	pat.id_menu = tes3ui.registerID("kl_patron_menu")
	pat.id_pane = tes3ui.registerID("kl_patron_pane")
	pat.id_ok = tes3ui.registerID("kl_patron_ok")
	pat.id_growth = tes3ui.registerID("kl_patron_growth_btn")
	pat.id_image = tes3ui.registerID("kl_patron_image")

	log = logger.getLogger("Companion Leveler")
	log:debug("Patron menu initialized.")

	if (ref) then
		pat.ref = ref
		pat.aID = aID
	end

	pat.total = 0

	if (tes3ui.findMenu(pat.id_menu) ~= nil) then
		return
	end
	log:debug("Patron menu triggered.")

	-- Create window and frame
	local menu = tes3ui.createMenu { id = pat.id_menu, fixedFrame = true }
	menu.alpha = 1.0

	-- Create layout
	local name = ref.object.name
	--local modData = func.getModData(ref)

	local input_label = menu:createLabel { text = "Select " .. name .. "'s Patron:" }
	input_label.borderBottom = 12
	if aID == 139 then
		input_label.text = "Choose a deity for " .. ref.object.name .. " to serve."
	end

	--Pane and Image Block
	local pane_block = menu:createBlock { id = "pane_block_patron" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	local border = pane_block:createThinBorder { id = "kl_border_patron" }
	border.width = 400
	border.height = 225

	--Pane
	local pane = border:createVerticalScrollPane { id = pat.id_pane }
	pane.height = 225
	pane.width = 400
	pane.widget.scrollbarVisible = true

	--Populate Pane
	if aID == 139 then
		for i = 1, #tables.patrons do
			pat.total = pat.total + 1
			local a = pane:createTextSelect({ text = "" .. tables.patrons[i] .. "", id = "kl_patron_btn_" .. pat.total .. "" })
			a:register("mouseClick", function(e) pat.onSelect(a, i)end)
			if i < 10 then
				a.widget.idle = tables.colors["blue"]
				a.widget.idleActive = tables.colors["white"]
			else
				a.widget.idle = tables.colors["red"]
				a.widget.idleActive = tables.colors["white"]
			end
			func.patronTooltip(a, i)
			if i == 14 then
				local werewolf = tes3.getReference("kl_werewolf_companion")
				if werewolf then
					a.disabled = true
					a.widget.state = tes3.uiState.disabled
				end
			end
		end
	end

	--Sort Spells
	pane:getContentElement():sortChildren(function(c, d)
		local cText
		local dText

		for int = 1, pat.total do
			cText = ""
			local cChild = c:findChild("kl_patron_btn_" .. int .. "")
			if cChild ~= nil then cText = cChild.text break end
		end
		for num = 1, pat.total do
			dText = ""
			local dChild = d:findChild("kl_patron_btn_" .. num .. "")
			if dChild ~= nil then dText = dChild.text break end
		end

		return cText < dText
	end)

	--Text Blocks
	local text_block = menu:createBlock { id = "text_block" }
	text_block.width = 400
	text_block.height = 330
	text_block.flowDirection = "top_to_bottom"
	text_block.borderTop = 16

	local msg_block = text_block:createBlock {}
	msg_block.width = 400
	msg_block.height = 100
	msg_block.flowDirection = "top_to_bottom"

	local gift_block = text_block:createBlock {}
	gift_block.width = 400
	gift_block.height = 110
	gift_block.flowDirection = "top_to_bottom"
	gift_block.borderTop = 10
	gift_block.borderBottom = 10

	local duty_block = text_block:createBlock {}
	duty_block.width = 400
	duty_block.height = 110
	duty_block.flowDirection = "top_to_bottom"

	--Message
	local msg = msg_block:createLabel({ text = "", id = "kl_msg" })
	msg.wrapText = true
	msg.justifyText = tes3.justifyText.center

	--Duties
	local duty = duty_block:createLabel({ text = "Conditions:", id = "kl_duty_label" })
	duty.color = tables.colors["white"]

	local duty2 = duty_block:createLabel({ text = "", id = "kl_duty" })
	duty2.wrapText = true
	duty2.borderLeft = 2

	--Gifts
	local gift = gift_block:createLabel({ text = "Gifts:", id = "kl_gift_label" })
	gift.color = tables.colors["white"]

	local gift2 = gift_block:createLabel({ text = "", id = "kl_gift" })
	gift2.wrapText = true
	gift2.borderLeft = 2


	--Button Block
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0 -- width is 100% parent width
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 8

	pat.button_ok = button_block:createButton { id = pat.id_ok, text = tes3.findGMST("sOK").value }
	pat.button_ok.disabled = true

	-- Events
	pat.button_ok:register(tes3.uiEvent.mouseClick, pat.onOK)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(pat.id_menu)
end

----Events----------------------------------------------------------------------------------------------------------
function pat.onOK()
	local menu = tes3ui.findMenu(pat.id_menu)
	local modData = func.getModData(pat.ref)
	if (menu) then
		if pat.aID == 139 then
			--Cleric
			func.clMessageBox("" .. pat.ref.object.name .. " entered the service of " .. pat.patron .. ".")
			log:info("" .. pat.ref.object.name .. " entered the service of " .. pat.patron .. ".")
			modData["patron"] = pat.id
			modData["tributePaid"] = true
			modData["tributeHours"] = 0
			tes3.addSpell({ reference = pat.ref, spell = "kl_ability_patron_" .. pat.id .. "" })

			if pat.id == 11 then
				modData["bloodKarma"] = 0.00
			end

			if pat.id == 13 then
				modData.tp_max = modData.tp_max + 3
				modData.tp_current = modData.tp_current + 3
			end

			if pat.id == 14 then
				modData["hircineHunt"] =  tables.hircineHunts[math.random(1, #tables.hircineHunts)]
				modData["lycanthropicPower"] = 1
				func.clMessageBox("" .. pat.ref.object.name .. " was issued a new hunt for " .. modData.hircineHunt[2] .. " " .. tes3.getObject(modData.hircineHunt[1]).name .. ".")
			end

			if pat.id == 15 then
				modData["orderStreak"] = 1
				modData["lastClass"] = modData.class
			end

			if pat.id == 20 then
				modData["soulEnergy"] = 0
			end
		end
		menu:destroy()
		tes3ui.leaveMenuMode()
		func.updateIdealSheet(pat.ref)
	end
end

function pat.onSelect(elem, id)
	local menu = tes3ui.findMenu(pat.id_menu)
	if (menu) then

		pat.patron = elem.text
		pat.id = id

		--States
		for n = 0, pat.total do
			local btn = menu:findChild("kl_patron_btn_" .. n .. "")
			if btn then
				if btn.widget.state == 4 then
					btn.widget.state = 1
				end
			end
		end

		elem.widget.state = 4

		--Change Text
		local msg = menu:findChild("kl_msg")
		msg.text = "" .. tables.patronMessages[id] .. ""

		local duty = menu:findChild("kl_duty")
		duty.text = tables.patronDuties[id]

		local gift = menu:findChild("kl_gift")
		gift.text = tables.patronGifts[id]

		local cond = menu:findChild("kl_duty_label")
		if id < 10 then
			cond.text = "Conditions:"
		else
			cond.text = "Tribute:"
		end

		log:debug("" .. pat.ref.object.name .. " chose to serve " .. pat.patron .. ".")
		pat.button_ok.disabled = false
		menu:updateLayout()
	end
end






return pat