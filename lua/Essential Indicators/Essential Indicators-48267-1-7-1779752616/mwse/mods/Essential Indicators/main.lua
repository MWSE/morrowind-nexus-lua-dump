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
	shouldFade = true,
	fadeSpeed = 10,
	defaultColor = {r = 1, g = 1, b = 1, a = 1},
	ownershipColor = {r = 1.0, g = 0.1, b = 0.1, a = 1},
	essentialColor = {r = 0.1, g = 0.1, b = 1.0, a = 1},
	questItemcolor = {r = 0.1, g = 0.1, b = 1.0, a = 1},
	questgiverColor = {r = 0.1, g = 1.0, b = 1.0, a = 1},
	allowInteropReplacementTextures = true,
	allowInteropOverrideTextures = true,
	allowInteropOverrideColors = true,
	allowInteropOverrideScale = true,

	-- NPC Settings
	npcVanilla = true,
	npcExtended = true,
	npcGuild = false,
	npcSide = false,
	essentialsInvincible = false,
	noEssentials = false,
}

local data = require("Essential Indicators.data")
local interop = require("Essential Indicators.interop")

local menuMultiId = tes3ui.registerID("MenuMulti")
local essentialIndicatorID  = tes3ui.registerID("EssentialIndicators_block")

---@type EssentialIndicators.Config
local config = mwse.loadConfig("Essential Indicators", defaultConfig)

local currentFade = 1
local colorState = config.defaultColor

-- To keep track of the current indicator state
---@type integer
local currentTargettingState = interop.indicatorEnum.DefaultIndicator

---@type integer
local currentSneakState = interop.indicatorEnum.DefaultIndicator

-- Helper functions

local function lerp(start, goal, alpha)
    return start + (goal - start)*alpha
end





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
event.register("loaded", onLoaded, {priority = 100}) -- Make sure it fires before other mods affecting the crosshair, and let them interop with this mod instead

local crosshair = {}

local function destroyCrosshair()
	if not crosshair.parent then return end
	
	local existing = crosshair.parent:findChild(essentialIndicatorID)
    if existing then
        existing:destroy()
    end
	crosshair.main = nil
	crosshair.default = nil
	crosshair.undetected = nil
	crosshair.detected = nil
	crosshair.interopOverride = nil
end

local function createCrosshair()
	if crosshair.parent == nil then
		return
	end

	destroyCrosshair()

	local crosshairScale = config.crosshairScale
	local sneakIndicatorScale = config.sneakIndicatorScale

	if config.allowInteropOverrideScale then
		local interopCrosshairScale = interop.getOverrideScale(interop.scaleTypeEnum.DefaultIndicatorScale)
		if interopCrosshairScale then
			crosshairScale = interopCrosshairScale
		end

		local interopSneakIndicatorScale = interop.getOverrideScale(interop.scaleTypeEnum.SneakIndicatorScale)
		if interopSneakIndicatorScale then
			sneakIndicatorScale = interopSneakIndicatorScale
		end
	end

	local ei = crosshair.parent:createBlock{ id = essentialIndicatorID }

	crosshair.main = ei

	crosshair.main.absolutePosAlignX = 0.5
	crosshair.main.absolutePosAlignY = 0.5
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

	if config.allowInteropReplacementTextures then
		local interopDefaultOverride = interop.getReplacementTexture(interop.textureEnum.DefaultTexture)
		if interopDefaultOverride then
			defaultTex = interopDefaultOverride
		end
	end

	crosshair.default = crosshair.main:createImage({ path = defaultTex })
	crosshair.default.scaleMode = true
	crosshair.default.width = (32 * (crosshairScale / 100))
	crosshair.default.height = (32 * (crosshairScale / 100))
	crosshair.default.color = { colorState.r, colorState.g, colorState.b }

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

	if config.allowInteropReplacementTextures then
		local interopUndetectedOverride = interop.getReplacementTexture(interop.textureEnum.HiddenTexture)
		if interopUndetectedOverride then
			undetectedTex = interopUndetectedOverride
		end
	end

	crosshair.undetected = crosshair.main:createImage({ path = undetectedTex })
	crosshair.undetected.visible = false
	crosshair.undetected.scaleMode = true
	crosshair.undetected.width = (32 * (sneakIndicatorScale / 100))
	crosshair.undetected.height = (32 * (sneakIndicatorScale / 100))
	crosshair.undetected.color = { colorState.r, colorState.g, colorState.b }

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

	if config.allowInteropReplacementTextures then
		local interopDetectedOverride = interop.getReplacementTexture(interop.textureEnum.DetectedTexture)
		if interopDetectedOverride then
			detectedTex = interopDetectedOverride
		end
	end

	crosshair.detected = crosshair.main:createImage({ path = detectedTex })
	crosshair.detected.visible = false
	crosshair.detected.scaleMode = true
	crosshair.detected.width = (32 * (sneakIndicatorScale / 100))
	crosshair.detected.height = (32 * (sneakIndicatorScale / 100))
	crosshair.detected.color = { colorState.r, colorState.g, colorState.b }


	--- Interop overridden indicator
	
	local interopOverrideTex = interop.getOverrideTexture()
	if interopOverrideTex then
		crosshair.interopOverride = crosshair.main:createImage({ path = interopOverrideTex })
		crosshair.interopOverride.visible = false
		crosshair.interopOverride.scaleMode = true
		crosshair.interopOverride.width = (32 * (crosshairScale / 100))
		crosshair.interopOverride.height = (32 * (crosshairScale / 100))
		crosshair.interopOverride.color = { colorState.r, colorState.g, colorState.b }
	end
end

interop.recreateCrosshair = function()
	destroyCrosshair()
	createCrosshair()
end

local function onMenuMultiCreated(e)
	if not e.newlyCreated then
		return
	end
	crosshair = {}
	crosshair.parent = e.element --[[@as tes3uiElement]]
	createCrosshair()
end
event.register("uiActivated", onMenuMultiCreated, { filter = "MenuMulti", priority = -10000})


local function ensureCrosshairOnTop()
	-- Wiggling some values is enough to make this render last, and have priority over other mods rendering UI in MenuMulti on the same space.
	crosshair.default.imageScaleX = 1 
	crosshair.detected.imageScaleX = 1
	crosshair.undetected.imageScaleX = 1
	if crosshair.interopOverride then
		crosshair.interopOverride.imageScaleX = 1
	end
end


local function setCrosshair(e)
	crosshair.default.visible = false
	crosshair.detected.visible = false
	crosshair.undetected.visible = false

	if crosshair.interopOverride then
		crosshair.interopOverride.visible = false
	end

	if e == crosshair.default and tes3.worldController.cursorOff then
		return
	end

	e.visible = true
end

local function setCrosshairColor(color)
	crosshair.default.color = { color.r, color.g, color.b }
	crosshair.detected.color = { color.r, color.g, color.b }
	crosshair.undetected.color = { color.r, color.g, color.b }
	if crosshair.interopOverride then
		crosshair.interopOverride.color = { color.r, color.g, color.b }
	end

	colorState = color
end

local function setCrosshairAlpha(value)
	crosshair.default.alpha = value
	crosshair.detected.alpha = value
	crosshair.undetected.alpha = value

	if crosshair.interopOverride then
		crosshair.interopOverride.alpha = value
	end

	if value < 0.01 then
		crosshair.main.visible = false
	end
end

local function updateIndicator(target)
	if config.sneakTarget then
		if not tes3.mobilePlayer.isSneaking then
			setCrosshair(crosshair.default)
		elseif crosshair.detected.visible == true then
			if not interop.isIndicatorDisabled(interop.indicatorEnum.SneakIndicator) then
				setCrosshair(crosshair.detected)
			end
		else
			if not interop.isIndicatorDisabled(interop.indicatorEnum.SneakIndicator) then
				tes3.messageBox("updateIndicator: Set undetected")
				setCrosshair(crosshair.undetected)
			end
		end
	else
		setCrosshair(crosshair.default)
	end

	if target ~= nil then

		local interopDisabled ={
			ownershipTarget = interop.isIndicatorDisabled(interop.indicatorEnum.OwnershipIndicator),
			sneakTarget = interop.isIndicatorDisabled(interop.indicatorEnum.SneakIndicator),
			npcTarget = interop.isIndicatorDisabled(interop.indicatorEnum.EssentialNPCIndicator),
			sideTarget = interop.isIndicatorDisabled(interop.indicatorEnum.QuestgiverIndicator),
			itemTarget = interop.isIndicatorDisabled(interop.indicatorEnum.QuestItemIndicator)
		}


		if config.ownershipTarget then
			local owner = tes3.getOwner(target)
			if owner ~= nil then
				if owner.objectType == tes3.objectType.npc then
					-- Doors
					if target.object.objectType == tes3.objectType.door or string.find(target.object.name, '[Dd]oor') then
						local locked = tes3.getLocked{ reference = target }
						if locked then
							if not interopDisabled.ownershipTarget then
								setCrosshairColor(config.ownershipColor)
							end
							currentTargettingState = interop.indicatorEnum.OwnershipIndicator
						else
							return
						end
					end
					-- Check it's not a rented bed.
					local globalVar = target.attachments.variables.requirement
					if globalVar == nil or globalVar.value ~= 1 then
						if not interopDisabled.ownershipTarget then
							setCrosshairColor(config.ownershipColor)
						end
						currentTargettingState = interop.indicatorEnum.OwnershipIndicator
					end
				-- Factions may allow the player to use their items, if they're a member of adequate rank
				elseif owner.objectType == tes3.objectType.faction then
					if not owner.playerJoined or target.attachments.variables.requirement > owner.playerRank then
						if not interopDisabled.ownershipTarget then
							setCrosshairColor(config.ownershipColor)
						end
						currentTargettingState = interop.indicatorEnum.OwnershipIndicator
					end
				end
			-- Pickpocketing (living) people is always bad.
			elseif target.object.objectType == tes3.objectType.npc and tes3.mobilePlayer.isSneaking and target.mobile.health.current > 0 then
				if not interopDisabled.ownershipTarget then
					setCrosshairColor(config.ownershipColor)
				end
				currentTargettingState = interop.indicatorEnum.OwnershipIndicator
			else
				setCrosshairColor(config.defaultColor)
				currentTargettingState = interop.indicatorEnum.DefaultIndicator
			end
		end

		if config.npcTarget then
			local npc = data.vanillaTable[target.baseObject.id:lower()]
			local npcExtended = data.extendedTable[target.baseObject.id:lower()]
			if npc then
				if config.ownershipTarget and not interopDisabled.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local entry = tes3.getJournalIndex{ id = (npc.entry) }
				local index = npc.index
				if (entry < index) then
					if not interopDisabled.npcTarget then
						setCrosshairColor(config.essentialColor)
					end
					currentTargettingState = interop.indicatorEnum.EssentialNPCIndicator
				elseif (entry >= index) then
					return
				end
			elseif config.npcExtended and npcExtended then
				local entry = tes3.getJournalIndex{ id = (npcExtended.entry) }
				local index = npcExtended.index
				if (entry < index) then
					if not interopDisabled.npcTarget then
						setCrosshairColor(config.essentialColor)
					end
					currentTargettingState = interop.indicatorEnum.EssentialNPCIndicator
				elseif (entry >= index) then
					return
				end
			end
		end

		if config.sideTarget then
			local npcSide = data.sideTable[target.baseObject.id:lower()]
			local npcGuild = data.guildTable[target.baseObject.id:lower()]

			if npcSide then
				if config.ownershipTarget and not interopDisabled.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local entry = tes3.getJournalIndex{ id = (npcSide.entry) }
				local index = npcSide.index
				if (entry < index) then
					if not interopDisabled.sideTarget then
						setCrosshairColor(config.questgiverColor)
					end
					currentTargettingState = interop.indicatorEnum.QuestgiverIndicator
				elseif (entry >= index) then
					return
				end
			elseif config.factionFactor and npcGuild then
				if config.ownershipTarget and not interopDisabled.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local factor = target.object.faction
				if factor ~= nil then
					if factor.playerJoined then
						local entry = tes3.getJournalIndex{ id = (npcGuild.entry) }
						local index = npcGuild.index
						if (entry < index) then
							if not interopDisabled.sideTarget then
								setCrosshairColor(config.questgiverColor)
							end
							currentTargettingState = interop.indicatorEnum.QuestgiverIndicator
						elseif (entry >= index) then
							return
						end
					end
				end
			elseif npcGuild then
				if config.ownershipTarget and not interopDisabled.ownershipTarget and tes3.mobilePlayer.isSneaking then
					return
				end

				local entry = tes3.getJournalIndex{ id = (npcGuild.entry) }
				local index = npcGuild.index
				if (entry < index) then
					if not interopDisabled.sideTarget then
						setCrosshairColor(config.questgiverColor)
					end
					currentTargettingState = interop.indicatorEnum.QuestgiverIndicator
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
						if not interopDisabled.itemTarget then
							setCrosshairColor(config.questItemcolor)
						end
						currentTargettingState = interop.indicatorEnum.QuestItemIndicator
					elseif (entry >= index) then
						return
					end
				end
			end
		end
	else
		setCrosshairColor(config.defaultColor)
		currentTargettingState = interop.indicatorEnum.DefaultIndicator
	end
end

local function onActivationTargetChanged(e)
	updateIndicator(e.current)
end
event.register("activationTargetChanged", onActivationTargetChanged, { priority = -10000 }) -- Low priority ensures that colors are set properly if someone else uses onActivationChange to set new textures etc.

local hideTime = 0
local prevSneaking
local function onSimulate(e)

	local playerTarget = tes3.getPlayerTarget()
	crosshair.main.visible = true

	if prevSneaking ~= tes3.mobilePlayer.isSneaking then
		updateIndicator(playerTarget)
	end

	if config.sneakTarget then
		if tes3.mobilePlayer.isSneaking then
			local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
			local child = menu:findChild(tes3ui.registerID("MenuMulti_sneak_icon"))
			if config.hideVanillaSneak then
				child.maxWidth = 0
				child.maxHeight = 0
			end
			if not interop.isIndicatorDisabled(interop.indicatorEnum.SneakIndicator) then
				if child.visible then
					setCrosshair(crosshair.undetected)
				else
					setCrosshair(crosshair.detected)
				end
			end
		end
	end

	if tes3.mobilePlayer.isSneaking then
		currentSneakState = interop.indicatorEnum.SneakIndicator
	else
		currentSneakState = interop.indicatorEnum.DefaultIndicator
	end

	if tes3.mobilePlayer.is3rdPerson then
		crosshair.main.visible = false
	end
	
	-- Checks for fading and visibility
	local shouldBeVisible = true

	if interop.isIndicatorInvisible(currentSneakState) then
		if config.autoHide then
			-- This is to fade out immediately on entering sneak, but give ordinary auto hide behavior when in sneak.
			-- Gives best result if both disabling and setting invisible for the sneak behavior (i.e., a mod completely replaces sneak crosshair)
			if tes3.mobilePlayer.isSneaking and not prevSneaking then
				hideTime = 1.5
			end
		else
			shouldBeVisible = false
		end
	end

	if interop.isIndicatorInvisible(currentTargettingState) then
		shouldBeVisible = false
	elseif playerTarget then
		shouldBeVisible = true
	end

	-- Check auto hide features
	if config.autoHide then
		if config.autoHideSneak and tes3.mobilePlayer.isSneaking then
			hideTime = 0
		elseif playerTarget == nil and not tes3.mobilePlayer.castReady and ( not tes3.mobilePlayer.weaponReady or tes3.mobilePlayer.readiedWeapon == nil or not tes3.mobilePlayer.readiedWeapon.object.isRanged) then
			hideTime = hideTime + e.delta
			if hideTime >= 1.5 then
				shouldBeVisible = false
			end
		else
			hideTime = 0
		end
	end

	-- Fade and app cull as needed
	if not shouldBeVisible then
		if config.shouldFade then
			currentFade = lerp(currentFade, 0, 1 - math.exp(-e.delta * config.fadeSpeed))
			setCrosshairAlpha(currentFade)
		else
			crosshair.main.visible = false
		end
	else
		if config.shouldFade then
			currentFade = lerp(currentFade, 1, 1 - math.exp(-e.delta * config.fadeSpeed))
			setCrosshairAlpha(currentFade)
		else
			setCrosshairAlpha(1)
			crosshair.main.visible = true
		end
	end

	if config.allowInteropOverrideColors then
		local interopOverrideColor = interop.getOverrideColor()
		if interopOverrideColor then
			setCrosshairColor(interopOverrideColor)
		end
	end

	if config.allowInteropOverrideTextures then
		local interopOverrideTexture = interop.getOverrideTexture()
		if interopOverrideTexture then
			setCrosshair(crosshair.interopOverride)
		end
	end

	ensureCrosshairOnTop()

	-- Set values to persist frames
	prevSneaking = tes3.mobilePlayer.isSneaking
end
event.register("simulate", onSimulate, { priority = -10000 }) -- Make sure we run last, so we render on top of other UI.

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

	crosshairPage:createOnOffButton({
		label = "Fade in and out crosshair when hiding (both interop and auto hide)",
		description = "Fade in and out crosshair when hiding (both interop and auto hide)\n\nWhen the crosshair is turned off after the auto hide timer (if the feature is toggled on), or if another mod disables a specific indicator through interop, setting this setting to on will make them fade in and out rather than just turn on and off immediately. Does nothing if the crosshair is never hidden.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "shouldFade", table = config},
	})

	crosshairPage:createSlider({
		label = "Fade speed",
		description = "Determines the speed at which the crosshair fades in and out if the fade option is toggled on. Does nothing if the fade option is toggeled off. \n\nDefault: 10",
		min = 5,
		max = 20,
		step = 1,
		variable = mwse.mcm.createTableVariable{id = "fadeSpeed", table = config },
	})

	crosshairPage:createOnOffButton({
		label = "Allow other mods to replace default crosshair textures",
		description = "Determines wether other mods are allowed to replace the default textures in Essential Indicator using interop functionality. \n\nDefault: On",
		variable = mwse.mcm.createTableVariable{id = "allowInteropReplacementTextures", table = config },
	})

	crosshairPage:createOnOffButton({
		label = "Allow other mods to override crosshair textures",
		description = "Determines wether other mods are allowed to show their own textures (meant to be used with new indicator types introduced by the new mods) in Essential Indicator using interop functionality. \n\nDefault: On",
		variable = mwse.mcm.createTableVariable{id = "allowInteropOverrideTextures", table = config },
	})

	crosshairPage:createOnOffButton({
		label = "Allow other mods to override the crosshair scale",
		description = "Determines wether other mods are allowed to override the scales for the crosshair and sneak indicator in Essential Indicator using interop functionality. \n\nDefault: On",
		variable = mwse.mcm.createTableVariable{id = "allowInteropOverrideScale", table = config },
	})

	crosshairPage:createOnOffButton({
		label = "Allow other mods to override colors",
		description = "Determines wether other mods are allowed to override the color for the crosshair and sneak indicator in Essential Indicator using interop functionality. This can be used by other mods to create new types of indicator behavior specific to their mods. \n\nDefault: On",
		variable = mwse.mcm.createTableVariable{id = "allowInteropOverrideColors", table = config}
	})

	local indicatorColorPage = template:createSideBarPage({
		label = "Indicator colors",
		description = "Here you can change the colors of the different indicator stages.",
		showReset = true,
		showDefaultSetting = true
	})

	indicatorColorPage:createColorPicker({
		label = "Default crosshair color",
		description = "Sets the default value of the crosshair.",
		defaultSetting = defaultConfig.defaultColor,
		variable = mwse.mcm.createTableVariable{id = "defaultColor", table = config}
	})

	indicatorColorPage:createColorPicker({
		label = "Ownership crosshair color",
		description = "Sets the default value of the crosshair.",
		defaultSetting = defaultConfig.ownershipColor,
		variable = mwse.mcm.createTableVariable{id = "ownershipColor", table = config}
	})

	indicatorColorPage:createColorPicker({
		label = "Essential NPC crosshair color",
		description = "Sets the default value of the crosshair.",
		defaultSetting = defaultConfig.essentialColor,
		variable = mwse.mcm.createTableVariable{id = "essentialColor", table = config}
	})

	indicatorColorPage:createColorPicker({
		label = "Quest giver NPC crosshair color",
		description = "Sets the default value of the crosshair.",
		defaultSetting = defaultConfig.questgiverColor,
		variable = mwse.mcm.createTableVariable{id = "questgiverColor", table = config}
	})

	indicatorColorPage:createColorPicker({
		label = "Quest relevant item crosshair color",
		description = "Sets the default value of the crosshair.",
		defaultSetting = defaultConfig.questItemcolor,
		variable = mwse.mcm.createTableVariable{id = "questItemcolor", table = config}
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
