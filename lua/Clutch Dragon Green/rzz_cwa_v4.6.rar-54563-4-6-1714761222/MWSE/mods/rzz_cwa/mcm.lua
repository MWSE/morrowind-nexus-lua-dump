--ModConfig
--local configId = "Perfect Placement"
local this = {}

function this.onCreate(container)
	local pane = container:createThinBorder{}
	pane.layoutWidthFraction = 1.0
	pane.layoutHeightFraction = 1.0
	pane.paddingAllSides = 12
	pane.flowDirection = "top_to_bottom"

	local header = pane:createLabel{ text = i18n("mcm.title") .. "\n " .. i18n("mcm.version") .. " " .. string.format("%.1f",RZZ_Version) .. "\n " .. i18n("mcm.autor") .. " Borivit" }
	header.color = tes3ui.getPalette("header_color")
	header.borderBottom = 25

	-- Description and credits
	local txtBlock_1 = pane:createBlock()
	txtBlock_1.layoutWidthFraction = 1.0
	txtBlock_1.autoHeight = true
	txtBlock_1.borderBottom = 25

	local txt_1 = txtBlock_1:createLabel{}
	txt_1.layoutHeightFraction = 1.0
	txt_1.layoutWidthFraction = 1.0
	txt_1.wrapText = true
	txt_1.text = i18n("mcm.descripcion.txt")

	local txtBlock = pane:createBlock()
	txtBlock.layoutWidthFraction = 1.0
	txtBlock.autoHeight = true
	txtBlock.borderBottom = 25

	local txt = txtBlock:createLabel{}
	txt.layoutHeightFraction = 1.0
	txt.layoutWidthFraction = 1.0
	txt.wrapText = true
	txt.text = i18n("mcm.descripcion.title") .. i18n("mcm.descripcion.p1") .. i18n("mcm.descripcion.p2") .. i18n("mcm.descripcion.p3") .. i18n("mcm.descripcion.p4") .. i18n("mcm.descripcion.p5") .. i18n("mcm.descripcion.p6") .. i18n("mcm.descripcion.p7") .. i18n("mcm.descripcion.p8")
	
	pane:updateLayout()
end
--[[
function this.onClose(container)
	--mwse.saveConfig("pg_continue_config", config, { indent = true })

	if tes3.onMainMenu() then
		-- Make sure we update the credits button visiblity.
		local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
		local creditsButton = mainMenu:findChild(menu_credits_id)
		creditsButton.visible = not config.hideCredits
	end
end
--]]
return this
