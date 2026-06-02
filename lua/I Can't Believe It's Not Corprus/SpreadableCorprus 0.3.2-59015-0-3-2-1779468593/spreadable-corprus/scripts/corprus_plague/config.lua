-- Build a set from a list of record IDs (must already be lowercase).
local function idSet(ids)
    local set = {}
    for _, id in ipairs(ids) do
        set[id] = true
    end
    return set
end

-- Sleepers Awake victims (UESP: Morrowind:Sleepers_Awake) plus Sixth House faction NPCs.
-- The 15 mind-controlled Sleeper record IDs below are also listed in tools/build_dialogue_esp.mjs
-- (SLEEPER_NPC_IDS) for strange-nightmare dialogue; keep both lists in sync when editing.
local sleeperAndHouseNpcIds = {
    -- Sixth House faction (Category:Morrowind-Factions-Sixth House)
    'dreamer prophet',
    'hanarai assutlanipal',
    'zula',
    -- Generic dreamer NPC record used in Sixth House areas
    'dreamer',
    -- Mind-controlled "Sleeper" agents (15 reputation rewards)
    'alvura othrenim',
    'assi serimilk',
    'daynasa telandas',
    'dralas gilu',
    'drarayne girith',
    'dravasa andrethi',
    'endris dilmyn',
    'eralane hledas',
    'llandras belaal',
    'neldris llervu',
    'nelmil hler',
    'rararyn radarys',
    'relur faryon',
    'vireveri darethran',
    'vivyne andrano',
}

return {
    storageSection = 'corprus_plague',

    -- false = core pandemic only (no nightmare, journal, cure, dialogue addon needed).
    enableStory = true,

    carrierSpellId = 'corprus_plague_pandemic',
    carrierSpellName = 'Pandemic',
    carrierEffectId = 'spreadable_corprus_marker',
    carrierEffectName = 'Divine Disease Carrier',
    carrierCuredEffectId = 'spreadable_corprus_marker_cured',
    carrierCuredEffectName = 'Divine Disease Carrier (Cured)',

    -- Story mode only (requires corprus_plague_dialogue.omwaddon for journal text).
    -- Journal console test: journal cp_carrier 10
    carrierJournalId = 'cp_carrier',
    carrierJournalNightmareStage = 10,
    carrierJournalCureStage = 100,

    -- Story mode only: vanilla main quest update when Dagoth Ur is defeated.
    cureQuestId = 'C3_DestroyDagoth',
    cureQuestStage = 50,
    cureMessage = "Dagoth Ur is no more, and the Heart's beating comes to a stop, and with it, the vessel of his vengeance is cleansed. Breathe deep, for every breath is a new victory for Morrowind's Incarnate.",

    -- Show "#{sKilledEssential}" when an essential NPC morphs (same text as vanilla death).
    showProphecyOnEssentialMorph = true,
    essentialDeathGmst = 'sKilledEssential',

    settingsPageKey = 'CorprusPlague',
    settingsGroupKey = 'SettingsCorprusPlague',
    defaultIncubationDays = 7,
    minIncubationDays = 1,
    maxIncubationDays = 21,

    defaultDispositionModifier = 0.5,
    minDispositionModifier = 0,
    maxDispositionModifier = 2,
    dispositionModifierStep = 0.1,

    -- Set true for ONE load to wipe bad infection/transform records from earlier tests, then set false.
    clearPlagueDataOnLoad = false,

    -- Story mode debug — first-rest nightmare (see scripts/corprus_plague/first_rest_dream*.lua).
    debugFirstRestDream = false, -- openmw.log + optional in-game toasts; F9 forces encounter indoors
    debugIgnoreFirstRestDreamSave = false, -- allow re-trigger on the same save
    debugTriggerDreamOnLoad = false, -- fire nightmare immediately on load

    -- Story mode debug — carrier cure (Dagoth Ur). See DEVELOPING.md.
    debugCure = false, -- log cure flow to openmw.log ([corprus_plague] cure: …)
    debugForceCurePendingOnLoad = false, -- set curePending on every load (smoke-test load retry)
    debugSkipCureApplication = false, -- accept cure events but do not mark cured (fail-state test)

    -- How often to check active NPCs for transformation (seconds of simulation time).
    transformScanInterval = 5,

    spawnVfxMagicEffectIds = { 'corprus', 'blightdisease' },
    spawnVfxId = 'spreadable_corprus_spawn_vfx',

    -- NPC morph targets after incubation. List of { id = '<creature_record_id>', weight = N }.
    -- Weights are relative (70/30 and 7/3 behave the same). Restart OpenMW after edits.
    -- Creature IDs must exist in loaded content (vanilla or other plugins).
    transformCreatures = {
        { id = 'corprus_stalker', weight = 70 },
        { id = 'corprus_lame', weight = 30 },
    },

    -- Only the living god form, not other Vivec-related NPCs.
    immuneRecordIds = idSet({
        'vivec_god',
        'yagrum bagarn',
    }),

    -- Faction membership checked at runtime via types.NPC.getFactions.
    immuneFactions = idSet({
        'sixth house',
    }),

    -- Dreamer-class cultists and named sleepers (see list above).
    immuneClasses = idSet({
        'dreamer',
    }),

    immuneSleeperRecordIds = idSet(sleeperAndHouseNpcIds),
}
