local mod = require("Spammer\\G7 Containers\\mod")
local price = require("Spammer\\G7 Containers\\vendor")
local renamer = require("Spammer\\G7 Containers\\renamer")
local i18n = mwse.loadTranslations("Spammer\\G7 Containers")
local allowed = mod.allowed
local containers = mod.containers
local itemCheck = mod.itemCheck
local items = table.invert(containers)
local skip = false
local weight = {}
local currentRef
local currentName
local function updateWeight(id, ref, item)
    if not (id and weight[id]) then return end
    item = item or tes3.getObject(id)
    if not (ref and item) then return end
    local mult = tes3.getGlobal("g7_container_mult")
    ref:clone()
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


---@param itemData tes3itemData|nil
---@return tes3reference|nil
---@return string|nil
local function checkData(itemData)
    local data = itemData and itemData.data and itemData.data.g7containers
    if data then
        return tes3.getReference(data.linkedRef), data.baseObject
    end
end


---@param ref tes3reference
local function activateOrEquip(ref)
    if not currentRef then return end
    if not ref then
        currentRef = nil
        return
    end
    ref:clone()
    timer.delayOneFrame(function()
        tes3.showContentsMenu { reference = ref }
        tes3ui.forcePlayerInventoryUpdate()
        event.trigger("uiActivated",
            { claim = true, newlyCreated = true, element = tes3ui.findMenu("MenuContents") })
    end)
end


---@param ref tes3reference
---@param linkedItem tes3alchemy|nil
local function stashAll(ref, linkedItem)
    if not currentRef then return end
    if ref then
        tes3.transferInventory { to = ref, from = tes3.player, limitCapacity = false,
            filter = function(item, itemData)
                return itemCheck(currentRef, item) and not tes3.mobilePlayer.object:hasItemEquipped(item.id, itemData)
            end }
        updateWeight(containers[currentRef], ref, linkedItem)
    end
    currentRef = nil
end

---@param ref tes3reference
---@param linkedItem tes3alchemy|nil
local function retrieveAll(ref, linkedItem)
    if not currentRef then return end
    if ref then
        tes3.transferInventory { to = tes3.player, from = ref, limitCapacity = false, checkCrime = true,
            filter = function(item)
                return itemCheck(currentRef, item)
            end }
        updateWeight(containers[currentRef], ref, linkedItem)
    end
    currentRef = nil
end



---Container activated
---@param e table|activateEventData
event.register("activate", function(e)
    if tes3.player ~= e.activator then return end
    if not tes3.hasOwnershipAccess { target = e.target } then return end
    if e.target.lockNode then return end
    local id = e.target and e.target.baseObject and e.target.baseObject.id
    if not id then return end
    if not containers[id] then return end
    if tes3ui.menuMode() then return false end
    currentRef = id
    e.target:clone()
    tes3.messageBox { message = i18n("messageText"), buttons = { i18n("pickUp"), i18n("browse"), i18n("stashAll"), i18n("retrieveAll") }, callback = function(
        f)
        if f.button == 0 then
            tes3.addItem { reference = e.target, item = "g7_initialized" }
            local item = tes3.getObject(containers[id]):createCopy {}
            local ref = tes3.createReference { object = item, orientation = e.target.orientation, position = e.target.position, cell = e.target.cell }
            ref.data.g7containers = {}
            ref.data.g7containers = {
                linkedRef = e.target.id,
                baseObject = containers[id],
            }
            ref.modified = true
            e.target:disable()
            skip = true
            timer.delayOneFrame(function() tes3.player:activate(ref) end)
            currentRef = nil
        elseif f.button == 1 then
            activateOrEquip(e.target)
        elseif f.button == 2 then
            stashAll(e.target)
        elseif f.button == 3 then
            retrieveAll(e.target)
        end
    end }
    return false
end)


---Item activated
---@param e table|activateEventData
event.register("activate", function(e)
    if skip then
        skip = false
        return
    end
    if tes3ui.menuMode() then return end
    if tes3.player ~= e.activator then return end
    if not tes3.hasOwnershipAccess { target = e.target } then return end
    local target = e.target
    local id = target and target.data and target.data.g7containers and target.data.g7containers.baseObject
    if not id then return end
    if not items[id] then return end
    currentRef = items[id]
    local ref = target.data.g7containers.linkedRef
    ref = ref and tes3.getReference(ref)
    if not ref then return end
    tes3.messageBox { message = i18n("messageText"), buttons = { i18n("pickUp"), i18n("browse"), i18n("stashAll"), i18n("retrieveAll"), i18n("rename"), }, callback = function(
        f)
        if f.button == 0 then
            currentRef = nil
            skip = true
            timer.delayOneFrame(function() tes3.player:activate(target) end)
        elseif f.button == 1 then
            currentName = target.object.name
            activateOrEquip(ref)
        elseif f.button == 2 then
            stashAll(ref, target.object)
        elseif f.button == 3 then
            retrieveAll(ref, target.object)
        elseif f.button == 3 then
            renamer.onCommand(target.object)
            currentRef = nil
        end
    end }
    return false
end)


---@param e table|equippedEventData
event.register("equipped", function(e)
    if tes3.player ~= e.reference then return end
    local ref, id = checkData(e.itemData)
    if not (ref and id) then return end
    tes3.mobilePlayer:unequip { item = e.item, itemData = e.itemData }
    currentRef = items[id]
    tes3.messageBox { message = i18n("messageText"), buttons = { i18n("browse"), i18n("stashAll"), i18n("retrieveAll"), i18n("rename"), tes3.findGMST("sCancel").value }, callback = function(
        f)
        if f.button == 0 then
            currentName = e.item.name
            tes3ui.leaveMenuMode()
            activateOrEquip(ref)
        elseif f.button == 1 then
            stashAll(ref, e.item)
        elseif f.button == 2 then
            retrieveAll(ref, e.item)
        elseif f.button == 3 then
            renamer.onCommand(e.item)
            currentRef = nil
        elseif f.button == 4 then
            currentRef = nil
        end
    end }
end)


---@param e table|equipEventData
event.register("equip", function(e)
    if tes3.player ~= e.reference then return end
    local ref, id = checkData(e.itemData)
    if not (ref and id) then return end
    currentRef = items[id]
    tes3.messageBox { message = i18n("messageText"), buttons = { i18n("browse"), i18n("stashAll"), i18n("retrieveAll"), i18n("rename"), tes3.findGMST("sCancel").value }, callback = function(
        f)
        if f.button == 0 then
            currentName = e.item.name
            tes3ui.leaveMenuMode()
            activateOrEquip(ref)
        elseif f.button == 1 then
            stashAll(ref, e.item)
        elseif f.button == 2 then
            retrieveAll(ref, e.item)
        elseif f.button == 3 then
            renamer.onCommand(e.item)
            currentRef = nil
        elseif f.button == 4 then
            currentRef = nil
        end
    end }
    return false
end)



---@param e itemTileUpdatedEventData
event.register("itemTileUpdated", function(e)
    e.element:registerBefore("mouseClick", function()
        local c = tes3ui.findHelpLayerMenu("CursorIcon")
        if currentRef and not (itemCheck(currentRef, e.item) or c) then
            tes3.messageBox("Only %s items allowed in this container!", allowed[currentRef])
            return false
        end
    end)


    local ref, id = checkData(e.itemData)
    if not (ref and id) then return end
    if not items[id]
        or e.menu:getPropertyObject("MenuContents_Actor")
        or e.menu:getPropertyObject("MenuContents_ObjectContainer")
    then
        return
    end

    ref:clone()
    updateWeight(id, ref, e.item)
    ref:onCloseInventory()

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

        if success and c then
            if (itemCheck(items[id], c.item)) and not items[c.item] then
                ref:clone()
                tes3.transferItem { from = tes3.player, to = ref, item = c.item, itemData = c.itemData, count = c.count }
                tes3.messageBox("%d %s successfully transferred to %s.", c.count, c.item.name, e.item.name)
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

---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    if not currentRef then return end
    tes3ui.forcePlayerInventoryUpdate()
    local close = e.element:findChild("MenuContents_closebutton")
    if not close then return end
    local title = e.element:findChild("PartDragMenu_title")
    title.text = currentName or title.text
    close:registerBefore(tes3.uiEvent.mouseClick, function()
        local ref = e.element:getPropertyObject("MenuContents_ObjectRefr")
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
        currentName = nil
    end)
    e.element:updateLayout()
end, { filter = "MenuContents" })


---@param e table|uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local ref, id = checkData(e.itemData)
    ref, id = ref or e.reference, id or (e.reference and e.reference.baseObject.id)
    if not (ref and id) then return end
    if items[id] or containers[id] then
        ref:clone()
        local inventory = ref.object.inventory.items
        local min = math.min(#inventory, 10)
        for i = 1, min do
            local item = inventory[i].object
            if item and (item.id ~= "g7_initialized") then
                local block = e.tooltip:createBlock()
                block.minWidth = 1
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
            label.wrapText = false
        end
    end
end)


---Door activated
---@param e table|activateEventData
event.register("activate", function(e)
    if tes3.player ~= e.activator then return end
    local cRef = e.target
    local key = cRef.lockNode and cRef.lockNode.key
    if not key then return end
    if tes3.mobilePlayer.object.inventory:contains(key) then return end
    local keyRings = {}
    local inventory = tes3.mobilePlayer.inventory
    for _, c in ipairs(inventory) do
        if c.variables then
            for _, itemData in ipairs(c.variables) do
                local ref, id = checkData(itemData)
                if ref and ("g7_inventory_KEYS" == id) then
                    table.insert(keyRings, ref)
                end
            end
        end
    end
    if (#keyRings < 1) then return end
    local unlock
    for _, ref in ipairs(keyRings) do
        ref:clone()
        if ref.object.inventory:contains(key) then
            unlock = true
            break
        end
    end
    if not unlock then return end
    local sKeyUsed = key.name .. ' ' .. tes3.findGMST(tes3.gmst.sKeyUsed).value;
    tes3.messageBox(sKeyUsed);
    tes3.unlock { reference = cRef };
    tes3.setTrap { reference = cRef };
    cRef.modified = true;
    tes3.playSound { sound = 'Open Lock', reference = cRef };
end)


---@param e table|loadedEventData
event.register("loaded", function(e)
    if e.newGame then return end
    if not tes3.mobilePlayer then return end
    local inventory = tes3.mobilePlayer.object.inventory
    local swap = {}
    for _, item in pairs(containers) do
        if inventory:contains(item) then
            swap[item] = tes3.getItemCount { reference = tes3.player, item = item }
        end
    end

    for id, count in pairs(swap) do
        local item = tes3.getObject(id):createCopy {}
        local ref = tes3.createReference { object = item, orientation = tes3.player.orientation, position = tes3.player.position, cell = tes3.player.cell }
        ref.data.g7containers = {}
        ref.data.g7containers = {
            linkedRef = tes3.getReference(items[id]).id,
            baseObject = id,
        }
        ref.modified = true
        tes3.removeItem { reference = tes3.player, item = id, count = count }
        skip = true
        tes3.player:activate(ref)

        if count > 1 then
            local refund = (count - 1) * price[id]
            tes3.addItem { reference = tes3.player, item = "gold_001", count = refund }
        end
    end
end)


---@param e table|referenceActivatedEventData
event.register("referenceActivated", function(e)
    local id = e.reference and e.reference.baseObject and e.reference.baseObject.id
    if not (id and items[id]) then return end
    local item = tes3.getObject(id):createCopy {}
    local ref = tes3.createReference { object = item, orientation = e.reference.orientation, position = e.reference.position, cell = e.reference.cell }
    ref.data.g7containers = {}
    ref.data.g7containers = {
        linkedRef = tes3.getReference(items[id]).id,
        baseObject = id,
    }
    ref.modified = true
    e.reference:delete()
end)



-- Script overrides can be queued when initialited event triggers.
event.register(tes3.event.initialized, function()
    ---@param e mwseOverrideScriptCallbackData
    local function overrideScript(e)
    end
    mwse.overrideScript("g7_inventory_scri", overrideScript)
    mwse.overrideScript("g7_container_scri", overrideScript)
    mwse.overrideScript("g7_intialize_scri", overrideScript)
    for _, item in pairs(containers) do
        weight[item] = tes3.getObject(item).weight
    end
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end, { priority = -1000 })
