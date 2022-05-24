local mod = { name = "Fahrenheit 451", ver = "1.0"}
local burnt = {}
local burned
local function getDistance(ref, light, distance)
    if ref.position:distance(light.position) <= distance*100 then
        return true
    end
    return false
end
local decalTextures = {
    ["textures\\tr\\bk\\tr_book_burned_01.dds"] = true,
    ["textures\\tx_book_13.dds"] = true,
    ["textures\\tx_book_16.dds"] = true
}

local function addDecal(sceneNode)
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local alphaProperty = node:getProperty(0x0)
            local texturingProperty = node:getProperty(0x4)
            if (alphaProperty == nil
                and texturingProperty ~= nil
                and texturingProperty.canAddDecal == true)
            then
                -- we have to detach/clone the property
                -- because it could have multiple users
                texturingProperty = node:detachProperty(0x4):clone()
                texturingProperty:addDecalMap(table.choice(decalTextures))
                node:attachProperty(texturingProperty)
                node:updateProperties()
            end
        end
    end
end

---@param e projectileHitObjectEventData
local function onProjectileHit(e)
    local effects = (e.mobile
        and e.mobile.reference
        and e.mobile.reference.object
        and e.mobile.reference.object.enchantment
        and e.mobile.reference.object.enchantment.effects) or
        (e.mobile
        and e.mobile.spellInstance
        and e.mobile.spellInstance.sourceEffects)
    if effects == nil then
        return
    end
    local magn = 1
    local fire = false
    for _,effect in ipairs(effects) do
        if effect.id == tes3.effect.fireDamage then
            magn = (effect.radius and math.max(1, effect.radius)) or 1
            fire = true
        end
    end
    local targets = {}
    if e.target and e.target.objectType == tes3.objectType.book then
        targets = {e.target}
    elseif tes3.game.playerTarget and tes3.game.playerTarget.objectType == tes3.objectType.book then
        targets = {tes3.game.playerTarget}
    else
        for book in tes3.getPlayerCell():iterateReferences(tes3.objectType.book) do
            if getDistance(book, e.mobile.reference, magn) then
                table.insert(targets, book)
            end
        end
    end
    if fire and #targets ~= 0 then
        for _, target in ipairs(targets) do
            local boom = tes3.createReference({object = "light_fire", scale = .5, position = target.position, cell = target.cell})
            tes3.createVisualEffect({effect = burned, scale = .1, position = target.position, lifespan = 10})
            tes3.playSound({sound = "destruction hit", reference = e.mobile, loop = false})
            local objectHandle = tes3.makeSafeObjectHandle(boom)
            timer.start({
            duration = 10,
            callback = function()
                if objectHandle:valid() then
                    objectHandle:getObject():delete()
                end
            end})--]]
            addDecal(target.sceneNode)
            --[[if target.object.type == tes3.bookType.book then
                local new = tes3.createReference({object = table.choice(burnt), scale = target.scale, position = target.position, orientation = target.orientation, cell = target.cell})
                new.data.spa_burntBookName = target.object.name
                target:disable()
            end--]]
            target.data.spa_burntBookName = target.object.name
            local owner = tes3.getOwner({reference = target})
            if not owner then return end
            tes3.triggerCrime({type = tes3.crimeType.theft, value = target.object.value, victim = owner})
        end
    end
end


---@param e convertReferenceToItemEventData
local function addInv(e)
    if e.reference.object and table.find(burnt, e.reference.object) then
        timer.delayOneFrame(function()
        tes3.removeItem({reference = tes3.player, item = e.reference.object, playSound = false})
    end)
        tes3.messageBox("You can't take this book.")
    end
end event.register("convertReferenceToItem", addInv)


---@param e activateEventData
local function bookGetText(e)
    if e.activator ~= tes3.player then return end
    local target = e.target
    if  target and ((not target.data.spa_burntBookName) or target.object.type ~= tes3.bookType.book) then
        return
    end
    local new
    if not new then
    new = tes3.createReference({object = table.choice(burnt), scale = target.scale, position = target.position, orientation = target.orientation, cell = target.cell})
    new:disable() end
    tes3.player:activate(new)
    return false
end event.register("activate", bookGetText)

---@param e uiObjectTooltipEventData
local function readTooltip(e)
    if e.object.objectType ~= tes3.objectType.book then
        return
    end
    if not (e.reference and e.reference.data and e.reference.data.spa_burntBookName) then
        return
    end
    local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    label.text = e.reference.data.spa_burntBookName .. " (Burnt)"
end event.register("uiObjectTooltip", readTooltip)

event.register("initialized", function()
event.register("projectileHitObject", onProjectileHit)
event.register("projectileExpire", onProjectileHit)
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")

for k in pairs(decalTextures) do
    decalTextures[k] = niSourceTexture.createFromPath(k)
end

burnt[1] = tes3.createObject({
    objectType = tes3.objectType.book,
    id = "spa_burntBook_01",
    mesh = "nc\\m\\M_burntbook01.nif",
    icon = "nc\\m\\tx_m_burntbook01.dds",
    name = "Burned book"
})
burnt[2] = tes3.createObject({
    objectType = tes3.objectType.book,
    id = "spa_burntBook_02",
    mesh = "nc\\m\\M_burntbook00.nif",
    icon = "nc\\m\\tx_m_burntbook00.dds",
    name = "Burned book"
})
burnt[3] = tes3.createObject({
    objectType = tes3.objectType.book,
    id = "spa_burntBook_03",
    mesh = "tr\\m\\tr_book_burned_02.nif",
    icon = "tr\\m\\tr_book_burned_01.dds",
    name = "Burned book"
})--]]

for _,v in ipairs(burnt) do
    tes3.setSourceless(v)
end
burned = tes3.createObject({
    objectType = tes3.objectType.static,
    id = "Spa_Light_Fire_Static",
    mesh = "l\\Light_Fire.nif",
})
end)