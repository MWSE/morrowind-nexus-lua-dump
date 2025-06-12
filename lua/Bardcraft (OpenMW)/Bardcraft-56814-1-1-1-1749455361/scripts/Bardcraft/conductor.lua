local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local storage = require('openmw.storage')
local util = require('openmw.util')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')

local Song = require('scripts.Bardcraft.util.song').Song
local Cell = require('scripts.Bardcraft.cell')
local Feedback = require('scripts.Bardcraft.feedback')
local instrumentItems = require('scripts.Bardcraft.data').InstrumentItems
local configGlobal = require('scripts.Bardcraft.config.global')

local l10n = core.l10n('Bardcraft')

local playing = false
local song = nil
local performers = {}
local partToPerformer = {}

local performance = {
    noteEvents = {},
    quality = 0,
    density = 0,
    complexity = 0,
    time = 0,
}
local performanceEvalTimer = 0
local performanceEvalInterval = 1.0 -- seconds

local performanceRandomEventInterval = { 3.0, 5.0 }
local performanceRandomEventTimer = performanceRandomEventInterval[1]

local logAwait = nil

local infiniteLuteRelease = false

local function resyncActor(performer)
    local part = performer.part
    local instrumentName = Song.getInstrumentProfile(part.instrument).name
    performer.actor:sendEvent('BO_ConductorEvent', { type = 'PerformStart', time = song:ticksToSeconds(song.playbackTickCurr), realTime = core.getRealTime(), instrument = instrumentName, song = song, part = part, perfType = performance.type, item = performer.item })
end

local function resyncAllActors()
    for _, performerData in ipairs(performers) do
        resyncActor(performerData)
    end
end

local function start(data)
    if not song then return end
    print("Starting performance (" .. song.title .. ")")
    playing = true

    partToPerformer = {}
    for _, performerData in ipairs(performers) do
        local partIndex = performerData.part.index
        if not partToPerformer[partIndex] then
            partToPerformer[partIndex] = {}
        end
        table.insert(partToPerformer[partIndex], performerData.actor)
    end

    song.loopCount = (data.type == Song.PerformanceType.Street or data.type == Song.PerformanceType.Ambient) and 1e10 or song.loopTimes
    performance.noteEvents = {}
    performance.quality = 0
    performance.density = 0
    performance.complexity = 0
    performance.time = 0
    performance.type = data.type
    performance.streetName = data.streetName
    performance.streetType = data.streetType
    performance.cell = world.players[1].cell
    performance.startGameTime = core.getGameTime()
    performance.songName = song.title
    performance.tips = 0
    performanceEvalTimer = 0
    performanceRandomEventTimer = performanceRandomEventInterval[1]

    infiniteLuteRelease = configGlobal.options.bInfiniteLuteRelease

    resyncAllActors()
end

local function payPlayer(player, gold, message, sfx)
    if gold > 0 then
        if player then
            local item = world.createObject('gold_001', gold or 1)
            item:moveInto(types.Actor.inventory(player))
            if message then
                player:sendEvent('BC_PerformanceEvent', { type = 'Gold', amount = gold, message = message, sound = sfx })
            end
        end
    end
end

local function isPerforming(actorId)
    for _, performerData in ipairs(performers) do
        if performerData.actor.id == actorId then
            return true
        end
    end
    return false
end

local function getRandomLocalizedLine(prefix)
	local lines = {}
	local i = 1
	while true do
		local key = prefix .. '_' .. i
		local localized = l10n(key)
		if localized == key then
			break -- We've reached the end of the list
		end
		table.insert(lines, key)
		i = i + 1
	end
	if #lines == 0 then
        return nil
	end
	return lines[math.random(#lines)]
end

local function getStatFactor()
    local player = world.players[1]
    if player then
        local speechcraftFactor = (types.NPC.stats.skills.speechcraft(player).modified - 50) / 50 * 0.125
        local personalityFactor = (types.Actor.stats.attributes.personality(player).modified - 50) / 50 * 0.25
        return speechcraftFactor + personalityFactor
    end
    return 0
end

local function getQualityFactor(statFactor)
    if not performance then return 0 end
    local minQualityModifier = 30 * (1 - statFactor)
    local minPerfQualityToPay = util.clamp(minQualityModifier, 16, 99)
    local scaledQuality = math.pow(performance.quality / 100, 2) * 100
    local qualityFactor = util.clamp((scaledQuality - minPerfQualityToPay) / (100 - minPerfQualityToPay), 0, 1)
    return qualityFactor
end

local getImpressivenessFactor = function()
    if not performance then return 0 end
    return math.min(1, performance.density / 10)
end

local function getBasePayAmount()
    if not performance then return 0 end
    local player = world.players[1]
    if player then
        local payment = 0
        local statSumFactor = getStatFactor()
        local qualityFactor = getQualityFactor(statSumFactor)
        local impressivenessFactor = math.pow(getImpressivenessFactor(), 1.5)
        local payScale = math.max(0, 1 + statSumFactor)
        local timeScale = math.min(performance.time / 60, 3)
        -- Base: A maximum impressiveness song (density > 10) with a 100% quality should reward 250 gold
        local basePayment = 250 * impressivenessFactor * qualityFactor
        payment = math.max(0, math.floor(basePayment * payScale * timeScale))
        payment = math.floor(payment * (1 + math.random() * 0.1))
        return payment
    end
    return 0
end

local function stop()
    if song then
        song:resetPlayback()
    end
    playing = false
    for _, performerData in ipairs(performers) do
        performerData.actor:sendEvent('BO_ConductorEvent', { type = 'PerformStop', completion = song and (performance.time / song:lengthInSeconds()) or 0, cell = performance.streetName or performance.cell.name, startTime = performance.startGameTime, })
    end

    if performance.type == Song.PerformanceType.Practice or performance.type == Song.PerformanceType.Ambient then
        return
    end

    local performanceLog = {
        type = performance.type,
        quality = performance.quality,
        density = performance.density,
        complexity = performance.complexity,
        time = performance.time,
        cell = performance.streetName or performance.cell.name,
        tips = performance.tips,
        gameTime = performance.startGameTime,
        songName = performance.songName,
    }

    local player = world.players[1]
    if player then
        local timeScale = math.min(performance.time / 60, 2)
        local statSumFactor = getStatFactor()
        local impressiveness = getImpressivenessFactor()

        -- Calculate rep gain/loss
        local rep = 0
        local gainRepMin = 50
        local loseRepMax = 29
        if performance.quality >= gainRepMin then
            -- Gain rep: Interpolation between 0 rep at gainRepMin and (.1 + impressiveness * 1.9) rep at 100 quality
            local qualityRange = 100 - gainRepMin
            if qualityRange > 0 then
                local normalizedQuality = (performance.quality - gainRepMin) / qualityRange
                local maxRepGain = 0.1 + impressiveness * 1.9
                rep = normalizedQuality * maxRepGain
            elseif performance.quality == 100 then -- Handle edge case where gainRepMin is 100
                rep = 0.1 + impressiveness * 1.9
            end
            rep = math.max(0, rep + statSumFactor)
        elseif performance.quality <= loseRepMax then
            -- Lose rep: Interpolation between (-3 + impressiveness * 2) rep at 0 quality and 0 rep at loseRepMax
            if loseRepMax > 0 then
                local normalizedQuality = performance.quality / loseRepMax
                local minRepLoss = -3 + impressiveness * 2
                local repRange = 0 - minRepLoss -- = 3 - impressiveness * 2
                rep = minRepLoss + normalizedQuality * repRange
            elseif performance.quality == 0 then -- Handle edge case where loseRepMax is 0 or less
                rep = -3 + impressiveness * 2
            end
            rep = math.min(0, rep + statSumFactor * 0.5)
        end

        if performance.type == Song.PerformanceType.Tavern then
            local publican = Cell.getPublican(performance.cell)
            local context = {
                perfQuality = performance.quality,
                perfDensity = performance.density,
                race = publican and types.NPC.record(publican).race or '',
                length = performance.time,
            }
            local feedbackTree = storage.globalSection('Bardcraft'):getCopy('feedback')
            if feedbackTree then
                local publicanFeedback = Feedback.findMatchingNode(feedbackTree.publican, context)
                if publicanFeedback then
                    local choice = getRandomLocalizedLine(publicanFeedback.prefix)
                    local effects = publicanFeedback.effects

                    performanceLog.publicanComment = choice
                    performanceLog.effects = effects
                end

                local patronFeedback = {}
                local activeActorsCopy = {}
                for _, actor in ipairs(world.activeActors) do
                    table.insert(activeActorsCopy, actor)
                end

                -- Shuffle the copied table (Fisher-Yates shuffle)
                for i = #activeActorsCopy, 2, -1 do
                    local j = math.random(i)
                    activeActorsCopy[i], activeActorsCopy[j] = activeActorsCopy[j], activeActorsCopy[i]
                end

                for _, actor in ipairs(activeActorsCopy) do
                    if actor.type == types.NPC and actor.cell == performance.cell and (not publican or actor.id ~= publican.id) and not isPerforming(actor.id) then
                        local record = types.NPC.record(actor)
                        local context = {
                            perfQuality = performance.quality,
                            perfDensity = performance.density,
                            race = record.race,
                        }
                        local feedback = Feedback.findMatchingNode(feedbackTree.patron, context)
                        if feedback then
                            local choice = getRandomLocalizedLine(feedback.prefix)
                            if choice then
                                -- Check if comment was already made by another NPC
                                local alreadySaid = false
                                for _, existingFeedback in ipairs(patronFeedback) do
                                    if existingFeedback.comment == choice then
                                        alreadySaid = true
                                        break
                                    end
                                end
                                if not alreadySaid then
                                    -- Add the comment to the list of patron feedback
                                    table.insert(patronFeedback, {
                                        name = record.name,
                                        comment = choice,
                                    })
                                end
                            end
                        end
                    end
                end
                -- Pick at most 3 patron comments
                if #patronFeedback > 3 then
                    local diff = #patronFeedback - 3
                    for _ = 1, diff do
                        table.remove(patronFeedback, math.random(1, #patronFeedback))
                    end
                end
                if #patronFeedback > 0 then
                    performanceLog.patronComments = patronFeedback
                end
            end

            local kickOut = (performanceLog.effects and performanceLog.effects.kickPlayer) or performance.quality < 15 and performance.time >= 10

            -- Calculate how much the publican pays
            local payment = 0
            if not kickOut then
                payment = getBasePayAmount() * configGlobal.options.fOverallGoldMult * configGlobal.options.fTavernGoldMult
            end

            -- Calculate publican disposition change
            local dispositionChange = 0
            -- Base neutral point for disposition change (0-100 quality scale)
            local baseNeutralDispositionQuality = 40
            -- Stat factor can shift this neutral point by up to +/- 15
            -- Max positive statSumFactor (0.125 + 0.25 = 0.375) shifts neutral point down (easier to gain)
            -- Max negative statSumFactor (-0.375) shifts neutral point up (harder to gain)
            local neutralDispositionQuality = baseNeutralDispositionQuality - (statSumFactor / 0.375 * 15)
            neutralDispositionQuality = util.clamp(neutralDispositionQuality, 25, 55) -- Keep it within a reasonable range

            local gainDispMin = neutralDispositionQuality
            local loseDispMax = neutralDispositionQuality - 1 -- Ensure a gap or direct transition

            if performance.quality >= gainDispMin then
                -- Gain disposition
                local qualityRange = 100 - gainDispMin
                if qualityRange > 0 then
                    local normalizedQuality = (performance.quality - gainDispMin) / qualityRange
                    -- Max disposition gain: 50 base + 25 from impressiveness
                    local maxDispGainBase = 50
                    local maxDispGainFromImpressiveness = 25 * impressiveness
                    local maxDispGainTotal = maxDispGainBase + maxDispGainFromImpressiveness
                    dispositionChange = normalizedQuality * maxDispGainTotal
                elseif performance.quality == 100 then -- Edge case: gainDispMin is 100
                    dispositionChange = 50 + 25 * impressiveness
                end
                -- Apply stat factor: max positive statSumFactor (0.375) adds up to ~18.75 to the gain
                -- This is an additional bonus on top of the impressiveness and quality scaling
                dispositionChange = dispositionChange * (1 + statSumFactor * 0.5) -- statSumFactor can be up to 0.375
            elseif performance.quality < loseDispMax then
                -- Lose disposition
                if loseDispMax > 0 then
                    local normalizedQuality = performance.quality / loseDispMax -- Quality from 0 to loseDispMax
                    -- Max disposition loss: -50 base - 25 from (1 - impressiveness)
                    -- So, low impressiveness leads to higher potential loss
                    local maxDispLossBase = -50
                    local maxDispLossFromImpressiveness = -25 * (1 - impressiveness) -- More loss if not impressive
                    local maxDispLossTotal = maxDispLossBase + maxDispLossFromImpressiveness
                    -- Interpolate: at quality 0, full loss; at quality loseDispMax, 0 loss
                    dispositionChange = (1 - normalizedQuality) * maxDispLossTotal
                elseif performance.quality == 0 then -- Edge case: loseDispMax is 0 or less
                     dispositionChange = -50 -25 * (1-impressiveness)
                end
                -- Apply stat factor: max negative statSumFactor (-0.375) adds up to ~18.75 to the loss
                dispositionChange = dispositionChange * (1 - statSumFactor * 0.5) -- if statSumFactor is negative, (1 - (-val)) increases loss
            end

            dispositionChange = util.round(util.clamp(math.floor(dispositionChange * 1/3), -25, 25) * timeScale)
            local currDisp = publican.type.getBaseDisposition(publican, player)
            local newDisp = util.clamp(currDisp + dispositionChange, 0, 100)
            publican.type.setBaseDisposition(publican, player, newDisp)

            performanceLog.disp = dispositionChange
            performanceLog.oldDisp = currDisp
            performanceLog.newDisp = newDisp
            performanceLog.payment = payment
            performanceLog.kickedOut = kickOut
            payPlayer(player, payment, l10n('UI_Msg_PerfTavern_Payment'), 'sound\\Fx\\item\\money.wav')
        elseif performance.type == Song.PerformanceType.Street then
            rep = rep * 0.1
        end
        performanceLog.rep = util.round((rep) * timeScale * 10) / 10
        logAwait = performanceLog
    end
end

local function tickPerformance(dt)
    if not playing or not song then return end

    local loopStart = song.loopBars[1] * song.resolution * (song.timeSig[1] / song.timeSig[2]) * 4
    if song.playbackTickCurr == loopStart then
        resyncAllActors()
    end

    if not song:tickPlayback(dt,
    -- noteOnHandler
    function(filePath, velocity, instrument, note, part, id)
        local profile = Song.getInstrumentProfile(instrument)
        velocity = velocity * profile.volume / 127
        local actors = partToPerformer[part]
        if not actors then return end
        for _, actor in ipairs(actors) do
            actor:sendEvent('BO_ConductorEvent', { type = 'NoteEvent', time = performance.time, note = note, id = id, filePath = filePath, velocity = velocity })
        end
    end,
    -- noteOffHandler
    function(filePath, instrument, note, part, id)
        local profile = Song.getInstrumentProfile(instrument)
        local actors = partToPerformer[part]
        if not actors then return end
        for _, actor in ipairs(actors) do
            local sustain = profile.sustain
            if profile.name == 'Lute' then sustain = not infiniteLuteRelease end
            actor:sendEvent('BO_ConductorEvent', { type = 'NoteEndEvent', note = note, id = id, filePath = filePath, stopSound = sustain })
        end
    end,
    -- tempoChangeHandler
    function(bpm)
        for _, performerData in ipairs(performers) do
            performerData.actor:sendEvent('BO_ConductorEvent', { type = 'TempoEvent', bpm = bpm })
        end
    end,
    -- loopHandler
    nil,
    -- lyricHandler
    function(newPhrase, index)
        for _, performerData in ipairs(performers) do
            performerData.actor:sendEvent('BO_ConductorEvent', { type = 'LyricEvent', newPhrase = newPhrase, index = index })
        end
    end) then
        stop()
        return
    end

    -- Check if it's a new bar, and if so alert all actors
    local ticksPerBar = song.resolution * (song.timeSig[1] / song.timeSig[2]) * 4
    local introTicks = song.loopBars[1] * ticksPerBar
    local barProgress = (song.playbackTickCurr - introTicks) % ticksPerBar
    if barProgress < (song.playbackTickPrev - introTicks) % ticksPerBar then
        for _, performerData in ipairs(performers) do
            performerData.actor:sendEvent('BO_ConductorEvent', { type = 'NewBar', bar = math.floor(song.playbackTickCurr / ticksPerBar) })
        end
    end
end

local function tickJudge(dt)
    performance.time = performance.time + dt
    if performanceEvalTimer >= performanceEvalInterval then -- Changed > to >= to match typical timer logic
        performanceEvalTimer = 0
        local partDensities = {}
        local totalSuccessCount = 0
        local totalNoteCount = 0

        -- performance.noteEvents accumulates all notes since the performance started.
        -- So, totalMod, totalSuccessCount, totalNoteCount are cumulative.
        for performerId, partNoteEvents in pairs(performance.noteEvents) do
            local noteCount = #partNoteEvents
            if noteCount > 0 then
                local successCount = 0
                local totalMod = 0
                for _, event in ipairs(partNoteEvents) do
                    if event.success then successCount = successCount + 1 end
                    totalMod = totalMod + event.mod
                end
                -- Density for a part is its total accumulated 'mod' / total performance time
                if performance.time > 0 then -- Avoid division by zero if dt was 0 and it's the first frame
                    table.insert(partDensities, totalMod / performance.time)
                else
                    table.insert(partDensities, 0)
                end
                totalSuccessCount = totalSuccessCount + successCount
                totalNoteCount = totalNoteCount + noteCount
            end
        end

        if totalNoteCount > 0 then
            performance.quality = math.pow(totalSuccessCount / totalNoteCount, 2) * 100

            local sumOfRawDensities = 0
            for _, density in ipairs(partDensities) do
                sumOfRawDensities = sumOfRawDensities + density
            end
            performance.complexity = sumOfRawDensities

            if #partDensities > 0 then
                -- Sort partDensities in descending order to apply diminishing returns correctly
                table.sort(partDensities, function(a, b) return a > b end)

                local newPerfDensity = 0
                local diminishingFactor = configGlobal.options.fTroupeDiminishMult
                for i, sortedDensity in ipairs(partDensities) do
                    newPerfDensity = newPerfDensity + sortedDensity * (diminishingFactor ^ (i - 1))
                end
                performance.density = newPerfDensity
            else
                -- No parts contributed to density (e.g., all mods were 0)
                performance.density = 0
                -- performance.complexity would also be 0 if partDensities is empty
            end
        else
            -- If totalNoteCount is 0 (e.g., at the very start of the performance before any notes),
            -- quality, density, and complexity will retain their initial values (typically 0).
            -- If performance.noteEvents is cumulative, this 'else' branch is primarily for the initial state.
        end
    else
        performanceEvalTimer = performanceEvalTimer + dt
    end
end
local ThrownItemType = {
    Drink = 1,
    Bread = 2,
}

local function createThrownItemData(threshold, probability, damage, type, items, chances, messagePrefix)
    return {
        threshold = threshold,
        probability = probability,
        damage = damage,
        type = type,
        items = items,
        chances = chances,
        messagePrefix = messagePrefix,
    }
end

local ThrownItemData = {
    [ThrownItemType.Drink] = createThrownItemData(20, 0.1, 3, types.Potion, {
        potion_local_brew_01 = 1/10, -- Mazte
        potion_comberry_wine_01 = 1/10, -- Shein
        potion_comberry_brandy_01 = 1/30, -- Greef
        potion_local_liquor_01 = 1/30, -- Sujamma
        potion_cyro_brandy_01 = 1/100, -- Cyrodiilic Brandy
        potion_cyro_whiskey_01 = 1/100, -- Flin
    },
    { hit = 0.5, criticalHit = 0.3, catch = 0.3, }, 
    'UI_Msg_PerfTavern_Throw_Drink'),

    [ThrownItemType.Bread] = createThrownItemData(40, 0.3, 1, types.Ingredient, {
        ingred_bread_01 = 1,
    },
    { hit = 0.5, criticalHit = 0.05, catch = 0.6, },
    'UI_Msg_PerfTavern_Throw_Bread'),
}

local function selectItemFromProbabilityList(list, roll)
    roll = roll or math.random()

    -- Calculate the sum of all positive weights (non-normalized probabilities)
    local totalWeight = 0
    for _, weight in pairs(list) do
        if weight > 0 then
            totalWeight = totalWeight + weight
        end
    end

    -- If total weight is not positive, cannot select an item
    if totalWeight <= 0 then
        return nil
    end

    -- Iterate through the items, accumulating normalized probability
    local accumulatedProbability = 0
    for itemKey, weight in pairs(list) do
        if weight > 0 then
            local probability = weight / totalWeight
            accumulatedProbability = accumulatedProbability + probability
            -- math.random() returns [0, 1), so check if roll falls below the current accumulated threshold
            if roll < accumulatedProbability then
                return itemKey
            end
        end
    end

    local lastItem = nil
    for itemKey, weight in pairs(list) do
        if weight > 0 then
            lastItem = itemKey
        end
    end
    return lastItem
end

local TipType = {
    Normal = 1,
    Wealthy = 2,
    Pitiful = 3,
}

local function doRandomEvent()
    local player = world.players[1]
    if not player then return end
    if performance.type == Song.PerformanceType.Practice or performance.type == Song.PerformanceType.Ambient then return end

    local function giveItem(item, count)
        local itemObj = world.createObject(item, count or 1)
        itemObj:moveInto(types.Actor.inventory(player))
    end
    
    local tipChance = 0.5
    local tipAmount = configGlobal.options.fOverallGoldMult
    local tipType = TipType.Normal

    local statFactor = getStatFactor()
    local qualityFactor = getQualityFactor(statFactor)
    local perfFactor = (qualityFactor - 0.5) * (math.pow(getImpressivenessFactor(), 1.5) + 0.5)
    if performance.type == Song.PerformanceType.Street then
        tipChance = 0.25
        tipAmount = 0.25

        if performance.streetType == Cell.StreetType.Metropolis then
            tipChance = tipChance * 2
        elseif performance.streetType == Cell.StreetType.City then
            tipChance = tipChance * 1.5
        end
    end

    tipChance = (tipChance + statFactor) * perfFactor
    tipAmount = tipAmount * math.random() * 40 * perfFactor * (1 + statFactor)

    if perfFactor < 0.15 then
        tipType = TipType.Pitiful
        tipAmount = tipAmount * 0.2
    elseif math.random() < 0.05 then
        tipType = TipType.Wealthy
        tipAmount = tipAmount * 5
    end

    if performance.type == Song.PerformanceType.Tavern then
        -- Thrown Items
        for _, itemData in pairs(ThrownItemData) do
            if performance.quality < itemData.threshold and math.random() < itemData.probability then
                local item = selectItemFromProbabilityList(itemData.items)

                if item then
                    local agilityFactor = 1 + (player.type.stats.attributes.agility(player).modified - 50) / 50 * 0.25

                    local hitChance = itemData.chances.hit / agilityFactor
                    local criticalHitChance = itemData.chances.criticalHit / agilityFactor
                    local catchChance = itemData.chances.catch * agilityFactor

                    local damage = 0
                    local message = l10n(itemData.messagePrefix)

                    if math.random() < hitChance then
                        if math.random() < criticalHitChance then
                            -- Critical hit
                            damage = itemData.damage * 3
                            message = message .. '\n' .. l10n('UI_Msg_Perf_Throw_HitCritical')
                        else
                            -- Hit
                            damage = itemData.damage
                        end
                    else
                        damage = 0
                        if math.random() < catchChance then
                            -- Catch
                            message = message .. '\n' .. l10n('UI_Msg_Perf_Throw_Catch'):gsub('%%{count}', 1):gsub('%%{itemName}', itemData.type.record(item).name)
                            giveItem(item)
                        else
                            -- Miss
                            message = message .. '\n' .. l10n('UI_Msg_Perf_Throw_Dodge')
                        end
                    end

                    player:sendEvent('BC_PerformanceEvent', { type = 'ThrownItem', damage = damage, message = message })
                    return
                end
            end
        end

        -- Random crowd sounds
        if performance.quality < 60 and math.random() < 0.4 then
            -- Play a cough sound
            local cough = math.random(1, 2)
            local soundFile = 'sound/Bardcraft/crowd/cough' .. cough .. '.wav'
            if not core.sound.isSoundFilePlaying(soundFile, player) then
                core.sound.playSoundFile3d(soundFile, player, { volume = 0.1 + 0.4 * (60 - performance.quality) / 60 })
            end
        elseif performance.quality < 40 and math.random() < 0.05 then
            -- Play a retching sound
            local soundFile = 'sound/Bardcraft/crowd/hurl.wav'
            if not core.sound.isSoundFilePlaying(soundFile, player) then
                core.sound.playSoundFile3d(soundFile, player, { volume = 0.1 + 0.4 * (40 - performance.quality) / 40 })
            end
        end
    end

    -- Tips
    if performance.time >= 5 and math.random() < tipChance then
        local message
        local sfx
        local speechXp
        if tipType == TipType.Normal then
            message = l10n(performance.type == Song.PerformanceType.Tavern and getRandomLocalizedLine('UI_Msg_PerfTavern_Tip') or getRandomLocalizedLine('UI_Msg_PerfBusking_Tip'))
            sfx = 'sound\\Bardcraft\\crowd\\coin-few.wav'
            speechXp = 2
        elseif tipType == TipType.Wealthy then
            message = l10n(performance.type == Song.PerformanceType.Tavern and getRandomLocalizedLine('UI_Msg_PerfTavern_Tip_Wealthy') or getRandomLocalizedLine('UI_Msg_PerfBusking_Tip_Wealthy'))
            sfx = 'sound\\Bardcraft\\crowd\\coin-many.wav'
            speechXp = 5
        else
            message = l10n(performance.type == Song.PerformanceType.Tavern and getRandomLocalizedLine('UI_Msg_PerfTavern_Tip_Bad') or getRandomLocalizedLine('UI_Msg_PerfBusking_Ignore'))
            sfx = 'sound\\Bardcraft\\crowd\\coin-one.wav'
            speechXp = 1
        end
        if performance.type == Song.PerformanceType.Tavern then
            tipAmount = tipAmount * configGlobal.options.fTavernGoldMult
        elseif performance.type == Song.PerformanceType.Street then
            tipAmount = tipAmount * configGlobal.options.fStreetGoldMult
        end
        tipAmount = math.ceil(tipAmount)
        if tipAmount > 0 then
            payPlayer(player, tipAmount, message, sfx)
            performance.tips = performance.tips + tipAmount
            player:sendEvent('BC_SpeechcraftXP', { amount = speechXp, })
            return
        end
    elseif tipChance <= 0 and performance.type == Song.PerformanceType.Street then
        if math.random() < 0.25 then
            player:sendEvent('BC_PerformanceEvent', { type = 'Flavor', message = l10n(getRandomLocalizedLine('UI_Msg_PerfBusking_Ignore')) })
        end
    end
end

local lastCrowdBoo = 0
local lastCrowdClap = 0

local function doCrowdNoise()
    if performance.type ~= Song.PerformanceType.Tavern then return end
    if performance.quality < 35 then
        local crowdNoiseNum = math.random(2, 4)
        if crowdNoiseNum <= lastCrowdBoo then
            crowdNoiseNum = crowdNoiseNum - 1
        end
        lastCrowdBoo = crowdNoiseNum
        local soundFile = 'sound/Bardcraft/crowd/boo' .. crowdNoiseNum .. '.wav'
        if not core.sound.isSoundFilePlaying(soundFile, world.players[1]) then
            core.sound.playSoundFile3d(soundFile, world.players[1], { volume = 0.1 + 0.4 * (35 - performance.quality) / 35 })
        end
    elseif performance.quality >= 90 and performance.density > 4.5 then
        local crowdNoiseNum = math.random(2, 4)
        if crowdNoiseNum <= lastCrowdClap then
            crowdNoiseNum = crowdNoiseNum - 1
        end
        lastCrowdClap = crowdNoiseNum
        local soundFile = 'sound/Bardcraft/crowd/clap' .. crowdNoiseNum .. '.wav'
        if not core.sound.isSoundFilePlaying(soundFile, world.players[1]) then
            core.sound.playSoundFile3d(soundFile, world.players[1], { volume = 0.1 + 0.4 * (performance.quality - 80) / 20 })
        end
    elseif performance.quality >= 85 and performance.density > 3 then
        if math.random() < 0.5 then
            local clapOptions = { "clap3", "clap4", "clap-polite" }
            local idx = math.random(1, #clapOptions)
            local soundFile = 'sound/Bardcraft/crowd/' .. clapOptions[idx] .. '.wav'
            if not core.sound.isSoundFilePlaying(soundFile, world.players[1]) then
                core.sound.playSoundFile3d(soundFile, world.players[1], { volume = 0.1 + 0.15 * (performance.quality - 85) / 15 })
            end
        end
    end
end

local function tickRandomEvents(dt)
    if performanceRandomEventTimer <= 0 then
        performanceRandomEventTimer = math.random() * (performanceRandomEventInterval[2] - performanceRandomEventInterval[1]) + performanceRandomEventInterval[1]
        doCrowdNoise()
        doRandomEvent()
    else
        performanceRandomEventTimer = performanceRandomEventTimer - dt
    end
end

local function update(dt)
    if playing then
        tickPerformance(dt)
        tickJudge(dt)
        tickRandomEvents(dt)
    end
end

return {
    engineHandlers = {
        onUpdate = update,
    },
    eventHandlers = {
        BO_StartPerformance = function(data)
            if not playing then
                local player = world.players[1]
                if not data.performers or #data.performers == 0 then 
                    player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_NoPerformers') })
                    return 
                end

                -- Require the player to be one of the performers
                local playerIsPerformer = false
                for _, performer in ipairs(data.performers) do
                    if performer.actorId == player.id then
                        playerIsPerformer = true
                        break
                    end
                end
                if not playerIsPerformer then
                    player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_PlayerNotPerformer') })
                    return
                end

                local type, streetName, streetType = Cell.canPerformHere(player.cell, data.type)
                if not type then
                    if data.type == Song.PerformanceType.Practice then
                        player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_InvalidPracticeLocation') })
                    elseif data.type == Song.PerformanceType.Ambient then
                        player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_InvalidPracticeLocation') })
                    else
                        player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_InvalidLocation') })
                    end
                    return
                elseif type == Song.PerformanceType.Tavern then
                    local bannedVenues = data.playerStats.bannedVenues
                    for venue, banEndTime in pairs(bannedVenues) do
                        if venue == player.cell.name then
                            player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_BannedVenue'):gsub('%%{date}', calendar.formatGameTime('%d %B', banEndTime)):match("0*(.+)") })
                            return
                        end
                    end

                    local alreadyPerformed = data.playerStats.performedVenuesToday
                    for venue, _ in pairs(alreadyPerformed) do
                        if venue == player.cell.name then
                            player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_AlreadyPerformed') })
                            return
                        end
                    end

                    -- Check if it's the evening (6PM - midnight)
                    local gameTime = core.getGameTime()
                    local timeOfDay = gameTime % time.day
                    local isEvening = (timeOfDay >= 18 * time.hour) or (configGlobal.options.bEnableTimeRestriction == false)
                    if not isEvening then
                        player:sendEvent('BC_StartPerformanceFail', { reason = l10n('UI_Msg_PerfStartFail_TooEarly') })
                        return
                    end
                end
                data.type = type
                data.streetName = streetName
                data.streetType = streetType

                song = data.song
                setmetatable(song, Song)

                local perfList = data.performers
                local activeActors = world.activeActors
                local playerItem = nil
                local playedParts = {}
                for i, performer in ipairs(data.performers) do
                    for _, actor in ipairs(activeActors) do
                        if actor.id == performer.actorId then
                            perfList[i].actor = actor
                            break
                        end
                    end
                    perfList[i].part = song:getPartByIndex(performer.part)
                    -- Make sure all the performers have their required instrument
                    local instrument = Song.getInstrumentProfile(perfList[i].part.instrument).name
                    local validItems = instrumentItems[instrument]
                    local inventory = types.Actor.inventory(perfList[i].actor)
                    for item, _ in pairs(validItems) do
                        if inventory:find(item) then
                            perfList[i].item = item
                            break
                        end
                    end
                    if not perfList[i].item then
                        player:sendEvent('BC_StartPerformanceFail', { 
                            reason = l10n('UI_Msg_PerfStartFail_NoInstrument')
                                    :gsub('%%{performer}', perfList[i].actor.type.record(perfList[i].actor).name)
                                    :gsub('%%{instrument_indef}', l10n('UI_Msg_' .. instrument .. '_Indef')) })
                        return
                    end
                    if performer.actorId == player.id then
                        playerItem = perfList[i].item
                    end
                    -- Add part index to playedParts
                    playedParts[perfList[i].part.index] = true
                end
                performers = perfList
                song:resetPlayback()
                start(data)

                player:sendEvent('BC_StartPerformanceSuccess', { item = playerItem and playerItem.recordId or nil, song = song, playedParts = playedParts })
            end
        end,
        BO_StopPerformance = function(data)
            if not playing then return end
            stop()
        end,
        BC_RecheckCell = function(data)
            if not playing then return end
            
            local type, streetName = Cell.canPerformHere(data.player.cell, performance.type)

            if performance.type == Song.PerformanceType.Tavern then
                stop()
            elseif performance.type == Song.PerformanceType.Street then
                if not type or streetName ~= performance.streetName then
                    stop()
                end
            elseif not type then
                stop()
            end
        end,
        BC_PerformerNoteHandled = function(data)
            if not performance.noteEvents[data.performer.id] then
                performance.noteEvents[data.performer.id] = {}
            end
            table.insert(performance.noteEvents[data.performer.id], { success = data.success, mod = data.mod })
        end,
        BC_PlayerPerfSkillLog = function(data)
            if logAwait then
                logAwait.xpGain = util.round(data.xpGain * 10) / 10
                logAwait.level = data.level
                logAwait.levelGain = data.levelGain
                logAwait.xpCurr = util.round(data.xpCurr * 10) / 10
                logAwait.xpReq = util.round(data.xpReq * 10) / 10
                world.players[1]:sendEvent('BC_PerformanceLog', logAwait)
                logAwait = nil
            end
        end,
    }
}