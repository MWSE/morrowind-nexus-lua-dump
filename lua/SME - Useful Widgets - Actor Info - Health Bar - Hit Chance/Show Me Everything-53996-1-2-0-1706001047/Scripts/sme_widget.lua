local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require('openmw.storage')

local settings = {
    behavior = storage.playerSection('SMESettingsBh'),
    style = storage.playerSection('SMESettingsSt'),
}


local raycastCloseLength = 500
local raycastCurrentLength

local fadeOutTimer = 0
local fadeOutTime = 1
local isFadeOut = false
local timeToShow = 0
local focusTime = 1
local combatTime = 3
local widgetIsShowing = false

local barSize = util.vector2(252, 12)

local actorInFocus
local lastActorInFocus
local lastNPC
local npcRecord

local interpolationTime = 0.5
local interpolationTimer = 0

local isNPC = types.NPC.objectIsInstance
local isCreature = types.Creature.objectIsInstance

local needToUpdateWhileSwimming = true
local timeToUpdateAfterWater = 3
local timerToUpdateAfterWater = 0

local cachedActorTickTime = 0.1
local cachedActorTickTimer = 0

local lastNPCTable = {}
local lastNPCMaxTableSize = 7
local tableTimerMaxTime = 60

local damageTimer = 0
local damageTime = 0
local damageAmount = 0


local healthAnimTime = 0.7
local healthAnimTimeBase = 0.8

local damageHasEnded = true

local healthBeforeDamage = 0

local actorLevel
local healthText

local commonTimer = 0
local commonCheckTime = 0.1
local isShowTime = false

local finalHealthForInterpolation = 0
local overridingTimer = 0
local isOverridingTime = false

local healthBarSize = util.vector2(252, 12)
local animHealthBarSize = util.vector2(252,12)

local currentActorInFocus = nil

local timerToUpdateAfterWater = 0
local standartWidgetPos
local standartNameElementPos
local standartHealthTextElementPos
local standartDamageElementPos
local needToUpdateWhileSwimming = true
local timeToUpdateAfterWater = 3

local healthBarElement = ui.create {
    name = 'healthBarContent',
    props = {
        visible = true,
        relativeSize = util.vector2(1, 1),
        relativePosition = util.vector2(0.5, 0.5),
      },
    content = I.SME_STYLE.getStyleVanilla(),
}

local damageElement = ui.create {
	type = ui.TYPE.Text,
	props = {
	  relativePosition = util.vector2(0, 0),
	  anchor = util.vector2(0.5, 0.5),
	  text = '',
	  textSize = 14,
	  textShadow = true,
	  textShadowColor =	util.color.rgb(0, 0, 0),
	  textColor = util.color.rgb(200 / 255, 200 / 255, 200 / 255),
	  visible = false,
	},
  }

  local nameElement = ui.create {
	-- important not to forget the layer
	-- by default widgets are not attached to any layer and are not visible
	type = ui.TYPE.Text,
	props = {
	  -- position in the top right corner
	  relativePosition = util.vector2(0.5, 0.08),
	  -- position is for the top left corner of the widget by default
	  -- change it to align exactly to the top right corner of the screen
	  anchor = util.vector2(0.5, 0),
	  text = '',
	  textSize = 19,
	  textShadow = true,
	  textShadowColor =	util.color.rgb(0, 0, 0),
	  -- default black text color isn't always visible
	  textColor = util.color.rgb(200 / 255, 200 / 255, 200 / 255),
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
	  anchor = util.vector2(0.5, 0),
	  text = '',
	  textSize = 14,
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
	layer = 'HUD',
	-- This is a helper template, which sets up this interface element in the style of Morrowind.
	-- Reference: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/interface_mwui.html
	--template = I.MWUI.templates.boxTransparent,
	type = ui.TYPE.Widget,
    props = {
		anchor = util.vector2(0.5, 0),
		relativePosition = util.vector2(0.5, 0.035),
		visible = true,
		size = util.vector2(256, 24),
        --template = I.MWUI.templates.boxTransparent,
		-- Menu positioning props:
		-- Reference: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/widgets/widget.html

		-- Pin the bottom center (50% X 100% Y) of this container to ...
		----anchor = util.vector2(0.5, 1),
		
		-- the screen horizontal center and near the bottom of the screen (50% X 95% Y).
        ----relativePosition = util.vector2(0.5, 0.95),
	},
	-- Use ui.content for every content field.
	content = ui.content 
    {
        healthBarElement,
        damageElement,
        nameElement,
        healthTextElement,
    },
}




--UI UPDATE FUNCTIONS
local function disableHealthValues()
    local disabled = not settings.behavior:get('SMEHealth')
    healthTextElement.layout.props.text = ''
    local healthBarContent = healthBarElement.layout.content
    if healthBarContent == I.SME_STYLE.getStyleFlat() and not settings.behavior:get('SMEHealth') then
        healthBarContent["healthBG"].props.visible = false
    elseif healthBarContent == I.SME_STYLE.getStyleFlat() then
        healthBarContent["healthBG"].props.visible = true
    end
end

local function updateFlatHealthBG()
    local healthBarContent = healthBarElement.layout.content
    if healthBarContent == I.SME_STYLE.getStyleFlat() and not settings.behavior:get('SMEHealth') then
        healthBarContent["healthBG"].props.visible = false
    elseif healthBarContent == I.SME_STYLE.getStyleFlat() then
        healthBarContent["healthBG"].props.visible = true
    end
end

local function updateStandartPositions()
    standartWidgetPos = healthBarFull.layout.props.relativePosition
end

local function updateWidgetStyle()
    if settings.style:get('SMEWidgetStyle') == 'Vanilla' then
        healthBarElement.layout.content = I.SME_STYLE.getStyleVanilla()
        healthBarFull.layout.props.size = util.vector2(450, 70)
        healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0.29)
        barSize = util.vector2(260, 16)
        damageElement.layout.props.relativePosition = util.vector2(0.735, 0.83)
        healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.429)
        nameElement.layout.props.textSize = 17.5
        nameElement.layout.props.relativePosition = util.vector2(0.5, 0.047)
    elseif settings.style:get('SMEWidgetStyle') == 'Skyrim' then
        healthBarElement.layout.content = I.SME_STYLE.getStyleSkyrim()
        healthBarFull.layout.props.size = util.vector2(450, 60)
        healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0.29)
        barSize = util.vector2(252, 12)
        damageElement.layout.props.relativePosition = util.vector2(0.735, 0.87)
        healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.432)
        nameElement.layout.props.textSize = 18
        nameElement.layout.props.relativePosition = util.vector2(0.5, 0.03)
    elseif settings.style:get('SMEWidgetStyle') == 'Sky Nostalgy' then
        healthBarElement.layout.content = I.SME_STYLE.getStyleNostalgy()
        barSize = util.vector2(307, 10)
        healthBarFull.layout.props.size = util.vector2(450, 60)
        healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.43)
        healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0.29)
        nameElement.layout.props.textSize = 17
        nameElement.layout.props.relativePosition = util.vector2(0.5, 0.052)
        damageElement.layout.props.relativePosition = util.vector2(0.76, 0.87)
    elseif settings.style:get('SMEWidgetStyle') == 'Flat' then
        healthBarElement.layout.content = I.SME_STYLE.getStyleFlat()
        barSize = util.vector2(300, 16)
        healthBarFull.layout.props.size = util.vector2(450, 65)
        healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.735)
        healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0.15)
        nameElement.layout.props.textSize = 18
        nameElement.layout.props.relativePosition = util.vector2(0.5, 0)
        damageElement.layout.props.relativePosition = util.vector2(0.9, 0.548)
    elseif settings.style:get('SMEWidgetStyle') == 'Minimal Vanilla' then
        healthBarElement.layout.content = I.SME_STYLE.getStyleMinimal()
        barSize = util.vector2(180, 30)
        healthBarFull.layout.props.size = util.vector2(250, 40)
        healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0.14)
        healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.65)
        nameElement.layout.props.textSize = 16
        nameElement.layout.props.relativePosition = util.vector2(0.5, 0.067)
        damageElement.layout.props.relativePosition = util.vector2(0.94, 0.83)
    elseif settings.style:get('SMEWidgetStyle') == 'Sixth House' then
        healthBarElement.layout.content = I.SME_STYLE.getStyleSixthHouse()
        barSize = util.vector2(275, 18)
        healthTextElement.layout.props.relativePosition = util.vector2(0.50, 0.45)
        healthBarFull.layout.props.size = util.vector2(400, 70)
        healthBarFull.layout.content[1].layout.props.relativePosition = util.vector2(0, 0)
        nameElement.layout.props.textSize = 16
        nameElement.layout.props.relativePosition = util.vector2(0.5, 0.077)
        damageElement.layout.props.relativePosition = util.vector2(0.78, 0.85)
    end
    updateStandartPositions()
end

local function updateStance()
    if settings.behavior:get('SMEStance') and types.Actor.getStance(self) == types.Actor.STANCE.Nothing then
        nameElement.layout.props.visible = false
	    healthTextElement.layout.props.visible = false
	    healthBarFull.layout.props.visible = false
        healthTextElement:update()
        healthBarFull:update()
        nameElement:update()
    end
end

disableHealthValues()
updateWidgetStyle()
updateFlatHealthBG()
updateStance()

settings.behavior:subscribe(async:callback(disableHealthValues))
settings.behavior:subscribe(async:callback(updateStance))
settings.style:subscribe(async:callback(updateWidgetStyle))
settings.style:subscribe(async:callback(updateFlatHealthBG))
--UI UPDATE FUNCTIONS


--UI VISIBILITY FUNCTIONS
local function setOpacityFull()
    nameElement.layout.props.alpha = 1.0
    healthTextElement.layout.props.alpha = 1.0
    healthBarFull.layout.props.alpha = 1.0
    healthBarFull.layout.content[1].layout.props.alpha = 1.0
end

local function enableVisibility()
	nameElement.layout.props.visible = true
	healthTextElement.layout.props.visible = true
	healthBarFull.layout.props.visible = true
    healthBarFull.layout.content[1].layout.props.visible = true
end

local function hideElements()
	nameElement.layout.props.visible = false
	healthTextElement.layout.props.visible = false
	healthBarFull.layout.props.visible = false
    healthBarFull.layout.content[1].layout.props.visible = false
end

local function updateAllElements()   
        healthTextElement:update()
        healthBarFull:update()
        nameElement:update()
        healthBarFull.layout.content[1]:update()
end

local function fadeOutElements(dt)
	fadeOutTimer = fadeOutTimer + dt
		
	-- Gradually lower alpha to 0 over fadeOutTime
	local alphaPercentage = 1.0 - fadeOutTimer / fadeOutTime
	nameElement.layout.props.alpha = math.max(0, alphaPercentage)
	healthTextElement.layout.props.alpha = math.max(0, alphaPercentage)
	healthBarFull.layout.props.alpha = math.max(0, alphaPercentage)

	updateAllElements()

	if fadeOutTimer >= fadeOutTime then

		nameElement.layout.props.visible = false
		healthBarFull.layout.props.visible = false
		healthTextElement.layout.props.visible = false

		fadeOutTimer = 0
		updateAllElements()
		setOpacityFull()
		isFadeOut = false
        widgetIsShowing = false
	end
end
--UI VISIBILITY FUNCTIONS


--Casting a raycast and getting our actors
local function getTooltipTarget(dt)

local from = camera.getPosition()
local to = from + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * settings.behavior:get('SMERaycastLength')
nearby.asyncCastRenderingRay(
    async:callback(function(result)
        tooltipTarget = result.hitObject
        if result.hitPos ~= nil then
            raycastCurrentLength = (result.hitPos - from):length()
        end
    end),
    from,
    to
)
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
        isDead = types.Actor.stats.dynamic.health(raycastActor).current <= 0,
    }

    table.insert(lastNPCTable, npc)
    -- Check if the table exceeds the specified size
    if #lastNPCTable > lastNPCMaxTableSize then
        table.remove(lastNPCTable, 1)  -- Remove the oldest NPC
    end
end

--Updating our actors based on time in the table
local function updateCachedNPC(dt)
    for i = #lastNPCTable, 1, -1 do
        local npc = lastNPCTable[i]
        npc.timer = npc.timer - dt

        if npc.timer <= 0 then
            -- Remove the NPC with an expired timer
            table.remove(lastNPCTable, i)
        end
    end
end

--Rendering name, taking NPC
local function getName(actor)
    if isNPC(actor) then
		npcRecord = types.NPC.record(actor)
	elseif isCreature(actor) then
		npcRecord = types.Creature.record(actor)
        actorLevel = types.NPC.stats.level(actor).current
	end

    local name = npcRecord.name
    
    if settings.behavior:get('SMEClass') then
        local class = npcRecord.class
        --local services = npcRecord.servicesOffered
        --for service, isProvided in pairs(npcRecord.servicesOffered) do
            --if isProvided then
                --print("This NPC provides service: " .. service)
            --else
                --print("This NPC does not provide service: " .. service)
            --end
        --end
        --print('Services: ' ,npcRecord.servicesOffered)
        if isNPC(actor) then
            if string.match(class, "^t_glb_") then
                -- String starts with "t_glb", clean the class
                class = string.gsub(class, "^t_glb_", "")
            end
        end
        name = name .. (class and (", " .. class) or "")
    end

    if settings.behavior:get('SMELevel') then
        name = name .. " (" .. types.Actor.stats.level(actor).current .. ")"
    end

    return name

end



--Getting health Values
local function getHealthBar(actor)
	local healthCurrent = types.Actor.stats.dynamic.health(actor).current
    local healthBase = types.Actor.stats.dynamic.health(actor).base
    if healthCurrent <= 0 then
        if settings.behavior:get('SMEHealth') then
		    healthTextElement.layout.props.text = "Dead"
        end
		healthBarSize = util.vector2(0, 1)
		return healthBarSize
		--healthTextElement.props.text = "Health: " .. util.round(types.Actor.stats.dynamic.health(tooltipTarget).current) .. " / " .. types.Actor.stats.dynamic.health(tooltipTarget).base
	else
		--healthTextElement.props.text = "Dead"
		local ratio = healthCurrent / healthBase
        healthBarSize = barSize:emul(util.vector2(ratio, 1))
        return healthBarSize
	end
end


--Getting health text values
local function getHealthText(actor)
	local healthCurrent = util.round(types.Actor.stats.dynamic.health(actor).current)
	local healthBase = types.Actor.stats.dynamic.health(actor).base
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
        local healthText = healthCurrent .. " / " .. strHealthBase
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

--Function to turn on the main widgets
local function showWidgets(npc)

    if currentActorInFocus and npc.actor == currentActorInFocus then
        local name = getName(npc.actor)
        local healthBar = getHealthBar(npc.actor)

        if settings.behavior:get('SMEHealth') then
            healthText = getHealthText(npc.actor)
            healthTextElement.layout.props.text = healthText
        end

        if not npc.healthInterpolationTime then
            local animHealthBar = getAnimHealthBar(npc, healthBar)
            healthBarFull.layout.content[1].layout.content["hbBarAnim"].props.size = animHealthBar
        end
        nameElement.layout.props.text = name
        
        healthBarFull.layout.content[1].layout.content["hbBar"].props.size = healthBar

        enableVisibility()
        setOpacityFull()
        updateAllElements()
    end
end

local function rayCastChecker()

    if tooltipTarget and (isNPC(tooltipTarget) or isCreature(tooltipTarget)) and tooltipTarget.recordId ~= 'player' then

        if not settings.behavior:get('SMEnotForDead') and types.Actor.isDead(tooltipTarget) then
            return
        end

        local isTargetInTable = false
        for _, npc in ipairs(lastNPCTable) do
            if npc.actor == tooltipTarget then
            isTargetInTable = true
            break
            end
        end
        --print('Is target in the table? ',isTargetInTable)
        if not isTargetInTable then
            addNPC(tooltipTarget)
        end
        --print('TooltipTarget: ', tooltipTarget)
        if raycastCurrentLength < settings.behavior:get('SMEShowDistance') then
			--Updating timers and bool that our timer is shown
			for _, npc in ipairs(lastNPCTable) do
                if npc.actor == tooltipTarget then
                    currentActorInFocus = npc.actor
                    if (types.Actor.getStance(self) == types.Actor.STANCE.Nothing and settings.behavior:get('SMEStance')) or settings.behavior:get('SMEonHit') then
                        lastActorInFocus = tooltipTarget
                        overridingTimer = focusTime
                        isOverridingTime = true
                    else
                        showWidgets(npc)
                        lastActorInFocus = tooltipTarget
                        renewWidget(focusTime)
                        overridingTimer = focusTime
                        isOverridingTime = true
                        if not npc.isTakingDamage then
                            damageElement.layout.props.text = ''
                            damageElement.layout.props.visible = false
                            damageElement:update()
                        end
                    end
                    
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
    --print('Time to show timer: ' .. timeToShow)
    return timeToShow <= 0
end

--if timer 
local function widgetHideHandler()
    if not isShowTime and widgetIsShowing then
        isFadeOut = true
    end
end

local function showDamageWidget(damage, actor)
    -- Find the NPC in lastNPCTable
    for _, npc in ipairs(lastNPCTable) do
        if npc.actor == actor then
            if npc.actor == currentActorInFocus and npc.isTakingDamage then
                damageElement.layout.props.text = tostring(util.round(npc.damage))
                damageElement.layout.props.visible = true
                damageElement:update()
            end

            return  -- Exit the function once the update is done
        end
    end
end

local function calculateStartingAnimWidth(npc)
    
    local baseHealth = types.Actor.stats.dynamic.health(npc.actor).base
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
                npc.damageTimer = 1
                npc.isTakingDamage = true
                npc.damage = npc.damage + damageAmount
                if npc.healthBeforeDamage == nil then
                    npc.healthBeforeDamage = npc.lastHealth
                    calculateStartingAnimWidth(npc)
                end
                if settings.behavior:get('SMEDamage') then
                    showDamageWidget(damageAmount, actor)
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
        --print('Актер в фокусе при получении урона обновлен!')
    end
end


local function updateIndividualHealth(npc)
    local actor = npc.actor
    --print('Dead?: ', types.Actor.isDead(actor))
    if not (isNPC(actor) or isCreature(actor)) then
        return
    end
    local health = types.Actor.stats.dynamic.health(actor).current

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
    --print('Пытаемся обновить здоровье')
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
                    
                    if settings.behavior:get('SMEDamage') then
                        damageElement.layout.props.text = ''
                        damageElement.layout.props.visible = false
                        damageElement:update()
                    end

                end
            end
        end
    end
end

local function healthAnimation(dt)
    for _, npc in ipairs(lastNPCTable) do
        if npc.healthInterpolationTime then
            npc.animTimer = npc.animTimer + dt

            local finalHealthForInterpolation = types.Actor.stats.dynamic.health(npc.actor).current
            local maxIntActorHealth = types.Actor.stats.dynamic.health(npc.actor).base
            
            local ratio = finalHealthForInterpolation / maxIntActorHealth
            local amount = npc.healthBeforeDamage - finalHealthForInterpolation
            local lostPercent = (amount / maxIntActorHealth) * 100
            
            local animTime = math.max(healthAnimTimeBase * (lostPercent / 100), 0.2)



            local finalSize = barSize:emul(util.vector2(ratio, 1))
            local sizeDifference = npc.interpolationWidth.x - finalSize.x
            local timeDifference = animTime / dt
            local step = sizeDifference / timeDifference


            npc.currentAnimHealthWidth = util.vector2(npc.currentAnimHealthWidth.x - step, barSize.y)


            if npc.actor == currentActorInFocus then
                healthBarFull.layout.content[1].layout.content["hbBarAnim"].props.size = npc.currentAnimHealthWidth
                updateAllElements()
            end

            if npc.isTakingDamage then
                npc.animTimer = 0
                npc.healthInterpolationTime = false
                npc.interpolationWidth = healthBarFull.layout.content[1].layout.content["hbBarAnim"].props.size
            elseif npc.animTimer >= animTime then
                npc.animTimer = 0
                npc.healthBeforeDamage = nil
                npc.healthInterpolationTime = false -- Сбрасываем флаг
                npc.currentAnimHealthWidth = nil
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
				if not standartWidgetPos then
                    updateStandartPositions()
                end
                healthBarFull.layout.props.relativePosition = standartWidgetPos
				updateAllElements()
				needToUpdateWhileSwimming = true
				timerToUpdateAfterWater = 0
			end
		end
		
	end

	if types.Actor.isSwimming(self) and needToUpdateWhileSwimming then
		needToUpdateWhileSwimming = false
        if not standartWidgetPos then
            updateStandartPositions()
        end
		healthBarFull.layout.props.relativePosition = util.vector2(standartWidgetPos.x, standartWidgetPos.y + 0.07)
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

local function onUpdate(dt)

    if not settings.behavior:get('SMEisActive') then
        return
    end
    --Firing a raycast and returning distance and actor
    getTooltipTarget()
    --Handling Raycast, adding NPCs to the table, showind a 
    rayCastChecker()
    
    --functions that should fire once per 0.1 seconds for perfomance
    commonTimer = commonTimer + dt
    if commonTimer >= commonCheckTime then
        if overridingTimer > 0 then
            --print('OverridingTimer is ticking: ' .. overridingTimer, commontimer)
            overridingTimer = overridingTimer - commonTimer
        end
        if overridingTimer <= 0 and isOverridingTime == true then
            -- Если таймер закончился, сбросим npc.actorInFocus
            --currentActorInFocus = nil
            isOverridingTime = false
        end

        isShowTime = not hasShowingTimeEnded(commonTimer)
        updateDamageTimers(commonTimer)
        widgetHideHandler()
        commonTimer = 0
        
        

    end

    if isFadeOut then
        fadeOutElements(dt)
    end

    updateHealth(dt)
    
    if damageHasEnded ~= true then
        damageWidget(dt)
    end

    for _, npc in ipairs(lastNPCTable) do
        if npc.healthInterpolationTime then
            healthAnimation(dt)
        end
    end

    updateWhileSwimming(dt)

end


return { 
    engineHandlers = 
    { 
        onUpdate = onUpdate 
    },
    interfaceName = "SME_CORE",
    interface = {
        getRaycastTarget = getRaycastTarget,
        getDistance = getDistance,
    },
}