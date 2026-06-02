local types   = require('openmw.types')
local self_   = require('openmw.self')
local ui      = require('openmw.ui')
local util    = require('openmw.util')
local async   = require('openmw.async')
local storage = require('openmw.storage')
local I       = require('openmw.interfaces')
local anim    = require('openmw.animation')
local vfs     = require('openmw.vfs')
local core    = require('openmw.core')
local camera  = require('openmw.camera')

local MD = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }
local STANCE  = types.Actor.STANCE
local WT      = types.Weapon.TYPE
local SLOT_WEAPON = types.Actor.EQUIPMENT_SLOT.CarriedRight

local SLOT_LEFT_RING  = types.Actor.EQUIPMENT_SLOT.LeftRing
local SLOT_RIGHT_RING = types.Actor.EQUIPMENT_SLOT.RightRing
local RING_TYPE       = 8
local CONST_EFFECT    = core.magic.ENCHANTMENT_TYPE.ConstantEffect

local FINGER_NAMES = {
    "Left. Pinky", "Left. Ring finger", "Left. Middle",
    "Left. Index", "Left. Thumb",
    "Right. Pinky", "Right. Ring finger", "Right. Middle",
    "Right. Index", "Right. Thumb",
}

local FINGER_TO_SLOT = {
    [4] = SLOT_LEFT_RING,
    [9] = SLOT_RIGHT_RING,
}

local FINGER_TO_BONE = {
    [1]  = { first = "Ring L Pinky",  third = "Ring L Pinky"  },
    [2]  = { first = "Ring L Ring",   third = "Ring L Ring"   },
    [3]  = { first = "Ring L Middle", third = "Ring L Middle" },
    [5]  = {
        first              = "Ring L Thumb1",  
        first_combat_1h    = "Ring L Thumb2",
        first_combat_2h    = "Ring L Thumb4",
        first_combat_bow   = "Ring L Thumb5",
        first_combat_crossbow = "Ring L Thumb6",
        first_combat_hth   = "Ring L Thumb7",
        third              = "Ring L Thumb",
        third_combat_1h    = "Ring L Thumb3",
        third_combat_2h    = "Ring L Thumb8",
        third_combat_bow   = "Ring L Thumb3",
        third_combat_crossbow = "Ring L Thumb9",
        third_combat_hth   = "Ring L ThumbH",
    },
    [6]  = { first = "Ring R Pinky",  third = "Ring R Pinky"  },
    [7]  = { first = "Ring R Ring",   third = "Ring R Ring"   },
    [8]  = { first = "Ring R Middle", third = "Ring R Middle" },
    [10] = {
        first              = "Ring R Thumb1",  
        first_combat_1h    = "Ring R Thumb2",
        first_combat_2h    = "Ring R Thumb6",
        first_combat_bow   = "Ring R Thumb7",
        first_combat_crossbow = "Ring R Thumb8",
        first_combat_hth   = "Ring R Thumb9",
        third              = "Ring R Thumb",
        third_combat_1h    = "Ring R Thumb3",
        third_combat_2h    = "Ring R Thumb3",
        third_combat_bow   = "Ring R Thumb3",
        third_combat_crossbow = "Ring R Thumb4",
        third_combat_hth   = "Ring R Thumb5",
    },
}

local VFX_TAG        = "unlimitedRingsVfx"
local FRAME_INTERVAL = 60
local VFX_INTERVAL   = 400
local INIT_DELAY     = 1.5
local INIT_RETRY     = 0.5

local playerSection  = storage.playerSection('UnlimitedRings')
local assignments    = {}
local activeSpellIds = {}
local activeDialog   = nil
local pendingItem    = nil
local pendingEquip   = nil
local frameCounter   = FRAME_INTERVAL
local initPending    = false
local initTimer      = 0
local vfxCounter     = VFX_INTERVAL
local currentCam        = camera.getMode()
local currentStance     = types.Actor.getStance(self_)
local currentWeaponType = nil  

local function fingerVfxId(fingerIdx)
    return VFX_TAG .. "_" .. tostring(fingerIdx)
end

local function getRecordId(item)
    if not item then return nil end
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then return rec.id end
    return nil
end

local function findItemByRecordId(recId)
    if not recId then return nil end
    for _, item in ipairs(types.Actor.inventory(self_):getAll()) do
        if getRecordId(item) == recId then return item end
    end
    return nil
end

local function countInInventory(recId)
    if not recId then return 0 end
    local count = 0
    for _, item in ipairs(types.Actor.inventory(self_):getAll()) do
        if getRecordId(item) == recId then
            local stackSize = 1
            pcall(function() stackSize = item.count end)
            count = count + stackSize
        end
    end
    return count
end

local function countAssigned(recId)
    if not recId then return 0 end
    local count = 0
    for _, id in pairs(assignments) do
        if id == recId then count = count + 1 end
    end
    return count
end

local function canAssignMore(recId, excludeFinger)
    if not recId then return false end
    local inInv = countInInventory(recId)
    local worn  = 0
    for fingerStr, id in pairs(assignments) do
        local fi = tonumber(fingerStr)
        if id == recId and fi ~= excludeFinger then
            worn = worn + 1
        end
    end
    return inInv > worn
end

local function findAllFingersByRecordId(recId)
    local fingers = {}
    for k, id in pairs(assignments) do
        if id == recId then fingers[#fingers + 1] = tonumber(k) end
    end
    return fingers
end

local function saveAssignments()
    local copy = {}
    for k, v in pairs(assignments) do copy[tostring(k)] = v end
    playerSection:set('assignments', copy)
end

local function loadAssignments()
    local saved = playerSection:get('assignments')
    if not saved then return {} end
    local result = {}
    local ok, err = pcall(function()
        for k, v in pairs(saved) do result[tostring(k)] = v end
    end)
    if not ok then return {} end
    return result
end

local function getConstantEnchantment(item)
    local ok, rec = pcall(types.Clothing.record, item)
    if not ok or not rec or not rec.enchant or rec.enchant == '' then return nil end
    local ok2, ench = pcall(function()
        return core.magic.enchantments.records[rec.enchant]
    end)
    if not ok2 or not ench then return nil end
    if ench.type ~= CONST_EFFECT then return nil end
    return ench
end

local function applyEnchantment(item, fingerIdx)
    if FINGER_TO_SLOT[fingerIdx] then return end

    local ench = getConstantEnchantment(item)
    if not ench then return end

    local fingerStr = tostring(fingerIdx)
    local recId     = getRecordId(item)

    if activeSpellIds[fingerStr] then
        local stillActive = false
        pcall(function()
            for _, s in ipairs(types.Actor.activeSpells(self_)) do
                if s == activeSpellIds[fingerStr] then
                    stillActive = true
                    break
                end
            end
        end)
        if stillActive then return end
        activeSpellIds[fingerStr] = nil
    end

    local effectIndexes = {}
    for i = 0, #ench.effects - 1 do
        effectIndexes[#effectIndexes + 1] = i
    end

    local ok, result = pcall(function()
        return types.Actor.activeSpells(self_):add({
            id      = recId,
            effects = effectIndexes,
            name    = ench.id,
        })
    end)

    if ok and result ~= nil then
        activeSpellIds[fingerStr] = result
    end
end

local function removeEnchantment(fingerIdx)
    if FINGER_TO_SLOT[fingerIdx] then return end
    local fingerStr = tostring(fingerIdx)
    local activeId  = activeSpellIds[fingerStr]
    if not activeId then return end
    pcall(function()
        types.Actor.activeSpells(self_):remove(activeId)
    end)
    activeSpellIds[fingerStr] = nil
end

local function reapplyAllEnchantments()
    for fingerStr, recId in pairs(assignments) do
        local fingerIdx = tonumber(fingerStr)
        if fingerIdx and not FINGER_TO_SLOT[fingerIdx] then
            local item = findItemByRecordId(recId)
            if item then applyEnchantment(item, fingerIdx) end
        end
    end
end

local function getRingModel(item)
    local ok, rec = pcall(types.Clothing.record, item)
    if not ok or not rec or not rec.model or rec.model == '' then return nil end
    local model = rec.model:lower()
    model = model:gsub("_gnd%.nif$", ".nif")
    model = model:gsub("%.nif$", "_skins.nif")
    if vfs.fileExists(model) then return model end
    return nil
end

local function getCombatSuffix()
    local eq = types.Actor.equipment(self_)
    local weapon = eq[SLOT_WEAPON]
    if not weapon then
        return "combat_hth"
    end
    if weapon.type ~= types.Weapon then return "combat_1h" end
    local ok, rec = pcall(types.Weapon.record, weapon)
    if not ok or not rec then return "combat_1h" end
    local t = rec.type
    if t == WT.MarksmanBow then
        return "combat_bow"
    elseif t == WT.MarksmanCrossbow then
        return "combat_crossbow"
    elseif t == WT.LongBladeTwoHand or t == WT.BluntTwoClose
        or t == WT.BluntTwoWide or t == WT.SpearTwoWide or t == WT.AxeTwoHand then
        return "combat_2h"
    else
        return "combat_1h"
    end
end

local function getViewKey()
    local stance = types.Actor.getStance(self_)
    local fp = (camera.getMode() == MD.first)
    if stance == STANCE.Weapon then
        local suffix = getCombatSuffix()
        return fp and ("first_" .. suffix) or ("third_" .. suffix)
    end
    return fp and "first" or "third"
end

local function getBoneForFinger(fingerIdx)
    local boneEntry = FINGER_TO_BONE[fingerIdx]
    if not boneEntry then return nil end
    local key = getViewKey()
    if boneEntry[key] then return boneEntry[key] end
    local base = (camera.getMode() == MD.first) and "first" or "third"
    return boneEntry[base]
end

local function addRingVfx(item, fingerIdx)
    local model = getRingModel(item)
    if not model then return end
    local bone = getBoneForFinger(fingerIdx)
    if not bone then return end
    pcall(function()
        anim.addVfx(self_, model, {
            loop            = true,
            useAmbientLight = false,
            vfxId           = fingerVfxId(fingerIdx),
            boneName        = bone,
        })
    end)
end

local function refreshRingVfx(allowCleanup)
    local dirty = false
    for fingerStr, recId in pairs(assignments) do
        local fingerIdx = tonumber(fingerStr)
        if fingerIdx and FINGER_TO_BONE[fingerIdx] then
            local item = findItemByRecordId(recId)
            if not item then
                if allowCleanup then
                    assignments[fingerStr] = nil
                    dirty = true
                end
            else
                anim.removeVfx(self_, fingerVfxId(fingerIdx))
                pcall(addRingVfx, item, fingerIdx)
            end
        end
    end
    if dirty then saveAssignments() end
end

local function unassignFinger(fingerIdx)
    local fingerStr = tostring(fingerIdx)

    anim.removeVfx(self_, fingerVfxId(fingerIdx))
    removeEnchantment(fingerIdx)

    local slot = FINGER_TO_SLOT[fingerIdx]
    if slot then
        local eq = types.Actor.equipment(self_)
        eq[slot] = nil
        types.Actor.setEquipment(self_, eq)
    end

    assignments[fingerStr] = nil
    saveAssignments()
end

local function onFingerChosen(fingerIdx, item)
    if not item then return end
    local recId = getRecordId(item)
    if not recId then return end

    if assignments[tostring(fingerIdx)] == recId then return end

    local targetHasSame  = (assignments[tostring(fingerIdx)] == recId)
    local excludeTarget  = targetHasSame and fingerIdx or nil
    local freeAfterEvict = countInInventory(recId)
    for fingerStr, id in pairs(assignments) do
        local fi = tonumber(fingerStr)
        if id == recId and fi ~= excludeTarget then
            freeAfterEvict = freeAfterEvict - 1
        end
    end

    local sourceFinger = nil
    if freeAfterEvict <= 0 then
        for fingerStr, id in pairs(assignments) do
            local fi = tonumber(fingerStr)
            if id == recId and fi ~= fingerIdx then
                sourceFinger = fi
                break
            end
        end
    end

    if not canAssignMore(recId, sourceFinger or excludeTarget) then return end

    local evictedRecId = assignments[tostring(fingerIdx)]
    if evictedRecId then
        anim.removeVfx(self_, fingerVfxId(fingerIdx))
        removeEnchantment(fingerIdx)
        local slot = FINGER_TO_SLOT[fingerIdx]
        if slot then
            local eq = types.Actor.equipment(self_)
            eq[slot] = nil
            types.Actor.setEquipment(self_, eq)
        end
        assignments[tostring(fingerIdx)] = nil
    end

    if sourceFinger then
        anim.removeVfx(self_, fingerVfxId(sourceFinger))
        removeEnchantment(sourceFinger)
        local srcSlot = FINGER_TO_SLOT[sourceFinger]
        if srcSlot then
            local eq = types.Actor.equipment(self_)
            eq[srcSlot] = nil
            types.Actor.setEquipment(self_, eq)
        end
        assignments[tostring(sourceFinger)] = nil
    end

    assignments[tostring(fingerIdx)] = recId
    saveAssignments()

    local slot = FINGER_TO_SLOT[fingerIdx]
    if slot then
        pendingEquip = { slot = slot, recId = recId }
    else
        anim.removeVfx(self_, fingerVfxId(fingerIdx))
        addRingVfx(item, fingerIdx)
        applyEnchantment(item, fingerIdx)
    end
end

local function closeDialog()
    if activeDialog then activeDialog:destroy(); activeDialog = nil end
    pendingItem = nil
end

local function buildDialog(ringName, capturedItem)
    local MWUI  = I.MWUI
    local BTN_W = 200
    local BTN_H = 27
    local GAP   = 4
    local recId = getRecordId(capturedItem)

    local currentFingers = {}
    for _, fi in ipairs(findAllFingersByRecordId(recId)) do
        currentFingers[fi] = true
    end

    local inInv    = countInInventory(recId)
    local worn     = countAssigned(recId)
    local freeLeft = inInv - worn
    local isMovable = (next(currentFingers) ~= nil) and (freeLeft == 0)

    local stackInfoText = 'In inventory: ' .. tostring(inInv) .. '   On fingers: ' .. tostring(worn)

    local function makeBtn(idx)
        local label = FINGER_NAMES[idx]
        local isStd = FINGER_TO_SLOT[idx] ~= nil

        local isCurrentFinger = currentFingers[idx] == true
        local takenByOther    = (assignments[tostring(idx)] ~= nil) and not isCurrentFinger
        local canFreshPlace   = (not takenByOther) and (freeLeft > 0)
        local canMove         = isMovable and not isCurrentFinger

        local color
        if isCurrentFinger then
            color = util.color.rgb(0.5, 0.5, 0.5)
            label = label .. '  [click to remove]'
        elseif takenByOther then
            if freeLeft > 0 or canMove then
                color = util.color.rgb(0.9, 0.65, 0.3)
                label = label .. '  [replace]'
            else
                color = util.color.rgb(0.55, 0.55, 0.55)
                label = label .. '  [no copies left]'
            end
        elseif canMove then
            color = util.color.rgb(0.6, 0.85, 0.95)
            label = label .. '  [move here]'
        elseif canFreshPlace then
            color = isStd and util.color.rgb(0.6, 0.95, 0.55) or util.color.rgb(0.97, 0.93, 0.8)
        else
            color = util.color.rgb(0.55, 0.55, 0.55)
            label = label .. '  [no copies left]'
        end

        local i = idx
        local clickable = isCurrentFinger
            or canFreshPlace
            or (takenByOther and (freeLeft > 0 or canMove))
            or (canMove and not takenByOther)

        return {
            type   = ui.TYPE.Widget,
            props  = { size = util.vector2(BTN_W, BTN_H), propagateEvents = false },
            events = { mouseClick = async:callback(function()
                if isCurrentFinger then
                    if activeDialog then activeDialog:destroy(); activeDialog = nil end
                    unassignFinger(i)
                    pendingItem = nil
                    return
                end
                if not clickable then return end
                if activeDialog then activeDialog:destroy(); activeDialog = nil end
                onFingerChosen(i, capturedItem)
                pendingItem = nil
            end) },
            content = ui.content({
                { template = MWUI.templates.boxSolid, content = ui.content({
                    { type = ui.TYPE.Text, props = {
                        text            = label,
                        textSize        = 13,
                        textColor       = color,
                        textShadow      = true,
                        textShadowColor = util.color.rgb(0, 0, 0),
                        autoSize        = false,
                        size            = util.vector2(BTN_W, BTN_H),
                        textAlignH      = ui.ALIGNMENT.Center,
                        textAlignV      = ui.ALIGNMENT.Center,
                    }},
                })},
            }),
        }
    end

    local function makeCol(from, to)
        local rows = {}
        for i = from, to do
            rows[#rows + 1] = makeBtn(i)
            if i < to then
                rows[#rows + 1] = { type = ui.TYPE.Widget, props = { size = util.vector2(1, GAP) } }
            end
        end
        return {
            type  = ui.TYPE.Flex,
            props = { autoSize = false, size = util.vector2(BTN_W, 5 * BTN_H + 4 * GAP) },
            content = ui.content(rows),
        }
    end

    local GW = BTN_W * 2 + 12
    local GH = 5 * BTN_H + 4 * GAP

    local anyCurrentFinger = next(currentFingers) ~= nil
    local multipleFingers  = false
    do
        local cnt = 0
        for _ in pairs(currentFingers) do cnt = cnt + 1 end
        if cnt > 1 then multipleFingers = true end
    end

    local BTN_REMOVE_W = 160
    local BTN_CANCEL_W = 110
    local BTNS_GAP     = 12
    local PW = GW + 32
    local PH = 16 + 8 + 14 + 10 + GH + 10 + 30 + 32

    local bottomContent
    if anyCurrentFinger then
        local removeLabel = multipleFingers and 'Remove all' or 'Remove'
        bottomContent = {
            type  = ui.TYPE.Flex,
            props = { horizontal = true, autoSize = true, align = ui.ALIGNMENT.Center },
            content = ui.content({
                {
                    type   = ui.TYPE.Widget,
                    props  = { size = util.vector2(BTN_REMOVE_W, 30), propagateEvents = false },
                    events = { mouseClick = async:callback(function()
                        if activeDialog then activeDialog:destroy(); activeDialog = nil end
                        for fi in pairs(currentFingers) do unassignFinger(fi) end
                        pendingItem = nil
                    end) },
                    content = ui.content({
                        { template = MWUI.templates.boxSolid, content = ui.content({
                            { type = ui.TYPE.Text, props = {
                                text            = removeLabel,
                                textSize        = 13,
                                textColor       = util.color.rgb(0.95, 0.45, 0.4),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = false,
                                size            = util.vector2(BTN_REMOVE_W, 30),
                                textAlignH      = ui.ALIGNMENT.Center,
                                textAlignV      = ui.ALIGNMENT.Center,
                            }},
                        })},
                    }),
                },
                { type = ui.TYPE.Widget, props = { size = util.vector2(BTNS_GAP, 1) } },
                {
                    type   = ui.TYPE.Widget,
                    props  = { size = util.vector2(BTN_CANCEL_W, 30), propagateEvents = false },
                    events = { mouseClick = async:callback(closeDialog) },
                    content = ui.content({
                        { template = MWUI.templates.boxSolid, content = ui.content({
                            { type = ui.TYPE.Text, props = {
                                text            = 'Cancel',
                                textSize        = 13,
                                textColor       = util.color.rgb(0.75, 0.75, 0.72),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = false,
                                size            = util.vector2(BTN_CANCEL_W, 30),
                                textAlignH      = ui.ALIGNMENT.Center,
                                textAlignV      = ui.ALIGNMENT.Center,
                            }},
                        })},
                    }),
                },
            }),
        }
    else
        bottomContent = {
            type   = ui.TYPE.Widget,
            props  = { size = util.vector2(BTN_CANCEL_W, 30), propagateEvents = false },
            events = { mouseClick = async:callback(closeDialog) },
            content = ui.content({
                { template = MWUI.templates.boxSolid, content = ui.content({
                    { type = ui.TYPE.Text, props = {
                        text            = 'Cancel',
                        textSize        = 13,
                        textColor       = util.color.rgb(0.75, 0.75, 0.72),
                        textShadow      = true,
                        textShadowColor = util.color.rgb(0, 0, 0),
                        autoSize        = false,
                        size            = util.vector2(BTN_CANCEL_W, 30),
                        textAlignH      = ui.ALIGNMENT.Center,
                        textAlignV      = ui.ALIGNMENT.Center,
                    }},
                })},
            }),
        }
    end

    return {
        layer = 'Windows',
        type  = ui.TYPE.Widget,
        props = { relativeSize = util.vector2(1, 1) },
        content = ui.content({
            { type = ui.TYPE.Image, props = {
                resource     = ui.texture({ path = 'white.png' }),
                color        = util.color.rgb(0, 0, 0),
                alpha        = 0.5,
                relativeSize = util.vector2(1, 1),
            }},
            { type  = ui.TYPE.Widget,
              props = {
                size             = util.vector2(PW, PH),
                relativePosition = util.vector2(0.5, 0.5),
                anchor           = util.vector2(0.5, 0.5),
              },
              content = ui.content({
                { template = MWUI.templates.boxSolidThick, content = ui.content({
                    { template = MWUI.templates.padding,
                      props    = { padding = 14 },
                      content  = ui.content({
                        { type  = ui.TYPE.Flex,
                          props = { autoSize = true, align = ui.ALIGNMENT.Center },
                          content = ui.content({
                            { type = ui.TYPE.Text, props = {
                                text            = 'Unlimited Rings',
                                textSize        = 16,
                                textColor       = util.color.rgb(0.98, 0.92, 0.72),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = true,
                            }},
                            { type = ui.TYPE.Widget, props = { size = util.vector2(1, 8) } },
                            { type = ui.TYPE.Text, props = {
                                text            = 'Equip: ' .. ringName,
                                textSize        = 13,
                                textColor       = util.color.rgb(0.95, 0.92, 0.88),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = true,
                            }},
                            { type = ui.TYPE.Widget, props = { size = util.vector2(1, 4) } },
                            { type = ui.TYPE.Text, props = {
                                text            = stackInfoText,
                                textSize        = 11,
                                textColor       = util.color.rgb(0.65, 0.82, 0.95),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = true,
                            }},
                            { type = ui.TYPE.Widget, props = { size = util.vector2(1, 10) } },
                            { type  = ui.TYPE.Flex,
                              props = { horizontal = true, autoSize = false, size = util.vector2(GW, GH) },
                              content = ui.content({
                                makeCol(1, 5),
                                { type = ui.TYPE.Widget, props = { size = util.vector2(12, 1) } },
                                makeCol(6, 10),
                              }),
                            },
                            { type = ui.TYPE.Widget, props = { size = util.vector2(1, 10) } },
                            bottomContent,
                          }),
                        },
                      }),
                    },
                })},
              }),
            },
        }),
    }
end

local function showDialog(item)
    local ringName = 'ring'
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.name and rec.name ~= '' then ringName = rec.name end
    pendingItem = item
    if activeDialog then activeDialog:destroy(); activeDialog = nil end
    pcall(function()
        activeDialog = ui.create(buildDialog(ringName, item))
    end)
end

local function onUnlimitedRingsPrompt(data)
    local item = findItemByRecordId(data.itemId)
    if item then
        showDialog(item)
    end
end

local function onFrame(dt)
    if initPending then
        initTimer = initTimer - dt
        if initTimer > 0 then return end

        local allFound = true
        for fingerStr, recId in pairs(assignments) do
            local fi = tonumber(fingerStr)
            if fi and FINGER_TO_BONE[fi] and not findItemByRecordId(recId) then
                allFound = false
                break
            end
        end

        if not allFound then
            initTimer = INIT_RETRY
            return
        end

        initPending = false
        refreshRingVfx(false)
        reapplyAllEnchantments()
        return
    end

    frameCounter = frameCounter - 1
    if frameCounter <= 0 then
        frameCounter = FRAME_INTERVAL
        for fingerStr, recId in pairs(assignments) do
            local fi = tonumber(fingerStr)
            if fi and FINGER_TO_BONE[fi] then
                local item = findItemByRecordId(recId)
                if item then applyEnchantment(item, fi) end
            end
        end
    end

    vfxCounter = vfxCounter - 1
    if vfxCounter <= 0 then
        vfxCounter = VFX_INTERVAL
        for fingerStr, recId in pairs(assignments) do
            local fi = tonumber(fingerStr)
            if fi and FINGER_TO_BONE[fi] then
                local item = findItemByRecordId(recId)
                if item then
                    anim.removeVfx(self_, fingerVfxId(fi))
                    addRingVfx(item, fi)
                end
            end
        end
    end

    if pendingEquip then
        local item = findItemByRecordId(pendingEquip.recId)
        if item then
            local slot  = pendingEquip.slot
            pendingEquip = nil
            local eq = types.Actor.equipment(self_)
            eq[slot] = item
            types.Actor.setEquipment(self_, eq)
            for fi, s in pairs(FINGER_TO_SLOT) do
                if s == slot then
                    anim.removeVfx(self_, fingerVfxId(fi))
                    addRingVfx(item, fi)
                    break
                end
            end
        end
    end
end

local function onUpdate(dt)
    if dt == 0 then return end

    local newCam    = camera.getMode()
    local newStance = types.Actor.getStance(self_)

    local newWeaponType = nil
    if newStance == STANCE.Weapon then
        newWeaponType = getCombatSuffix()
    end

    local camChanged        = (newCam ~= currentCam)
    local stanceChanged     = (newStance ~= currentStance)
    local weaponTypeChanged = (newWeaponType ~= currentWeaponType)

    if not camChanged and not stanceChanged and not weaponTypeChanged then return end

    local thumbsOnly = not camChanged
    for fingerStr, recId in pairs(assignments) do
        local fi = tonumber(fingerStr)
        if fi and FINGER_TO_BONE[fi] then
            local isThumb = (fi == 5 or fi == 10)
            if not thumbsOnly or isThumb then
                anim.removeVfx(self_, fingerVfxId(fi))
                local item = findItemByRecordId(recId)
                if item then addRingVfx(item, fi) end
            end
        end
    end

    currentCam        = newCam
    currentStance     = newStance
    currentWeaponType = newWeaponType
end

local function initState()
    assignments    = loadAssignments()
    activeSpellIds = {}
    closeDialog()
    frameCounter = FRAME_INTERVAL
    currentCam        = camera.getMode()
    currentStance     = types.Actor.getStance(self_)
    currentWeaponType = nil
    initPending  = true
    initTimer    = INIT_DELAY
end

return {
    engineHandlers = {
        onInit   = initState,
        onLoad   = initState,
        onActive = initState,
        onFrame  = onFrame,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        UnlimitedRings_PromptFinger = onUnlimitedRingsPrompt,
        vfxRemoveAll = function()
            initPending = true
            initTimer   = 0.3
        end,
    },
}
