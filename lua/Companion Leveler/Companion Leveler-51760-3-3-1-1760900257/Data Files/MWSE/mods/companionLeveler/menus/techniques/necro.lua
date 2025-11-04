local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local necro = {}


function necro.createWindow(ref)
	--Initialize IDs
	necro.id_menu = tes3ui.registerID("kl_necro_menu")
	necro.id_pane = tes3ui.registerID("kl_necro_pane")
	necro.id_ok = tes3ui.registerID("kl_necro_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Necro menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")

	local conjuration = ref.mobile:getSkillStatistic(13)
	local willpower = ref.mobile.attributes[3]
	local modData = func.getModData(ref)
	necro.limit = 1

	if willpower.current >= 75 then
		necro.limit = necro.limit + 1
	end

	if willpower.current >= 150 then
		necro.limit = necro.limit + 1
	end

	-- Create window and frame
	local menu = tes3ui.createMenu { id = necro.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_necro" }
	head_block.autoWidth = true
	head_block.autoHeight = true
	head_block.borderBottom = 5

	--Title/TP Bar Blocks
	local title_block = head_block:createBlock{}
	title_block.width = 265
	title_block.autoHeight = true

	local tp_block = head_block:createBlock{}
	tp_block.width = 265
	tp_block.autoHeight = true

	-- Title
	title_block:createLabel { text = "Use which corpse? Willpower Limit: " .. necro.limit .. "" }

	-- TP Bar
	necro.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = necro.id_tp_bar })
	func.configureBar(necro.tp_bar, "small", "purple")
	necro.tp_bar.borderLeft = 145

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_necro" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- Pane Border
	local border = pane_block:createThinBorder { id = "kl_border_necro" }
	border.positionX = 4
	border.positionY = -4
	border.width = 210
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Material Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_necro" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 308
	border2.height = 170
	border2.paddingAllSides = 4
	border2.wrapText = true
	border2.flowDirection = tes3.flowDirection.topToBottom

	----Populate-----------------------------------------------------------------------------------------------------

	--Materials
	local mTitle = border2:createLabel { text = "Corpse Quality", id = "kl_necro_mTitle" }
	mTitle.wrapText = true
	mTitle.justifyText = tes3.justifyText.center
	mTitle.borderBottom = 20

	local mats = border2:createLabel { text = "", id = "kl_necro_mats_0"}
	mats.wrapText = true
	mats.justifyText = tes3.justifyText.center

	necro.mats = mats

	--Pane
	local pane = border:createVerticalScrollPane { id = necro.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane
	local ghost = tes3.getObject("ancestor_ghost")
	local walker = tes3.getObject("bonewalker")
	local greaterWalker = tes3.getObject("Bonewalker_Greater")
	local lord = tes3.getObject("bonelord")

	necro.total = 0

	for mobileActor in tes3.iterate(tes3.worldController.allMobileActors) do
		if (mobileActor.cell == tes3.getPlayerCell() and mobileActor.reference.object.objectType == tes3.objectType.npc and mobileActor.isDead) then
			local pos = mobileActor.reference.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. mobileActor.reference.object.name .. "'s distance: " .. dist .. "")

			if dist < 750 then
				necro.total = necro.total + 1

				local a = pane:createTextSelect { text = "" .. mobileActor.reference.object.name .. "", id = "kl_necro_btn_" .. necro.total .. ""}
				local lvl = mobileActor.reference.object.level
				if func.checkModData(mobileActor.reference) == true then
					local tempModData = func.getModData(mobileActor.reference)
					lvl = tempModData.level
				end
				local obj
				local req
				local tp

				if lvl < 4 then
					obj = ghost
					req = 15
					tp = 2
				elseif lvl >= 4 and lvl < 8 then
					obj = walker
					req = 25
					tp = 4
				elseif lvl >= 8 and lvl < 12 then
					obj = greaterWalker
					req = 50
					tp = 6
				elseif lvl >= 12 then
					obj = lord
					req = 75
					tp = 8
				end

				a:register("mouseClick", function(e) necro.onSelect(a, obj, mobileActor.reference, req, tp, pos) end)
			end
		end
	end

	--Calculate Bonuses
	local modifier = conjuration.current
	if modifier > 200 then
		modifier = 200
	end

	necro.hthBonus = math.round(modifier * 0.25)
	necro.mgkBonus = math.round(modifier * 0.25)
	necro.fatBonus = math.round(modifier * 0.50)
	necro.strBonus = math.round(modifier * 0.10)

	--Text Block
	local text_block = menu:createBlock { id = "text_block_necro" }
	text_block.width = 490
	text_block.height = 112
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local base_block = text_block:createBlock {}
	base_block.width = 175
	base_block.height = 112
	base_block.borderAllSides = 4
	base_block.flowDirection = "top_to_bottom"

	local ench_block = text_block:createBlock {}
	ench_block.width = 175
	ench_block.height = 112
	ench_block.borderAllSides = 4
	ench_block.flowDirection = "top_to_bottom"
	ench_block.wrapText = true

	local total_block = text_block:createBlock {}
	total_block.width = 175
	total_block.height = 112
	total_block.borderAllSides = 4
	total_block.flowDirection = "top_to_bottom"
	total_block.wrapText = true

	--Base Statistics
	local base_title = base_block:createLabel({ text = "Base Statistics:", id = "kl_att_necro" })
	base_title.color = { 1.0, 1.0, 1.0 }
	necro.base_hth = base_block:createLabel({ text = "Health: ", id = "kl_necro_hth" })
	necro.base_mgk = base_block:createLabel({ text = "Magicka: ", id = "kl_necro_mgk" })
	necro.base_fat = base_block:createLabel({ text = "Fatigue: ", id = "kl_necro_fat" })
	necro.base_str = base_block:createLabel({ text = "Strength: ", id = "kl_necro_str" })

	--Enchantments
	local ench_title = ench_block:createLabel({ text = "Enhancements:" })
	ench_title.color = { 1.0, 1.0, 1.0 }
	func.clTooltip(ench_title, "skill:13")
	ench_block:createLabel { text = "Health: +" .. necro.hthBonus .. "", id = "kl_necro_hth_e" }
	ench_block:createLabel { text = "Magicka: +" .. necro.mgkBonus .. "", id = "kl_necro_mgk_e" }
	ench_block:createLabel { text = "Fatigue: +" .. necro.fatBonus .. "", id = "kl_necro_fat_e" }
	ench_block:createLabel { text = "Strength: +" .. necro.strBonus .. "", id = "kl_necro_str_e" }

	--Totals
	local total_title = total_block:createLabel({ text = "Total Statistics:" })
	total_title.color = { 1.0, 1.0, 1.0 }
	necro.total_hth = total_block:createLabel { text = "Health: ", id = "kl_necro_hth_t" }
	necro.total_mgk = total_block:createLabel { text = "Magicka: ", id = "kl_necro_mgk_t" }
	necro.total_fat = total_block:createLabel { text = "Fatigue: ", id = "kl_necro_fat_t" }
	necro.total_str = total_block:createLabel { text = "Strength: ", id = "kl_necro_str_t" }

	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	necro.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()

		if conjuration.current < necro.req then
			func.clMessageBox("" .. ref.object.name .. " is not skilled enough to enthrall " .. necro.ref.object.name .. ".")
			return
		end

		if modData.tp_current < necro.tp then
			func.clMessageBox("Not enough Technique Points!")
			return
		end

		local thralls = 0

		for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
			if (mobileActor.reference.object.objectType == tes3.objectType.creature) and mobileActor.reference.object.type == 2
			and string.startswith(mobileActor.reference.object.name, "Summoned") == false then
				thralls = thralls + 1
				if thralls >= necro.limit then
					func.clMessageBox("" .. ref.object.name .. "'s Willpower can only extend to " .. necro.limit .. " minion(s)!")
					return
				end
			end
		end

		--Spend TP
		modData.tp_current = modData.tp_current - necro.tp

		--Raise Undead
		tes3.createVisualEffect({ object = "VFX_DefaultHit", lifespan = 3, reference = necro.ref })
		local zombo = tes3.createReference({ object = necro.obj, position = necro.pos, orientation = tes3.player.orientation:copy(), cell = tes3.player.cell })
		tes3.createVisualEffect({ object = "VFX_DefaultHit", lifespan = 3, reference = zombo })
		tes3.playSound({ sound = "conjuration hit", reference = zombo })
		zombo.mobile.fight = 40
		tes3.setAIFollow({ reference = zombo, target = ref })

		necro.ref:delete()

		--Apply Bonuses
		tes3.modStatistic({ name = "health", value = necro.hthBonus, reference = zombo })
		tes3.modStatistic({ name = "magicka", value = necro.mgkBonus, reference = zombo })
		tes3.modStatistic({ name = "fatigue", value = necro.fatBonus, reference = zombo })
		tes3.modStatistic({ attribute = tes3.attribute.strength, value = necro.strBonus, reference = zombo })

		menu:destroy()
		tes3ui.leaveMenuMode()
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(necro.id_menu)
end

function necro.onSelect(elem, obj, ref, req, tp, pos)
	local menu = tes3ui.findMenu(necro.id_menu)

	if menu then
		for i = 1, necro.total do
			local btn = menu:findChild("kl_necro_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4
		necro.obj = obj
		necro.ref = ref
		necro.tp = tp
		necro.pos = pos
		necro.req = req

		necro.base_hth.text = "Health: " .. obj.health .. ""
		necro.base_mgk.text = "Magicka: " .. obj.magicka .. ""
		necro.base_fat.text = "Fatigue: " .. obj.fatigue .. ""
		necro.base_str.text = "Strength: " .. obj.attributes[1] .. ""

		necro.total_hth.text = "Health: " .. obj.health + necro.hthBonus .. ""
		necro.total_mgk.text = "Magicka: " .. obj.magicka + necro.mgkBonus .. ""
		necro.total_fat.text = "Fatigue: " .. obj.fatigue + necro.fatBonus .. ""
		necro.total_str.text = "Strength: " .. obj.attributes[1] + necro.strBonus .. ""

		necro.mats.text = "" .. ref.object.name .. ": Level " .. ref.object.level .."\n\n" .. obj.name .. "\nConjuration Required: " .. req .. "\nTP: " .. tp .. ""

		necro.ok.widget.state = 1
		necro.ok.disabled = false

		menu:updateLayout()
	end
end


return necro