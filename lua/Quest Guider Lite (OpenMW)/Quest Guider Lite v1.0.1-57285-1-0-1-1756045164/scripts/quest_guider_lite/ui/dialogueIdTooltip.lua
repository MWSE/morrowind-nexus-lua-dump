local ui = require('openmw.ui')
local util = require('openmw.util')
local templates = require('openmw.interfaces').MWUI.templates
local core = require('openmw.core')

local config = require("scripts.quest_guider_lite.configLib")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local commonData = require("scripts.quest_guider_lite.common")

local interval = require("scripts.quest_guider_lite.ui.interval")

local l10n = core.l10n(commonData.l10nKey)

local this = {}


---@param params {meta : questGuider.ui.questBoxMeta?, recordInfo : questGuider.playerQuest.storageQuestInfo?, fontSize : integer?, filter : string?}
function this.getContentForTooltip(params)
    if not params or (not params.meta and not params.recordInfo) then return ui.content{} end

    local meta = params.meta
    local recordInfo = params.recordInfo

    local list = {}

    if meta then
        local arrayIndexByDiaId = {}
        local count = 1
        for _, info in ipairs(meta.params.playerQuestData.list) do
            if not arrayIndexByDiaId[info.diaId] then
                arrayIndexByDiaId[info.diaId] = count
                table.insert(list, {diaId = info.diaId, index = info.index})
                count = count + 1
            else
                list[arrayIndexByDiaId[info.diaId]].index = info.index
            end
        end
    elseif recordInfo then
        table.insert(list, {diaId = recordInfo.diaId, index = recordInfo.index})
    end

    local idStr
    for _, qData in ipairs(list) do
        if not idStr then
            idStr = string.format(l10n("tooltipIDStringStart"), qData.diaId, tostring(qData.index))
        else
            idStr = string.format(l10n("tooltipIDString"), idStr, qData.diaId, tostring(qData.index))
        end
    end
    idStr = idStr or ""

    local startedInStr = l10n("receivedInDefault")
    if meta and meta.params.playerQuestData.list[1] then
        local firstRecordData = meta.params.playerQuestData.list[1]
        if firstRecordData.cellData then
            startedInStr = string.format(l10n("startedIn"), firstRecordData.cellData.name)
        end
    elseif recordInfo and recordInfo.cellData then
        startedInStr = string.format(l10n("receivedIn"), recordInfo.cellData.name)
    end

    local scaledScreenSize = uiUtils.getScaledScreenSize()
    local width = scaledScreenSize.x / 3
    local fontSize = params.fontSize or (meta and meta.params.fontSize) or 18
    local idTextHeight = uiUtils.getTextHeight(idStr, fontSize, width, config.data.journal.textHeightMul)
    local startedInHeight = uiUtils.getTextHeight(startedInStr, fontSize, width, config.data.journal.textHeightMul)

    if params.filter then
        idStr = uiUtils.colorize(idStr, params.filter, "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex())
    end

    return ui.content{
        {
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = idStr,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = util.vector2(width, idTextHeight),
                textSize = fontSize,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Start,
            },
        },
        interval(0, fontSize),
        {
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = startedInStr,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = util.vector2(width, startedInHeight),
                textSize = fontSize,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Start,
            },
        },
    }
end

return this