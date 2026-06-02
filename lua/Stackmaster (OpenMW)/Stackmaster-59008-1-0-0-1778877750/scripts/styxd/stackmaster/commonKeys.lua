-- Unique string keys that need to be referenced in multiple places, etc.
local M = {}

local SEP = '/'
local MOD_NAME = 'StyxdStackmaster'
local ACTIONS_PREFIX = 'Actions'
local SETTINGS_PREFIX = 'Settings'
local BINDINGS_PREFIX = 'Bindings'

local ACTION_DUMP_ALL = 'DumpAll'
local ACTION_PICK_ONE = 'PickOne'

local L10N_NAME = 'name'
local L10N_DESC = 'description'

M.l10n = MOD_NAME

M.actions = {
    DumpAll =  table.concat(
        {ACTIONS_PREFIX, MOD_NAME, ACTION_DUMP_ALL},
        SEP
    ),
    PickOne = table.concat(
        {ACTIONS_PREFIX, MOD_NAME, ACTION_PICK_ONE},
        SEP
    )
}

M.settings = {
    page = {
        key = table.concat({SETTINGS_PREFIX, MOD_NAME}, SEP),
        name = table.concat({SETTINGS_PREFIX, L10N_NAME}, SEP),
        desc = table.concat({SETTINGS_PREFIX, L10N_DESC}, SEP)
    },
    bindings = {
        key = table.concat({SETTINGS_PREFIX, MOD_NAME, BINDINGS_PREFIX}, SEP),
        name = table.concat(
            {SETTINGS_PREFIX, BINDINGS_PREFIX, L10N_NAME},
            SEP
        ),
        DumpAll = {
            key = table.concat(
                {SETTINGS_PREFIX, MOD_NAME, BINDINGS_PREFIX, ACTION_DUMP_ALL},
                SEP
            ),
            name = table.concat(
                {
                    SETTINGS_PREFIX,
                    BINDINGS_PREFIX,
                    ACTION_DUMP_ALL,
                    L10N_NAME
                },
                SEP
            ),
            desc = table.concat(
                {
                    SETTINGS_PREFIX,
                    BINDINGS_PREFIX,
                    ACTION_DUMP_ALL,
                    L10N_DESC
                },
                SEP
            )
        },
        PickOne = {
            key = table.concat(
                {SETTINGS_PREFIX, MOD_NAME, BINDINGS_PREFIX, ACTION_PICK_ONE},
                SEP
            ),
            name = table.concat(
                {
                    SETTINGS_PREFIX,
                    BINDINGS_PREFIX,
                    ACTION_PICK_ONE,
                    L10N_NAME
                },
                SEP
            ),
            desc = table.concat(
                {
                    SETTINGS_PREFIX,
                    BINDINGS_PREFIX,
                    ACTION_PICK_ONE,
                    L10N_DESC
                },
                SEP
            )
        }
    }
}

return M
