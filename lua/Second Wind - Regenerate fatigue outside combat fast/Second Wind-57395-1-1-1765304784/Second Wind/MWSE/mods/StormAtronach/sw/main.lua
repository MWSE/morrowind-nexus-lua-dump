--- Configuration stuff
local default_config = {
    enabled         = true,
    wanderingValue  = 2,
    restingValue    = 3
}

local config        = mwse.loadConfig("SA_SecondWind_config", default_config) ---@cast config table
config.confPath     = "SA_SecondWind_config"
config.default      = default_config

-- Variables
local wandering = "SA_WanderingSpell"
local resting   = "SA_RestingSpell"
local wanderingSpell
local restingSpell

local function initializedCallback()
    wanderingSpell = tes3.createObject{
            objectType = tes3.objectType.spell,
            id = wandering,
            name = "Wandering",
            castType = tes3.spellType.ability,
            effects = {
            { id = tes3.effect.restoreFatigue, min = config.wanderingValue, max = config.wanderingValue}
        }
    }

    restingSpell = tes3.createObject{
        objectType = tes3.objectType.spell,
        id = resting,
        name = "Catching your breath",
        castType = tes3.spellType.ability,
        effects = {
        { id = tes3.effect.restoreFatigue, min = config.restingValue, max = config.restingValue}
    }
}
end
event.register(tes3.event.initialized, initializedCallback)

-- Helper to update spell magnitudes only when necessary
local function updateSpellMagnitudes()
    if wanderingSpell then
        local effect = wanderingSpell.effects[1]
        effect.min = config.wanderingValue
        effect.max = config.wanderingValue
    end

    if restingSpell then
        local effect = restingSpell.effects[1]
        effect.min = config.restingValue
        effect.max = config.restingValue
    end

    -- Refresh spells on player if they are active to apply new magnitudes immediately
    if tes3.player then
        if tes3.hasSpell({ reference = tes3.player, spell = wandering }) then
            tes3.removeSpell({ reference = tes3.player, spell = wandering })
            tes3.addSpell({ reference = tes3.player, spell = wandering })
        end
        if tes3.hasSpell({ reference = tes3.player, spell = resting }) then
            tes3.removeSpell({ reference = tes3.player, spell = resting })
            tes3.addSpell({ reference = tes3.player, spell = resting })
        end
    end

    if not config.enabled then
        tes3.removeSpell({ reference = tes3.player, spell = wandering })
        tes3.removeSpell({ reference = tes3.player, spell = resting })
    end
end

local function recoverFatigue()
    -- check to safeguard against the loading or other conditions where this timer might get called
    if not tes3.player then return end
    -- Check if the player has the spell active
    local isActive = tes3.hasSpell({
        reference = tes3.player,
        spell = wandering})
    local isCrouchingBonusActive = tes3.hasSpell{
        reference = tes3.player,
        spell = resting}

        if not isActive and not tes3.mobilePlayer.inCombat and config.enabled then
            tes3.addSpell{reference = tes3.player, spell = wandering}
        end

        if isActive and tes3.mobilePlayer.inCombat then
            tes3.removeSpell{reference = tes3.player, spell = wandering}
        end
        local mp = tes3.mobilePlayer
        local movement = mp.isMovingBack or mp.isMovingForward or mp.isMovingLeft or mp.isMovingRight
        if tes3.mobilePlayer.isSneaking then
            if not isCrouchingBonusActive and not movement and not tes3.mobilePlayer.inCombat and config.enabled then
                tes3.addSpell{reference = tes3.player, spell = resting}
            elseif isCrouchingBonusActive and movement then
                tes3.removeSpell{reference = tes3.player, spell = resting}
            end
        else
            if isCrouchingBonusActive then
                tes3.removeSpell{reference = tes3.player, spell = resting}
            end
        end
end

-- We start the timer when the game has been loaded
--- @param e loadedEventData
local function loadedCallback(e)
    timer.start{
    type = timer.simulate,
    duration = 1,
    iterations = -1,
    callback = recoverFatigue
}
    updateSpellMagnitudes()
end
event.register(tes3.event.loaded, loadedCallback)

--- MCM stuff
--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

local authors = {
	{
		name = "Storm Atronach",
		url = "https://next.nexusmods.com/profile/StormAtronach0",
	},
}


--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text =      "Second Wind\n\n" ..
                    "A quality of life mod for recovering stamina while out of combat. \n" ..
                    "If you are out of combat, your stamina will regenerate fast. You can configure how fast in the sliders below. \n" ..
                    "For extra stamina regen, crouch without moving.\n\nMade by:",
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Second Wind",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
        onClose = function()
            updateSpellMagnitudes()
            mwse.saveConfig(config.confPath, config)
        end
	})
	template:register()

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

    page:createOnOffButton{
        label = "Enable Mod",
        description = "Toggle the mod on or off.",
        configKey = "enabled",
    }

    page:createSlider{
        label = "Stamina regen per second while wandering",
        description = "This is the value of the stamina regeneration per second while wandering",
        min = 0, max = 5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="wanderingValue",
    }

    page:createSlider{
        label = "Stamina regen per second while crouching and not moving",
        description = "This is the value of the stamina regeneration per second while crouching and not moving",
        min = 0, max = 10, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="restingValue",
    }
    end
event.register("modConfigReady", registerModConfig)