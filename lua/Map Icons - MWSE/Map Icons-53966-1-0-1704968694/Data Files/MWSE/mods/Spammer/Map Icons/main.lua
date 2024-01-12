local mod = {
    name = "Map Icons",
    ver = "1.0",
    author = "Spammer",
    cf = { onOff = false, key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false }, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false, skyrim = false }
}
local cf = mwse.loadConfig(mod.name, mod.cf)

local sort = require("Spammer\\Map Icons\\sort")
local skyIcons = require("Spammer\\Map Icons\\skyIcons")
local vanillaIcons = require("Spammer\\Map Icons\\vanillaIcons")

---@param e table|referenceActivatedEventData
event.register("referenceActivated", function(e)
    local icons = (cf.switch and skyIcons) or vanillaIcons
    if e.reference.object.objectType ~= tes3.objectType.door then return end
    local doorRef = e.reference
    if not doorRef.supportsLuaData then return end
    if doorRef.tempData and doorRef.tempData.spa_MapIcons then return end
    if doorRef and doorRef.destination and doorRef.destination.cell then
        local cell = doorRef.destination.cell
        --mwse.log('destination.cell %s', cell)
        local cave, door = icons[" cave"], icons.active_door
        doorRef.tempData.spa_MapIcons = ((string.find(doorRef.id:lower(), "cave") ~= nil) and cave) or door
        for _, pattern in ipairs(sort) do
            if tes3.player.cell.isOrBehavesAsExterior then
                local newPath = ((string.find(cell.id:lower(), pattern) and icons[pattern]) or doorRef.tempData.spa_MapIcons)
                --mwse.log(pattern)
                doorRef.tempData.spa_MapIcons = newPath
            end
        end
    end
end)

---@param menu tes3uiElement
local function applyMapIcons(menu)
    --if not (cf.onOff or tes3ui.menuMode()) then return end
    local map = menu:findChild("MenuMap_local")
    if not map then return end
    local icons = (cf.switch and skyIcons) or vanillaIcons
    local multiplier = (cf.switch and 2) or 1
    --mwse.log(map and map.visible)
    ---@param child tes3uiElement
    for child in table.traverse(map.children) do
        if child.name == "MenuMap_active_door" then
            local doorRef = child:getPropertyObject("MenuMap_object")
            if (doorRef and doorRef.tempData and doorRef.tempData.spa_MapIcons) and (child.contentPath ~= doorRef.tempData.spa_MapIcons) and (lfs.fileexists("Data Files\\" .. doorRef.tempData.spa_MapIcons)) then
                --debug.log(doorRef.tempData.spa_MapIcons)
                child.contentPath = doorRef.tempData.spa_MapIcons
            elseif doorRef and not (doorRef.supportsLuaData or (child.contentPath == icons["active_door"])) then
                child.contentPath = icons["active_door"]
            end
            child.scaleMode = true
            child.height = 3 * cf.slider * multiplier
            child.width = 3 * cf.slider * multiplier

            if cf.skyrim and doorRef.position.z > (tes3.player.position.z + 256) then
                child.color = tes3ui.getPalette(tes3.palette.fatigueColor)
            elseif cf.skyrim and doorRef.position.z < (tes3.player.position.z - 256) then
                child.color = tes3ui.getPalette(tes3.palette.healthColor)
            elseif child.color ~= tes3ui.getPalette(tes3.palette.activeColor) then
                child.color = tes3ui.getPalette(tes3.palette.normalColor)
            end
        end
    end
    --menu:updateLayout()
end 
--[[    
---@param e menuEnterEventData
event.register("menuEnter", function(e)
    if e.menu ~= tes3ui.findMenu("MenuMap") then return end
    applyMapIcons(e.menu)
end)
--]]
--
---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    e.element:registerAfter("update", function()
        --mwse.log("Map Updated at %s", os.time())
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


---@param parent tes3uiElement
---@param imagePath string
---@param label string
local function createMapKey(parent, label, imagePath)
    local block = parent:createBlock()
    block.flowDirection = "left_to_right"
    block.borderBottom = 5
    block.autoHeight = true
    block.autoWidth = true
    block.childAlignY = 0.5
    local icon = (cf.switch and skyIcons[imagePath]) or vanillaIcons[imagePath]
    local image = block:createImage { path = icon }
    image.scaleMode = true
    image.height = 6 * cf.slider
    image.width = 6 * cf.slider
    image.borderAllSides = 5
    block:createLabel { text = label }
    --debug.log(imagePath)
    --debug.log(label)
end


---@param page3 tes3uiElement
---@param text string
local function createSeparator(page3, text)
    local label = page3:createLabel { text = "--" .. text }
    label.color = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)
    label.borderTop = 10
end


---@param page3 tes3uiElement
local function createPage3(page3)
    createSeparator(page3, "Housing")
    createMapKey(page3, "Ashlander's Yurt", " yurt")
    createMapKey(page3, "Houses", " house")
    createMapKey(page3, "Farms", "farm")

    createSeparator(page3, "Religious Places")
    createMapKey(page3, "Temples", " temple")
    createMapKey(page3, "Imperial Cult Chapels", " chapel")
    
    createSeparator(page3, "Factions")
    createMapKey(page3, "East Empire Company", "east empire")
    createMapKey(page3, "Imperial Legion", "legion")
    createMapKey(page3, "Fighter's Guild", "fighter")
    createMapKey(page3, "Mage's Guild", "mages")
    createMapKey(page3, "Morag Tong Guild", "morag")
    createMapKey(page3, "Great House Indoril", "indoril")
    createMapKey(page3, "Great House Hlaalu", "hlaalu")
    createMapKey(page3, "Great House Redoran", "redoran")
    createMapKey(page3, "Great House Telvanni", "telvanni")
    
    createSeparator(page3, "Services")
    createMapKey(page3, "Alchemists", "alchemist")
    createMapKey(page3, "Armorers, Weaponsmiths", "smith")
    createMapKey(page3, "Booksellers", "book")
    createMapKey(page3, "Clothiers, Outfitters", "clothier")
    createMapKey(page3, "Enchanters", "enchanter")
    createMapKey(page3, "Inns, Taverns", " tavern")
    createMapKey(page3, "Pawnbrokers", "pawnbroker")
    createMapKey(page3, "Potters", "potter")
    createMapKey(page3, "Traders", "trade")
    
    createSeparator(page3, "Dungeons")
    createMapKey(page3, "Ancestral Tombs", "ancestral tomb")
    createMapKey(page3, "Caves, Caverns, Grottos", " cave")
    createMapKey(page3, "Daedric Shrines", " shrine")
    createMapKey(page3, "Dunmer Strongholds", "berandas")
    createMapKey(page3, "Dwemer Ruins", "aleft")
    createMapKey(page3, "Mines", " mine")
    createMapKey(page3, "Nordic Barrows", "barrow")
    createMapKey(page3, "Shipwrecks", "ship")
end

local modConfig = {}
function modConfig.onSearch(search)
    return string.startswith("spammer", search)
end


---@param parent tes3uiElement
function modConfig.onCreate(parent)
    parent.flowDirection = "left_to_right"
    local block = parent:createBlock()
    block.flowDirection = "top_to_bottom"
    block.heightProportional = 1.0
    block.widthProportional = 1.0
    --block.paddingAllSides = 12
    local page = block:createThinBorder({})
    page.flowDirection = "top_to_bottom"
    page.heightProportional = 2 / 3
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

    local page3 = block:createVerticalScrollPane({})
    --page3.flowDirection = "top_to_bottom"
    page3.heightProportional = 4 / 3
    page3.widthProportional = 1.0
    page3.paddingAllSides = 12
    page3 = page3:getContentElement()

    local label = page2:createLabel({
        text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by " .. mod.author .. ".\n"
    })
    local link = page2:createHyperlink({
        text = "Spammer's Nexus Profile",
        url = "https://www.nexusmods.com/users/140139148?tab=user+files"
    })

    --
    local cycleButtonDesc = page2:createLabel({
        text =
        "Switches between Vanilla-style icons and Skyrim-style more colorful ones."
    })
    if tes3.player then
        cycleButtonDesc.text = cycleButtonDesc.text .. " Requires a Game Restart."
    end
    cycleButtonDesc.visible = false

    header = page:createLabel({ text = "Icon Style:" })
    header.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header.borderBottom = 5
    local cycle = page:createCycleButton { options = { { text = "Colorful", value = true }, { text = "Vanilla", value = false } } }
    cycle.borderBottom = 20
    cycle.widget.value = cf.switch
    cycle:registerAfter("mouseClick", function()
        cf.switch = cycle.widget.value
        mwse.saveConfig(mod.name, cf)
        page3:destroyChildren()
        createPage3(page3)
        cycle:getTopLevelMenu():updateLayout()
        --tes3.messageBox("You'll need to restart the game for the changes to apply.")
    end)
    cycle:register("mouseOver", function()
        label.visible = false
        link.visible = false
        cycleButtonDesc.visible = true
    end)
    cycle:register("mouseLeave", function()
        label.visible = true
        link.visible = true
        cycleButtonDesc.visible = false
    end)

    --]]

    header = page:createLabel({ text = "Icons Size:" })
    header.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header.borderBottom = 5
    local desc = page:createLabel({ text = string.format("Size Multiplier: %.1f", (cf.slider / 10)) })
    desc.borderBottom = 1
    local slider = page:createSlider { current = cf.slider, min = 0, max = 100, step = 1, jump = 10 }
    slider.widthProportional = 1
    slider:register("PartScrollBar_changed", function()
        cf.slider = slider.widget.current
        mwse.saveConfig(mod.name, cf)
        local map = tes3ui.findMenu("MenuMap")
        if map then
            applyMapIcons(map)
        end
        desc.text = string.format("Size Multiplier: %.1f", (cf.slider / 10))
        page3:destroyChildren()
        createPage3(page3)
        slider:getTopLevelMenu():updateLayout()
    end)

    --
    local buttonDesc = page2:createLabel({
        text =
        "Optional. With this toogled, Map Icons will switch colors depending on their position relative to you: Green if the door is above your current postion, Red if it's below it."
    })
    buttonDesc.visible = false

    local header = page:createLabel({ text = "Relative Positionning Color:" })
    header.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header.borderBottom = 5
    header.borderTop = 20
    local cycle1 = page:createCycleButton { options = { { text = "On", value = true }, { text = "Off", value = false } } }
    cycle1.borderBottom = 20
    cycle1.widget.value = cf.skyrim
    cycle1:registerAfter("mouseClick", function()
        cf.skyrim = cycle1.widget.value
        mwse.saveConfig(mod.name, cf)
    end)
    cycle1:register("mouseOver", function()
        label.visible = false
        link.visible = false
        buttonDesc.visible = true
    end)
    cycle1:register("mouseLeave", function()
        label.visible = true
        link.visible = true
        buttonDesc.visible = false
    end)

    --]]

    local header1 = page:createLabel { text = "Map Key" }
    header1.absolutePosAlignX = 0.5
    header1.absolutePosAlignY = 0.95
    header1.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header1.borderBottom = 2
    createPage3(page3)
end

local function registerModConfig()
    mwse.registerModConfig(mod.name, modConfig)
end
event.register("modConfigReady", registerModConfig)


local function initialized()
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = -1000 })
