--[[
	Mod: Steadicam
	Author: Hrnchamd
	Version: 1.1
]]--

local this = {}
local i18n = mwse.loadTranslations("hrnchamd.steadicam")

local versionString = "v1.1"

local configPath = "Steadicam"
local configDefault = {
	configVersion = 1,
	enabled = true,

	bodyInertia = true,
	bodyInertiaDamping = 20,

	freeLookKeybind	= {
		keyCode = tes3.scanCode.n,
		isShiftDown = false,
		isControlDown = false,
		isAltDown = false
	}
}

local presets = {
	default = {
		firstPersonLookDamping = 10,
		freeLookDamping = 60,
		thirdPersonLookDamping = 250,
		thirdPersonFollowDamping = 140
	},
	close = {
		firstPersonLookDamping = 2,
		freeLookDamping = 15,
		thirdPersonLookDamping = 50,
		thirdPersonFollowDamping = 80
	},
	smooth = {
		firstPersonLookDamping = 30,
		freeLookDamping = 150,
		thirdPersonLookDamping = 450,
		thirdPersonFollowDamping = 200
	},
	loose = {
		firstPersonLookDamping = 120,
		freeLookDamping = 250,
		thirdPersonLookDamping = 1000,
		thirdPersonFollowDamping = 300
	}
}

function this.registerModConfig()
	table.copy(presets.default, configDefault)
	table.copy(mwse.loadConfig(configPath, configDefault), this.config)

	local template = mwse.mcm.createTemplate("Steadicam")
	template.onClose = function()
		mwse.saveConfig(configPath, this.config)

		if this.sensitivityChanged then
			tes3.game:savePlayerOptions()
			this.sensitivityChanged = nil
		end
	end
	
	local refreshPage = function()
		local pageBlock = template.elements.pageBlock
		pageBlock:destroyChildren()
		template.currentPage:create(pageBlock)
	end

	local page = template:createSideBarPage{
		postCreate = function(self)
			local block = self.elements.sideToSideBlock
			block.children[1].widthProportional = 1.25
			block.children[2].widthProportional = 0.75
			block:getTopLevelMenu():updateLayout()
		end,
		sidebarComponents = {
			mwse.mcm.createInfo{ text = i18n("DefaultHelp") },
		},
		components = {
			{
				class = "Info",
				label = "Steadicam " .. versionString
			},
			{
				class = "Category",
				label = i18n("ModEnableToggle"),
				components = {
					{
						class = "OnOffButton",
						label = "",
						description = i18n("ModEnableToggleHelp"),
						variable = mwse.mcm:createTableVariable{ id = "enabled", table = this.config }
					}
				}
			},
			{
				class = "Category",
				label = i18n("CategoryPresets"),
				postCreate = function(self)
					local container = self.elements.subcomponentsContainer
					container.flowDirection = tes3.flowDirection.leftToRight
					container.autoWidth = true
					container.widthProportional = nil
				end,
				components = {
					{
						class = "Button",
						buttonText = i18n("PresetDefault"),
						description = i18n("PresetDefaultHelp"),
						callback = function(self)
							table.copy(presets.default, this.config)
							refreshPage()
						end
					},
					{
						class = "Button",
						buttonText = i18n("PresetClose"),
						description = i18n("PresetCloseHelp"),
						callback = function(self)
							table.copy(presets.close, this.config)
							refreshPage()
						end
					},
					{
						class = "Button",
						buttonText = i18n("PresetSmooth"),
						description = i18n("PresetSmoothHelp"),
						callback = function(self)
							table.copy(presets.smooth, this.config)
							refreshPage()
						end
					},
					{
						class = "Button",
						buttonText = i18n("PresetLoose"),
						description = i18n("PresetLooseHelp"),
						callback = function(self)
							table.copy(presets.loose, this.config)
							refreshPage()
						end
					}
				}
			},

			{
				class = "Category",
				label = i18n("CategoryCameraAngle"),
				components = {
					{
						class = "Slider",
						label = i18n("1PSmoothness"),
						description = i18n("1PSmoothnessHelp"),
						min = 1, max = 250, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "firstPersonLookDamping", table = this.config }
					},
					{
						class = "Slider",
						label = i18n("1PFreelookSmoothness"),
						description = i18n("1PFreelookSmoothnessHelp"),
						min = 1, max = 250, step = 1, jump = 10,
						variable = mwse.mcm:createTableVariable{ id = "freeLookDamping", table = this.config }
					},
					{
						class = "Slider",
						label = i18n("3PSmoothness"),
						description = i18n("3PSmoothnessHelp"),
						min = 1, max = 1000, step = 1, jump = 10,
						variable = mwse.mcm:createTableVariable{ id = "thirdPersonLookDamping", table = this.config }
					}
				}
			},

			{
				class = "Category",
				label = i18n("CategoryCameraTracking"),
				components = {
					{
						class = "Slider",
						label = i18n("3PMotionSmoothness"),
						description = i18n("3PMotionSmoothnessHelp"),
						min = 1, max = 400, step = 1, jump = 10,
						variable = mwse.mcm:createTableVariable{ id = "thirdPersonFollowDamping", table = this.config }
					}
				}
			},

			{
				class = "Category",
				label = i18n("CategoryBody"),
				components = {
					{
						class = "OnOffButton",
						label = i18n("BodyInertiaToggle"),
						description = i18n("BodyInertiaToggleHelp"),
						variable = mwse.mcm:createTableVariable{ id = "bodyInertia", table = this.config }
					},
					{
						class = "Slider",
						label = i18n("BodyInertiaSmoothness"),
						description = i18n("BodyInertiaSmoothnessHelp"),
						min = 10, max = 100, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "bodyInertiaDamping", table = this.config }
					}
				}
			},

			{
				class = "Category",
				label = i18n("CategoryControls"),
				components = {
					{
						class = "KeyBinder",
						label = i18n("KeybindToggleFreeLook"),
						description = i18n("KeybindToggleFreeLookHelp"),
						paddingBottom = 10,
						min = 1, max = 250, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{
							id = "freeLookKeybind",
							table = this.config,
							defaultSetting = { keyCode = tes3.scanCode.n }
						}
					},
					{
						class = "Slider",
						label = i18n("MouseHSensitivity"),
						description = i18n("MouseHSensitivityHelp"),
						min = 1, max = 500, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "proxySensitivityX", table = this },
						callback = function(e)
							tes3.worldController.mouseSensitivityX = 0.00001 * this.proxySensitivityX
							this.sensitivityChanged = true
						end
					},
					{
						class = "Slider",
						label = i18n("MouseVSensitivity"),
						description = i18n("MouseVSensitivityHelp"),
						min = 1, max = 500, step = 1, jump = 5,
						variable = mwse.mcm:createTableVariable{ id = "proxySensitivityY", table = this },
						callback = function(e)
							tes3.worldController.mouseSensitivityY = 0.00001 * this.proxySensitivityY
							this.sensitivityChanged = true
						end
					}
				}
			}
		}
	}

	this.proxySensitivityX = 100000 * tes3.worldController.mouseSensitivityX
	this.proxySensitivityY = 100000 * tes3.worldController.mouseSensitivityY

	template:register()
	mwse.log("[Steadicam] " .. versionString .. " loaded successfully.")
end

return this