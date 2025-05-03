--[[ 
This file is absolutely horrific but it kinda works.
Cobbled together mostly using ChatGPT and some of my own code.
Not at all polished or well-structured.
Proceed if you dare.
]]

local vfs = require("openmw.vfs")

local Parser = {}

Parser.batchSizeMult = 1

Parser.Genre = {
    DEFAULT = 1,
    ELECTRONIC = 2,
    ROCK = 3,
    METAL = 4,
    JAZZ = 5,
    CLASSICAL = 6,
    HIP_HOP = 7,
    FOLK = 8,
    POP = 9,
    COMPLEX = 10
}

-- Helper function to read 4 bytes as a little-endian unsigned int
local function readUInt32LE(handle)
    local b1, b2, b3, b4 = handle:read(4):byte(1, 4)
    if not b4 then return nil end -- Handle incomplete reads
    return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
end

-- Helper function to read 2 bytes as a little-endian unsigned int
local function readUInt16LE(handle)
    local b1, b2 = handle:read(2):byte(1, 2)
    if not b2 then return nil end -- Handle incomplete reads
    return b1 + (b2 * 256)
end

local function getGenreSettings(genre)
    local settings = {
        -- Default values (will be overridden)
        name = "Default",
        lowpassCutoff = 300,
        highpassCutoff = 30,
        bpmRange = {60, 220},
        correlationThreshold = 0.15,
        peakDistance = 0.4,
        downsampleTarget = 1100,
        preferDoubleTempo = false,
        emphasizeLowEnd = false,
        analysisTime = 40,
        description = "Balanced settings for unknown genre"
    }
    
    -- Override with genre-specific settings
    if genre == Parser.Genre.ELECTRONIC then
        settings.name = "Electronic"
        settings.lowpassCutoff = 150
        settings.highpassCutoff = 0
        settings.bpmRange = {70, 200}
        settings.correlationThreshold = 0.3
        settings.peakDistance = 0.5
        settings.preferDoubleTempo = true
        settings.emphasizeLowEnd = true
        settings.description = "Optimized for electronic music with clear kick drums"
    elseif genre == Parser.Genre.ROCK then
        settings.name = "Rock"
        settings.lowpassCutoff = 180
        settings.highpassCutoff = 40
        settings.bpmRange = {60, 190}
        settings.correlationThreshold = 0.2
        settings.emphasizeLowEnd = true
        settings.description = "Balanced settings for rock with focus on drums and bass"
    elseif genre == Parser.Genre.METAL then
        settings.name = "Metal"
        settings.lowpassCutoff = 250
        settings.highpassCutoff = 30
        settings.bpmRange = {80, 220}
        settings.correlationThreshold = 0.15
        settings.peakDistance = 0.3
        settings.downsampleTarget = 1500
        settings.analysisTime = 40
        settings.description = "Tuned for metal's complex rhythms and polyrhythms"
    elseif genre == Parser.Genre.JAZZ then
        settings.name = "Jazz"
        settings.lowpassCutoff = 800
        settings.highpassCutoff = 100
        settings.bpmRange = {40, 300}
        settings.correlationThreshold = 0.1
        settings.peakDistance = 0.3
        settings.downsampleTarget = 1200
        settings.analysisTime = 45
        settings.description = "Settings for jazz with focus on ride cymbal patterns"
    elseif genre == Parser.Genre.CLASSICAL then
        settings.name = "Classical"
        settings.lowpassCutoff = 1000
        settings.highpassCutoff = 50
        settings.bpmRange = {30, 200}
        settings.correlationThreshold = 0.08
        settings.downsampleTarget = 800
        settings.analysisTime = 60
        settings.description = "Optimized for classical music with subtle tempos"
    elseif genre == Parser.Genre.HIP_HOP then
        settings.name = "Hip Hop"
        settings.lowpassCutoff = 200
        settings.highpassCutoff = 0
        settings.bpmRange = {60, 110}
        settings.correlationThreshold = 0.25
        settings.emphasizeLowEnd = true
        settings.analysisTime = 25
        settings.description = "Tuned for hip hop's strong bass and steady beats"
    elseif genre == Parser.Genre.FOLK then
        settings.name = "Folk"
        settings.lowpassCutoff = 500
        settings.highpassCutoff = 80
        settings.bpmRange = {40, 160}
        settings.correlationThreshold = 0.15
        settings.analysisTime = 35
        settings.description = "Settings for folk and acoustic music"
    elseif genre == Parser.Genre.POP then
        settings.name = "Pop"
        settings.lowpassCutoff = 200
        settings.highpassCutoff = 20
        settings.bpmRange = {80, 170}
        settings.correlationThreshold = 0.2
        settings.preferDoubleTempo = true
        settings.emphasizeLowEnd = true
        settings.analysisTime = 25
        settings.description = "Balanced settings for pop music with clear beats"
    elseif genre == Parser.Genre.COMPLEX then
        settings.name = "Complex"
        settings.lowpassCutoff = 3000
        settings.highpassCutoff = 50
        settings.bpmRange = {20, 220}
        settings.correlationThreshold = 0.05
        settings.downsampleTarget = 800
        settings.analysisTime = 60
        settings.description = "Highly lenient settings for swung or syncopated rhythms"
    end
    
    return settings
end

local function parseWavHeader(file)
    local header = {}

    -- Check RIFF header
    local chunkID = file:read(4)
    if not chunkID or chunkID ~= "RIFF" then
        file:close()
        error("Not a valid WAV file (missing RIFF header)")
        return
    end
    
    -- Skip chunk size
    file:read(4)
    
    -- Check format
    local format = file:read(4)
    if not format or format ~= "WAVE" then
        file:close()
        error("Not a valid WAV file (missing WAVE format)")
        return
    end
    
    -- Find "fmt " subchunk
    local subchunkID = file:read(4)
    while subchunkID and subchunkID ~= "fmt " do
        local subchunkSize = readUInt32LE(file)
        if not subchunkSize then
            file:close()
            error("WAV file format error (subchunk size missing)")
            return
        end
        file:seek("cur", subchunkSize)
        subchunkID = file:read(4)
    end
    
    -- Read fmt subchunk
    local subchunkSize = readUInt32LE(file)
    header.audioFormat = readUInt16LE(file)
    header.numChannels = readUInt16LE(file)
    header.sampleRate = readUInt32LE(file)
    header.byteRate = readUInt32LE(file)
    header.blockAlign = readUInt16LE(file)
    header.bitsPerSample = readUInt16LE(file)
    
    -- Skip any extra data in fmt subchunk
    if subchunkSize > 16 then
        file:seek("cur", subchunkSize - 16)
    end
    
    -- Find "data" subchunk
    subchunkID = file:read(4)
    while subchunkID and subchunkID ~= "data" do
        local subchunkSize = readUInt32LE(file)
        file:seek("cur", subchunkSize)
        subchunkID = file:read(4)
    end
    
    -- Read data subchunk size
    header.dataSize = readUInt32LE(file)
    header.dataStart = file:seek()

    return header
end

local function readSamples(file, header, startTime, duration)
    return coroutine.create(function()
        local bytesPerSample = header.bitsPerSample / 8
        local frameSize = header.numChannels * bytesPerSample
        local startFrame = math.floor(startTime * header.sampleRate)
        local numFrames = math.floor(duration * header.sampleRate)
        
        -- Move to the starting position in the file
        file:seek("set", header.dataStart + startFrame * frameSize)
        
        local samples = {}
        local data = file:read(header.dataSize)
        local dataIdx = 1
        
        -- Read frames in batches for efficiency
        local batchSize = 10000 * Parser.batchSizeMult
        local remaining = numFrames
        
        while remaining > 0 do
            local currentBatch = math.min(batchSize, remaining)
            
            for i = 1, currentBatch do
                local frameSum = 0
                local validChannels = 0
                
                -- Read all channels in the frame and average them
                for ch = 1, header.numChannels do
                    local readData = string.sub(data, dataIdx, dataIdx + bytesPerSample - 1)
                    dataIdx = dataIdx + bytesPerSample
                    if not readData or #readData < bytesPerSample then
                        break
                    end
                    
                    local sample = 0
                    
                    if header.bitsPerSample == 8 then
                        -- 8-bit samples are unsigned
                        sample = readData:byte(1) - 128
                    elseif header.bitsPerSample == 16 then
                        -- 16-bit samples are signed little-endian
                        local b1, b2 = readData:byte(1, 2)
                        sample = b1 + (b2 * 256)
                        -- Convert to signed
                        if sample > 32767 then
                            sample = sample - 65536
                        end
                    elseif header.bitsPerSample == 24 then
                        -- 24-bit samples are signed little-endian
                        local b1, b2, b3 = readData:byte(1, 3)
                        sample = b1 + (b2 * 256) + (b3 * 65536)
                        -- Convert to signed
                        if sample > 8388607 then
                            sample = sample - 16777216
                        end
                    elseif header.bitsPerSample == 32 then
                        -- 32-bit samples could be float or int, we assume int here
                        local b1, b2, b3, b4 = readData:byte(1, 4)
                        sample = b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
                        -- Convert to signed
                        if sample > 2147483647 then
                            sample = sample - 4294967296
                        end
                    end
                    
                    frameSum = frameSum + sample
                    validChannels = validChannels + 1
                end
                
                -- Store the average of all channels
                if validChannels > 0 then
                    table.insert(samples, frameSum / validChannels)
                else
                    break  -- Reached end of file
                end
            end
            
            remaining = remaining - currentBatch
            if #samples < numFrames - remaining then
                break  -- End of file reached
            end

            coroutine.yield()
        end

        coroutine.yield(samples)
    end)
end

local function lowPassFilter(samples, cutoffFreq, sampleRate)
    local dt = 1 / sampleRate
    local rc = 1 / (2 * math.pi * cutoffFreq)
    local alpha = dt / (rc + dt)
    
    local filtered = {samples[1]}  -- Start with the first sample
    
    -- Filter in batches for better performance
    local batchSize = 50000 * Parser.batchSizeMult
    for i = 2, #samples, batchSize do
        local endIdx = math.min(i + batchSize - 1, #samples)
        for j = i, endIdx do
            filtered[j] = filtered[j-1] + alpha * (samples[j] - filtered[j-1])
        end
    end
    
    return filtered
end

local function execCoroutine(co, callback)
    local success, result = coroutine.resume(co)
    if not success then
        return false, result
    end
    
    while coroutine.status(co) ~= "dead" do
        success, result = coroutine.resume(co)
        if not success then
            return false, result
        end

        if result ~= nil then
            return true, result
        end
        
        if callback then
            callback(result)
        end
        coroutine.yield()
    end
    
    return false, result
end

-- Apply bandpass filter (combines low and high pass)
local function bandpassFilter(samples, lowpassCutoff, highpassCutoff, sampleRate)
    -- First apply lowpass
    local lowpassed = lowPassFilter(samples, lowpassCutoff, sampleRate)

    -- If no highpass needed, just do lowpass
    if highpassCutoff <= 0 then
        return lowpassed
    end
    
    -- Then apply highpass (implemented as simple IIR filter)
    local dt = 1 / sampleRate
    local rc = 1 / (2 * math.pi * highpassCutoff)
    local alpha = rc / (rc + dt)
    
    local filtered = {lowpassed[1]}
    local prev = lowpassed[1]
    
    for i = 2, #lowpassed do
        filtered[i] = alpha * (filtered[i-1] + lowpassed[i] - prev)
        prev = lowpassed[i]
    end
    
    return filtered
end

local function applyGenreWeighting(samples, settings, sampleRate)
    -- If we should emphasize low end
    if settings.emphasizeLowEnd then
        local cutoff = 100  -- Focus on frequencies below 100Hz
        
        -- Create a simple low-passed version
        local lowEnd = lowPassFilter(samples, cutoff, sampleRate)
        
        -- Blend the original with emphasized low-end
        for i = 1, #samples do
            -- Boosting low frequencies by 50%
            samples[i] = samples[i] + (lowEnd[i] * 0.5)
            --coroutine.yield()
        end
        
        return samples
    end
    
    -- For jazz, emphasize mid-range where ride cymbals live
    if settings.name == "Jazz" then
        -- Band-pass to focus on 500-800Hz
        local midRange = bandpassFilter(samples, 800, 300, sampleRate)
        return midRange
    end
    
    -- No special weighting needed
    return samples
end

local function downsample(samples, factor)
    if factor <= 1 then
        return samples  -- No downsampling needed
    end
    
    local result = {}
    for i = 1, #samples, factor do
        table.insert(result, samples[i])
    end
    
    return result
end

-- Normalize array values to have zero mean and unit variance 
local function normalize(arr)
    -- Calculate mean
    local sum = 0
    for i = 1, #arr do
        sum = sum + arr[i]
    end
    local mean = sum / #arr
    
    -- Calculate variance
    local sumSq = 0
    for i = 1, #arr do
        local diff = arr[i] - mean
        sumSq = sumSq + diff * diff
    end
    local variance = sumSq / #arr
    local stdDev = math.sqrt(variance)
    
    -- Early return if stdDev is too small (avoid division by zero)
    if stdDev < 0.0001 then
        for i = 1, #arr do
            arr[i] = 0
        end
        return arr
    end
    
    -- Normalize in-place to avoid creating a new table
    for i = 1, #arr do
        arr[i] = (arr[i] - mean) / stdDev
    end
    
    return arr
end

local function autocorrelate(samples, maxLag)
        local normalized = normalize(samples)
        normalized = samples
        local n = #normalized
        local result = {}
        
        -- Process in batches to improve performance
        local batchSize = 1000 * Parser.batchSizeMult
        for lag = 0, maxLag, batchSize do
            local endLag = math.min(lag + batchSize - 1, maxLag)
            
            for currLag = lag, endLag do
                local sum = 0
                local count = 0
                
                -- We can skip some samples for large lags to improve performance
                local step = 1
                if currLag > 500 then step = 2 end
                if currLag > 1000 then step = 3 end
                
                for i = 1, n - currLag, step do
                    sum = sum + normalized[i] * normalized[i + currLag]
                    count = count + 1
                end
                
                if count > 0 then
                    result[currLag + 1] = sum / count
                else
                    result[currLag + 1] = 0
                end
            end
        end
        
        return result--normalize(result)
end

--[[
local function normalizeACF(acf)
    if #acf == 0 then return {} end
    
    -- Find the first non-zero lag (skip lag 0 which is always max)
    local firstNonZero = 2
    while firstNonZero <= #acf and acf[firstNonZero] == 0 do
        firstNonZero = firstNonZero + 1
    end
    
    if firstNonZero > #acf then
        -- All zeros except lag 0
        local normalized = {}
        for i = 1, #acf do normalized[i] = 0 end
        normalized[1] = 1 -- lag 0 is always perfect correlation
        return normalized
    end
    
    -- Calculate baseline noise floor (median of later lags)
    local noiseSamples = {}
    local noiseStart = math.floor(#acf * 0.75) -- last 25% of lags
    for i = noiseStart, #acf do
        table.insert(noiseSamples, acf[i])
    end
    
    table.sort(noiseSamples)
    local noiseFloor = noiseSamples[math.floor(#noiseSamples/2)] or 0
    
    -- Normalize: (ACF - noiseFloor) / (peak - noiseFloor)
    local normalized = {}
    local peak = acf[1] -- lag 0 is always the peak
    
    for i = 1, #acf do
        if peak - noiseFloor > 0 then
            normalized[i] = (acf[i] - noiseFloor) / (peak - noiseFloor)
        else
            normalized[i] = 0
        end
        
        -- Clamp between 0 and 1 to handle numerical instability
        normalized[i] = math.max(0, math.min(1, normalized[i]))
    end
    
    -- Apply gentle exponential decay compensation
    local decayCompensation = math.exp(1/#acf)
    for i = firstNonZero, #normalized do
        local decayFactor = math.exp(-(i-1)/#acf) * decayCompensation
        normalized[i] = normalized[i] * decayFactor
    end
    
    return normalized
end

local function enhanceHarmonics(acf)
    local enhanced = {table.unpack(acf)}
    
    -- For each lag position
    for i = 1, #acf do
        -- Add weighted contributions from harmonic positions
        for harmonic = 2, 4 do
            local harmonicPos = i * harmonic
            if harmonicPos <= #acf then
                enhanced[i] = enhanced[i] + (acf[harmonicPos] * 0.5 / harmonic)
            end
        end
        
        -- Also consider subharmonics
        for divisor = 2, 4 do
            local subharmonicPos = math.floor(i / divisor)
            if subharmonicPos >= 1 then
                enhanced[i] = enhanced[i] + (acf[subharmonicPos] * 0.3 / divisor)
            end
        end
    end
    
    return enhanced
end
]]

-- Find peaks in the autocorrelation function (optimized)
local function findPeaks(data, minDistance)
    local peaks = {}
    
    -- Skip the first few elements (self-correlation)
    local startIndex = math.max(3, minDistance)
    
    -- First pass: find local maxima
    for i = startIndex, #data - 1 do
        if data[i] > data[i-1] and data[i] > data[i+1] and data[i] > 0.05 then
            local isPeak = true
            local checkDistance = math.ceil(minDistance / 2)
            
            -- Check if it's the highest peak in vicinity
            for j = math.max(startIndex, i - checkDistance), math.min(#data - 1, i + checkDistance) do
                if j ~= i and data[j] > data[i] then
                    isPeak = false
                    break
                end
            end
            
            if isPeak then
                table.insert(peaks, {
                    position = i,
                    value = data[i]
                })
            end
        end
    end
    
    -- Sort peaks by correlation value (descending)
    table.sort(peaks, function(a, b) return a.value > b.value end)
    
    return peaks
end

--[[
local function smoothPeaks(peaks, acf, smoothingRadius)
    local smoothed = {}
    
    for i = 1, #peaks do
        local peak = peaks[i]
        local startIdx = math.max(1, peak.position - smoothingRadius)
        local endIdx = math.min(#acf, peak.position + smoothingRadius)
        
        local sum = 0
        local count = 0
        
        for j = startIdx, endIdx do
            sum = sum + acf[j]
            count = count + 1
        end
        
        smoothed[i] = {
            position = peak.position,
            value = sum / count
        }
    end
    
    return smoothed
end

local function smoothPeaksAdaptive(peaks, acf, genre, bpmRange)
    if #peaks == 0 then return peaks end
    
    -- Base window size by genre (in samples)
    local genreParams = {
        [Parser.Genre.METAL] = { min=3, max=7, trigger=0.4 },
        [Parser.Genre.ELECTRONIC] = { min=2, max=5, trigger=0.3 },
        [Parser.Genre.JAZZ] = { min=5, max=9, trigger=0.5 },
        [Parser.Genre.CLASSICAL] = { min=7, max=11, trigger=0.6 },
        -- Default for other genres
        default = { min=3, max=7, trigger=0.4 }
    }
    
    local params = genreParams[genre] or genreParams.default
    
    -- Dynamic adjustment based on BPM range width
    local bpmSpread = bpmRange[2] - bpmRange[1]
    local spreadFactor = math.min(1, bpmSpread / 60) -- Normalize to 0-1 range
    local baseWindow = math.floor(params.min + (params.max - params.min) * spreadFactor)
    
    -- Content-aware adjustment
    local avgPeakHeight = 0
    for _, peak in ipairs(peaks) do
        avgPeakHeight = avgPeakHeight + peak.value
    end
    avgPeakHeight = avgPeakHeight / #peaks
    
    -- Smaller window for clear strong peaks, larger for noisy signals
    local clarityFactor = math.min(1, avgPeakHeight / params.trigger)
    local finalWindow = math.floor(baseWindow * (0.5 + 0.5 * clarityFactor))
    
    -- Ensure odd number for symmetric smoothing
    finalWindow = finalWindow % 2 == 0 and finalWindow + 1 or finalWindow
    finalWindow = math.max(3, math.min(finalWindow, 11)) -- Hard limits
    
    -- Apply smoothing with dynamic window
    local smoothed = {}
    local halfWindow = math.floor(finalWindow / 2)
    
    for i = 1, #peaks do
        local sum = 0
        local count = 0
        
        for j = math.max(1, i - halfWindow), math.min(#peaks, i + halfWindow) do
            -- Weight by inverse distance from center peak
            local weight = 1 - (math.abs(i - j) / (halfWindow + 1))
            sum = sum + peaks[j].value * weight
            count = count + weight
        end
        
        if count > 0 then
            table.insert(smoothed, {
                position = peaks[i].position,
                value = sum / count
            })
        else
            table.insert(smoothed, peaks[i])
        end
    end
    
    return smoothed
end
]]

local function boostSimilarCandidates(bpmCandidates, similarityThreshold)
    if #bpmCandidates == 0 then return bpmCandidates end
    
    -- First, sort candidates by correlation if not already sorted
    table.sort(bpmCandidates, function(a, b) return a.correlation > b.correlation end)
    
    -- Find groups of similar BPMs
    local groups = {}
    local currentGroup = {bpmCandidates[1]}
    
    for i = 2, #bpmCandidates do
        local prevBpm = currentGroup[#currentGroup].bpm
        local currBpm = bpmCandidates[i].bpm
        
        -- Check if current BPM is similar to any in group (within threshold %)
        local isSimilar = false
        for _, candidate in ipairs(currentGroup) do
            if math.abs(candidate.bpm - currBpm) <= (candidate.bpm * similarityThreshold / 100) then
                isSimilar = true
                break
            end
        end
        
        if isSimilar then
            table.insert(currentGroup, bpmCandidates[i])
        else
            table.insert(groups, currentGroup)
            currentGroup = {bpmCandidates[i]}
        end
    end
    table.insert(groups, currentGroup) -- Add last group
    
    -- Boost correlations within groups
    for _, group in ipairs(groups) do
        if #group > 1 then
            -- Calculate boost factor based on group size and top candidate strength
            local topCorrelation = group[1].correlation
            local boostFactor = 1 + (0.15 * math.min(3, #group)) * topCorrelation
            
            -- Apply boost while maintaining relative rankings
            for i, candidate in ipairs(group) do
                -- Diminishing boost for lower-ranked candidates
                local rankFactor = 1 + (0.5 / i)
                candidate.correlation = (candidate.correlation + math.min(1, candidate.correlation * boostFactor * rankFactor)) / 2
            end
        end
    end
    
    -- Re-sort all candidates after boosting
    table.sort(bpmCandidates, function(a, b) return a.correlation > b.correlation end)
    
    return bpmCandidates
end

local function detectDottedRatio(topPeaks)
    if #topPeaks < 2 then return false end
    
    -- Sort peaks by position (lag time)
    table.sort(topPeaks, function(a, b) return a.position < b.position end)
    
    -- Check common dotted ratios between top peaks
    for i = 1, math.min(3, #topPeaks) do
        for j = i+1, math.min(5, #topPeaks) do
            local ratio = topPeaks[j].position / topPeaks[i].position
            -- Common dotted rhythm ratios (2:3, 1:1.5, etc.)
            if math.abs(ratio - 1.5) < 0.05 then  -- Within 5% error margin
                return true, topPeaks[i].position
            end
        end
    end
    return false
end

-- Calculate BPM using appropriate settings for the given genre
function Parser.calculateBPMByGenre(fileName, genre, verbose)
    return coroutine.create(function()
        if not genre then genre = Parser.Genre.UNKNOWN end
        local settings = getGenreSettings(genre)

        print("Analyzing file: " .. fileName .. " (Genre: " .. settings.name .. ")")
        
        if not vfs.fileExists(fileName) then
            error("File does not exist: " .. fileName)
        end
        coroutine.yield(false)
        

        if verbose then print(settings.description) end
        
        local file = vfs.open(fileName)
        if not file then
            error("Could not open file: " .. fileName)
        end
        coroutine.yield(false)
        
        local header = parseWavHeader(file)
        coroutine.yield(false)
        
        -- Print header info
        if verbose then print("WAV Info: " .. header.numChannels .. " channels, " .. header.sampleRate .. " Hz, " .. header.bitsPerSample .. " bits") end
        
        -- Calculate total duration in seconds
        local totalDuration = header.dataSize / (header.sampleRate * header.numChannels * (header.bitsPerSample / 8))
        if verbose then print("Duration: " .. string.format("%.2f", totalDuration) .. " seconds") end

        -- Use genre-specific analysis duration
        local analysisDuration = math.min(settings.analysisTime or 40, totalDuration)
        local startTime = 0
        
        -- For longer files, start 30 seconds in to avoid intros (for most genres)
        if totalDuration > 60 and genre ~= Parser.Genre.CLASSICAL and genre ~= Parser.Genre.COMPLEX then
            startTime = 30
            analysisDuration = math.min(settings.analysisTime or 40, totalDuration - startTime)
        end
        
        if verbose then print("Analyzing " .. string.format("%.2f", analysisDuration) .. " seconds from position " .. string.format("%.2f", startTime)) end

        -- Read audio samples
        local success2, samples = execCoroutine(readSamples(file, header, startTime, analysisDuration))
        if not success2 then
            error(samples)
        end
        file:close()
        
        if #samples == 0 then
            error("Failed to read audio samples")
        end
        if verbose then print("Read " .. #samples .. " samples") end
        coroutine.yield(false)
        -- Apply genre-specific filtering
        local filtered = bandpassFilter(samples, settings.lowpassCutoff, settings.highpassCutoff, header.sampleRate)
        coroutine.yield(false)
        -- Apply genre-specific weighting
        local filtered = applyGenreWeighting(filtered, settings, header.sampleRate)
        coroutine.yield(false)
        -- Downsample to reduce computation
        local downsampleFactor = math.floor(header.sampleRate / (settings.downsampleTarget or 1000))
        if downsampleFactor < 1 then downsampleFactor = 1 end
        local downsampled = downsample(filtered, downsampleFactor)
        coroutine.yield(false)
        local effectiveSampleRate = header.sampleRate / downsampleFactor
        -- Calculate valid BPM range in terms of lag samples
        local minBPM = settings.bpmRange[1]
        local maxBPM = settings.bpmRange[2]
        local minLag = math.floor(effectiveSampleRate * 60 / maxBPM)
        local maxLag = math.ceil(effectiveSampleRate * 60 / minBPM)
        -- Ensure maxLag doesn't exceed the number of samples
        maxLag = math.min(maxLag, math.floor(#downsampled / 2))
        
        if verbose then print("Searching for BPM between " .. minBPM .. " and " .. maxBPM) end
        
        -- Apply autocorrelation
        local acf = autocorrelate(downsampled, maxLag)
        --acf = enhanceHarmonics(normalizeACF(acf))
        coroutine.yield(false)
        
        -- Find peaks in the autocorrelation function
        local minPeakDistance = math.floor(minLag * (settings.peakDistance or 0.4))
        if minPeakDistance < 1 then minPeakDistance = 1 end
        
        local peaks = findPeaks(acf, minPeakDistance)
        coroutine.yield(false)
        
        if #peaks == 0 then
            error("No clear beat pattern detected")
        end
        coroutine.yield(false)

        --peaks = smoothPeaksAdaptive(peaks, acf, genre, settings.bpmRange)
        
        -- Determine how many peaks to analyze based on genre complexity
        local maxPeaks = 5
        if genre == Parser.Genre.METAL or genre == Parser.Genre.JAZZ or genre == Parser.Genre.CLASSICAL then
            maxPeaks = 8
        end
        maxPeaks = math.min(maxPeaks, #peaks)
        
        -- Create BPM candidates
        local bpmCandidates = {}
        
        local isDotted, baseLag = detectDottedRatio(peaks)
        for i = 1, maxPeaks do
            local peak = peaks[i]
            local periodSec = peak.position / effectiveSampleRate
            local bpm = 60 / periodSec

            -- Handle dotted rhythm case
            if isDotted and math.abs(bpm - (60/(baseLag/effectiveSampleRate)*1.5)) < 0.1 then
                local correctedBpm = bpm * 1.5
                table.insert(bpmCandidates, {
                    bpm = correctedBpm,
                    correlation = peak.value * 0.9,  -- Slightly reduce confidence
                    correctedFrom = bpm
                })
            end

            -- Check if it's in our expected BPM range
            if bpm >= minBPM and bpm <= maxBPM then
                table.insert(bpmCandidates, {
                    bpm = bpm,
                    correlation = peak.value
                })
                --if verbose then print("BPM candidate: " .. string.format("%.1f", bpm) .. " (correlation: " .. string.format("%.3f", peak.value) .. ")") end
            -- Try multiples/divisors for out-of-range tempos
            elseif bpm < minBPM then
                -- Try doubling, tripling, quadrupling
                for mult = 2, 3, 4 do
                    local adjustedBpm = bpm * mult
                    if adjustedBpm >= minBPM and adjustedBpm <= maxBPM then
                        local confidence = peak.value * 0.8
                        table.insert(bpmCandidates, {
                            bpm = adjustedBpm,
                            correlation = confidence
                        })
                        --[[if verbose then print("BPM candidate (×" .. mult .. "): " .. string.format("%.1f", adjustedBpm) 
                            .. " (correlation: " .. string.format("%.3f", confidence) .. ")") end
                        break]]
                    end
                end
            elseif bpm > maxBPM then
                -- Try halving
                local adjustedBpm = bpm / 2
                if adjustedBpm >= minBPM and adjustedBpm <= maxBPM then
                    local confidence = peak.value * 0.8
                    table.insert(bpmCandidates, {
                        bpm = adjustedBpm,
                        correlation = confidence
                    })
                    --[[if verbose then print("BPM candidate (÷2): " .. string.format("%.1f", adjustedBpm) 
                        .. " (correlation: " .. string.format("%.3f", confidence) .. ")") end]]
                end
            end
        end

        --[[for i = 1, maxPeaks do
            local peak = peaks[i]
            local periodSec = peak.position / effectiveSampleRate
            local bpm = 60 / periodSec
            
            -- Check if it's in our expected BPM range
            if bpm >= minBPM and bpm <= maxBPM then
                table.insert(bpmCandidates, {
                    bpm = bpm,
                    correlation = peak.value
                })
                --if verbose then print("BPM candidate: " .. string.format("%.1f", bpm) .. " (correlation: " .. string.format("%.3f", peak.value) .. ")") end
            -- Try multiples/divisors for out-of-range tempos
            elseif bpm < minBPM then
                -- Try doubling, tripling
                for mult = 2, 3 do
                    local adjustedBpm = bpm * mult
                    if adjustedBpm >= minBPM and adjustedBpm <= maxBPM then
                        local confidence = peak.value * 0.6
                        table.insert(bpmCandidates, {
                            bpm = adjustedBpm,
                            correlation = confidence
                        })
                    end
                end
            elseif bpm > maxBPM then
                -- Try halving
                local adjustedBpm = bpm / 2
                if adjustedBpm >= minBPM and adjustedBpm <= maxBPM then
                    local confidence = peak.value * 0.6
                    table.insert(bpmCandidates, {
                        bpm = adjustedBpm,
                        correlation = confidence
                    })
                end
            end
        end
        ]]
        
        if #bpmCandidates == 0 then
            error("No valid BPM candidates found in the expected range")
        end
        coroutine.yield(false)
        
        -- Apply genre-specific tempo preferences
        
        --[[-- For genres where 2x tempo is often preferred, boost faster tempos
        if settings.preferDoubleTempo and #bpmCandidates >= 2 then
            for i = 1, #bpmCandidates do
                for j = 1, #bpmCandidates do
                    if i ~= j then
                        local ratio = bpmCandidates[i].bpm / bpmCandidates[j].bpm
                        -- If this is approximately double tempo
                        if ratio >= 1.9 and ratio <= 2.1 and bpmCandidates[i].bpm > bpmCandidates[j].bpm then
                            -- Boost the faster tempo's correlation
                            if bpmCandidates[i].correlation >= bpmCandidates[j].correlation * 0.7 then
                                bpmCandidates[i].correlation = bpmCandidates[i].correlation * 2
                            end
                        end
                    end
                end
            end
        end]]

        -- Apply genre-specific tempo range boosts
        if genre == Parser.Genre.METAL then
            -- Boost metal-typical tempos (100-140)
            for i = 1, #bpmCandidates do
                -- Diminish outliers by distance from lower or upper bound
                if bpmCandidates[i].bpm < 100 then
                    bpmCandidates[i].correlation = bpmCandidates[i].correlation * (bpmCandidates[i].bpm / 100)
                elseif bpmCandidates[i].bpm > 140 then
                    bpmCandidates[i].correlation = bpmCandidates[i].correlation * ((240 - bpmCandidates[i].bpm) / 100)
                end
            end
        elseif genre == Parser.Genre.JAZZ then
            -- Boost jazz-typical tempos (120-180)
            for i = 1, #bpmCandidates do
                -- Diminish outliers by distance from lower or upper bound
                if bpmCandidates[i].bpm < 120 then
                    bpmCandidates[i].correlation = bpmCandidates[i].correlation * (bpmCandidates[i].bpm / 120)
                elseif bpmCandidates[i].bpm > 180 then
                    bpmCandidates[i].correlation = bpmCandidates[i].correlation * ((240 - bpmCandidates[i].bpm) / 60)
                end
            end
        end
        
        -- Sort candidates by correlation
        --table.sort(bpmCandidates, function(a, b) return a.correlation > b.correlation end)

        bpmCandidates = boostSimilarCandidates(bpmCandidates, 3)

        if verbose then
            for i = 1, #bpmCandidates do
                print("BPM candidate: " .. string.format("%.3f", bpmCandidates[i].bpm) .. 
                    " (correlation: " .. string.format("%.3f", bpmCandidates[i].correlation) .. ")")
            end
        end
        
        -- Check if top candidate meets minimum correlation threshold
        if bpmCandidates[1].correlation < settings.correlationThreshold then
            print("Warning: Best correlation (" .. string.format("%.3f", bpmCandidates[1].correlation) .. 
                ") is below the threshold (" .. settings.correlationThreshold .. ")")
        end
        
        -- Return the BPM with the highest correlation
        local bpm = math.floor(bpmCandidates[1].bpm + 0.5)
        if verbose then print("Selected BPM: " .. bpm .. " with confidence: " .. string.format("%.1f%%", bpmCandidates[1].correlation * 100)) end
        
        -- Return the BPM and the confidence level
        coroutine.yield(true, bpm, bpmCandidates[1].correlation, totalDuration)
    end)
end

return Parser