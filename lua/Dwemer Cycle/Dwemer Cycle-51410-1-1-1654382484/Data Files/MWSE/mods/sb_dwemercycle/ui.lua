local mcm = require("sb_dwemercycle.mcm")

local ui = {
    multi = {
        reference    = nil,
        controls     = nil,
        controlSpawn = nil,
        speed        = nil,
        fuel         = nil,
        icon_1       = nil,
        icon_2       = nil
    },
    stat  = {
        reference = nil,
        speed     = nil,
        fuel      = nil
    }
}

function ui.updateIcon1(i)
    ui.multi.icon_1.contentPath = "Icons\\sb_dwemercycle\\icn_gear_" .. tostring(i) .. ".tga"
end

function ui.updateIcon2(b)
    ui.multi.icon_2.contentPath = "Icons\\sb_dwemercycle\\icn_light_" .. (b and "on" or "off") .. ".tga"
end

local function createControlText(element, keys, control)
    local group = element:createBlock { id = tes3ui.registerID("Label") }
    group.autoWidth = true
    group.autoHeight = true
    local key = ""
    for _, i in ipairs(keys) do
        if (_ > 1) then
            key = key .. "\n"
        end
        if (type(i) == "table") then
            for _, j in ipairs(i) do
                for letter, code in pairs(tes3.scanCode) do
                    if code == tes3.worldController.inputController.inputMaps[j + 1].code then
                        key = key .. "[" .. tostring(tes3.scanCodeToNumber[code] or letter):upper():gsub("EFT", ""):gsub("IGHT", "") .. "]"
                        break
                    end
                end
            end
        elseif (i ~= -1) then
            for letter, code in pairs(tes3.scanCode) do
                if code == tes3.worldController.inputController.inputMaps[i + 1].code then
                    key = key .. "[" .. tostring(tes3.scanCodeToNumber[code] or letter):upper():gsub("EFT", ""):gsub("IGHT", "") .. "]"
                    break
                end
            end
        end
    end
    local k = group:createLabel { text = key }
    local v = group:createLabel { text = control }
    k.borderRight = 4
    v.borderLeft = 4
end

local function createControlSpawn(element, key)
    ui.multi.controlSpawn = element:createRect { color = { 0, 0, 0 } }
    ui.multi.controlSpawn.autoWidth = true
    ui.multi.controlSpawn.autoHeight = true
    ui.multi.controlSpawn.alpha = 0.8
    ui.multi.controlSpawn.borderRight = 2

    local controlSpawnBorder = ui.multi.controlSpawn:createThinBorder()
    controlSpawnBorder.autoWidth = true
    controlSpawnBorder.autoHeight = true
    controlSpawnBorder.flowDirection = "top_to_bottom"
    controlSpawnBorder.paddingAllSides = 8

    local group = controlSpawnBorder:createBlock { id = tes3ui.registerID("Label") }
    group.autoWidth = true
    group.autoHeight = true
    group.childAlignY = 0.5
    local displayKey = ""
    for letter, code in pairs(tes3.scanCode) do
        if code == key then
            displayKey = displayKey .. "[" .. tostring(tes3.scanCodeToNumber[code] or letter):upper():gsub("EFT", ""):gsub("IGHT", "") .. "]"
            break
        end
    end
    local k = group:createLabel { text = displayKey }
    local v = group:createImage { path = "Icons\\sb_dwemercycle\\icn_spawn.tga" }
    k.borderRight = 4
    v.borderLeft = 4
end

local function createMulti(element, borderBottom, icon, stat, fillBarColour)
    local group = element:createBlock { id = tes3ui.registerID("sb_dwemercycle_stat_" .. stat) }
    group.maxWidth = 65
    group.autoWidth = true
    group.autoHeight = true
    group.widthProportional = 1
    group.childAlignX = -1
    group.borderBottom = borderBottom

    local multiRect = group:createRect { color = { 0, 0, 0 } }
    multiRect.autoWidth = true
    multiRect.autoHeight = true
    multiRect.alpha = 0.8
    multiRect.borderRight = 4

    local multiBorder = multiRect:createThinBorder()
    multiBorder.width = 16
    multiBorder.height = 16

    ui.multi[icon] = multiBorder:createImage { id = icon, path = "Icons\\sb_dwemercycle\\icn_gear_3.tga" }
    ui.multi[icon].absolutePosAlignX = 0.5
    ui.multi[icon].absolutePosAlignY = 0.5

    ui.multi[stat] = group:createRect { color = { 0, 0, 0 } }:createFillBar { current = 450, max = 500 }
    ui.multi[stat].width = 65 - 16 - 4
    ui.multi[stat].height = 16
    ui.multi[stat].parent.autoWidth = true
    ui.multi[stat].parent.autoHeight = true
    ui.multi[stat].parent.alpha = 0.8
    ui.multi[stat].widget.fillColor = fillBarColour
    ui.multi[stat].widget.showText = false
end

local function createStat(element, label, fillBarLabel, fillBarColour)
    local group = element:createBlock { id = tes3ui.registerID("sb_dwemercycle_stat") }
    group.autoWidth = true
    group.autoHeight = true
    group.widthProportional = 1
    group.childAlignX = -1
    local k = group:createLabel { text = label }
    local v = group:createRect { id = tes3ui.registerID(fillBarLabel), color = { 0, 0, 0 } }:createFillBar { current = 4, max = 10 }
    k.width = 48
    k.color = { 0.875, 0.788, 0.624 }
    v.width = 130
    v.parent.autoWidth = true
    v.parent.autoHeight = true
    v.parent.alpha = 0.8
    v.widget.fillColor = fillBarColour
    return v
end

function ui.showBars()
    ui.multi.reference.visible = true
    ui.stat.reference.visible = true
    ui.showControls()
    timer.start { duration = 5, callback = ui.hideControls }
end

function ui.hideBars()
    if (ui.multi.reference) then
        ui.multi.reference.visible = false
    end
    if (ui.stat.reference) then
        ui.stat.reference.visible = false
    end
end

function ui.toggleBars(toggle)
    (toggle and ui.showBars or ui.hideBars)()
end

function ui.showControls()
    ui.multi.controls.visible = true
end

function ui.hideControls()
    ui.multi.controls.visible = false
end

function ui.showSpawnControl()
    ui.multi.controlSpawn.visible = true
end

function ui.hideSpawnControl()
    ui.multi.controlSpawn.visible = false
end

function ui.updateSpeed(speed, max, label)
    local s = math.min(speed, max)
    ui.multi.speed.widget.current = s
    ui.multi.speed.widget.max = max
    ui.stat.speed.widget.current = s
    ui.stat.speed.widget.max = max
    ui.stat.speed:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = label
end

function ui.updateFuel(fuel, max, label)
    local s = math.min(fuel, max)
    ui.multi.fuel.widget.current = s
    ui.multi.fuel.widget.max = max
    ui.stat.fuel.widget.current = s
    ui.stat.fuel.widget.max = max
    ui.stat.fuel:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = label
end

local function uiMultiActivatedCallback(e)
    local MenuMulti_main = e.element:findChild(tes3ui.registerID("MenuMulti_main"))

    ui.multi.reference = MenuMulti_main:createBlock { id = tes3ui.registerID("sb_dwemercycle_multis") }
    ui.multi.reference.autoWidth = true
    ui.multi.reference.autoHeight = true
    ui.multi.reference.paddingRight = 2
    ui.multi.reference.flowDirection = "top_to_bottom"
    ui.multi.reference.childAlignX = 1.0
    ui.multi.reference:registerBefore("destroy", function() ui.multi.reference = nil end)

    ui.multi.controls = ui.multi.reference:createRect { color = { 0, 0, 0 } }
    ui.multi.controls.autoWidth = true
    ui.multi.controls.autoHeight = true
    ui.multi.controls.alpha = 0.8
    ui.multi.controls.borderBottom = 4

    local controlsBorder = ui.multi.controls:createThinBorder()
    controlsBorder.autoWidth = true
    controlsBorder.autoHeight = true
    controlsBorder.flowDirection = "top_to_bottom"
    controlsBorder.paddingAllSides = 8
    createControlText(controlsBorder,
            { tes3.keybind.forward,
              tes3.keybind.back,
              -1,
              --tes3.keybind.jump,
              tes3.keybind.readyMagic,
              -1,
              { tes3.keybind.activate, tes3.keybind.left },
              { tes3.keybind.activate, tes3.keybind.right },
              -1,
              tes3.keybind.run,
              tes3.keybind.sneak } --[["[Forward]\n[Brake]\n[Jump]\n[Run]\n[Sneak]"]],
            "ride\n" ..
                    "brake\n" ..
                    "\n" ..
                    --"jump (N/A)\n" ..
                    "headlamp\n" ..
                    "\n" ..
                    "dismount left\n" ..
                    "dismount right\n" ..
                    "\n" ..
                    "gear up\n" ..
                    "gear down")

    createMulti(ui.multi.reference, 4, "icon_1", "speed", { 0, 1, 1 })
    createMulti(ui.multi.reference, 0, "icon_2", "fuel", { 1, 0.5, 0 })

    --ui.multi.speed = ui.multi.reference:createRect { color = { 0, 0, 0 } }:createFillBar { current = 4, max = 10 }
    --ui.multi.speed.width = 65
    --ui.multi.speed.height = 12
    --ui.multi.speed.parent.autoWidth = true
    --ui.multi.speed.parent.autoHeight = true
    --ui.multi.speed.parent.alpha = 0.8
    --ui.multi.speed.parent.borderBottom = 4
    --ui.multi.speed.widget.fillColor = { 0, 1, 1 }
    --ui.multi.speed.widget.showText = false

    --ui.multi.fuel = ui.multi.reference:createRect { color = { 0, 0, 0 } }:createFillBar { current = 450, max = 500 }
    --ui.multi.fuel.width = 65
    --ui.multi.fuel.height = 12
    --ui.multi.fuel.parent.autoWidth = true
    --ui.multi.fuel.parent.autoHeight = true
    --ui.multi.fuel.parent.alpha = 0.8
    --ui.multi.fuel.widget.fillColor = { 1, 0.5, 0 }
    --ui.multi.fuel.widget.showText = false

    createControlSpawn(MenuMulti_main, mcm.config.keyBind.keyCode)

    MenuMulti_main.flowDirection = "top_to_bottom"
    MenuMulti_main.childAlignX = 1.0
    MenuMulti_main:reorderChildren(0, -1, 2)
end

local function uiStatActivatedCallback(e)
    local MenuStat_mini_frame = e.element:findChild(tes3ui.registerID("MenuStat_mini_frame"))

    ui.stat.reference = MenuStat_mini_frame:createBlock { id = tes3ui.registerID("sb_dwemercycle_stats") }
    ui.stat.reference.autoWidth = true
    ui.stat.reference.autoHeight = true
    ui.stat.reference.widthProportional = 1
    ui.stat.reference.paddingTop = 18
    ui.stat.reference.flowDirection = "top_to_bottom"
    ui.stat.reference:registerBefore("destroy", function() ui.stat.reference = nil end)

    ui.stat.speed = createStat(ui.stat.reference, "Speed", "sb_dwemercycle_speed_stat", { 0, 1, 1 })
    ui.stat.fuel = createStat(ui.stat.reference, "Fuel", "sb_dwemercycle_fuel_stat", { 1, 0.5, 0 })
    --ui.stat.speed:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "20 mph"
    --ui.stat.fuel.widget.current = 450
    --ui.stat.fuel.widget.max = 500
    --ui.stat.fuel:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "28.2 miles"

    --ui.multi.fuel = ui.multi.reference:createRect { color = { 0, 0, 0 } }:createFillBar { current = 450, max = 500 }
    --ui.multi.fuel.width = 65
    --ui.multi.fuel.height = 12
    --ui.multi.fuel.parent.autoWidth = true
    --ui.multi.fuel.parent.autoHeight = true
    --ui.multi.fuel.parent.alpha = 0.8
    --ui.multi.fuel.widget.fillColor = { 1, 0.5, 0 }
    --ui.multi.fuel.widget.showText = false
    --
    --MenuStat_mini_frame.flowDirection = "top_to_bottom"
    --MenuStat_mini_frame.childAlignX = 1.0
    --MenuStat_mini_frame:reorderChildren(0, -1, 1)
end

local function menuEnterCallback(e)
    if (ui.multi.reference.visible) then
        ui.showControls()
    end
end

local function menuExitCallback(e)
    --if (e.menu and e.menu.name == "MenuMap" and ui.multi.reference.visible) then
    ui.hideControls()
    --end
end

local function uiObjectTooltipCallback(e)
    if (e.tooltip:findChild("HelpMenu_name").text == "Dwemer Cycle" and ui.multi.reference.visible) then
        e.tooltip.maxWidth = 0
        e.tooltip.maxHeight = 0
    end
end

function ui.init()
    event.register("uiActivated", uiMultiActivatedCallback, { filter = "MenuMulti" })
    event.register("uiActivated", uiStatActivatedCallback, { filter = "MenuStat" })
    event.register("menuEnter", menuEnterCallback)
    event.register("menuExit", menuExitCallback)
    event.register("uiObjectTooltip", uiObjectTooltipCallback)
end

return ui