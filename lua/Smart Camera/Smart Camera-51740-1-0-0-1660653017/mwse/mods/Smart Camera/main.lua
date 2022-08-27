-- Configuration
local modName = "Smart Camera"
local modVersion = "v. 1.0"

local defaultConfig = {
	enable = true,
	interior = true,
	weapon = true,
	sneak = true,
	swim = true,
	fly = true,
	fall = true,
	door = true,
	npc = true,
	container = true,
	organic = true,
	misc = true,
	roadsign = true,
	delayTime = 10,
	manual = true,
	interiors = {},
	exteriors = {
		["Vivec, Foreign Quarter Plaza"] = true,
		["Vivec, St. Olms Plaza"] = true,
		["Vivec, Telvanni Plaza"] = true,
		["Vivec, Hlaalu Plaza"] = true,
		["Vivec, St. Delyn Plaza"] = true,
		["Ald-ruhn, Manor District"] = true,
		["Mournhold, Plaza Brindisi Dorom"] = true,
		["Vivec, Redoran Plaza"] = true,
	},
	debug = false,
}

-- Misc objects
local miscObjects = {
	[tes3.objectType.alchemy] = true,
	[tes3.objectType.ammunition] = true,
	[tes3.objectType.apparatus] = true,
	[tes3.objectType.armor] = true,
	[tes3.objectType.book] = true,
	[tes3.objectType.clothing] = true,
	[tes3.objectType.ingredient] = true,
	[tes3.objectType.leveledItem] = true,
	[tes3.objectType.lockpick] = true,
	[tes3.objectType.miscItem] = true,
	[tes3.objectType.probe] = true,
	[tes3.objectType.repairItem] = true,
	[tes3.objectType.weapon] = true,
}

-- Road signs
local roadSigns = {
	"^active_sign_", -- Vanilla
	"^T_Com_Set%a%a%a?_SignWay", -- Tamriel Data
	"^STS_sign", -- Swappable Texture Signposts
}

local config = mwse.loadConfig(modName, defaultConfig) or defaultConfig

local delay = 0
local sneak = nil
local swim = nil
local fly = nil
local fall = nil

-- Support functions
local function isRoadSign(item)
	for _, v in pairs(roadSigns) do
		if item:match(v) then
			return true
		end
	end
	return false
end

local function isMiscObject(item)
	if miscObjects[item] ~= nil then
		return true
	else
		return false
	end
end

local function isInteriorName(name)
	if config.interiors[name] ~= nil then
		return true
	else
		return false
	end
end

local function isExteriorName(name)
	if config.exteriors[name] ~= nil then
		return true
	else
		return false
	end
end

local function debug(message, ...)
	if config.debug then
		local output = string.format("[%s] %s", modName, tostring(message):format(...))
		mwse.log(output)
	end
end

local function isInteriorCell(cell)
	if isInteriorName(cell.name) then
		debug("Info: Cell '%s' match configured interiors", cell.name)
		return true
	elseif isExteriorName(cell.name) then
		debug("Info: Cell '%s' match configured exteriors", cell.name)
		return false
	else
		if cell.isOrBehavesAsExterior then
			debug("Info: Cell '%s' is or behaves as exterior", cell.name)
			return false
		else
			debug("Info: Cell '%s' is interior", cell.name)
			return true
		end
	end
end

-- Switch view
local function to1stPersonView()
	if tes3.is3rdPerson() then
		debug("Action: Switch to 1st person view")
		tes3.force1stPerson()
	else
		debug("Nothing: Already in 1st person view")
	end
end

local function to3rdPersonView()
	if not tes3.is3rdPerson() then
		debug("Action: Switch to 3rd person view")
		tes3.force3rdPerson()
	else
		debug("Nothing: Already in 3rd person")
	end
end

-- Delayed restore
local function delayedRestore()
	debug("Action: Delayed restore pended")
	delay = config.delayTime / 10
end

local function cancelDelayedRestore()
	debug("Action: Delayed restore canceled")
	delay = -1
end

-- Change camera view
local function changePersonView()
	local current = tes3.getPlayerTarget()
	if current then
		-- Door targeted
		if config.door and (current.object.objectType == tes3.objectType.door or string.find(current.object.name, '[Dd]oor')) then
			debug("State: Door targeted")
			to1stPersonView()
			return
		end
		-- NPC targeted
		if config.npc and current.object.objectType == tes3.objectType.npc and current.mobile.fight < 82 and
		current.mobile.health.current > 0 then
			debug("State: NPC targeted")
			to1stPersonView()
			return
		end
		-- Container targeted
		if config.container and current.object.objectType == tes3.objectType.container and not current.object.organic then
			debug("State: Container targeted")
			to1stPersonView()
			return
		end
		-- Organic targeted
		if config.organic and current.object.objectType == tes3.objectType.container and current.object.organic then
			debug("State: Organic targeted")
			to1stPersonView()
			return
		end
		-- Misc targeted
		if config.misc and isMiscObject(current.object.objectType) then
			debug("State: Misc targeted")
			to1stPersonView()
			return
		end
		-- Road sign targeted
		if config.roadsign and current.object.objectType == tes3.objectType.activator and isRoadSign(current.object.id) then
			debug("State: Road sign targeted")
			to1stPersonView()
			return
		end
	end
	-- Sneak
	if config.sneak and tes3.mobilePlayer.isSneaking then
		debug("State: Sneaking")
		to1stPersonView()
		return
	end
	-- Swim
	if config.swim and tes3.mobilePlayer.isSwimming then
		debug("State: Swimming")
		to1stPersonView()
		return
	end
	-- Fly
	if config.fly and tes3.mobilePlayer.isFlying then
		debug("State: Flying")
		to1stPersonView()
		return
	end
	-- Fall
	if config.fall and tes3.mobilePlayer.isFalling and not tes3.mobilePlayer.isJumping then
		debug("State: Falling")
		to1stPersonView()
		return
	end
	-- Weapon
	if config.weapon and tes3.mobilePlayer.weaponReady then
		debug("State: Weapon ready")
		to1stPersonView()
		return
	end
	-- Cell
	if config.interior then
		if isInteriorCell(tes3.mobilePlayer.cell) then
			debug("State: Interior")
			if config.manual and tes3.player.data.preferExteriorInInterior then
				debug("State: Prefer reversed")
				to3rdPersonView()
				return
			end
			to1stPersonView()
			return
		else
			debug("State: Exterior")
			if config.manual and tes3.player.data.preferInteriorInExterior then
				debug("State: Prefer reversed")
				to1stPersonView()
				return
			end
			to3rdPersonView()
			return
		end
	end
end

local function targetSomething()
	cancelDelayedRestore()
	changePersonView()
end

local function untargetSomething(previous)
	if not previous then
		return
	end
	-- Door untargeted
	if config.door and (previous.object.objectType == tes3.objectType.door or string.find(previous.object.name, '[Dd]oor')) then
		debug("State: Door untargeted")
		delayedRestore()
		return
	end
	-- NPC untargeted
	if config.npc and previous.object.objectType == tes3.objectType.npc and previous.mobile.fight < 82 and
	previous.mobile.health.current > 0 then
		debug("State: NPC untargeted")
		delayedRestore()
		return
	end
	-- Container untargeted
	if config.container and previous.object.objectType == tes3.objectType.container and not previous.object.organic then
		debug("State: Container untargeted")
		delayedRestore()
		return
	end
	-- Organic untargeted
	if config.organic and previous.object.objectType == tes3.objectType.container and previous.object.organic then
		debug("State: Organic untargeted")
		delayedRestore()
		return
	end
	-- Misc untargeted
	if config.misc and isMiscObject(previous.object.objectType) then
		debug("State: Misc untargeted")
		delayedRestore()
		return
	end
	-- Road sign untargeted
	if config.roadsign and previous.object.objectType == tes3.objectType.activator and isRoadSign(previous.object.id) then
		debug("State: Road sign untargeted")
		delayedRestore()
		return
	end
end

-- Delayed restore event
local function onDelayedRestore(e)
	if not config.enable then
		return
	end
	if delay <= 0 then
		return
	end
	delay = delay - e.delta
	if delay <= 0 then
		debug("Event: Delayed restore")
		changePersonView()
	end
end

-- Target changed event
local function onActivationTargetChanged(e)
	if not config.enable then
		return
	end
	debug("Event: Target changed")
	if e.current then
		targetSomething()
	else
		untargetSomething(e.previous)
	end
end

-- Cell changed event
local function onCellChanged(e)
	if not config.enable then
		return
	end
	debug("Event: Cell changed")
	changePersonView()
end

-- Weapon's events
local function onWeaponReadied(e)
	if not config.enable then
		return
	end
	debug("Event: Weapon readied")
	changePersonView()
end

local function onWeaponUnreadied(e)
	if not config.enable then
		return
	end
	debug("Event: Weapon unreadied")
	changePersonView()
end

-- Sneaking event
local function onSneak(e)
	if not config.enable then
		return
	end
	if sneak == false and tes3.mobilePlayer.isSneaking then
		debug("Event: Sneak detected")
		changePersonView()
	end
	if sneak == true and not tes3.mobilePlayer.isSneaking then
		debug("Event: Sneak complete")
		changePersonView()
	end
	sneak = tes3.mobilePlayer.isSneaking
end

-- Swimming event
local function onSwim(e)
	if not config.enable then
		return
	end
	if swim == false and tes3.mobilePlayer.isSwimming then
		debug("Event: Swim detected")
		changePersonView()
	end
	if swim == true and not tes3.mobilePlayer.isSwimming then
		debug("Event: Swim complete")
		changePersonView()
	end
	swim = tes3.mobilePlayer.isSwimming
end

-- Flying event
local function onFly(e)
	if not config.enable then
		return
	end
	if fly == false and tes3.mobilePlayer.isFlying then
		debug("Event: Fly detected")
		changePersonView()
	end
	if fly == true and not tes3.mobilePlayer.isFlying then
		debug("Event: Fly complete")
		changePersonView()
	end
	fly = tes3.mobilePlayer.isFlying
end

-- Falling event
local function onFall(e)
	if not config.enable then
		return
	end
	if fall == false and tes3.mobilePlayer.isFalling and not tes3.mobilePlayer.isJumping then
		debug("Event: Fall detected")
		changePersonView()
	end
	if fall == true and not tes3.mobilePlayer.isFalling then
		debug("Event: Fall complete")
		changePersonView()
	end
	fall = tes3.mobilePlayer.isFalling
end

-- Manual change event
local function onManualChange(e)
	if not config.manual then
		return
	end
	if e.transition ~= tes3.keyTransition.up then
		return
	end
	if not e.result then
		return
	end
	-- mwse.log("H4")
	-- if tes3ui.menuMode then
	-- 	return
	-- end
	-- mwse.log("H5")
	-- if tes3.mobilePlayer.viewSwitchDisabled then
	-- 	return
	-- end
	debug("Event: Manual camera switch")
	if isInteriorCell(tes3.mobilePlayer.cell) then
		-- interior
		if tes3.mobilePlayer.is3rdPerson then
			-- prefer 1st person
			debug("Info: Prefer 1st person view in interiors")
			tes3.player.data.preferExteriorInInterior = false
		else
			-- prefer 3rd person
			debug("Info: Prefer 3rd person view in interiors")
			tes3.player.data.preferExteriorInInterior = true
		end
	else
		-- exterior
		if tes3.mobilePlayer.is3rdPerson then
			-- prefer 1st person
			debug("Info: Prefer 1st person view in exteriors")
			tes3.player.data.preferInteriorInExterior = true
		else
			-- prefer 3rd person
			debug("Info: Prefer 3rd person view in exteriors")
			tes3.player.data.preferInteriorInExterior = false
		end
	end
end

-- Initialization
local function initialized()
	event.register(tes3.event.simulate, onDelayedRestore)
	event.register(tes3.event.activationTargetChanged, onActivationTargetChanged)
	event.register(tes3.event.simulate, onSneak)
	event.register(tes3.event.simulate, onSwim)
	event.register(tes3.event.simulate, onFly)
	event.register(tes3.event.simulate, onFall)
	event.register(tes3.event.weaponReadied, onWeaponReadied)
	event.register(tes3.event.weaponUnreadied, onWeaponUnreadied)
	event.register(tes3.event.cellChanged, onCellChanged)
	event.register(tes3.event.keybindTested, onManualChange, { filter = tes3.keybind.togglePOV })
	mwse.log(modName .. " " .. modVersion .. " initialized")
end

event.register(tes3.event.initialized, initialized)

-- Smart Camera Configuration
local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable { id = varId, table = config }
end

local cells = require("Smart Camera.cells")
local function getCells()
	return cells
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(modName)
	template.onClose = function()
		mwse.saveConfig(modName, config, { indent = false })
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label = "General",
		postCreate = function(self)
			self.elements.sideToSideBlock.children[1].widthProportional = 1.4
			self.elements.sideToSideBlock.children[2].widthProportional = 0.6
		end,
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{ text = "" }

	-- General preferences
	local general = preferences:createCategory{ label = modName .. " " .. modVersion }
	general:createYesNoButton{
		label = "Enabled",
		variable = createConfigVariable("enable"),
		description = [[Default: Yes.]],
	}
	general:createYesNoButton{
		label = "Remember manually selected camera view for interiors and exteriors",
		variable = createConfigVariable("manual"),
		description = [[Default: Yes.]],
	}
	general:createSlider{
		label = "Delay before restore person view, when applicable (tenths of a second)",
		variable = createConfigVariable("delayTime"),
		min = 5,
		max = 30,
		step = 1,
		jump = 1,
		description = [[Default: 10, i.e. 1 sec]],
	}

	-- State preferences
	local cameraMain = preferences:createCategory{ label = "Change camera view when" }
	cameraMain:createYesNoButton{
		label = "Enter/Leave interiors",
		variable = createConfigVariable("interior"),
		description = [[Default: Yes.]],
	}
	cameraMain:createYesNoButton{
		label = "Ready/Hide weapon",
		variable = createConfigVariable("weapon"),
		description = [[Default: Yes.]],
	}
	cameraMain:createYesNoButton{
		label = "Sneaking",
		variable = createConfigVariable("sneak"),
		description = [[Default: Yes.]],
	}
	cameraMain:createYesNoButton{
		label = "Swimming",
		variable = createConfigVariable("swim"),
		description = [[Default: Yes.]],
	}
	cameraMain:createYesNoButton{ label = "Flying", variable = createConfigVariable("fly"),
                               description = [[Default: Yes.]] }
	cameraMain:createYesNoButton{
		label = "Falling",
		variable = createConfigVariable("fall"),
		description = [[Default: Yes.]],
	}

	-- Target preferences
	local cameraTarget = preferences:createCategory{ label = "Change camera view when target/untarget" }
	cameraTarget:createYesNoButton{
		label = "Doors",
		variable = createConfigVariable("door"),
		description = [[Default: Yes.]],
	}
	cameraTarget:createYesNoButton{ label = "NPCs", variable = createConfigVariable("npc"),
                                 description = [[Default: Yes.]] }
	cameraTarget:createYesNoButton{
		label = "Containers",
		variable = createConfigVariable("container"),
		description = [[Default: Yes.]],
	}
	cameraTarget:createYesNoButton{
		label = "Organics",
		variable = createConfigVariable("organic"),
		description = [[Default: Yes.]],
	}
	cameraTarget:createYesNoButton{
		label = "Road signs",
		variable = createConfigVariable("roadsign"),
		description = [[Default: Yes.]],
	}
	cameraTarget:createYesNoButton{
		label = "Other items",
		variable = createConfigVariable("misc"),
		description = [[Default: Yes.]],
	}

	-- Development preferences
	local development = preferences:createCategory{ label = "Development options" }
	development:createYesNoButton{
		label = "Debug mode",
		variable = createConfigVariable("debug"),
		description = [[Default: No.]],
	}

	-- Interiors manual config
	template:createExclusionsPage{
		label = "Interiors",
		description = "Always treat specified cells as interiors when changing location",
		leftListLabel = "Interiors",
		rightListLabel = "Cells",
		variable = mwse.mcm.createTableVariable { id = "interiors", table = config },
		filters = { { callback = getCells } },
	}

	-- Exteriors manual config
	template:createExclusionsPage{
		label = "Exteriors",
		description = "Always treat specified cells as exteriors when changing location",
		leftListLabel = "Exteriors",
		rightListLabel = "Cells",
		variable = mwse.mcm.createTableVariable { id = "exteriors", table = config },
		filters = { { callback = getCells } },
	}

	mwse.mcm.register(template)
	logConfig(config, { indent = false })
end

event.register(tes3.event.modConfigReady, modConfigReady)
