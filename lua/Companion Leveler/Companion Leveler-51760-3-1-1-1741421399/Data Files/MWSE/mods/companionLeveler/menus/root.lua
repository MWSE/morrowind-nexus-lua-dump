local config = require("companionLeveler.config")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local typeChange = require("companionLeveler.menus.typeChange")
local classChange = require("companionLeveler.menus.classChange")
local buildChange = require("companionLeveler.menus.buildChange")
local sheet = require("companionLeveler.menus.sheet")
local growth = require("companionLeveler.menus.growthSettings")
local tech = require("companionLeveler.menus.techniques.techniques")
local cast = require("companionLeveler.menus.cast")

local root = {}

function root.createWindow(reference)
    root.id_menu = tes3ui.registerID("kl_root_menu")
    root.id_label = tes3ui.registerID("kl_root_label")
    root.id_label2 = tes3ui.registerID("kl_root_label2")
    root.id_label3 = tes3ui.registerID("kl_root_label3")
    root.id_label4 = tes3ui.registerID("kl_root_label4")
    root.id_sheet = tes3ui.registerID("kl_root_sheet_btn")
    root.id_change = tes3ui.registerID("kl_root_change_btn")
    root.id_build = tes3ui.registerID("kl_root_build_btn")
    root.id_growth = tes3ui.registerID("kl_root_growth_btn")
    root.id_cast = tes3ui.registerID("kl_root_cast_btn")
    root.id_tech = tes3ui.registerID("kl_root_tech_btn")
    root.id_exp = tes3ui.registerID("kl_root_exp_bar")

    log = logger.getLogger("Companion Leveler")
    log:debug("Root menu initialized.")

    root.reference = reference
    --Check for version update
    func.updateModData(reference)

    local menu = tes3ui.createMenu { id = root.id_menu, fixedFrame = true }
    local modData = func.getModData(reference)
    local class

    if reference.object.objectType ~= tes3.objectType.creature and modData.metamorph == false then
        class = "Class: " .. tes3.findClass(modData.class).name .. ""
    else
        class = "Type: " .. modData.type .. ""
    end

    --Labels
    local label = menu:createLabel { text = "Companion Leveler", id = root.id_label }
    label.wrapText = true
    label.justifyText = "center"
    local divider = menu:createDivider{}
    divider.borderBottom = 28
    local label2 = menu:createLabel { text = "" .. reference.object.name .. "", id = root.id_label2 }
    label2.wrapText = true
    label2.justifyText = "center"
    local label3 = menu:createLabel { text = "" .. class .. "", id = root.id_label3 }
    label3.wrapText = true
    label3.justifyText = "center"
    local label4 = menu:createLabel { text = "Level: " .. modData.level .. "", id = root.id_label4 }
    label4.wrapText = true
    label4.justifyText = "center"
    label4.borderBottom = 28


    --Button Block
    local root_block = menu:createBlock { id = "kl_root_block" }
    root_block.flowDirection = "top_to_bottom"
    root_block.autoHeight = true
    root_block.autoWidth = true
    root_block.paddingLeft = 10
    root_block.paddingRight = 10
    root_block.widthProportional = 1.0
	root_block.autoHeight = true
	root_block.childAlignX = 0.5


    -- Buttons
    local button_sheet = root_block:createButton { id = root.id_sheet, text = "Character Sheet" }
    local button_change = root_block:createButton { id = root.id_change, text = "Change Class/Type" }
    local button_tech = root_block:createButton { id = root.id_tech, text = "Use Techniques" }
    local button_cast = root_block:createButton { id = root.id_cast, text = "Cast Spells"}
    if config.buildMode == true then
        local button_build = root_block:createButton { id = root.id_build, text = "Change Build" }
        button_build:register("mouseClick", function() menu:destroy() buildChange.buildChange(reference) end)
    end
    local button_growth = root_block:createButton { id = root.id_growth, text = "Growth Settings" }
    local button_cancel = root_block:createButton { id = root.id_cancel, text = tes3.findGMST("sCancel").value }

    --EXP Bar
    if config.expMode == true then
        func.calcEXP(reference)
        local exp = root_block:createFillBar({ current = modData.lvl_progress,
            max = modData.lvl_req,
            id = root.id_exp })
        func.configureBar(exp, "standard", "gold")
        exp.height = 21
        exp.borderTop = 10

        func.clTooltip(exp, "exp")
    end

    -- Events
    button_sheet:register("mouseClick", function() menu:destroy() sheet.createWindow(reference) end)

    if reference.object.objectType == tes3.objectType.creature or modData.metamorph == true then
        button_change:register("mouseClick", function() menu:destroy() typeChange.typeChange(reference) end)
    else
        button_change:register("mouseClick", function() menu:destroy() classChange.classChange(reference) end)
    end

    button_growth:register("mouseClick", function() menu:destroy() growth.createWindow(reference) end)
    button_tech:register("mouseClick", function() menu:destroy() tech.createWindow(reference) end)
    button_cast:register("mouseClick", function() menu:destroy() cast.createWindow(reference) end)
    button_cancel:register("mouseClick", function() tes3ui.leaveMenuMode() menu:destroy() end)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(root.id_menu)
end


return root