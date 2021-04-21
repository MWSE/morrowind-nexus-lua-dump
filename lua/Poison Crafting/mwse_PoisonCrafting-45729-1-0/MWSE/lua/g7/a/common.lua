--[[
	Plugin: mwse_PoisonCrafting.esp
--]]

local this = {
	config = {}
}

-- Config

function this.loadConfig()
	local cfg = json.loadfile("mwse_PoisonCrafting")

	if not cfg then
		-- defaults
		cfg = {
			msgPoisonApplied = true,
			msgReadyPoison = true,
			poisonHotkey = 18,
			useBaseStats = true,
			useBonusProgress = true,
			useLabels = true,
			usePoisonRecovery = true,
			version = 1,
		}
	end

	this.config = cfg
end


function this.saveConfig()
	this.loadLabels() -- ensures labels are reloaded after changes
	json.savefile("mwse_PoisonCrafting", this.config, {indent=true})
end


-- Interface

function this.prepareHUD()
	local scale = mge.getUIScale()
	local width = mge.getScreenWidth()
	local height = mge.getScreenHeight()

	mge.loadHUD{
		hud = "g7a_PoisonHUD",
		texture = "g7/hud/PoisonDrop.dds",
	}
	mge.scaleHUD{
		hud = "g7a_PoisonHUD",
		x = scale,
		y = scale,
	}
	mge.positionHUD{
		hud = "g7a_PoisonHUD",
		x = scale * 110,
		y = height - scale * 64,
	}
end


-- Labels

do -- applyLabel
	local assets = {icon=".tga", model=".nif"}
	local qualities = {"exclusive", "quality", "fresh", "standard", "cheap", "bargain"}

	function this.applyLabel(potion)
		for asset, suffix in pairs(assets) do
			local current = potion[asset]:lower()
			for _, quality in pairs(qualities) do
				if current:find(quality) then
					local effect = potion.effects[1].id
					potion[asset] = "r0\\p\\" .. quality .. "_" .. effect .. suffix
					break
				end
			end
		end
	end
end


do -- clearLabel
	local assets = {
		icon = {
			bargain = "m\\tx_potion_bargain_01.tga",
			cheap = "m\\tx_potion_cheap_01.tga",
			exclusive = "m\\tx_potion_exclusive_01.tga",
			fresh = "m\\tx_potion_fresh_01.tga",
			quality = "m\\tx_potion_quality_01.tga",
			standard = "m\\tx_potion_standard_01.tga",
		},
		model = {
			bargain = "m\\misc_potion_bargain_01.nif",
			cheap = "m\\misc_potion_cheap_01.nif",
			exclusive = "m\\misc_potion_exclusive_01.nif",
			fresh = "m\\misc_potion_fresh_01.nif",
			quality = "m\\misc_potion_quality_01.nif",
			standard = "m\\misc_potion_standard_01.nif",
		},
	}
	function this.clearLabel(potion)
		for asset, qualities in pairs(assets) do
			local current = potion[asset]:lower()
			for quality, filename in pairs(qualities) do
				if current:find(quality) then
					potion[asset] = filename
					break
				end
			end
		end
	end
end


function this.loadLabels()
	local useLabels = this.config.useLabels

	for potion in tes3.iterateObjects(tes3.objectType.alchemy) do
		local isLabelled = (
			potion.model:lower():find("^r0\\p\\")
			and potion.icon:lower():find("^r0\\p\\")
		)
		if not useLabels and isLabelled then
			this.clearLabel(potion)
		elseif useLabels and not isLabelled then
			this.applyLabel(potion)
		end
	end
end


-- Compatibility

function this.confirmMCP()
	-- Confirm that some required MCP features are enabled.

	local labelFix = tes3.hasCodePatchFeature(145)
	local usageFix = tes3.hasCodePatchFeature(166)
	if (labelFix and usageFix) then
		return
	end

	local function warning()
		tes3.messageBox{
			message = (
				"mwse_PoisonCrafting.esp\n\n"
				.."The required MCP features for this mod are not enabled!\n\n"
				.."Please enable the following:\n\n"
				.."Game mechanics -> Quality-based potion icons/models\n\n"
				.."Mod specific -> Scriptable potion use"
			),
			buttons = {"Ok"},
		}
	end

	event.register("menuEnter", warning, {doOnce = true})
end


function this.equip(args)
	-- compatibility for controlled consumption
	-- prevents enemy poisons causing cooldowns
	local cc = include("nc.consume.interop")

	if not cc then
		-- controlled consumption not installed
		this.equip = mwscript.equip
	else
		-- bypass controlled consumption checks
		function this.equip(args)
			local bool = cc.skipNextConsumptionCheck
			cc.skipNextConsumptionCheck = true
			mwscript.equip(args)
			cc.skipNextConsumptionCheck = bool
		end
		print("[g7a] Controlled Consumption Detected")
	end

	this.equip(args)
end


-- Menus

local parent = nil

do -- genericMenu
	local function resolve(x)
		return type(x) == "function" and x() or x
	end

	function this.genericMenu(t)

		function t.callback(e)
			local action = (
				t.actions[e.button+1]
				or this.configMain
			)
			action()
		end

		function t.menu()
			parent = t.menu
			tes3.messageBox{
				message = resolve(t.message),
				buttons = resolve(t.buttons),
				callback = t.callback,
			}
		end

		return t.menu
	end
end

do -- booleanMenu
	local bool = {[0]=false, true}

	local buttons = {
		[false] = {"Disable (Current)", "Enable", "Back"},
		[true]  = {"Disable", "Enable (Current)", "Back"},
	}

	function this.booleanMenu(t)

		function t.callback(e)
			if e.button == 2 then
				parent()
			else
				this.config[t.setting] = bool[e.button]
				t.menu()
			end
		end

		function t.menu()
			tes3.messageBox{
				message = t.message,
				buttons = buttons[this.config[t.setting]],
				callback = t.callback,
			}
		end

		return t.menu
	end
end

do -- hotkey info
	local buttons = {
		[-1]  = {"Alt", "Shift", "Control", "Back"},
		[18]  = {"Alt (Current)", "Shift", "Control", "Back"},
		[160] = {"Alt", "Shift (Current)", "Control", "Back"},
		[162] = {"Alt", "Shift", "Control (Current)", "Back"},
	}
	function this.getHotkeyButtons()
		local b = buttons[this.config.poisonHotkey]
		return b or buttons[-1]
	end

	this.getHotkeyActions = {}
	for i, v in pairs{18, 160, 162} do
		this.getHotkeyActions[i] = (
			function()
				this.config.poisonHotkey = v
				this.configHotkey()
			end
		)
	end
end


this.configLabels = this.booleanMenu{
	message = (
		"This feature implements labeled icons and models for alchemical potions.\n\n"
		.."You will need to save and restart your game for changes to take effect."
	),
	setting = "useLabels",
}


this.configRecovery = this.booleanMenu{
	message = "This feature allows a poison to be recovered by unequipping all weapons.",
	setting = "usePoisonRecovery",
}


this.configBaseStats = this.booleanMenu{
	message = (
		"This feature forces the alchemy system to use the player's base attributes"
		.." and skills, rather than their drained or fortified values."
	),
	setting = "useBaseStats",
}


this.configBonusProgress = this.booleanMenu{
	message = (
		"This feature grants additional alchemy skill progress dependent on the number"
		.." of magic effects in a created potion. For each effect beyond the first, your"
		.." progress gained will be increased by an additional 10 percent."
	),
	setting = "useBonusProgress",
}


this.configReadyPoison = this.booleanMenu{
	message = "The 'Ready Poison' menu appears when equipping a poison.",
	setting = "msgReadyPoison",
}


this.configPoisonApplied = this.booleanMenu{
	message = "The 'Poison Applied' message appears when you successfully poison an enemy.",
	setting = "msgPoisonApplied",
}


this.configMessageBoxes = this.genericMenu{
	message = (
		"These settings allows you to toggle whether messagebox popups are created when"
		.." using certain features of the mod. Select the messagebox you want to modify."
	),
	buttons = {
		"Ready Poison",
		"Poison Applied",
		"Back"
	},
	actions = {
		this.configReadyPoison,
		this.configPoisonApplied,
	},
}


this.configHotkey = this.genericMenu{
	message = "Select the desired modifier key for poison usage.",
	buttons = this.getHotkeyButtons,
	actions = this.getHotkeyActions,
}


this.configMain = this.genericMenu{
	message = "What do you want to adjust?",
	buttons = {
		"Poison Hotkey",
		"Poison Recovery",
		"Alchemy Labels",
		"Alchemy Exploit Fix",
		"Alchemy Bonus Progress",
		"Messagebox Settings",
		"Close",
	},
	actions = {
		this.configHotkey,
		this.configRecovery,
		this.configLabels,
		this.configBaseStats,
		this.configBonusProgress,
		this.configMessageBoxes,
		this.saveConfig,
	},
}


-- Events

function this.onLoaded(e)
	-- ensure data table exists
	local data = tes3.getPlayerRef().data
	data.g7a = data.g7a or {}

	-- also do projectile table
	data.g7a.projectiles = data.g7a.projectiles or {}

	-- create a public shortcut
	this.data = data.g7a
end


function this.register()
	event.register("loaded", this.onLoaded)
end


return this
