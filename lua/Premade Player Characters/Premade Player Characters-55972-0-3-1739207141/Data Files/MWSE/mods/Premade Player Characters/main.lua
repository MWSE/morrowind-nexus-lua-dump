
local characterPresets = {
	{
		["name"] = "Gurak gro-Zaal",
		["quote"] = "Let us make an older Orsinium.",
		["race"] = "Orsimer",
		["bio"] = "Ambitious even for an orc, Gurak was exiled from his clan for a crime he did not commit. He was apprehended in neighboring Cyrodil for public disorder offences.",
		["birth"] = "Lady's Favor",
		["art"] = "textures/pg/presetCharacters/orc_archer.dds",
		["offset"] = -87,
		["id"] = "pg_orc_archer",
	},
	{
		["name"] = "Dhakir",
		["quote"] = "I will not debase myself again.",
		["race"] = "Redguard",
		["bio"] = "A hot temper in the searing desert heat does not lead one to rational decisions. The abusive fiance of Dhakir's sister had powerful family connections, and only a few greased palms landed him in jail for years.",
		["birth"] = "Warwyrd",
		["art"] = "textures/pg/presetCharacters/redguard_berserker.dds",
		["offset"] = -60,
		["id"] = "pg_red_berserker",
	},
	{
		["name"] = "Nethyn Areth",
		["quote"] = "The only good nord is a dead one.",
		["race"] = "Dunmer",
		["bio"] = "Born inside Skyrim, Areth eked out a living by hunting bandits. Imperial legionaires didn't waste time investigating when they found a Dunmer living among the corpses of his ancestral enemies, and he was swiftly transferred to Frostmoth Legion Fort awaiting trial.",
		["birth"] = "Charioteer",
		["art"] = "textures/pg/presetCharacters/dunmer_nightblade.dds",
		["offset"] = -80,
		["id"] = "pg_dun_spellsword",
	},
	{
		["name"] = "Arabhi",
		["quote"] = "Secunda smiles upon Khajiit.",
		["race"] = "Khajiit",
		["bio"] = "Slave bracers kept Arabhi unaware of the extent of her magical prowess, but during her escape she grasped her innate power. For the first time she felt the hunger for the knowledge and power that she had been denied all her life. Though the escape attempt couldn't be called a success, she was lucky enough to find herself in Imperial custody.",
		["birth"] = "Elfborn",
		["art"] = "textures/pg/presetCharacters/khajiit_mage.dds",
		["offset"] = -40,
		["id"] = "pg_kha_mage",
	},
	{
		["name"] = "Waits-Beneath-Waves",
		["quote"] = "Blood in the water.",
		["race"] = "Argonian",
		["bio"] = "A patient killer can wait at the docks - not under the prying eyes of guards and officials, but beneath the surface of the water. But when the task is so easy, it's natural to become complacent.",
		["birth"] = "Beggar's Nose",
		["art"] = "textures/pg/presetCharacters/argonian_rogue.dds",
		["offset"] = -90,
		["id"] = "pg_arg_rogue",
	},
}

local allChars = {}
local selectedCharBlock
local selectedChar
local lockedIn = false

local function generateCharacterAndStartGame(quickstart)
	local player = tes3.getObject("player")
	--- @type tes3npc
	local character = tes3.getObject(selectedChar.id)
	player.name = selectedChar.name
	player.female = character.female
	player.race = character.race
	player.head = character.head
	player.hair = character.hair
	player.class = character.class

	if quickstart and mge.enabled() then
		tes3.hammerKey(tes3.scanCode.esc)
	end

	tes3.newGame()

	if quickstart and mge.enabled() then
   		tes3.unhammerKey(tes3.scanCode.esc)
	end

	--- @type tes3birthsign
	local sign = tes3.findBirthsign(selectedChar.birth)
	for _, s in pairs(sign.spells) do
		-- birthsign setting doesn't seem to work for abilities, but is fine for powers and spells.
		if s.castType == tes3.spellType.ability then
			tes3.addSpell{ reference = tes3.player, spell = s, updateGUI = true }
		end
	end
	tes3.mobilePlayer.birthsign = sign

	for s, _ in pairs(character.attributes) do
		tes3.mobilePlayer.attributes[s].baseRaw = character.attributes[s]
		tes3.mobilePlayer.attributes[s].base = character.attributes[s]
		tes3.mobilePlayer.attributes[s].currentRaw = character.attributes[s]
		tes3.mobilePlayer.attributes[s].current = character.attributes[s]
	end
	for s, _ in pairs(character.skills) do
		tes3.mobilePlayer.skills[s].baseRaw = character.skills[s]
		tes3.mobilePlayer.skills[s].base = character.skills[s]
		tes3.mobilePlayer.skills[s].currentRaw = character.skills[s]
		tes3.mobilePlayer.skills[s].current = character.skills[s]
	end

	if character.race.isBeast then
		tes3.removeItem{ reference = tes3.player, item = "common_shoes_01", playSound = false }
	end

	if quickstart == true then
		tes3.setGlobal("CharGenState", -1)
		tes3.mobilePlayer.controlsDisabled = false
		tes3.mobilePlayer.jumpingDisabled = false
		tes3.mobilePlayer.viewSwitchDisabled = false
		tes3.mobilePlayer.vanityDisabled = false
		tes3.mobilePlayer.attackDisabled = false
		tes3.mobilePlayer.magicDisabled = false

		local tradehouse = tes3.getCell{id = "Seyda Neen, Arrille's Tradehouse"}
		tes3.positionCell{cell = tradehouse, position = tes3vector3.new(-446, -198, 386)}
	end

	tes3.updateInventoryGUI{ reference = tes3.player }
	tes3.updateMagicGUI{ reference = tes3.player }
end

local function createStatLine(parent, label, value, indent)
	local b = parent:createBlock()
	b.borderLeft = indent
	b.autoHeight = true
	b.widthProportional = 1
	b.childAlignX = -1
	b:createLabel{ text = label }
	b:createLabel{ text = "" .. value }
end

local function createCharacterMenu(select)
	local menu = tes3ui.createMenu{
		id = "pg_presetCharacters",
		fixedFrame = true,
		modal = true,
		loadable = false,
	}

	local container = menu:createBlock()
	container.minWidth = 1180
	container.maxWidth = 1180
	container.autoHeight = true
	container.autoWidth = true
	container.flowDirection = tes3.flowDirection.leftToRight

	local smallWidth = 180
	local bigWidth = 320

	if lockedIn then
		--- @type tes3npc
		local charNPC = tes3.getObject(selectedChar.id)

		local block = container:createBlock{ id = selectedChar.name }
		block.autoWidth = true
		block.autoHeight = true
		block.heightProportional = 1
		block.borderAllSides = 12
		block.flowDirection = tes3.flowDirection.topToBottom
		block.childAlignX = 0.5

		local quote = block:createLabel{ text = "\"" .. selectedChar.quote .. "\"" }
		quote.borderAllSides = 8
		quote.color = tes3ui.getPalette(tes3.palette.headerColor)

		local artContainer = block:createThinBorder()
		artContainer.width = bigWidth
		artContainer.autoHeight = true
		artContainer.paddingAllSides = 2
		artContainer.childOffsetX = 0

		local art = artContainer:createImage{
			path = selectedChar.art
		}
		art.width = bigWidth
		art.height = 512
		art.scaleMode = true

		local rightPanel = container:createBlock()
		rightPanel.heightProportional = 1
		rightPanel.widthProportional = 1
		rightPanel.flowDirection = tes3.flowDirection.topToBottom
		rightPanel.borderAllSides = 8
		rightPanel.borderTop = 72

		local name = rightPanel:createLabel{ text = selectedChar.name }
		name.color = tes3ui.getPalette(tes3.palette.headerColor)
		name.borderBottom = 4

		local raceClass = rightPanel:createLabel{ text = selectedChar.race .. " " .. charNPC.class.name }
		raceClass.borderLeft = 8
		raceClass.borderBottom = 12

		local restBlock = rightPanel:createBlock()
		restBlock.widthProportional = 1
		restBlock.heightProportional = 1

		local statsBlock = restBlock:createBlock{ id = "statistics" }
		statsBlock.flowDirection = tes3.flowDirection.topToBottom
		statsBlock.width = 240
		statsBlock.heightProportional = 1
		statsBlock.borderRight = 12

		local stats = statsBlock:createThinBorder{ id = "attributes" }
		stats.widthProportional = 1
		stats.autoHeight = true
		stats.flowDirection = tes3.flowDirection.topToBottom
		stats.paddingAllSides = 8
		stats.borderRight = 2
		for _, s in pairs(tes3.attribute) do
			createStatLine(stats, tes3.getAttributeName(s), charNPC.attributes[s + 1])
		end
		local skills = statsBlock:createThinBorder{ id = "skills" }
		skills.widthProportional = 1
		skills.autoHeight = true
		skills.flowDirection = tes3.flowDirection.topToBottom
		skills.paddingAllSides = 8
		skills.borderRight = 2
		skills.borderTop = 8
		skills:createLabel{ text = "Major Skills" }.color = tes3ui.getPalette(tes3.palette.headerColor)
		for _, s in ipairs(charNPC.class.majorSkills) do
			createStatLine(skills, tes3.getSkillName(s), charNPC.skills[s + 1], 8)
		end
		local minor = skills:createLabel{ text = "Minor Skills"}
		minor.color = tes3ui.getPalette(tes3.palette.headerColor)
		minor.borderTop = 8
		for _, s in ipairs(charNPC.class.minorSkills) do
			createStatLine(skills, tes3.getSkillName(s), charNPC.skills[s + 1], 8)
		end

		local bioBlock = restBlock:createBlock{ id = "bio" }
		bioBlock.widthProportional = 1
		bioBlock.heightProportional = 1
		bioBlock.flowDirection = tes3.flowDirection.topToBottom

		local bio = bioBlock:createLabel{ text = selectedChar.bio }
		bio.wrapText = true
		bio.borderBottom = 12

		local sign = tes3.findBirthsign(selectedChar.birth)
		local birth = bioBlock:createLabel{ text = "Born under the sign of " .. sign.name .. "." }
		birth.borderBottom = 12

		local birthBlock = bioBlock:createBlock()
		birthBlock.widthProportional = 1
		birthBlock.heightProportional = 1
		birthBlock.flowDirection = tes3.flowDirection.topToBottom
		birthBlock.borderLeft = 8

		if sign.spells:containsType(tes3.spellType.ability) then
			birthBlock:createLabel{ text = "Abilities:" }.color = tes3ui.getPalette(tes3.palette.headerColor)
			for _, s in pairs(sign.spells) do
				if s.castType == tes3.spellType.ability then
					birthBlock:createLabel{ text = s.name }
					for i = 1, #s.effects do
						local e = s.effects[i]
						if e.id == -1 then break end
						-- Abilities do not use durations!
						e.duration = 0
						local effect = birthBlock:createBlock()
						effect.autoHeight = true
						effect.widthProportional = 1
						effect.borderAllSides = 4
						local icon = effect:createImage{ path = string.format("icons\\%s", e.object.icon) }
						icon.borderTop = 1
						icon.borderRight = 6
						local labelString = string.format("%s", e)
						local label = effect:createLabel{ text = labelString:sub(1, #labelString - 8) }
						label.wrapText = false
					end
				end
			end
		end
		if sign.spells:containsType(tes3.spellType.spell) then
			birthBlock:createLabel{ text = "Spells:" }.color = tes3ui.getPalette(tes3.palette.headerColor)
			for _, s in pairs(sign.spells) do
				if s.castType == tes3.spellType.spell then
					birthBlock:createLabel{ text = s.name }
					for i = 1, #s.effects do
						local e = s.effects[i]
						if e.id == -1 then break end
						local effect = birthBlock:createBlock()
						effect.autoHeight = true
						effect.widthProportional = 1
						effect.borderAllSides = 4
						local icon = effect:createImage{ path = string.format("icons\\%s", e.object.icon) }
						icon.borderTop = 1
						icon.borderRight = 6
						local label = effect:createLabel{ text = string.format("%s", e) }
						label.wrapText = false
					end
				end
			end
		end
		if sign.spells:containsType(tes3.spellType.power) then
			birthBlock:createLabel{ text = "Powers:" }.color = tes3ui.getPalette(tes3.palette.headerColor)
			for _, s in pairs(sign.spells) do
				if s.castType == tes3.spellType.power then
					birthBlock:createLabel{ text = s.name }
					for i = 1, #s.effects do
						local e = s.effects[i]
						if e.id == -1 then break end
						local effect = birthBlock:createBlock()
						effect.autoHeight = true
						effect.widthProportional = 1
						effect.borderAllSides = 4
						local icon = effect:createImage{ path = string.format("icons\\%s", e.object.icon) }
						icon.borderTop = 1
						icon.borderRight = 6
						local label = effect:createLabel{ text = string.format("%s", e) }
						label.wrapText = false
					end
				end
			end
		end

		menu:updateLayout()

		local bottomContainer = menu:createBlock()
		bottomContainer.autoHeight = true
		bottomContainer.widthProportional = 1
		bottomContainer.childAlignX = -1
		local back = bottomContainer:createButton{ text = "Back" }
		back.paddingAllSides = 4
		back.paddingBottom = 6
		back:register(tes3.uiEvent.mouseClick, function()
			lockedIn = false
			menu:destroy()
			allChars = {}
			createCharacterMenu(false)
		end)

		local start = bottomContainer:createButton{ id = "presetCharacters_Start", text = "Start" }
		start.paddingAllSides = 4
		start.paddingBottom = 6
		start:register(tes3.uiEvent.mouseClick, function()
			local quickstart = tes3.worldController.inputController:isControlDown()
			generateCharacterAndStartGame(quickstart)
		end)
	else
		for i, char in pairs(characterPresets) do
			--- @type tes3npc
			local charNPC = tes3.getObject(char.id)

			local block = container:createBlock{ id = char.name }
			block.autoWidth = true
			block.autoHeight = true
			block.heightProportional = 1
			block.borderAllSides = 12
			block.flowDirection = tes3.flowDirection.topToBottom
			block.childAlignX = 0.5

			-- maybe help with some interop potential in the future?
			block:setLuaData("character", char)

			local name = block:createLabel{ text = char.name }
			name.borderAllSides = 8
			name.color = tes3ui.getPalette(tes3.palette.headerColor)

			local artContainer = block:createThinBorder()
			artContainer.width = smallWidth
			artContainer.autoHeight = true
			artContainer.paddingAllSides = 2
			artContainer.childOffsetX = char.offset

			artContainer:register(tes3.uiEvent.help, function()
				local help = tes3ui.createTooltipMenu()
				help:createLabel{ text = char.race }
				help:createLabel{ text = charNPC.class.name }
				help:createLabel{ text = tes3.findBirthsign(char.birth).name }
			end)

			local art = artContainer:createImage{
				path = char.art
			}
			art.width = bigWidth
			art.height = 512
			art.scaleMode = true

			artContainer:register(tes3.uiEvent.mouseClick, function()
				selectedCharBlock = art
				for _, charBlock in pairs(allChars) do
					local c = charBlock.block
					c.parent.width = smallWidth
					c.parent.childOffsetX = charBlock.char.offset
					c.scaleMode = true
				end

				if selectedChar ~= selectedCharBlock.parent.parent:getLuaData("character") then
					tes3.worldController.menuClickSound:play()
				end

				selectedCharBlock.parent.width = bigWidth
				selectedCharBlock.parent.childOffsetX = 0
				selectedCharBlock.scaleMode = true
				selectedChar = selectedCharBlock.parent.parent:getLuaData("character")
				menu:findChild("presetCharacters_Start").text = "Continue as " .. selectedChar.name
				menu:updateLayout()
			end)

			table.insert(allChars, {
				["block"] = art,
				["char"] = char,
			})

			if select and i == math.round(#characterPresets / 2) then
				selectedCharBlock = artContainer
				selectedChar = char
			end
		end

		local bottomContainer = menu:createBlock()
		bottomContainer.autoHeight = true
		bottomContainer.widthProportional = 1
		bottomContainer.childAlignX = -1
		local back = bottomContainer:createButton{ text = "Back" }
		back.paddingAllSides = 4
		back.paddingBottom = 6
		back:register(tes3.uiEvent.mouseClick, function()
			local button = tes3ui.findMenu("MenuOptions"):findChild("MenuOptions_New_container")
			button.parent.visible = true
			menu:destroy()
			allChars = {}
		end)

		local start = bottomContainer:createButton{ id = "presetCharacters_Start", text = "Start" }
		start.paddingAllSides = 4
		start.paddingBottom = 6
		start:register(tes3.uiEvent.mouseClick, function()
			lockedIn = true
			menu:destroy()
			createCharacterMenu()
		end)

		for _, b in pairs(container.children) do
			if selectedChar == b:getLuaData("character") then
				b.children[2]:triggerEvent(tes3.uiEvent.mouseClick)
			end
		end
	end

	-- lmao
	menu:updateLayout()
	menu:updateLayout()
	menu:updateLayout()
end

--- @param e uiActivatedEventData
local function updateMenu(e)
	if not e.newlyCreated then return end
	local mainMenu = e.element

	local button = mainMenu:findChild("MenuOptions_New_container")
	button:register(tes3.uiEvent.mouseClick, function()
		button.parent.visible = false
		createCharacterMenu(true)
	end)
end
event.register(tes3.event.uiActivated, updateMenu, { filter = "MenuOptions" })