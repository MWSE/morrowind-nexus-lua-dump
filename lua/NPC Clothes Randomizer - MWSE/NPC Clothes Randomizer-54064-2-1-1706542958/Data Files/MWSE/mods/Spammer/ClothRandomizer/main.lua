

---
---I don't know what you're doing here, but if you care for your sanity, run.
---This code is a mess!
---


local completeList = {}
local mod = {
    name = "NPC Clothes Randomizer",
    ver = "2.1",
    author = "Spammer",
    cf = { onOff = true }
}

mod.cf.blacklist = {
    [tes3.clothingSlot.shirt] = {},
    [tes3.clothingSlot.skirt] = {},
    [tes3.clothingSlot.shoes] = {},
    [tes3.clothingSlot.pants] = {},
    [tes3.clothingSlot.robe] = {},
    [tes3.clothingSlot.ring] = {},
    [tes3.clothingSlot.amulet] = {},
    [tes3.clothingSlot.belt] = {}
}

mod.cf.common = {
    [tes3.clothingSlot.shirt] = {},
    [tes3.clothingSlot.skirt] = {},
    [tes3.clothingSlot.shoes] = {},
    [tes3.clothingSlot.pants] = {},
    [tes3.clothingSlot.robe] = {},
    [tes3.clothingSlot.ring] = {},
    [tes3.clothingSlot.amulet] = {},
    [tes3.clothingSlot.belt] = {}
}

mod.cf.expensive = {
    [tes3.clothingSlot.shirt] = {},
    [tes3.clothingSlot.skirt] = {},
    [tes3.clothingSlot.shoes] = {},
    [tes3.clothingSlot.pants] = {},
    [tes3.clothingSlot.robe] = {},
    [tes3.clothingSlot.ring] = {},
    [tes3.clothingSlot.amulet] = {},
    [tes3.clothingSlot.belt] = {}
}

mod.cf.extravagant = {
    [tes3.clothingSlot.shirt] = {},
    [tes3.clothingSlot.skirt] = {},
    [tes3.clothingSlot.shoes] = {},
    [tes3.clothingSlot.pants] = {},
    [tes3.clothingSlot.robe] = {},
    [tes3.clothingSlot.ring] = {},
    [tes3.clothingSlot.amulet] = {},
    [tes3.clothingSlot.belt] = {}
}

mod.cf.exquisite = {
    [tes3.clothingSlot.shirt] = {},
    [tes3.clothingSlot.skirt] = {},
    [tes3.clothingSlot.shoes] = {},
    [tes3.clothingSlot.pants] = {},
    [tes3.clothingSlot.robe] = {},
    [tes3.clothingSlot.ring] = {},
    [tes3.clothingSlot.amulet] = {},
    [tes3.clothingSlot.belt] = {}
}

local cf = mwse.loadConfig(mod.name, mod.cf)

--]]

local multiplier = {
    [tes3.clothingSlot.shirt] = 1.5,
    [tes3.clothingSlot.skirt] = 1.5,
    [tes3.clothingSlot.shoes] = 1,
    [tes3.clothingSlot.pants] = 1.5,
    [tes3.clothingSlot.robe] = 1,
    [tes3.clothingSlot.ring] = 3,
    [tes3.clothingSlot.amulet] = 3,
    [tes3.clothingSlot.belt] = 1
}

local names = {}

---@param cloth tes3clothing
---@return string
local function rarity(cloth)
    local price = (cloth.value / multiplier[cloth.slot])
    return ((string.find(cloth.name:lower(), "exquis") ~= nil) and "exquisite")
        or ((string.find(cloth.name:lower(), "extravagant") ~= nil) and "extravagant")
        or ((string.find(cloth.name:lower(), "expensive") ~= nil) and "expensive")
        or ((string.find(cloth.name:lower(), "common") ~= nil) and "common")
        or (price >= 80 and "exquisite")
        or (price >= 40 and "extravagant")
        or (price >= 10 and "expensive")
        or "common"
end


local function traverse(list)
    local data = {}
    for _, subtable in pairs(list) do
        for _, id in ipairs(subtable) do
            table.insert(data, id)
        end
    end
    table.sort(data)
    return data
end

---@param e mobileActivatedEventData
local function onMobileActivated(e)
    if not (e.reference and e.mobile) then return end
    if (e.reference == tes3.player) or (e.mobile == tes3.mobilePlayer) then
        return
    end
    if e.reference.object.objectType ~= tes3.objectType.npc then
        return
    end
    local data = e.reference.data and e.reference.data.spa_randomClothes
    if data then
        if type(data) == "boolean" then
            e.reference.data.spa_randomClothes = tes3.getSimulationTimestamp()
            return
        elseif (data > (tes3.getSimulationTimestamp() - 24)) or (cf.onOff == false) then
            return
        end
    end

    local script = e.reference.baseObject.script
    if script then
        local scriptVars = script:getVariableData()
        if scriptVars then
            for var in pairs(scriptVars) do
                var = var:lower()
                if var == "companion" then
                    return
                end
            end
        end
    end
    local newClothes = {}
    local oldClothes = {}
    local equipment = e.mobile.object.equipment
    for _, stack in ipairs(equipment) do
        local item = stack.object
        if completeList[item.id] and (completeList[item.id] ~= "blacklist") then
            local rare = completeList[item.id]
            local choices = cf[rare][item.slot]
            if table.find(choices, item.id) then
                newClothes[item.slot] = table.choice(choices)
                oldClothes[item.slot] = { object = item, itemData = stack.itemData }
            end
        end
    end

    if not table.empty(newClothes) then
        for slot, cloth in pairs(newClothes) do
            if data then
                local stack = oldClothes[slot]
                tes3.removeItem { reference = e.reference, item = stack.object, itemData = stack.itemData, playSound = false, updateGUI = false }
            end
            e.mobile:equip { item = cloth, addItem = true }
        end
        e.reference.data.spa_randomClothes = tes3.getSimulationTimestamp()
        e.reference.modified = true
    end
end

local timeStamp
---@param e menuEnterEventData|menuExitEventData
local function onMenuEnterExit(e)
    if not cf.onOff then return end
    if not tes3.player then return end
    if e.menuMode then
        timeStamp = tes3.getSimulationTimestamp()
    elseif timeStamp and (timeStamp <= (tes3.getSimulationTimestamp() - 24)) then
        for _, cell in ipairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences(tes3.objectType.npc) do
                onMobileActivated({ reference = ref, mobile = ref.mobile, claim = false })
            end
        end
    end
end

local buttonRare = {
    [0] = "common",
    [1] = "expensive",
    [2] = "extravagant",
    [3] = "exquisite",
    [4] = "blacklist",
}

local modConfig = {}

local function createPane(layer, rare)
    local list = traverse(cf[rare])
    local searchBlock = layer:createBlock()
    searchBlock.flowDirection = "left_to_right"
    searchBlock.autoHeight = true
    searchBlock.widthProportional = 1.0
    searchBlock.borderBottom = 0
    local searchBar = searchBlock:createThinBorder({ id = tes3ui.registerID("ExclusionsSearchBar") })
    searchBar.autoHeight = true
    searchBar.widthProportional = 1.0
    -- Create the search input itself.
    local text = searchBar:createTextInput({ id = rare, placeholderText = "Search..." })
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
    button.borderAllSides = 0
    button.paddingAllSides = 2
    local pane = layer:createVerticalScrollPane()
    pane.widthProportional = 1
    pane.height = layer.height - 40
    pane = pane:getContentElement()

    for _, clothID in ipairs(list) do
        local cloth = tes3.getObject(clothID)
        local label = pane:createLabel { id = clothID, text = clothID }
        label.consumeMouseEvents = true
        label:register("mouseOver", function()
            label.color = tes3ui.getPalette(tes3.palette.normalOverColor)
            label:getTopLevelMenu():updateLayout()
        end)
        label:register("mouseLeave", function()
            label.color = tes3ui.getPalette(tes3.palette.normalColor)
            label:getTopLevelMenu():updateLayout()
        end)
        label:register("help", function()
            local tooltip = tes3ui.createTooltipMenu { item = cloth }
            local block1 = tooltip:createBlock()
            block1.flowDirection = "left_to_right"
            block1.autoWidth = true
            block1.autoHeight = true
            block1.paddingAllSides = -1
            block1.childAlignY = 0.5
            local image = block1:createImage { path = "Icons\\" .. cloth.icon }
            image.borderAllSides = 2
            local name = tooltip:findChild("HelpMenu_name")
            local label1 = block1:createLabel { text = (name and name.text) or cloth.name }
            label1.wrapText = true
            label1.color = (name and name.color) or tes3ui.getPalette(tes3.palette.disabledPressedColor)
            block1.parent:reorderChildren(name, block1, 1)
            name.visible = false
            local block2 = tooltip:createBlock()
            block2.flowDirection = "left_to_right"
            block2.autoWidth = true
            block2.autoHeight = true
            block2.paddingAllSides = -1
            block2.childAlignY = 0.5
            block2:createLabel { text = "Source: " .. (cloth.sourceMod or "None.") }
        end)
        label:register("mouseClick", function()
            tes3.playSound { sound = tes3.worldController.menuClickSound, loop = false }
            tes3.messageBox { message = "Which rarity?", buttons = { "Common", "Expensive", "Extravagant", "Exquisite", "Blacklist" }, callback = function(
                e)
                table.removevalue(cf[rare][cloth.slot], clothID)
                table.insert(cf[buttonRare[e.button]][cloth.slot], clothID)
                completeList[cloth.id] = rare
                mwse.saveConfig(mod.name, cf)
                local saveText = text.text
                local parent = layer.parent.parent
                parent:destroyChildren()
                modConfig.onCreate(parent)
                local newtext = parent:findChild(rare)
                if saveText ~= newtext.text then
                    newtext.text = saveText
                    newtext:triggerEvent("textUpdated")
                end
                parent:getTopLevelMenu():updateLayout()
            end }
        end)
    end
    text:registerAfter("textUpdated", function(e)
        local search = e.source.text:lower()
        for _, child in pairs(pane.children) do
            local cloth = tes3.getObject(child.text)
            child.visible = (string.find(cloth.id:lower(), search, 1, true) ~= nil) or (string.find(cloth.name:lower(), search, 1, true) ~= nil)
        end
    end)
    text:registerAfter("textCleared", function()
        for _, child in pairs(pane.children) do
            child.visible = true
        end
    end)
    button:register("mouseClick", function()
        tes3.messageBox { message = "Which rarity?", buttons = { "Common", "Expensive", "Extravagant", "Exquisite", "Blacklist" }, callback = function(
            e)
            for _, child in pairs(pane.children) do
                if child.visible then
                    local cloth = tes3.getObject(child.text)
                    table.removevalue(cf[rare][cloth.slot], cloth.id)
                    table.insert(cf[buttonRare[e.button]][cloth.slot], cloth.id)
                    completeList[cloth.id] = rare
                end
            end
            mwse.saveConfig(mod.name, cf)
            local parent = layer.parent.parent
            parent:destroyChildren()
            modConfig.onCreate(parent)
            parent:getTopLevelMenu():updateLayout()
        end }
    end)
end


local function createRarityPane(page, name)
    local common = page:createBlock()
    common.childAlignX = 0.5
    common.flowDirection = "top_to_bottom"
    common.heightProportional = 1.0
    common.widthProportional = 1.0
    common:createLabel({ text = name })
    createPane(common, name:lower())
end

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
    page.childAlignX = 0.5
    --page.childAlignY = 0.5
    local page2 = parent:createThinBorder({})
    page2.flowDirection = "top_to_bottom"
    page2.heightProportional = 1.0
    page2.widthProportional = 1.0
    page2.paddingAllSides = 12
    local block = page2:createBlock()
    block.wrapText = true
    block.heightProportional = 1.0
    block.widthProportional = 1.0
    block.flowDirection = "top_to_bottom"
    block:createLabel({ text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by " .. mod.author .. ".\n" })
    block:createHyperlink({
        text = "Spammer's Nexus Profile",
        url = "https://www.nexusmods.com/users/140139148?tab=user+files"
    })
    local desc = block:createLabel { text = (cf.onOff and [[
This mod randomizes NPCs clothes every 24h.
Blacklisted Items will not be swapped.]]) or [[
This mod randomizes NPCs clothes once per playthrough.
Blacklisted Items will not be swapped.]] }
    desc.borderAllSides = 10
    local button = block:createLabel { text = "Daily Swaps?" }
    button.borderTop = 30
    button.borderBottom = 5
    local cycle = block:createCycleButton { options = { { text = "On", value = true }, { text = "Off", value = false } } }
    cycle.borderBottom = 20
    cycle.widget.value = cf.onOff
    cycle:registerAfter("mouseClick", function()
        cf.onOff = cycle.widget.value
        mwse.saveConfig(mod.name, cf)
        parent:destroyChildren()
        modConfig.onCreate(parent)
        parent:getTopLevelMenu():updateLayout()
    end)
    createRarityPane(page, "Common")
    createRarityPane(page, "Expensive")
    createRarityPane(page, "Extravagant")
    createRarityPane(page, "Exquisite")
    createRarityPane(page2, "Blacklist")
end

local function registerModConfig()
    mwse.registerModConfig(mod.name, modConfig)
end
event.register("modConfigReady", registerModConfig)



local function validCloth(cloth)
    if cf.common[cloth.slot] then
        return ((table.find(cf.common[cloth.slot], cloth.id) == nil)
            and (table.find(cf.expensive[cloth.slot], cloth.id) == nil)
            and (table.find(cf.extravagant[cloth.slot], cloth.id) == nil)
            and (table.find(cf.exquisite[cloth.slot], cloth.id) == nil)
            and (table.find(cf.blacklist[cloth.slot], cloth.id) == nil))
    end
    return false
end

local function initialized()
    table.insert(names, tes3.getObject("common_skirt_01").name)
    table.insert(names, tes3.getObject("extravagant_skirt_01").name)
    table.insert(names, tes3.getObject("expensive_skirt_01").name)
    table.insert(names, tes3.getObject("exquisite_skirt_01").name)
    table.insert(names, tes3.getObject("common_shirt_01").name)
    table.insert(names, tes3.getObject("extravagant_shirt_01").name)
    table.insert(names, tes3.getObject("expensive_shirt_01").name)
    table.insert(names, tes3.getObject("exquisite_shirt_01").name)
    table.insert(names, tes3.getObject("common_shoes_01").name)
    table.insert(names, tes3.getObject("extravagant_shoes_01").name)
    table.insert(names, tes3.getObject("expensive_shoes_01").name)
    table.insert(names, tes3.getObject("exquisite_shoes_01").name)
    table.insert(names, tes3.getObject("common_pants_01").name)
    table.insert(names, tes3.getObject("extravagant_pants_01").name)
    table.insert(names, tes3.getObject("expensive_pants_01").name)
    table.insert(names, tes3.getObject("exquisite_pants_01").name)
    table.insert(names, tes3.getObject("common_ring_01").name)
    table.insert(names, tes3.getObject("extravagant_ring_01").name)
    table.insert(names, tes3.getObject("expensive_ring_01").name)
    table.insert(names, tes3.getObject("exquisite_ring_01").name)
    table.insert(names, tes3.getObject("common_robe_01").name)
    table.insert(names, tes3.getObject("extravagant_robe_01").name)
    table.insert(names, tes3.getObject("expensive_robe_01").name)
    table.insert(names, tes3.getObject("exquisite_robe_01").name)
    table.insert(names, tes3.getObject("common_amulet_01").name)
    table.insert(names, tes3.getObject("extravagant_amulet_01").name)
    table.insert(names, tes3.getObject("expensive_amulet_01").name)
    table.insert(names, tes3.getObject("exquisite_amulet_01").name)
    table.insert(names, tes3.getObject("common_belt_01").name)
    table.insert(names, tes3.getObject("extravagant_belt_01").name)
    table.insert(names, tes3.getObject("expensive_belt_01").name)
    table.insert(names, tes3.getObject("exquisite_belt_01").name)
    names = table.invert(names)
    ---@param cloth tes3clothing
    for cloth in tes3.iterateObjects(tes3.objectType.clothing) do
        if not (cloth.enchantment or cloth.script) and validCloth(cloth) then
            local value = ((names[cloth.name] ~= nil) and rarity(cloth)) or "blacklist"
            table.insert(cf[value][cloth.slot], cloth.id)
        end
    end
    mwse.saveConfig(mod.name, cf)
    for _, v in pairs(buttonRare) do
        for _, k in ipairs(traverse(cf[v])) do
            completeList[k] = v
        end
    end
    event.register("mobileActivated", onMobileActivated, { priority = -1000 })
    event.register("menuEnter", onMenuEnterExit)
    event.register("menuExit", onMenuEnterExit)
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = 1000 })
