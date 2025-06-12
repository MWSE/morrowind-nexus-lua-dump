local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require('openmw.input')
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require('openmw.storage')

-- Reference resolution values (for 1920x1080)
local refWidth = 1920
local refHeight = 1080
local refAspectRatio = refWidth / refHeight

-- Get current screen dimensions
local screenSize = ui.screenSize()
local currentAspectRatio = screenSize.x / screenSize.y

-- Calculate scale factors
local scaleX = screenSize.x / refWidth
local scaleY = screenSize.y / refHeight
local uiScale = math.min(scaleX, scaleY)  -- Use the smaller scale to prevent stretching

-- Function to scale sizes based on screen resolution
local function scaleSize(width, height)
    return util.vector2(width * uiScale, height * uiScale)
end

local raycastCurrentLength

local fadeOutTimer = 0
local fadeOutTime = 1
local isFadeOut = false
local timeToShow = 0
local focusTime = 1
local combatTime = 3
local widgetIsShowing = false

local barSize = scaleSize(252, 12)

local npcRecord


local isNPC = types.NPC.objectIsInstance
local isCreature = types.Creature.objectIsInstance

local cachedActorTickTime = 0.1
local cachedActorTickTimer = 0

local lastNPCTable = {}
local lastNPCMaxTableSize = 7
local tableTimerMaxTime = 60

local healthAnimTimeBase = 0.8

local healthText

local commonTimer = 0
local commonCheckTime = 1.5
local isShowTime = false

local overridingTimer = 0
local isOverridingTime = false

local healthBarSize = scaleSize(252, 12)

local currentActorInFocus = nil

local timerToUpdateAfterWater = 0
local defaultPos
local needToUpdateWhileSwimming = true
local timeToUpdateAfterWater = 3
local actorHealth = types.Actor.stats.dynamic.health
local tooltipTarget
local widgetStorage = storage.playerSection('MMUIWidget')
local cursorPos = widgetStorage:get('cursorPos') or util.vector2(0, 0)
local actorLevel

local guards = "Hlaalu Guard, Redoran Guard, Telvanni Guard, Guard, Company Guard, Duke's Guard, Ordinator"

local actorsInCombat = {}
local player

local MODE = camera.MODE
local targetMaxDistance = 50000


-- should probably refresh every time 
local screenSize = ui.screenSize()

local healthBarElement = ui.create {
    name = 'healthBarContent',
    props = {
        visible = false,
        relativeSize = util.vector2(1, 1),
        anchor = util.vector2(-0.2, -0.3),
    },
    content = I.MM_UI.getFocusHealthBar(),
}

local nameElement = ui.create {
    layer = 'Windows',
	type = ui.TYPE.Text,
	props = {
	  relativePosition = util.vector2(0.5, 0.01),
	  anchor = util.vector2(0.5, 0),
	  text = '',
	  textSize = 24,
	  textShadow = true,
	  textShadowColor = util.color.rgb(0, 0, 0),
	  textColor = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
      textAlignH = ui.ALIGNMENT.Center,
	  visible = true,
	},
}

local classElement = ui.create {
-- important not to forget the layer
-- by default widgets are not attached to any layer and are not visible
type = ui.TYPE.Text,
props = {
  -- position in the top right corner
  relativePosition = util.vector2(0.5, 0.0),
  -- position is for the top left corner of the widget by default
  -- change it to align exactly to the top right corner of the screen
  anchor = util.vector2(0.5, -0.35),
  text = '',
  textSize = 19,
  textShadow = true,
  textShadowColor = util.color.rgb(0, 0, 0),
  -- default black text color isn't always visible
  textColor = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
  multiline = true,
  visible = true,
},
}


local levelElement = ui.create {
    layer = 'Windows',
    type = ui.TYPE.Text,
    props = {
      relativePosition = util.vector2(0.5, 0.01),
      anchor = util.vector2(0, 0),
      text = '',
      textSize = 11,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textColor = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
      visible = true,
    },
}

local healthTextElement = ui.create {
	-- important not to forget the layer
	-- by default widgets are not attached to any layer and are not visible
	type = ui.TYPE.Text,
	props = {
	  -- position in the top right corner
	  --relativePosition = util.vector2(0.50, 0.113),
	  -- position is for the top left corner of the widget by default
	  -- change it to align exactly to the top right corner of the screen
	  anchor = util.vector2(0.5, 1.5),
	  text = '',
	  textSize = 24,
	  textShadow = true,
	  textShadowColor =	util.color.rgb(0, 0, 0),
	  -- default black text color isn't always visible
	  textColor = util.color.rgb(1, 1, 1, 1),
	  visible = true,
	},
}

local healthBarFull = ui.create {
	name = 'TutorialNotifyMenu',
	l10n = 'UITutorial',
	layer = 'Windows',
	-- This is a helper template, which sets up this interface element in the style of Morrowind.
	-- Reference: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/interface_mwui.html
	-- template = I.MWUI.templates.boxThick,
	type = ui.TYPE.Widget,
    props = {
		anchor = util.vector2(0.5, -0.7),
		relativePosition = util.vector2(0.5, 0),
		visible = true,
		size = scaleSize(448, 126),
    -- template = I.MWUI.templates.boxThick,
		-- Menu positioning props:
		-- Reference: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/widgets/widget.html

		-- Pin the bottom center (50% X 100% Y) of this container to ...
		----anchor = util.vector2(0.5, 1),
		
		-- the screen horizontal center and near the bottom of the screen (50% X 95% Y).
        ----relativePosition = util.vector2(0.5, 0.95),
	},
	-- Use ui.content for every content field.
	content = ui.content {
        healthBarElement,
        classElement,
        healthTextElement,
    },
}


local actorBarFocus = ui.create {
  name = 'actorBarContent',
  layer = 'Windows',
  type = ui.TYPE.Widget,
  
  props = {
    anchor = util.vector2(0.095, 0),
    relativePosition = util.vector2(0.25, 0),
    visible = false,
    size = scaleSize(1150, 117.2),

  },
  
  content = I.MM_UI.getBG3Focus()
}

local enemyBar = ui.create {
  name = 'actorBarContent',
  layer = 'Windows',
  type = ui.TYPE.Widget,
  props = {
    anchor = util.vector2(0.3472, 0),
    relativePosition = util.vector2(0, 0),
    size = scaleSize(2100, 117.2),

  },
  
  content = I.MM_UI.getBG3EnemyBar()
}

local function updateDefaultPos()
    defaultPos = healthBarFull.layout.props.relativePosition
end

local function updateWidgetStyle()
    healthBarElement.layout.content = I.MM_UI.getFocusHealthBar()
    
    -- Use relative positioning that adjusts with screen size
    actorBarFocus.layout.props.relativePosition = util.vector2(0.25, 0.01)
    enemyBar.layout.props.relativePosition = util.vector2(0.533, 0.01)
    
    -- Scale barSize to maintain consistent appearance across resolutions
    barSize = scaleSize(525, 28)
    
    -- Scale healthBar elements
    healthBarFull.layout.props.size = scaleSize(710, 175)
    healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.65)
    healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0.15)
    
    -- Position nameElement and levelElement
    nameElement.layout.props.relativePosition = util.vector2(0.5, 0.135)
    levelElement.layout.props.relativePosition = util.vector2(0.1, 0.135)
    
    -- Scale text sizes appropriately
    nameElement.layout.props.textSize = math.max(12, math.floor(36 * uiScale))
    levelElement.layout.props.textSize = math.max(8, math.floor(19 * uiScale))
    classElement.layout.props.textSize = math.max(10, math.floor(21 * uiScale))
    healthTextElement.layout.props.textSize = math.max(12, math.floor(21 * uiScale))
    classElement.layout.props.relativePosition = util.vector2(0.505, 0.26)
    
    updateDefaultPos()
end

local function updateStance()
    -- Function left empty - we no longer need to hide UI elements based on stance
end

updateWidgetStyle()
updateStance()


--UI VISIBILITY FUNCTIONS
local function setOpacityFull()
    nameElement.layout.props.alpha = 1.0
    classElement.layout.props.alpha = 1.0
    levelElement.layout.props.alpha = 1.0
    healthTextElement.layout.props.alpha = 1.0
    healthBarFull.layout.props.alpha = 1.0
    healthBarFull.layout.content[1].layout.props.alpha = 1.0
    actorBarFocus.layout.props.alpha = 1.0
    
end

local function enableVisibility()
	nameElement.layout.props.visible = true
	classElement.layout.props.visible = true
	levelElement.layout.props.visible = true
	healthTextElement.layout.props.visible = true
	healthBarFull.layout.props.visible = true
    healthBarFull.layout.content[1].layout.props.visible = true
    actorBarFocus.layout.props.visible = true
  
end


local function updateAllElements()
        healthTextElement:update()
        healthBarFull:update()
        nameElement:update()
        classElement:update()
        levelElement:update()
        healthBarFull.layout.content[1]:update()
        actorBarFocus:update()
        enemyBar:update()
end

local function hideAfterFadeOut()

    nameElement.layout.props.visible = false
    classElement.layout.props.visible = false
    levelElement.layout.props.visible = false
    healthBarFull.layout.props.visible = false
    healthTextElement.layout.props.visible = false
    actorBarFocus.layout.props.visible = false
    --enemyBar.layout.props.visible = false

    fadeOutTimer = 0
    isFadeOut = false
    widgetIsShowing = false

    updateAllElements()
    setOpacityFull()
    
end

local function fadeOutElements(dt)
	fadeOutTimer = fadeOutTimer + dt
		
	-- Gradually lower alpha to 0 over fadeOutTime
	local alphaPercentage = 1.0 - fadeOutTimer / fadeOutTime
	nameElement.layout.props.alpha = math.max(0, alphaPercentage)
	classElement.layout.props.alpha = math.max(0, alphaPercentage)
	levelElement.layout.props.alpha = math.max(0, alphaPercentage)
	healthTextElement.layout.props.alpha = math.max(0, alphaPercentage)
	healthBarFull.layout.props.alpha = math.max(0, alphaPercentage)
	actorBarFocus.layout.props.alpha = math.max(0, alphaPercentage)
	--enemyBar.layout.props.alpha = math.max(0, alphaPercentage)
	updateAllElements()

	if fadeOutTimer >= fadeOutTime then
		hideAfterFadeOut()
	end
end
--UI VISIBILITY FUNCTIONS


--Casting a raycast and getting our actors

local function checkTarget(ray)
	-- First check if we have both a hitObject and hitPos
    if not ray or not ray.hitObject or not ray.hitPos then return false end
	-- Now safely check if it's an instance
    if ray.hitObject and types.Actor.objectIsInstance(ray.hitObject) then return true end
	
	-- If not an actor, check the position criteria
    local delta = ray.hitPos - self.position
    return delta.z < 160 or delta.z < 0.5 * delta:length()
end

local function getTooltipTarget(dt)
    local delta = camera.viewportToWorldVector(cursorPos:ediv(ui.screenSize()))
    local basePos = camera.getPosition() + delta * 50
    local endPos = basePos + delta * 10000

    nearby.asyncCastRenderingRay(async:callback(
        function(result)
            -- Reset tooltipTarget if no hit occurred
            if not result or not result.hit then
                tooltipTarget = nil
                raycastCurrentLength = nil
                return
            end

            if result.hitPos then
                -- Check if target meets validation criteria
                if checkTarget(result) then
                    tooltipTarget = result.hitObject
                    raycastCurrentLength = (result.hitPos - basePos):length()
                else
                    -- Try a physics raycast ignoring the first hit object
                    local physicsResult = nearby.castRay(result.hitPos, endPos, {ignore=result.hitObject})
                    
                    -- Try another rendering raycast from beyond the hit point
                    local newFrom = result.hitPos + delta * 20
                    nearby.asyncCastRenderingRay(async:callback(
                        function(renderResult)
                            if not renderResult or not renderResult.hit then
                                tooltipTarget = nil
                                raycastCurrentLength = nil
                                return
                            end
                            
                            -- Compare physics and rendering results
                            if physicsResult and physicsResult.hitPos and 
                               (not renderResult.hitPos or 
                               (physicsResult.hitPos-basePos):length2() < (renderResult.hitPos-basePos):length2()) then
                                -- Use physics result if it's closer or only hit
                                if checkTarget(physicsResult) then
                                    tooltipTarget = physicsResult.hitObject
                                    raycastCurrentLength = (physicsResult.hitPos - basePos):length()
                                else
                                    tooltipTarget = nil
                                    raycastCurrentLength = nil
                                end
                            elseif renderResult and renderResult.hitPos and checkTarget(renderResult) then
                                -- Use rendering result if it's closer or physics didn't hit
                                tooltipTarget = renderResult.hitObject
                                raycastCurrentLength = (renderResult.hitPos - basePos):length()
                            else
                                tooltipTarget = nil
                                raycastCurrentLength = nil
                            end
                        end
                    ), newFrom, endPos)
                end
            else
                tooltipTarget = nil
                raycastCurrentLength = nil
            end
        end
    ), basePos, endPos)
end

--Adding our actors to our table
local function addNPC(raycastActor)
    -- Check if the NPC is already in the table    
    -- If the NPC is not in the table, add it as a new NPC
    
    local npc = {
        actor = raycastActor,
        timer = tableTimerMaxTime,  -- Initial timer value (in seconds)
        lastHealth = nil,
        damage = 0,  -- Initial damage value
        damageTimer = 0, -- Initial damage timer value
        isTakingDamage = false,
        healthBeforeDamage = nil,
        interpolationWidth = 0,
        healthInterpolationTime = false,
        animTimer = 0,
        currentAnimHealthWidth = nil,
        isDead = actorHealth(raycastActor).current <= 0,
    }

    table.insert(lastNPCTable, npc)
    -- Check if the table exceeds the specified size
    if #lastNPCTable > lastNPCMaxTableSize then
        table.remove(lastNPCTable, 1)  -- Remove the oldest NPC
    end
end


--Rendering name, taking NPC
local function getName(actor)
    if isNPC(actor) then
		npcRecord = types.NPC.record(actor)
	elseif isCreature(actor) then
		npcRecord = types.Creature.record(actor)
	end
    local name = npcRecord.name
    return name
end

local function getClass(actor)
    local class
    class = npcRecord.class
    if isNPC(actor) then
        if string.match(class, "^t_glb_") then
        -- String starts with "t_glb", clean the class
        class = string.gsub(class, "^t_glb_", "")
        end
    elseif isCreature(actor) then
        if types.Creature.record(actor).type == 0 then
            class = "Creature"
        elseif types.Creature.record(actor).type == 1 then
            class = "Daedra"
        elseif types.Creature.record(actor).type == 2 then
            class = "Undead"
        elseif types.Creature.record(actor).type == 3 then
            class = "Humanoid"
        end
    end
  class = string.gsub(" "..class, "%W%l", string.upper):sub(2)
  return class
end

local function getLevel(actor)
    local level = "Lv. " .. types.Actor.stats.level(actor).current
    return level
end


local function getPortraitPath(actor)
if isNPC(actor) then
  local npcRecord = types.NPC.record(actor)
  local name = npcRecord.name
  local class = npcRecord.class
  local race = npcRecord.race
  local sex
  local head = types.NPC.record(actor).head
  local hair = types.NPC.record(actor).hair
  
  
  if npcRecord.isMale == true then
    sex = 'm'
  else
    sex = 'f'
  end
 
  local vampirism = types.Actor.activeEffects(actor):getEffect(core.magic.EFFECT_TYPE.Vampirism)
  
  if vampirism.magnitude ~= 0 then
      -- set vampire portrait
      head = 'b_v_' .. race .. '_' .. sex .. '_head_01'
  else
      -- no vampirism
  end
  
  if class == "guard" then
    local startPos, endPos = string.find(guards, name)
    if startPos then
        return 'special/' .. string.sub(guards, startPos, endPos) .. '/'
    end
  end
    
  if string.find(npcRecord.id, "db_assassin") then
    return 'special/' .. 'db_assassin' .. '/'
  end
  return race .. '/' .. sex .. '/' .. head .. '/' .. hair .. '/'

elseif isCreature(actor) then
  local type
  local subtype = types.Creature.record(actor).model
  if types.Creature.record(actor).type == 0 then
    type = "Creature"
  elseif types.Creature.record(actor).type == 1 then
    type = "Daedra"
  elseif types.Creature.record(actor).type == 2 then
    type = "Undead"
  elseif types.Creature.record(actor).type == 3 then
    type = "Humanoid"
  end
  
  subtype = string.sub(subtype, 10, -5)
  --ui.showMessage(subtype)
  
  return type .. '/' .. subtype .. '/'
end
end


local function populateEnemyBar()
    local enemyCount = math.min(table.maxn(actorsInCombat), 9)  -- Limit to maximum of 9 enemies
    local displayedEnemies = 0
    
    -- First hide all enemy bar elements
    for i = 1, 9 do
        enemyBar.layout.content["ebFrame" .. (i)].props.visible = false
        enemyBar.layout.content["ebDamage" .. (i)].props.visible = false
        enemyBar.layout.content["ebPortrait" .. (i)].props.visible = false
        enemyBar.layout.content["ebBG" .. (i)].props.visible = false
    end

    -- Then populate only with non-focused enemies
    local displayIndex = 1
    for i = 1, enemyCount do
        local enemy = actorsInCombat[i]
        -- Skip if this enemy is dead
        if actorHealth(enemy).current > 0 then
            local ratio = actorHealth(enemy).current / actorHealth(enemy).base
            
            -- Store which slot this enemy is in for focus tracking
            if enemy == tooltipTarget then
                currentFocusSlot = displayIndex
            end
            
            -- Only show enemy in slot if it's not the current focus and we haven't exceeded max slots
            if enemy ~= currentActorInFocus and displayIndex <= 9 then
                enemyBar.layout.content["ebBG" .. (displayIndex)].props.visible = true
                enemyBar.layout.content["ebPortrait" .. (displayIndex)].props.visible = true
                enemyBar.layout.content["ebPortrait" .. (displayIndex)].props.resource = ui.texture({path = 'Textures/portraits/' .. getPortraitPath(enemy) .. 'portrait.png' })
                enemyBar.layout.content["ebDamage" .. (displayIndex)].props.color = util.color.rgb(220 / 255, 65 / 255, 80 / 255)
                enemyBar.layout.content["ebDamage" .. (displayIndex)].props.visible = true
                enemyBar.layout.content["ebDamage" .. (displayIndex)].props.relativePosition = util.vector2(enemyBar.layout.content["ebDamage" .. (displayIndex)].props.relativePosition.x, ratio)
                enemyBar.layout.content["ebFrame" .. (displayIndex)].props.visible = true
            end
            
            displayIndex = displayIndex + 1
            if displayIndex > 9 then
                break  -- Stop processing if we've reached the maximum number of slots
            end
        end
    end
end


--Getting health Values
local function getHealthBar(actor)
	local healthCurrent = actorHealth(actor).current
    local healthBase = actorHealth(actor).base
    if healthCurrent <= 0 then
        healthTextElement.layout.props.text = "Dead"
        actorBarFocus.layout.content["abDamage"].props.color = util.color.rgb(100 / 255, 100 / 255, 100 / 255)
        actorBarFocus.layout.content["abDamage"].props.relativePosition = util.vector2(0,0)
		healthBarSize = scaleSize(0, 1)
		return healthBarSize
		--healthTextElement.props.text = "Health: " .. util.round(actorHealth(tooltipTarget).current) .. " / " .. actorHealth(tooltipTarget).base
	else
		--healthTextElement.props.text = "Dead"
		local ratio = healthCurrent / healthBase
        healthBarSize = barSize:emul(util.vector2(ratio, 1))
        actorBarFocus.layout.content["abDamage"].props.relativePosition = util.vector2(0, ratio)
        return healthBarSize
	end
end


--Getting health text values
local function getHealthText(actor)
	local healthCurrent = util.round(actorHealth(actor).current)
	local healthBase = actorHealth(actor).base
    if healthCurrent <= 0 then
        local healthText = "Dead"
        return healthText
    else
        -- Convert health values to strings
        local strHealthCurrent = tostring(healthCurrent)
        local strHealthBase = tostring(healthBase)

        -- Calculate the number of digits in each value
        local numDigitsCurrent = string.len(strHealthCurrent)
        local numDigitsBase = string.len(strHealthBase)

        -- If the number of digits in healthBase is greater, add spaces to healthCurrent
        if numDigitsBase > numDigitsCurrent then
            local numSpacesToAdd = numDigitsBase - numDigitsCurrent
            local spaces = string.rep(" ", numSpacesToAdd)
            healthCurrent = spaces .. strHealthCurrent
        end

        -- Create the healthText with the adjusted healthCurrent
        local healthText = healthCurrent .. "/" .. strHealthBase
        return healthText
    end	
end

local function getAnimHealthBar(npc, healthBar)
    local animHealthBarWidth
    
    if npc.isTakingDamage then
        animHealthBarWidth = npc.interpolationWidth
    else
        animHealthBarWidth = healthBar
    end
    return animHealthBarWidth
end

--Function to renew widgets time and resetting the fadeout if in process
local function renewWidget(time)
    widgetIsShowing = true
    isFadeOut = false
    fadeOutTimer = 0
    timeToShow = time
end

-- Add these variables at the top with other local variables
local basePosition = 0.4825  -- Center position ratio
local increment = 0.06355    -- Space between portraits ratio
local screenAspectRatio = 16/9 -- Default aspect ratio (for 1920x1080)


-- This will be recalculated when screen size changes
local enemySlotPositions = {
    util.vector2(basePosition, 0),                    -- Slot 1 (base position)
    util.vector2(basePosition + increment + 0.001, 0),        -- Slot 2 (+increment)
    util.vector2(basePosition - increment, 0),        -- Slot 3 (-increment)
    util.vector2(basePosition + increment*2 + 0.002, 0),      -- Slot 4 (+increment*2)
    util.vector2(basePosition - increment*2, 0),      -- Slot 5 (-increment*2)
    util.vector2(basePosition + increment*3 + 0.002, 0),      -- Slot 6 (+increment*3)
    util.vector2(basePosition - increment*3, 0),      -- Slot 7 (-increment*3)
    util.vector2(basePosition + increment*4 + 0.002, 0),      -- Slot 8 (+increment*4)
    util.vector2(basePosition - increment*4, 0),      -- Slot 9 (-increment*9)
}
local currentFocusSlot = 1

local lastScreenWidth = 0
local lastScreenHeight = 0

-- Function to recalculate position ratios based on current screen aspect ratio
local function updateEnemySlotPositions()
    local currentScreenSize = ui.screenSize()
    
    -- Only update if screen size has changed
    if currentScreenSize.x ~= lastScreenWidth or currentScreenSize.y ~= lastScreenHeight then
        -- Calculate actual aspect ratio
        local currentAspectRatio = currentScreenSize.x / currentScreenSize.y
        
        -- Scale factor to adjust position based on aspect ratio difference
        local scaleRatio = currentAspectRatio / screenAspectRatio
        
        -- If screen is wider than standard, we need to adjust the spacing to match
        local adjustedIncrement = increment
        if scaleRatio ~= 1 then
            adjustedIncrement = increment / scaleRatio
        end
        
        -- Recalculate all slot positions
        enemySlotPositions = {
            util.vector2(basePosition, 0),                                 -- Slot 1 (center)
            util.vector2(basePosition + adjustedIncrement + 0.001, 0),     -- Slot 2
            util.vector2(basePosition - adjustedIncrement, 0),             -- Slot 3
            util.vector2(basePosition + (adjustedIncrement*2) + 0.002, 0), -- Slot 4
            util.vector2(basePosition - (adjustedIncrement*2), 0),         -- Slot 5
            util.vector2(basePosition + (adjustedIncrement*3) + 0.002, 0), -- Slot 6
            util.vector2(basePosition - (adjustedIncrement*3), 0),         -- Slot 7
            util.vector2(basePosition + (adjustedIncrement*4) + 0.002, 0), -- Slot 8
            util.vector2(basePosition - (adjustedIncrement*4), 0),         -- Slot 9
        }
        
        -- Remember current screen size for next comparison
        lastScreenWidth = currentScreenSize.x
        lastScreenHeight = currentScreenSize.y
    end
end

-- Add this function to update health bar display
local function updateHealthBarDisplay(actor)
    if not actor then return end
    
    local healthCurrent = actorHealth(actor).current
    local healthBase = actorHealth(actor).base
    
    -- Update health text
    healthText = getHealthText(actor)
    healthTextElement.layout.props.text = healthText
    
    -- Calculate health bar size
    if healthCurrent <= 0 then
        healthBarFull.layout.content[1].layout.content["hbBar"].props.size = scaleSize(0, 15.3)
    else
        local ratio = healthCurrent / healthBase
        local barWidth = 423.5 * ratio * uiScale
        healthBarFull.layout.content[1].layout.content["hbBar"].props.size = util.vector2(barWidth, 26.775 * uiScale)
    end
    
    healthBarFull.layout.content[1]:update()
    healthTextElement:update()
end

-- Modify the showWidgets function to use our new updateHealthBarDisplay function
local function showWidgets(npc)
    if npc.actor then
        local name = getName(npc.actor)
        local class = getClass(npc.actor)
        local level = getLevel(npc.actor)
        local healthBar = getHealthBar(npc.actor)

        -- Update health display
        updateHealthBarDisplay(npc.actor)

        nameElement.layout.props.text = name
        classElement.layout.props.text = class
        levelElement.layout.props.text = tostring(level)
        
        -- Calculate approximate width of nameElement text and adjust levelElement position
        local nameWidth = string.len(name) * nameElement.layout.props.textSize * 0.65 * uiScale
        local levelOffset = (nameWidth / screenSize.x) * 0.4 + 0.01  -- Convert to screen ratio
        levelElement.layout.props.relativePosition = util.vector2(0.5 + levelOffset, 0.145)
        levelElement:update()
        
        -- Only show portraits if actor is in combat
        local isInCombat = false
        for i, combatActor in ipairs(actorsInCombat) do
            if combatActor == npc.actor then
                isInCombat = true
                -- Update currentFocusSlot based on actor's position in combat list
                if npc.actor == currentActorInFocus then
                    currentFocusSlot = i
                end
                break
            end
        end

        if isInCombat and npc.actor == currentActorInFocus then
            -- Get the position from the corresponding enemy slot
            local slotPosition = enemySlotPositions[currentFocusSlot]
            local healthRatio = actorHealth(npc.actor).current / actorHealth(npc.actor).base
            
            -- Show focus bar elements at the correct slot position
            actorBarFocus.layout.content["abBG"].props.relativePosition = slotPosition
            actorBarFocus.layout.content["abPortrait"].props.relativePosition = slotPosition
            actorBarFocus.layout.content["abDamage"].props.relativePosition = util.vector2(slotPosition.x, healthRatio)
            actorBarFocus.layout.content["abFocus"].props.relativePosition = slotPosition
            
            -- Apply the same damage color as enemy bars
            actorBarFocus.layout.content["abDamage"].props.color = util.color.rgb(220 / 255, 65 / 255, 80 / 255)
            
            actorBarFocus.layout.content["abPortrait"].props.visible = true
            actorBarFocus.layout.content["abBG"].props.visible = true
            actorBarFocus.layout.content["abDamage"].props.visible = true
            actorBarFocus.layout.content["abFocus"].props.visible = true
            actorBarFocus.layout.content["abPortrait"].props.resource = ui.texture({path = 'Textures/portraits/' .. getPortraitPath(npc.actor) .. 'portrait.png' })
        else
            -- Hide all focus bar elements
            actorBarFocus.layout.content["abPortrait"].props.visible = false
            actorBarFocus.layout.content["abBG"].props.visible = false
            actorBarFocus.layout.content["abDamage"].props.visible = false
            actorBarFocus.layout.content["abFocus"].props.visible = false
        end

        -- Only hide enemy bar if there are no combat actors at all
        if #actorsInCombat == 0 then
            for i = 1, 9 do
                enemyBar.layout.content["ebFrame" .. (i)].props.visible = false
                enemyBar.layout.content["ebBG" .. (i)].props.visible = false
            end
        else
            populateEnemyBar()
        end
        
        enableVisibility()
        setOpacityFull()
        ui.updateAll()
    end
end


local function rayCastChecker()
    -- Only start fade out if widget is showing AND there are no actors in combat
    if widgetIsShowing and #actorsInCombat == 0 then
        timeToShow = 0
        isShowTime = false
        isFadeOut = true
    end

    -- Only continue if we have a valid target
    if tooltipTarget and (isNPC(tooltipTarget) or isCreature(tooltipTarget)) and tooltipTarget.recordId ~= 'player' then
        -- Check if the target is in combat
        local isInCombat = false
        for _, combatActor in ipairs(actorsInCombat) do
            if combatActor == tooltipTarget then
                isInCombat = true
                break
            end
        end

        local isTargetInTable = false
        for _, npc in ipairs(lastNPCTable) do
            if npc.actor == tooltipTarget then
                isTargetInTable = true
                break
            end
        end

        if not isTargetInTable then
            addNPC(tooltipTarget)
        end

        if raycastCurrentLength < targetMaxDistance then
            for _, npc in ipairs(lastNPCTable) do
                if npc.actor == tooltipTarget then
                    -- Update focus status separately from basic info display
                    if isInCombat and not types.Actor.isDead(tooltipTarget) then
                        currentActorInFocus = npc.actor
                    else
                        currentActorInFocus = nil
                    end

                    -- Always show basic info for valid targets regardless of stance
                    showWidgets(npc)  -- This will now run regardless of stance
                    renewWidget(focusTime)
                    overridingTimer = focusTime
                    isOverridingTime = true
                    
                    break
                end
            end
        end
    end
end

--if timer is zero or less, return true
local function hasShowingTimeEnded(dt)
    if timeToShow > 0 then
        timeToShow = timeToShow - dt
    end
    return timeToShow <= 0
end

--if timer 
local function widgetHideHandler()
    -- Only initiate fade out if not in combat and show time has ended
    if not isShowTime and widgetIsShowing and #actorsInCombat == 0 then
        isFadeOut = true
    end
end

local function calculateStartingAnimWidth(npc)
    
    local baseHealth = actorHealth(npc.actor).base
    local ratio = npc.healthBeforeDamage / baseHealth
    local healthBarSize = barSize:emul(util.vector2(ratio, 1))
    npc.interpolationWidth = barSize:emul(util.vector2(ratio, 1))
    npc.currentAnimHealthWidth = npc.interpolationWidth

end

local function updateDamageInfo(npc, actor, health)
    if health < npc.lastHealth then
        local damageAmount = npc.lastHealth - health
        for _, npc in ipairs(lastNPCTable) do
            if npc.actor == actor then
                npc.damageTimer = 0.15
                npc.isTakingDamage = true
                npc.damage = npc.damage + damageAmount
                if npc.healthBeforeDamage == nil then
                    npc.healthBeforeDamage = npc.lastHealth
                    calculateStartingAnimWidth(npc)
                end
                break
            end
        end
    end
    
    if overridingTimer <= 0 or actor == currentActorInFocus then
        showWidgets(npc)
        renewWidget(combatTime)
    end
end

local function updateActorInFocus(npc, actor, health)
    if overridingTimer <= 0 then
        currentActorInFocus = actor 
    end
end


local function updateIndividualHealth(npc)
    local actor = npc.actor
    if not (isNPC(actor) or isCreature(actor)) then
        return
    end
    local health = actorHealth(actor).current

    if npc.lastHealth and npc.lastHealth ~= health then
        local currentRecord

        if isNPC(actor) then
            currentRecord = types.NPC.record(actor)
        elseif isCreature(actor) then
            currentRecord = types.Creature.record(actor)
        end

        if health ~= npc.lastHealth then
            updateActorInFocus(npc, actor, health)
            updateDamageInfo(npc, actor, health)
        end
    end

    

    npc.lastHealth = health
end


local function updateHealth(dt)
    if #lastNPCTable == 0 then
        return
    end

    cachedActorTickTimer = cachedActorTickTimer + dt

    if cachedActorTickTimer < cachedActorTickTime then
        return
    end

    cachedActorTickTimer = 0
    for _, npc in ipairs(lastNPCTable) do
        updateIndividualHealth(npc)
    end
end

local function updateDamageTimers(commonTimer)
    if #lastNPCTable > 0 then
        for _, npc in ipairs(lastNPCTable) do
            if npc.isTakingDamage then
                npc.damageTimer = npc.damageTimer - commonTimer
                if npc.damageTimer <= 0 then
                    npc.damage = 0 -- Reset damage when the timer expires
                    npc.isTakingDamage = false -- Reset the flag
                    npc.healthInterpolationTime = true
                end
            end
        end
    end
end

local function updateWhileSwimming(dt)
    if not types.Actor.isSwimming(self) and not needToUpdateWhileSwimming then
		
		

		timerToUpdateAfterWater = timerToUpdateAfterWater + dt
			
		if timerToUpdateAfterWater > timeToUpdateAfterWater then
			if types.Actor.isSwimming(self) then
				return
			else
				if not defaultPos then
                    updateDefaultPos()
                end
				updateAllElements()
				needToUpdateWhileSwimming = true
				timerToUpdateAfterWater = 0
			end
		end
		
	end

	if types.Actor.isSwimming(self) and needToUpdateWhileSwimming then
		needToUpdateWhileSwimming = false
        if not defaultPos then
            updateDefaultPos()
        end
		updateAllElements()
	end
end


local function getRaycastTarget()
    if tooltipTarget then
        return tooltipTarget
    end
end


local function getDistance()
    if raycastCurrentLength and raycastCurrentLength > 0 then
        return raycastCurrentLength
    end
end 

local function scanForCombat()
    local scannedActors = nearby.actors
    local hash = {}
    local res = {}
    player = scannedActors[1]
    
    
    for _, actor in ipairs(scannedActors) do
         if (player.position - scannedActors[_].position):length() <= 3600 and types.Actor.getStance(actor) ~= 0 and types.Actor.isDead(actor) == false and actor.recordId ~= 'player' and (not hash[actor]) then
              res[#res+1] = actor
              hash[actor] = true
              -- Limit to 9 enemies
              if #res >= 9 then
                  break
              end
         end
    end
    
    actorsInCombat = res
    
end

local function hideGUI()
    nameElement.layout.props.visible = false
    classElement.layout.props.visible = false
    levelElement.layout.props.visible = false
    healthTextElement.layout.props.visible = false
    healthBarFull.layout.props.visible = false
    actorBarFocus.layout.props.visible = false
    enemyBar.layout.props.visible = false
end

local function showGUI()
    nameElement.layout.props.visible = true
    classElement.layout.props.visible = true
    levelElement.layout.props.visible = true
    healthTextElement.layout.props.visible = true
    healthBarFull.layout.props.visible = true
    actorBarFocus.layout.props.visible = true
    enemyBar.layout.props.visible = true
end

-- Function to update UI sizes when screen resolution changes
local function updateUISizes()
    -- Update screen dimensions
    screenSize = ui.screenSize()
    currentAspectRatio = screenSize.x / screenSize.y
    
    -- Recalculate scale factors
    scaleX = screenSize.x / refWidth
    scaleY = screenSize.y / refHeight
    uiScale = math.min(scaleX, scaleY)
    
    -- Update main container sizes
    actorBarFocus.layout.props.size = scaleSize(657, 66.96)
    enemyBar.layout.props.size = scaleSize(1200, 66.96)
    
    -- Update health bar size and related elements
    healthBarFull.layout.props.size = scaleSize(405, 100)
    barSize = scaleSize(525, 28) -- Make sure barSize is updated with resolution changes
    
    -- If we have a current actor focused, update the health bar display
    if currentActorInFocus then
        updateHealthBarDisplay(currentActorInFocus)
    end
    
    -- Update text sizes
    nameElement.layout.props.textSize = math.max(12, math.floor(36 * uiScale))
    classElement.layout.props.textSize = math.max(10, math.floor(19 * uiScale))
    levelElement.layout.props.textSize = math.max(8, math.floor(12 * uiScale))
    healthTextElement.layout.props.textSize = math.max(12, math.floor(24 * uiScale))
    
    -- Apply changes
    updateAllElements()
end
local function onFrame(dt)

	-- Check if screen size has changed
	local currentScreen = ui.screenSize()
	if screenSize.x ~= currentScreen.x or screenSize.y ~= currentScreen.y then
		ui.updateAll()
		updateUISizes()
	end
        
	
	-- // Code below from OpenNevermind v0.13.37.2 by Petr Mikheev
    if core.isWorldPaused() or (I.UI and I.UI.getMode()) or camera.getMode() == MODE.FirstPerson then
        return
    end
	cursorPos = cursorPos + util.vector2(input.getMouseMoveX(), input.getMouseMoveY())
    local controllerCoef = math.min(screenSize.x, screenSize.y) * (dt * 1.5)
    cursorPos = cursorPos + util.vector2(
        input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight),
        input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward)) * controllerCoef
    cursorPos = util.vector2(util.clamp(cursorPos.x, 0, screenSize.x), util.clamp(cursorPos.y, 0, screenSize.y))
	-- //
end


local function onUpdate(dt)
	if camera.getMode() == MODE.FirstPerson then
		-- Hide custom UI
        I.MMUI_ACTIONBAR.hideAllUI()
        hideGUI()
		
		-- Show default HUD
		I.UI.setHudVisibility(true)
		
		-- Update all UI elements to apply changes
		updateAllElements()
	else
        I.MMUI_ACTIONBAR.showAllUI()
        showGUI()
		-- Get current UI mode
		local currentMode = I.UI.getMode()
		
		-- Check if we're in a mode that requires the default UI
		if currentMode and (
			currentMode == "Interface" or
			currentMode == "Inventory" or
			currentMode == "Container" or
			currentMode == "Barter" or
			currentMode == "Dialogue" or
			currentMode == "Magic" or
			currentMode == "Stats" or
			currentMode == "Map" or
			currentMode == "Journal" or
			currentMode == "Alchemy" or
			currentMode == "SpellCreation" or
			currentMode == "Enchanting" or
			currentMode == "Recharge" or
			currentMode == "Travel" or
			currentMode == "SpellBuying" or
			currentMode == "Training" or
			currentMode == "Repair" or
			currentMode == "MerchantRepair" or
			currentMode == "Companion" or
			currentMode == "Rest"
		) then
			-- Enable default UI for these modes
			I.UI.setHudVisibility(true)
		else
			-- Otherwise, hide default UI and show our custom UI
			I.UI.setHudVisibility(false)
		end
		-- Update slot positions based on current screen size
		updateEnemySlotPositions()
		
		--Firing a raycast and returning distance and actor
		getTooltipTarget()
		--Handling Raycast, adding NPCs to the table, showind a 
		rayCastChecker()
		--functions that should fire once per 0.1 seconds for perfomance
		commonTimer = commonTimer + dt
		if commonTimer >= commonCheckTime then
			if overridingTimer > 0 then
				overridingTimer = overridingTimer - commonTimer
			end
			if overridingTimer <= 0 and isOverridingTime == true then
				
				--currentActorInFocus = nil
				isOverridingTime = false
			end
			scanForCombat()

			
			isShowTime = not hasShowingTimeEnded(commonTimer)
			updateDamageTimers(commonTimer)
			widgetHideHandler()
			commonTimer = 0
			
			

		end

		if isFadeOut then
			fadeOutElements(dt)
		end

		updateHealth(dt)
		

		for _, npc in ipairs(lastNPCTable) do
			if npc.healthInterpolationTime then
				--healthAnimation(dt)
			end
		end

		updateWhileSwimming(dt)
	end
end

return {
    engineHandlers =
    {
        onUpdate = onUpdate,
		onFrame = onFrame,
        onSave = function()
            return { cursorPos = cursorPos, screenSize = screenSize }
        end,
        onLoad = function(data)
            if data and data.cursorPos then
                cursorPos = data.cursorPos
            end
			if data and data.screenSize then
				screenSize = data.screenSize
			end
        end,
    },
    interfaceName = "MM_WIDGET",
    interface = {
		getPortraitPath = getPortraitPath,
		getClass = getClass,
    },
}