local mod = {
    name = "R-Zero's Flies",
    ver = "1.1",
    author = "Remiros and Spammer",
    cf = { onOff = true, key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false }, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false }
}
local cf = mwse.loadConfig(mod.name, mod.cf)

local bloodTypes = { [0] = true, [5] = true, [6] = true }


local function validRef(ref)
    local base = ref and ref.baseObject
    return (base and ((base.objectType == tes3.objectType.npc) or (base.objectType == tes3.objectType.creature and bloodTypes[base.blood])) and not ref.isRespawn)
end

---@param e deathEventData
event.register("death", function(e)
    if not (e.reference and validRef(e.reference)) then return end
    if (e.mobile and e.mobile.underwater) then return end
    e.reference.data.spa_CountDown = tes3.getSimulationTimestamp()
end)


local function refDelete(cell)
    for ref in cell:iterateReferences({ tes3.objectType.activator }) do
        if ref
            and ref.data
            and ref.data.spa_TempFlies then
            if not tes3.getSoundPlaying({ sound = "Flies", reference = ref.data.spa_TempFlies }) then
                ref:delete()
            end
        end
    end
end

---@param e cellChangedEventData
event.register("cellChanged", function(e)
    for ref in e.cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do
        if ref
            and ref.data
            and ref.isDead
            and ref.data.spa_CountDown
            and ref.data.spa_CountDown < (tes3.getSimulationTimestamp() - 24) then
            tes3.playSound { sound = "Flies", reference = ref, loop = true }
        end
    end
    refDelete(e.cell)
end)


---@param e table|menuExitEventData
event.register("menuExit", function(e)
    refDelete(tes3.player.cell)
end)

--[[
local function getVisual(mesh)
    local visual = tes3.loadMesh(mesh)
    if visual then
        visual = visual:clone()
        visual:clearTransforms()
        visual.name = 'ab01node'
    end
    return visual
end


local function updateVisuals(sceneNode, attachNode, visual)
    attachNode:attachChild(visual, true)
    sceneNode:update()
    sceneNode:updateEffects()
end
--]]

---@param e addSoundEventData
event.register("addSound", function(e)
    if e.sound and e.sound.id == "Flies" and e.reference then
        if (e.reference.deleted or e.reference.isRespawn) then
            return false
        elseif validRef(e.reference) and not e.reference.data.spa_Flies then
            --local visual = getVisual("R0\\f\\flies.NIF")
            --local sceneNode = e.reference.sceneNode
            --local attachNode = sceneNode and sceneNode:getObjectByName('Bip01 Spine1')
            --updateVisuals(sceneNode, attachNode, visual)
            local ref = tes3.createReference { object = "Spa_Flies_fx", position = e.reference.position, orientation = e.reference.orientation, cell = e.reference.cell }
            ref.data.spa_TempFlies = e.reference.id
            e.reference.data.spa_Flies = true
        end
    end
end)


local function initialized()
    local flies = tes3.createObject({
        objectType = tes3.objectType.activator,
        id = "Spa_Flies_fx",
        name = "Flies",
        mesh = "R0\\f\\flies.NIF",
    })
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = -1000 })
