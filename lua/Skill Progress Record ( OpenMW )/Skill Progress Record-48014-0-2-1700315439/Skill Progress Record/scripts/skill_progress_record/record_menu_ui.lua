local ui = require("openmw.ui")
local util = require("openmw.util")
local input = require("openmw.input")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local async = require("openmw.async")
local storage = require("openmw.storage")
local l10n = core.l10n("skill_progress_record")
local const = require("scripts.skill_progress_record.constants")
local playerSettings = storage.playerSection("Settings_SkillProgressRecord_CONTROLS")
local SPC = I.SkillProgressRecord_eqnx

local spc_main_menu = nil
local spc_help_menu = nil
local confirmNotification = nil
local waitingForYN = false
local c_textSize = playerSettings:get("textSize")
local num = 1
local levelview = SPC.getLevel.current

playerSettings:subscribe(async:callback(function(sectionName, changedKey)
    if changedKey == "textSize" or changedKey == nil then
        c_textSize = playerSettings:get("textSize")
    end
end))

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

local recordNavigation = {
    [input.ACTION.MoveRight] = ">",
    [input.ACTION.MoveLeft] = "<",
    [input.ACTION.Inventory] = "inventory",
}

local function listSkills()
    local tbl = {}
    local pad = nil
    local attr = core.stats.Attribute.records[num].id
    for _, skill in pairs(core.stats.Skill.records) do
        if attr == skill.attribute then
            local skillincreasethislevel = SPC.getSkillIncreaseThisLevel(skill.id, levelview)
            local symbol = skillincreasethislevel < 0 and "-" or "+"
            table.insert(tbl, {
                name = "skill_and_value_block",
                type = ui.TYPE.Flex,
                props =
                {
                    horizontal = true,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                    {
                        name = "skill",
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props =
                        {

                            text = string.format("%s: %s ", skill.name, SPC.getSkillValueHistory(skill.id, levelview)),
                            textSize = c_textSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        }
                    },
                    {
                        name = "added",
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props =
                        {

                            text = skillincreasethislevel ~= 0 and string.format("%s %s", symbol, math.abs(skillincreasethislevel)) or "",
                            textSize = c_textSize,
                            textColor = skillincreasethislevel > 0 and util.color.hex("33FF33") or util.color.hex("FF3333"),
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        }
                    }
                }

            })
            if pad then
                pad.props.size = util.vector2(10, 20) -- hack to remove the last padding
            end
            pad = padding(0, 0)
            table.insert(tbl, pad)
        end
    end

    table.remove(tbl) -- hack to remove the last padding
    return table.unpack(tbl)
end

local function listButtons()
    local tbl = {}
    local isHighligted
    for index, attr in pairs(core.stats.Attribute.records) do
        isHighligted = (index == num) and attr or isHighligted
        table.insert(tbl,
            {
                template = index == num and I.MWUI.templates.boxTransparentThick or I.MWUI.templates.padding,
                propagateEvents = false,
                events = {
                    mouseClick = async:callback(function() ui.showMessage(attr.name) end)

                },
                content = ui.content {
                    {
                        name = "attribute",
                        type = ui.TYPE.Text,
                        template = index == num and I.MWUI.templates.textHeader or I.MWUI.templates.textNormal,
                        props =
                        {
                            text = " " .. attr.name .. " ",
                            textSize = c_textSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        },
                    },

                }
            }
        )

        table.insert(tbl, padding(20, 20))
    end

    return table.unpack(tbl)
end

local function openRecord()
    return ui.create {
        name = "spc_main_menu",
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Windows',
        props =
        {
            horizontal = false,
            relativePosition = util.vector2(.5, .5),
            anchor = util.vector2(.5, .5),
            alpha = 1,
        },
        content = ui.content {
            {
                name = "mainflex",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    alpha = 1,
                },
                content = ui.content {
                    padding(10, 10),
                    {
                        name = "spc_main_menu_block",
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                            alpha = 1,
                        },
                        content = ui.content {
                            {
                                name = "level_change_text",
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = l10n("settings_modName"),
                                    textSize = c_textSize,
                                    textAlignH = ui.ALIGNMENT.Center,
                                    textAlignV = ui.ALIGNMENT.Center
                                },
                            },
                            {
                                name = "skill_increase_text",
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = string.format("<%s %s>", l10n("level"), levelview, SPC.getTotalSkillIncreaseThisLevel(levelview)),
                                    textSize = c_textSize,
                                    textAlignH = ui.ALIGNMENT.Center,
                                    textAlignV = ui.ALIGNMENT.Center
                                },
                            },
                            padding(10, 10),
                            {
                                name = "attribute_name_text",
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props =
                                {

                                    text = core.stats.Attribute.records[num].name:upper(),
                                    textSize = c_textSize,
                                    textAlignH = ui.ALIGNMENT.Center,
                                    textAlignV = ui.ALIGNMENT.Center
                                }
                            },
                            {
                                name = "divider",
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props =
                                {

                                    text = string.rep("--", 10),
                                    textSize = c_textSize,
                                    textAlignH = ui.ALIGNMENT.Center,
                                    textAlignV = ui.ALIGNMENT.Center
                                }
                            },
                            {
                                name = "skill_list_block",
                                type = ui.TYPE.Flex,
                                props =
                                {
                                    horizontal = false,
                                    align = ui.ALIGNMENT.Center,
                                    arrange = ui.ALIGNMENT.Center
                                },
                                content = ui.content {
                                    listSkills()
                                }
                            },
                            {
                                name = "divider",
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props =
                                {
                                    text = string.rep(" ", 4) .. string.rep("_", 100) .. string.rep(" ", 4),
                                    textSize = c_textSize,
                                    textAlignH = ui.ALIGNMENT.Center,
                                    textAlignV = ui.ALIGNMENT.Center
                                }
                            },
                            padding(10, 10),
                            {
                                name = "buttons_flex_block",
                                type = ui.TYPE.Flex,
                                props =
                                {
                                    horizontal = true,
                                    align = ui.ALIGNMENT.Center,
                                    arrange = ui.ALIGNMENT.Center
                                },
                                content = ui.content {
                                    listButtons()
                                }
                            }
                        }
                    },
                    padding(10, 10),
                }
            },

        },

    }
end

local function helpMenu()
    return ui.create {
        name = "spc_help_menu",
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Windows',
        props =
        {
            horizontal = false,
            relativePosition = util.vector2(0, 0),
            anchor = util.vector2(0, 0),
            alpha = 1,
        },
        content = ui.content {
            {
                name = "spc_main_menu_block",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    alpha = 1,
                },
                content = ui.content {
                    padding(400, 10),
                    {
                        name = "help",
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props =
                        {
                            text = l10n("Next/Prev Attribute [Left/Right]"),
                            textSize = c_textSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        }
                    },
                    {
                        name = "help",
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props =
                        {
                            text = l10n("Next/Prev Level [Shift + Left/Right]"),
                            textSize = c_textSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        }
                    },
                    {
                        name = "help",
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props =
                        {
                            text = string.format(l10n("Reset Data [Shift + %s]"), playerSettings:get("Open Reset"):upper()),
                            textSize = c_textSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        }
                    },
                    {
                        name = "help",
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props =
                        {
                            text = string.format(l10n("Open/Close [%s]"), playerSettings:get("Open Record"):upper()),
                            textSize = c_textSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center
                        }
                    },
                    padding(400, 10),
                    -- {
                    --     name = "help",
                    --     template = I.MWUI.templates.textParagraph,
                    --     props =
                    --     {
                    --         text = l10n("game_infoDesc"),
                    --         size = util.vector2(400, 10),
                    --         textSize = c_textSize,
                    --         textAlignH = ui.ALIGNMENT.Center,
                    --         textAlignV = ui.ALIGNMENT.Center
                    --     }
                    -- },
                    -- padding(400, 10),
                }
            }
        }
    }
end

local function resetConfirmation()
    return ui.create {
        name = "SkillProgressRecord_CONFIRM",
        template = I.MWUI.templates.boxTransparentThick,
        layer = 'Popup',
        props =
        {
            horizontal = false,
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            alpha = 1,
        },
        content = ui.content {
            {
                name = "help",
                template = I.MWUI.templates.textParagraph,
                props =
                {
                    text = string.format("%s\n\n%s\n\n\n%s[%s] - %s[%s]", l10n("are you sure"), l10n("erase all"), core.getGMST("sYes"), playerSettings:get("Yes"):upper(), core.getGMST("sCancel"), l10n("any")),
                    textSize = c_textSize,
                    size = util.vector2(300, 300),
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center
                }
            },
        }
    }
end

local function toggleRecord()
    if spc_main_menu and spc_help_menu then
        spc_main_menu:destroy()
        spc_main_menu = nil
        spc_help_menu:destroy()
        spc_help_menu = nil
        types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, true)
        --I.UI.setMode()
    else
        --I.UI.setMode('Interface', {windows = {}})
        spc_main_menu = openRecord()
        spc_main_menu:update()
        spc_help_menu = helpMenu()
        spc_help_menu:update()
        types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, false)
    end
end

local function updateRecord()
    if spc_main_menu and spc_help_menu then
        spc_main_menu:destroy()
        spc_main_menu = openRecord()
        spc_main_menu:update()

        spc_help_menu:destroy()
        spc_help_menu = helpMenu()
        spc_help_menu:update()
    end
end

return {
    engineHandlers = {
        onKeyPress = function(key)
            if waitingForYN and confirmNotification then
                if key.symbol == playerSettings:get("Yes"):lower() then
                    SPC.clearData()
                    ui.showMessage(l10n("All records erased!"))
                    confirmNotification:destroy()
                    waitingForYN = false
                    confirmNotification = nil
                else
                    confirmNotification:destroy()
                    waitingForYN = false
                    confirmNotification = nil
                end
            end
            if key.symbol == playerSettings:get("Open Record"):lower() then
                toggleRecord()
                core.sound.playSoundFile3d(const.soundClickPath, self)
            elseif input.isShiftPressed() and key.symbol == playerSettings:get("Open Reset"):lower() then
                if spc_main_menu and not confirmNotification then
                    confirmNotification = resetConfirmation()
                    confirmNotification:update()
                    waitingForYN = true
                    --ui.showMessage("Not yet implemented")
                end
            end
        end,
        onInputAction = function(id)
            local command = recordNavigation[id]
            if command and spc_main_menu then
                if command == ">" then
                    if input.isShiftPressed() then
                        levelview = math.min(levelview + 1, SPC.getLevel.current)
                        if levelview == SPC.getLevel.current then
                            ui.showMessage("Your current level is " .. levelview)
                        end
                    else
                        num = (num + 1) > #core.stats.Attribute.records and 1 or (num + 1)
                    end
                elseif command == "<" then
                    if input.isShiftPressed() then
                        levelview = math.max(1, levelview - 1)
                    else
                        num = (num - 1) < 1 and #core.stats.Attribute.records or (num - 1)
                    end
                elseif command == "inventory" then
                    toggleRecord()
                end
                core.sound.playSoundFile3d(const.soundClickPath, self)
                updateRecord()
            end
        end,
        onFrame = function(dt)

        end
    },
    eventHandlers = {
        SkillProgressRecord_resetSkillsCounter_eqnx = function()
            levelview = SPC.getLevel.current
        end
    }
}
