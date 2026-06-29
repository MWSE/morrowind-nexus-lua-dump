local VoiceManager = {}
local vfs = require("openmw.vfs")

-- Configuration for voice paths
local BasePath = "Sound/Vo"

-- Silent placeholder audio files for text-only / no-asset installations.
-- core.sound.say needs an audio file to trigger engine subtitles;
-- these let us show subtitles even when no voice assets are present.
local SILENCE_DURATIONS = {2, 4, 6, 8, 10, 12, 14, 16, 18, 20}
local SILENCE_BASE_PATH = "Sound/Vo/ProceduralChatter/Silence/silent_"

local function getSilenceFile(duration)
    local best = SILENCE_DURATIONS[1]
    local bestDiff = math.abs(best - duration)
    for _, d in ipairs(SILENCE_DURATIONS) do
        local diff = math.abs(d - duration)
        if diff < bestDiff then
            best = d
            bestDiff = diff
        end
    end
    local path = SILENCE_BASE_PATH .. string.format("%02d", best) .. ".mp3"
    if vfs.fileExists(path) then
        return path
    end
    return nil
end


local types = require("openmw.types")

local core = require("openmw.core")
local self = require("openmw.self")
local VoiceDataLoader = require("scripts.ProceduralChatter.VoiceDataLoader")
local VoiceData = VoiceDataLoader.getVoiceData()

-- Load race-to-voice bindings so modded races can reuse existing voice sets.
local RaceBindings = {}
local function loadRaceBindings()
    local json = require("scripts.ProceduralChatter.lib.json")
    local path = "scripts/ProceduralChatter/data/Dialogue/VoiceRaceBindings.json"
    local ok, stream = pcall(vfs.open, path)
    if not ok or not stream then
        print("[VoiceManager] No VoiceRaceBindings.json found; using built-in races only.")
        return
    end
    local chunks = {}
    local readOk = pcall(function()
        for line in stream:lines() do
            chunks[#chunks + 1] = line .. "\n"
        end
    end)
    pcall(function() stream:close() end)
    if not readOk or #chunks == 0 then
        print("[VoiceManager] VoiceRaceBindings.json empty or unreadable.")
        return
    end
    local text = table.concat(chunks)
    local decodeOk, data = pcall(json.decode, text)
    if decodeOk and type(data) == "table" then
        RaceBindings = data
        local count = 0
        for _ in pairs(RaceBindings) do count = count + 1 end
        print(string.format("[VoiceManager] Loaded %d race voice bindings.", count))
    else
        print("[VoiceManager] Failed to parse VoiceRaceBindings.json.")
    end
end
loadRaceBindings()

local function normalizeRace(race)
    if not race or race == "" then
        return ""
    end
    return string.lower(tostring(race)):gsub("%s+", "")
end

local function getMappedRace(race)
    local normalized = normalizeRace(race)
    if normalized == "" then
        return ""
    end
    -- If the race already exists in voice data, use it directly.
    if VoiceData[normalized] then
        return normalized
    end
    -- Otherwise check the binding map.
    local bound = RaceBindings[normalized]
    if bound then
        local mapped = normalizeRace(bound)
        if mapped ~= "" and VoiceData[mapped] then
            return mapped
        end
    end
    -- Try suffix stripping for prefixed races (e.g. t_sky_reachman -> reachman)
    local parts = {}
    for part in string.gmatch(normalized, "[^_]+") do
        table.insert(parts, part)
    end
    if #parts > 1 then
        for i = 2, #parts do
            local suffix = table.concat(parts, "_", i)
            if VoiceData[suffix] then
                return suffix
            end
            if RaceBindings[suffix] then
                local mapped = normalizeRace(RaceBindings[suffix])
                if mapped ~= "" and VoiceData[mapped] then
                    return mapped
                end
            end
        end
    end
    return normalized
end

function VoiceManager.resolvePath(npc, audioId)
    if not audioId then return nil end
    
    local record = types.NPC.record(npc)
    local race = getMappedRace(record.race)
    if race == "" then
        print(string.format("[ProceduralChatter] Warning: NPC has no race; cannot resolve voice path for '%s'", tostring(audioId)))
        return nil
    end
    local gender = record.isMale and "m" or "f"
    
    -- Construct Path: Sound/Vo/ProceduralChatter/[Race]/[Gender]/[ID].mp3
    -- Note: Race names might need normalization (e.g., "Dark Elf" -> "darkelf")
    -- For now, simple lower case.
    
    local path_mp3 = string.format("%s/ProceduralChatter/%s/%s/%s.mp3", BasePath, race, gender, audioId)
    local path_wav = string.format("%s/ProceduralChatter/%s/%s/%s.wav", BasePath, race, gender, audioId)
    
    if vfs.fileExists(path_mp3) then
        return path_mp3
    elseif vfs.fileExists(path_wav) then
        return path_wav
    end
    
    -- Fallback: Dynamic Conversations compatibility directory
    local dc_mp3 = string.format("%s/ProceduralChatter_DC/%s/%s/%s.mp3", BasePath, race, gender, audioId)
    local dc_wav = string.format("%s/ProceduralChatter_DC/%s/%s/%s.wav", BasePath, race, gender, audioId)
    
    if vfs.fileExists(dc_mp3) then
        return dc_mp3
    elseif vfs.fileExists(dc_wav) then
        return dc_wav
    end
    
    print(string.format("[ProceduralChatter] Warning: Voice file missing: %s (.mp3/.wav)", path_mp3))
    return nil
end

function VoiceManager.getDuration(npc, audioId, text)
    if not audioId then return 0 end
    
    local record = types.NPC.record(npc)
    local race = getMappedRace(record.race)
    if race == "" then
        -- Unknown/unmappable race: estimate from text or return a safe fallback.
        if text then
            local estimated = (#text * 0.085) + 0.5
            print(string.format("[ProceduralChatter] Fallback duration (no race): %.2fs (Len: %d)", estimated, #text))
            return estimated
        end
        return 3.0
    end
    local gender = record.isMale and "m" or "f"
    
    -- Debug Lookup
    -- print(string.format("[DEBUG] VoiceLookup: Race='%s' Gender='%s' ID='%s'", race, gender, audioId))

    if VoiceData[race] and VoiceData[race][gender] and VoiceData[race][gender][audioId] then
        local duration = VoiceData[race][gender][audioId]
        -- Safety Multiplier Removed as per user request (Timer fixed)
        print(string.format("[DEBUG] VoiceManager found duration for %s (%s/%s): %.3fs", audioId, race, gender, duration))
        return duration
    end
    
    print(string.format("[ProceduralChatter] WARNING: Duration MISSING for '%s' (Race: '%s', Gender: '%s')", audioId, tostring(race), tostring(gender)))
    
    if not VoiceData[race] then 
        print(string.format("DEBUG: VoiceData['%s'] is NIL. Available races:", race))
        local raceList = {}
        for k, _ in pairs(VoiceData) do table.insert(raceList, k) end
        print(table.concat(raceList, ", "))
    elseif not VoiceData[race][gender] then
        print(string.format("DEBUG: VoiceData['%s']['%s'] is NIL.", race, gender))
    else
        print(string.format("DEBUG: Entry missing in VoiceData['%s']['%s']. Checking simplified ID match...", race, gender))
        -- Optional: Check if the ID exists but maybe with slight casing diff (though Lua keys are case sensitive and should match)
    end

    -- Fallback: Estimate based on text length if provided
    if text then
        -- Derived from actual MP3 averages: ~0.074s/char + 15% leeway = 0.085s/char + 0.5s base padding
        local estimated = (#text * 0.085) + 0.5
        print(string.format("[ProceduralChatter] Fallback duration: %.2fs (Len: %d)", estimated, #text))
        return estimated
    end
    
    return 3.0 -- Increased Hard fallback
end

local storage = require("openmw.storage")
-- require("scripts.ProceduralChatter.settings") -- Removed to prevent double registration
local settingsGeneral = storage.playerSection("01_Settings_Chatter_General")

function VoiceManager.playVoice(npc, text, race, gender, audioId)
    local audioEnabled = settingsGeneral:get("02_AudioEnabled")
    local path = nil
    
    -- Only resolve path if Audio is enabled
    if audioEnabled ~= false then -- Default true
        path = VoiceManager.resolvePath(npc, audioId)
    end
    
    local duration = VoiceManager.getDuration(npc, audioId, text)
    
    local mode = settingsGeneral:get("04_SubtitleMode") -- "None", "Regular", "Floating", "Both"
    
    -- Handle Floating Text (Always works if enabled, regardless of audio)
    if mode == "Floating" or mode == "Both" then
        self:sendEvent("ProceduralChatter_ShowSubtitle", {
            actor = npc,
            text = text,
            duration = duration
        })
    end
    
    -- Handle Audio & Standard Subtitles
    local subtitleText = text
    if mode == "Floating" or mode == "None" then
        subtitleText = "" -- Suppress standard subtitle
    end
    
    local fileToPlay = nil
    if path then
        fileToPlay = path
    elseif mode == "Regular" or mode == "Both" then
        -- No real audio available, but engine subtitles are requested.
        -- Use a silent placeholder so core.sound.say still triggers subtitles.
        fileToPlay = getSilenceFile(duration)
    end

    if fileToPlay then
        npc:sendEvent("PC_Say", { file = fileToPlay, text = subtitleText })
    elseif mode == "Regular" or mode == "Both" then
        print("[ProceduralChatter] Text-Only Mode: Standard subtitles skipped (Requires Audio). Use Floating Subtitles.")
    end
end

return VoiceManager
