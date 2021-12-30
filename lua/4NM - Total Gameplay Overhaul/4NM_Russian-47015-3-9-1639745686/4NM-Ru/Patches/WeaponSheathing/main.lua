--[[
    Weapon Sheathing  v1.6
    By Greatness7
--]]

local config = require("weaponSheathing.config")
mwse.log("[Weapon Sheathing] Initialized Version 1.6")

local attachSlots = {
    [0] = "Bip01 ShortBladeOneHand",
    [1] = "Bip01 LongBladeOneHand",
    [2] = "Bip01 LongBladeTwoClose",
    [3] = "Bip01 BluntOneHand",
    [4] = "Bip01 BluntTwoClose",
    [5] = "Bip01 BluntTwoWide",
    [6] = "Bip01 SpearTwoWide",
    [7] = "Bip01 AxeOneHand",
    [8] = "Bip01 AxeTwoClose",
    [9] = "Bip01 MarksmanBow",
    [10] = "Bip01 MarksmanCrossbow",
    [11] = "Bip01 MarksmanThrown",
    [-1] = "Bip01 AttachWeapon",
    [-2] = "Bip01 AttachShield",
}

local function GoD(m, wid) if m == tes3.mobilePlayer and wid:sub(1,2) == "4_" then local Old = tes3.getObject(wid:sub(3))	if Old then return Old.type end end	return false end
-------------
-- STARTUP --
-------------
local attachNodes = {}
local function getAttachNodes()
    local node = tes3.loadMesh("xbase_anim_sh.nif")
    if not node then
        mwse.log('[Weapon Sheathing] ERROR: failed to load "xbase_anim_sh.nif"')
        return
    end
    for i, name in pairs(attachSlots) do
        attachNodes[i] = node:getObjectByName(name)
        if not attachNodes[i] then
            mwse.log('[Weapon Sheathing] ERROR: failed to find attachNode "%s"', name)
        end
    end
end
event.register("meshLoaded", getAttachNodes, {doOnce=true})


local overrides = {}
local function getOverrides()
    local meshes = {}

    for obj in tes3.iterateObjects(tes3.objectType.weapon) do
        meshes[obj.mesh] = true
    end
    for obj in tes3.iterateObjects(tes3.objectType.armor) do
        if obj.slot == tes3.armorSlot.shield then
            meshes[obj.mesh] = true
        end
    end

    for mesh in pairs(meshes) do
        mesh = mesh:lower()
        if not overrides[mesh] then
            if not mesh:find("%.nif$") then
                config.blocked[mesh] = true
            else
                local override = mesh:sub(1, -5) .. "_sh.nif"
                if tes3.getFileExists("meshes\\" .. override) then
                    overrides[mesh] = override
                end
            end
        end
    end
end
event.register("initialized", getOverrides)


local patchTargets = {
    ["xbase_anim.nif"] = true,
    ["xbase_animkna.nif"] = true,
    ["xbase_anim_female.nif"] = true,
}
local function getPatchTargets()
    local meshes = {}

    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        meshes[obj.mesh] = true
    end
    for obj in tes3.iterateObjects(tes3.objectType.creature) do
        if obj.biped and obj.usesEquipment then
            meshes[obj.mesh] = true
        end
    end

    for mesh in pairs(meshes) do
        mesh = mesh:lower()
        if not patchTargets[mesh] then
            if not mesh:find("%.nif$") then
                config.blocked[mesh] = true
            else
                local dir, name = mesh:match("(.-)([^\\]+)$")
                patchTargets[dir .. "x" .. name] = true
                patchTargets[mesh] = true
            end
        end
    end
end
event.register("initialized", getPatchTargets)


local function patchMesh(e)
    local mesh = e.path:sub(8):lower()
    if not patchTargets[mesh] then
        return
    end
    for i, node in pairs(attachNodes) do
        local parent = e.node:getObjectByName(node.parent.name)
        if not parent then
            mwse.log('[Weapon Sheathing] ERROR: Failed to patch "%s."', mesh)
            return
        end
        parent:attachChild(node:clone(), true)
    end
end
event.register("meshLoaded", patchMesh)


local function registerMCM(e)
    require("weaponSheathing.mcm")
end
event.register("modConfigReady", registerMCM)
-------------


-------------
-- UTILITY --
-------------
local function clearControllers(node)
    node:removeAllControllers()
    if node.children then
        for i = 1, #node.children do
            local child = node.children[i]
            -- meshes may have empty slots
            if child then
                clearControllers(child)
            end
        end
    end
end


local function validateAmmoType(weapon, ammo)
    return (weapon.type + 3) == ammo.type
end


local function validateObject(object)
    local file = object.sourceMod
    if file and config.blocked[file:lower()] then
        return false
    elseif config.blocked[object.id:lower()] then
        return false
    end
    return true
end


local function validateRef(ref)
    local object = ref.object
    if not patchTargets[object.mesh:lower()] then
        return false
    elseif ref.disabled or not ref.sceneNode then
        return false
    end
    return validateObject(object.baseObject)
end
-------------


------------
-- UPDATE --
------------
local noop = function () end


local function updateQuiver(ref, mobile, quiver)
    -- mwse.log("updateQuiver(%s, %s)", ref, quiver)

    if not (config.showWeapon and config.showCustom) then
        return
    elseif quiver and not validateObject(quiver) then
        return
    end

    -- ensure a valid weapon is equipped
    local attachNode = ref.sceneNode:getObjectByName("Bip01 Ammo")
    if not attachNode then
        return
    end

    -- clear the previous quiver visuals
    for i = 1, #attachNode.children do
        attachNode.children[i]:detachChildAt(1)
    end

    -- don't pass unless quiver equipped
    if not quiver then
        return
    end

    -- don't pass unless valid ammo type
    if mobile.readiedWeapon then
        local weapon = mobile.readiedWeapon.object
        if not validateAmmoType(weapon, quiver) then
            return
        end
    end

    -- load the new ammunition's visuals
    local visual = tes3.loadMesh(quiver.mesh)
    if not visual then
        mwse.log("[Weapon Sheathing] ERROR: failed to load mesh %s.", quiver.mesh)
        return
    end

    -- clone and clear cached transforms
    visual = visual:clone()
    visual:clearTransforms()

    -- apply enchant effect when present
    if quiver.enchantment then
        tes3.worldController:applyEnchantEffect(visual, quiver.enchantment)
    end

    -- clone the visuals into ammo slots
    for i = 1, #attachNode.children do
        local slot = attachNode.children[i]
        slot:attachChild(visual:clone(), true)
    end
end


local function updateShield(ref, mobile, shield)
    -- mwse.log("updateShield(%s, %s)", ref, shield)

    if not config.showShield then
        return
    elseif shield and not validateObject(shield) then
        return
    end

    -- clear the previous shield visuals
    local attachNode = ref.sceneNode:getObjectByName("Bip01 AttachShield")
    attachNode:detachChildAt(1)

    -- update the shield bone visibility
    local shieldBone = ref.sceneNode:getObjectByName("Shield Bone")
    shieldBone.appCulled = false

    -- ensure the shield should be shown
    if not shield or mobile.weaponDrawn then
        return
    end

    -- catch some fake shields from mods
    if shield.armorRating == 0 then
        return
    end

    -- load the sheath or shield visuals
    local sheath = overrides[shield.mesh:lower()]
    local visual = tes3.loadMesh(sheath or shield.mesh)
    if not visual then
        mwse.log("[Weapon Sheathing] ERROR: failed to load mesh %s.", sheath or shield.mesh)
        return
    end

    -- clone and clear cached transforms
    visual = visual:clone()
    visual:clearTransforms()

    -- append the visual onto attachNode
    attachNode:attachChild(visual, true)
    shieldBone.appCulled = true

    -- apply enchant effect when present
    if shield.enchantment then
        tes3.worldController:applyEnchantEffect(visual, shield.enchantment)
    end
end


local function updateWeapon(ref, mobile, weapon)
    -- mwse.log("updateWeapon(%s, %s)", ref, weapon)

    if not config.showWeapon then
        return
    elseif weapon and not validateObject(weapon) then
        return
    end

    -- clear the previous weapon visuals
    local attachNode = ref.sceneNode:getObjectByName("Bip01 AttachWeapon")
    attachNode:detachChildAt(1)

    -- don't pass unless weapon equipped
    if not (weapon and weapon.type) or (weapon.type == 11) then
        -- TODO support throwing weapons
        return
    end

    -- ensure the sheath should be shown
    local sheath = config.showCustom and overrides[weapon.mesh:lower()]
    if not sheath and mobile.weaponDrawn then
        return
    end

    -- load the sheath or weapon visuals
    local visual = tes3.loadMesh(sheath or weapon.mesh)
    if not visual then
        mwse.log("[Weapon Sheathing] ERROR: failed to load mesh %s.", sheath or weapon.mesh)
        return
    end

    -- get the weapon type's parent node
    local typeNode = ref.sceneNode:getObjectByName(attachSlots[GoD(mobile, weapon.id) or weapon.type])

    -- update AttachWeapon to new parent
    attachNode.parent:detachChild(attachNode)
    typeNode:attachChild(attachNode, true)

    -- clone and clear cached transforms
    visual = visual:clone()
    visual:clearTransforms()

    -- append the visual onto attachNode
    attachNode:attachChild(visual, true)

    -- hide the weapon part if was drawn
    if sheath and mobile.weaponDrawn then
        attachNode:getObjectByName("Bip01 Weapon").appCulled = true
    end

    -- extra handling for ranged weapons
    if weapon.isRanged then
        clearControllers(attachNode)
        if mobile.readiedAmmo then
            local quiver = mobile.readiedAmmo.object
            if validateAmmoType(weapon, quiver) then
                updateQuiver(ref, mobile, quiver)
            end
        end
    end

    -- apply enchant effect when present
    if weapon.enchantment then
        tes3.worldController:applyEnchantEffect(visual, weapon.enchantment)
    end

    -- fix for the 'black texture' bugs?
    ref.sceneNode:updateNodeEffects()
end


local function getUpdater(item)
    if item.objectType == tes3.objectType.ammunition then
        return updateQuiver
    elseif item.objectType == tes3.objectType.weapon then
        return updateWeapon
    elseif item.objectType == tes3.objectType.armor then
        if item.slot == tes3.armorSlot.shield then
            return updateShield
        end
    end
    return noop
end
-------------


------------
-- EVENTS --
------------
local function updateVisuals(e)
    if not validateRef(e.reference) then return end

    local mobile = e.reference.mobile
    local weapon = mobile.readiedWeapon
    local shield = mobile.readiedShield

    if weapon then
        updateWeapon(e.reference, mobile, weapon.object)
    end
    if shield then
        updateShield(e.reference, mobile, shield.object)
    end
end
event.register("loaded", updateVisuals)
event.register("weaponReadied", updateVisuals)
event.register("weaponUnreadied", updateVisuals)
event.register("mobileActivated", updateVisuals)

event.register("equipped", function(e)
    if not validateRef(e.reference) then return end
    getUpdater(e.item)(e.reference, e.mobile, e.item)
end)

event.register("unequipped", function(e)
    if not validateRef(e.reference) then return end
    getUpdater(e.item)(e.reference, e.mobile, nil)
end)
------------
