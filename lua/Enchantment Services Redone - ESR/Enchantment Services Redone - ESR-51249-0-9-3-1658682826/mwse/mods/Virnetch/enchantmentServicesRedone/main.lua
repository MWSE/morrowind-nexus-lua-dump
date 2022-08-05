
local common = require("Virnetch.enchantmentServicesRedone.common")

if mwse.buildDate == nil or mwse.buildDate < 20220509 then
    common.log:error("Build date of %s does not meet minimum build date of 20220509.", mwse.buildDate)
	event.register(tes3.event.initialized, function()
		tes3.messageBox(common.i18n("mod.updateRequired"))
	end)
    return
end

event.register(tes3.event.modConfigReady, function()
	require("Virnetch.enchantmentServicesRedone.mcm")
end)

local function onLoaded()
	local data = tes3.player.data

	data.esr = data.esr or {
		temporaryObjects = {
			[tostring(tes3.objectType.book)] = {},
			[tostring(tes3.objectType.enchantment)] = {}
		},
		transcriptions = {},
		decipheredScrolls = {}
	}

	--- @type esrSavedData
	common.savedData = data.esr
end

local function onInitialized()
	if not common.config.modEnabled then
		common.log:info("Disabled")
		return
	end

	if common.config.changePassiveRecharge then
		tes3.findGMST(tes3.gmst.fMagicItemRechargePerSecond).value = common.config.passiveRecharge/1000
	end

	require("Virnetch.enchantmentServicesRedone.services.services")
	require("Virnetch.enchantmentServicesRedone.items.additions")

	-- Add player transcription
	if (
		common.config.transcription.enablePlayer ~= false
		and common.config.transcription.enable ~= false
	) then
		require("Virnetch.enchantmentServicesRedone.services.transcription.player")
	end

	event.register(tes3.event.loaded, onLoaded)

	common.log:info("Initialized version %s", common.mod.version)
end
event.register(tes3.event.initialized, onInitialized)

if common.config.modEnabled then
	-- Add console commands to UI Expansion console
	event.register("UIEXP:sandboxConsole", function(e)
		e.sandbox.esr = {
			common = common,
			-- objectCreator = require("Virnetch.enchantmentServicesRedone.objects.objectCreator")
			-- services = require("Virnetch.enchantmentServicesRedone.services.services"),
		}
	end)
end

