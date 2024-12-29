local logger = require("logging.logger")
local config = require("companionLeveler.config")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local cast = {}


function cast.createWindow(ref)
	--Initialize IDs
	cast.id_menu = tes3ui.registerID("kl_cast_menu")
	cast.id_pane = tes3ui.registerID("kl_cast_pane")
	cast.id_pane2 = tes3ui.registerID("kl_cast_pane2")
	cast.id_ok = tes3ui.registerID("kl_cast_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("cast menu initialized.")

	local root = require("companionLeveler.menus.root")

	cast.caster = ref
	cast.npc_choices = 0
	cast.spell_choices = 0

	-- Create Menu
	local menu = tes3ui.createMenu { id = cast.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_cast" }
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
	title_block:createLabel { text = "Cast which spell?" }

	-- Magicka Bar
	cast.mgk_bar = tp_block:createFillBar({ current = ref.mobile.magicka.current, max = ref.mobile.magicka.base, id = cast.id_mgk_bar })
	func.configureBar(cast.mgk_bar, "small", "blue")
	cast.mgk_bar.borderLeft = 155

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_cast" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- cast Border
	local border = pane_block:createThinBorder { id = "kl_border_cast" }
	border.positionX = 4
	border.positionY = -4
	border.width = 267
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Attribute Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_cast" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 267
	border2.height = 160
	border2.paddingAllSides = 4
	border2.borderAllSides = 4


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = cast.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	cast.pane2 = border2:createVerticalScrollPane { id = cast.id_pane2 }
	cast.pane2.height = 148
	cast.pane2.width = 210
	cast.pane2.widget.scrollbarVisible = true

	--Populate Panes

	--Choices
	for mobileActor in tes3.iterate(tes3.worldController.allMobileActors) do
		if mobileActor.cell == tes3.getPlayerCell() then
			local pos = mobileActor.reference.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. mobileActor.reference.object.name .. "'s distance: " .. dist .. "")

			if dist < 700 and mobileActor.reference.object.name ~= "" and mobileActor.reference.object.name ~= "<spawner>" then
				cast.npc_choices = cast.npc_choices + 1

				local a = cast.pane2:createTextSelect { text = "" .. mobileActor.reference.object.name .. "", id = "kl_cast_npc_btn_" .. cast.npc_choices .. ""}

				a:register("mouseClick", function(e) cast.onSelectTarget(a, mobileActor) end)
			end
		end
	end

	--Spell Choices
	local spellList = tes3.getSpells({ target = ref, spellType = 0, getRaceSpells = false, getBirthsignSpells = false })
	for i = 1, #spellList do
		cast.spell_choices = cast.spell_choices + 1
		local a = pane:createTextSelect { text = "" .. spellList[i].name .. "",  id = "kl_cast_spell_btn_" .. cast.spell_choices .. ""}
		a:register("mouseClick", function(e) cast.onSelectSpell(a, spellList[i].id) end)
		a:register("help", function(e)
            local tooltip = tes3ui.createTooltipMenu { spell = spellList[i] }

            local contentElement = tooltip:getContentElement()
            contentElement.paddingAllSides = 12
            contentElement.childAlignX = 0.5
            contentElement.childAlignY = 0.5
        end)
	end

	--Sort Spells
	pane:getContentElement():sortChildren(function(c, d)
		local cText
		local dText

		for int = 0, cast.spell_choices do
			cText = ""
			local cChild = c:findChild("kl_cast_spell_btn_" .. int .. "")
			if cChild ~= nil then cText = cChild.text break end
		end
		for num = 0, cast.spell_choices do
			dText = ""
			local dChild = d:findChild("kl_cast_spell_btn_" .. num .. "")
			if dChild ~= nil then dText = dChild.text break end
		end

		return cText < dText
	end)

	--Text Block
	local text_block = menu:createBlock { id = "text_block_cast" }
	text_block.autoWidth = true
	text_block.autoHeight = true
	text_block.borderAllSides = 10
	text_block.flowDirection = "top_to_bottom"

	--Cast Chance
	local chance_title = text_block:createLabel({ text = "Cast Chance:" })
	chance_title.color = tables.colors["white"]
	cast.cast_chance = text_block:createLabel { text = "", id = "kl_cast_cast_chance" }
	text_block:createLabel { text = "" }

	--Magicka Cost
	local cost_title = text_block:createLabel({ text = "Magicka Cost:" })
	cost_title.color = tables.colors["white"]
	cast.mgk_cost = text_block:createLabel { text = "", id = "kl_cast_mgk_cost" }


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	cast.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		--Reset
		menu:destroy()
		tes3ui.leaveMenuMode()

		--Cast Spell
		tes3.cast({ reference = cast.caster, target = cast.target, spell = cast.spell, instant = true, alwaysSucceeds = false })

		if cast.target ~= tes3.mobilePlayer and cast.target ~= cast.caster.mobile then
			if cast.isSpellHostile(tes3.getObject(cast.spell)) then
				local isHostile
				for actor in tes3.iterate(tes3.mobilePlayer.hostileActors) do
					if actor.reference == cast.target then
						isHostile = true
					end
				end
				if not isHostile then
					tes3.triggerCrime{
						victim = cast.target,
						type = tes3.crimeType.attack
					}
				end
				cast.target:startCombat(cast.caster.mobile)
			end
		end
	end)
	button_cancel:register("mouseClick", function() menu:destroy() root.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(cast.id_menu)
end

function cast.onSelectTarget(elem, mobileActor)
	local menu = tes3ui.findMenu(cast.id_menu)

	if menu then
		for i = 1, cast.npc_choices do
			local btn = menu:findChild("kl_cast_npc_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4

		cast.target = mobileActor

		if cast.target ~= nil and cast.spell ~= nil then
			cast.ok.widget.state = 1
			cast.ok.disabled = false
		end

		menu:updateLayout()
	end
end

function cast.onSelectSpell(elem, id)
	local menu = tes3ui.findMenu(cast.id_menu)

	if menu then
		for i = 1, cast.spell_choices do
			local btn = menu:findChild("kl_cast_spell_btn_" .. i .. "")
			btn.widget.state = 1
		end

		elem.widget.state = 4
		cast.spell = id

		local spell = tes3.getObject(id)

		cast.cast_chance.text = "" .. math.round(spell:calculateCastChance({ checkMagicka = true,  caster = cast.caster })).. "%"
		cast.mgk_cost.text = "" .. spell.magickaCost .. ""


		if cast.target ~= nil and cast.spell ~= nil then
			cast.ok.widget.state = 1
			cast.ok.disabled = false
		end

		menu:updateLayout()
	end
end

--- @param magicSource tes3spell|tes3enchantment|tes3alchemy
function cast.isSpellHostile(magicSource)
	log = logger.getLogger("Companion Leveler")
	log:debug("Hostile spell check triggered.")
    for _, effect in ipairs(magicSource.effects) do
        if (effect.object.isHarmful) then
            -- If one of the spell's effects is harmful, then
            -- `true` is returned and function ends here.
			log:debug("Spell is hostile.")
            return true
        end
    end
    -- If no harmful effect was found then return `false`.
	log:debug("Spell is not hostile.")
    return false
end

return cast