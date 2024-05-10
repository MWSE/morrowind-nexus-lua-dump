-- Modernized UI
-- With help from user "ownlyme" on Nexus!

local interfaces = require('openmw.interfaces')
local ui = require('openmw.ui')
local deepLayoutCopy = require('openmw_aux.ui').deepLayoutCopy
local API = require('openmw.core').API_REVISION
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local settings = require('scripts.settings')
local helpers = require('scripts.helpers')
local camera = require('openmw.camera')
local Actor = types.Actor
local Player = types.Player
local v2 = util.vector2
local v3 = util.vector3

-- Player values and their respective names
local stats = {
 	health = Player.stats.dynamic.health(self),
	fatigue = Player.stats.dynamic.fatigue(self),
	magicka = Player.stats.dynamic.magicka(self),
}

-- Effects and their respective stat
local effects = {
	["restorehealth"] = "health",
	["restorefatigue"] = "fatigue",
	["restoremagicka"] = "magicka",
}

-- Gauge colors
local colors = {
	health = util.color.rgb(200/255, 60/255, 30/255),
	fatigue = util.color.rgb(0, 150/255, 60/255),
	magicka = util.color.rgb(53/255, 69/255, 159/255),
}

-- GUI widget properties
local foreground = ui.texture { path = "textures/menu_bar_gray.tga" }
local background = ui.texture { path = "white" }
local segment = ui.texture { path = "textures/segment100.tga" }
local cornerMargin = 12
local horizontalOffset = 80
local verticalOffset = 0

-- Delta time
local dt = 0

-- Combat
local combatTimer = 0	-- Timer for the combat HUD to fade out
local combatData		-- Data from the combat event
local listOfEnemies = {}-- List of enemies in combat
local targetedEnemyId		-- The enemy currently targeted, holds the id of the enemy
local cachedTarget 		-- The enemy that has been removed from combat, to keep updating the HUD
local alpha = 0	
local barWidth = 12

local targetPositionExceptions = {
	rat = -40,
	ratblighted = -40,
	nixhound = 25,
	scamp = 45,
	alitdiseased = 100,
	kagoutidiseased = 75,
	guarferal = 75,

	mudcrabdiseased = 40,

	cliffracer = 0,
}

-- Page variables
local MUISmoothTransitions = storage.playerSection('MUISmoothTransitions')
local MUIYellowRemainder = storage.playerSection('MUIYellowRemainder')
local MUIMisc = storage.playerSection('MUIMisc')
local MUIExperimental = storage.playerSection('MUIExperimental')
local MUIEnemy = storage.playerSection('MUIEnemy')

------------------------------------------------------------------------------------- UI elements

local bar = {
    type = ui.TYPE.Container,
	props = {
		visible = true,
		alpha = 1,
	},
	userData = {
		lerp = 0,
		borderLerp = 0,
		remainder = 0,
		remainderCap = 0,
		timer = 0,
		cache = 0,
		incomingRestoration = 0,

		-- For segments
		history = {},

		-- For damage taken
		statLoss = 0,
		accumulatedLoss = 0,
		lastStat = 0,
		cachedValue = 0,
		damageValueTimer = 0,

		enableFlash = true,
		enableBorderLerp = false,

	},
    content = ui.content {
		{
			name = 'background',
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = true,
				tileV = true,
			},
		},
		{
			name = 'remainder',
			type = ui.TYPE.Image,
			props = {
				resource = foreground,
				position = v2(2, 0),
				tileH = true,
				tileV = true,
				color = util.color.rgb(243/255,237/255,22/255)
			}
		},
		{
			name = 'foreground',
			type = ui.TYPE.Image,
			props = {
				resource = foreground,
				position = v2(2, 0),
				tileH = true,
				tileV = true,
				color = util.color.rgb(200/255, 60/255, 30/255)
			},
		},
		{
			name = 'healing',
			type = ui.TYPE.Image,
			props = {
				resource = foreground,
				position = v2(2, 0),
				tileH = true,
				tileV = true,
				color = util.color.rgb(255/255, 255/255, 255/255),
				alpha = 1
			},
		},
		{
			name = 'value',
			type = ui.TYPE.Text,
			props = {
				text = "",
				textColor = util.color.rgba(1, 1, 1, 0.5),
				position = v2(2.5, 6),
				textShadow = true,
				anchor = v2(0, 0.5),
				relativePosition = v2(0, 0.5),
			}
		},
		{
			name = 'border',
			template = interfaces.MWUI.templates.borders,
			props = {
			},
		},
		{	
			name = 'segment50',
			type = ui.TYPE.Image,
			props = {
				resource = segment,
				position = v2(4, 0),
				tileH = true,
				tileV = true,
			},
		},
		{	
			name = 'segment100',
			type = ui.TYPE.Image,
			props = {
				resource = segment,
				position = v2(4, 0),
				tileH = true,
				tileV = true,
			},
		},
	},
	events = {
		mouseClick = function()
			print("CLICKED!")
			interfaces.UI.setMode('Interface', {windows = {'Map', 'Stats', 'Magic', 'Inventory'}})
		end
	}
}

local bars = { 
	health = deepLayoutCopy(bar), 
	fatigue = deepLayoutCopy(bar), 
	magicka = deepLayoutCopy(bar) 
}

local targetName = {
	type = ui.TYPE.Text,
	props = {
		text = "",
		textColor = util.color.rgb(1, 1, 1),
		textShadow = true,
		textSize = 14,
		alpha = 1
	}
}

local targetDamage = {
	type = ui.TYPE.Container,
	props = {
		alpha = 1,
		relativePosition = v2(1, 0),
		anchor = v2(1, 0),
		size = v2(100, 15),
		relativeSize = v2(1, 1),
	},
}

local targetBar = deepLayoutCopy(bar)
targetBar.name = "target"

-- For loop that assigns the names of the bars
for stat, bar in pairs(bars) do
	bar.name = stat
end

local screen = {
	type = ui.TYPE.Widget,
	layer = 'HUD',
	props = {
		position = v2(0, 0),
		relativeSize = v2(1, 1),
		anchor = v2(0, 0),
		relativePosition = v2(0, 0),
		visible = true,
	},
	content = ui.content {
		{	
			name = 'flex',
			type = ui.TYPE.Flex,
			layer = 'HUD',
			props = {
				position = v2(cornerMargin + horizontalOffset, -cornerMargin + verticalOffset),
				anchor = v2(0, 1),
				relativePosition = v2(0, 1),
				arrange = ui.ALIGNMENT.Start,
				horizontal = false,
				visible = true,

			},
			content = ui.content {
				{	
					template = bars['health']
				},
				{ template = spacer },
				{
					template = bars['fatigue']
				},
				{ template = spacer },
				{
					template = bars['magicka']
				}
			}
		},
		{	
			name = 'TargetWidget',
			type = ui.TYPE.Flex,
			props = {
				anchor = v2(0.5, 1),
				relativePosition = v2(0.5, 0.8),
				arrange = ui.ALIGNMENT.Center,
				horizontal = false,
				visible = true,
			},
			content = ui.content {
				{
					template = targetName
				},
				{ template = spacer },
				{	
					template = targetBar
				},
				{
					template = targetDamage,
					content = ui.content {
						{
							type = ui.TYPE.Text,
							props = {
								text = "-34",
								textColor = util.color.rgb(214/255,203/255,166/255),
								textShadow = true,
								textSize = 12,
								alpha = 1,
								relativePosition = v2(1, 0),
								anchor = v2(1, 0),
								relativeSize = v2(1, 1),
							}
						}
					}
				}
			},
		},
	}
}

local hud = ui.create(screen)

------------------------------------------------------------------------------------- Handling of elements
local function calculateRemainder(bar)
	local d = bar.userData
	local historyLength = 60
	local normalized
	normalized = d.current / d.base
	normalizedLerp = d.lerp / d.base
	d.remainderCap = d.remainder

	
	table.insert(d.history, 1, normalized)												-- Record the history								
	if #d.history > historyLength then table.remove(d.history) end						-- Clear entries older than historyLength frames
	if d.history[historyLength] == nil then d.history[historyLength] = normalized end 	-- Prevents nil values
	if d.remainder < normalizedLerp then
		d.remainder = normalizedLerp
		d.remainderCap = normalizedLerp
		d.timer = 0
	elseif d.timer > historyLength/60 then	
		d.remainder = smoothstep(d.remainder, math.min(math.max(d.history[historyLength], normalized), d.remainderCap), MUIYellowRemainder:get('YellowRemainderDrainSpeed') * ((d.remainder - normalized) + 1) * dt)
	end
	
	d.timer = d.timer + dt
	return d.remainder
end

local function setTargetBarPos(a)
	local verticalOffset = MUIEnemy:get('VerticalOffset') / 100
	if MUIEnemy:get('PositionAnchor') == false then
		screen.content['TargetWidget'].props.relativePosition = v2(0.5, verticalOffset)
		return
	end

	local playerPos = self.object.position
	local barPos = screen.content['TargetWidget'].props
	local box = a.object:getBoundingBox()
	local record, raceHeight
	if types.NPC.objectIsInstance(a.object) then
		record = types.NPC.record(a.object.recordId)
		raceHeight = types.NPC.races.record(record.race).height.male * 135
	else 
		record = types.Creature.record(a.object.recordId)
		raceHeight = box.halfSize.z
	end

	-- Remove spaces and dashes from the record name
	local id = record.id:gsub("%s+", ""):gsub("-", ""):gsub("_", "")

	if targetPositionExceptions[id] then
		if targetPositionExceptions[id] == 0 then
			barPos.relativePosition = v2(0.5, 0.8)
			return
		else 
			raceHeight = raceHeight + targetPositionExceptions[id]
		end
	end
	
	local top = v3(a.object.position.x, a.object.position.y, a.object.position.z + raceHeight)
	local pos = camera.worldToViewportVector(top)
	local screenSize = ui.screenSize() -- Screen size in pixels
	normalized = v2(pos.x / screenSize.x, pos.y / screenSize.y)

	local isInBoundsX = isInRange(normalized.x, 0.05, 0.95)
	local isInBoundsY = isInRange(normalized.y, 0.05, 0.95)

	-- Check if the player is facing the enemy
	local playerDir = camera.getYaw()
	local enemyDir = math.atan2(top.x - playerPos.x, top.y - playerPos.y)
	local isFacingEnemy = isInRange(math.abs(playerDir - enemyDir), 0, math.pi / 2)

	if isInBoundsX and isInBoundsY and (a.object.cell == self.object.cell) then
		if isFacingEnemy then
			barPos.relativePosition = v2(normalized.x, normalized.y)
		else
			barPos.relativePosition = v2(0.5, verticalOffset)
		end
	else
		barPos.relativePosition = v2(0.5, verticalOffset)
	end
end

local function sendRay() -- Send ray from camera straight ahead from crosshair
	local pos = camera.getPosition()
	local dir = pos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 1000
	local ray = nearby.castRay(pos, dir, { collisionType = nearby.Actor, ignore = self })
	if ray.hit == true and ray.hitObject ~= nil then
		return tonumber(ray.hitObject.id)
    end
end

local function drawSegments(bar, width)
	local c = bar.content
	if not MUIExperimental:get('SegmentedNotches') then 
		c['segment50'].props.visible = false
		c['segment100'].props.visible = false
		return
	end

	local barLength = math.min(bar.userData.base * MUIMisc:get('LengthMultiplier') / 10, MUIMisc:get('LengthCap') + 4)
	c['segment50'].props.visible = true
	c['segment100'].props.visible = true

	-- 100HP
	local size = 100 / (bar.userData.base / barLength)
	c['segment100'].props.resource = ui.texture {
		path = "textures/segment100.tga",
		size = v2(size, 18),
		offset = v2(4 - size, 0),
	}

	-- 50HP
	if (bar.userData.base / barLength) > 1.2 then size = 0 end
	c['segment50'].props.resource = ui.texture {
		path = "textures/segment50.tga",
		size = v2(size, 18),
		offset = v2(4 - size, 0),
	}

	c['segment50'].props.position = v2(3 - size / 2, 0)
	c['segment50'].props.size = v2(barLength + (size / 2) -2, width - 2)

	c['segment100'].props.position = v2(3, 0)
	c['segment100'].props.size = v2(barLength - 5, width - 2)

	hud:update()
end

local function settingsChanged()
	local f = screen.content['flex']
	if(MUIMisc:get('Position')) then
		f.props.position = v2(cornerMargin, cornerMargin)
		f.props.anchor = v2(0, 0)
		f.props.relativePosition = v2(0, 0)
	else
		f.props.position = v2(cornerMargin + horizontalOffset, -cornerMargin + verticalOffset)
		f.props.anchor = v2(0, 1)
		f.props.relativePosition = v2(0, 1)
	end

end

local function calculateLerp(bar)
	local d = bar.userData
	local lerpSpeed = MUISmoothTransitions:get('LerpSpeed')
	d.lerp = smoothstep(d.lerp, d.current, dt * lerpSpeed)

	local clampedLerp = math.min(math.max(d.lerp, 0), d.base)
	return (clampedLerp / d.base)
end

local function calculateRestoration(bar, length) -- Credit to user "ownlyme" on Nexus!
	local timeBand = 3
	local incomingRestoration = 0

	for effect, stat in pairs(effects) do
		for a, b in pairs(Actor.activeSpells(self)) do
			for c, d in pairs(b.effects) do
				if d.id == effect and bar.name == stat then
					local duration = d.durationLeft
					if duration == nil then return 0 end
					incomingRestoration = incomingRestoration + (d.maxMagnitude + d.minMagnitude) / 2 * duration
				end
			end
		end
	end
	local restoration, size, position
	if MUISmoothTransitions:get('SmoothTransitions') then
		restoration = bar.userData.current + incomingRestoration
		size = ((math.floor(restoration) - math.floor(bar.userData.current)) / bar.userData.base) * length
		position = v2((math.floor(bar.userData.current) / bar.userData.base) * length + 2, 0)
	else
		restoration = bar.userData.current + incomingRestoration
		size = ((math.floor(restoration) - math.floor(bar.userData.current)) / bar.userData.base) * length
		position = v2((math.floor(bar.userData.current) / bar.userData.base) * length + 2, 0)
	end

	return math.min(size, length + 4 - position.x), position
end

local function handleStatValueDisplay(bar)
	local d = bar.userData
	local timerLength = MUIYellowRemainder:get('YellowRemainderTimer') / 10
	local drainSpeed = MUIYellowRemainder:get('YellowRemainderDrainSpeed')
	local statLoss = d.lastStat - d.current
	d.accumulatedLoss = d.accumulatedLoss + statLoss
	if d.accumulatedLoss < 0 then d.accumulatedLoss = 0 end

	if statLoss ~= 0 then -- Indicates damage taken
		d.damageValueTimer = 0
	end

	if d.accumulatedLoss < 1 then
		d.damageValueTimer = 0
		d.accumulatedLoss = 0
		return tostring(math.floor(d.current))
	end

	d.damageValueTimer = d.damageValueTimer + dt

	if d.damageValueTimer > timerLength then
		d.accumulatedLoss = smoothstep(d.accumulatedLoss, 0, dt * drainSpeed)
		if d.accumulatedLoss < 0 then d.accumulatedLoss = 0 end
	end

	local offset = (d.current + d.accumulatedLoss) % 1

	return math.floor(d.current + d.accumulatedLoss), math.ceil(d.accumulatedLoss - offset)
end

local function handleBar(bar, stat, color, width)
	local d = bar.userData
	d.current = stat.current
	d.base = stat.base
	bar.content['foreground'].props.color = color
	if(stat.base < 1) then 
		bar.props.visible = false
	else	
		bar.props.visible = true
	end

	local normalized = d.current / d.base
	local borderSize = 4
	local LengthMultiplier, LengthCap = MUIMisc:get('LengthMultiplier') / 10, MUIMisc:get('LengthCap')

	local length = math.min(d.base * LengthMultiplier, LengthCap)
	if d.enableBorderLerp == true and MUISmoothTransitions:get('SmoothTransitions') then
		d.borderLerp = smoothstep(d.borderLerp, length, dt * 48)
		length = d.borderLerp
	else 
		d.borderLerp = length
	end
	-- Foreground & Remainder
	if MUISmoothTransitions:get('SmoothTransitions') then 
		bar.content['foreground'].props.size = v2(calculateLerp(bar) * length, width)
	else 
		bar.content['foreground'].props.size = v2(normalized * length, width) 
	end
	--bar.content['remainder'].props.size = l(math.min(calculateYellowRemainder(bar) * length, length))
	bar.content['remainder'].props.size = v2(math.min(calculateRemainder(bar) * length, length), width)


	-- Background & Borders
	local equippedSpell = Actor.getSelectedSpell(self)
	local equippedSpellCost 

	if equippedSpell == nil then 
		equippedSpellCost = 0 
	else 
		equippedSpellCost = equippedSpell.cost
	end
	local flash = oscillateBackground(dt * 7)
	local stance = Actor.getStance(self)

	bar.content['background'].props.size = v2(length + borderSize, width)
	bar.content['border'].props.size = v2(length + borderSize, width)

	if d.enableFlash == true then
		if (stat.current / stat.base < 0.15 or stat.current < 16) and stance > 0 and MUIMisc:get('FlashWhenLow') and bar.name ~= "magicka" then 
			bar.content['background'].props.color = flash
		elseif bar.name == "magicka" and equippedSpellCost > d.current and stance == 2 then
			bar.content['background'].props.color = flash
		else 
			bar.content['background'].props.color = util.color.rgb(0, 0, 0)
		end
	end

	-- Restoration Effects
	local size, pos = calculateRestoration(bar, length)
	bar.content['healing'].props.size = v2(size, width)
	bar.content['healing'].props.position = pos

	-- Segments
	drawSegments(bar, width)

	local hpTick, accumulatedDamage = handleStatValueDisplay(bar)

	-- Value overlay
	if MUIMisc:get('ShowValues') and bar.name ~= "target" then 
		bar.content['value'].props.text = tostring(math.floor(d.current))
	else 
		bar.content['value'].props.text = "" 
	end
	
	d.lastStat = stat.current
end

local function handleCombat()
	local target = sendRay()
	if listOfEnemies[target] then 
		targetedEnemyId = target
	end

	if listOfEnemies[targetedEnemyId] then 
		target = listOfEnemies[targetedEnemyId]
	else
		target = cachedTarget
	end

	if not target then return end

	setTargetBarPos(target)

	--print("Handling combat. Debug: " .. target.debug)
	handleBar(targetBar, { current = target.health, base = target.maxHealth }, colors['health'], barWidth + 2)
	targetBar.userData.enableFlash = false
	targetBar.userData.enableBorderLerp = true

	local name = target.name
	if MUIEnemy:get('ShowEnemyLevels') then name = name .. ", " .. target.level end
	if MUIEnemy:get('ShowEnemyClass') and target.class ~= nil then name = name .. ", " .. target.class end
	targetName.props.text = name

	if target.health == 0 then targetName.props.textColor = util.color.rgb(200/255, 60/255, 30/255)
	else targetName.props.textColor = util.color.rgb(214/255,203/255,166/255) end
end

local function handleCombatTimer()
	local target = listOfEnemies[targetedEnemyId]
	if combatTimer < 3 then 
		combatTimer = combatTimer + dt
		alpha = math.min(alpha + dt * 6, 1)
		targetBar.props.alpha = math.min(targetBar.props.alpha + dt * 6, 1)
		targetName.props.alpha = alpha
	elseif target then
		if target.health == 0 or target.object.cell ~= self.object.cell then
			alpha = math.max(alpha - dt * 6, 0)
			targetBar.props.alpha = alpha
			targetName.props.alpha = alpha
		end
	else
		alpha = math.max(alpha - dt * 6, 0)
		targetBar.props.alpha = alpha
		targetName.props.alpha = alpha
	end

	if alpha > 0 and MUIEnemy:get('EnableEnemyHealthbar') then
		handleCombat()
	end
end

local function sendCombatData(enemy) 
	local id = enemy.id							-- The enemy source for identification in the list.
	if id == nil then return end
	if listOfEnemies[id] then 										-- If the enemy is already in combat
		if enemy.health == 0 or enemy.stoppedTargeting then 			-- If its dead or has stopped targeting the player
			cachedTarget = enemy										-- Remove it from the list
			listOfEnemies[id] = nil
			targetedEnemyId = next(listOfEnemies)
		elseif targetedEnemyId == id and enemy.hasBeenHealed then 	-- If it already is targeted and is healing, as to not target itself if it heals
			listOfEnemies[id] = enemy
	elseif not enemy.hasBeenHealed then									-- Else update its stats.
			listOfEnemies[id] = enemy
			targetedEnemyId = id
		end
	elseif enemy.health > 0 then										-- If the enemy is not already in combat, add it to the list
		table.insert(listOfEnemies, id, enemy)
		print("Added: " .. enemy.name .. " to the list.")
		targetedEnemyId = id
	end
	
	combatTimer = 0
end

local function updateHud()
	for stat, bar in pairs(bars) do
		handleBar(bar, stats[stat], colors[stat], barWidth)
	end

	handleCombatTimer()

	hud:update()
end
------------------------------------------------------------------------------------- Update cycle

-- Call this once to apply the initial settings
settingsChanged()
MUIMisc:subscribe(async:callback(settingsChanged))

local function onFrame(_dt)
	dt = _dt
	if API >= 59 then
		if interfaces.UI.isHudVisible() or self.object.cell ~= nil then
			screen.props.visible = true
			updateHud()
		else 
			screen.props.visible = false
			hud:update()
		end
	else 
		updateHud()
	end
end

return {
    engineHandlers = {
		onFrame = onFrame,
    },

	eventHandlers = {
		SendCombatData = sendCombatData,
	}
}