local mod = require("Spammer\\Map Icons\\mod")
local cf = mwse.loadConfig(mod.name, mod.cf)
local sort = require("Spammer\\Map Icons\\sort")
local skyIcons = require("Spammer\\Map Icons\\skyIcons")
local vanillaIcons = require("Spammer\\Map Icons\\vanillaIcons")
local node = require("Spammer\\Map Icons\\cursor")
local config = {}

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
            --debug.log(doorRef.tempData and doorRef.tempData.spa_MapIcons)
            --debug.log(doorRef.tempData and lfs.fileexists("Data Files\\" .. doorRef.tempData.spa_MapIcons))
            if doorRef and doorRef.destination and cf.blocked[doorRef.destination.cell.id] then
                if child.contentPath:lower() ~= string.gsub(cf.blocked[doorRef.destination.cell.id]:lower(), "/", "\\") then
                    child.contentPath = cf.blocked[doorRef.destination.cell.id]
                end
            elseif cf.Danae and doorRef and doorRef.data and doorRef.data.spa_MapIcons then
                if (child.contentPath:lower() ~= string.gsub(doorRef.data.spa_MapIcons:lower(), "/", "\\")) and (lfs.fileexists("Data Files\\" .. doorRef.data.spa_MapIcons)) then
                    child.contentPath = doorRef.data.spa_MapIcons
                end
            else
                if (doorRef and doorRef.tempData and doorRef.tempData.spa_MapIcons) and (child.contentPath ~= doorRef.tempData.spa_MapIcons) and (lfs.fileexists("Data Files\\" .. doorRef.tempData.spa_MapIcons)) then
                    --debug.log(doorRef.tempData.spa_MapIcons)
                    child.contentPath = doorRef.tempData.spa_MapIcons
                elseif doorRef and not (doorRef.supportsLuaData or (child.contentPath == icons["active_door"])) then
                    child.contentPath = icons["active_door"]
                end
            end
            child.scaleMode = true
            child.height = 3 * cf.slider * multiplier
            child.width = 3 * cf.slider * multiplier

            if cf.skyrim and doorRef and doorRef.position.z > (tes3.player.position.z + 256) then
                child.color = tes3ui.getPalette(tes3.palette.fatigueColor)
            elseif cf.skyrim and doorRef and doorRef.position.z < (tes3.player.position.z - 256) then
                child.color = tes3ui.getPalette(tes3.palette.healthColor)
            elseif child.color ~= tes3ui.getPalette(tes3.palette.activeColor) then
                child.color = tes3ui.getPalette(tes3.palette.normalColor)
            end
        end
    end
    --menu:updateLayout()
end



---@param cell tes3cell|table
---@return boolean
local function validCell(cell)
    return cell.isOrBehavesAsExterior
        --or (string.startswith(cell.id:lower(), "sadrith mora"))
        --or (string.find(cell.id:lower(), " plaza") ~= nil)
        --or (string.find(cell.id, "works") ~= nil)
        or cf.whiteList[cell.id]
end
---
---@param refCell tes3cell|table
---@param cell tes3cell|table
---@param default string|nil
local function getIcon(refCell, cell, default)
    local icons = (cf.switch and table.copy(skyIcons)) or table.copy(vanillaIcons)
    default = default or icons.active_door
    local newPath
    if cf.blocked[cell.id] and lfs.fileexists("Data Files\\" .. cf.blocked[cell.id]) then
        newPath = cf.blocked[cell.id]
    else
        for _, pattern in ipairs(sort) do
            if validCell(refCell) then
                newPath = ((string.find(cell.id:lower(), pattern, 1, true) ~= nil) and icons[pattern]) or newPath
                --mwse.log(pattern)
            end
        end
    end
    return newPath or default
end

local function checkForCaves(id)
    return (string.find(id:lower(), "cave") ~= nil)
        or (string.find(id:lower(), "dark") ~= nil)
        or (string.find(id:lower(), "black") ~= nil)
end


local function getDoorIcon(doorRef)
    if not doorRef then return end
    local icons = (cf.switch and skyIcons) or vanillaIcons
    local cave, door = icons[" cave"], icons.active_door
    if not doorRef.supportsLuaData then
        if doorRef.destination and doorRef.destination.cell then
            local cell = doorRef.destination.cell
            local temp = (checkForCaves(doorRef.id) and cave) or door
            cf.blocked[cell.id] = getIcon(doorRef.cell, cell, temp)
        end
        return
    end
    if doorRef.tempData and doorRef.tempData.spa_MapIcons then return end
    if doorRef.destination and doorRef.destination.cell then
        local cell = doorRef.destination.cell
        --mwse.log('destination.cell %s', cell)
        doorRef.tempData.spa_MapIcons = (checkForCaves(doorRef.id) and cave) or door
        doorRef.tempData.spa_MapIcons = getIcon(doorRef.cell, cell, doorRef.tempData.spa_MapIcons)
        if cf.Danae then doorRef.data.spa_MapIcons = doorRef.tempData.spa_MapIcons end
        doorRef.modified = true
    end
end

---@param e table|referenceActivatedEventData
event.register("referenceActivated", function(e)
    if cf.Danae then return end
    if not (e.reference and e.reference.object) then return end
    if (e.reference.object.objectType ~= tes3.objectType.door) then return end
    getDoorIcon(e.reference)
end)

---@param e table|activateEventData
event.register("activate", function(e)
    if not cf.Danae then return end
    if e.activator ~= tes3.player then return end
    if not (e.target and e.target.object) then return end
    if (e.target.object.objectType ~= tes3.objectType.door) then return end
    getDoorIcon(e.target)
end)


---@param e uiEventEventData
local function callBack(e)
    applyMapIcons(e.source)
end

--
---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    e.element:unregisterBefore("update", callBack)
    e.element:registerBefore("update", callBack)
end, { filter = "MenuMap" })
--]]

--[[
local myTimer
event.register("loaded", function()
    if myTimer then
        myTimer:cancel()
        myTimer = nil
    end
    local menu = tes3ui.findMenu("MenuMap")
    if menu then
        myTimer = timer.start { type = timer.real, duration = 0.5, iterations = -1, callback = function() applyMapIcons(menu) end }
    end
end)

--[[
---@param e menuEnterEventData
event.register("menuEnter", function(e)
    if e.menu ~= tes3ui.findMenu("MenuMap") then return end
    applyMapIcons(e.menu)
end)
--
---@param e table|cellChangedEventData
event.register("cellChanged", function(e)
    local menu = tes3ui.findMenu("MenuMap")
    if menu and menu.visible then
        menu:updateLayout()
        timer.delayOneFrame(function()
            applyMapIcons(menu)
        end)
    end
end)

--]]


---@param e mouseButtonDownEventData
local function mouseDown(e)
    if e.button == 0 then return end
    if mod.hello == "hello" then return end
    tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
    local cursor = node():getObjectByName("cursor") --[[@as niTriShape]]
    local texturingProperty = cursor.texturingProperty --[[@as niTexturingProperty]]
    local map = texturingProperty.baseMap --[[@as niTexturingPropertyMap]]
    local texture = niSourceTexture.createFromPath("textures/tx_cursor.dds")
    map.texture = texture
    cursor:updateProperties()
    mod.hello = "hello"
    return false
end event.register("mouseButtonDown", mouseDown, { priority = 1000 })

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
    local key = block:createLabel { text = label }
    image:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        local newPath = string.gsub(imagePath, "/", "\\")
        if ((image.contentPath == newPath) and (mod.hello == "hello") and (string.endswith(label:lower(), ".dds") or string.endswith(label:lower(), ".tga"))) then
            mod.hello = image.contentPath
            local cursor = node():getObjectByName("cursor") --[[@as niTriShape]]
            local texturingProperty = cursor.texturingProperty --[[@as niTexturingProperty]]
            local map = texturingProperty.baseMap --[[@as niTexturingPropertyMap]]
            local texture = niSourceTexture.createFromPath(mod.hello)
            map.texture = texture
            cursor:updateProperties()
        end
    end)
    key.consumeMouseEvents = true
    key:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        local newPath = string.gsub(imagePath, "/", "\\")
        if ((image.contentPath == newPath) and cf.customIconSearch[imagePath] and (string.endswith(label:lower(), ".dds") or string.endswith(label:lower(), ".tga"))) then
            config.createWindow(parent.parent.parent.parent.parent, imagePath, label, cf.customIconSearch[imagePath])
        end
    end)
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
    end) --]]
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
    createMapKey(page3, "Fighter's Guild", "fighter's guild")
    createMapKey(page3, "Mage's Guild", "mage's guild")
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

    if not table.empty(cf.customIconSearch) then
        createSeparator(page3, "Custom Icons")
        for path, label in pairs(cf.customIconSearch) do
            createMapKey(page3, label, path)
        end
    end
end


local function createHeader(page, text)
    local header = page:createLabel({ text = text })
    header.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header.borderBottom = 5
    return header
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
    page.heightProportional = 1
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
    page3.heightProportional = 1
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

    createHeader(page, "Icon Style:")
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

    createHeader(page, "Icon Size:")
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

    local header = createHeader(page, "Relative Positionning Color:")
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




    local buttonDesc2 = page2:createLabel({
        text =
        "Optional. With this toogled, the mod will display Icons only after you've activated the corresponding door."
    })
    buttonDesc2.visible = false

    local header2 = createHeader(page, "onActivate")
    header2.borderTop = 20
    local cycle12 = page:createCycleButton { options = { { text = "On", value = true }, { text = "Off", value = false } } }
    cycle12.borderBottom = 20
    cycle12.widget.value = cf.Danae
    cycle12:registerAfter("mouseClick", function()
        cf.Danae = cycle12.widget.value
        mwse.saveConfig(mod.name, cf)
    end)
    cycle12:register("mouseOver", function()
        label.visible = false
        link.visible = false
        buttonDesc2.visible = true
    end)
    cycle12:register("mouseLeave", function()
        label.visible = true
        link.visible = true
        buttonDesc2.visible = false
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
local function toggleList(layer, list, id)
    table.sort(list)
    local searchBlock = layer:createBlock()
    searchBlock.flowDirection = "left_to_right"
    searchBlock.autoHeight = true
    searchBlock.widthProportional = 1.0
    searchBlock.borderBottom = 0
    local searchBar = searchBlock:createThinBorder({ id = tes3ui.registerID("ExclusionsSearchBar") })
    searchBar.autoHeight = true
    searchBar.widthProportional = 1.0
    -- Create the search input itself.
    local text = searchBar:createTextInput({ id = id, placeholderText = "Search..." })
    text.borderLeft = 5
    text.borderRight = 5
    text.borderTop = 2
    text.borderBottom = 4
    text.widget.eraseOnFirstKey = true
    text.consumeMouseEvents = false
    searchBar.consumeMouseEvents = true
    searchBar:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        tes3ui.acquireTextInput(text)
    end)
    local button = searchBlock:createButton({ text = "Toggle Filtered" })
    button.heightProportional = 1.0
    -- button.alignY = 0.0
    button.borderAllSides = 0
    button.paddingAllSides = 2
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
                local icon = toolTip:createImage { id = "ttIcon", path = getIcon({ isOrBehavesAsExterior = true }, { id = cell }, nil) }
                icon.scaleMode = true
                icon.width = 16
                icon.height = 16
            end)
        end
        label:register("mouseClick", function()
            tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
            cf.whiteList[label.text] = (id == "blackList") or nil
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
    button:register("mouseClick", function()
        for _, child in pairs(pane.children) do
            if child.visible and (id ~= "switchIconer") then
                cf.whiteList[child.text] = (id == "blackList") or nil
            elseif child.visible then
                cf.blocked[child.text] = ((mod.hello ~= "hello") and mod.hello) or nil
            end
        end
        mwse.saveConfig(mod.name, cf)
        if id == "switchIconer" then
            mouseDown({ button == 1 })
            tes3.messageBox("Cells Icons succesfully changed!")
        else
            local parent = layer.parent
            parent:destroyChildren()
            config.thirdPage(parent)
            parent:getTopLevelMenu():updateLayout()
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
    local keys = {}
    for key, value in pairs(cf.whiteList) do
        if value then table.insert(keys, key) end
    end
    toggleList(layer, keys, "whiteList")
    layer = parent:createBlock()
    layer.widthProportional = 1
    layer.heightProportional = 0.945
    layer.flowDirection = "top_to_bottom"
    label = layer:createLabel { text = "Act as Interior Cells:" }
    label.color = tes3ui.getPalette(tes3.palette.headerColor)
    toggleList(layer, exclusionList(), "blackList")
end


function config.createWindow(parent, path, fileName, label)
    -- Return if window is already open
    if tes3ui.findMenu("spa_IconNameInput") then return end

    -- Create window and frame
    local menu = tes3ui.createMenu { id = "spa_IconNameInput", fixedFrame = true }

    -- To avoid low contrast, text input windows should not use menu transparency settings
    menu.alpha = 1.0

    -- Create layout
    local input_label = menu:createLabel { text = "Custom Icon Name" }
    input_label.borderBottom = 5

    local input_block = menu:createBlock {}
    input_block.width = 300
    input_block.autoHeight = true
    input_block.childAlignX = 0.5 -- centre content alignment

    local border = input_block:createThinBorder {}
    border.width = 300
    border.height = 30
    border.childAlignX = 0.5
    border.childAlignY = 0.5

    local input = border:createTextInput { placeholderText = (label or "Custom Icon") }
    --input.text = this.item.name -- initial text
    input.borderLeft = 5
    input.borderRight = 5
    input.widget.lengthLimit = 31 -- TextInput custom properties
    input.widget.eraseOnFirstKey = true

    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0       -- right content alignment

    local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }
    local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }

    -- Events
    button_cancel:register(tes3.uiEvent.mouseClick, function()
        menu:destroy()
    end)
    --menu:register(tes3.uiEvent.keyEnter, this.onOK) -- only works when text input is not captured
    input:register(tes3.uiEvent.keyEnter, function()
        button_ok:triggerEvent("mouseClick")
    end)
    button_ok:register(tes3.uiEvent.mouseClick, function()
        cf.customIconSearch[path] = ((type(input.text) == "string") and input.text) or "Custom Icon"
        cf.customIcons[fileName] = path
        mwse.saveConfig(mod.name, cf)
        parent:destroyChildren()
        config.fourthPage(parent)
        parent:getTopLevelMenu():updateLayout()
        tes3.messageBox("Custom Icon %s Added!", input.text)
        menu:destroy()
    end)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode("spa_IconNameInput")
    tes3ui.acquireTextInput(input) -- automatically reset when menu is closed
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
    toggleList(layer, keys, "switchIconer")
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
    local searchBlock = layer2:createBlock()
    searchBlock.flowDirection = "left_to_right"
    searchBlock.autoHeight = true
    searchBlock.widthProportional = 1.0
    searchBlock.borderBottom = 0
    local searchBar = searchBlock:createThinBorder()
    searchBar.autoHeight = true
    searchBar.widthProportional = 1.0
    -- Create the search input itself.
    local text = searchBar:createTextInput({ placeholderText = "Textures/" })
    text.borderLeft = 5
    text.borderRight = 5
    text.borderTop = 2
    text.borderBottom = 4
    text.widget.eraseOnFirstKey = true
    text.consumeMouseEvents = false
    searchBar.consumeMouseEvents = true
    searchBar:register("mouseClick", function()
        tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
        tes3ui.acquireTextInput(text)
    end)
    local button = searchBlock:createButton({ text = "Validate" })
    button.heightProportional = 1
    -- button.alignY = 0.0
    button.borderAllSides = 0
    button.paddingAllSides = 2
    button:register("mouseClick", function()
        local success, c = pcall(function() return lfs.fileexists("Data Files/" .. text.text) end)
        if (success and c) and (string.endswith(text.text:lower(), ".dds") or string.endswith(text.text:lower(), ".tga")) then
            local fileName = string.lower(text.text):match(".*/(.*)")
            local path = text.text:lower()
            config.createWindow(parent, path, fileName)
        else
            tes3.messageBox("Invalid File.")
        end
    end)
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

local modConfig = {}
function modConfig.onSearch(search)
    return string.startswith("spammer", search)
end

---@param container tes3uiElement
function modConfig.onCreate(container)
    container.flowDirection = "top_to_bottom"
    container.wrapText = true
    local switcher = container:createThinBorder()
    switcher.height = 25
    switcher.widthProportional = 1
    local label = container:createLabel { text = [[]] }
    label.borderBottom = 20
    label.visible = false
    local parent = container:createBlock()
    parent.height = container.height - 25
    parent.widthProportional = 1
    parent.flowDirection = "left_to_right"
    config.firstPage(parent)
    local page2
    local page3
    local page1 = switcher:createButton { text = "Mod Config" }
    page1.widget.state = tes3.uiState.active
    page1:register("mouseClick", function()
        page1.widget.state = tes3.uiState.active
        page2.widget.state = tes3.uiState.normal
        page3.widget.state = tes3.uiState.normal
        parent:destroyChildren()
        label.text = [[]]
        label.visible = false
        config.firstPage(parent)
        parent:getTopLevelMenu():updateLayout()
    end)
    --
    page2 = switcher:createButton { text = "Customization" }
    page2:register("mouseClick", function()
        page2.widget.state = tes3.uiState.active
        page1.widget.state = tes3.uiState.normal
        page3.widget.state = tes3.uiState.normal
        parent:destroyChildren()
        label.text =
        [[Registering your own Icons: Enter the icon path, relative to "Data Files/" (e.g. "Textures/compass.tga", "Icons/c/c_ring_khajiit.dds"), in the text input. Press [Enter] or click the button to Validate.

Changing Cell Icons: [Left Click] on one of the icon images. Once the pointer changes shape, find the cell you want to edit the icon of in the right panel, and [Left Click] on it. [Right Click] or [Middle Mouse Click] to switch to the normal pointer again.]]
        label.visible = true
        config.fourthPage(parent)
        parent:getTopLevelMenu():updateLayout()
    end)
    --page2.visible = false
    --]]
    page3 = switcher:createButton { text = "Cells Whitelist" }
    page3:register("mouseClick", function()
        page3.widget.state = tes3.uiState.active
        page1.widget.state = tes3.uiState.normal
        page2.widget.state = tes3.uiState.normal
        parent:destroyChildren()
        label.text =
        [[Whitelist cells that should act as Exterior.]]
        label.visible = true
        config.thirdPage(parent)
        parent:getTopLevelMenu():updateLayout()
    end)
end

event.register("modConfigReady", function()
    mwse.registerModConfig(mod.name, modConfig)
end)


local function initialized()
    if table.empty(cf.whiteList) then
        for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
            if cell.isInterior and (string.endswith(cell.id, "works")
                    or (string.startswith(cell.id:lower(), "vivec, ") and string.endswith(cell.id:lower(), " plaza"))
                ) then
                print(cell.id)
                cf.whiteList[cell.id] = true
            end
        end
        cf.whiteList["emptyWhiteList"] = false
        mwse.saveConfig(mod.name, cf)
    end
    if not table.empty(cf.customIcons) then
        for _, path in pairs(cf.customIcons) do
            if not cf.customIconSearch[path] then
                cf.customIconSearch[path] = "Custom Icon"
            end
        end
    end
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = -1000 })
