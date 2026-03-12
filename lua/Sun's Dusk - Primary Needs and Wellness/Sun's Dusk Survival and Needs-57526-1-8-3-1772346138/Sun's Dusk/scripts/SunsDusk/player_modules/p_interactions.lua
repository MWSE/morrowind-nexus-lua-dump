--[[
╭───────────────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - World Interactions System                                       │
│  Centralized raycast-based interaction management                             │
│  Modules register via G_worldInteractions table                               │
│                                                                               │
│  Supports:                                                                    │
│    - ToggleWeapon/ToggleSpell/Activate bindings (disables combat controls)   │
│    - Attack binding (hint only, triggers via animation hit)                   │
│    - Custom UI content via customContent()                                    │
│    - Animation hit dispatch via onHit(object, objectType, groupname, key, swingData)     │
╰───────────────────────────────────────────────────────────────────────────────╯
]]

local currentTarget = nil
local currentTargetType = nil
local assignedKeys = {}
local interactionTooltip = nil
local shiftHeld = false
local controlsDisabled = false
-- ════════════════════════════════════════════════════════════════════════════════
-- Swing Strength Tracking (for attack interactions)
-- ════════════════════════════════════════════════════════════════════════════════

local isUsing = false
local startedUse = nil
local preSwingFatigue = 0
local slot1, slot2, slot3 = {0, 0}, {0, 0}, {0, 0}
local nextSlot = 1
local lastHit = 0

input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	if use and not isUsing then
		startedUse = core.getSimulationTime()
		isUsing = true
	elseif not use and isUsing then
		preSwingFatigue = typesPlayerStatsSelf.fatigue.current
		local currentTime = core.getSimulationTime()
		local holdDuration = math.max(0, currentTime - startedUse)
		local swingStrength = math.min(holdDuration, 1.0)
		local slot = nextSlot == 1 and slot1 or (nextSlot == 2 and slot2 or slot3)
		slot[1], slot[2] = currentTime, swingStrength
		nextSlot = (nextSlot % 3) + 1
		isUsing = false
		startedUse = nil
	end
	return use
end), {})

-- Get max swing strength from recent slots
local function getSwingData(groupname, key)
	local now = core.getSimulationTime()
	local weaponSpeed = animation.getSpeed(self, groupname)
	local swingType = key:match("^(%S+)")
	
	-- Calculate required wind-up time
	local requiredWindUp = 0.5
	local startTime = animation.getTextKeyTime(self, groupname..": "..swingType.." start")
	local chargedTime = animation.getTextKeyTime(self, groupname..": "..swingType.." max attack")
	if startTime and chargedTime then
		requiredWindUp = (chargedTime - startTime) * 0.9
	end
	
	-- Find max strength from valid swings
	local cutoff = now - 0.8
	local maxStrength = 0
	if slot1[1] >= cutoff and slot1[2] > maxStrength then maxStrength = slot1[2] end
	if slot2[1] >= cutoff and slot2[2] > maxStrength then maxStrength = slot2[2] end
	if slot3[1] >= cutoff and slot3[2] > maxStrength then maxStrength = slot3[2] end
	
	-- If all expired, use the most recent one
	if maxStrength == 0 then
		local mostRecent = slot1
		if slot2[1] > mostRecent[1] then mostRecent = slot2 end
		if slot3[1] > mostRecent[1] then mostRecent = slot3 end
		maxStrength = mostRecent[2]
	end
	
	local swingStrength = math.min(1, weaponSpeed * maxStrength / requiredWindUp)
	
	return {
		swingType = swingType,
		swingStrength = swingStrength,
		weaponSpeed = weaponSpeed,
		preSwingFatigue = preSwingFatigue,
		requiredWindUp = requiredWindUp,
		maxStrength = maxStrength,
	}
end

-- ════════════════════════════════════════════════════════════════════════════════
-- Anchor Alignment (shared utility)
-- ════════════════════════════════════════════════════════════════════════════════

local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)
	else
		return 0.5 + (t * 0.5)
	end
end

local function alignAnchor(pos)
	return v2(alignAxis(pos.x), alignAxis(pos.y))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- Tooltip Management
-- ════════════════════════════════════════════════════════════════════════════════

local function destroyTooltip()
	if interactionTooltip then
		interactionTooltip:destroy()
		interactionTooltip = nil
	end
end

local function disableControls(attackable, nonAttackable)
	if not controlsDisabled then
		if not attackable then
			I.Controls.overrideCombatControls(true)
		end
		if nonAttackable then
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
		end
		controlsDisabled = true
	end
end

local function restoreControls()
	if controlsDisabled then
		I.Controls.overrideCombatControls(false)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
		controlsDisabled = false
	end
end

local keyIcons = {
	ToggleWeapon = "f",
	ToggleSpell = "r",
	ShiftToggleWeapon = "f",
	ShiftToggleSpell = "r",
	Attack = "attack",
}

local function hasShiftActions()
	return assignedKeys.ShiftToggleWeapon or assignedKeys.ShiftToggleSpell or assignedKeys.ShiftActivate
end

local function buildTooltip()
	destroyTooltip()
	
	local keysToShow
	if shiftHeld and hasShiftActions() then
		keysToShow = {"ShiftActivate", "ShiftToggleWeapon", "ShiftToggleSpell", "Attack"}
	else
		keysToShow = {"Activate", "ToggleWeapon", "ToggleSpell", "Attack"}
	end
	
	local lines = {}
	local customContentFn = nil
	
	for _, key in ipairs(keysToShow) do
		local action = assignedKeys[key]
		
		-- Fallback to main action if showing shift keys but shift action doesn't exist
		if not action and shiftHeld and key ~= "Attack" then
			local baseKey = key:gsub("^Shift", "")
			action = assignedKeys[baseKey]
		end
		
		if action then
			table.insert(lines, {
				key = key,
				icon = keyIcons[key],
				label = action.label,
				disabled = action.disabled,
			})
			
			-- Capture custom content from first action that has it
			if action.customContent and not customContentFn then
				customContentFn = action.customContent
			end
		end
	end
	
	if #lines == 0 then return end
	
	local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
	
	local validIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
	validIconHsv[2] = validIconHsv[2] * 0.6
	validIconHsv[3] = math.min(1, validIconHsv[3] * 1.8)
	local validIconColor = util.color.rgb(hsvToRgb(validIconHsv[1], validIconHsv[2], validIconHsv[3]))
	
	local disabledIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
	disabledIconHsv[2] = disabledIconHsv[2] * 0.3
	disabledIconHsv[3] = math.min(1, disabledIconHsv[3] * 0.4)
	local disabledIconColor = util.color.rgb(hsvToRgb(disabledIconHsv[1], disabledIconHsv[2], disabledIconHsv[3]))
	
	local content = ui.content{}
	
	for _, line in ipairs(lines) do
		local iconColor = line.disabled and disabledIconColor or validIconColor
		local textColor = line.disabled and disabledIconColor or WORLD_TOOLTIP_FONT_COLOR
		
		content:add({
			type = ui.TYPE.Flex,
			props = { horizontal = true, autoSize = true },
			content = ui.content{
				{
					type = ui.TYPE.Image,
					props = {
						resource = line.icon and getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/"..line.icon..".dds") or getTexture("transparent"),
						size = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
						alpha = line.icon and 0.6 or 0,
						color = iconColor,
					}
				},
				{
					type = ui.TYPE.Text,
					props = {
						text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "")..line.label,
						textColor = textColor,
						textShadow = true,
						textSize = math.max(1, WORLD_TOOLTIP_FONT_SIZE),
						alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
					}
				}
			}
		})
	end
	
	-- Shift hint
	if not shiftHeld and hasShiftActions() then
		content:add({
			type = ui.TYPE.Text,
			props = {
				text = "[Shift] More...",
				textColor = disabledIconColor,
				textShadow = true,
				textSize = math.max(1, WORLD_TOOLTIP_FONT_SIZE - 2),
			}
		})
	end
	
	-- Custom content injection
	if customContentFn then
		content:add{props = {size = v2(1, 1) * 2}}
		local customLayout = customContentFn(currentTarget)
		if customLayout then
			content:add(customLayout)
		end
	end
	
	interactionTooltip = ui.create({
		layer = 'Scene',
		name = "worldInteractionTooltip",
		type = ui.TYPE.Flex,
		props = {
			relativePosition = v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100),
			anchor = anchor,
			horizontal = false,
			autoSize = true,
			arrange = anchor.x < 0.4 and ui.ALIGNMENT.Start or anchor.x > 0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center,
		},
		content = content
	})
end

-- ════════════════════════════════════════════════════════════════════════════════
-- Raycast Handler
-- ════════════════════════════════════════════════════════════════════════════════

local function raycastChanged()
	if not G_raycastResultType or not I.UI.isHudVisible() or saveData.playerInfo.isInWerewolfForm then
		if interactionTooltip then
			destroyTooltip()
			restoreControls()
			currentTarget = nil
			currentTargetType = nil
			assignedKeys = {}
		end
		return
	end
	local hitObject = G_raycastResult.hitObject
	
	if currentTarget == hitObject then return end
	currentTarget = hitObject
	currentTargetType = G_raycastResultType
	
	-- Gather actions from all modules
	local actions = {}
	
	for moduleId, module in pairs(G_worldInteractions) do
		local canInteract = module.canInteract and module.canInteract(hitObject, G_raycastResultType)
		if canInteract then
			local moduleActions = module.getActions and module.getActions(hitObject, G_raycastResultType) or {}
			for _, action in ipairs(moduleActions) do
				action.moduleId = moduleId
				table.insert(actions, action)
			end
		end
	end
	
	-- Assign hotkeys
	assignedKeys = {}
	
	local fallbackOrder = {
		Activate = {"Activate", "ToggleWeapon", "ToggleSpell", "ShiftActivate", "ShiftToggleWeapon", "ShiftToggleSpell"},
		ToggleWeapon = {"ToggleWeapon", "ToggleSpell", "ShiftToggleWeapon", "ShiftToggleSpell"},
		ToggleSpell = {"ToggleSpell", "ToggleWeapon", "ShiftToggleSpell", "ShiftToggleWeapon"},
		Attack = {"Attack"},
	}
	
	for _, action in ipairs(actions) do
		local pref = action.preferred or "ToggleWeapon"
		local order = fallbackOrder[pref] or fallbackOrder.ToggleWeapon
		
		for _, slot in ipairs(order) do
			if not assignedKeys[slot] then
				assignedKeys[slot] = action
				break
			end
		end
	end
	
	-- Check for non-attack actions (attack actions don't block controls)
	local hasNonAttackAction = assignedKeys.ToggleWeapon or assignedKeys.ToggleSpell or assignedKeys.Activate
	local hasAnyAction = hasNonAttackAction or assignedKeys.Attack
	
	if hasAnyAction then
		disableControls(assignedKeys.Attack, hasNonAttackAction)
		buildTooltip()
	else
		destroyTooltip()
		restoreControls()
	end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- Animation Handler (dispatches to Attack action's onHit)
-- ════════════════════════════════════════════════════════════════════════════════

local stopOnce = true

I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if stopOnce and key:find("stop") then
		startedUse = core.getSimulationTime() + 0.04
		stopOnce = false
	elseif key:find("hit") then
		startedUse = core.getSimulationTime() + 0.04
		stopOnce = true
		
		local attackAction = assignedKeys.Attack
		local target = currentTarget
		local targetType = currentTargetType
		local hitPos = G_raycastResult and G_raycastResult.hitPos
		
		-- Fallback: if rendering ray missed, try physics raycast to find a target
		if not target then
			local yaw = camera.getYaw()
			local pitch = camera.getPitch()
			local cosPitch = math.cos(pitch)
			local dir = util.vector3(
				math.sin(yaw) * cosPitch,
				math.cos(yaw) * cosPitch,
				-math.sin(pitch)
			)
			local cameraPos = camera.getPosition()
			local maxDist = (core.getGMST("iMaxActivateDist") or 192) + camera.getThirdPersonDistance()
			local telekinesis = typesActorActiveEffectsSelf:getEffect(core.magic.EFFECT_TYPE.Telekinesis)
			if telekinesis then
				maxDist = maxDist + telekinesis.magnitude * 22
			end
			local ray = nearby.castRay(cameraPos, cameraPos + dir * maxDist, { ignore = self })
			if ray.hitObject then
				hitPos = ray.hitPos
				local hitType = tostring(ray.hitObject.type)
				for _, module in pairs(G_worldInteractions) do
					if module.canInteract and module.canInteract(ray.hitObject, hitType) then
						local actions = module.getActions and module.getActions(ray.hitObject, hitType) or {}
						for _, action in ipairs(actions) do
							if action.preferred == "Attack" and action.onHit then
								attackAction = action
								target = ray.hitObject
								targetType = hitType
								break
							end
						end
					end
					if target then break end
				end
			end
		end
		
		-- Dispatch to Attack action if we have a valid target
		if attackAction and attackAction.onHit and target then
			local now = core.getSimulationTime()
			local weaponSpeed = animation.getSpeed(self, groupname)
			--local equipped = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
			--if equipped then
			--	local weaponRecord = types.Weapon.record(equipped)
			--	weaponSpeed = weaponSpeed * weaponRecord.speed
			--end
			if now > lastHit + 0.35/weaponSpeed then
				local swingData = getSwingData(groupname, key)
				lastHit = now
				attackAction.onHit(target, targetType, groupname, key, swingData, hitPos)
			end
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- Frame Update (shift key monitoring)
-- ════════════════════════════════════════════════════════════════════════════════

local function onFrame(dt)
	local newShiftHeld = input.isShiftPressed()
	if newShiftHeld ~= shiftHeld then
		shiftHeld = newShiftHeld
		if currentTarget and hasShiftActions() then
			buildTooltip()
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- Input Handlers
-- ════════════════════════════════════════════════════════════════════════════════

local function executeAction(baseKey)
	local key = shiftHeld and ("Shift"..baseKey) or baseKey
	local action = assignedKeys[key]
	
	-- Fallback to main action if shift is held but no shift action exists
	if not action and shiftHeld then
		action = assignedKeys[baseKey]
	end
	
	if action then
		if action.disabled and action.failedHandler then
			action.failedHandler(currentTarget)
		elseif action.handler and not action.disabled then
			action.handler(currentTarget)
		end
	end
end

input.registerTriggerHandler("ToggleWeapon", async:callback(function()
	if assignedKeys.ToggleWeapon or assignedKeys.ShiftToggleWeapon then
		executeAction("ToggleWeapon")
	end
end))

input.registerTriggerHandler("ToggleSpell", async:callback(function()
	if assignedKeys.ToggleSpell or assignedKeys.ShiftToggleSpell then
		executeAction("ToggleSpell")
	end
end))

input.registerTriggerHandler("Activate", async:callback(function()
	if assignedKeys.Activate or assignedKeys.ShiftActivate then
		executeAction("Activate")
	end
end))

-- ════════════════════════════════════════════════════════════════════════════════
-- Refresh handler (for settings changes, etc)
-- ════════════════════════════════════════════════════════════════════════════════

local function refreshTooltip()
	if currentTarget then
		currentTarget = nil
		raycastChanged()
	end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- Registration
-- ════════════════════════════════════════════════════════════════════════════════

table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_onFrameJobs, onFrame)
table.insert(G_refreshWidgetJobs, refreshTooltip)
table.insert(G_refreshTooltipJobs, refreshTooltip)
table.insert(G_refreshTooltipJobs, function()
	if interactionTooltip then
		interactionTooltip:update()
	end
end)


-- ════════════════════════════════════════════════════════════════════════════════
-- Built-in Interactions
-- ════════════════════════════════════════════════════════════════════════════════

G_worldInteractions.consumable = {
	canInteract = function(object, objectType)
		if WORLD_CONSUME_TOOLTIPS == "Hide" then return end
		if types.Potion.objectIsInstance(object) and object.recordId ~= "potion_t_bug_musk_01" then return true end
		if not types.Ingredient.objectIsInstance(object) then return end
		if not saveData.registeredConsumables[object.recordId] and not dbConsumables[object.recordId] then return end
		if G_isBathingItem(object) then return end
		return true
	end,
	getActions = function(object, objectType)
		local dbEntry = saveData.registeredConsumables[object.recordId] or dbConsumables[object.recordId]
		local text = ""
		local name = object.type.record(object).name:gsub(" %b[]", ""):gsub("^%s+", "")
		
		if WORLD_CONSUME_TOOLTIPS == "Detailed" then
			text = name.." ("
			local foodValue = G_getFoodValue(object) or 0
			local drinkValue = G_getTheoreticalDrinkValue(object) or 0
			local wakeValue = G_getWakeValue(object) or 0
			
			if drinkValue > foodValue then
				text = text .. string.format("%+d%% thirst", -drinkValue*100)
				if wakeValue ~= 0 then
					text = text .. string.format(", %+d%% tiredness", -wakeValue*100)
				end
				text = text ..")"
			elseif foodValue ~= 0 then
				text = string.format("%+d%% hunger", -foodValue*100)
				if wakeValue ~= 0 then
					text = text .. string.format(", %+d%% tiredness", -wakeValue*100)
				end
				text = text ..")"
			elseif wakeValue ~= 0 then
				text = string.format("%+d%% tiredness", -wakeValue*100)
				text = text ..")"
			end
		end
		return {{
			label = "Consume "..text,
			preferred = "ToggleWeapon",
			disabled = isTheft(object),
			handler = function(obj)
				core.sendGlobalEvent('UseItem', {object = object, actor = self})
				if obj.count == 1 then
					core.sendGlobalEvent('SunsDusk_LootVfxItem', object)
					--core.sendGlobalEvent('SunsDusk_removeItem', {nil, object})
					core.sendGlobalEvent('SunsDusk_downgradeWorldConsumable', {self, object})
				end
			end
		}}
	end
}


local VALID_INSTRUMENTS = {
	["misc_de_drum_01"] = true,
	["misc_de_drum_02"] = true,
	["t_imp_drum_01"] = true,
	["t_imp_drum_02"] = true,
	["t_imp_drum_03"] = true,
	["t_imp_drum_04"] = true,
	["t_nor_deerskindrum_01"] = true,
	["t_orc_drum_01"] = true,
	["t_rga_drum_01"] = true,
	["tr_m4_q_headless_drum_uni"] = true,
	["tr_m7_othm_q_madranadrum"] = true,
	["sky_qre_nar2_drum"] = true,
}

local MUSIC_SOUNDS = {
	"sound/sunsdusk/bongos/bongo0.mp3",
	"sound/sunsdusk/bongos/bongo1.mp3",
	"sound/sunsdusk/bongos/bongo2.mp3",
	"sound/sunsdusk/bongos/bongo3.mp3",
	"sound/sunsdusk/bongos/bongo4.mp3",
}

local soundCounter = math.random(1, #MUSIC_SOUNDS)

G_worldInteractions.musicItem = {
	canInteract = function(object, objectType)
		return VALID_INSTRUMENTS[object.recordId] == true
	end,
	getActions = function(object, objectType)
		saveData.musicItems = saveData.musicItems or {}
		if not saveData.musicItems[object.id] then
			saveData.musicItems[object.id] = MUSIC_SOUNDS[soundCounter]
			soundCounter = soundCounter % #MUSIC_SOUNDS + 1
		end
		
		local soundFile = saveData.musicItems[object.id]
		local name = object.type.record(object).name:gsub(" %b[]", ""):gsub("^%s+", "")
		
		return {{
			label = "",
			preferred = "ToggleWeapon",
			handler = function(obj)
				ambient.playSoundFile(soundFile, {
					volume = 0.5,
					position = self.position
				})
			end
		}}
	end
}