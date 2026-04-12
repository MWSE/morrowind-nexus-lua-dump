local I = require('openmw.interfaces')
local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')

local l10n = core.l10n('SkillFramework')

local API = require('scripts.SkillFramework.api')

local configGlobal = require('scripts.SkillFramework.config.global')

local nativeStatsHandlersRegistered = false
local nativeStatsDirty = true

local function supportsNativeStatsWindowBridge()
    return core.stats and type(core.stats._setCustomSkillsForStatsWindow) == 'function'
end

local function markNativeStatsDirty()
    nativeStatsDirty = true
end

local function initNativeStatsWindowBridge()
    if nativeStatsHandlersRegistered then
        return
    end

    nativeStatsHandlersRegistered = true

    API.interface.addSkillRegisteredHandler(function()
        markNativeStatsDirty()
    end)

    API.interface.addSkillStatChangedHandler(function()
        markNativeStatsDirty()
    end)
end

local function publishCustomSkillsToNativeStatsWindow()
    if self.type ~= types.Player then
        return
    end

    if not supportsNativeStatsWindowBridge() then
        return
    end

    local configPlayer = require('scripts.SkillFramework.config.player')

    local records = API.interface.getSkillRecords()
    local skills = {}

    local useSubsections = false
    if configPlayer.options.b_ShowSubsections then
        for _, rec in pairs(records) do
            if rec and rec.statsWindowProps and rec.statsWindowProps.subsection ~= nil then
                useSubsections = true
                break
            end
        end
    end

    local ordered = {}
    for id, rec in pairs(records) do
        if id and rec then
            table.insert(ordered, { id = id, rec = rec })
        end
    end

    table.sort(ordered, function(a, b)
        local an = tostring(a.rec.name or a.id)
        local bn = tostring(b.rec.name or b.id)
        if an == bn then
            return a.id < b.id
        end
        return an < bn
    end)

    for _, entry in ipairs(ordered) do
        local id, rec = entry.id, entry.rec
        if rec then
            local visible = true
            if rec.statsWindowProps and rec.statsWindowProps.visible ~= nil then
                if type(rec.statsWindowProps.visible) == 'function' then
                    local ok, result = pcall(rec.statsWindowProps.visible)
                    visible = (not ok) or result
                else
                    visible = rec.statsWindowProps.visible
                end
            end

            if visible then
                local stat = API.interface.getSkillStat(id)
                if stat then
                    local subsection
                    if useSubsections then
                        local subsectionName = (rec.statsWindowProps and rec.statsWindowProps.subsection) or API.interface.STATS_WINDOW_SUBSECTIONS.Misc
                        subsection = tostring(subsectionName)
                    end

                    table.insert(skills, {
                        id = id,
                        name = rec.name,
                        description = rec.description or '',
                        icon = rec.icon and rec.icon.fgr or '',
                        attribute = rec.attribute or '',
                        subsection = subsection,
                        base = math.floor(stat.base or 0),
                        modified = math.floor(stat.modified or stat.base or 0),
                        progress = stat.progress or 0,
                        maxLevel = rec.maxLevel or 100,
                        visible = true,
                    })
                end
            end
        end
    end

    core.stats._setCustomSkillsForStatsWindow(skills)
end

local function initStatsWindowIntegration()
    if I.StatsWindow then
        local configPlayer = require('scripts.SkillFramework.config.player')
        local C = I.StatsWindow.Constants

        I.StatsWindow.trackStat('SF_CustomSkills', function() return API.interface.getSkillRecords() end)

        local lineBuilder = function(skillId)
            local skillRecord = API.interface.getSkillRecord(skillId)
            if not skillRecord then
                return nil
            end
            return {
                label = skillRecord.name,
                labelColor = C.Colors.DEFAULT,
                value = function()
                    local skillStat = API.interface.getSkillStat(skillId)
                    local color
                    if skillStat.modified > skillStat.base then
                        color = C.Colors.POSITIVE
                    elseif skillStat.modified < skillStat.base then
                        color = C.Colors.DAMAGED
                    end
                    return { string = tostring(math.floor(skillStat.modified)), color = color }
                end,
                tooltip = function()
                    local skillStat = API.interface.getSkillStat(skillId)
                    return I.StatsWindow.TooltipBuilders.SKILL({
                        icon = skillRecord.icon,
                        title = skillRecord.name,
                        subtitle = skillRecord.attribute and (I.StatsWindow.Constants.Strings.GOVERNING_ATTRIBUTE .. ': ' .. core.stats.Attribute.records[skillRecord.attribute].name) or nil,
                        description = skillRecord.description,
                        currentValue = skillStat.base,
                        progress = skillStat.progress,
                        maxLevel = skillRecord.maxLevel,
                    })
                end,
                visibleFn = function()
                    if type(skillRecord.statsWindowProps.visible) == 'function' then
                        return skillRecord.statsWindowProps.visible()
                    else
                        return skillRecord.statsWindowProps.visible
                    end
                end,
                onClick = skillRecord.statsWindowProps.onClick,
            }
        end

        I.StatsWindow.addSectionToBox('otherSkills', C.DefaultBoxes.RIGHT_SCROLL_BOX, {
            l10n = 'SkillFramework',
            placement = {
                type = C.Placement.AFTER,
                target = C.DefaultSections.MISC_SKILLS,
                priority = 1,
            },
            header = l10n('StatsWindow_OtherSkillsHeader'),
            indent = true,
            sort = C.Sort.LABEL_ASC,

            trackedStats = { SF_CustomSkills = true },
            builder = function()
                local records = API.interface.getSkillRecords()

                -- Check whether any record defines a subsection
                local hasSubsection = false

                if configPlayer.options.b_ShowSubsections then
                    for id, rec in pairs(records) do
                        if rec and rec.statsWindowProps and rec.statsWindowProps.subsection ~= nil then
                            hasSubsection = true
                            break
                        end
                    end
                end

                if not hasSubsection then
                    for id in pairs(records) do
                        I.StatsWindow.addLineToSection(id, 'otherSkills', lineBuilder(id))
                    end
                    return
                end

                -- Group skills by subsection name
                local groups = {}
                for id, rec in pairs(records) do
                    local subsectionName = (rec and rec.statsWindowProps and rec.statsWindowProps.subsection) or API.interface.STATS_WINDOW_SUBSECTIONS.Misc
                    local nameKey = tostring(subsectionName)
                    if not groups[nameKey] then
                        groups[nameKey] = { subsectionId = 'otherSkills_' .. nameKey, ids = {} }
                    end
                    table.insert(groups[nameKey].ids, id)
                end

                -- Sort subsection names ascending
                local names = {}
                for name in pairs(groups) do
                    table.insert(names, name)
                end
                table.sort(names, function(a, b) return a < b end)

                -- Create subsections in sorted order and add their skills
                for _, name in ipairs(names) do
                    local info = groups[name]
                    I.StatsWindow.addSectionToSection(info.subsectionId, 'otherSkills', {
                        header = tostring(name),
                        indent = true,
                        sort = C.Sort.LABEL_ASC,
                    })

                    for _, id in ipairs(info.ids) do
                        I.StatsWindow.addLineToSection(id, info.subsectionId, lineBuilder(id))
                        if records[id].statsWindowProps.shortenedName then
                            I.StatsWindow.modifyLine(id, {
                                label = records[id].statsWindowProps.shortenedName,
                            })
                        end
                    end
                end
            end,
        })
    end
end

-- Reuse logic from scripts.omw.mechanics.playercontroller, but for custom skills

local function skillUsedHandler(skillId, params)
    if self.type.isWerewolf(self) then
        return false
    end

    local skillStat = API.interface.getSkillStat(skillId)
    local skillRecord = API.interface.getSkillRecord(skillId)
    if not skillStat or not skillRecord then
        return false
    end

    local req = API.interface.getSkillProgressRequirement(skillId)
    if not req or req <= 0 then
        skillStat.progress = 1
    else
        skillStat.progress = skillStat.progress + params.skillGain / req
    end

    if skillStat.progress >= 1 and not (skillRecord.maxLevel >= 0 and skillStat.base >= skillRecord.maxLevel) then
        API.interface.skillLevelUp(skillId, API.interface.SKILL_INCREASE_SOURCES.Usage)
    end
end

local function skillLevelUpHandler(skillId, source, params)
    local skillStat = API.interface.getSkillStat(skillId)
    local skillRecord = API.interface.getSkillRecord(skillId)
    if not skillStat or not skillRecord then
        return false
    end

    if (skillRecord.maxLevel >= 0 and skillStat.base >= skillRecord.maxLevel and params.skillIncreaseValue > 0) or
        (skillStat.base <= 0 and params.skillIncreaseValue < 0) then
        return false
    end

    if params.skillIncreaseValue then
        skillStat.base = skillStat.base + params.skillIncreaseValue
    end

    local levelStat = self.type.stats.level(self)
    if params.levelUpProgress then
        levelStat.progress = levelStat.progress + params.levelUpProgress
    end

    if params.levelUpAttribute and params.levelUpAttributeIncreaseValue and configGlobal.options.b_SkillsProgressAttributes then
        levelStat.skillIncreasesForAttribute[params.levelUpAttribute] =
            levelStat.skillIncreasesForAttribute[params.levelUpAttribute] + params.levelUpAttributeIncreaseValue
    end

    if params.levelUpSpecialization and params.levelUpSpecializationIncreaseValue then
        levelStat.skillIncreasesForSpecialization[params.levelUpSpecialization] =
            levelStat.skillIncreasesForSpecialization[params.levelUpSpecialization] + params.levelUpSpecializationIncreaseValue
    end

    if source ~= API.interface.SKILL_INCREASE_SOURCES.Jail then
        if self.type == types.Player then
            local ui = require('openmw.ui')
            local ambient = require('openmw.ambient')

            ambient.playSound('skillraise')

            local message = string.format(core.getGMST('sNotifyMessage39'), skillRecord.name, skillStat.base)

            if source == API.interface.SKILL_INCREASE_SOURCES.Book then
                message = '#{sBookSkillMessage}\n'..message
            end

            ui.showMessage(message, { showInDialogue = false })

            if levelStat.progress >= core.getGMST('iLevelUpTotal') then
                ui.showMessage('#{sLevelUpMsg}', { showInDialogue = false })
            end
        end
        
        if not source or source == API.interface.SKILL_INCREASE_SOURCES.Usage then skillStat.progress = 0 end
    end
end

API.interface.addSkillUsedHandler(skillUsedHandler)
API.interface.addSkillLevelUpHandler(skillLevelUpHandler)

local function onBookRead(recordId)
    recordId = string.lower(recordId)
    local bookRecord = API.interface.getSkillBookRecord(recordId)
    if not bookRecord then
        return
    end
    
    for skillId, props in pairs(bookRecord) do
        if not API.interface.isSkillBookRead(recordId, skillId) then
            local grant = true
            local grantFailMsg
            if type(props.grantSkill) == 'function' then
                grant, grantFailMsg = props.grantSkill()
            else
                grant = props.grantSkill
            end

            if grant then
                API.interface.skillLevelUp(skillId, API.interface.SKILL_INCREASE_SOURCES.Book, props.skillIncrease)
                API.interface.setSkillBookReadState(recordId, skillId, true)
            elseif grantFailMsg then
                if self.type == types.Player then
                    local ui = require('openmw.ui')
                    ui.showMessage(grantFailMsg, { showInDialogue = false })
                end
            end
        end
    end
end

return {
    interfaceName = 'SkillFramework',
    interface = API.interface,
    engineHandlers = {
        onInit = function()
            initStatsWindowIntegration()
            initNativeStatsWindowBridge()
            markNativeStatsDirty()
        end,
        onSave = function()
            return API.onSave()
        end,
        onLoad = function(data)
            API.onLoad(data)
            initStatsWindowIntegration()
            initNativeStatsWindowBridge()
            markNativeStatsDirty()
        end,
        onUpdate = function()
            API.onUpdate()
            if nativeStatsDirty then
                nativeStatsDirty = false
                publishCustomSkillsToNativeStatsWindow()
            end
        end,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == 'Book' or data.newMode == 'Scroll' then
                if data.arg then
                    onBookRead(data.arg.recordId)
                end
            end
        end,       
    }
}
