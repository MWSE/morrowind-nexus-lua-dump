local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.common")


local buildModule = {}


function buildModule.buildChange(reference)
    --Initialize IDs
    buildModule.id_menu = tes3ui.registerID("kl_build_menu")
    buildModule.id_pane = tes3ui.registerID("kl_build_pane")
    buildModule.id_pane2 = tes3ui.registerID("kl_build_pane2")
    buildModule.id_input = tes3ui.registerID("kl_build_input")
    buildModule.id_ok = tes3ui.registerID("kl_build_ok")
	buildModule.id_image = tes3ui.registerID("kl_build_image")
    log = logger.getLogger("Companion Leveler")
    log:debug("Build menu initialized.")

    if (reference) then
            buildModule.reference = reference
    end

    if (tes3ui.findMenu(buildModule.id_menu) ~= nil) then
        return
    end
    log:debug("Build menu triggered.")
    -- Create window and frame
    local menu = tes3ui.createMenu{ id = buildModule.id_menu, fixedFrame = true }

    -- Create layout
	local name = reference.object.name
	local modData = func.getModData(reference)
    local input_label = menu:createLabel{ text = "Modify " .. name .. "'s Build:" }
    input_label.borderBottom = 32

	local text_block = menu:createBlock{ id = "text_block" }
	text_block.positionX = 10
	text_block.positionY = -146
	text_block.autoWidth = true
	text_block.autoHeight = true
	text_block.flowDirection = "left_to_right"

	local att_block = text_block:createBlock{}
	att_block.positionX = 4
	att_block.positionY = -4
	att_block.width = 103
	att_block.height = 200
	att_block.borderAllSides = 2
	att_block.flowDirection = "top_to_bottom"

    local kl_att = att_block:createLabel({ text = "Attributes:", id = "kl_att_build" })
	kl_att.color = {1.0, 1.0, 1.0}
    kl_att.borderBottom = 13
	for i = 0, 7 do
        local atts = att_block:createLabel{ text = "" .. tables.capitalization[i] .. " +", id = "aBuildL_" .. i .. "" }
        atts.borderBottom = 3
    end

    local Iatt_block = text_block:createBlock{}
	Iatt_block.positionX = 4
	Iatt_block.positionY = -4
	Iatt_block.width = 35
	Iatt_block.height = 190
	Iatt_block.borderTop = 31
    Iatt_block.borderRight = 1
	Iatt_block.flowDirection = "top_to_bottom"

    for i = 1, 8 do
        local bord = Iatt_block:createThinBorder({ id = "aBuildIbord_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.attMods[i] .. "", numeric = true, id = "aBuildI_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

    local mid_block = text_block:createBlock{}
	mid_block.positionX = 4
	mid_block.positionY = -4
	mid_block.width = 13
	mid_block.height = 190
	mid_block.borderTop = 31
    mid_block.borderRight = 1
	mid_block.flowDirection = "top_to_bottom"

    for i = 1, 8 do
        local mid = mid_block:createLabel({ text = "-" })
        mid.borderBottom = 3
    end

    local Iatt_block2 = text_block:createBlock{}
	Iatt_block2.positionX = 4
	Iatt_block2.positionY = -4
	Iatt_block2.width = 40
	Iatt_block2.height = 190
	Iatt_block2.borderTop = 31
    Iatt_block2.borderRight = 8
	Iatt_block2.flowDirection = "top_to_bottom"

    for i = 1, 8 do
        local bord = Iatt_block2:createThinBorder({ id = "aBuildIbordmax_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.attModsMax[i] .. "", numeric = true, id = "aBuildImax_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

	local combat_block = text_block:createBlock{}
	combat_block.positionX = 167
	combat_block.positionY = -4
	combat_block.width = 130
	combat_block.height = 218
	combat_block.borderAllSides = 2
	combat_block.flowDirection = "top_to_bottom"

    local kl_combat = combat_block:createLabel({ text = "Combat Skills:", id = "kl_combat_build" })
	kl_combat.color = {1.0, 1.0, 1.0}
    kl_combat.borderBottom = 13
	for i = 0, 8 do
        local skills = combat_block:createLabel{ text = "" .. tes3.skillName[i] .. " +", id = "sBuildL_" .. i .. "" }
        skills.borderBottom = 3
    end

    local Icombat_block = text_block:createBlock{}
	Icombat_block.positionX = 4
	Icombat_block.positionY = -4
	Icombat_block.width = 35
	Icombat_block.height = 190
	Icombat_block.borderTop = 32
    Icombat_block.borderRight = 1
	Icombat_block.flowDirection = "top_to_bottom"

    for i = 1, 9 do
        local bord = Icombat_block:createThinBorder({ id = "sBuildIbord_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.skillMods[i] .. "", numeric = true, id = "sBuildI_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

    local mid_block2 = text_block:createBlock{}
	mid_block2.positionX = 4
	mid_block2.positionY = -4
	mid_block2.width = 13
	mid_block2.height = 190
	mid_block2.borderTop = 31
    mid_block2.borderRight = 1
	mid_block2.flowDirection = "top_to_bottom"

    for i = 1, 9 do
        local mid = mid_block2:createLabel({ text = "-" })
        mid.borderBottom = 3
    end

    local Icombat_block2 = text_block:createBlock{}
	Icombat_block2.positionX = 4
	Icombat_block2.positionY = -4
	Icombat_block2.width = 40
	Icombat_block2.height = 190
	Icombat_block2.borderTop = 31
    Icombat_block2.borderRight = 8
	Icombat_block2.flowDirection = "top_to_bottom"

    for i = 1, 9 do
        local bord = Icombat_block2:createThinBorder({ id = "sBuildIbordmax_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.skillModsMax[i] .. "", numeric = true, id = "sBuildImax_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

	local magic_block = text_block:createBlock{}
	magic_block.positionX = 320
	magic_block.positionY = -4
	magic_block.width = 112
	magic_block.height = 218
	magic_block.borderAllSides = 2
	magic_block.flowDirection = "top_to_bottom"

    local kl_magic = magic_block:createLabel({ text = "Magic Skills:", id = "kl_magic_build" })
	kl_magic.color = {1.0, 1.0, 1.0}
    kl_magic.borderBottom = 13
	for i = 9, 17 do
        local skills = magic_block:createLabel{ text = "" .. tes3.skillName[i] .. " +", id = "sBuildL_" .. i .. "" }
        skills.borderBottom = 3
    end

    local Imagic_block = text_block:createBlock{}
	Imagic_block.positionX = 4
	Imagic_block.positionY = -4
	Imagic_block.width = 35
	Imagic_block.height = 190
	Imagic_block.borderTop = 32
    Imagic_block.borderRight = 1
	Imagic_block.flowDirection = "top_to_bottom"

    for i = 10, 18 do
        local bord = Imagic_block:createThinBorder({ id = "sBuildIbord_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.skillMods[i] .. "", numeric = true, id = "sBuildI_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

    local mid_block3 = text_block:createBlock{}
	mid_block3.positionX = 4
	mid_block3.positionY = -4
	mid_block3.width = 13
	mid_block3.height = 190
	mid_block3.borderTop = 31
    mid_block3.borderRight = 1
	mid_block3.flowDirection = "top_to_bottom"

    for i = 10, 18 do
        local mid = mid_block3:createLabel({ text = "-" })
        mid.borderBottom = 3
    end

    local Imagic_block2 = text_block:createBlock{}
	Imagic_block2.positionX = 4
	Imagic_block2.positionY = -4
	Imagic_block2.width = 40
	Imagic_block2.height = 190
	Imagic_block2.borderTop = 31
    Imagic_block2.borderRight = 8
	Imagic_block2.flowDirection = "top_to_bottom"

    for i = 10, 18 do
        local bord = Imagic_block2:createThinBorder({ id = "sBuildIbordmax_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.skillModsMax[i] .. "", numeric = true, id = "sBuildImax_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

    local stealth_block = text_block:createBlock{}
	stealth_block.positionX = 320
	stealth_block.positionY = -4
	stealth_block.width = 118
	stealth_block.height = 218
	stealth_block.borderAllSides = 2
	stealth_block.flowDirection = "top_to_bottom"

    local kl_stealth = stealth_block:createLabel({ text = "Stealth Skills:", id = "kl_stealth_build" })
	kl_stealth.color = {1.0, 1.0, 1.0}
    kl_stealth.borderBottom = 13
	for i = 18, 26 do
        local skills = stealth_block:createLabel{ text = "" .. tes3.skillName[i] .. " +", id = "sBuildL_" .. i .. "" }
        skills.borderBottom = 3
    end

    local Istealth_block = text_block:createBlock{}
	Istealth_block.positionX = 4
	Istealth_block.positionY = -4
	Istealth_block.width = 35
	Istealth_block.height = 190
	Istealth_block.borderTop = 32
    Istealth_block.borderRight = 1
	Istealth_block.flowDirection = "top_to_bottom"

    for i = 19, 27 do
        local bord = Istealth_block:createThinBorder({ id = "sBuildIbord_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.skillMods[i] .. "", numeric = true, id = "sBuildI_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

    local mid_block4 = text_block:createBlock{}
	mid_block4.positionX = 4
	mid_block4.positionY = -4
	mid_block4.width = 13
	mid_block4.height = 190
	mid_block4.borderTop = 31
    mid_block4.borderRight = 1
	mid_block4.flowDirection = "top_to_bottom"

    for i = 19, 27 do
        local mid = mid_block4:createLabel({ text = "-" })
        mid.borderBottom = 3
    end

    local Istealth_block2 = text_block:createBlock{}
	Istealth_block2.positionX = 4
	Istealth_block2.positionY = -4
	Istealth_block2.width = 40
	Istealth_block2.height = 190
	Istealth_block2.borderTop = 31
    Istealth_block2.borderRight = 8
	Istealth_block2.flowDirection = "top_to_bottom"

    for i = 19, 27 do
        local bord = Istealth_block2:createThinBorder({ id = "sBuildIbordmax_" .. i .. "" })
        bord.width = 30
        bord.height = 20
        bord.borderBottom = 1
        bord.paddingLeft = 2
        local input = bord:createTextInput({ text = "" .. modData.skillModsMax[i] .. "", numeric = true, id = "sBuildImax_" .. i .. "" })
        input.widget.lengthLimit = 3
        input.widget.eraseOnFirstKey = true
    end

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 1.0
    button_block.borderTop = 32

    local button_ok = button_block:createButton{ id = buildModule.id_ok, text = tes3.findGMST("sOK").value }

    -- Events
    menu:register(tes3.uiEvent.keyEnter, buildModule.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, buildModule.onOK)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(buildModule.id_menu)
end



function buildModule.onOK(e)
    local menu = tes3ui.findMenu(buildModule.id_menu)
    local modData = func.getModData(buildModule.reference)
    if (menu) then
        for i = 1, 8 do
            local txt = tonumber(menu:findChild("aBuildI_" .. i .. "").text)
            modData.attMods[i] = txt
            local txt2 = tonumber(menu:findChild("aBuildImax_" .. i .. "").text)
            modData.attModsMax[i] = txt2
        end
        for i = 1, 27 do
            local txt = tonumber(menu:findChild("sBuildI_" .. i .. "").text)
            modData.skillMods[i] = txt
            local txt2 = tonumber(menu:findChild("sBuildImax_" .. i .. "").text)
            modData.skillModsMax[i] = txt2
        end
        tes3ui.leaveMenuMode()
        menu:destroy()
        tes3.messageBox{ message = "" .. buildModule.reference.object.name .. "'s Build changed." }
    end
end


return buildModule