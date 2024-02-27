local mod = {
    name = "Containers Extended",
    ver = "1.1.1",
    author = "Spammer",
}


local currentRef

local ids = {

    "g7_container_ALCH",
    "g7_container_AMMO",
    "g7_container_ARMO",
    "g7_container_BOOK",
    "g7_container_CLOT",
    "g7_container_INGR",
    "g7_container_KEYS",
    "g7_container_LOCK",
    "g7_container_MISC",
    "g7_container_REPA",
    "g7_container_SCRL",
    "g7_container_SOUL",
    "g7_container_WEAP",

}

local weight = {
}


local allowed = {
    [ids[1]] = "potion",
    [ids[2]] = "ammunition or thrown weapon",
    [ids[3]] = "armor",
    [ids[4]] = "book",
    [ids[5]] = "clothing",
    [ids[6]] = "ingredient",
    [ids[7]] = "key",
    [ids[8]] = "lockpick or probe",
    [ids[9]] = "miscellanious",
    [ids[10]] = "repair",
    [ids[11]] = "scrolls",
    [ids[12]] = "soulgems",
    [ids[13]] = "weapon",
}

---@param id string
---@param item tes3book|tes3misc|tes3item
---@return boolean|nil
local function itemCheck(id, item)
    local check = {
        [ids[1]] = (tes3.objectType.alchemy == item.objectType),
        [ids[2]] = (tes3.objectType.weapon == item.objectType and tes3.weaponType.marksmanThrown == item.type) or
            (tes3.objectType.ammunition == item.objectType),
        [ids[3]] = (tes3.objectType.armor == item.objectType),
        [ids[4]] = (tes3.objectType.book == item.objectType) and (tes3.bookType.book == item.type),
        [ids[5]] = (tes3.objectType.clothing == item.objectType),
        [ids[6]] = (tes3.objectType.ingredient == item.objectType),
        [ids[7]] = (tes3.objectType.miscItem == item.objectType) and item.isKey,
        [ids[8]] = (tes3.objectType.lockpick == item.objectType) or (tes3.objectType.probe == item.objectType),
        [ids[9]] = (tes3.objectType.miscItem == item.objectType) and not (item.isKey or item.isSoulGem or item.isGold),
        [ids[10]] = tes3.objectType.repairItem == item.objectType,
        [ids[11]] = (tes3.objectType.book == item.objectType) and (tes3.bookType.scroll == item.type),
        [ids[12]] = (tes3.objectType.miscItem == item.objectType) and item.isSoulGem,
        [ids[13]] = (tes3.objectType.weapon == item.objectType) and tes3.weaponType.marksmanThrown ~= item.type,
    }

    return check[id]
end
local items = {}

for _, v in pairs(ids) do
    local i = string.gsub(v, "container", "inventory")
    items[i] = v
end

local containers = table.invert(items)


---@param itemData tes3itemData
---@param id string
---@return tes3reference
local function checkData(itemData, id)
    local data = itemData and itemData.data and itemData.data.g7container
    return (data and tes3.getReference(data)) or tes3.getReference(id)
end

---@param id string
---@param ref tes3reference
---@param item tes3alchemy
local function updateWeight(id, ref, item)
    local mult = tes3.getGlobal("g7_container_mult")
    local calculatedWeight = weight[id] + (mult * ref.object.inventory:calculateWeight())
    if item.weight ~= calculatedWeight then
        item.weight = calculatedWeight
        if tes3.mobilePlayer.object.inventory:contains(item) then
            local current = tes3.mobilePlayer.object.inventory:calculateWeight()
            local feather = tes3.getEffectMagnitude { reference = tes3.player, effect = tes3.effect.feather }
            local burden = tes3.getEffectMagnitude { reference = tes3.player, effect = tes3.effect.burden }
            tes3.setStatistic { reference = tes3.player, name = "encumbrance", current = (current + burden - feather) }
        end
    end
end


---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    if not currentRef then return end
    tes3ui.forcePlayerInventoryUpdate()
    local close = e.element:findChild("MenuContents_closebutton")
    if not close then return end
    close:registerBefore(tes3.uiEvent.mouseClick, function()
        local ref = tes3.getReference(currentRef)
        local inventory = ref.object.inventory.items
        for _, stack in ipairs(inventory) do
            local item = stack.object
            if not itemCheck(currentRef, item) then
                if item.id ~= "g7_initialized" then
                    tes3.messageBox("Only %s items allowed in this container! Remove %s.", allowed[currentRef], item.name)
                    return false
                end
            elseif items[item.id] then
                tes3.messageBox("A container is inside another container! Remove it to continue.")
                return false
            end
        end
    end)
    e.element:registerBefore("destroy", function()
        currentRef = nil
    end)
end, { filter = "MenuContents" })


local function activateOrEquip()
    local ref = tes3.getReference(currentRef)
    ref:clone()
    timer.delayOneFrame(function()
        tes3.showContentsMenu { reference = ref }
        tes3ui.forcePlayerInventoryUpdate()
        event.trigger("uiActivated",
            { claim = true, newlyCreated = true, element = tes3ui.findMenu("MenuContents") })
    end)
end


local function stashAll(item)
    if not currentRef then return end
    local ref = tes3.getReference(currentRef)
    if ref then
        tes3.transferInventory { to = ref, from = tes3.player, limitCapacity = false,
            filter = function(item, itemData)
                return itemCheck(currentRef, item) and not tes3.mobilePlayer.object:hasItemEquipped(item, itemData)
            end }
    end
    updateWeight(containers[currentRef], ref, item)
    currentRef = nil
end


local function retrieveAll()
    if not currentRef then return end
    local ref = tes3.getReference(currentRef)
    if ref then
        tes3.transferInventory { to = tes3.player, from = ref, limitCapacity = false, checkCrime = true, 
            filter = function(item)
                return (item.id:lower() ~= "g7_initialized")
            end }
    end
    local item = tes3.getObject(containers[currentRef])
    updateWeight(containers[currentRef], ref, item)
    currentRef = nil
end



---@param e table|equippedEventData
event.register("equipped", function(e)
    if tes3.player ~= e.reference then return end
    local id = e.item and e.item.id
    if not items[id] then return end
    tes3.mobilePlayer:unequip { item = e.item, itemData = e.itemData }
    currentRef = checkData(e.itemData, items[id]).id
    tes3.messageBox { message = "What do you want to do?", buttons = { "Browse", "Stash All", "Retrieve All", "Cancel" }, callback = function(
        f)
        if f.button == 0 then
            tes3ui.leaveMenuMode()
            activateOrEquip()
        elseif f.button == 1 then
            stashAll()
        elseif f.button == 2 then
            retrieveAll()
        elseif f.button == 3 then
            currentRef = nil
        end
    end }
end)


---@param e table|equipEventData
event.register("equip", function(e)
    if tes3.player ~= e.reference then return end
    local id = e.item and e.item.id
    if not items[id] then return end
    currentRef = checkData(e.itemData, items[id]).id
    debug.log(currentRef)
    tes3.messageBox { message = "What do you want to do?", buttons = { "Browse", "Stash All", "Retrieve All", "Cancel" }, callback = function(
        f)
        if f.button == 0 then
            tes3ui.leaveMenuMode()
            activateOrEquip()
        elseif f.button == 1 then
            stashAll()
        elseif f.button == 2 then
            retrieveAll()
        elseif f.button == 3 then
            currentRef = nil
        end
    end }
    return false
end, { priority = 1000 })



local skip = false
--Item activated
event.register("activate", function(e)
    if skip then
        skip = false
        return
    end
    if tes3ui.menuMode() then return end
    if tes3.player ~= e.activator then return end
    if not tes3.hasOwnershipAccess { target = e.target } then return end
    local target = e.target
    local container = target and target.baseObject
    if not container then return end
    if not items[container.id] then return end
    currentRef = items[container.id]
    tes3.messageBox { message = "What do you want to do?", buttons = { "Pick Up", "Browse", "Stash All", "Retrieve All" }, callback = function(
        f)
        if f.button == 0 then
            currentRef = nil
            skip = true
            timer.delayOneFrame(function() tes3.player:activate(target) end)
        elseif f.button == 1 then
            activateOrEquip()
        elseif f.button == 2 then
            stashAll()
        elseif f.button == 3 then
            retrieveAll()
        end
    end }
    return false
end)

--Container activated
---@param e table|activateEventData
event.register("activate", function(e)
    if tes3ui.menuMode() then return end
    if tes3.player ~= e.activator then return end
    if not tes3.hasOwnershipAccess { target = e.target } then return end
    if e.target.lockNode then return end
    local id = e.target and e.target.baseObject and e.target.baseObject.id
    if not id then return end
    if not containers[id] then return end
    currentRef = e.target.id
    tes3.messageBox { message = "What do you want to do?", buttons = { "Pick Up", "Browse", "Stash All", "Retrieve All" }, callback = function(f)
        if f.button == 0 then
            --tes3.addItem { reference = tes3.player, item = containers[id] }
            tes3.addItem { reference = e.target, item = "g7_initialized" }
            local item = tes3.createReference { object = containers[id], orientation = e.target.orientation, position = e.target.position, cell = e.target.cell }
            item.data.g7container = e.target.id
            skip = true
            timer.delayOneFrame(function() tes3.player:activate(item) end)
            e.target:disable()
            currentRef = nil
        elseif f.button == 1 then
            activateOrEquip()
        elseif f.button == 2 then
            stashAll()
        elseif f.button == 3 then
            retrieveAll()
        end
    end }
    return false
end, { priority = 1000 })



---@param e itemTileUpdatedEventData
event.register("itemTileUpdated", function(e)
    e.element:registerBefore("mouseClick", function()
        local c = tes3ui.findHelpLayerMenu("CursorIcon")
        if currentRef and not (itemCheck(currentRef, e.item) or c) then
            tes3.messageBox("Only %s items allowed in this container!", allowed[currentRef])
            return false
        end
    end)


    local id = e.item and e.item.id
    if not items[id]
        or e.menu:getPropertyObject("MenuContents_Actor")
        or e.menu:getPropertyObject("MenuContents_ObjectContainer")
    then
        return
    end

    local ref = checkData(e.itemData, items[id])
    if ref then
        ref:clone()
        updateWeight(id, ref, e.item)
        ref:onCloseInventory()
    end

    e.element:registerBefore("mouseClick", function()
        local menu = tes3ui.findMenu("MenuBarter")
        if menu then
            tes3.messageBox("Containers cannot be traded!")
            return false
        end

        local success, c = pcall(function()
            -- Get the thing that is currently on the cursor tile.
            local c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            -- Ensure it's an object from player inventory.
            local pcInventory = tes3.player.object.inventory
            return assert(
                pcInventory:contains(c.item, c.itemData)
                and pcInventory:contains(e.item, e.itemData)
                and c
            )
        end)
        if success and c and ref then
            if (itemCheck(items[id], c.item))
                and not items[c.item] then
                local count = c.count or 1
                tes3.transferItem { from = tes3.player, to = ref, item = c.item, itemData = c.itemData, count = count }
                tes3.messageBox("%s succesfully trasferred to %s.", c.item.name, e.item.name)
                e.menu:findChild("MenuInventory_scrollpane"):getContentElement():triggerEvent(tes3.uiEvent.mouseClick)
                timer.frame.delayOneFrame(function()
                    tes3ui.forcePlayerInventoryUpdate()
                end)
            else
                tes3.messageBox("Only %s items allowed in this container!", allowed[items[id]])
            end
            return false
        end
    end)
end, { filter = "MenuInventory" })

---@param e table|uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local id = (e.reference and e.reference.baseObject.id) or e.object.id
    if items[id] or containers[id] then
        local ref = (items[id] and (checkData(e.itemData, items[id]))) or e.reference
        if ref then
            ref:clone()
            local inventory = ref.object.inventory.items
            local min = math.min(#inventory, 10)
            for i = 1, min do
                local item = inventory[i].object
                if item and (item.id ~= "g7_initialized") then
                    local block = e.tooltip:createBlock()
                    block.minWidth = 1
                    --block.maxWidth = 230
                    block.wrapText = true
                    block.autoWidth = true
                    block.autoHeight = true
                    block.paddingAllSides = -1
                    block.flowDirection = "left_to_right"
                    local image = block:createImage { path = "Icons\\" .. item.icon }
                    image.scaleMode = true
                    image.width = 16
                    image.height = 16
                    image.borderAllSides = 5
                    local label = block:createLabel { text = string.format("%s (%s)", item.name, inventory[i].count) }
                    label.wrapText = true
                end
            end
            local remainder = #inventory - min
            if remainder > 0 then
                local label = e.tooltip:createLabel { text = string.format("... + %s other(s)", remainder) }
                label.color = tes3ui.getPalette(tes3.palette.disabledColor)
                --label.absolutePosAlignX = 0.1
                label.wrapText = false
            end
            --ref:onCloseInventory()
        end
    end
end)


---@param e table|activateEventData
event.register("activate", function(e)
    if tes3.player ~= e.activator then return end
    local cRef = e.target
    local key = cRef.lockNode and cRef.lockNode.key
    if not key then return end
    if tes3.mobilePlayer.object.inventory:contains(key) then return end
    local keyRing = tes3.mobilePlayer.object.inventory:contains("g7_inventory_KEYS")
    if not keyRing then return end
    local ref = tes3.getReference("g7_container_KEYS")
    if ref then
        ref:clone()
        if ref.object.inventory:contains(key) then
            local sKeyUsed = key.name .. ' ' .. tes3.findGMST(tes3.gmst.sKeyUsed).value;
            tes3.messageBox(sKeyUsed);
            tes3.unlock { reference = cRef };
            tes3.setTrap { reference = cRef };
            cRef.modified = true;
            tes3.playSound { sound = 'Open Lock', reference = cRef };
        end
    end
end)


event.register("spellTick", function(e)
    local reference = tes3.player
    local spell = e.source
    if reference == e.target and string.startswith(spell.id:lower(), "g7_burden_") then
        tes3.removeSpell { reference = reference, spell = spell }
    end
end)


local function overrideScript()
end

-- Script overrides can be queued when initialited event triggers.
event.register(tes3.event.initialized, function()
    mwse.overrideScript("g7_inventory_scri", overrideScript)
    mwse.overrideScript("g7_container_scri", overrideScript)
    for item, _ in pairs(items) do
        weight[item] = tes3.getObject(item).weight
    end
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end, { priority = -1000 })


