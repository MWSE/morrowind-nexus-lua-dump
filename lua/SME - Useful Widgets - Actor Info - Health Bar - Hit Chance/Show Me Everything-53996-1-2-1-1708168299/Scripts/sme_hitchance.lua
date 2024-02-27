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

local hitChanceLogicTimer = 0
local hitChanceLogicTime = 0.1
local hitChanceUpdateTimer = 0
local hitChanceUpdateTime = 5
local distance = 0
local focusTimer = 0
local focusTime = 0.3
local timeToFadeOut = false
local fadeOutTimer = 0
local fadeOutTime = 1
local widgetIsShowing = false
local lastUpdateTime = 0
local updateInterval = 1
local showingTime = 0

local settings = {
    behavior = storage.playerSection('SMESettingsBh'),
    style = storage.playerSection('SMESettingsSt'),
    hitChance = storage.playerSection('SMEHitChanceSettings'),
}

local weaponSkillMap = {
	[types.Weapon.TYPE.AxeOneHand] = "axe",
	[types.Weapon.TYPE.AxeTwoHand] = "axe",
	[types.Weapon.TYPE.BluntOneHand] = "bluntweapon",
	[types.Weapon.TYPE.BluntTwoClose] = "bluntweapon",
	[types.Weapon.TYPE.BluntTwoWide] = "bluntweapon",
	[types.Weapon.TYPE.LongBladeOneHand] = "longblade",
	[types.Weapon.TYPE.LongBladeTwoHand] = "longblade",
	[types.Weapon.TYPE.MarksmanBow] = "marksman",
	[types.Weapon.TYPE.MarksmanCrossbow] = "marksman",
	[types.Weapon.TYPE.MarksmanThrown] = "marksman",
	[types.Weapon.TYPE.ShortBladeOneHand] = "shortblade",
	[types.Weapon.TYPE.SpearTwoWide] = "spear",
}

local function calcHitChance(weapon)
	local weaponSkill =
		types.NPC.stats.skills[weapon and weaponSkillMap[types.Weapon.record(weapon).type] or "handtohand"](self).modified
	local agility = types.Actor.stats.attributes.agility(self).modified
	local luck = types.Actor.stats.attributes.luck(self).modified
	local fatigueCurrent = types.Actor.stats.dynamic.fatigue(self).current
	local fatigueBase = types.Actor.stats.dynamic.fatigue(self).base
	local fortifyAttack = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyAttack)
	local blind = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Blind)
	return (weaponSkill + (agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ (fortifyAttack and fortifyAttack.magnitude or 0)
		+ (blind and blind.magnitude or 0)
end

local function calcEvasion(target)
	local agility = types.Actor.stats.attributes.agility(target).modified
	local luck = types.Actor.stats.attributes.luck(target).modified
	local fatigueCurrent = types.Actor.stats.dynamic.fatigue(target).current
	local fatigueBase = types.Actor.stats.dynamic.fatigue(target).base
	local sanctuary = types.Actor.activeEffects(target):getEffect(core.magic.EFFECT_TYPE.Sanctuary)
	return ((agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ (sanctuary and sanctuary.magnitude or 0)
end

local hitChanceReticleElement = {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture({ path = 'Textures/targetHitChance.png' }),
		--color = util.color.rgb(65 / 255, 65 / 255, 65 / 255),
		size = util.vector2(38, 38),
		-- position in the top right corner
		relativePosition = util.vector2(0.5, 0.5),
		-- position is for the top left corner of the widget by default
		-- change it to align exactly to the top right corner of the screen
		anchor = util.vector2(0.5, 0.5),
		--visible = false,
	},
}

local hitChanceReticle = ui.create({
	layer = "HUD",
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture({ path = 'Textures/targetHitChance.png' }),
		--color = util.color.rgb(65 / 255, 65 / 255, 65 / 255),
		size = util.vector2(26, 26),
		-- position in the top right corner
		relativePosition = util.vector2(0.5, 0.5),
		-- position is for the top left corner of the widget by default
		-- change it to align exactly to the top right corner of the screen
		anchor = util.vector2(0.5, 0.5),
		visible = false,
	},
})

local hitChanceWidgetPercent = ui.content {
    {
        name = "hitChanceContainer",
        props = {
            -- suspicious, probably this should be aligned within a Flex widget of some kind instead
            relativePosition = util.vector2(0.8, 0.63),
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(50, 20),
        },
        content = ui.content {
            {
                name = "hitChanceBG",
                type = ui.TYPE.Image,
                props = {
                    alpha = 0.8,
                    resource = ui.texture({ path = 'White' }),
                    color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
                    relativeSize = util.vector2(1, 1),
                },
            },
            {

                name = "hitChanceText",
                type = ui.TYPE.Text,
                props = {
                    text = "%",
                    textColor = util.color.rgba(1, 1, 1, 1),
                    textSize = 14,
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                },
            },
        },
    },
}

local hitChanceWidgetCircle = ui.content {
    {
        name = "hitChanceWidget",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/hitIndicator.png' }),
            --color = util.color.rgb(65 / 255, 65 / 255, 65 / 255),
            size = util.vector2(8, 8),
            -- position in the top right corner
            relativePosition = util.vector2(0.6, 0.6),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0.5),
            --visible = false,
        },
    },
}

local hitChanceWidgetScale = ui.content {
    {
        name = "hitChanceWidgetBG",
        type = ui.TYPE.Image,
            props = {
			alpha = 0.8,
            resource = ui.texture({ path = 'White' }),
            color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
            size = util.vector2(10, 45),
            -- position in the top right corner
            relativePosition = util.vector2(0.65, 0.5),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0.5),
            --visible = false,
        },
    },
	{
        name = "hitChanceWidgetScale",
        type = ui.TYPE.Image,
            props = {
			alpha = 0.8,
            resource = ui.texture({ path = 'White' }),
            color = util.color.rgb(244 / 255, 198 / 255, 0 / 255),
            size = util.vector2(6, 40),
            -- position in the top right corner
            relativePosition = util.vector2(0.65, 0.5),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0.5),
            --visible = false,
        },
    },
}

local hitChanceWidget = ui.create {
	name = 'TutorialNotifyMenu',
	l10n = 'UITutorial',
	layer = 'HUD',
	-- This is a helper template, which sets up this interface element in the style of Morrowind.
	-- Reference: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/interface_mwui.html
	--template = I.MWUI.templates.boxTransparent,
	type = ui.TYPE.Widget,
    props = {
		anchor = util.vector2(0.5, 0.5),
		relativePosition = util.vector2(0.5, 0.5),
		visible = false,
		size = util.vector2(150, 150),
        template = I.MWUI.templates.boxTransparent,
		-- Menu positioning props:
		-- Reference: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/widgets/widget.html

		-- Pin the bottom center (50% X 100% Y) of this container to ...
		----anchor = util.vector2(0.5, 1),
		
		-- the screen horizontal center and near the bottom of the screen (50% X 95% Y).
        ----relativePosition = util.vector2(0.5, 0.95),
	},
	-- Use ui.content for every content field.
	content = hitChanceWidgetScale,
}

local function updateWidgetStyle()
	if settings.hitChance:get('SMEhitChanceWidget') == 'Percent' then
        hitChanceWidget.layout.content = hitChanceWidgetPercent
	elseif settings.hitChance:get('SMEhitChanceWidget') == 'Circle' then
		hitChanceWidget.layout.content = hitChanceWidgetCircle
	elseif settings.hitChance:get('SMEhitChanceWidget') == 'Scale' then
		hitChanceWidget.layout.content = hitChanceWidgetScale
	end
end

local function disableHitChance()
	if not settings.hitChance:get('hitChanceIsActive') then
		if settings.hitChance:get('SMEhitChanceReticle') then
			hitChanceReticle.layout.props.visible = false
			hitChanceReticle:update()
		end
	--hitChanceElement:update()
		hitChanceWidget.layout.props.visible = false
		fadeOutTimer = 0
		hitChanceWidget:update()
	end
end

local function disableColoredReticle()
	if not settings.hitChance:get('SMEhitChanceReticle') then
		hitChanceReticle.layout.props.visible = false
		hitChanceReticle:update()
	end
end

updateWidgetStyle()
disableHitChance()
disableColoredReticle()

settings.hitChance:subscribe(async:callback(updateWidgetStyle))
settings.hitChance:subscribe(async:callback(disableHitChance))
settings.hitChance:subscribe(async:callback(disableColoredReticle))

local tooltipTarget
local barSize = util.vector2(6, 40)

local function getTooltipTarget(dt)
    local from = camera.getPosition()
    local to

    if types.Weapon.objectIsInstance(types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)) then
        -- Check if the carried right weapon is of the marksman group
        local weaponType = types.Weapon.record(types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)).type
        local isMarksmanWeapon = weaponSkillMap[weaponType] == "marksman"

        -- Adjust raycast length based on weapon type
        local raycastLength = isMarksmanWeapon and 4000 or 192
        to = from + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * raycastLength
    else
        -- Default raycast length for non-weapon cases
        to = from + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 192
    end

    nearby.asyncCastRenderingRay(
        async:callback(function(result)
            tooltipTarget = result.hitObject
        end),
        from,
        to
    )
end

local function displayWidget(elementColour, hitChance)
	focusTimer = focusTime
	timetoFadeOut = false
	widgetIsShowing = true
	--hitChanceElement.layout.props.alpha = 1.0
	hitChanceWidget.layout.props.alpha = 1.0
	
	if hitChanceWidget.layout.content == hitChanceWidgetPercent then
		hitChanceWidget.layout.content["hitChanceContainer"].content["hitChanceText"].props.textColor = util.color.rgba(table.unpack(elementColour))
	elseif hitChanceWidget.layout.content == hitChanceWidgetCircle then
		hitChanceWidget.layout.content["hitChanceWidget"].props.color = util.color.rgba(table.unpack(elementColour))
	end

	if settings.hitChance:get('SMEhitChanceReticle') then
		hitChanceReticle.layout.props.alpha = 1.0
		hitChanceReticle.layout.props.visible = true
		hitChanceReticle.layout.props.color = util.color.rgba(table.unpack(elementColour))
	end

	if hitChanceWidget.layout.content == hitChanceWidgetScale then
		hitChanceWidget.layout.content["hitChanceWidgetScale"].props.color = util.color.rgba(table.unpack(elementColour))
		local hitChanceRounded = math.min(hitChance, 100)
		local ratio = hitChanceRounded / 100
        hitChanceWidget.layout.content["hitChanceWidgetScale"].props.size = barSize:emul(util.vector2(1, ratio))
	end
	
	--hitChanceElement.layout.props.visible = true
	hitChanceWidget.layout.props.visible = true
	fadeOutTimer = 0
	--hitChanceElement:update()
	hitChanceWidget:update()
	hitChanceReticle:update()
end

local function displayHitChance(dt)
	hitChanceLogicTimer = hitChanceLogicTimer + dt

	if hitChanceLogicTimer >= hitChanceLogicTime then
		if camera.getMode() == camera.MODE.FirstPerson then
            
            if settings.behavior:get('SMEisActive') and settings.hitChance:get('hitChanceIsActive') then
                tooltipTarget = I.SME_CORE.getRaycastTarget()
                distance = I.SME_CORE.getDistance()
            else
			    getTooltipTarget()
            end
		else
			tooltipTarget = nil
		end
		if
			tooltipTarget
			and (types.NPC.objectIsInstance(tooltipTarget) or types.Creature.objectIsInstance(tooltipTarget))
			and types.Actor.getStance(self) == types.Actor.STANCE.Weapon
			and not types.Actor.isDead(tooltipTarget)
		then
			local carriedRight = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
			if carriedRight and types.Weapon.objectIsInstance(carriedRight) or carriedRight == nil then
				local hitChance = math.max(0, calcHitChance(carriedRight) - calcEvasion(tooltipTarget))
				if hitChanceWidget.layout.content == hitChanceWidgetPercent then
					hitChanceWidget.layout.content["hitChanceContainer"].content["hitChanceText"].props.text = string.format("%d%%", util.round(hitChance * 100) / 100)
				end
				local elementColour
				if hitChance <= 25 then
					elementColour = { 193 / 255, 63 / 255, 55 / 255, 1 }
				elseif hitChance <= 50 then
					elementColour = { 255 / 255, 220 / 255, 95 / 255, 1 }
				elseif hitChance <= 75 then
					elementColour = { 1, 1, 1, 1 }
				elseif hitChance <= 100 then
					elementColour = { 180 / 255, 255 / 255, 158 / 255, 1 }
				else
					elementColour = { 184 / 255, 102 / 255, 211 / 255, 1 }
				end
                if settings.behavior:get('SMEisActive') then 
                    local weaponType = types.Weapon.record(types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)).type
                    local isMarksmanWeapon = weaponSkillMap[weaponType] == "marksman"
                    if distance < 193 and not isMarksmanWeapon then
						displayWidget(elementColour, hitChance)
						
					elseif isMarksmanWeapon then
						displayWidget(elementColour, hitChance)
                    end
                else
					displayWidget(elementColour, hitChance)
                end
			end
		end
	end


end




local function hitChanceFadeOut(dt)
	fadeOutTimer = fadeOutTimer + dt
		
	-- Gradually lower alpha to 0 over fadeOutTime
	local alphaPercentage = 1.0 - fadeOutTimer / fadeOutTime

	if settings.hitChance:get('SMEhitChanceReticle') then
		hitChanceReticle.layout.props.alpha = math.max(0, alphaPercentage)
		hitChanceReticle:update()
	end
	hitChanceWidget.layout.props.alpha =  math.max(0, alphaPercentage)

	
	hitChanceWidget:update()
	if fadeOutTimer >= fadeOutTime then

		if settings.hitChance:get('SMEhitChanceReticle') then
			hitChanceReticle.layout.props.visible = false
			hitChanceReticle.layout.props.alpha = 1
			hitChanceReticle:update()
		end
		
		hitChanceWidget.layout.props.visible = false
		
		hitChanceWidget.layout.props.alpha = 1.0
		
		hitChanceWidget:update()
		
		fadeOutTimer = 0

		timetoFadeOut = false
		widgetIsShowing = false
	end
end

local function onUpdate(dt)
    if not settings.hitChance:get('hitChanceIsActive') then return end

	displayHitChance(dt)

	if focusTimer > 0 then
		focusTimer = focusTimer - dt
	end

	if focusTimer <= 0 and widgetIsShowing then
		timetoFadeOut = true
	end

	if timetoFadeOut then
		hitChanceFadeOut(dt)
	end
end

return { engineHandlers = { onUpdate = onUpdate } }