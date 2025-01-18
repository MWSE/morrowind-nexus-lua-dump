-- not changed greaves: nordic ringmail greaves, glass greaves, chitin greaves

-- local isDebugOn = true
local isDebugOn = false

local function log(...)
  if not isDebugOn then
    return
  end

  local filteredArgs = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)

    if v == nil then
      v = 'NIL!'
    end

    table.insert(filteredArgs, tostring(v))
  end

  mwse.log(table.unpack(filteredArgs))
end

local function addToTable(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
           dst[k] = v
        end
    end
    return dst
end

-- greaves clip with cuirasses but not with shirts
local greavesClippingWithLongCuirass = {
    ['iron_greaves'] = true,
    ['bonemold_greaves'] = true,
    ['daedric_greaves'] = true,
    ['netch_leather_greaves'] = true,
    ['imperial_chain_greaves'] = true,
}

local longCuirasses = {
    ['steel_cuirass'] = true,
    ['templar_cuirass'] = true,
    ['ebony_cuirass'] = true,
    ['indoril cuirass'] = true,
    ['orcish_cuirass'] = true,
    ['chitin cuirass'] = true,
    ['glass_cuirass'] = true,
}

local clippingLowerBody = {
    ["exquisite_pants_01"] = true,
    ["common_pants_01"] = true,
    ["common_pants_01_a"] = true,
    ["common_pants_01_e"] = true,
    ["common_pants_01_u"] = true,
    ["common_pants_01_z"] = true,
    ["common_pants_02"] = true,
    ["common_pants_03"] = true,
    ["common_pants_03_b"] = true,
    ["common_pants_03_c"] = true,
    ["common_pants_04"] = true,
    ["common_pants_04_b"] = true,
    ["common_pants_05"] = true,
    ["expensive_pants_01"] = true,
    ["expensive_pants_01_a"] = true,
    ["expensive_pants_01_e"] = true,
    ["expensive_pants_01_u"] = true,
    ["expensive_pants_01_z"] = true,
    ["expensive_pants_02"] = true,
    ["expensive_pants_03"] = true,
    ["extravagant_pants_01"] = true,
    ["extravagant_pants_02"] = true,
}
clippingLowerBody = addToTable(clippingLowerBody, greavesClippingWithLongCuirass)

local clippingUpperBody = {
    ["expensive_shirt_01_u"] = true,
    ["expensive_shirt_02"] = true,
    ["expensive_shirt_03"] = true,
    ["common_shirt_02_h"] = true,

    -- some shirts do not clip:
    -- ["common_shirt_02_t"] = true,
    -- ["expensive_shirt_01"] = true,
};
clippingUpperBody = addToTable(clippingUpperBody, longCuirasses)

local lowerBodyParts = {
    [tes3.activeBodyPart.leftUpperLeg] = true,
    [tes3.activeBodyPart.rightUpperLeg] = true,
    [tes3.activeBodyPart.groin] = true,
    [tes3.activeBodyPart.rightKnee] = true,
    [tes3.activeBodyPart.leftKnee] = true,
    [tes3.activeBodyPart.rightAnkle] = true,
    [tes3.activeBodyPart.leftAnkle] = true,
}

---@param e bodyPartAssignedEventData
local function onEquip(e)
    if (e.bodyPart == nil or e.object == nil or not e.bodyPart.female) then
        return
    end

    log('[THICC] -----------------')
    log('[THICC] e.reference.id (NPC): %s', e.reference.id)
    log('[THICC] e.bodyPart.mesh: %s', e.bodyPart.mesh)
    log('[THICC] e.bodyPart.female: %s', e.bodyPart.female)

    if (lowerBodyParts[e.index] == nil
        or (e.object.objectType ~= tes3.objectType.armor and e.object.objectType ~= tes3.objectType.clothing)) then
        -- only when equipping clothes or armor on legs 
        -- (lower body in fact updates also when other EQ chanes, including upper body)
        log('[THICC] e.index (body part): %s', e.index)
        log('[THICC] ABORT, not armor OR cloth OR lower body part')
        return
    end

    if (clippingLowerBody[e.object.id] == nil) then
        log('[THICC] ABORT, not a thicc/clipping lower body item: %s', e.object.id)
        return
    end

    local folderName
    if e.object.objectType == tes3.objectType.clothing then
        if string.sub(string.lower(e.bodyPart.mesh), -7) ~= "fem.nif" then
            log('[THICC] something is off, either start of the game, or female is wearing male clothes...? ABORT')
            return
        end

        folderName = 'BC' -- DMRA clothes replacers (pants) are in BC, Better Clothes fallback is in BC_
    elseif e.object.objectType == tes3.objectType.armor then
        folderName = 'BAM' -- curvybody armor replacers (greaves) are in BAM, Better Morrowind Armor fallback is in BAM_
    end

    local fileName = string.match(e.bodyPart.mesh, "\\(.*)")
    local meshPathThicc = folderName .. '\\' .. fileName
    local meshPathOld = folderName .. '_\\' .. fileName
    local equippedGreaves = tes3.getEquippedItem({ actor = e.reference, objectType = tes3.objectType.armor, slot = tes3.armorSlot.greaves })
    local equippedCuirass = tes3.getEquippedItem({ actor = e.reference, objectType = tes3.objectType.armor, slot = tes3.armorSlot.cuirass })
    local equippedShirt = tes3.getEquippedItem({ actor = e.reference, objectType = tes3.objectType.clothing, slot = tes3.clothingSlot.shirt })
    log('[THICC] equipped shirt: %s', equippedShirt)
    log('[THICC] equipped cuirass: %s', equippedCuirass)

    if (equippedShirt == nil and equippedCuirass == nil) then
        log('[THICC] no shirt or cuirass, so switch to thicc version')
        e.bodyPart.mesh = meshPathThicc
        return
    end

    -- GREAVES
    -- we check greaves first, compare only with cuirasses and abort when done
    if (equippedGreaves) then
        log('[THICC] equipped greaves: %s', equippedGreaves.object.id)

        -- TODO: what if steel cuirass + steel greaves? steel greaves will never clip? what if steel greaves are worn with clipping pants?
        -- all greaves are not clipping with shirts?

        if equippedCuirass == nil then
            log('[THICC] has greaves but no cuirass, so switch to thicc version')
            e.bodyPart.mesh = meshPathThicc
            return
        end

        if (greavesClippingWithLongCuirass[equippedGreaves.object.id] and longCuirasses[equippedCuirass.object.id]) then
            log('[THICC] equipped greaves and cuirass will clip, fallback greaves to old non-thicc version')
            e.bodyPart.mesh = meshPathOld
            return
        end
        
        log('[THICC] equipped greaves will not clip, so switch to thicc version')
        e.bodyPart.mesh = meshPathThicc
        return
    end

    -- resolve upper body outfit
    local upperBodyId
    if equippedShirt then 
        upperBodyId = equippedShirt.object.id
    end
    if equippedCuirass then 
        -- if shirt AND cuirass is equipped we care only about the cuirass
        -- all long cuirasses are clipping with all thicc pants
        upperBodyId = equippedCuirass.object.id
    end

    log('[THICC] upperBodyId: %s', upperBodyId)

    -- PANTS
    if (clippingUpperBody[upperBodyId]) then
        log('[THICC] equipped pants and upper body outfit will clip, so switch to old non-thicc version')
        e.bodyPart.mesh = meshPathOld
    else
        log('[THICC] not wearing a clipping upper body outfit, so switch to thicc version')
        e.bodyPart.mesh = meshPathThicc
    end
end
event.register(tes3.event.bodyPartAssigned, onEquip)

local function onInitialized()
  mwse.log('[THICC] Mod initialized.')

  if isDebugOn then tes3.messageBox({ message = '[THICC] Mod initialized.', duration = 20 }) end
end
event.register('initialized', onInitialized)
