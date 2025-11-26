local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.settings')
local mH = require('scripts.skill-evolution.util.helpers')

local L = core.l10n(mDef.MOD_NAME)
local API = I.StatsWindow
local C = API.Constants
local BASE = API.Templates.BASE
local v2 = util.vector2
local decayBarColor = mH.mixColors(mCfg.decayColor, C.Colors.DEFAULT, 0.5)

local module = {}

local skillDecayProgressBar = function(progress)
    return ui.content {
        BASE.padding(4),
        {
            template = BASE.textHeader,
            props = {
                text = L("tooltipDecayProgress"),
                textSize = API.Templates.STATS.TEXT_SIZE,
            }
        },
        API.Templates.STATS.progressBar {
            value = progress * 100,
            maxValue = 100,
            size = v2(200, API.Templates.STATS.LINE_HEIGHT),
            color = decayBarColor,
        }
    }
end

local skillTooltipBuilder = function(params)
    local base = API.Templates.STATS.skillTooltip(params)
    if not params.hasDecay then
        return base
    end
    local content = base.content[1].content.tooltip.content
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
    return base
end

local setSkillLineBuilder = function(state)
    API.LineBuilders.SKILL = function(skillId)
        local skillRecord = core.stats.Skill.records[skillId]
        return {
            label = skillRecord.name,
            labelColor = C.Colors.DEFAULT,
            value = function()
                local hasDecay = mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
                local skillStat = self.type.stats.skills[skillId](self)
                local color
                local maxDecayColorRatio = 0.5
                local decayColor = mCfg.decayColor
                local skillMod = skillStat.modified - skillStat.base
                if skillMod > 0 then
                    color = C.Colors.POSITIVE
                    decayColor = mCfg.decayBuffedColor
                elseif skillMod < 0 then
                    color = C.Colors.DAMAGED
                    decayColor = mCfg.decayDamagedColor
                else
                    color = C.Colors.DEFAULT
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
                    icon = { bgr = skillRecord.icon },
                    title = skillRecord.name,
                    subtitle = C.Strings.GOVERNING_ATTRIBUTE .. ': ' .. core.stats.Attribute.records[skillRecord.attribute].name,
                    description = skillRecord.description,
                    currentValue = skillStat.base,
                    progress = state.skills.progress[skillId],
                    maxValue = mS.getSkillMaxValue(skillId),
                    skillMod = util.round(skillStat.modified - skillStat.base),
                    hasDecay = hasDecay,
                    decayProgress = state.skills.decay[skillRecord.id] / mCfg.decayTimeBaseInHours,
                    decayLostLevels = state.skills.max[skillId] - state.skills.base[skillId],
                })
            end,
        }
    end
end

module.setStatsWindow = function(state)
    setSkillLineBuilder(state)
end

return module