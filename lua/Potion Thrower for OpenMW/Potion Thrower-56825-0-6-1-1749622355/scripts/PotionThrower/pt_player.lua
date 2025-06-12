local core = require('openmw.core')
local ambient = require('openmw.ambient')
local camera = require('openmw.camera')
local ui = require('openmw.ui')
local input = require('openmw.input')
local anim = require('openmw.animation')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')
local async = require('openmw.async')

local modEnabled = true

local armedPotion = nil
local velocity = nil
local previousPosition = nil
local widget = nil
local potionInfoWidget = nil
local promptWidget = nil
local promptInFocus = false
local canDismissPrompt = false
local promptDuringGameplay = false
local throwCharge = -1
local potionMode = 0 -- 0 is not enabled, 1 is throwing, 2 is drinking
local meshPath = nil

-- for holding ToggleWeapon to arm a potion
local armingEnabled = false
local drinkingEnabled = false
local armPotionHoldTime = 0
local armPotionReady = false
local armPotionTriggerSeconds = 0.5
local drinkPotionHoldTime = 0
local drinkPotionTriggerSeconds = 0.5
local drinkPotionReady = false
local potionModeTimePassed = 0
local canEndPotionMode = false
local canEnterThrowMode = false
local canEnterDrinkMode = false
local canUsePotion = true
local potionUseTime = 0
local quickLobKey = 'c'
local quickLobHeld = false

-- animation definitions
local animThrowIdle = "idle2w"
local animThrowWindUp = "idle2c"
local animThrow = "hit3"
local animThrowLeft = "swimknockdown"
local animDrinkIdle = "idlebow"
local animDrink = "idlespell"

local fatigueHit = 20

I.Settings.registerPage {
    key = 'PotionThrower',
    l10n = 'PotionThrower',
    name = 'Potion Thrower',
    description = 'Equip and throw potions, poisons and alcohol.',
}

I.Settings.registerGroup {
    key = 'SettingsPotionThrower',
    page = 'PotionThrower',
    l10n = 'PotionThrower',
    name = 'Options',
    permanentStorage = false,
    settings = {
        {
            key = 'Enabled',
            renderer = 'checkbox',
            name = 'Enabled',
            description = 'Enables or disables throwable potions.',
	    default = true
        },
	--[[
        {
            key = 'Style',
            renderer = 'select',
            name = 'Style',
            description = 'Style of gameplay you prefer.\n\nStance: Hold ToggleWeapon in gameplay when a potion is equipped to enter a potion throwing stance. Holding ToggleSpell in gameplay enters a potion drinking stance. Truer to the vanilla Morrowind experience, i.e. fumbling between stances mid-battle.\n\nQuick: Lobs a potion with the press of a dedicated button while staying in your current stance.',
	    argument = {
		disabled = false,
        	l10n = "PotionThrower", 
	    	items = { 'stance', 'quick' },
            },
	    default = true
        },
	]]--
        {
            key = 'QuickLob',
            renderer = 'textLine',
            name = 'Quick Lob Button',
            description = 'Hold and release this button to quickly lob a potion while retaining your current stance. You can also switch to a dedicated potion throwing stance by holding ToggleWeapon.',
	    default = 'c'
        },

    },
}

I.Settings.registerGroup {
    key = 'SettingsPotionThrowerSound',
    page = 'PotionThrower',
    l10n = 'PotionThrower',
    name = 'Sound',
    description = 'Potion Thrower sound settings.',
    permanentStorage = false,
    settings = {
        {
            key = 'SoundEffects',
            renderer = 'checkbox',
            name = 'Sound Effects',
            description = 'Play hit and miss sound effects for thrown potions.',
	    default = true
        },
    },
}

I.Settings.registerGroup {
    key = 'SettingsPotionThrowerVisual',
    page = 'PotionThrower',
    l10n = 'PotionThrower',
    name = 'Visual',
    description = 'Potion Thrower visual settings.',
    permanentStorage = false,
    settings = {
        {
            key = 'DisplayMessages',
            renderer = 'checkbox',
            name = 'Display Messages',
            description = 'Displays messages about throwable potions at the bottom of the screen.',
	    default = true
        },
        {
            key = 'IconDisplayMode',
            renderer = 'select',
            name = 'Icon Display Mode',
            description = 'Display options for potion throwing icon when a potion is equipped. Constant = Always show icon, Armed = Only show icon when holding potion, Never = Don\'t show icon',
	    default = 'constant',
	    argument = {
		disabled = false,
        	l10n = "PotionThrower", 
	    	items = { 'constant', 'armed', 'never' },
            }
        },
        {
            key = 'PotionInfoFadeSeconds',
            renderer = 'number',
            name = 'Potion Info Display Time',
            description = 'Time in seconds to display potion info when switching to potion throwing mode. Set to -1 to always display and 0 to never display.',
	    default = 5
        },
        {
            key = 'LobPotionInfo',
            renderer = 'checkbox',
            name = 'Display Info While Holding Quick Lob',
            description = 'If true, displays info about the armed potion while the Quick Lob key is held.',
	    default = true
        },
    },
}

local settings = storage.playerSection('SettingsPotionThrower')
local audioSettings = storage.playerSection('SettingsPotionThrowerAudio')
local visualSettings = storage.playerSection('SettingsPotionThrowerVisual')
local tweakSettings = storage.globalSection('SettingsPotionThrowerTweaks')

local function displayMessage(event)
	if visualSettings:get('DisplayMessages') then
		ui.showMessage(event.text)
	end
end

local function playSound(event)
	if audioSettings:get('SoundEffects') then
		if event.volume == nil then
			event.volume = 1.0
		end
		-- print(string.format('playing %s at volume %s', event.path, event.volume))
		ambient.playSoundFile(event.path, { volume = event.volume })	
	end
end

local function removeWidget()
	if widget then
		widget:destroy()
		widget = nil
	end
	if potionInfoWidget then
		potionInfoWidget:destroy()
		potionInfoWidget = nil
	end
end

local function fadeWidget(fadingWidget, dt)
	if fadingWidget.layout.props.alpha <= 0 or visualSettings:get('PotionInfoFadeSeconds') == 0 then
		fadingWidget.layout.props.alpha = 0
	elseif visualSettings:get('PotionInfoFadeSeconds') < 0 then
		return
	else
		fadingWidget.layout.props.alpha = fadingWidget.layout.props.alpha - dt / visualSettings:get('PotionInfoFadeSeconds')
	end

	fadingWidget:update()
end

local function hideWidgetsFromSettings()
	if quickLobHeld and visualSettings:get('PotionInfoFadeSeconds') ~= 0 then
		return
	end
	if potionInfoWidget ~= nil and potionInfoWidget.layout.props.alpha ~= 0.0 and visualSettings:get('PotionInfoFadeSeconds') > 0 and potionModeTimePassed > visualSettings:get('PotionInfoFadeSeconds') then
		potionInfoWidget.layout.props.alpha = 0
		potionInfoWidget:update()
	end
end

local function refreshUI()
	if widget == nil then return end
	local count = types.Actor.inventory(self):countOf(armedPotion)
	widget.layout.content["armedPotionContainer"].content["armedPotionCount"].props.text = tostring(count)
	if count > 999 then
		widget.layout.content["armedPotionContainer"].content["armedPotionCount"].props.relativePosition = util.vector2(0.5, 0.8)
	elseif count > 99 then
		widget.layout.content["armedPotionContainer"].content["armedPotionCount"].props.relativePosition = util.vector2(0.6, 0.8)
	elseif count > 9 then
		widget.layout.content["armedPotionContainer"].content["armedPotionCount"].props.relativePosition = util.vector2(0.7, 0.8)
	else
		widget.layout.content["armedPotionContainer"].content["armedPotionCount"].props.relativePosition = util.vector2(0.8, 0.8)
	end

	if visualSettings:get('IconDisplayMode') == 'constant' or (visualSettings:get('IconDisplayMode') == 'armed' and potionMode ~= 0) then
		widget.layout.props.alpha = 1.0
	else
		widget.layout.props.alpha = 0.0

	end

	if visualSettings:get('IconDisplayMode') == 'never' then
		potionInfoWidget.layout.content['name'].props.position = util.vector2(0, potionInfoWidget.layout.content['name'].props.position.y)
		potionInfoWidget.layout.content['action'].props.position = util.vector2(0, potionInfoWidget.layout.content['action'].props.position.y)
	else
		potionInfoWidget.layout.content['name'].props.position = util.vector2(40, potionInfoWidget.layout.content['name'].props.position.y)
		potionInfoWidget.layout.content['action'].props.position = util.vector2(40, potionInfoWidget.layout.content['action'].props.position.y)
	end

	if visualSettings:get('PotionInfoFadeSeconds') == 0 or potionMode == 0 then
		potionInfoWidget.layout.props.alpha = 0
	else
		potionInfoWidget.layout.props.alpha = 1.0
	end

	if potionMode == 0 then
		potionInfoWidget.layout.content["action"].props.text = ""
	elseif potionMode == 1 then
		potionInfoWidget.layout.content["action"].props.text = "Throwing"
	else
		potionInfoWidget.layout.content["action"].props.text = "Drinking"
	end

	if not (I.UI.getMode() == nil or I.UI.getMode() == 'Interface') then
		widget.layout.props.alpha = 0.0
		potionInfoWidget.layout.props.alpha = 0
	end

	widget:update()
	potionInfoWidget:update()
end

local function clearPrompt()
	if promptWidget ~= nil then
		promptWidget:destroy()
		promptWidget = nil
	end
	core.sendGlobalEvent('Unprompt', {} )
	promptInFocus = false
	if promptDuringGameplay then
		I.UI.setMode()
	else
		I.UI.setMode('Interface')
	end
end

local function actionPrompt(event)
	if not modEnabled then return end
	canDismissPrompt = false
	local potionRecord = types.Potion.record(event.recordId)
	local equipText = 'Equip'
	if armedPotion ~= nil and armedPotion == event.recordId then
		equipText = 'Unequip'
	end
	local width = math.max(100, #potionRecord.name * 10)
	local content = ui.content {
	    {
		name = "actionPrompt",
                template = I.MWUI.templates.borders,
		props = {
		    size = util.vector2(width, 128),
		},
		events = {
			focusLoss = async:callback(function()
				promptInFocus = false
		  	end),
			focusGain = async:callback(function()
				promptInFocus = true
		  	end),
		},
		content = ui.content {
		    {
			name = "armedPotionBg",
			type = ui.TYPE.Image,
			props = {
			    resource = ui.texture({ path = 'Black' }),
			    relativeSize = util.vector2(1, 1),
			},
		    },
		    {
                	template = I.MWUI.templates.borders,
			props = {
		    	    size = util.vector2(width-8, 120),
			    position = util.vector2(2, 2),
		    	}
		    },
		    {
			name = "armedPotionIcon",
			type = ui.TYPE.Image,
			props = {
			    resource = ui.texture({ path = potionRecord.icon }),
			    size = util.vector2(32, 32),
			    relativePosition = util.vector2(0.5, 0.35),
			    anchor = util.vector2(0.5, 0.5),
			    --position = util.vector2(8, 8),
			},
		    },
		    {
			name = "armedPotionName",
			type = ui.TYPE.Text,
            		template = I.MWUI.templates.textNormal,
			props = {
			    text = potionRecord.name,
			    textColor = util.color.rgba(255 / 255, 220 / 255, 134 / 255, 1),
			    textSize = 16,
			    relativePosition = util.vector2(0.5, 0.1),
			    anchor = util.vector2(0.5, 0),
			},
		    },
		    {
			name = "drinkOption",
                	template = I.MWUI.templates.borders,
			props = {
			    size = util.vector2(70, 24),
			    relativePosition = util.vector2(0.5, 0.5),
			    anchor = util.vector2(0.5, 0),
			},
			events = {
				mouseClick = async:callback(function()
					clearPrompt()
					core.sendGlobalEvent('DrinkPotion', { recordId = event.recordId, target  = self, fromInventory = true } )
				end),
			},
			content = ui.content {
				    {
					name = "drinkLabel",
					type = ui.TYPE.Text,
					template = I.MWUI.templates.textNormal,
					props = {
					    text = 'Drink',
					    textColor = util.color.rgba(255 / 255, 220 / 255, 134 / 255, 1),
					    textSize = 16,
					    relativePosition = util.vector2(0.5, 0.5),
					    anchor = util.vector2(0.5, 0.5),
					},
				    },
			},
		    },
		    {
			name = "equipOption",
                	template = I.MWUI.templates.borders,
			props = {
			    size = util.vector2(70, 24),
			    relativePosition = util.vector2(0.5, 0.75),
			    anchor = util.vector2(0.5, 0),
			},
			events = {
				mouseClick = async:callback(function()
					clearPrompt()
					core.sendGlobalEvent('EquipPotion', { recordId = event.recordId, player = self } )
				end),
			},
			content = ui.content {
				    {
					name = "equipLabel",
					type = ui.TYPE.Text,
					template = I.MWUI.templates.textNormal,
					props = {
					    text = equipText,
					    textColor = util.color.rgba(255 / 255, 220 / 255, 134 / 255, 1),
					    textSize = 16,
					    relativePosition = util.vector2(0.5, 0.5),
					    anchor = util.vector2(0.5, 0.5),
					},
				    },
			},
		    },
		},
	    },
	}
	if I.UI.getMode() ~= 'Interface' then
		promptDuringGameplay = true
		I.UI.setMode('Interface', {windows = {}})
	else
		promptDuringGameplay = false
	end
	promptWidget = ui.create({
		layer = 'Windows',
		type = ui.TYPE.Widget,
		props = {
			relativePosition = util.vector2(0.5, 0.5),
			anchor = util.vector2(0.5, 0.5),
			--position = util.vector2(12, -96),
		    	size = util.vector2(width, 128),
		},
		content = ui.content(content)
	})
	promptWidget:update()
end

local function createWidget(potionRecordId)
	removeWidget()

	local potionRecord = types.Potion.record(potionRecordId)

	-- use list of effects
	local info = {}

	local textOffset = 0
	local longestName = potionRecord.name
	local effectIndex = 1
	local alchemySkill = types.NPC.stats.skills["alchemy"](self).modified
	for index, effect in pairs(potionRecord.effects) do
		local effectText = core.magic.effects.records[effect.id].name
		if effect.affectedAttribute then
			effectText = effectText .. " " .. effect.affectedAttribute:gsub("^%l", string.upper)
		elseif effect.affectedSkill then
			effectText = effectText .. " " .. effect.affectedSkill:gsub("^%l", string.upper)
		end
		if effect.magnitudeMin ~= nil then
			if effect.magnitudeMin == effect.magnitudeMax then
				effectText = effectText .. string.format(" [%s for %ss]", effect.magnitudeMin, effect.duration)
			else
				effectText = effectText .. string.format(" [%s-%s for %ss]", effect.magnitudeMin, effect.magnitudeMax, effect.duration)
			end
		end

		if alchemySkill < effectIndex * 15 then
			table.insert(info, {
				type = ui.TYPE.Text,
				props = {
					text = '?',
					template = I.MWUI.templates.textNormal,
					position = util.vector2(4, textOffset),
					textColor = util.color.rgba(255, 220, 134, 1),
					textSize = 16,
				}
			})
		else
			table.insert(info, {
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture({ path = effect.effect.icon }),
					size = util.vector2(18, 18),
					position = util.vector2(0, textOffset),
				},
			})
			table.insert(info, {
				type = ui.TYPE.Text,
				props = {
					text = effectText,
					template = I.MWUI.templates.textNormal,
					position = util.vector2(24, textOffset),
					textColor = util.color.rgba(255, 220, 134, 1),
					textSize = 16,
				}
			})
		end
		effectIndex = effectIndex + 1
		textOffset = textOffset + 20
		if #effectText > #longestName then
			longestName = effectText
		end
	end
	table.insert(info, {
		type = ui.TYPE.Text,
		name = 'action',
		props = {
			text = "Throwing",
            		--template = I.MWUI.templates.textNormal,
			textColor = util.color.rgba(216, 220, 134, 1),
			--textColor = util.color.rgba(255 / 255, 220 / 255, 134 / 255, 0.8),
			textColor = util.color.rgba(186 / 255, 160 / 255, 106 / 255, 1),
			textSize = 16,
                	position = util.vector2(40, textOffset),
        	}
	})
	textOffset = textOffset + 20
	table.insert(info, {
		type = ui.TYPE.Text,
		name = 'name',
		props = {
			text = potionRecord.name,
            		--template = I.MWUI.templates.textNormal,
			-- textColor = util.color.rgba(1, 1, 1, 1),
			textColor = util.color.rgba(255 / 255, 220 / 255, 134 / 255, 1),
			textSize = 16,
                	position = util.vector2(40, textOffset),
        	}
	})
	textOffset = textOffset + 20
	local potionInfo = ui.content {
		name = "armedPotionInfo",
                template = I.MWUI.templates.borders,
		props = {
			size = util.vector2(#longestName * 20, textOffset),
		},
		content = ui.content(info)
	}
	local content = ui.content {
	    {
		name = "armedPotionContainer",
                template = I.MWUI.templates.borders,
		props = {
		    size = util.vector2(36, 36),
		},
		events = {
			mouseClick = async:callback(function()
				self:sendEvent('PotionArmed', {potion = nil})
		  	end),
		},
		content = ui.content {
		    {
			name = "armedPotionBg",
			type = ui.TYPE.Image,
			props = {
			    resource = ui.texture({ path = 'Black' }),
			    relativeSize = util.vector2(36, 36),
			},
		    },
		    {
			name = "armedPotionIcon",
			type = ui.TYPE.Image,
			props = {
			    resource = ui.texture({ path = potionRecord.icon }),
			    size = util.vector2(32, 32),
			    relativePosition = util.vector2(0.5, 0.5),
			    anchor = util.vector2(0.5, 0.5),
			    --alpha = 0.75
			},
		    },
		    {
			name = "armedPotionCount",
			type = ui.TYPE.Text,
            		template = I.MWUI.templates.textNormal,
			props = {
			    text = tostring(types.Actor.inventory(self):countOf(potionRecordId)),
			    -- textColor = util.color.rgba(255 / 255, 220 / 255, 134 / 255, 1),
			    textColor = util.color.rgba(245 / 255, 222 / 255, 165 / 255, 1),
			    textSize = 16,
			    relativePosition = util.vector2(0.8, 0.8),
			    anchor = util.vector2(0.5, 0.5),
			},
		    },
		},
	    },
	}
	widget = ui.create({
		layer = 'Windows',
		type = ui.TYPE.Widget,
		props = {
			relativePosition = util.vector2(0, 1),
			anchor = util.vector2(0, 1),
			position = util.vector2(12, -96),
		    	size = util.vector2(128, 40),
		},
		content = ui.content(content)
	})
	potionInfoWidget = ui.create({
		layer = 'HUD',
		type = ui.TYPE.Widget,
		props = {
			alpha = 1.0,
			relativePosition = util.vector2(0, 1),
			anchor = util.vector2(0, 1),
			position = util.vector2(12, -96),
			size = util.vector2(#longestName * 16, textOffset),
		},
		content = ui.content(info)
	})
	refreshUI()
	-- TODO: move stealth icon?
	-- createStealthIcon()
end


local function throwPotion(arm)
	-- TODO: reduce fatigue
	-- types.Actor.DynamicStats.fatigue(self).current = types.Actor.DynamicStats.fatigue(self).current - fatigueHit
	anim.removeVfx(self, "heldpotion")
	--self.type.activeEffects(self):set(100, core.magic.EFFECT_TYPE.DamageFatigue)
	arm = arm or 'right'
	if arm == 'right' then
		anim.playBlended(self, animThrow, {
			priority = anim.PRIORITY.Scripted,
			blendMask = anim.BLEND_MASK.RightArm,
			autoDisable = false,
			loops = 0,
		})
	else
		anim.playBlended(self, animThrowLeft, {
			priority = anim.PRIORITY.Scripted,
			blendMask = anim.BLEND_MASK.LeftArm,
			autoDisable = false,
			loops = -1,
		})
	end
	local direction = (camera.viewportToWorldVector(util.vector2(0.5,0.5))):normalize()
	local speed = tweakSettings:get('BaseSpeed') + tweakSettings:get('StrengthFactor') * types.Actor.stats.attributes.strength(self).modified * math.max(0.0, math.min(2.0, throwCharge - 0.25)) -- first 0.25 seconds dont add throw charge for tapping/lobbing
	local startPos = self.position + direction * 20 + util.vector3(0,0, tweakSettings:get('InitialHeight'))
	if input.isActionPressed(input.ACTION.MoveForward) then
		startPos = startPos + direction * 15
		--speed = speed + 30
	end
	if input.isActionPressed(input.ACTION.MoveBackward) then
		startPos = startPos - direction * 15
		--speed = speed - 10
	end
	if input.isActionPressed(input.ACTION.MoveRight) then
		local right = util.vector3(
			direction.y,
			-direction.x,
			0
	  	)
		startPos = startPos + right * 10
		--speed = speed - 10
	end
	if input.isActionPressed(input.ACTION.MoveLeft) then
		local right = util.vector3(
			direction.y,
			-direction.x,
			0
	  	)
		startPos = startPos - right * 5
		--speed = speed - 10
	end
	-- local invPotion = types.Actor.inventory(self).find(armedPotion)
	core.sendGlobalEvent("ThrowPotion", { direction = direction, speed = speed, player = self, startPos = startPos, throwerVelocity = velocity / 10.0 } )
	throwCharge = -1
end

local function skillUp(event)
	I.SkillProgression.skillUsed(event.skill, { skillGain = event.amount, skillUseType = 0 })
end

local function onFrame(dt)
	if not modEnabled then return end

	--[[
	local use = input.getBooleanActionValue('Use')
	if promptWidget ~= nil and ((canDismissPrompt and not promptInFocus and use) or (not promptDuringGameplay and not I.UI.getMode())) then
		clearPrompt()
	end

	if not use then
		canDismissPrompt = true
	end
	]]--

	-- allow enabling by holding the ready weapon button
	local armPotionHeld = input.isActionPressed(input.ACTION.ToggleWeapon)
	if not armingEnabled and armPotionHeld then
		if I.UI.getMode() == I.UI.MODE.Interface then
    			displayMessage({ text = 'Hold ToggleWeapon to equip a potion..' })
		end
		armingEnabled = true
		core.sendGlobalEvent("EnableArming", { armingButtonHeld = true } )
	end
	if armingEnabled and not armPotionHeld then
		if I.UI.getMode() == I.UI.MODE.Interface then
    			--ui.showMessage('Hold Weapon Toggle key to equip throwable potion.')
		end
		armingEnabled = false
		core.sendGlobalEvent("EnableArming", { armingButtonHeld = false })
	end

	-- allow drinking by holding the ready spell button
	local drinkPotionHeld = input.isActionPressed(input.ACTION.ToggleSpell)
	if not drinkingEnabled and drinkPotionHeld then
		if I.UI.getMode() == I.UI.MODE.Interface then
    			displayMessage({ text = 'Hold ToggleSpell to drink a potion..' })
		end
		drinkingEnabled = true
		core.sendGlobalEvent("EnableDrinking", { drinkingButtonHeld = true } )
	end
	if drinkingEnabled and not drinkPotionHeld then
		drinkingEnabled = false
		core.sendGlobalEvent("EnableDrinking", { drinkingButtonHeld = false })
	end
end

local function endPotionMode()
	if potionMode ~= 0 then
		potionMode = 0
		canEndPotionMode = false
		canEnterThrowMode = false
		canEnterDrinkMode = false
		potionModeTimePassed = 0
		anim.playBlended(self, 'nil', {
			priority = anim.PRIORITY.Scripted,
			blendMask = anim.BLEND_MASK.RightArm,
			loops = -1,
			autoDisable = false,
		})
		refreshUI()
		anim.removeVfx(self, "heldpotion")
		-- types.Actor.setStance(self, types.Actor.STANCE.Nothing)
	end
end

local function armPotion(event)
    	anim.removeVfx(self, "heldpotion")
	if event.potion == nil or types.Actor.inventory(self):countOf(event.potion) == 0 then
		if modEnabled and armedPotion ~= nil then
    			displayMessage({ text = string.format('%s unequipped.', types.Potion.record(armedPotion).name) })
		end
		endPotionMode()
		armedPotion = nil
		meshPath = nil
		removeWidget()
		-- remove holding animation with an invalid anim
		anim.playBlended(self, 'nil', {
			priority = anim.PRIORITY.Scripted,
			blendMask = anim.BLEND_MASK.RightArm,
			loops = -1,
			autoDisable = false,
		})
		return
	end

	if not modEnabled then return end

	local potionRecord = types.Potion.record(event.potion)
	-- I would love to just use the model, and support all current and future potions.
	-- But a bug in addVfx means we need distinct models to show a potion in-hand.
	meshPath = string.gsub(potionRecord.model, '.nif', '_throwable.nif')
	if not vfs.fileExists(meshPath) then
		-- probably a modded mesh, just default to a standard one
		meshPath = 'meshes/m/misc_potion_standard_01_throwable.nif'
	end
    	displayMessage( { text = string.format('Equipped %s', potionRecord.name) } )
	armedPotion = event.potion
	if types.Actor.getStance(self) == types.Actor.STANCE.Nothing then
		armedPotionReady = true
	end
	createWidget(potionRecord.id)
end

local function onUpdate(dt)
	if not modEnabled then return end
	if armedPotion == nil then return end

	local armPotionHeld = input.isActionPressed(input.ACTION.ToggleWeapon)
	local drinkPotionHeld = input.isActionPressed(input.ACTION.ToggleSpell)

	if not I.UI.getMode() then
		if armPotionHeld then
			armPotionHoldTime = armPotionHoldTime + dt
			if armPotionHoldTime >= armPotionTriggerSeconds * 0.5 then
				types.Actor.setStance(self, types.Actor.STANCE.Nothing)
			end
			if armPotionHoldTime >= armPotionTriggerSeconds then
				armPotionReady = true
			end
		else
			armPotionHoldTime = 0
			if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
				armPotionReady = false
			end
		end

		if drinkPotionHeld then
			drinkPotionHoldTime = drinkPotionHoldTime + dt
			if drinkPotionHoldTime >= drinkPotionTriggerSeconds * 0.5 then
				types.Actor.setStance(self, types.Actor.STANCE.Nothing)
			end
			if drinkPotionHoldTime >= drinkPotionTriggerSeconds then
				drinkPotionReady = true
			end
		else
			drinkPotionHoldTime = 0
			if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
				drinkPotionReady = false
			end
		end
	end

	hideWidgetsFromSettings()

	if not canEnterThrowMode then
		canEnterThrowMode = types.Actor.getStance(self) == types.Actor.STANCE.Weapon and not input.isActionPressed(input.ACTION.ToggleWeapon)
	end

	if not canEnterDrinkMode then
		canEnterDrinkMode = types.Actor.getStance(self) == types.Actor.STANCE.Spell and not input.isActionPressed(input.ACTION.ToggleSpell)
	end

	if not canUsePotion and not input.getBooleanActionValue('Use') then
		potionUseTime = potionUseTime + dt
		if potionUseTime > 0.3 then
			anim.cancel(self, animThrowLeft)
		end
		if potionUseTime > 0.5 then
			if types.Actor.inventory(self):countOf(armedPotion) == 0 then
				armPotion({potion = nil })
				return
			else
				canUsePotion = true
			end
		end
	end

	if potionMode == 1 or armPotionReady then
		if potionMode ~= 1 then
			potionMode = 1
			refreshUI()
		end

		if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
			endPotionMode()
			return
			--types.Actor.setStance(self, types.Actor.STANCE.Nothing)
		end

		potionModeTimePassed = potionModeTimePassed + dt
		if throwCharge == -1 and not anim.isPlaying(self, animThrow) and potionModeTimePassed > 0.25 then
			local bone = "Bip01 R Finger11"
			if camera.getMode() == camera.MODE.FirstPerson then
				bone = "Bip01 R Finger4" 
			end
    			anim.addVfx(self, meshPath, {loop = true, boneName = bone, vfxId = "heldpotion", useAmbientLight = false})
			anim.playBlended(self, animThrowIdle, {
				priority = anim.PRIORITY.Scripted,
				blendMask = anim.BLEND_MASK.RightArm,
				loops = -1,
				autoDisable = false,
			})
		end

		if I.UI.getMode() then return end

		if input.getBooleanActionValue('Use') and canUsePotion then
			if throwCharge == -1 then
				if anim.isPlaying(self, animThrowIdle) then
					-- only start throw when we are in position
					anim.playBlended(self, animThrowWindUp, {
						priority = anim.PRIORITY.Scripted,
						blendMask = anim.BLEND_MASK.RightArm,
						loops = -1,
						--speed = 0.1,
						--startPoint = 0.9,
						autoDisable = false,
					})
					throwCharge = 0
				end
			else
				throwCharge = throwCharge + dt
			end
		else
			if throwCharge ~= -1 then
				canUsePotion = false
    				throwPotion()
			end

		end
	elseif potionMode == 2 or drinkPotionReady then

		if potionMode ~= 2 then
			types.Actor.setStance(self, types.Actor.STANCE.Nothing)
			potionMode = 2
			refreshUI()
		end

		if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
			endPotionMode()
			return
		end

		potionModeTimePassed = potionModeTimePassed + dt
		if canUsePotion then
			local bone = "bip01 r hand"
			if camera.getMode() == camera.MODE.FirstPerson then
				bone = "bip01 r finger42" 
			end
    			anim.addVfx(self, meshPath, {loop = true, boneName = bone, vfxId = "heldpotion", useAmbientLight = false})
			anim.playBlended(self, animDrinkIdle, {
				priority = anim.PRIORITY.Scripted,
				blendMask = anim.BLEND_MASK.RightArm,
				loops = -1,
				autoDisable = false,
			})
		end

		if I.UI.getMode() then return end

		if input.getBooleanActionValue('Use') and canUsePotion then
			canUsePotion = false
			anim.playBlended(self, animDrink, {
				priority = anim.PRIORITY.Scripted,
				blendMask = anim.BLEND_MASK.RightArm,
				loops = -1,
				--speed = 0.1,
				--startPoint = 0.9,
				autoDisable = false,
			})
			core.sendGlobalEvent('DrinkPotion', { recordId = armedPotion, target = self} )
		end
	elseif quickLobHeld then
		throwCharge = throwCharge + dt
	end

	if previousPosition ~= nil then
		velocity = (self.position - previousPosition) / dt
	end
	previousPosition = self.position
end


settings:subscribe(async:callback(function(section, key)
    if key then
        print('Potion Thrower setting is changed:', key, '=', settings:get(key))
	if key == 'Enabled' and not settings:get(key) then
		armPotion({potion=nil})
		modEnabled = false
		core.sendGlobalEvent('SetEnabled', { enabled = false } )
	end
	if key == 'Enabled' and settings:get(key) then
		modEnabled = true
		core.sendGlobalEvent('SetEnabled', { enabled = true } )
	end
	refreshUI()
    end
end))

local function onInit()
	modEnabled = settings:get('Enabled')
	core.sendGlobalEvent('SetEnabled', { enabled = modEnabled } )
end

local function onKeyPress(key)
	if not modEnabled then return end
	if I.UI.getMode() then return end
	if armedPotion == nil then return end
	if not canUsePotion then return end
	if potionMode ~= 0 then return end
	if key.symbol == settings:get('QuickLob') then
		anim.playBlended(self, 'jump2c', {
			priority = anim.PRIORITY.Scripted,
			blendMask = anim.BLEND_MASK.LeftArm,
			loops = -1,
			autoDisable = false,
		})
		quickLobHeld = true
		throwCharge = 0
		if visualSettings:get('LobPotionInfo') then
			potionInfoWidget.layout.props.alpha = 1.0
			potionInfoWidget.layout.content["action"].props.text = "Throwing"
			potionInfoWidget:update()
		end
		--[[
		local bone = "bip01 l finger1"
		if camera.getMode() == camera.MODE.FirstPerson then
			bone = "bip01 l finger42" 
		end
		anim.addVfx(self, meshPath, {loop = true, boneName = bone, vfxId = "heldpotion", useAmbientLight = false})
		]]--
	end
end

local function onKeyRelease(key)
	if not modEnabled then return end
	if I.UI.getMode() then return end
	if armedPotion == nil then return end
	if not canUsePotion then return end
	if potionMode ~= 0 then return end
	if key.symbol == settings:get('QuickLob') then
		throwPotion('left')
		potionUseTime = 0
		canUsePotion = false
		quickLobHeld = false
		if visualSettings:get('PotionInfoFadeTime') ~= -1 then
			potionInfoWidget.layout.props.alpha = 0
			potionInfoWidget:update()
		end
	end
end

local function uiModeChanged(data)
	if not modEnabled then return end
	if data.newMode == nil and promptWidget ~= nil then
		clearPrompt()
	end
	refreshUI()
end

return {
	eventHandlers = { PotionArmed = armPotion,
		RefreshUI = refreshUI,
		SkillUp = skillUp,
		ShowMessage = displayMessage,
		PlaySound = playSound,
		PromptForAction = actionPrompt,
		UiModeChanged = uiModeChanged
	},
	engineHandlers = { onUpdate = onUpdate,
		onFrame = onFrame,
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onInit = onInit,
	}
}
