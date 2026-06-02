-- common.lua
local types = require('openmw.types')
local vfs   = require('openmw.vfs')
local anim  = require('openmw.animation')
local bones = require('scripts.show-all-weapons.bones')

local ARMOR_TYPE_SHIELD = 8

local USE_SHEATH_MODEL = {
    [types.Weapon.TYPE.MarksmanBow]      = true,
    [types.Weapon.TYPE.MarksmanCrossbow] = true,
}

local AMMO_TYPES = {
    [types.Weapon.TYPE.Arrow] = true,
    [types.Weapon.TYPE.Bolt]  = true,
}

local RANGED_TYPES = {
    [types.Weapon.TYPE.MarksmanBow]      = true,
    [types.Weapon.TYPE.MarksmanCrossbow] = true,
}

local activeVfx = {}

local function clearVfx(actor)
    local tags = activeVfx[actor]
    if tags then
        for _, tag in ipairs(tags) do
            pcall(anim.removeVfx, actor, tag)
        end
    end
    activeVfx[actor] = {}
end

local function trackTag(actor, tag)
    local t = activeVfx[actor]
    if not t then
        t = {}
        activeVfx[actor] = t
    end
    t[#t + 1] = tag
end

local function normPath(path)
    if not path then return nil end
    return (path:gsub("\\", "/"):lower())
end

local function resolveMesh(model, weaponType)
    local path = normPath(model)
    if not path then return nil end
    if USE_SHEATH_MODEL[weaponType] then
        local sheath = path:gsub("%.nif$", "_sh.nif")
        if vfs.fileExists(sheath) then return sheath end
    else
        local sheath = path:gsub("%.nif$", "_sh.nif")
        if vfs.fileExists(sheath) then return sheath end
    end
    return path
end

local function attachVfx(actor, mesh, bone, tag)
    if not mesh or not bone then return false end
    if not anim.hasBone(actor, bone) then return false end
    local ok = pcall(anim.addVfx, actor, mesh, {
        boneName = bone,
        vfxId    = tag,
        tag      = tag,
        loop     = true,
        isMagic  = false,
        useAmbientLight = false,
    })
    if ok then
        trackTag(actor, tag)
        return true
    end
    return false
end

local function handler(actor, equippedWeapon, equippedShield, isDrawn)
    clearVfx(actor)

    local inv = types.Actor.inventory(actor)

    local equippedWeaponId = equippedWeapon and tostring(equippedWeapon.recordId) or nil
    local equippedShieldId = equippedShield  and tostring(equippedShield.recordId)  or nil

    local slotTaken = {}

    if equippedWeapon then
        local ok, rec = pcall(types.Weapon.record, equippedWeapon)
        if ok and rec then
            slotTaken[rec.type] = true
        end
    end

    local ammoForRanged = {}
    local rangedPresent = {}
    local rangedEquipped = {}

    if equippedWeapon then
        local ok, rec = pcall(types.Weapon.record, equippedWeapon)
        if ok and rec and RANGED_TYPES[rec.type] then
            rangedPresent[rec.type]  = true
            rangedEquipped[rec.type] = true
        end
    end

    local weapons = inv:getAll(types.Weapon)
    local seen = {}

    for _, item in ipairs(weapons) do
        local ok, rec = pcall(types.Weapon.record, item)
        if ok and rec then
            local rid  = tostring(item.recordId)
            local wt   = rec.type

            if AMMO_TYPES[wt] then
                if types.Actor.hasEquipped(actor, item) then
                    ammoForRanged[wt] = item
                end
            elseif RANGED_TYPES[wt] then
                rangedPresent[wt] = true
                if rid ~= equippedWeaponId and not seen[rid] then
                    seen[rid] = true
                    local mesh = resolveMesh(rec.model, wt)
                    local bone = bones.boneForWeapon(wt)
                    attachVfx(actor, mesh, bone, "saw_w_" .. rid)
                end
            else
                if not slotTaken[wt] and rid ~= equippedWeaponId and not seen[rid] then
                    seen[rid] = true
                    slotTaken[wt] = true
                    local mesh = resolveMesh(rec.model, wt)
                    local bone = bones.boneForWeapon(wt)
                    attachVfx(actor, mesh, bone, "saw_w_" .. rid)
                end
            end
        end
    end

    local ammoMap = {
        [types.Weapon.TYPE.Arrow] = types.Weapon.TYPE.MarksmanBow,
        [types.Weapon.TYPE.Bolt]  = types.Weapon.TYPE.MarksmanCrossbow,
    }

    for ammoType, rangedType in pairs(ammoMap) do
        local ammoItem = ammoForRanged[ammoType]
        if ammoItem and rangedPresent[rangedType] then
            local activelyAiming = isDrawn and rangedEquipped[rangedType]
            if not activelyAiming then
                local ok, rec = pcall(types.Weapon.record, ammoItem)
                if ok and rec then
                    local baseBone = bones.boneForWeapon(ammoType)
                    local count    = inv:countOf(rec.id)
                    local mesh     = normPath(rec.model)
                    if baseBone and mesh then
                        for i = 1, count do
                            local boneName = baseBone .. " " .. i
                            if not attachVfx(actor, mesh, boneName, "saw_ammo_" .. ammoType .. "_" .. i) then
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    do
        local armors   = inv:getAll(types.Armor)
        local seenSh   = {}
        local shieldIdx = 0

        if equippedShieldId then
            seenSh[equippedShieldId] = true
        end

        for _, item in ipairs(armors) do
            local ok, rec = pcall(types.Armor.record, item)
            if ok and rec and rec.model and rec.type == ARMOR_TYPE_SHIELD then
                local rid = tostring(item.recordId)
                if not seenSh[rid] then
                    seenSh[rid] = true
                    local mesh = normPath(rec.model)
                    attachVfx(actor, mesh, bones.SHIELD_BONE, "saw_sh_" .. shieldIdx)
                    shieldIdx = shieldIdx + 1
                end
            end
        end
    end
end

local POLL_INTERVAL = 10

local function makeUpdateHandler(actor)
    local frameCount = 0

    return function(_dt)
        frameCount = frameCount + 1
        if frameCount % POLL_INTERVAL ~= 0 then return end

        local equippedWeapon = nil
        local equippedShield = nil

        local ok, slots = pcall(types.Actor.equipment, actor)
        if ok and slots then
            local w = slots[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            if w and types.Weapon.objectIsInstance(w) then
                local rok, rec = pcall(types.Weapon.record, w)
                if rok and rec and not AMMO_TYPES[rec.type] then
                    equippedWeapon = w
                end
            end
            local s = slots[types.Actor.EQUIPMENT_SLOT.CarriedLeft]
            if s and types.Armor.objectIsInstance(s) then
                local rok, rec = pcall(types.Armor.record, s)
                if rok and rec and rec.type == ARMOR_TYPE_SHIELD then
                    equippedShield = s
                end
            end
        end

        local isDrawn = false
        local dok, stance = pcall(types.Actor.getStance, actor)
        if dok then
            isDrawn = (stance == types.Actor.STANCE.Weapon)
        end

        handler(actor, equippedWeapon, equippedShield, isDrawn)
    end
end

return {
    handler           = handler,
    makeUpdateHandler = makeUpdateHandler,
}