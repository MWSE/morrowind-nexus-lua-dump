local core = require('openmw.core')
local I = require('openmw.interfaces')

local nativeSetCustomSkills = core.stats and core.stats._setCustomSkillsForStatsWindow
local nativeClearCustomSkills = core.stats and core.stats._clearCustomSkillsForStatsWindow

local handlersBoundTo = nil
local hadPublished = false
local dirty = true

local function isTableLike(value)
    local valueType = type(value)
    return valueType == 'table' or valueType == 'userdata'
end

local function supportsNativeBridge()
    return type(nativeSetCustomSkills) == 'function'
end

local function markDirty()
    dirty = true
end

local function bindSkillFrameworkHandlers(sf)
    if handlersBoundTo == sf then
        return
    end

    handlersBoundTo = sf

    if not sf then
        return
    end

    if type(sf.addSkillRegisteredHandler) == 'function' then
        sf.addSkillRegisteredHandler(markDirty)
    end

    if type(sf.addSkillStatChangedHandler) == 'function' then
        sf.addSkillStatChangedHandler(markDirty)
    end

    markDirty()
end

local function isSkillVisible(record)
    local props = record and record.statsWindowProps
    if not props or props.visible == nil then
        return true
    end

    if type(props.visible) == 'function' then
        local ok, result = pcall(props.visible)
        return (not ok) or result
    end

    return props.visible ~= false
end

local function collectCustomSkillsForNativeStats(sf)
    if not isTableLike(sf) or type(sf.getSkillRecords) ~= 'function' or type(sf.getSkillStat) ~= 'function' then
        return {}
    end

    local okRecords, records = pcall(sf.getSkillRecords)
    if not okRecords or not isTableLike(records) then
        return {}
    end

    local skills = {}
    local showSubsections = true
    do
        local okConfig, configPlayer = pcall(require, 'scripts.SkillFramework.config.player')
        if okConfig and isTableLike(configPlayer) and isTableLike(configPlayer.options)
            and configPlayer.options.b_ShowSubsections == false then
            showSubsections = false
        end
    end

    local useSubsections = false
    if showSubsections then
        for _, record in pairs(records) do
            if isTableLike(record) and isTableLike(record.statsWindowProps)
                and record.statsWindowProps.subsection ~= nil then
                useSubsections = true
                break
            end
        end
    end

    for id, record in pairs(records) do
        if type(id) == 'string' and isTableLike(record) and type(record.name) == 'string' and record.name ~= ''
            and isSkillVisible(record) then
            local okStat, stat = pcall(sf.getSkillStat, id)
            if okStat and isTableLike(stat) then
                local icon = ''
                if isTableLike(record.icon) and type(record.icon.fgr) == 'string' then
                    icon = record.icon.fgr
                end

                local attribute = ''
                if type(record.attribute) == 'string' then
                    attribute = record.attribute
                end

                local subsection
                if useSubsections and isTableLike(record.statsWindowProps)
                    and record.statsWindowProps.subsection ~= nil then
                    subsection = tostring(record.statsWindowProps.subsection)
                end

                local base = tonumber(stat.base) or 0
                local modified = tonumber(stat.modified) or base
                local progress = tonumber(stat.progress) or 0
                local maxLevel = tonumber(record.maxLevel) or 100

                table.insert(skills, {
                    id = id,
                    name = record.name,
                    description = type(record.description) == 'string' and record.description or '',
                    icon = icon,
                    attribute = attribute,
                    subsection = subsection,
                    base = math.floor(base),
                    modified = math.floor(modified),
                    progress = progress,
                    maxLevel = math.floor(maxLevel),
                    visible = true,
                })
            end
        end
    end

    table.sort(skills, function(a, b)
        if a.name == b.name then
            return a.id < b.id
        end
        return a.name < b.name
    end)

    return skills
end

local function publish()
    local sf = I.SkillFramework
    bindSkillFrameworkHandlers(sf)

    if not sf then
        if hadPublished and type(nativeClearCustomSkills) == 'function' then
            nativeClearCustomSkills()
            hadPublished = false
        end
        return
    end

    nativeSetCustomSkills(collectCustomSkillsForNativeStats(sf))
    hadPublished = true
end

return {
    engineHandlers = {
        onInit = markDirty,
        onLoad = markDirty,
        onUpdate = function()
            if not supportsNativeBridge() then
                return
            end

            if not dirty then
                bindSkillFrameworkHandlers(I.SkillFramework)
                return
            end

            dirty = false
            publish()
        end,
    },
}
