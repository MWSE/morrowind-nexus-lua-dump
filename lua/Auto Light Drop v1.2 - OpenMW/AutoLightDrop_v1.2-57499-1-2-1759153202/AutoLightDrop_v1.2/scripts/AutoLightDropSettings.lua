local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local MOD_ID = "AutoLightDrop"
local SETTINGS_KEY = "Settings" .. MOD_ID

local settings = storage.playerSection(SETTINGS_KEY)

-- Custom renderer for Exception Item IDs list
I.Settings.registerRenderer('AutoLightDropExceptionList', function(input, set)
    local value = {}
    for i = 1, #input do
        table.insert(value, input[i])
    end

    local header = {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content({}),
        external = { stretch = 1 },
    }
    local inputText = ''
    header.content:add({
        template = I.MWUI.templates.box,
        content = ui.content({
            {
                template = I.MWUI.templates.textEditLine,
                events = {
                    textChanged = async:callback(function(text)
                        inputText = text:lower()
                    end),
                },
            },
        }),
    })
    header.content:add({
        template = I.MWUI.templates.padding,
        external = { grow = 1 },
    })
    header.content:add({
        template = I.MWUI.templates.box,
        content = ui.content({
            {
                template = I.MWUI.templates.textNormal,
                props = { text = "Add" },
                events = {
                    mouseClick = async:callback(function()
                        if inputText ~= '' then
                            table.insert(value, inputText)
                            set(value)
                            inputText = ''
                        end
                    end),
                },
            },
        }),
    })

    local body = {
        type = ui.TYPE.Flex,
        content = ui.content({}),
    }

    local function remove(text)
        for i, v in ipairs(value) do
            if v == text then
                table.remove(value, i)
                break
            end
        end
    end

    for _, text in ipairs(value) do
        body.content:add({ template = I.MWUI.templates.padding })
        body.content:add({
            type = ui.TYPE.Flex,
            props = { horizontal = true },
            content = ui.content({
                { template = I.MWUI.templates.textNormal, props = { text = text } },
                { template = I.MWUI.templates.padding },
                {
                    template = I.MWUI.templates.box,
                    content = ui.content({
                        {
                            template = I.MWUI.templates.textNormal,
                            props = { text = "Remove" },
                            events = {
                                mouseClick = async:callback(function()
                                    remove(text)
                                    set(value)
                                end),
                            },
                        },
                    }),
                },
            }),
        })
    end

    return {
        type = ui.TYPE.Flex,
        content = ui.content({ header, body }),
    }
end)

I.Settings.registerPage({
    key = MOD_ID,
    l10n = MOD_ID,
    name = "Auto Light Drop v1.2",
    description = "Drop any light quickly when fighting. You can add/remove exception itemIDs (immune to destroy in water) in both AutoLightDropGlobal.lua and physicsenginelocallight.lua file, for now. Made by skrow42",
})

I.Settings.registerGroup({
    key = SETTINGS_KEY,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "Main Settings",
    permanentStorage = true,
    settings = {
        {
            key = "hardcoreMode",
            name = "Hardcore Mode",
            description = "If disabled, the script won't activate throwing out light sources when feet are in water. They can still douse if they roll down to water.",
            default = true,
            renderer = "checkbox",
        },
    },
})

-- Only apply defaults if settings don't exist yet
local function onInit()
    if settings:get("hardcoreMode") == nil then
        settings:set("hardcoreMode", true)
        print(MOD_ID .. ": Initial default settings applied")
    end
end

return { engineHandlers = { onInit = onInit } }
