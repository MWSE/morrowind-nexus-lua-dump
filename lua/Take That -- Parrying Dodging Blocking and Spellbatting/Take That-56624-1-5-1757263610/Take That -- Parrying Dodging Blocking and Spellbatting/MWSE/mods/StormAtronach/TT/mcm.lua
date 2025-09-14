local common = require("StormAtronach.TT.common")
local config = require("StormAtronach.TT.config")

local function modActivation()
    event.trigger("stormatronach:modActivation")
end

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
		text =      "Take That!\n\n" ..
                    "A modern combat mod with blocking, parrying, dodging, and spell batting. \n" ..
                    "Tweak the settings below to customize your experience. \n" ..
                    "Please visit the Nexus page for more information and support.\n\nMade by:",
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
		name = "Take That!",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.confPath, config)

	local page = template:createSideBarPage({
		label = "Main Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

    local blockSettings = template:createSideBarPage({
		label = "Block",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(blockSettings)

    local parrySettings = template:createSideBarPage({
		label = "Parry (NPCs)",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(parrySettings)

    local dodgeSettings = template:createSideBarPage({
		label = "Dodge",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(dodgeSettings)

    local spellBattingSettings = template:createSideBarPage({
		label = "Dodge",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(spellBattingSettings)

    local balancing = template:createSideBarPage({
		label = "Re-balancing",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(balancing)

    page:createOnOffButton{
        label = "Enable Mod",
        description = "Toggle the mod on or off.",
        configKey = "enabled",
        callback = modActivation
    }

    page:createKeyBinder{
        label = "Block Hotkey",
        description = "Choose a hotkey for starting the block. Mouse buttons are allowed, as well as combinations (shift+stuff, ctrl+stuff, etc.)",
        allowCombinations = true,
        allowModifierKeys = true,
        allowMouse        = true,
        configKey         = "hotkey"
    }
    page:createOnOffButton{
        label = "Enable Parry Slowdown",
        description = "Toggle the parry slowdown functionality on or off. You should deactivate this if you are using chronomancy from Halls of the Colossus",
        configKey = "parrySlowDown",
    }
    balancing:createOnOffButton{
        label = "Enable Damage Multiplier for player attacks",
        description = "Enable a damage mulitplier for player attacks. This is to speed up combat since parries can reduce the effective DPS on both sides, making each hit count more.",
        configKey = "damageMultiplierPlayer",
    }
    balancing:createOnOffButton{
        label = "Enable Damage Multiplier for non-player attacks",
        description = "Enable a damage mulitplier for NPC and creature attacks. This is to speed up combat since parries can reduce the effective DPS on both sides, making each hit count more.",
        configKey = "damageMultiplierNPC",
    }

    balancing:createSlider{
        label = "Damage multiplier",
        description = "This is a damage multiplier, which only affects physical attacks (and not ranged attacks). This multiplier is intended to give more weight to the attacks that actually land, in order not to extend combat excessively. The parry mechanic effectively lowers DPS as less attacks hit; this is intented to correct for that.",
        min = 1, max = 5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey = "damageMultiplier",
    }
    
    balancing:createOnOffButton{
        label = "Enable Hit Chance Multiplier for player attacks",
        description = "Enable Hit Chance Multiplier for player attacks. As before, the parry mechanic reduces the DPS, potentially slowing down combat. This helps make each hit count, resulting in more impactful combat.",
        configKey = "hitChanceModPlayer",
    }
    balancing:createOnOffButton{
        label = "Enable Hit Chance Multiplier for non-player attacks",
        description = "TEnable Hit Chance Multiplier for NPC and creature's attacks. As before, the parry mechanic reduces the DPS, potentially slowing down combat. This helps make each hit count, resulting in more impactful combat.",
        configKey = "hitChanceModNPC",
    }

    balancing:createSlider{
        label = "Hit chance multiplier",
        description = "This is the hit chance multiplier, which only affects physical attacks (and not ranged attacks). This multiplier is intended to give more weight to the attacks that actually land, in order not to extend combat excessively. The parry mechanic effectively lowers DPS as less attacks hit; this is intented to correct for that.",
        min = 1, max = 5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey = "hitChanceMultiplier",
    }

    blockSettings:createSlider{
        label = "Block Cooldown (seconds)",
        description = "This is the cooldown for blocking. It is not the same as the block window.",
        min = 1, max = 10, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey = "block_cool_down_time",
    }

    dodgeSettings:createSlider{
        label = "Dodge Cooldown (seconds)",
        description = "This is the cooldown for dodging. It is not the same as the dodge window.",
        min = 1, max = 10, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="dodge_cool_down_time",
    }

    blockSettings:createSlider{
        label = "Block Window (seconds)",
        description = "This is the base window for blocking. Block before the enemy hits.",
        min = 0.1, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="block_window",
    }
--[[
    page:createSlider{
        label = "Parry Window (seconds)",
        description = "This is the base window for parrying. Release the attack just before the enemy hits. Each attack will reduce the window by the factor below.",
        min = 0.1, max = 0.5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="parry_window",
    }

    page:createSlider{
        label = "Parry window reduction factor per Attack",
        description = "This is the factor that will reduce the parry window for each attack. The more you parry, the smaller the window. The contribution of each attack is removed after 0.75 seconds",
        min = 1.5, max = 5, step = 0.25, jump = 0.25, decimalPlaces = 2,
        configKey ="parry_red_per_attack",
    }

    page:createSlider{
        label = "Parry window reduction duration (seconds)",
        description = "This is the duration for the parry window reduction. The contribution of each attack is removed after this time.",
        min = 0.5, max = 5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="parry_red_duration",
    }
]]
    spellBattingSettings:createSlider{
        label = "Spell Batting Minimum Skill",
        description = "This is the minimum skill required to use spell batting. It just feels unrealistic to be able to bat spells with 0 skill, but it is your choice.",
        min = 0, max = 100, step = 1, jump = 5,
        configKey ="bat_min_skill",
    }

    spellBattingSettings:createSlider{
        label = "Spell Batting Window (seconds)",
        description = "This is the window for spell batting. Release the attack just before the spell hits.",
        min = 0.1, max = 1.2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="bat_window",
    }

    blockSettings:createSlider{
        label = "Block Shield Base %",
        description = "This is the base damage reduction when blocking with a shield.",
        min = 0, max = 100, step = 1, jump = 5,
        configKey ="block_shield_base_pc",
    }

    blockSettings:createSlider{
        label = "Block Shield Skill Multiplier",
        description = "0.5 means 50% of the block skill is added to the damage reduction formula.",
        min = 0, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="block_shield_skill_mult",
    }

    blockSettings:createSlider{
        label = "Block Weapon Base %",
        description = "This is the base damage reduction when blocking with a weapon.",
        min = 0, max = 100, step = 1, jump = 5,
        configKey ="block_weapon_base_pc",
    }

    blockSettings:createSlider{
        label = "Blocking: Weapon Skill Multiplier",
        description = "0.2 means 20% of the weapon skill is added to the damage reduction formula.",
        min = 0, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="block_weapon_skill_mult",
    }

    blockSettings:createOnOffButton{
        label = "Alternative calculation for weapon block. Block skill also contributes to the damage reduction when using weapon block",
        description = "If this is enabled, the block skill will also contribute to the damage reduction when using weapon block. Also, blocking will grant experience to the block skill instead of the weapon skill.",
        configKey ="block_skill_bonus_active",
    }

    blockSettings:createSlider{
        label = "Bonus from block skill when using weapon block. ",
        description = "0.2 means 20% of the block skill is added to the damage reduction formula.",
        min = 0, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="block_weapon_blockSkill_bonus",
    }

    blockSettings:createSlider{
        label = "Blocking: Vanilla blocking cap%",
        description = "Set the vanilla blocking cap to 0 to disable vanilla blocking. Set to 50 to allow full vanilla block chance.",
        min = 0, max = 50, step = 1, jump = 1,
        configKey ="vanilla_blocking_cap",
    }

    blockSettings:createOnOffButton{
        label = "Blocking: Allow Vanilla Blocking while attacking",
        description = "If this is enabled, the vanilla automatic blocking mechanic will work while you are holding an attack at full power, ignoring the Vanilla Blocking cap%.",
        configKey ="allow_vanilla_block",
    }

    page:createSlider{
        label = "Training: XP gain from blocking",
        description = "XP gain from blocking. Vanilla per succesful block is 2.5",
        min = 0, max = 10, step = 0.5, jump = 0.5, decimalPlaces = 1,
        configKey ="block_skill_gain",
    }

    page:createSlider{
        label = "Training: XP gain from parry",
        description = "XP gain from parrying. Vanilla per succesful attack is 1-2 depending on the weapon",
        min = 0, max = 10, step = 0.5, jump = 0.5, decimalPlaces = 1,
        configKey ="parry_skill_gain",
    }
    page:createSlider{
        label = "Training: XP gain from dodging",
        description = "XP gain from dodging. I am using 5, but there is no equivalent in vanilla.",
        min = 0, max = 10, step = 0.5, jump = 0.5, decimalPlaces = 1,
        configKey ="dodge_skill_gain",
    }

    parrySettings:createOnOffButton{
        label = "NPC Parry Active",
        description = "If this is enabled, NPCs will be able to parry your attacks.",
        configKey ="enemy_parry_active",
    }

    parrySettings:createSlider{
        label = "NPC Parry Window (seconds)",
        description = "This is the base window for NPC parrying.",
        min = 0.1, max = 0.5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="enemy_parry_window",
    }

    parrySettings:createSlider{
        label = "NPC minimum swing for parry",
        description = "This is the minimum swing that the NPC will need to achieve to parry your attack. NPC swing is randomized by the game engine",
        min = 0.1, max = 1, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="enemy_min_attackSwing",
    }

    parrySettings:createSlider{
        label = "Parry light magnitude",
        description = "This is the magnitude of the light effect when parrying. Set to 0 to disable the effect.",
        min = 0, max = 100, step = 1, jump = 5, decimalPlaces = 1,
        configKey ="parry_light_magnitude",
    }

    parrySettings:createSlider{
        label = "Parry light duration",
        description = "This is the magnitude of the light effect when parrying. Set to 0 to disable the effect.",
        min = 0, max = 0.5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        configKey ="parry_light_duration",
    }

	page:createLogLevelOptions({
		configKey = "log_level",
        defaultSetting = "error"
	})
end
event.register("modConfigReady", registerModConfig)
