-- Essential Indicators

---@class EssentialIndicators.Config
local defaultConfig = {
	-- General Settings
	messages = true,
	ownershipTarget = true,
	sneakTarget = true,
	npcTarget = true,
	sideTarget = true,
	factionFactor = true,
	itemTarget = true,
	essentialTooltip = true,
	hideVanillaSneak = true,

	-- Crosshair Settings
	autoHide = false,
	autoHideSneak = false,
	newDefault = true,
	dotCrosshair = false,
	crosshairTexture = "vanilla",
	crosshairScale = 100,
	sneakIndicatorScale = 100,

	-- NPC Settings
	npcVanilla = true,
	npcExtended = true,
	npcGuild = false,
	npcSide = false,
	essentialsInvincible = false,
	noEssentials = false,
}

local data = require("Essential Indicators.data")

---@type EssentialIndicators.Config
local config = mwse.loadConfig("Essential Indicators", defaultConfig)

local function essentialSwitch()
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor) do
		if ref == nil then
			return
		end

		if config.npcVanilla then
			local npc = data.vanillaTable[ref.baseObject.id:lower()]
			if config.noEssentials and npc then
				ref.baseObject.essential = false
			elseif not config.noEssentials and npc then
				local entry = tes3.getJournalIndex{ id = (npc.entry) }
				local index = npc.index
				if (entry < index) then
					ref.baseObject.essential = true
				elseif (entry >= index) then
					ref.baseObject.essential = false
				end
			end
		end

		if config.npcExtended then
			local npc = data.extendedTable[ref.baseObject.id:lower()]
			if config.noEssentials and npc then
				ref.baseObject.essential = false
			elseif not config.noEssentials and npc then
				local entry = tes3.getJournalIndex{ id = (npc.entry) }
				local index = npc.index
				if (entry < index) then
					ref.baseObject.essential = true
				elseif (entry >= index) then
					ref.baseObject.essential = false
				end
			end
		end

		if config.npcGuild then
			local npc = data.guildTable[ref.baseObject.id:lower()]
			if config.noEssentials and npc then
				ref.baseObject.essential = false
			elseif not config.noEssentials and npc then
				local entry = tes3.getJournalIndex{ id = (npc.entry) }
				local index = npc.index
				if (entry < index) then
					ref.baseObject.essential = true
				elseif (entry >= index) then
					ref.baseObject.essential = false
				end
			end
		end

		if config.npcSide then
			local npc = data.sideTable[ref.baseObject.id:lower()]
			if config.noEssentials and npc then
				ref.baseObject.essential = false
			elseif not config.noEssentials and npc then
				local entry = tes3.getJournalIndex{ id = (npc.entry) }
				local index = npc.index
				if (entry < index) then
					ref.baseObject.essential = true
				elseif (entry >= index) then
					ref.baseObject.essential = false
				end
			end
		end
	end
end

local function onDamage(e)
	if config.essentialsInvincible then
		if (e.reference.baseObject.essential == true) then
			local newFatigue = (e.reference.mobile.fatigue.current - e.damage)
			tes3.setStatistic{ reference = e.reference.mobile, name = "fatigue", current = newFatigue }
			e.damage = 0
			if config.messages then
				tes3.messageBox("This character's death would result in the thread of prophecy being severed. Hand yourself over to the guard, utilize a calm spell, or restore a saved game to reverse this tempting of fate.")
			end
		end
	end
end

local function onTooltip(e)
	if config.essentialTooltip then
		local item = data.questItemTable[e.object.id:lower()]
		if item then
			local entry = tes3.getJournalIndex{ id = (item.entry) }
			local index = item.index
			if (entry < index) then
				local block = e.tooltip:createBlock{}
				block.minWidth = 1
				block.maxWidth = 440
				block.autoWidth = true
				block.autoHeight = true
				block.paddingAllSides = 4
				local essentialLabel
				essentialLabel = (block:createLabel{ id = tes3ui.registerID("Essential_Indicators_Item"), text = "Essential Item" })
				essentialLabel.wrapText = true
			elseif (entry >= index) then
				return
			end
		end
	end
end

local function onInitialized()
	event.register("cellChanged", essentialSwitch)
	event.register("loaded", essentialSwitch)
	event.register("journal", essentialSwitch)
	event.register("damage", onDamage)
	event.register("uiObjectTooltip", onTooltip)
	print("[Essential Indicators]: Initialized Essential Indicators.")
end
event.register("initialized", onInitialized)

-- Crosshair Stuff

if config.sneakIndicatorScale == nil then
	config.sneakIndicatorScale = 100
end

local function onLoaded(e)
	-- Hide the crosshair.We hide the niTriShape instead of the main niNode,
	-- because Bethesda appCull the main node to hide it in the menu.
	tes3.worldController.nodeCursor.children[1].appCulled = true
end
event.register("loaded", onLoaded)

local crosshair = {}
local function createCrosshair()
	if crosshair.parent == nil then
		return
	end
    local existing = crosshair.parent:findChild("EssentialIndicators_block")
    if existing then
        existing:destroy()
    end
	crosshair.main = crosshair.parent:createBlock{
        id = "EssentialIndicators_block"
    }
	crosshair.main.layoutOriginFractionX = 0.5
	crosshair.main.layoutOriginFractionY = 0.5
	crosshair.main.autoWidth = true
	crosshair.main.autoHeight = true

	local defaultTex = "textures/target.dds"
	if config.newDefault then
		if config.dotCrosshair then
			if (config.crosshairTexture == "none") then
				defaultTex = "textures/Anu/Indicators/target_dot_vanilla.dds"
			elseif (config.crosshairTexture == "vanilla") then
				defaultTex = "textures/Anu/Indicators/target_dot_vanilla.dds"
			elseif (config.crosshairTexture == "anumarilDefault") then
				defaultTex = "textures/Anu/Indicators/target_dot.dds"
			elseif (config.crosshairTexture == "anumarilGold") then
				defaultTex = "textures/Anu/Indicators/target_dot_gold.dds"
			elseif (config.crosshairTexture == "anumarilWhite") then
				defaultTex = "textures/Anu/Indicators/target_dot_white.dds"
			elseif (config.crosshairTexture == "knotOblivion") then
				defaultTex = "textures/Anu/Indicators/target_dot_gold.dds"
			end
		else
			if (config.crosshairTexture == "none") then
				defaultTex = "textures/target.dds"
			elseif (config.crosshairTexture == "vanilla") then
				defaultTex = "textures/Anu/Indicators/target_default_vanilla.dds"
			elseif (config.crosshairTexture == "anumarilDefault") then
				defaultTex = "textures/Anu/Indicators/target_default.dds"
			elseif (config.crosshairTexture == "anumarilGold") then
				defaultTex = "textures/Anu/Indicators/target_default_gold.dds"
			elseif (config.crosshairTexture == "anumarilWhite") then
				defaultTex = "textures/Anu/Indicators/target_default_white.dds"
			elseif (config.crosshairTexture == "knotOblivion") then
				defaultTex = "textures/Anu/Indicators/target_default_oblivion.dds"
			end
		end
	end

	crosshair.default = crosshair.main:createImage({ path = defaultTex })
	crosshair.default.scaleMode = true
	crosshair.default.width = (32 * (config.crosshairScale / 100))
	crosshair.default.height = (32 * (config.crosshairScale / 100))

	-- Undetected Indicator

	local undetectedTex
	if (config.crosshairTexture == "none") then
		undetectedTex = "textures/target.dds"
	elseif (config.crosshairTexture == "vanilla") then
		undetectedTex = "textures/Anu/Indicators/target_undetected_vanilla.dds"
	elseif (config.crosshairTexture == "anumarilDefault") then
		undetectedTex = "textures/Anu/Indicators/target_undetected.dds"
	elseif (config.crosshairTexture == "anumarilGold") then
		undetectedTex = "textures/Anu/Indicators/target_undetected_gold.dds"
	elseif (config.crosshairTexture == "anumarilWhite") then
		undetectedTex = "textures/Anu/Indicators/target_undetected_white.dds"
	elseif (config.crosshairTexture == "knotOblivion") then
		undetectedTex = "textures/Anu/Indicators/target_undetected_oblivion.dds"
	end
	crosshair.undetected = crosshair.main:createImage({ path = undetectedTex })
	crosshair.undetected.visible = false
	crosshair.undetected.scaleMode = true
	crosshair.undetected.width = (32 * (config.sneakIndicatorScale / 100))
	crosshair.undetected.height = (32 * (config.sneakIndicatorScale / 100))

	-- Detected Indicator

	local detectedTex
	if (config.crosshairTexture == "none") then
		detectedTex = "textures/target.dds"
	elseif (config.crosshairTexture == "vanilla") then
		detectedTex = "textures/Anu/Indicators/target_detected_vanilla.dds"
	elseif (config.crosshairTexture == "anumarilDefault") then
		detectedTex = "textures/Anu/Indicators/target_detected.dds"
	elseif (config.crosshairTexture == "anumarilGold") then
		detectedTex = "textures/Anu/Indicators/target_detected_gold.dds"
	elseif (config.crosshairTexture == "anumarilWhite") then
		detectedTex = "textures/Anu/Indicators/target_detected_white.dds"
	elseif (config.crosshairTexture == "knotOblivion") then
		detectedTex = "textures/Anu/Indicators/target_detected_oblivion.dds"
	end
	crosshair.detected = crosshair.main:createImage({ path = detectedTex })
	crosshair.detected.visible = false
	crosshair.detected.scaleMode = true
	crosshair.detected.width = (32 * (config.sneakIndicatorScale / 100))
	crosshair.detected.height = (32 * (config.sneakIndicatorScale / 100))

	crosshair.main:updateLayout()
end

local function onMenuMultiCreated(e)
	if not e.newlyCreated then
		return
	end
	crosshair = {}
	crosshair.parent = e.element
	createCrosshair()
end
event.register("uiActivated", onMenuMultiCreated, { filter = "MenuMulti" })

local function setCrosshair(e)
	crosshair.default.visible = false
	crosshair.detected.visible = false
	crosshair.undetected.visible = false

	if e == crosshair.default and tes3.worldController.cursorOff then
		return
	end

	e.visible = true
end

local function updateIndicator(target)
	if config.sneakTarget then
		if not tes3.mobilePlayer.isSneaking then
			setCrosshair(crosshair.default)
		elseif crosshair.detected.visible == true then
			setCrosshair(crosshair.detected)
		else
			setCrosshair(crosshair.undetected)
		end
	else
		setCrosshair(crosshair.default)
	end

	if target ~= nil then
		if config.ownershipTarget then
			local owner = tes3.getOwner(target)
			if owner ~= nil then
				if owner.objectType == tes3.objectType.npc then
					-- Doors
					if target.object.objectType == tes3.objectType.door or string.find(target.object.name, '[Dd]oor') then
						local locked = tes3.getLocked{ reference = target }
						if locked then
							crosshair.default.color = {1.0, 0.1, 0.1}
							crosshair.detected.color = {1.0, 0.1, 0.1}
							crosshair.undetected.color = {1.0, 0.1, 0.1}
						else
							return
						end
					end
					-- Check it's not a rented bed.
					local globalVar = target.attachments.variables.requirement
					if globalVar == nil or globalVar.value ~= 1 then
						crosshair.default.color = {1.0, 0.1, 0.1}
						crosshair.detected.color = {1.0, 0.1, 0.1}
						crosshair.undetected.color = {1.0, 0.1, 0.1}
					end
				-- Factions may allow the player to use their items, if they're a member of adequate rank
				elseif owner.objectType == tes3.objectType.faction then
					if not owner.playerJoined or target.attachments.variables.requirement > owner.playerRank then
						crosshair.default.color = {1.0, 0.1, 0.1}
						crosshair.detected.color = {1.0, 0.1, 0.1}
						crosshair.undetected.color = {1.0, 0.1, 0.1}
					end
				end
			-- Pickpocketing (living) people is always bad.
			elseif target.object.objectType == tes3.objectType.npc and tes3.mobilePlayer.isSneaking and target.mobile.health.current > 0 then
				crosshair.default.color = {1.0, 0.1, 0.1}
				crosshair.detected.color = {1.0, 0.1, 0.1}
				crosshair.undetected.color = {1.0, 0.1, 0.1}
			else
				crosshair.default.color = {1.0, 1.0, 1.0}
				crosshair.detected.color = {1.0, 1.0, 1.0}
				crosshair.undetected.color = {1.0, 1.0, 1.0}
			end
		end

		if config.npcTarget then
			local npc = data.vanillaTable[target.baseObject.id:lower()]
			local npcExtended = data.extendedTable[target.baseObject.id:lower()]
			if npc then
				if config.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local entry = tes3.getJournalIndex{ id = (npc.entry) }
				local index = npc.index
				if (entry < index) then
					crosshair.default.color = {0.1, 0.1, 1.0}
					crosshair.detected.color = {0.1, 0.1, 1.0}
					crosshair.undetected.color = {0.1, 0.1, 1.0}
				elseif (entry >= index) then
					return
				end
			elseif config.npcExtended and npcExtended then
				local entry = tes3.getJournalIndex{ id = (npcExtended.entry) }
				local index = npcExtended.index
				if (entry < index) then
					crosshair.default.color = {0.1, 0.1, 1.0}
					crosshair.detected.color = {0.1, 0.1, 1.0}
					crosshair.undetected.color = {0.1, 0.1, 1.0}
				elseif (entry >= index) then
					return
				end
			end
		end

		if config.sideTarget then
			local npcSide = data.sideTable[target.baseObject.id:lower()]
			local npcGuild = data.guildTable[target.baseObject.id:lower()]

			if npcSide then
				if config.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local entry = tes3.getJournalIndex{ id = (npcSide.entry) }
				local index = npcSide.index
				if (entry < index) then
					crosshair.default.color = {0.1, 1.0, 1.0}
					crosshair.detected.color = {0.1, 1.0, 1.0}
					crosshair.undetected.color = {0.1, 1.0, 1.0}
				elseif (entry >= index) then
					return
				end
			elseif config.factionFactor and npcGuild then
				if config.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local factor = target.object.faction
				if factor ~= nil then
					if factor.playerJoined then
						local entry = tes3.getJournalIndex{ id = (npcGuild.entry) }
						local index = npcGuild.index
						if (entry < index) then
							crosshair.default.color = {0.1, 1.0, 1.0}
							crosshair.detected.color = {0.1, 1.0, 1.0}
							crosshair.undetected.color = {0.1, 1.0, 1.0}
						elseif (entry >= index) then
							return
						end
					end
				end
			elseif npcGuild then
				if config.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local entry = tes3.getJournalIndex{ id = (npcGuild.entry) }
				local index = npcGuild.index
				if (entry < index) then
					crosshair.default.color = {0.1, 1.0, 1.0}
					crosshair.detected.color = {0.1, 1.0, 1.0}
					crosshair.undetected.color = {0.1, 1.0, 1.0}
				elseif (entry >= index) then
					return
				end
			end
		end

		if config.itemTarget then
			local owner = tes3.getOwner(target)
			if owner == nil then
				local item = data.questItemTable[target.object.id:lower()]
				if item then
					local entry = tes3.getJournalIndex{ id = (item.entry) }
					local index = item.index
					if (entry < index) then
						crosshair.default.color = {0.1, 0.1, 1.0}
						crosshair.detected.color = {0.1, 0.1, 1.0}
						crosshair.undetected.color = {0.1, 0.1, 1.0}
					elseif (entry >= index) then
						return
					end
				end
			end
		end
	else
		crosshair.default.color = {1.0, 1.0, 1.0}
		crosshair.detected.color = {1.0, 1.0, 1.0}
		crosshair.undetected.color = {1.0, 1.0, 1.0}
	end
end

local function onActivationTargetChanged(e)
	updateIndicator(e.current)
end
event.register("activationTargetChanged", onActivationTargetChanged)

local hideTime = 0
local prevSneaking
local function onSimulate(e)
	crosshair.main.visible = true

	if prevSneaking ~= tes3.mobilePlayer.isSneaking then
		updateIndicator(tes3.getPlayerTarget())
	end

	prevSneaking = tes3.mobilePlayer.isSneaking

	if config.sneakTarget then
		if prevSneaking then
			local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
			local child = menu:findChild(tes3ui.registerID("MenuMulti_sneak_icon"))
			if config.hideVanillaSneak then
				child.maxWidth = 0
				child.maxHeight = 0
			end

			if child.visible then
				setCrosshair(crosshair.undetected)
			else
				setCrosshair(crosshair.detected)
			end
		end
	end

	if tes3.mobilePlayer.is3rdPerson then
		crosshair.main.visible = false
	end

	if config.autoHide then
		if config.autoHideSneak and tes3.mobilePlayer.isSneaking then
				return
		elseif tes3.getPlayerTarget() == nil and not tes3.mobilePlayer.castReady and ( not tes3.mobilePlayer.weaponReady or tes3.mobilePlayer.readiedWeapon == nil or not tes3.mobilePlayer.readiedWeapon.object.isRanged) then
			hideTime = hideTime + e.delta
			if hideTime > 1.5 then
				crosshair.main.visible = false
			end
		else
			hideTime = 0
		end
	end
end
event.register("simulate", onSimulate)

local function menuUpdate(e)
	crosshair.main.visible = not e.menuMode

	if e.menuMode == false then
		updateIndicator(tes3.getPlayerTarget())
	end
end
event.register("menuEnter", menuUpdate)
event.register("menuExit", menuUpdate)

-- MCM

local function registerMCM()
	local template = mwse.mcm.createTemplate("Essential Indicators")
	template.onClose = function(self)
		mwse.saveConfig("Essential Indicators", config)
		essentialSwitch()
        createCrosshair()
	end

	local generalPage = template:createSideBarPage()
	generalPage.label = "General Settings"
	generalPage.description = "Essential Indicators - General Settings\n\nThis page enables you to configure which indicators are active as well as some of their functions.\n\nMouse over each setting to learn more."

	generalPage:createOnOffButton({
		label = "Enable Essential Item Indicator",
		description = "Enable Essential Item Indicator\n\nDetermines whether the crosshair indicates when you're targeting a quest-essential item.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "itemTarget", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Essential NPC Indicator",
		description = "Enable Essential NPC Indicator\n\nDetermines whether the crosshair indicates when you're targeting a quest-essential NPC.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "npcTarget", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Quest-Giver NPC Indicator",
		description = "Enable Quest-Giver NPC Indicator\n\nDetermines whether the crosshair indicates when you're targeting a quest-giving NPC.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "sideTarget", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Quest-Giver Faction Sensibility",
		description = "Enable Quest-Giver Faction Sensibility\n\nDetermines whether the crosshair is sensitive to your membership in a guild quest-giving NPC's faction.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "factionFactor", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Ownership Indicator",
		description = "Enable Ownership Indicator\n\nDetermines whether the crosshair indicates when you're targeting an owned item or NPC to pickpocket.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "ownershipTarget", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Sneak Indicator",
		description = "Enable Sneak Indicator\n\nDetermines whether the crosshair indicates when you're sneaking, changing depending on whether you're detected or not.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "sneakTarget", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Messages",
		description = "Enable Messages\n\nDetermines whether new messages are displayed.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "messages", table = config},
	})

	generalPage:createOnOffButton({
		label = "Enable Tooltip for Quest Items",
		description = "Enable Tooltip for Quest Items\n\nDetermines whether quest-essential items receive a helpful tooltip reminding the player of their importance.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "essentialTooltip", table = config},
	})

	generalPage:createOnOffButton({
		label = "Disable Vanilla Sneak Indicator",
		description = "Disable Vanilla Sneak Indicator\n\nDetermines whether the vanilla sneak indicator is disabled, only suggested for use with the new sneak indicator.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "hideVanillaSneak", restartRequired = true, table = config},
	})

	local crosshairPage = template:createSideBarPage()
	crosshairPage.label = "Crosshair Settings"
	crosshairPage.description = "Essential Indicators - Crosshair Settings\n\nThis page enables you to personalize your crosshair by choosing from a number of stylistically consistent packs or deciding what complements your own custom crosshair best.\n\nMouse over each setting to learn more."

	crosshairPage:createOnOffButton({
		label = "Enable Autohiding Crosshair",
		description = "Enable Autohiding Crosshair\n\nDetermines whether the crosshair disappears while not in use.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "autoHide", table = config},
	})

	crosshairPage:createOnOffButton({
		label = "Disable Autohiding While Sneaking",
		description = "Disable Autohiding While Sneaking\n\nDetermines whether the crosshair disappears even while sneaking. Has no effect without 'Enable Autohiding Crosshair' turned on.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "autoHideSneak", table = config},
	})

	crosshairPage:createOnOffButton({
		label = "Enable New Default Crosshair Texture",
		description = "Enable New Default Crosshair Texture\n\nDetermines whether the default crosshair texture changes in accordance with the selected crosshair option. If disabled, your crosshair choice will only impact the appearance of the sneak indicator.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "newDefault", table = config},
	})

	crosshairPage:createOnOffButton({
		label = "Enable Dot Crosshair",
		description = "Enable Dot Crosshair\n\nDetermines whether the basic crosshair utilizes a dot style texture rather than the original target shape. Only relevant if you use a texture option.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "dotCrosshair", table = config},
	})

	crosshairPage:createDropdown({
		label = "Crosshair Options",
		description = "Crosshair Options\n\nDetermines the set of crosshair textures used for indicators.\n\nDefault: None",
		options = {
			{label = "None", value = "none", description = "Enable the default crosshair, its color changing to indicate objects depending on your enabled general settings."},
			{label = "Vanilla-Friendly", value = "vanilla", description = "Enable the vanilla crosshair and textures inspired by it."},
			{label = "Anumaril Grey", value = "anumarilDefault", description = "Enable entirely new crosshair textures with a grey theme created for this mod."},
			{label = "Anumaril Gold", value = "anumarilGold", description = "Enable entirely new crosshair textures with a gold theme created for this mod."},
			{label = "Anumaril White", value = "anumarilWhite", description = "Enable entirely new crosshair textures with a white theme created for this mod."},
			{label = "ReverendKnots' Oblivion-Style", value = "knotOblivion", description = "Enable entirely new crosshair textures with a TES IV: Oblivion theme created by ReverendKnots for this mod."},
		},
		variable = mwse.mcm:createTableVariable{id = "crosshairTexture", table = config},
	})

	crosshairPage:createSlider({
		label = "Crosshair Scale: %s%%",
		description = "Determines the size of the default crosshair on the screen.\n\nDefault: 100%",
		min = 0,
		max = 300,
		step = 1,
		jump = 24,
		variable = mwse.mcm.createTableVariable{id = "crosshairScale", table = config },
	})

	crosshairPage:createSlider({
		label = "Sneak Indicator Scale: %s%%",
		description = "Determines the size of the sneak indicator crosshair/texture on the screen.\n\nDefault: 100%",
		min = 0,
		max = 300,
		step = 1,
		jump = 24,
		variable = mwse.mcm.createTableVariable{id = "sneakIndicatorScale", table = config },
	})

	local NPCPage = template:createSideBarPage()
	NPCPage.label = "NPC Settings"
	NPCPage.description = "Essential Indicators - NPC Settings\n\nThis page enables you to configure the 'essential' status of NPCs to either make them consistent with your indicator settings or provide them with new qualities like their status updating when no longer essential or invincibility.\n\nMouse over each setting to learn more."

	NPCPage:createOnOffButton({
		label = "Enable Status Changes for Vanilla Essential NPCs",
		description = "Enable Status Changes for Vanilla Essential NPCs\n\nDetermines whether NPCs with the 'essential' status in the vanilla game will have their status changed once they are no longer needed.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "npcVanilla", table = config}
	})

	NPCPage:createOnOffButton({
		label = "Enable Status Changes for Extended Essential NPCs",
		description = "Enable Status Changes for Extended Essential NPCs\n\nDetermines whether NPCs that lacked the 'essential' status in the vanilla game, but whose deaths still rendered the main quest impossible to finish, will be given the 'essential' status and have it changed once they are no longer needed.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "npcExtended", table = config}
	})

	NPCPage:createOnOffButton({
		label = "Enable Status Changes for Guild NPCs",
		description = "Enable Status Changes for Guild NPCs\n\nDetermines whether guild quest-giving NPCs that lacked the 'essential' status in the vanilla game will be given the 'essential' status and have it changed once they are no longer needed.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "npcGuild", table = config}
	})

	NPCPage:createOnOffButton({
		label = "Enable Status Changes for Side Quest NPCs",
		description = "Enable Status Changes for Side Quest NPCs\n\nDetermines whether quest-giving NPCs that lacked the 'essential' status in the vanilla game will be given the 'essential' status and have it changed once they are no longer needed.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "npcSide", table = config}
	})

	NPCPage:createOnOffButton({
		label = "Enable Invincible Essential NPCs",
		description = "Enable Invincible Essential NPCs\n\nDetermines whether NPCs with the 'essential' status are made invincible, all damage being dealt to their fatigue rather than health.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "essentialsInvincible", table = config}
	})

	NPCPage:createOnOffButton({
		label = "Disable Essential NPCs",
		description = "Disable Essential NPCs\n\nDetermines whether the 'essential' status is removed from all NPCs. Not recommended unless you're an experienced player or just sick of messageboxes getting in the way of your rampage.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "noEssentials", table = config}
	})

	mwse.mcm.register(template)
end

event.register("modConfigReady", registerMCM)
