local mod = "Seph's Guar Petting"
local version = "1.0.0"

local function logMessage(message)
	mwse.log("[" .. mod .. " " .. version .. "] " .. message)
end

local defaultConfig = {
	playSound = true,
	showMessage = false,
	message = "%s likes you.",
	sound = "guar moan",
	guars = {
		["guar"] = true,
		["guar_feral"] = true,
		["guar_hrmudcrabnest"] = true,
		["guar_llovyn_unique"] = true,
		["guar_pack"] = true,
		["guar_pack_tarvyn_unique"] = true,
		["guar_white_unique"] = true,
		["mr_guar_ald_rhun"] = true,
		["mr_guar_harness"] = true
	}
}

local config = mwse.loadConfig(mod, defaultConfig)

local function onKeyDown(e)
	if e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code then
		local target = tes3.getPlayerTarget()
		if target and target.object and target.baseObject then
			if (config.guars[target.baseObject.id:lower()] or config.guars[target.object.id:lower()]) and (not target.mobile or (target.mobile and not target.mobile.inCombat and not target.mobile.isDead)) then
				if config.showMessage then
					tes3.messageBox(config.message, target.baseObject.name)
				end
				if config.playSound then
					if target.mobile then
						tes3.playSound{reference = target, sound = config.sound}
					else
						tes3.playSound{reference = tes3.player, sound = config.sound}
					end
				end
			end
		end
	end
end

local function onInitialized(e)
	event.register("keyDown", onKeyDown)
    logMessage("Initialized")
end
event.register("initialized", onInitialized)

local function onModConfigReady(e)
    local template = mwse.mcm.createTemplate{ name = mod }
    template:saveOnClose(mod, config)
    template:register()

    local page = template:createSideBarPage("Settings")
    page.description = mod .. " " .. version .. "\n\nThis mod makes guars play sounds and optionally display messages when 'activated'."

    page:createYesNoButton{
        label = "Play sound?",
        description = "Default: Yes",
        variable = mwse.mcm.createTableVariable{id = "playSound", table = config, restartRequired = false}
    }
	
	page:createYesNoButton{
        label = "Show message?",
        description = "Default: No",
        variable = mwse.mcm.createTableVariable{id = "showMessage", table = config, restartRequired = false}
    }
	
	page:createTextField{
		label = "Message",
		description = "Default: %s likes you.",
		variable = mwse.mcm.createTableVariable{id = "message", table = config, restartRequired = false},
	}
	
	page:createTextField{
		label = "Sound",
		description = "Default: guar moan",
		variable = mwse.mcm.createTableVariable{id = "sound", table = config, restartRequired = false},
	}
	
	template:createExclusionsPage{
		label = "Data",
		description = "You can add anything that you'd like to count as guars from the right list to the left list.\nCould you let any item or even Fargoth make guar sounds when interacting with them through this?\nYes, you could, but why?",
		leftListLabel = "Guars",
        rightListLabel = "Available",
		variable = mwse.mcm:createTableVariable{id = "guars", table = config},
		filters = {
			{
				label = "Creatures",
				type = "Object",
				objectType = tes3.objectType.creature,
			},
			{
				label = "NPCs",
				type = "Object",
				objectType = tes3.objectType.npc,
			},
			{
				label = "Weapons",
				type = "Object",
				objectType = tes3.objectType.weapon,
			},
			{
				label = "Armor",
				type = "Object",
				objectType = tes3.objectType.armor,
			},
			{
				label = "Clothing",
				type = "Object",
				objectType = tes3.objectType.clothing,
			},
			{
				label = "Ammunition",
				type = "Object",
				objectType = tes3.objectType.ammunition,
			},
			{
				label = "Lockpicks",
				type = "Object",
				objectType = tes3.objectType.lockpick,
			},
			{
				label = "Probes",
				type = "Object",
				objectType = tes3.objectType.probe,
			},
			{
				label = "Repair Items",
				type = "Object",
				objectType = tes3.objectType.repairItem,
			},
			{
				label = "Apparatus",
				type = "Object",
				objectType = tes3.objectType.apparatus,
			},
			{
				label = "Alchemy",
				type = "Object",
				objectType = tes3.objectType.alchemy,
			},
			{
				label = "Ingredients",
				type = "Object",
				objectType = tes3.objectType.ingredient,
			},
			{
				label = "Lights",
				type = "Object",
				objectType = tes3.objectType.light,
			},
			{
				label = "Miscellaneous",
				type = "Object",
				objectType = tes3.objectType.miscItem,
			},
			{
				label = "Containers",
				type = "Object",
				objectType = tes3.objectType.container,
			},
			{
				label = "Doors",
				type = "Object",
				objectType = tes3.objectType.door,
			},
			{
				label = "Activators",
				type = "Object",
				objectType = tes3.objectType.activator,
			}
		}
	}
end
event.register("modConfigReady", onModConfigReady)