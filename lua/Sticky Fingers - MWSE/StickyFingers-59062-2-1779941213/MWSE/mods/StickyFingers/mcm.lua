local mod = require("StickyFingers.config")
local config = mod.config

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Sticky Fingers",
	})

	template:saveOnClose(mod.configPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Sticky Fingers adds ownership and stolen-item warnings to item, container, and bed tooltips.",
	})

	-- ============================================================
	-- Main
	-- ============================================================

	page:createYesNoButton({
		label = "Enable Sticky Fingers",
		description = "When enabled, Sticky Fingers adds extra ownership and stolen-item information to supported tooltips.",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	-- ============================================================
	-- Item Ownership
	-- ============================================================

	page:createYesNoButton({
		label = "Show item owner",
		description = "When enabled, owned loose items will show who owns them.",
		variable = mwse.mcm.createTableVariable({
			id = "showItemOwnerName",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Show item status",
		description = "When enabled, owned loose items will show whether taking them is allowed or theft.",
		variable = mwse.mcm.createTableVariable({
			id = "showItemStatus",
			table = config,
		}),
	})

	-- ============================================================
	-- Container Ownership
	-- ============================================================

	page:createYesNoButton({
		label = "Show container owner",
		description = "When enabled, owned containers will show who owns them.",
		variable = mwse.mcm.createTableVariable({
			id = "showContainerOwnerName",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Show container status",
		description = "When enabled, owned containers will show whether taking items from them is allowed or theft.",
		variable = mwse.mcm.createTableVariable({
			id = "showContainerStatus",
			table = config,
		}),
	})

	-- ============================================================
	-- Bed Ownership
	-- ============================================================

	page:createYesNoButton({
		label = "Show bed owner",
		description = "When enabled, owned beds, bedrolls, and hammocks will show who owns them.",
		variable = mwse.mcm.createTableVariable({
			id = "showBedOwnerName",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Show bed status",
		description = "When enabled, owned beds, bedrolls, and hammocks will show whether sleeping there is allowed or trespassing.",
		variable = mwse.mcm.createTableVariable({
			id = "showBedStatus",
			table = config,
		}),
	})

	-- ============================================================
	-- Stolen Status
	-- ============================================================

	page:createYesNoButton({
		label = "Show stolen status",
		description = "When enabled, items already marked as stolen will show a stolen warning.",
		variable = mwse.mcm.createTableVariable({
			id = "showStolenStatus",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Show stolen-from name",
		description = "When enabled, stolen items will try to show who the item was stolen from.",
		variable = mwse.mcm.createTableVariable({
			id = "showStolenFromName",
			table = config,
		}),
	})

	-- ============================================================
	-- Display
	-- ============================================================

	page:createYesNoButton({
		label = "Show colors",
		description = "When enabled, important words like theft, trespassing, stolen, allowed, and access will use colored text.",
		variable = mwse.mcm.createTableVariable({
			id = "showColors",
			table = config,
		}),
	})

	-- ============================================================
	-- Debug
	-- ============================================================

	page:createYesNoButton({
		label = "Debug logging",
		description = "Writes extra Sticky Fingers information to MWSE.log. Useful while testing owner and stolen-item detection.",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config,
		}),
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)