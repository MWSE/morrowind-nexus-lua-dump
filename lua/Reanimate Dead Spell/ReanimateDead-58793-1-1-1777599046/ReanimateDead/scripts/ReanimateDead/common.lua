-- Shared identifiers used across LOAD/GLOBAL/PLAYER/CUSTOM scripts.
-- Centralized here so a typo can't desynchronize sender/handler event
-- names, or settings registration keys from settings reads.

local M = {}

M.L10N = 'ReanimateDead'

M.SPELL_ID = 'spell_reanimate_dead'
M.EFFECT_ID = 'reanimatedead'
M.MINION_SCRIPT = 'scripts/ReanimateDead/minion.lua'

M.SETTINGS = {
    PAGE = 'ReanimateDead',
    SECTION_SPELL = 'SettingsReanimateDeadSpell',
    SECTION_BEHAVIOR = 'SettingsReanimateDeadBehavior',
    SECTION_EFFECTS = 'SettingsReanimateDeadEffects',
}

M.EVENTS = {
    CAST = 'ReanimateDead_Cast',
    TRANSFER_INVENTORY = 'ReanimateDead_TransferInventory',
    SHOW_REJECTION = 'ReanimateDead_ShowRejection',
    SHOW_EXPEL_MESSAGE = 'ReanimateDead_ShowExpelMessage',
    SPAWN_CONSIDERED_VFX = 'ReanimateDead_SpawnConsideredVfx',
}

M.VFX = {
    SUMMON_START = 'VFX_Summon_Start',
    SUMMON_END = 'VFX_Summon_End',
    PARTICLE_TEXTURE = 'vfx_conj_flare02.tga',
}

M.L10N_KEYS = {
    NO_CORPSES_NEARBY = 'no_corpses_nearby',
    NO_EFFECT_DAEDRA = 'no_effect_daedra',
    NO_EFFECT_UNDEAD = 'no_effect_undead',
    NO_EFFECT_MINION = 'no_effect_minion',
    NO_EFFECT_TOO_POWERFUL = 'no_effect_too_powerful',
    RISEN_NAME_PREFIX = 'risen_name_prefix',
}

return M
