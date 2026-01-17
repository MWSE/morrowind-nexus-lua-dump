local core = require('openmw.core')
local storage = require('openmw.storage')
local self = require('openmw.self')
local T = require('openmw.types')
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')

local mDef = require('scripts.NCG.config.definition')
local mCfg = require('scripts.NCG.config.configuration')
local mS = require('scripts.NCG.config.settings')
local mCore = require('scripts.NCG.util.core')
local mC = require('scripts.NCG.common')

local L = core.l10n(mDef.MOD_NAME)
local v2 = util.vector2
local API
local C
local BASE

local module = {}

local function addColorToText(text, color, prevColor)
    return string.format("#%s%s#%s", color:asHex(), text, prevColor:asHex())
end

local function getHealthTooltipDetails(state, description)
    local healthFactor = mC.getHealthFactor(state)
    local perLevelHP = mS.getPerLevelHPGainFactor()
    local details = string.format("%s\n\n%s\n\n%s",
            description,
            addColorToText(L("tooltipHealthDetailsHeader"), C.Colors.DEFAULT_LIGHT, C.Colors.DEFAULT),
            L("tooltipHealthDetails", {
                healthFactor = healthFactor,
                perLevelHP = perLevelHP,
                levelHP = (mC.self.level.current - 1) * perLevelHP * healthFactor,
            }))
    local maxHealthMod = mCore.getMaxHealthModifier(self)
    if maxHealthMod ~= 0 then
        details = string.format("%s\n%s", details, L("tooltipHealthMaxModDetails", { maxHealthMod = maxHealthMod }))
    end
    return string.format("%s\n\n%s",
            details,
            L("tooltipHealthFactorDetails", {
                baseHPFactor = mS.getBaseHPFactor(),
                endurance = state.healthAttrs.endurance * mCfg.healthAttributeFactors.endurance,
                strength = state.healthAttrs.strength * mCfg.healthAttributeFactors.strength,
                willpower = state.healthAttrs.willpower * mCfg.healthAttributeFactors.willpower,
            }))
end

local function setHealth(state)
    API.modifyLine(C.DefaultLines.HEALTH, {
        tooltip = function()
            local description = L(C.Strings.HEALTH_DESC)
            if mS.healthStorage:get("showHealthValueDetails") then
                description = getHealthTooltipDetails(state, description)
            end
            return API.TooltipBuilders.ICON({
                icon = { bgr = 'icons/k/health.dds' },
                title = C.Strings.HEALTH,
                description = description,
            })
        end,
    })
end

local function setLevel(state)
    API.modifyLine(C.DefaultLines.LEVEL, {
        tooltip = function()
            return API.Templates.STATS.tooltip(
                    8,
                    API.Templates.STATS.levelProgressBar(
                            state.level.skillUps % state.level.skillUpsPerLevel,
                            state.level.skillUpsPerLevel,
                            {}),
                    'level')
        end
    })
end

local function setDeaths(state)
    API.addLineToSection("DEATHS", C.DefaultSections.LEVEL_STATS, {
        label = L("tooltipDeathCountTitle"),
        labelColor = C.Colors.DEFAULT_LIGHT,
        value = function()
            return { string = tostring(storage.playerSection(state.profileId):get("deathCount") or 0) }
        end,
        tooltip = function()
            return API.TooltipBuilders.HEADER(L("tooltipDeathCountTitle"), L("tooltipDeathCountDesc"), "")
        end,
        visibleFn = function()
            return mS.healthStorage:get("deathCounter")
        end,
    })
end

local function setMarksmansEye()
    API.addLineToSection("MARKSMANS_EYE", C.DefaultSections.LEVEL_STATS, {
        label = L("tooltipMarksmansEyeTitle"),
        labelColor = C.Colors.DEFAULT_LIGHT,
        value = function()
            return { string = I.MarksmansEye.Level() }
        end,
        tooltip = function()
            return API.TooltipBuilders.HEADER(L("tooltipMarksmansEyeTitle"), L("tooltipMarksmansEyeDesc"), "")
        end,
        visibleFn = function()
            return not not I.MarksmansEye
        end,
    })
end

-- Attribute tooltip from StatsWindow mod
local baseAttributeTooltipContent = function(props)
    return
    {
        -- Icon and title
        {
            name = 'headerRow',
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    name = 'icon',
                    props = {
                        size = v2(32, 32),
                    },
                    content = ui.content {
                        props.icon.bgr and {
                            name = 'bgr',
                            type = ui.TYPE.Image,
                            props = {
                                relativeSize = v2(1, 1),
                                resource = ui.texture { path = props.icon.bgr },
                                color = props.icon.bgrColor or util.color.rgb(1, 1, 1),
                            }
                        } or {},
                        props.icon.fgr and {
                            name = 'fgr',
                            type = ui.TYPE.Image,
                            props = {
                                relativeSize = v2(1, 1),
                                resource = ui.texture { path = props.icon.fgr },
                                color = props.icon.fgrColor or util.color.rgb(1, 1, 1),
                            }
                        } or {},
                    }
                },
                BASE.padding(4),
                {
                    name = 'titleFlex',
                    type = ui.TYPE.Flex,
                    props = {
                        grow = 1,
                    },
                    content = ui.content {
                        props.title and {
                            name = 'title',
                            template = BASE.textHeader,
                            props = {
                                text = props.title,
                            }
                        } or {},
                        props.subtitle and {
                            name = 'subtitle',
                            template = BASE.textNormal,
                            props = {
                                text = props.subtitle,
                            }
                        } or {},
                    }
                }
            }
        },
        BASE.padding(4),
        -- Description
        props.description and {
            template = BASE.textParagraph,
            props = {
                size = v2(400, 0),
                text = props.description,
                autoSize = true,
            }
        } or {},
    }
end

local function setAttributeTooltipProgress(state, attr, cap, content)
    local progress
    if state.attrs.base[attr.id] >= cap then
        progress = {
            BASE.padding(4),
            {
                template = BASE.textNormal,
                props = {
                    text = L("tooltipAttributeCapReached"),
                    textSize = API.Templates.STATS.TEXT_SIZE,
                }
            },
        }
    else
        progress = {
            BASE.padding(4),
            {
                template = BASE.textHeader,
                props = {
                    text = L("tooltipAttributeProgress"),
                    textSize = API.Templates.STATS.TEXT_SIZE,
                }
            },
            API.Templates.STATS.progressBar {
                value = state.attrs.progress[attr.id] * 100,
                maxValue = 100,
                size = v2(200, API.Templates.STATS.LINE_HEIGHT),
                color = C.Colors.BAR_HEALTH,
            },
        }
    end
    table.insert(content, {
        type = ui.TYPE.Flex,
        external = { stretch = 1 },
        props = { arrange = ui.ALIGNMENT.Center },
        content = ui.content(progress),
    })
end

local function setAttributeTooltipDetails(state, attrId, baseMod, content)
    local text
    local legend
    local finalBaseMod = baseMod + state.attrs.diffs[attrId]

    if attrId == "luck" then
        local luckGrowthRate = mS.getLuckGrowthRate()
        local growth = math.floor(luckGrowthRate * (mC.self.level.current - 1))
        text = L("tooltipLuckDetails", {
            chargen = state.attrs.chargen[attrId],
            rate = luckGrowthRate,
            growth = growth,
        })
        if mS.healthStorage:get("deathCounter") then
            local modifier = mS.healthStorage:get("luckModifierPerDeath")
            local count = storage.playerSection(state.profileId):get("deathCount") or 0
            text = string.format("%s\n%s", text, L("tooltipLuckDeaths", {
                perDeath = modifier,
                deaths = count,
                -- round to replace -0 with 0
                mod = util.round(math.floor(modifier * count)),
            }))
        end
    else
        local baseValue = T.Actor.stats.attributes[attrId](self).base
        local growth = baseValue - finalBaseMod - state.attrs.start[attrId]
        local ratio = mS.getAttributeStartValuesRatio()
        local baseStart = state.attrs.chargen[attrId] * ratio
        text = L("tooltipAttributeDetails", {
            chargen = state.attrs.chargen[attrId],
            ratio = ratio,
            start = baseStart,
            norm = state.attrs.normValue,
            growth = growth,
        })
        legend = L("tooltipAttributeLegend", { ratio = ratio })
    end

    if baseMod ~= 0 then
        text = string.format("%s\n%s", text, L("tooltipAttributeBaseMod", { mod = baseMod }))
    end
    if state.attrs.diffs[attrId] ~= 0 then
        text = string.format("%s\n%s", text, L("tooltipAttributeBaseDiff", { diff = state.attrs.diffs[attrId] }))
    end
    if legend then
        text = string.format("%s\n\n%s", text, legend)
    end
    table.insert(content, BASE.padding(4))
    table.insert(content, {
        template = BASE.textHeader,
        props = { text = L("tooltipAttributeDetailsHeader") }
    })
    table.insert(content, BASE.padding(4))
    table.insert(content, {
        template = BASE.textParagraph,
        props = {
            text = text,
            size = v2(400, 0),
            autoSize = true,
        }
    })
end

local function setAttributes(state)
    local baseAttrMods = mC.getBaseStatMods().attr
    local attrsCap = mS.getAttributeGeneralMaxValue()
    local perAttrCaps = mS.getPerAttributeMaxValues()
    for _, attrRecord in ipairs(core.stats.Attribute.records) do
        API.modifyLine(attrRecord.id, {
            tooltip = function()
                local content = baseAttributeTooltipContent({
                    icon = { bgr = attrRecord.icon },
                    title = attrRecord.name,
                    description = attrRecord.description,
                })
                local attr = T.Actor.stats.attributes[attrRecord.id](self)
                local mod = attr.modified - attr.base
                if mod ~= 0 then
                    table.insert(content, BASE.padding(4))
                    table.insert(content, {
                        template = BASE.textNormal,
                        props = { text = L(mod > 0 and "tooltipAttributePositiveMod" or "tooltipAttributeMod", { mod = mod }) }
                    })
                end
                setAttributeTooltipProgress(state, attrRecord, perAttrCaps[attrRecord.id] or attrsCap, content)
                if mS.attributesStorage:get("showAttributeValueDetails") then
                    setAttributeTooltipDetails(state, attrRecord.id, baseAttrMods[attrRecord.id] or 0, content)
                end
                return API.Templates.STATS.tooltip(4, ui.content {
                    {
                        name = 'tooltip',
                        type = ui.TYPE.Flex,
                        content = ui.content(content),
                    },
                })
            end,
        })
    end
end

module.setStatsWindow = function(state)
    API = I.StatsWindow
    C = API.Constants
    BASE = API.Templates.BASE
    setHealth(state)
    setLevel(state)
    setDeaths(state)
    setAttributes(state)
    setMarksmansEye()
end

return module