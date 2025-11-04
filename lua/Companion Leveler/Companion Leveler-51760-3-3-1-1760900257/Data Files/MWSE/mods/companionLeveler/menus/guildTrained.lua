local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")



local guild = {}


function guild.pickFaction(ref, aID)
	--Initialize IDs
	guild.id_menu = tes3ui.registerID("kl_faction_menu")
	guild.id_pane = tes3ui.registerID("kl_faction_pane")
	guild.id_ok = tes3ui.registerID("kl_faction_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Faction menu initialized.")

	if (ref) then
		guild.ref = ref
		guild.aID = aID
	end

	guild.total = 0

	if (tes3ui.findMenu(guild.id_menu) ~= nil) then
		return
	end
	log:debug("Faction menu triggered.")

	-- Create window and frame
	local menu = tes3ui.createMenu { id = guild.id_menu, fixedFrame = true }
	menu.alpha = 1.0

	-- Create layout
	local name = ref.object.name
	local modData = func.getModData(ref)

	local input_label = menu:createLabel { text = "Select " .. name .. "'s Faction:" }
	input_label.borderBottom = 12

	if aID == 84 then
		input_label.text = "Select another Faction for " .. name .. "."
	end

	--Pane and Image Block
	local pane_block = menu:createBlock { id = "pane_block" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	local border = pane_block:createThinBorder { id = "kl_border" }
	border.width = 400
	border.height = 200

	--Pane
	local pane = border:createVerticalScrollPane { id = guild.id_pane }
	pane.height = 200
	pane.width = 400
	pane.widget.scrollbarVisible = true

	--Populate Pane
	for i = 1, #tables.factions do
		local temp = tes3.getFaction(tables.factions[i])
		if temp ~= nil then
			local found = false
			if modData.guildTraining then
				for n = 1, #modData.guildTraining do
					if temp.id == modData.guildTraining[n] then
						found = true
						break
					end
				end
			end
			if not found then
				log:debug("Faction: " .. temp.name .. ", Reputation: " .. temp.playerReputation .. ", Source: " .. temp.sourceMod .. "")

				guild.total = guild.total + 1
				local a = pane:createTextSelect({ text = "" .. temp.name .. "", id = "kl_guild_btn_" .. guild.total .. "" })
				a:register("mouseClick", function(e) guild.onSelect(a, temp, i)end)
			end
		end
	end

	--No Choices
	if guild.total == 0 then
		func.clMessageBox("No valid factions found!")
		log:warn("No valid factions found!")
		menu:destroy()
		tes3ui.leaveMenuMode()
	end

	--Text Blocks
	local text_block = menu:createBlock { id = "text_block" }
	text_block.width = 400
	text_block.height = 120
	text_block.flowDirection = "left_to_right"
	text_block.borderTop = 12

	local spec_block = text_block:createBlock {}
	spec_block.width = 155
	spec_block.height = 108
	spec_block.borderAllSides = 4
	spec_block.flowDirection = "top_to_bottom"

	local major_block = text_block:createBlock {}
	major_block.width = 155
	major_block.height = 108
	major_block.borderAllSides = 4
	major_block.flowDirection = "top_to_bottom"
	major_block.borderLeft = 60

	--Ability
	local kl_ability = spec_block:createLabel({ text = "Faction Ability:", id = "kl_ability" })
	kl_ability.color = tables.colors["white"]
	spec_block:createLabel({ text = "", id = "kl_ability1" })

	--Attributes
	local kl_att = spec_block:createLabel({ text = "Favored Attributes:", id = "kl_att" })
	kl_att.color = tables.colors["white"]
	kl_att.borderTop = 18

	spec_block:createLabel({ text = "", id = "kl_att1" })
	spec_block:createLabel({ text = "", id = "kl_att2" })

	--Major skills
	local kl_major = major_block:createLabel({ text = "Favored Skills:", id = "kl_major" })
	kl_major.color = tables.colors["white"]
	for i = 1, 7 do
		major_block:createLabel { text = "", id = "kl_major" .. i .. "" }
	end

	--Friends and Enemies maybe?


	--Button Block
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0 -- width is 100% parent width
	button_block.autoHeight = true
	button_block.childAlignX = 1.0 -- right content alignment
	button_block.borderTop = 30

	guild.button_ok = button_block:createButton { id = guild.id_ok, text = tes3.findGMST("sOK").value }
	guild.button_ok.disabled = true

	-- Events
	guild.button_ok:register(tes3.uiEvent.mouseClick, guild.onOK)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(guild.id_menu)
end

----Events----------------------------------------------------------------------------------------------------------
function guild.onOK()
	local menu = tes3ui.findMenu(guild.id_menu)
	local modData = func.getModData(guild.ref)
	if (menu) then
		func.clMessageBox("" .. guild.ref.object.name .. " received guild training. (" .. guild.faction.name .. ")")
		log:info("" .. guild.ref.object.name .. " received guild training. (" .. guild.faction.name .. ")")

		if not modData.guildTraining then
			modData["guildTraining"] = { guild.faction.id }
		else
			if guild.aID == 82 then
				modData.guildTraining[1] = guild.faction.id
			elseif guild.aID == 84 then
				modData.guildTraining[2] = guild.faction.id
			end
		end

		local found2 = false
		for i = 1, #modData.factions do
			if guild.faction.id == modData.factions[i] then
				found2 = true
				break
			end
		end

		if not found2 then
			table.insert(modData.factions, guild.faction.id)
		else
			func.clMessageBox("" .. guild.ref.object.name .. " was already a member of the " .. guild.faction.name .. " faction.")
		end

		tes3.addSpell({ reference = guild.ref, spell = "kl_ability_gTrained_" .. guild.id .. "" })

		if guild.id == 1 then
			modData.tp_current = modData.tp_current + 1
			modData.tp_max = modData.tp_max + 1
		end

		if guild.id == 7 then
			modData.tp_current = modData.tp_current + 5
			modData.tp_max = modData.tp_max + 5
		end

		if guild.id == 21 then
			modData.tp_current = modData.tp_current + 1
			modData.tp_max = modData.tp_max + 1
		end

		menu:destroy()
		tes3ui.leaveMenuMode()
		func.updateIdealSheet(guild.ref)
		
		--Faction Check
		if #modData.factions > 3 then
			local faction1, faction2, faction3, faction4 = tes3.getFaction(modData.factions[1]), tes3.getFaction(modData.factions[2]), tes3.getFaction(modData.factions[3]), tes3.getFaction(modData.factions[4])
			tes3.messageBox({ message = "Companions may join up to 3 factions.\n\nChoose a faction to renounce.\nBonuses from abilities still apply.\n\n",
				buttons = { "" ..faction1.name .. "", "" .. faction2.name .. "", "" .. faction3.name .. "", "" .. faction4.name .. "" },
				callback = guild.forgetFaction })
		end
	end
end

function guild.onSelect(elem, faction, id)
	local menu = tes3ui.findMenu(guild.id_menu)
	if (menu) then
		guild.faction = faction
		guild.id = id

		--States
		for n = 0, guild.total do
			local id2 = menu:findChild("kl_guild_btn_" .. n .. "")
			if id2 then
				if id2.widget.state == 4 then
					id2.widget.state = 1
				end
			end
		end

		elem.widget.state = 4

		--Change Text
		local spellObject = tes3.getObject("kl_ability_gTrained_" .. id .. "")
		local sText = menu:findChild("kl_ability1")
		sText.text = "" .. spellObject.name .. ""
		func.guildTooltip(sText, id)

		local mAttributes = faction.attributes
		for n = 1, 2 do
			local text = menu:findChild("kl_att" .. n .. "")
			text.text = tables.capitalization[mAttributes[n]]
		end

		local mSkills = faction.skills
		for n = 1, 7 do
			local text = menu:findChild("kl_major" .. n .. "")
			text.text = tes3.skillName[mSkills[n]]
			text.color = tables.colors["default_font"]
		end

		log:debug("" .. guild.ref.object.name .. " joined " .. faction.name .. ".")
		guild.button_ok.disabled = false
		menu:updateLayout()
	end
end

function guild.forgetFaction(e)
	local modData = func.getModData(guild.ref)
	for i = 0, 3 do
		if e.button == i then
			func.clMessageBox("" .. guild.ref.object.name .. " renounced a faction. (" .. tes3.getFaction(modData.factions[i + 1]).name .. ").")
			table.remove(modData.factions, (i + 1))
		end
	end
end


return guild