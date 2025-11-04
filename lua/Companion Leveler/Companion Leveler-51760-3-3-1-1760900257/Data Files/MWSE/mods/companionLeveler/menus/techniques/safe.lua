local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local safe = {}


function safe.createWindow(ref)
	--Initialize IDs
	safe.id_menu = tes3ui.registerID("kl_safe_menu")
	safe.id_pane = tes3ui.registerID("kl_safe_pane")
	safe.id_pane2 = tes3ui.registerID("kl_safe_pane2")
	safe.id_ok = tes3ui.registerID("kl_safe_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Unlock menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")
	local modData = func.getModData(ref)

	safe.ref = ref
	safe.obj_choices = 0
	safe.spell_choices = 0
	safe.target = nil
	safe.spell = nil
	safe.security = ref.mobile:getSkillStatistic(tes3.skill.security)
	safe.fatigueText = tes3.findGMST(tes3.gmst.sFatigue).value
	safe.securityText = tes3.findGMST(tes3.gmst.sSkillSecurity).value
	safe.trappedText = tes3.findGMST(tes3.gmst.sTrapped).value

	-- Create Menu
	local menu = tes3ui.createMenu { id = safe.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_safe" }
	head_block.autoWidth = true
	head_block.autoHeight = true
	head_block.borderBottom = 5

	--Title/TP Bar Blocks
	local title_block = head_block:createBlock{}
	title_block.width = 275
	title_block.autoHeight = true

	local tp_block = head_block:createBlock{}
	tp_block.width = 275
	tp_block.autoHeight = true

	-- Title
	title_block:createLabel { text = "Choose a target." }

	-- Fatigue Bar
	safe.fat_bar = tp_block:createFillBar({ current = ref.mobile.fatigue.current, max = ref.mobile.fatigue.base, id = safe.id_fat_bar })
	func.configureBar(safe.fat_bar, "small", "green")
	safe.fat_bar.borderLeft = 20

	-- TP Bar
	safe.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = safe.id_tp_bar })
	func.configureBar(safe.tp_bar, "small", "purple")
	safe.tp_bar.borderLeft = 5

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_safe" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- safe Border
	local border = pane_block:createThinBorder { id = "kl_border_safe" }
	border.positionX = 4
	border.positionY = -4
	border.width = 300
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4
	border.borderLeft = 126


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = safe.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane

	--OBJ Choices
	for refe in tes3.getPlayerCell():iterateReferences({ tes3.objectType.door, tes3.objectType.container }) do
		if refe.cell == tes3.getPlayerCell() and refe.disabled == false then
			local pos = refe.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. refe.object.name .. "'s distance: " .. dist .. "")

			if dist < 300 and refe.object.name ~= "" then
				if tes3.getTrap({ reference = refe }) ~= nil or tes3.getLocked({ reference = refe }) then
					safe.obj_choices = safe.obj_choices + 1

					local a = pane:createTextSelect { text = "" .. refe.object.name .. "\nDistance: " .. math.round(dist) .."", id = "kl_safe_obj_btn_" .. safe.obj_choices .. ""}

					a:register("mouseClick", function(e) safe.onSelectTarget(a, refe) end)
				end
			end
		end
	end

	--Calculate Bonuses
	local modifier = safe.security.current
	if modifier > 200 then
		modifier = 200
	end

	safe.fatReduction = math.round(modifier * 0.33)

	--Text Block
	local text_block = menu:createBlock { id = "text_block_safe" }
	text_block.width = 490
	text_block.height = 112
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local base_block = text_block:createBlock {}
	base_block.width = 175
	base_block.height = 112
	base_block.borderAllSides = 4
	base_block.flowDirection = "top_to_bottom"

	local lock_block = text_block:createBlock {}
	lock_block.width = 175
	lock_block.height = 112
	lock_block.borderAllSides = 4
	lock_block.flowDirection = "top_to_bottom"
	lock_block.wrapText = true

	local total_block = text_block:createBlock {}
	total_block.width = 175
	total_block.height = 112
	total_block.borderAllSides = 4
	total_block.flowDirection = "top_to_bottom"
	total_block.wrapText = true

	--Fatigue
	local base_title = base_block:createLabel({ text = "" .. safe.fatigueText .. " Cost:", id = "kl_base_sabo" })
	base_title.color = tables.colors["white"]
	safe.base_fat = base_block:createLabel({ text = "Base: ", id = "kl_sabo_fat" })
	--Reductions
	local reduce_label = base_block:createLabel { text = "Reduction: " .. safe.fatReduction .. "%", id = "kl_sabo_fat_e" }
	func.clTooltip(reduce_label, "skill:18")
	--Totals
	safe.total_fat = base_block:createLabel { text = "Total Cost: ", id = "kl_sabo_fat_t" }

	--Lock Level/trap
	local lock_title = lock_block:createLabel({ text = "Target: " })
	lock_title.color = tables.colors["white"]
	safe.lock_level = lock_block:createLabel { text = "" .. tes3.findGMST(tes3.gmst.sLockLevel).value .. ": ", id = "kl_safe_lock_level" }
	safe.trap_label = lock_block:createLabel { text = "" .. safe.trappedText .. ": ", id = "kl_safe_trap_label" }

	--Chance
	local chance_title = total_block:createLabel({ text = "Success Chance:" })
	chance_title.color = tables.colors["white"]
	func.clTooltip(chance_title, "skill:18")
	safe.chance_label = total_block:createLabel { text = "", id = "kl_safe_chance" }


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	safe.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if not func.spendTP(ref, 2) then return end

		if ref.mobile.fatigue.current < safe.fatCost then
			func.clMessageBox("Not enough " .. safe.fatigueText .. "!")
			return
		end

		--Reset
		menu:destroy()
		tes3ui.leaveMenuMode()

		--Spend Fatigue
		tes3.modStatistic({ reference = ref, name = "fatigue", current = (safe.fatCost * -1) })

		--Roll
		if math.random(0, 99) > safe.chance then
			--Fail
			ref:activate(safe.target)
			tes3.playSound({ sound = "Open Lock Fail", reference = safe.target })
			func.clMessageBox("" .. tes3.findGMST("sLockFail").value .. "")
		else
			--Success

			--Remove Trap
			tes3.setTrap({ reference = safe.target, spell = nil })

			--Unlock
			tes3.unlock({ reference = safe.target })
			tes3.playSound({ sound = "Open Lock", reference = safe.target })
			func.clMessageBox("" .. tes3.findGMST("sLockSuccess").value .. "")
		end

		local owned = tes3.getOwner({ reference = safe.target })

		if owned then
			tes3.triggerCrime{
				type = tes3.crimeType.trespass
			}
		end
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(safe.id_menu)
end

function safe.onSelectTarget(elem, ref)
	local menu = tes3ui.findMenu(safe.id_menu)

	if menu then
		for i = 1, safe.obj_choices do
			local btn = menu:findChild("kl_safe_obj_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4

		safe.target = ref
		safe.lockLevel = tes3.getLockLevel({ reference = ref })
		if safe.lockLevel == nil then
			safe.lockLevel = 0
		end
		safe.trap = tes3.getTrap({ reference = ref })

		--Trap Label
		safe.trap_label.text = "" .. safe.trappedText .. ": ???"
		if safe.trap == nil then
			if safe.security.current >= 25 then
				safe.trap_label.text = "" .. safe.trappedText .. ": " .. tes3.findGMST(tes3.gmst.sNone).value .. ""
			end
		else
			if safe.security.current >= 25 then
				safe.trap_label.text = "" .. safe.trappedText .. ": " .. tes3.findGMST(tes3.gmst.sYes).value .. ""
			end

			if safe.security.current >= 50 then
				safe.trap_label.text = "" .. safe.trappedText .. ": " .. safe.trap.name .. ""
			end

			if safe.security.current >= 75 then
				safe.trap_label:register("help", function(e)
					local tooltip = tes3ui.createTooltipMenu { spell = safe.trap }

					local contentElement = tooltip:getContentElement()
					contentElement.paddingAllSides = 12
					contentElement.childAlignX = 0.5
					contentElement.childAlignY = 0.5
				end)
			end

			if safe.lockLevel == 0 then
				safe.lockLevel = 30
			else
				safe.lockLevel = safe.lockLevel + 10
			end
		end

		safe.chance = math.round(80 - ((safe.lockLevel * 1.5) - safe.security.current))
		safe.chance_label.text = "" .. safe.chance .. "%"
		safe.lock_level.text = "" .. tes3.findGMST(tes3.gmst.sLockLevel).value .. ": " .. safe.lockLevel .. ""

		safe.fatCost = math.round((safe.lockLevel * 2.25) * (1 - (safe.fatReduction * 0.01)))

		safe.base_fat.text = "Base: " .. (safe.lockLevel * 2.25) .. ""
		safe.total_fat.text = "Total Cost: " .. safe.fatCost .. ""

		if safe.target ~= nil then
			safe.ok.widget.state = 1
			safe.ok.disabled = false
		end

		menu:updateLayout()
	end
end


return safe