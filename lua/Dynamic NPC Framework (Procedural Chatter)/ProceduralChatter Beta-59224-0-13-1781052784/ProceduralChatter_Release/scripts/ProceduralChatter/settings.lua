local I = require("openmw.interfaces")

I.Settings.registerPage({
    key = "ProceduralChatter",
    l10n = "ProceduralChatter",
    name = "Procedural Chatter",
    description = "Configuration for dynamic NPC conversations."
})

I.Settings.registerGroup({
    key = "01_Settings_Chatter_General",
    page = "ProceduralChatter",
    l10n = "ProceduralChatter",
    name = "General Settings",
    permanentStorage = true,
    settings = {
        {
            key = "01_ChatterEnabled",
            renderer = "checkbox",
            name = "Enable Chatter",
            description = "Toggle the entire procedural chatter system.",
            default = true,
        },
        {
            key = "02_AudioEnabled",
            renderer = "checkbox",
            name = "Enable Audio",
            description = "If disabled, conversations will be text-only (using calculated durations). Useful for prototyping.",
            default = true,
        },
        {
            key = "03_SubtitleTextSize",
            renderer = "number",
            name = "Subtitle Text Size",
            description = "Base font size for floating subtitles.",
            default = 18,
            min = 12,
            max = 72,
            integer = true,
        },
        {
            key = "04_SubtitleMode",
            renderer = "select",
            name = "Subtitle Mode",
            description = "How conversation text should be displayed.",
            default = "Floating",
            argument = {
                l10n = "ProceduralChatter",
                items = { "None", "Regular", "Floating", "Both" }
            }
        },

        {
            key = "06_MaxLineLength",
            renderer = "number",
            name = "Max Subtitle Length",
            description = "Maximum characters per subtitle page. Longer text will be split into timed chunks.",
            default = 60,
            min = 10,
            max = 200,
            integer = true,
        },
        {
            key = "07_WalkingArrivalDist",
            renderer = "number",
            name = "Walking Arrival Distance",
            description = "Distance at which walking NPCs should stop to converse.",
            default = 250,
            min = 100,
            max = 500,
            integer = true,
        },
        {
            key = "08_StaticArrivalDist",
            renderer = "number",
            name = "Static Arrival Distance",
            description = "Max distance for two stationary NPCs to converse without moving.",
            default = 250,
            min = 200,
            max = 2000,
            integer = true,
        },
        {
            key = "09_SubtitleFadeStart",
            renderer = "number",
            name = "Subtitle Fade Start Dist",
            description = "Distance at which subtitles begin to fade out.",
            default = 300,
            min = 100,
            integer = true,
        },
        {
            key = "10_SubtitleFadeEnd",
            renderer = "number",
            name = "Subtitle Fade End Dist",
            description = "Distance at which subtitles are fully invisible. (Should be > Fade Start)",
            default = 1000,
            min = 200,
            integer = true,
        },
        {
            key = "11_MinTimer",
            renderer = "number",
            name = "Min Time Between Chats (s)",
            description = "Minimum delay before an NPC can start a new conversation.",
            default = 10,
            min = 1,
            integer = true,
        },
        {
            key = "12_MaxTimer",
            renderer = "number",
            name = "Max Time Between Chats (s)",
            description = "Maximum delay before an NPC can start a new conversation.",
            default = 30,
            min = 5,
            integer = true,
        },
        {
            key = "13_LineRepeatCooldownHours",
            renderer = "number",
            name = "Dialogue Snippet Repeat Cooldown (game hours)",
            description = "In-game hours before the same non-generic snippet line can play again. Applies to smalltalk, rumors, and future snippet categories. Greetings, goodbyes, and generic fallback lines are exempt.",
            default = 24,
            min = 0,
            max = 168,
            integer = true,
        },
        {
            key = "14_EnableDoorSounds",
            renderer = "checkbox",
            name = "Enable Door Transition Sounds",
            description = "Play a door opening/closing sound effect when NPCs pass between cells.",
            default = true,
        },
        {
            key = "15_DoorSoundCooldown",
            renderer = "number",
            name = "Door Sound Cooldown (s)",
            description = "Minimum delay in seconds before a door can play another transition sound.",
            default = 1.0,
            min = 0.1,
            max = 5.0,
        },
        {
            key = "17_ConversationScanRadius",
            renderer = "number",
            name = "Conversation Scan Radius",
            description = "Max distance from the player for NPCs to be considered for conversations.",
            default = 800,
            min = 500,
            max = 5000,
            integer = true,
        },
    }
})

I.Settings.registerGroup({
    key = "03_Settings_Chatter_Debug",
    page = "ProceduralChatter",
    l10n = "ProceduralChatter",
    name = "Experimental Features",
    permanentStorage = true,
    settings = {
        {
            key = "01_SleepEnabled",
            renderer = "checkbox",
            name = "Enable NPC Sleeping",
            description = "Allow NPCs to find beds and sleep. Disable to debug other systems without sleep log noise.",
            default = false,
        },
        {
            key = "02_SittingEnabled",
            renderer = "checkbox",
            name = "Enable NPC Sitting",
            description = "Allow NPCs to find stools and sit down. Disable to debug other systems without sitting log noise.",
            default = false,
        },
        {
            key = "03_ActivitiesEnabled",
            renderer = "checkbox",
            name = "Enable NPC Activities",
            description = "Allow NPCs to perform ambient activities (eating, sweeping, etc.). Disable to isolate conversation or schedule behaviour.",
            default = false,
        },
        {
            key = "04_ScheduleMovementEnabled",
            renderer = "checkbox",
            name = "Enable Schedule Inter-Cell Movement",
            description = "Allow the schedule system to move NPCs between cells. Disable to keep NPCs in their current cells for debugging.",
            default = false,
        },
    }
})

I.Settings.registerGroup({
    key = "02_Settings_Companion_Dialogue",
    page = "ProceduralChatter",
    l10n = "ProceduralChatter",
    name = "Companion Dialogue",
    permanentStorage = true,
    settings = {
        {
            key = "01_CompanionDialogueEnabled",
            renderer = "checkbox",
            name = "Enable Companion Dialogue",
            description = "Allow declared companions to speak custom voiced lines and banter with each other.",
            default = true,
        },
        {
            key = "02_CompanionIntervalMin",
            renderer = "number",
            name = "Random Comment Interval Min (s)",
            description = "Minimum seconds between ambient companion comments or banter.",
            default = 10,
            min = 10,
            max = 300,
            integer = true,
        },
        {
            key = "03_CompanionIntervalMax",
            renderer = "number",
            name = "Random Comment Interval Max (s)",
            description = "Maximum seconds between ambient companion comments or banter.",
            default = 30,
            min = 10,
            max = 600,
            integer = true,
        },
        {
            key = "04_CompanionSubtitleMode",
            renderer = "select",
            name = "Companion Subtitle Mode",
            description = "How companion dialogue text is displayed. 'Both' is recommended since companions may be off-screen.",
            default = "Both",
            argument = {
                l10n = "ProceduralChatter",
                items = { "None", "Regular", "Floating", "Both" }
            }
        },
        {
            key = "05_CompanionRepeatCooldownHours",
            renderer = "number",
            name = "Repeat Cooldown (game hours)",
            description = "In-game hours before the same companion line can play again. Prevents repeats while staying in one place. Persists across saves.",
            default = 48,
            min = 0,
            max = 168,
            integer = true,
        },
    }
})

I.Settings.registerGroup({
    key = "04_Settings_Chatter_Activities",
    page = "ProceduralChatter",
    l10n = "ProceduralChatter",
    name = "Activity Settings",
    permanentStorage = true,
    settings = {
        {
            key = "01_ActivityCooldownMin",
            renderer = "number",
            name = "Activity Cooldown Per NPC (Min Seconds)",
            description = "Minimum time an NPC waits before starting a NEW activity.",
            default = 10,
            min = 5,
            max = 60,
            integer = true,
        },
        {
            key = "02_ActivityCooldownMax",
            renderer = "number",
            name = "Activity Cooldown Per NPC (Max Seconds)",
            description = "Maximum time an NPC waits before starting a NEW activity.",
            default = 30,
            min = 10,
            max = 300,
            integer = true,
        },
    }
})
