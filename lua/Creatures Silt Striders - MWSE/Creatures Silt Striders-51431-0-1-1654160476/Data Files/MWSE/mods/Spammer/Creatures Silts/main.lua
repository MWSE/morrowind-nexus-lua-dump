


---comment
---@param e table|referenceActivatedEventData
local function onRef(e)
    if not tes3.isModActive("Creatures Silts.ESP") then
        print("Mod ESP not found! Aborting!")
        event.unregister("referenceActivated", onRef)
        return
    end
    if e.reference.baseObject.id ~= "a_siltstrider" then
        return
    end
    if e.reference.disabled then
        return
    end
    local ref = tes3.createReference{object = "LN_SiltStrider", position = e.reference.position, orientation = e.reference.orientation, cell = e.reference.cell, scale = e.reference.scale}
    ref.data.spa_helloSiltStrider = e.reference.cell.id
    e.reference:disable()
end event.register("referenceActivated", onRef)

---comment
---@param e table|damagedEventData
event.register("damaged", function(e)
    if e.attackerReference ~= tes3.player then
        return
    end
    if not (e.reference.data and e.reference.data.spa_helloSiltStrider) then
        return
    end
    tes3.triggerCrime{type = tes3.crimeType.attack, victim = e.reference}
    if not tes3.player.data.spa_siltstriderAnger then
        tes3.player.data.spa_siltstriderAnger = {}
    end
    tes3.player.data.spa_siltstriderAnger[e.reference.data.spa_helloSiltStrider] = true
end)

local function visibility(text, data)
    for id,_ in pairs(data) do
        if string.find(text, id) then return false end
    end
    return true
end

---comment
---@param e table|uiActivatedEventData
event.register("uiActivated", function(e)
    local travel = e.element:findChild("MenuServiceTravel_ServiceList")
    if tes3.player.data.spa_siltstriderAnger and tes3.player.data.spa_siltstriderAnger[tes3.getPlayerCell().id] then
        for child in table.traverse(travel.children) do
            if child.text and child.text == "Select destination" then
                child.text = "No service for you. You hurt my Silt Strider."
            elseif child.text then
                child.visible = false
            end
        end
    elseif tes3.player.data.spa_siltstriderAnger then
        for child in table.traverse(travel.children) do
                child.visible = visibility(child.text, tes3.player.data.spa_siltstriderAnger)
        end
    end
end, {filter = "MenuServiceTravel"})

---comment
local function onLoad()
    if not tes3.isModActive("Creatures Silts.ESP") then
        print("Mod ESP not found! Aborting!")
        event.unregister("loaded", onLoad)
        return
    end
    local cells = tes3.getActiveCells()
    for _,cell in ipairs(cells) do
        for reference in cell:iterateReferences(tes3.objectType.activator) do
            if reference.baseObject.id == "a_siltstrider" and not reference.disabled then
                local ref = tes3.createReference{object = "LN_SiltStrider", position = reference.position, orientation = reference.orientation, cell = reference.cell, scale = reference.scale}
                ref.data.spa_helloSiltStrider = reference.cell.id
                reference:disable()
            end
        end
    end
end event.register("loaded", onLoad)