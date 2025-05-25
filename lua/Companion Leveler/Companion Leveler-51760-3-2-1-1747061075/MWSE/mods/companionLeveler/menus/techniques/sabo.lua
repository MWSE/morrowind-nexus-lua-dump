local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local sabo = {}


function sabo.createWindow(ref)
	--Initialize IDs
	sabo.id_menu = tes3ui.registerID("kl_sabo_menu")
	sabo.id_pane = tes3ui.registerID("kl_sabo_pane")
	sabo.id_pane2 = tes3ui.registerID("kl_sabo_pane2")
	sabo.id_ok = tes3ui.registerID("kl_sabo_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Set Trap menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")
	local modData = func.getModData(ref)

	sabo.ref = ref
	sabo.obj_choices = 0
	sabo.spell_choices = 0
	sabo.target = nil
	sabo.spell = nil
	local enchant = ref.mobile:getSkillStatistic(tes3.skill.enchant)
	sabo.magickaText = tes3.findGMST(tes3.gmst.sMagic).value
	sabo.enchantText = tes3.findGMST(tes3.gmst.sSkillEnchant).value

	-- Create Menu
	local menu = tes3ui.createMenu { id = sabo.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_sabo" }
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
	title_block:createLabel { text = "Choose a target, then choose a trap." }

	-- Magicka Bar
	sabo.mgk_bar = tp_block:createFillBar({ current = ref.mobile.magicka.current, max = ref.mobile.magicka.base, id = sabo.id_mgk_bar })
	func.configureBar(sabo.mgk_bar, "small", "blue")
	sabo.mgk_bar.borderLeft = 20

	-- TP Bar
	sabo.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = sabo.id_tp_bar })
	func.configureBar(sabo.tp_bar, "small", "purple")
	sabo.tp_bar.borderLeft = 5

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_sabo" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- sabo Border
	local border = pane_block:createThinBorder { id = "kl_border_sabo" }
	border.positionX = 4
	border.positionY = -4
	border.width = 267
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Attribute Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_sabo" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 267
	border2.height = 160
	border2.paddingAllSides = 4
	border2.borderAllSides = 4


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = sabo.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	local pane2 = border2:createVerticalScrollPane { id = sabo.id_pane2 }
	pane2.height = 148
	pane2.width = 210
	pane2.widget.scrollbarVisible = true

	--Populate Panes

	--OBJ Choices
	for refe in tes3.getPlayerCell():iterateReferences({ tes3.objectType.door, tes3.objectType.container }) do
		if refe.cell == tes3.getPlayerCell() and refe.disabled == false then
			local pos = refe.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. refe.object.name .. "'s distance: " .. dist .. "")

			if dist < 300 and refe.object.name ~= "" then
				sabo.obj_choices = sabo.obj_choices + 1

				local a = pane:createTextSelect { text = "" .. refe.object.name .. "\nDistance: " .. math.round(dist) .."", id = "kl_sabo_obj_btn_" .. sabo.obj_choices .. ""}

				a:register("mouseClick", function(e) sabo.onSelectTarget(a, refe) end)
			end
		end
	end

	--Spell Choices
	local spellList = tes3.getSpells({ target = ref, spellType = 0, getRaceSpells = false, getBirthsignSpells = false })
	for i = 1, #spellList do
		sabo.spell_choices = sabo.spell_choices + 1
		local a = pane2:createTextSelect { text = "" .. spellList[i].name .. "",  id = "kl_sabo_spell_btn_" .. sabo.spell_choices .. ""}
		a:register("mouseClick", function(e) sabo.onSelectSpell(a, spellList[i].id) end)
		a:register("help", function(e)
            local tooltip = tes3ui.createTooltipMenu { spell = spellList[i] }

            local contentElement = tooltip:getContentElement()
            contentElement.paddingAllSides = 12
            contentElement.childAlignX = 0.5
            contentElement.childAlignY = 0.5
        end)
	end

	--Sort Spells
	pane2:getContentElement():sortChildren(function(c, d)
		local cText
		local dText

		for int = 0, sabo.spell_choices do
			cText = ""
			local cChild = c:findChild("kl_sabo_spell_btn_" .. int .. "")
			if cChild ~= nil then cText = cChild.text break end
		end
		for num = 0, sabo.spell_choices do
			dText = ""
			local dChild = d:findChild("kl_sabo_spell_btn_" .. num .. "")
			if dChild ~= nil then dText = dChild.text break end
		end

		return cText < dText
	end)

	--Calculate Bonuses
	local modifier = enchant.current
	if modifier > 200 then
		modifier = 200
	end

	sabo.mgkReduction = math.round(modifier * 0.33)


	--Text Block
	local text_block = menu:createBlock { id = "text_block_sabo" }
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
	local base_title = base_block:createLabel({ text = "Base Cost:", id = "kl_base_sabo" })
	base_title.color = tables.colors["white"]
	sabo.base_mgk = base_block:createLabel({ text = "" .. sabo.magickaText .. ": ", id = "kl_sabo_mgk" })

	--Enchantments
	local ench_title = ench_block:createLabel({ text = "Cost Reduction:" })
	ench_title.color = tables.colors["white"]
	func.clTooltip(ench_title, "skill:9")
	ench_block:createLabel { text = "" .. sabo.magickaText .. ": " .. sabo.mgkReduction .. "%", id = "kl_sabo_mgk_e" }

	--Totals
	local total_title = total_block:createLabel({ text = "Total Cost:" })
	total_title.color = tables.colors["white"]
	sabo.total_mgk = total_block:createLabel { text = "" .. sabo.magickaText .. ": ", id = "kl_sabo_mgk_t" }


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	sabo.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if not func.spendTP(ref, 3) then return end

		if ref.mobile.magicka.current < sabo.mgkCost then
			tes3.messageBox("Not enough " .. sabo.magickaText .. "!")
			return
		end

		--Reset
		menu:destroy()
		tes3ui.leaveMenuMode()

		--Spend Magicka
		tes3.modStatistic({ reference = ref, name = "magicka", current = (sabo.mgkCost * -1) })

		--Set Trap
		tes3.setTrap({ reference = sabo.target, spell = sabo.spell })
		tes3.playSound({ sound = "alteration hit", reference = sabo.target })
		tes3.createVisualEffect({ object = "VFX_AlterationHit", lifespan = 4, reference = sabo.target })

		local owned = tes3.getOwner({ reference = sabo.target })

		if owned then
			tes3.triggerCrime{
				type = tes3.crimeType.trespass
			}
		end
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(sabo.id_menu)
end

function sabo.onSelectTarget(elem, ref)
	local menu = tes3ui.findMenu(sabo.id_menu)

	if menu then
		for i = 1, sabo.obj_choices do
			local btn = menu:findChild("kl_sabo_obj_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4

		sabo.target = ref

		if sabo.target ~= nil and sabo.spell ~= nil then
			sabo.ok.widget.state = 1
			sabo.ok.disabled = false
		end

		menu:updateLayout()
	end
end

function sabo.onSelectSpell(elem, id)
	local menu = tes3ui.findMenu(sabo.id_menu)

	if menu then
		for i = 1, sabo.spell_choices do
			local btn = menu:findChild("kl_sabo_spell_btn_" .. i .. "")
			btn.widget.state = 1
		end

		elem.widget.state = 4
		sabo.spell = id

		local spell = tes3.getObject(id)
		sabo.mgkCost = math.round((spell.magickaCost * 3) * (1 - (sabo.mgkReduction * 0.01)))

		sabo.base_mgk.text = "" .. sabo.magickaText .. ": " .. (spell.magickaCost * 3) .. ""
		sabo.total_mgk.text = "" .. sabo.magickaText .. ": " .. sabo.mgkCost .. ""


		if sabo.target ~= nil and sabo.spell ~= nil then
			sabo.ok.widget.state = 1
			sabo.ok.disabled = false
		end

		menu:updateLayout()
	end
end

return sabo