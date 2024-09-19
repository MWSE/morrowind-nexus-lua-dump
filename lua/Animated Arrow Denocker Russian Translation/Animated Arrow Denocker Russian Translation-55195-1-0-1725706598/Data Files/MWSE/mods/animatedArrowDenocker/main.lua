local i18n = mwse.loadTranslations("animatedArrowDenocker")
local versionString = "1.0"

local configId = "Animated Arrow Denocker"
local configDefault = {
	instant = true,
}
local config = mwse.loadConfig(configId, configDefault)

local key = tes3.scanCode.f --workaround for keybindTest not working for me
local bind	--attack keybind
local shouldDenock = false
local maxTime = 310.33 - 309.0 --hardcoded animation time based on the "BowAndArrow: Shoot Start" and "BowAndArrow: Shoot Max Attack" keys.
local drawTime --store the start time of the bow draw so we know how long the animation should reverse for.

if tes3.hasCodePatchFeature(tes3.codePatchFeature.arrowDenocker) then
---@diagnostic disable-next-line: undefined-field
	mwse.memory.writeNoOperation{ address = 0x56954C, length = 5 }
	mwse.log("[Arrow Denocker] Disabling MCP de-nock patch.")
end

local function watchInput()
	local input = tes3.worldController.inputController
	if input:isKeyPressedThisFrame(key) then
		--force the attack to release by telling the button that it's not pressed.
		if bind.device == 1 then
			input.mouseState.buttons[bind.code + 1] = 0
		elseif bind.device == 0 then
			input.keyboardState[bind.code + 1] = 0
		end

		shouldDenock = true
		event.unregister(tes3.event.simulate, watchInput)
	end
end

--- @param e attackStartEventData
local function drawBow(e)
	drawTime = tes3.worldController.systemTime
	key = tes3.getInputBinding(tes3.keybind.readyWeapon).code
	bind = tes3.getInputBinding(tes3.keybind.use)

	if config.instant then
		event.register(tes3.event.simulate, watchInput)
	end
end
---@diagnostic disable-next-line: assign-type-mismatch
event.register(tes3.event.attackStart, drawBow, {filter = tes3.player})

local function denockBow()
	if tes3.mobilePlayer.actionData.nockedProjectile then
		tes3.mobilePlayer.animationController.weaponSpeed = -tes3.mobilePlayer.animationController.weaponSpeed
		local diff = (tes3.worldController.systemTime - drawTime) / 1000
		local time = math.min(diff, maxTime)
		timer.start{duration = time, callback = function()
			tes3.mobilePlayer.actionData.animationAttackState = tes3.animationState.idle
			tes3.mobilePlayer.animationController.weaponSpeed = 1
		end}
		-- have this remove slightly earlier to avoid jank when moving and denocking.
		timer.start{duration = math.max(0, time - 0.2), callback = function()
			tes3.mobilePlayer.actionData.nockedProjectile = nil
		end}
	end

	shouldDenock = false
end

--- @param e attackEventData
local function onAttack(e)
	if config.instant then
		event.unregister(tes3.event.simulate, watchInput)
	end

	if shouldDenock or tes3.worldController.inputController:isKeyDown(key) then
		denockBow()
	end
end
---@diagnostic disable-next-line: assign-type-mismatch
event.register(tes3.event.attack, onAttack, {filter = tes3.player})

local mcm = {}
function mcm.onCreate(parent)
	local pane = parent:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
	pane.flowDirection = tes3.flowDirection.topToBottom
	mcm.pane = pane

	local header = pane:createLabel{ text = "Анимированное снятие с тетивы\nВерсия " .. versionString }
	header.color = tes3ui.getPalette(tes3.palette.headerColor)
	header.borderBottom = 12

	local summary = pane:createLabel{ text = i18n("Description") }
	summary.widthProportional = 1.0
	summary.wrapText = true
	summary.borderBottom = 24

	mwse.mcm.createOnOffButton(pane, {
		class = "OnOffButton",
		label = i18n("Instant"),
		variable = mwse.mcm.createTableVariable{
			class = "TableVariable",
			table = config,
			id = "instant",
			defaultSetting = true
		}
	})

	local desc = pane:createLabel{ text = i18n("InstantDescription") }
	desc.widthProportional = 1.0
	desc.wrapText = true
	desc.borderBottom = 24

	if tes3.hasCodePatchFeature(tes3.codePatchFeature.arrowDenocker) then
		local patch = pane:createLabel{ text = i18n("MCPPatch") }
		patch.widthProportional = 1.0
		patch.wrapText = true
		patch.color = tes3ui.getPalette(tes3.palette.healthNpcColor)
	end

	parent:updateLayout()

	mwse.log("[Animated Arrow Denocker] " .. versionString .. " loaded successfully.")
end

function mcm.onClose(container)
	mwse.saveConfig(configId, config)
end

local function registerModConfig()
	mwse.registerModConfig("Анимированное снятие с тетивы", mcm)
end
event.register(tes3.event.modConfigReady, registerModConfig)