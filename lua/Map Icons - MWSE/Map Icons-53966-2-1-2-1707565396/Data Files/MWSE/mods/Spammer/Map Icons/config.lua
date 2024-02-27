local mod = require("Spammer\\Map Icons\\mod")
local cf = mwse.loadConfig(mod.name, mod.cf)
local skyIcons = require("Spammer\\Map Icons\\skyIcons")
local vanillaIcons = require("Spammer\\Map Icons\\vanillaIcons")
local applyMapIcons = require("Spammer\\Map Icons\\applyMapIcons")
local getIcon = require("Spammer\\Map Icons\\getIcon")
local node = require("Spammer\\Map Icons\\cursor")

local config = {}

---@param parent tes3uiElement
---@param imagePath string
---@param label string
---@param id string|nil
local function createMapKey(parent, label, imagePath, id)
    local block = parent:createBlock({ id = id })
    block.flowDirection = "left_to_right"
    block.borderBottom = 5
    block.autoHeight = true
    block.autoWidth = true
    block.childAlignY = 0.5
    local icon = ((cf.switch and skyIcons[imagePath]) or vanillaIcons[imagePath]) or imagePath
    local image = block:createImage { path = icon }
    image.scaleMode = true
    image.height = 6 * cf.slider
    image.width = 6 * cf.slider
    image.borderAllSides = 5
    image.consumeMouseEvents = true
    block:createLabel { text = label }
    image:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        imagePath = string.gsub(imagePath, "/", "\\")
        if ((image.contentPath == imagePath) and mod.hello == "hello") then
            mod.hello = image.contentPath
            local cursor = node():getObjectByName("cursor") --[[@as niTriShape]]
            local texturingProperty = cursor.texturingProperty --[[@as niTexturingProperty]]
            local map = texturingProperty.baseMap --[[@as niTexturingPropertyMap]]
            local texture = niSourceTexture.createFromPath(mod.hello)
            map.texture = texture
            cursor:updateProperties()
        end
        --[[
        imagePath = string.gsub(imagePath, "/", "\\")
        if ((image.contentPath == imagePath) and mod.hello ~= "hello") then
            tes3.messageBox { message = string.format('Link "%s" Cell to "%s" Icon?', mod.hello, label), buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value }, callback = function(
                e)
                if e.button == 0 then
                    cf.blocked[mod.hello] = imagePath
                    mwse.saveConfig(mod.name, cf)
                    tes3.messageBox('Link Succesful! "%" Cell will now use "% Icon!', mod.hello, label)
                end
            end }
        elseif (image.contentPath == imagePath) then
            tes3.messageBox("Select a Cell to link first!")
        end
        --]]
    end)
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
    createSeparator(page3, "Default Icon")
    createMapKey(page3, "Door", "active_door")

    createSeparator(page3, "Housing")
    createMapKey(page3, "Ashlander's Yurt", " yurt")
    createMapKey(page3, "Houses", " house")
    createMapKey(page3, "Farms", "farm")

    createSeparator(page3, "Religious Places")
    createMapKey(page3, "Temples", " temple")
    createMapKey(page3, "Imperial Cult Chapels", "imperial chapel")

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
    createMapKey(page3, "Other Guilds", " guild")

    createSeparator(page3, "Services")
    createMapKey(page3, "Alchemists", "alchemist")
    createMapKey(page3, "Armorers, Weaponsmiths", "smith")
    createMapKey(page3, "Booksellers", "book")
    createMapKey(page3, "Clothiers, Outfitters", "clothier")
    createMapKey(page3, "Enchanters", "enchanter")
    createMapKey(page3, "Fletchers", "fletcher")
    createMapKey(page3, "Inns, Taverns", " tavern")
    createMapKey(page3, "Pawnbrokers", "pawnbroker")
    createMapKey(page3, "Potters", "potter")
    createMapKey(page3, "Spellmakers", "sorcerer")
    createMapKey(page3, "Traders", "trade")

    createSeparator(page3, "Other Buildings")
    createMapKey(page3, "Guard Towers, Outposts", "tower")
    createMapKey(page3, "Lighthouses", "lighthouse")
    createMapKey(page3, "Warehouses", "storage")

    createSeparator(page3, "Dungeons")
    createMapKey(page3, "Ancestral Tombs", "ancestral tomb")
    createMapKey(page3, "Caves, Caverns, Grottos", " cave")
    createMapKey(page3, "Daedric Shrines", "ashunartes")
    createMapKey(page3, "Dunmer Strongholds", "berandas")
    createMapKey(page3, "Dwemer Ruins", "aleft")
    createMapKey(page3, "Mines", " mine")
    createMapKey(page3, "Nordic Barrows", "barrow")
    createMapKey(page3, "Shipwrecks", "ship")

    if not table.empty(cf.customIcons) then
        createSeparator(page3, "Custom Icons")
        for label, path in pairs(cf.customIcons) do
            createMapKey(page3, label, path)
        end
    end
end



---@param parent tes3uiElement
function config.firstPage(parent)
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
            applyMapIcons(map, cf)
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

---@param parent tes3uiElement
---@param text string
---@param placeHolder string
local function createTextInput(parent, text, placeHolder)
    local block = parent:createBlock()
    block.widthProportional = 0.9
    block.height = 80
    block.flowDirection = "top_to_bottom"
    block:createLabel { text = text }
    local element = block:createThinBorder():createTextInput { placeholderText = placeHolder }
    element.parent.autoHeight = true
    element.parent.heightProportional = 1
    element.widthProportional = 1
    element.heightProportional = 1
    return element
end

---@param parent tes3uiElement
function config.secondPage(parent)
    local page = parent:createThinBorder({})
    page.flowDirection = "top_to_bottom"
    page.heightProportional = 1.0
    page.widthProportional = 1.0
    page.paddingAllSides = 12
    page.wrapText = true
    local page1headerBlock = page:createBlock()
    page1headerBlock.widthProportional = 1
    page1headerBlock.heightProportional = 0.2
    page1headerBlock.flowDirection = "left_to_right"
    local page1mainBlock = page:createVerticalScrollPane()
    page1mainBlock.widthProportional = 1
    page1mainBlock.heightProportional = 0.9
    page1mainBlock.paddingAllSides = 12
    page1mainBlock = page1mainBlock:getContentElement()
    for name, path in pairs(cf.customIcons) do
        createMapKey(page1mainBlock, name, path)
    end
    local name = createTextInput(page1headerBlock, "Icon Name", "Painter's Guild")
    local path = createTextInput(page1headerBlock, "Icon Path", "Textures/")
    local button = page1headerBlock:createButton { text = tes3.findGMST("sOK").value }
    button.autoHeight = true
    button.autoWidth = true
    button:register("mouseClick", function()
        if name.text and path.text and lfs.fileexists("Data Files/" .. path.text) then
            cf.customIcons[name.text] = path.text
            mwse.saveConfig(mod.name, cf)
            page1mainBlock:destroyChildren()
            for names, paths in pairs(cf.customIcons) do
                createMapKey(page1mainBlock, names, paths)
            end
            parent:getTopLevelMenu():updateLayout()
        else
            tes3.messageBox("Invalid File")
        end
    end)
end

---@param filter boolean|nil
local function exclusionList(filter)
    local list = {}
    ---@param cell tes3cell
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if cell.isInterior and ((not cf.whiteList[cell.id]) or filter) then
            table.insert(list, cell.id)
        end
    end
    return list
end




---@param layer tes3uiElement
---@param list string[]
---@param toggle boolean|nil
local function toggleList(layer, list, id, toggle)
    table.sort(list)
    local text = layer:createThinBorder():createTextInput({ id = id, placeholderText = "Search..." })
    text.parent.widthProportional = 1
    text.parent.height = 30
    text.parent.consumeMouseEvents = true
    text.parent:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        tes3ui.acquireTextInput(text)
    end)
    local pane = layer:createVerticalScrollPane()
    pane.widthProportional = 1
    pane.height = layer.height - 40
    pane = pane:getContentElement()
    for _, cell in ipairs(list) do
        local label = pane:createLabel { id = cell, text = cell }
        label.consumeMouseEvents = true
        label:register("mouseOver", function()
            label.color = tes3ui.getPalette(tes3.palette.normalOverColor)
            label:getTopLevelMenu():updateLayout()
        end)
        label:register("mouseLeave", function()
            label.color = tes3ui.getPalette(tes3.palette.normalColor)
            label:getTopLevelMenu():updateLayout()
        end)
        if id == "switchIconer" then
            label:register("help", function()
                local toolTip = tes3ui.createTooltipMenu()
                local icon = toolTip:createImage { id = "ttIcon", path = getIcon({ isOrBehavesAsExterior = true }, { id = cell }, nil, cf ) }
                icon.scaleMode = true
                icon.width = 16
                icon.height = 16
            end)
        end
        label:register("mouseClick", function()
            tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
            cf.whiteList[label.text] = toggle
            mwse.saveConfig(mod.name, cf)
            local parent = layer.parent
            local savedText = text.text
            parent:destroyChildren()
            config.thirdPage(parent)
            parent:getTopLevelMenu():updateLayout()
            timer.frame.delayOneFrame(function()
                local newText = parent:findChild(id)
                newText.text = savedText
                if savedText ~= "Search..." then
                    newText.widget.eraseOnFirstKey = false
                    newText:triggerEvent("textUpdated")
                else
                    newText.widget.eraseOnFirstKey = true
                end
            end)
        end)
    end
    text:registerAfter("textUpdated", function(e)
        local search = e.source.text:lower()
        for _, child in pairs(pane.children) do
            child.visible = (string.find(child.text:lower(), search, 1, true) ~= nil)
        end
    end)
    text:registerAfter("textCleared", function()
        for _, child in pairs(pane.children) do
            child.visible = true
        end
    end)
end

---@param parent tes3uiElement
function config.thirdPage(parent)
    local layer = parent:createBlock()
    layer.widthProportional = 1
    layer.heightProportional = 0.945
    layer.flowDirection = "top_to_bottom"
    local label = layer:createLabel { text = "Act as Exterior Cells:" }
    label.color = tes3ui.getPalette(tes3.palette.headerColor)
    toggleList(layer, table.keys(cf.whiteList), "whiteList")
    layer = parent:createBlock()
    layer.widthProportional = 1
    layer.heightProportional = 0.945
    layer.flowDirection = "top_to_bottom"
    label = layer:createLabel { text = "Act as Interior Cells:" }
    label.color = tes3ui.getPalette(tes3.palette.headerColor)
    toggleList(layer, exclusionList(), "blackList", true)
end

---@param parent tes3uiElement
function config.fourthPage(parent)
    local layer = parent:createBlock { id = "layer1" }
    layer.widthProportional = 1
    layer.heightProportional = 0.85
    layer.flowDirection = "top_to_bottom"
    local label1 = layer:createLabel { text = "Edit Cell Icons:" }
    label1.color = tes3ui.getPalette(tes3.palette.headerColor)
    local keys = exclusionList(true)
    toggleList(layer, keys, "switchIconer", true)
    table.sort(keys)
    for _, cell in ipairs(keys) do
        local label = layer:findChild(cell)
        label:unregister("mouseClick")
        label:register("mouseClick", function()
            tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
            cf.blocked[cell] = ((mod.hello ~= "hello") and mod.hello) or nil
            mwse.saveConfig(mod.name, cf)
            tes3.messageBox("Cell Icon succesfully changed!")
        end)
    end

    local layer2 = parent:createBlock()
    layer2.widthProportional = 1
    layer2.heightProportional = 0.85
    layer2.flowDirection = "top_to_bottom"
    local label = layer2:createLabel { text = "Add Custom Icon:" }
    label.color = tes3ui.getPalette(tes3.palette.headerColor)
    local text = layer2:createThinBorder():createThinBorder():createTextInput({ placeholderText = "Textures/" })
    text.parent.widthProportional = 1
    text.parent.parent.widthProportional = 1.5
    text.parent.height = 30
    text.parent.parent.height = 30
    text.parent.parent.flowDirection = "left_to_right"
    text.parent.consumeMouseEvents = true
    text.parent:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        tes3ui.acquireTextInput(text)
    end)
    text.height = 30
    text.minWidth = layer2.width - 300
    local button = text.parent.parent:createButton { text = "Validate" }
    button:register("mouseClick", function()
        local success, c = pcall(function() return lfs.fileexists("Data Files/" .. text.text) end)
        if (success and c) and (string.endswith(text.text:lower(), ".dds") or string.endswith(text.text:lower(), ".tga")) then
            local name = text.text:match(".*/(.*)")
            local path = string.gsub(text.text:lower(), "data files/", "")
            cf.customIcons[name] = path
            mwse.saveConfig(mod.name, cf)
            parent:destroyChildren()
            config.fourthPage(parent)
            parent:getTopLevelMenu():updateLayout()
            tes3.messageBox("Custom Icon Added!")
        else
            tes3.messageBox("Invalid File.")
        end
    end)
    button.height = 30
    button.widthProportional = 0.25
    text:register("keyEnter", function()
        button:triggerEvent("mouseClick")
    end)
    local pane = layer2:createVerticalScrollPane()
    pane.widthProportional = 1
    pane.heightProportional = 1
    pane = pane:getContentElement()
    local icons = (cf.switch and "SkyIcons") or "MapIcons"
    --print(lfs.directoryexists("Data Files/Textures/Spammer/" .. icons))
    if not table.empty(cf.customIcons) then
        local customKeys = table.keys(cf.customIcons)
        table.sort(customKeys)
        createSeparator(pane, "Custom Icons")
        for _, name in ipairs(customKeys) do
            createMapKey(pane, name, cf.customIcons[name])
        end
        createSeparator(pane, "Mod Icons")
    end
    for filePath, _, fileName in lfs.walkdir("Data Files/Textures/Spammer/" .. icons .. "/") do
        createMapKey(pane, fileName, string.gsub(filePath:lower(), "data files/", ""))
    end

    parent:reorderChildren(layer, layer2, 1)
end

return config
