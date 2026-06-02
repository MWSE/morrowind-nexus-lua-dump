local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local ui      = require('openmw.ui')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local storage = require('openmw.storage')
local util    = require('openmw.util')
local I       = require('openmw.interfaces')

local Actor = types.Actor
local MD    = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }


local glassesSettings = storage.playerSection('Settings_tt_FashionGL')
local AheadBoneOwner  = storage.playerSection('Settings_tt_glasses')
local glassesState    = storage.playerSection('Settings_tt_glasses_state')


local function claimAHeadBone() AheadBoneOwner:set('owner', 'glasses') end
local function AheadIsOurs()
    local owner = AheadBoneOwner:get('owner')
    return owner == nil or owner == 'glasses'
end


local function getActiveRecordId()  return glassesState:get('activeRecordId') end
local function setActiveRecordId(v) glassesState:set('activeRecordId', v) end

local function getRecordId(item)
    if not item then return nil end
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then return rec.id:lower() end
    ok, rec = pcall(types.Armor.record, item)
    if ok and rec and rec.id then return rec.id:lower() end
    return nil
end

local function findItemByRecordId(recId)
    if not recId then return nil end
    for _, item in ipairs(Actor.inventory(self):getAll()) do
        if getRecordId(item) == recId then return item end
    end
    return nil
end

local function buildSkinsPath(item)
    local ok, rec = pcall(function() return item.type.records[item.recordId] end)
    if not ok or not rec or not rec.model then return nil end
    local path = rec.model:lower()
    path = path:gsub('_gnd%.nif$', ''):gsub('%.nif$', '')
    local folder = path:match('^(.*[/\\])') or ''
    local fname  = path:match('([^/\\]+)$') or path
    return folder .. fname .. '_skins.nif'
end


local VFX_ID   = 'visibleGlasses'
local VFX_BONE = 'head'

local function removeCurrentVfx()
    anim.removeVfx(self, VFX_ID)
end

local function applyVfxForRecordId(recId)
    removeCurrentVfx()
    if not recId then return end
    if camera.getMode() == MD.first then return end
    if not AheadIsOurs() then return end
    local item = findItemByRecordId(recId)
    if not item then return end
    local skins = buildSkinsPath(item)
    if not skins then return end
    anim.addVfx(self, skins, {
        loop            = true,
        useAmbientLight = false,
        vfxId           = VFX_ID,
        boneName        = VFX_BONE,
    })
end

local function refreshVfx()
    local recId = getActiveRecordId()
    if not recId then removeCurrentVfx(); return end
    if not findItemByRecordId(recId) then
        setActiveRecordId(nil)
        removeCurrentVfx()
        return
    end
    applyVfxForRecordId(recId)
end


local activeDialog = nil

local function closeDialog()
    if activeDialog then activeDialog:destroy(); activeDialog = nil end
end

local function onConfirmEquip(item)
    claimAHeadBone()
    local recId = getRecordId(item)
    setActiveRecordId(recId)
    applyVfxForRecordId(recId)
end

local function onRemoveGlasses()
    setActiveRecordId(nil)
    removeCurrentVfx()
end

local function buildDialog(item)
    local MWUI = I.MWUI

    local itemName = 'Glasses'
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.name and rec.name ~= '' then
        itemName = rec.name
    else
        ok, rec = pcall(types.Armor.record, item)
        if ok and rec and rec.name and rec.name ~= '' then itemName = rec.name end
    end

    local recId     = getRecordId(item)
    local alreadyOn = (getActiveRecordId() == recId)

    local BTN_W = 220
    local BTN_H = 30
    local GAP   = 8

    local function makeBtn(label, color, callback)
        return {
            type   = ui.TYPE.Widget,
            props  = { size = util.vector2(BTN_W, BTN_H), propagateEvents = false },
            events = { mouseClick = async:callback(callback) },
            content = ui.content({
                { template = MWUI.templates.boxSolid, content = ui.content({
                    { type = ui.TYPE.Text, props = {
                        text            = label,
                        textSize        = 14,
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

    local spacer = { type = ui.TYPE.Widget, props = { size = util.vector2(1, GAP) } }

    local rows = {
        makeBtn(
            alreadyOn and 'Re-equip glasses' or 'Equip glasses',
            util.color.rgb(0.6, 0.95, 0.55),
            function() closeDialog(); onConfirmEquip(item) end
        ),
    }
    if alreadyOn then
        rows[#rows + 1] = spacer
        rows[#rows + 1] = makeBtn(
            'Remove glasses',
            util.color.rgb(0.95, 0.45, 0.4),
            function() closeDialog(); onRemoveGlasses() end
        )
    end
    rows[#rows + 1] = spacer
    rows[#rows + 1] = makeBtn(
        'Cancel',
        util.color.rgb(0.75, 0.75, 0.72),
        closeDialog
    )

    local numBtns = alreadyOn and 3 or 2
    local PW = BTN_W + 32
    local PH = 16 + 8 + 14 + 12 + numBtns * BTN_H + (numBtns - 1) * GAP + 24

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
                      external = { padding = 14 },
                      content  = ui.content({
                        { type  = ui.TYPE.Flex,
                          props = { autoSize = true, align = ui.ALIGNMENT.Center },
                          content = ui.content({
                            { type = ui.TYPE.Text, props = {
                                text            = 'Cosmetic Glasses',
                                textSize        = 16,
                                textColor       = util.color.rgb(0.98, 0.92, 0.72),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = true,
                            }},
                            { type = ui.TYPE.Widget, props = { size = util.vector2(1, 8) } },
                            { type = ui.TYPE.Text, props = {
                                text            = itemName,
                                textSize        = 13,
                                textColor       = util.color.rgb(0.95, 0.92, 0.88),
                                textShadow      = true,
                                textShadowColor = util.color.rgb(0, 0, 0),
                                autoSize        = true,
                            }},
                            { type = ui.TYPE.Widget, props = { size = util.vector2(1, 12) } },
                            { type  = ui.TYPE.Flex,
                              props = { autoSize = true, align = ui.ALIGNMENT.Center },
                              content = ui.content(rows),
                            },
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
    closeDialog()
    pcall(function()
        activeDialog = ui.create(buildDialog(item))
    end)
end


local function onGlassesPrompt(data)
    local item = findItemByRecordId(data.itemId)
    if item then showDialog(item) end
end

local cam            = camera.getMode()
local refreshPending = false
local refreshCounter = 0

local function onFrame(dt)
    if refreshCounter > 0 then refreshCounter = refreshCounter - 1; return end
    if refreshPending then refreshPending = false; refreshVfx() end
end

local function onUpdate(dt)
    if dt == 0 then return end
    local newCam = camera.getMode()
    if newCam == cam then return end
    cam = newCam
    refreshCounter = 3
    refreshPending = true
end

local function onActive()
    cam            = camera.getMode()
    refreshCounter = 3
    refreshPending = true
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame  = onFrame,
        onActive = onActive,
    },
    eventHandlers = {
        Glasses_PromptEquip = onGlassesPrompt,
        vfxRemoveAll = function()
            refreshCounter = math.random(11, 16)
            refreshPending = true
        end,
        UiModeChanged = function(e)
            local uiModes = {
                [I.UI.MODE.Rest]     = true,
                [I.UI.MODE.Training] = true,
                [I.UI.MODE.Travel]   = true,
            }
            if uiModes[e.oldMode] then
                refreshCounter = 3
                refreshPending = true
            end
        end,
    },
}
