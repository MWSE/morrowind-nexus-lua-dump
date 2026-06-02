local core = require('openmw.core')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.store')
local mSettings = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mScaling = require('scripts.skill-evolution.skills.scaling')
local mHelpers = require('scripts.skill-evolution.util.helpers')

local L = core.l10n(mDef.MOD_NAME)
local v2 = util.vector2
local API, Templates, constants, BASE, decayBarColor

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
    local averageData = {
        { list = feats.averages.allTime, header = "featAllTime" },
        { list = feats.averages.prevLevel, header = "featPrevLevel" },
        { list = feats.averages.currLevel, header = "featCurrLevel" },
    }
    for i = 1, #averageData do
        local data = averageData[i]
        if data.list.count > 0 then
            table.insert(average, {
                template = BASE.textNormal,
                props = { text = L(data.header) },
            })
            table.insert(average, BASE.padding(2))
            table.insert(average, featProgressBar {
                value = mHelpers.avg(data.list);
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
    local maxFeatStats = mS.settings.skillScalingMaxFeatStats.get()
    for i = 1, #feats do
        local feat = feats[i]
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

local function setDecayLayout(content, params, skillProgressIndex)
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
    for useType, useTypeFeats in mHelpers.spairs(feats, function(_, a, b) return a < b end) do
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
                    props = { text = L("featHeader2", {
                        useType = mDef.getSkillUseTypeName(mS.settings[mSettings.getSkillUseGainsKey(skillId)].argument.config.gains[useType].key),
                    }) },
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

    local skillProgressIndex = content:indexOf("progress")

    if params.baseModifier ~= 0 then
        content:insert(skillProgressIndex, {
            template = BASE.textNormal,
            props = { text = L(params.baseModifier > 0 and "tooltipBaseSkillBuff" or "tooltipBaseSkillDebuff", { mod = params.baseModifier }) }
        })
        content:insert(skillProgressIndex, BASE.padding(4))
        skillProgressIndex = skillProgressIndex + 2
    end
    if params.modifier > 0 then
        content:insert(skillProgressIndex, {
            template = BASE.textNormal,
            props = { text = L("tooltipSkillBuff", { mod = params.modifier }) }
        })
        content:insert(skillProgressIndex, BASE.padding(4))
        skillProgressIndex = skillProgressIndex + 2
    end
    if params.damage > 0 then
        content:insert(skillProgressIndex, {
            template = BASE.textNormal,
            props = { text = L("tooltipSkillDebuff", { mod = -params.damage }) }
        })
        content:insert(skillProgressIndex, BASE.padding(4))
        skillProgressIndex = skillProgressIndex + 2
    end
    if params.hasDecay then
        setDecayLayout(content, params, skillProgressIndex)
    end

    if mS.settings.skillScalingShowFeats.get() then
        local featsLayout = getFeatsLayout(params.skillId, params.feats)
        if featsLayout then
            for i = 1, #featsLayout do
                content:add(featsLayout[i])
            end
        end
    end

    return base
end

local function updateSkillLineBuilder(state)
    for _, skillRecord in ipairs(mCore.getSkillRecords()) do
        local skillId = skillRecord.id
        I.StatsWindow.modifyLine(skillId, {
            value = function()
                local hasDecay = mSettings.isDecayEnabled()
                local skill = mCore.getSkillStat(skillId)
                local color
                local maxDecayColorRatio = 0.5
                local decayColor = mCfg.decayColor
                local skillMod = skill.modified - skill.base
                skillMod = skillMod > 0 and math.floor(skillMod) or math.ceil(skillMod)
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
                    color = mHelpers.mixColors(decayColor, color, decayColorRatio)
                end
                return { string = tostring(math.floor(skill.modified)), color = color }
            end,
            tooltip = function()
                local hasDecay = mSettings.isDecayEnabled()
                local skill = mCore.getSkillStat(skillId)
                local baseModifier = mCore.getBaseSkillMods()[skillId] or 0
                -- handle both vanilla and custom skill formats
                local modifier = math.max(0, math.ceil(skill.modifier))
                local damage = skill.damage and skill.damage or math.min(0, math.floor(skill.modifier))
                local icon = type(skillRecord.icon) == "string" and { bgr = skillRecord.icon } or skillRecord.icon
                return skillTooltipBuilder({
                    skillId = skillId,
                    icon = icon,
                    title = skillRecord.name,
                    subtitle = constants.Strings.GOVERNING_ATTRIBUTE .. ': ' .. core.stats.Attribute.records[skillRecord.attribute].name,
                    description = skillRecord.description,
                    currentValue = skill.base,
                    progress = state.skills.progress[skillId],
                    maxValue = mSettings.getSkillCappedValue(skillId),
                    baseModifier = baseModifier > 0 and math.floor(baseModifier) or math.ceil(baseModifier),
                    modifier = modifier,
                    damage = damage,
                    hasDecay = hasDecay,
                    decayProgress = state.skills.decay[skillRecord.id] / mCfg.decayTimeBaseInHours,
                    decayLostLevels = state.skills.max[skillId] - state.skills.base[skillId],
                    feats = state.skills.feats[skillId],
                })
            end,
        })
    end
end

module.setStatsWindow = function(state)
    API = I.StatsWindow
    Templates = API.Templates
    constants = API.Constants
    BASE = Templates.BASE
    decayBarColor = mHelpers.mixColors(mCfg.decayColor, constants.Colors.DEFAULT, 0.5)
    updateSkillLineBuilder(state)
end

return module