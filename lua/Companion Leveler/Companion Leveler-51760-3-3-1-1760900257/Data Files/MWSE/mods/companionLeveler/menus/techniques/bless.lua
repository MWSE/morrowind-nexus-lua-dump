local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local bless = {}


function bless.createWindow(ref)
	local menu = tes3ui.createMenu { id = "kl_simple_list", fixedFrame = true }
    menu.alpha = 1.0

	local label = menu:createLabel { text = "Choose a blessing. TP Cost: 3" }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 16

	local border = menu:createThinBorder {}
    border.width = 270
    border.height = 470
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 270
    pane.height = 470
    pane.widget.scrollbarVisible = true

	--Populate Pane
	for i = 1, 9 do
		local spell = tes3.getObject("kl_spell_creBlessing_" .. i .. "")
		local a = pane:createTextSelect { text = "" .. spell.name .. "", id = "kl_creBlessing_btn_" .. i .. ""}

		a:register("help", function(e)
			local tooltip = tes3ui.createTooltipMenu { spell = spell }
			local contentElement = tooltip:getContentElement()
			contentElement.paddingAllSides = 12
			contentElement.childAlignX = 0.5
			contentElement.childAlignY = 0.5
		end)
		a:register("mouseClick", function(e) bless.onSelect(a, spell) end)
	end

	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	bless.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		local once = true

		for i = 1, 9 do
			local affected = tes3.isAffectedBy({ reference = tes3.player, object = "kl_spell_creBlessing_" .. i .. ""})
			if affected then
				once = false
				break
			end
		end

		if not once then func.clMessageBox("Only one blessing may be channeled at once.") return end

		if not func.spendTP(ref, 3) then return end

		--Reset
		local tech = require("companionLeveler.menus.techniques.techniques")
		menu:destroy()
		tech.menu:destroy()
		tes3ui.leaveMenuMode()

		--Bestow Blessing
		local party = func.partyTable()
		for i = 1, #party do
			tes3.cast({spell = bless.spell, reference = party[i], target = party[i], bypassResistances = true, instant = true })
		end

		func.clMessageBox("" .. ref.object.name .. " channels the " .. bless.spell.name .. "!")
	end)
	button_cancel:register("mouseClick", function() menu:destroy() end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode("kl_simple_list")
end

function bless.onSelect(ele, spell)
	local menu = tes3ui.findMenu("kl_simple_list")
	if (menu) then
		--States
		for n = 0, 9 do
			local id2 = menu:findChild("kl_creBlessing_btn_" .. n .. "")
			if id2 then
				if id2.widget.state == 4 then
					id2.widget.state = 1
				end
			end
		end

		ele.widget.state = 4
		bless.spell = spell

		bless.ok.disabled = false
		bless.ok.widget.state = 1
		menu:updateLayout()
	end
end

return bless