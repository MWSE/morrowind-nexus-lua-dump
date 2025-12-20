local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.settings')
local mScaling = require('scripts.skill-evolution.skills.scaling')
local mH = require('scripts.skill-evolution.util.helpers')

local L = core.l10n(mDef.MOD_NAME)
local v2 = util.vector2
local API = I.StatsWindow
local Templates = API.Templates
local constants = API.Constants
local BASE = Templates.BASE
local decayBarColor = mH.mixColors(mCfg.decayColor, constants.Colors.DEFAULT, 0.5)

local module = {}

local stretchingLine = {
    template = I.MWUI.templates.horizontalLine,
    external = { grow = 1 }
}

local stretchingLineThick = {
    template = I.MWUI.templates.horizontalLineThick,
    external = { grow = 1 }
}

-- same as Stats Window Extender's, but without borders, and with aligned progresses
local featProgressBar = function(props)
    props.value = math.floor(props.value or 0)
    props.maxValue = math.floor(props.maxValue or 100)
    props.size = props.size or v2(100, Templates.STATS.LINE_HEIGHT)
    props.color = props.color or constants.Colors.RED
    props.textColor = props.textColor or constants.Colors.DEFAULT

    local percentage = props.maxValue ~= 0 and math.min(math.max(props.value / props.maxValue, 0), 1) or 1

    return {
        name = 'value',
        props = {
            size = props.size,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = v2(percentage, 1),
                    resource = ui.texture { path = 'textures/menu_bar_gray.dds' },
                    color = props.color,
                }
            },
            {
                template = BASE.textNormal,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    text = string.format("%d%%", props.value),
                    textColor = props.textColor,
                    textSize = Templates.STATS.TEXT_SIZE,
                }
            },
        }
    }
end

local function skillDecayProgressBar(progress)
    return ui.content {
        BASE.padding(4),
        {
            template = BASE.textHeader,
            props = {
                text = L("tooltipDecayProgress"),
                textSize = Templates.STATS.TEXT_SIZE,
            }
        },
        Templates.STATS.progressBar {
            value = progress * 100,
            maxValue = 100,
            size = v2(200, Templates.STATS.LINE_HEIGHT),
            color = decayBarColor,
        },
    }
end

local function addFeatAveragesLayout(layout, feats, maxValue)
    table.insert(layout, {
        type = ui.TYPE.Flex,
        props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
        external = { stretch = 1 },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { size = v2(20, 0) },
                content = ui.content {
                    stretchingLine,
                },
            },
            BASE.padding(4),
            {
                template = BASE.textHeader,
                props = { text = L("featAverages") },
            },
            BASE.padding(4),
            stretchingLine,
        },
    })

    local average = {}
    for _, data in ipairs({
        { list = feats.averages.allTime, header = "featAllTime" },
        { list = feats.averages.prevLevel, header = "featPrevLevel" },
        { list = feats.averages.currLevel, header = "featCurrLevel" },
    }) do
        if data.list.count > 0 then
            table.insert(average, {
                template = BASE.textNormal,
                props = { text = L(data.header) },
            })
            table.insert(average, BASE.padding(2))
            table.insert(average, featProgressBar {
                value = mH.avg(data.list);
                maxValue = maxValue,
                size = v2(65, Templates.STATS.LINE_HEIGHT),
                color = constants.Colors.BAR_HEALTH,
            })
            table.insert(average, BASE.padding(4))
        end
    end
    table.insert(layout, {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        external = { stretch = 1 },
        content = ui.content(average),
    })
end

local function addFeatListLayout(layout, headerKey, lineKey, feats, maxValue)
    table.insert(layout, {
        type = ui.TYPE.Flex,
        props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
        external = { stretch = 1 },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { size = v2(20, 0) },
                content = ui.content {
                    stretchingLine,
                },
            },
            BASE.padding(4),
            {
                template = BASE.textHeader,
                props = { text = L(headerKey) },
            },
            BASE.padding(4),
            stretchingLine,
        },
    })
    local maxFeatStats = mS.skillUsesScaledStorage:get("skillScalingMaxFeatStats")
    for i, feat in ipairs(feats) do
        if i > maxFeatStats then return end
        table.insert(layout, {
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            external = { stretch = 1 },
            content = ui.content {
                {
                    template = BASE.textNormal,
                    props = { text = L("featGain") },
                },
                BASE.padding(2),
                featProgressBar {
                    value = feat.factor,
                    maxValue = maxValue,
                    size = v2(65, Templates.STATS.LINE_HEIGHT),
                    color = constants.Colors.BAR_HEALTH,
                },
                BASE.padding(4),
                {
                    template = BASE.textNormal,
                    props = { text = L(lineKey, { level = feat.skillLvl, props = mScaling.formatFeatProps(feat) }) },
                },
            },
        })
    end
end

local function setDecayLayout(content, params)
    local skillProgressIndex = content:indexOf("progress")
    -- insert in revert order
    if params.decayLostLevels > 0 then
        content:insert(skillProgressIndex, {
            template = BASE.textNormal,
            props = { text = L("tooltipDecayGainBoost", { factor = 100 * util.round(mCfg.decayLostLevelsSkillGainFact(params.decayLostLevels)) }) }
        })
        content:insert(skillProgressIndex, {
            template = BASE.textNormal,
            props = { text = L("tooltipDecayDecayedLevels", { levels = params.decayLostLevels }) }
        })
    end
    if params.skillMod ~= 0 then
        content:insert(skillProgressIndex, {
            template = BASE.textNormal,
            props = { text = L(params.skillMod > 0 and "tooltipSkillPositiveMod" or "tooltipSkillMod", { mod = params.skillMod }) }
        })
    end
    content:insert(skillProgressIndex, BASE.padding(4))

    content:add({
        name = 'decayProgress',
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.Center },
        external = { stretch = 1 },
        content = skillDecayProgressBar(params.decayProgress),
    })
end

local function getFeatsLayout(skillId, feats)
    if not next(feats) then return end
    local layout = {}
    for useType, useTypeFeats in mH.spairs(feats, function(_, a, b) return a < b end) do
        local maxValue = useTypeFeats.lists.best[1].factor
        table.insert(layout, BASE.padding(9))
        table.insert(layout, {
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            external = { stretch = 1 },
            content = ui.content {
                stretchingLineThick,
                BASE.padding(4),
                {
                    template = BASE.textHeader,
                    props = { text = L("featHeader1") },
                },
                BASE.padding(4),
                {
                    type = ui.TYPE.Flex,
                    props = { size = v2(10, 0) },
                    content = ui.content { stretchingLineThick },
                },
                BASE.padding(4),
                {
                    template = BASE.textHeader,
                    props = { text = L("featHeader2", { useType = mS.getSkillUseTypeName(mCfg.skillUseTypes[skillId][useType].key) }) },
                },
                BASE.padding(4),
                stretchingLineThick,
            },
        })
        addFeatAveragesLayout(layout, useTypeFeats, maxValue)
        addFeatListLayout(layout, "featBest", "featBestLine", useTypeFeats.lists.best, maxValue)
        if #useTypeFeats.lists.level ~= 0 then
            addFeatListLayout(layout, "featLevel", "featLevelLine", useTypeFeats.lists.level, maxValue)
        end
        addFeatListLayout(layout, "featLast", "featLastLine", useTypeFeats.lists.last, maxValue)
    end
    return layout
end

local function skillTooltipBuilder(params)
    local base = Templates.STATS.skillTooltip(params)
    local content = base.content[1].content.tooltip.content

    if params.hasDecay then
        setDecayLayout(content, params)
    end

    if mS.skillUsesScaledStorage:get("skillScalingShowFeats") then
        local featsLayout = getFeatsLayout(params.skillId, params.feats)
        if featsLayout then
            for _, item in ipairs(featsLayout) do
                content:add(item)
            end
        end
    end

    return base
end

local function setSkillLineBuilder(state)
    API.LineBuilders.SKILL = function(skillId)
        local skillRecord = core.stats.Skill.records[skillId]
        return {
            label = skillRecord.name,
            labelColor = constants.Colors.DEFAULT,
            value = function()
                local hasDecay = mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
                local skillStat = self.type.stats.skills[skillId](self)
                local color
                local maxDecayColorRatio = 0.5
                local decayColor = mCfg.decayColor
                local skillMod = skillStat.modified - skillStat.base
                if skillMod > 0 then
                    color = constants.Colors.POSITIVE
                    decayColor = mCfg.decayBuffedColor
                elseif skillMod < 0 then
                    color = constants.Colors.DAMAGED
                    decayColor = mCfg.decayDamagedColor
                else
                    color = constants.Colors.DEFAULT
                    maxDecayColorRatio = 0.75
                end
                if hasDecay then
                    local decayColorRatio = 0
                    if state.skills.max[skillId] > state.skills.base[skillId] then
                        decayColorRatio = maxDecayColorRatio
                    else
                        decayColorRatio = math.min(maxDecayColorRatio, state.skills.decay[skillRecord.id] / mCfg.decayTimeBaseInHours)
                    end
                    color = mH.mixColors(decayColor, color, decayColorRatio)
                end
                return { string = tostring(math.floor(skillStat.modified)), color = color }
            end,
            tooltip = function()
                local hasDecay = mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
                local skillStat = self.type.stats.skills[skillId](self)
                return skillTooltipBuilder({
                    skillId = skillId,
                    icon = { bgr = skillRecord.icon },
                    title = skillRecord.name,
                    subtitle = constants.Strings.GOVERNING_ATTRIBUTE .. ': ' .. core.stats.Attribute.records[skillRecord.attribute].name,
                    description = skillRecord.description,
                    currentValue = skillStat.base,
                    progress = state.skills.progress[skillId],
                    maxValue = mS.getSkillMaxValue(skillId),
                    skillMod = util.round(skillStat.modified - skillStat.base),
                    hasDecay = hasDecay,
                    decayProgress = state.skills.decay[skillRecord.id] / mCfg.decayTimeBaseInHours,
                    decayLostLevels = state.skills.max[skillId] - state.skills.base[skillId],
                    feats = state.skills.feats[skillId],
                })
            end,
        }
    end
end

module.setStatsWindow = function(state)
    setSkillLineBuilder(state)
end

return module