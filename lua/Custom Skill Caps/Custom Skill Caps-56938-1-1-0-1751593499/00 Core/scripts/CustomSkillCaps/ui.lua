local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local info = require('scripts.CustomSkillCaps.info')
local myui = require('scripts.' .. info.name .. '.myui')

local v2 = util.vector2

local function contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

local function capital(text)
    return text:gsub('^%l', string.upper)
end

local function sortAlphabetical(a, b)
    return a:lower() < b:lower()
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Mod settings

local modSettings = {
    basic = storage.playerSection('SettingsPlayer' .. info.name .. 'Basic')
}

-- Player data

local Player = types.Player

local function getPlayerRecords()
    local playerRecord = Player.record(self)
    return {
        class = Player.classes.record(playerRecord.class)
    }
end

-- Get maximum value for skill depending on settings and class
local function getSkillCap(skillid)
    capMethod = modSettings.basic:get('SkillCapMethod')
    if capMethod == 'SharedCap' then
        return modSettings.basic:get('SharedSkillCap')
    elseif capMethod == 'ClassCap' then
        local playerRecords = getPlayerRecords()
        if contains(playerRecords.class.majorSkills, skillid) then
            return modSettings.basic:get('MajorSkillCap')
        elseif contains(playerRecords.class.minorSkills, skillid) then
            return modSettings.basic:get('MinorSkillCap')
        else
            return modSettings.basic:get('MiscSkillCap')
        end
    elseif capMethod == 'UniqueCap' then
        return modSettings.basic:get(capital(skillid) .. 'Cap')
    end
end

-- Game settings

local gameSettings = {
    skillMaxed = core.getGMST('sSkillMaxReached'),
    skillProgress = core.getGMST('sSkillProgress')
}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Menu resources

local resources = {
    barColor = ui.texture{path = 'textures/menu_bar_gray.dds'}
}

-- Menu variables

local menu

local menuLayout

local colors = {
    health = myui.textColors.health,
    positive = myui.textColors.positive
}

-- Create an alphabetical list of skills
local skillList = {}

for i, skillRecord in ipairs(core.stats.Skill.records) do
    table.insert(skillList, skillRecord.id)
    resources[skillRecord.id] = ui.texture{path = skillRecord.icon}
end

table.sort(skillList, sortAlphabetical)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- UI creation functions

local function createSkillFlex(skillId)
    local skillFlex = {
        name = skillId,
        type = ui.TYPE.Flex,
        props = {autoSize = false, size = v2(250, 64), horizontal = true, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center},
        content = ui.content {
            {
                name = 'icon',
                type = ui.TYPE.Image,
                props = {resource = resources[skillId], size = v2(32, 32)}
            },
            myui.padWidget(18, 0),
            {
                name = 'infoFlex',
                type = ui.TYPE.Flex,
                props = {align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center},
                content = ui.content {
                    {
                        name = 'nameFlex',
                        type = ui.TYPE.Flex,
                        props = {horizontal = true, autosize = false, size = v2(200, 16)},
                        content = ui.content {
                            {
                                name = 'name',
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {text = core.stats.Skill.record(skillId).name, textColor = colors.positive}
                            },
                            {
                                name = 'padding',
                                external = {grow = 1.0}
                            },
                            {
                                name = 'level',
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {text = tostring(types.Player.stats.skills[skillId](self).base)}
                            }
                        }
                    },
                    {
                        name = 'progressFlex',
                        type = ui.TYPE.Flex,
                        props = {autoSize = false, size = v2(200, 48), align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center},
                        content = ui.content {}
                    }
                }
            }
        }
    }

    local skillCap = getSkillCap(skillId)
    if skillCap > 0 and types.Player.stats.skills[skillId](self).base >= skillCap then
        skillFlex.content.infoFlex.content.progressFlex.content:add{
            name = 'maxedText',
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = gameSettings.skillMaxed, autoSize = false, size = v2(200, 48), wordWrap = true, textAlignH = ui.ALIGNMENT.Center, textAlignV = ui.ALIGNMENT.Center}
        }
    else
        local progress = types.Player.stats.skills[skillId](self).progress
        local progressPercent = math.floor(progress * 100)
        skillFlex.content.infoFlex.content.progressFlex.content:add{
            name = 'progressBar',
            type = ui.TYPE.Container,
            template = I.MWUI.templates.box,
            props = {},
            content = ui.content {
                {
                    name = 'color',
                    type = ui.TYPE.Image,
                    props = {resource = resources.barColor, color = colors.health, size = v2(196 * progress, 16)}
                },
                {
                    name = 'progress',
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = progressPercent .. '/100', textAlignH = ui.ALIGNMENT.Center, textAlignV = ui.ALIGNMENT.Center, autoSize = false, size = v2(196, 16), position = v2(0, -2)}
                }
            }
        }
    end
    return skillFlex
end

local function createProgressMenuLayout()
    menuLayout = {
        layer = 'Windows',
        name = 'progressMenu',
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxTransparentThick,
        props = {relativePosition = v2(0.5, 0.5), anchor = v2(0.5, 0.5)},
        content = ui.content {
            {
                name = 'mainFlex',
                type = ui.TYPE.Flex,
                props = {horizontal = true, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center},
                content = ui.content {}
            }
        }
    }

    local specializations = {
        'combat',
        'stealth',
        'magic'
    }

    for _, specialization in ipairs(specializations) do
        columnLayout = {
            name = specialization,
            type = ui.TYPE.Container,
            template = myui.padding(16, 16),
            content = ui.content{
                {
                    name = 'flex',
                    type = ui.TYPE.Flex,
                    props = {},
                    content = ui.content{}
                }
            }
        }
        menuLayout.content.mainFlex.content:add(columnLayout)
    end

    for i, skillId in ipairs(skillList) do
        local specialization = core.stats.Skill.record(skillId).specialization
        menuLayout.content.mainFlex.content[specialization].content.flex.content:add(createSkillFlex(skillId))
    end
end

local function createProgressMenu()
    createProgressMenuLayout()
    menu = ui.create(menuLayout)
end

local function updateProgressMenu(skillId)
    if menu ~= nil then
        local specialization = core.stats.Skill.record(skillId).specialization
        menuLayout.content.mainFlex.content[specialization].content.flex.content[skillId] = createSkillFlex(skillId)
        menu:update()
    end
end

local function hideProgressMenu()
    if menu ~= nil then
        menu:destroy()
        menu = nil
        return false
    else
        return true
    end
end

return {
    createProgressMenu = createProgressMenu,
    updateProgressMenu = updateProgressMenu,
    hideProgressMenu = hideProgressMenu
}