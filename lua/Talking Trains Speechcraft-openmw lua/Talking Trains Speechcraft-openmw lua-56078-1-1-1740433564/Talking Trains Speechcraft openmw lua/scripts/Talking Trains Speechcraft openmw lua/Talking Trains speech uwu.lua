I = require('openmw.interfaces')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local Player = require('openmw.types').Player
local storage = require('openmw.storage')
local ui = require('openmw.ui')

-- Persistent storage for settings
local settings = storage.playerSection("SettingsTalkingTrainsSpeech")

-- Table to track NPCs we've spoken to
local spokenNPCs = {}
local doonce = false

-- Mod info
local MOD_NAME = "TalkingTrainsSpeech"
local MOD_VERSION = "1.1"
local pageDescription = "By [Mistersmellies]\nv" .. MOD_VERSION .. "\n\nAdjust Speechcraft progression gains for dialogue interactions with NPCs."

-- Function to determine progress gain based on NPC interaction history
local function getProgressGain(npcId)
    local initialGainPercent = settings:get("initialDialogueGain") or 2  -- Default 2%
    local subsequentGainPercent = settings:get("subsequentDialogueGain") or 1  -- Default 1%
    if not spokenNPCs[npcId] or not spokenNPCs[npcId].spokenTo then
        return initialGainPercent / 100  -- Convert % to progress (e.g., 2 → 0.02)
    else
        return subsequentGainPercent / 100  -- Convert % to progress (e.g., 1 → 0.01)
    end
end

-- Function to mark an NPC as spoken to
local function markNPCSpoken(npcId)
    if not spokenNPCs[npcId] then
        spokenNPCs[npcId] = { spokenTo = true }
    else
        spokenNPCs[npcId].spokenTo = true
    end
    print("Marked NPC as spoken: " .. npcId)
end

-- Register the settings page
I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "Talking Trains Speech",
    description = pageDescription
}

-- Register the settings group with integer percentage sliders
I.Settings.registerGroup {
    key = "SettingsTalkingTrainsSpeech",
    page = MOD_NAME,
    l10n = MOD_NAME,
    name = "Speechcraft Progression Settings",
    permanentStorage = false,
    settings = {
        {
            key = "initialDialogueGain",
            renderer = "number",
            argument = {
                min = 0,
                max = 100,  -- Whole numbers 0 to 100
                integer = true  -- Only whole numbers
            },
            name = "Initial Dialogue Gain (%)",
            description = "Progression gain for the first dialogue with an NPC (0-100%).",
            default = 2  -- 2% = 0.02
        },
        {
            key = "subsequentDialogueGain",
            renderer = "number",
            argument = {
                min = 0,
                max = 100,  -- Whole numbers 0 to 100
                integer = true  -- Only whole numbers
            },
            name = "Subsequent Dialogue Gain (%)",
            description = "Progression gain for subsequent dialogues with the same NPC (0-100%).",
            default = 1  -- 1% = 0.01
        }
    }
}

-- Main dialogue event handler
return {
    engineHandlers = {
        onSave = function()
            return {
                spokenNPCs = spokenNPCs,
                doonce = doonce,
                scriptVersion = 1
            }
        end,

        onLoad = function(data)
            if data then
                spokenNPCs = data.spokenNPCs or {}
                doonce = data.doonce or false
                print("Loaded spokenNPCs: " .. #spokenNPCs .. " entries")
            end
        end,

        onInit = function()
            print("[" .. MOD_NAME .. "] Initialized v" .. MOD_VERSION)
        end
    },  -- No trailing comma here
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == 'Dialogue' and data.oldMode == nil and not doonce then
                -- Access Speechcraft skill for the player
                local speechcraft = Player.stats.skills.speechcraft(self)
                local currentProgress = speechcraft.progress

                -- Get the NPC from data.arg
                local npc = data.arg
                if not npc or npc.type ~= types.NPC then
                    print("No valid NPC in dialogue; skipping progress update")
                    return
                end
                local npcId = npc.id

                -- Determine progress gain based on NPC history
                local progressGain = getProgressGain(npcId)
                local newProgress = currentProgress + progressGain

                print("Before: Base = " .. speechcraft.base .. ", Progress = " .. currentProgress .. ", NPC = " .. npcId .. ", Gain = " .. progressGain)

                -- Apply the new progress
                speechcraft.progress = newProgress

                print("After Progress Update: Base = " .. speechcraft.base .. ", Progress = " .. speechcraft.progress)

                -- Trigger level-up if we cross 1.0
                if currentProgress < 1.0 and newProgress >= 1.0 then
                    I.SkillProgression.skillLevelUp("speechcraft")
                    speechcraft.progress = 0
                    print("Level Up Triggered: Base = " .. speechcraft.base .. ", Progress = " .. speechcraft.progress)
                end

                -- Mark NPC as spoken to if first time
                if progressGain == ((settings:get("initialDialogueGain") or 2) / 100) then
                    markNPCSpoken(npcId)
                end

                print("Final: Base = " .. speechcraft.base .. ", Progress = " .. speechcraft.progress)

                doonce = true
            elseif data.newMode == nil and data.oldMode == 'Dialogue' and doonce then
                doonce = false
            end
        end
    }
}