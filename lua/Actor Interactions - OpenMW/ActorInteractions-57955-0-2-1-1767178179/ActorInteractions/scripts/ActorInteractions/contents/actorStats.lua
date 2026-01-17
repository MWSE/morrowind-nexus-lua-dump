local types          = require('openmw.types')
local self           = require('openmw.self')
local core           = require('openmw.core')
local async          = require('openmw.async')
local ui             = require('openmw.ui')
local I              = require('openmw.interfaces')
local util           = require('openmw.util')
local myTypes        = require("scripts.ActorInteractions.myLib.myTypes")
local toolTip        = require("scripts.ActorInteractions.myLib.toolTip")
local g              = require('scripts.ActorInteractions.myLib')
local events         = require('scripts.ActorInteractions.events')
local scrollableGrid = require('scripts.ActorInteractions.myLib.scrollableGrid')
-- local toolTip        = require('scripts.ActorInteractions.myLib.toolTip')
local scrollableList = require("scripts.ActorInteractions.myLib.scrollableList")
local simpleList     = require("scripts.ActorInteractions.myLib.simpleList")
local storage        = require('openmw.storage')
local o              = require('scripts.ActorInteractions.settingsData').o
local SECTION_KEY    = require('scripts.ActorInteractions.settingsData').SECTION_KEY
local mySection      = storage.playerSection(SECTION_KEY)

local actorStats     = {}

---@param name string
---@param value string|number
---@return ui.Layout
local function makeStat(name, value)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                external = { stretch = 1 },
                props = {
                        horizontal = true,
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = name
                                }
                        },
                        g.gui.makeInt(10, 0, 1),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = tostring(value)
                                }
                        },
                        -- g.gui.makeInt(1, 0, 1),
                }

        }
end

---@param target NPC
---@return { combat: ui.Layout[], magic: ui.Layout[], armor: ui.Layout[], other: ui.Layout[] }
local function getSkillsLayouts(target)
        ---@type {combat: ui.Layout[], magic: ui.Layout[], armor: ui.Layout[], other: ui.Layout[]}
        local skillsLayouts = {
                combat = {},
                armor = {},
                magic = {},
                other = {}
        }
        ---@param skillName string
        ---@param skillStat fun(target: NPC): SkillStat
        for skillName, skillStat in pairs(types.NPC.stats.skills) do
                local value = string.format('%s%d',
                        (skillStat(target).damage ~= 0 and '#ee0000') or
                        (skillStat(target).modifier ~= 0 and '#00ee00') or '',
                        skillStat(target).modified
                )
                -- skillName = skillName:sub(1, 1):upper() .. skillName:sub(2)
                local layout = makeStat(toolTip.affectedAttrSkill[skillName], value)

                for i, v in pairs(myTypes.SKILL_GROUP) do
                        -- print(skillName, v, v[skillName])
                        if v[skillName] then
                                table.insert(skillsLayouts[i], layout)
                        end
                end
        end

        for _, skillGroup in pairs(skillsLayouts) do
                table.sort(skillGroup, function(a, b)
                        return a.content[1].props.text < b.content[1].props.text
                end)
        end
        return skillsLayouts
end

---@param target NPC
---@return ui.Layout
function actorStats.getItemsLO(target)
        ---@type CreatureRecord|NpcRecord
        local record = target.type.record(target)

        local health = types.NPC.stats.dynamic.health(target).current
        local maxHealth = types.NPC.stats.dynamic.health(target).base

        local magicka = types.NPC.stats.dynamic.magicka(target).current
        local maxMagicka = types.NPC.stats.dynamic.magicka(target).base

        local fatigue = types.NPC.stats.dynamic.fatigue(target).current
        local maxFatigue = types.NPC.stats.dynamic.fatigue(target).base


        ---@type ui.Layout[]
        local attributesLayouts = {}
        ---@param attrName string
        for _, attrName in pairs(myTypes.ATTRIBUTES) do
                ---@type AttributeStats
                local stats = types.Actor.stats.attributes
                local value = string.format('%s%d',
                        (stats[attrName](target).damage ~= 0 and '#ee0000') or
                        (stats[attrName](target).modifier ~= 0 and '#00ee00') or '',
                        stats[attrName](target).modified
                )
                local layout = makeStat(toolTip.affectedAttrSkill[attrName], value)
                table.insert(attributesLayouts, layout)
        end

        local attributesFlex = {
                type = ui.TYPE.Flex,
                external = { stretch = 1 },
                content = ui.content(attributesLayouts)
        }

        local skillsLayouts
        local combatFlex
        local armorFlex
        local magicFlex
        local otherFlex
        if target.type == types.NPC then
                skillsLayouts = getSkillsLayouts(target)

                combatFlex = {
                        type = ui.TYPE.Flex,
                        props = {
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Center
                        },
                        -- template = I.MWUI.templates.borders,
                        external = { stretch = 0.90 },
                        content = ui.content(skillsLayouts.combat)
                }
                armorFlex = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        external = { stretch = 0.90 },
                        content = ui.content(skillsLayouts.armor)
                }
                magicFlex = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        external = { stretch = 0.90 },
                        content = ui.content(skillsLayouts.magic)
                }
                otherFlex = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        external = { stretch = 0.90 },
                        content = ui.content(skillsLayouts.other)
                }
        end



        local factionsLayout = {
                type = ui.TYPE.Flex,
                external = { stretch = 1 },

                content = ui.content {
                        {
                                template = I.MWUI.templates.textHeader,
                                props = {
                                        text = 'Factions:'
                                }
                        },

                }
        }


        local factionsList = {}
        if target.type == types.NPC then
                factionsList = types.NPC.getFactions(target)
                for _, faction in pairs(factionsList) do
                        if types.NPC.isExpelled(target, faction) ~= true then
                                local factionRecord = core.factions.records[faction]
                                if factionRecord then
                                        local factionName = factionRecord.name
                                        local factionRankName = ''

                                        local rank = types.NPC.getFactionRank(target, faction)
                                        local ranks = factionRecord.ranks

                                        if rank and ranks and ranks[rank] then
                                                factionRankName = ranks[rank].name
                                        end

                                        factionsLayout.content:add(makeStat(factionName, factionRankName))
                                end
                        end
                end
        end



        local layout = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                external = { stretch = 1 },
                props = {
                        -- relativeSize = util.vector2(1, 1),
                        size = util.vector2(600, 0),
                        horizontal = true,
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        g.gui.makeInt(8, 0),
                        {
                                type = ui.TYPE.Flex,
                                template = I.MWUI.templates.borders,
                                external = { stretch = 0, grow = 0.2 },
                                props = {
                                        arrange = ui.ALIGNMENT.Center,
                                        align = ui.ALIGNMENT.Center,
                                        horizontal = false
                                },
                                content = ui.content {

                                        g.gui.makeInt(0, 5),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders,
                                                external = { stretch = 0.92 },
                                                props = {
                                                        -- size = util.vector2(230, 1)
                                                },
                                                content = ui.content {
                                                        g.gui.makeLabelWithBar('Health', g.gui.makeGUIBar(health, maxHealth, 130, 18, 'bb3333')),
                                                        g.gui.makeLabelWithBar('Magicka', g.gui.makeGUIBar(magicka, maxMagicka, 130, 18, '3333bb')),
                                                        g.gui.makeLabelWithBar('Fatigue', g.gui.makeGUIBar(fatigue, maxFatigue, 130, 18, '33bb33')),
                                                        g.gui.makeInt(0, 9),

                                                        -- g.gui.makeInt(0, 18),
                                                        makeStat('Level', types.Actor.stats.level(target).current),
                                                        target.type == types.NPC and makeStat('Race', types.NPC.races.record(record.race).name) or {},
                                                        target.type == types.NPC and makeStat('Class', types.NPC.classes.record(record.class).name) or {},
                                                        -- target.type == types.NPC and makeStat('Faction', types.NPC.fa) or {},
                                                        g.gui.makeInt(0, 9),
                                                        -- (target.type == types.NPC and (#factionsList ~= 0)) and factionsLayout or g.gui.makeInt(0, 18),
                                                        #factionsList > 0 and factionsLayout or g.gui.makeInt(0, 18),
                                                        g.gui.makeInt(0, 18),
                                                        attributesFlex


                                                }
                                        },
                                        g.gui.makeInt(0, 10),

                                }
                        },
                        g.gui.makeInt(10, 0),
                        skillsLayouts and {
                                type = ui.TYPE.Flex,
                                template = I.MWUI.templates.borders,
                                external = { grow = 0.2, stretch = 1 },
                                props = {
                                        arrange = ui.ALIGNMENT.Center,
                                },

                                content = ui.content {
                                        g.gui.makeInt(0, 5),

                                        {
                                                template = I.MWUI.templates.textHeader,
                                                props = {
                                                        text = 'Combat Skills',
                                                }
                                        },
                                        g.gui.makeInt(0, 5),

                                        combatFlex,
                                        g.gui.makeInt(0, 0, 1),
                                        {
                                                template = I.MWUI.templates.textHeader,
                                                props = {
                                                        text = 'Magic Skills',
                                                }
                                        },
                                        g.gui.makeInt(0, 5),
                                        magicFlex,

                                        g.gui.makeInt(0, 10),
                                }
                        } or {},
                        g.gui.makeInt(10, 0),
                        skillsLayouts and {
                                type = ui.TYPE.Flex,
                                template = I.MWUI.templates.borders,
                                external = { grow = 0.2, stretch = 1 },
                                props = {
                                        arrange = ui.ALIGNMENT.Center,
                                },

                                content = ui.content {
                                        g.gui.makeInt(0, 5),
                                        {
                                                template = I.MWUI.templates.textHeader,
                                                props = {
                                                        text = 'Armor Skills',
                                                }
                                        },
                                        g.gui.makeInt(0, 5),
                                        armorFlex,
                                        g.gui.makeInt(0, 0, 1),

                                        {
                                                template = I.MWUI.templates.textHeader,
                                                props = {
                                                        text = 'Other Skills',
                                                }
                                        },
                                        g.gui.makeInt(0, 5),
                                        otherFlex,
                                        g.gui.makeInt(0, 10),
                                },
                        } or {},
                        skillsLayouts and g.gui.makeInt(10, 0) or g.gui.makeInt(300, 0),
                }
        }

        return layout
end

return actorStats
