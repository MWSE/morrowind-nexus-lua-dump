local mod = {
    name = "Map Icons",
    ver = "1.0",
    author = "Spammer",
    cf = { onOff = true, key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false }, dropDown = 0, slider = 5, sliderpercent = 10, blocked = {}, npcs = {}, textfield = "hello", switch = false }
}
local cf = mwse.loadConfig(mod.name, mod.cf)

local sort = require("Spammer\\Map Icons\\sort")
local icons = require("Spammer.Map Icons.skyIcons")


---@param menu tes3uiElement
local function applyMapIcons(menu)
    local map = menu:findChild("MenuMap_local")
    if not map then return end
    --mwse.log(map and map.visible)
    ---@param child tes3uiElement
    for child in table.traverse(map.children) do
        if child.name == "MenuMap_active_door" then
            local doorRef = child:getPropertyObject("MenuMap_object")
            if doorRef and doorRef.destination and doorRef.destination.cell then
                local cell = doorRef.destination.cell
                --mwse.log('destination.cell %s', cell)
                --child.contentPath = "Textures\\Spammer\\Spaskycon\\shop.dds"
                child.contentPath = "Textures\\Spammer\\Spaskycon\\active_door.dds"
                for _, pattern in ipairs(sort) do
                    local newPath = ((string.find(cell.id:lower(), pattern) and icons[pattern]) or child.contentPath)
                    --mwse.log(pattern)
                    child.scaleMode = true
                    child.height = 3 * cf.sliderpercent
                    child.width = 3 * cf.sliderpercent
                    if tes3.player.cell.isOrBehavesAsExterior and newPath == icons[pattern] then
                        child.contentPath = newPath
                    end
                end
            end
        end
    end
    --menu:updateLayout()
end
---@param e menuEnterEventData
event.register("menuEnter", function(e)
    if e.menu ~= tes3ui.findMenu("MenuMap") then return end
    applyMapIcons(e.menu)
end)

--
---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    e.element:registerAfter("update", function()
        applyMapIcons(e.element)
    end)
end, { filter = "MenuMap" })
--]]
--[[
---@param e table|cellChangedEventData
event.register("cellChanged", function(e)
    local menu = tes3ui.findMenu("MenuMap")
    if menu and menu.visible then
        timer.delayOneFrame(function()
            applyMapIcons(menu)
        end)
    end
end)

--]]



local modConfig = {}
function modConfig.onSearch(search)
    return string.startswith("spammer", search)
end

---@param parent tes3uiElement
function modConfig.onCreate(parent)
    parent.flowDirection = "left_to_right"
    local page = parent:createThinBorder({})
    page.flowDirection = "top_to_bottom"
    page.heightProportional = 1.0
    page.widthProportional = 1.0
    page.paddingAllSides = 12
    --page.childAlignX = 0.s
    --page.childAlignY = 0.5
    local page2 = parent:createThinBorder({})
    page2.flowDirection = "top_to_bottom"
    page2.heightProportional = 1.0
    page2.widthProportional = 1.0
    page2.paddingAllSides = 12
    page2.wrapText = true
    local label = page2:createLabel({
        text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by " .. mod.author .. ".\n"
    })
    local link = page2:createHyperlink({
        text = "Spammer's Nexus Profile",
        url = "https://www.nexusmods.com/users/140139148?tab=user+files"
    })
    local header = page:createLabel({ text = "Icons Size:" })
    header.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header.borderBottom = 5
    local desc = page:createLabel({ text = string.format("Size Multiplier: %.1f", (cf.sliderpercent / 10)) })
    desc.borderBottom = 1
    local slider = page:createSlider { current = cf.sliderpercent, min = 0, max = 100, step = 1, jump = 10 }
    slider.widthProportional = 1
    slider:register("PartScrollBar_changed", function()
        cf.sliderpercent = slider.widget.current
        mwse.saveConfig(mod.name, cf)
        local map = tes3ui.findMenu("MenuMap")
        if map then
            applyMapIcons(map)
        end
        desc.text = string.format("Size Multiplier: %.1f", (cf.sliderpercent / 10))
        slider:getTopLevelMenu():updateLayout()
    end)
end

local function registerModConfig()
    mwse.registerModConfig(mod.name, modConfig)
end
event.register("modConfigReady", registerModConfig)


local function initialized()
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = -1000 })
