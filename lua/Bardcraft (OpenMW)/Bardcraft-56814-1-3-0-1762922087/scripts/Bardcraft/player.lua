local input = require('openmw.input')
local core = require('openmw.core')
local anim = require('openmw.animation')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local camera = require('openmw.camera')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local ambient = require('openmw.ambient')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local nearby = require('openmw.nearby')

local l10n = core.l10n('Bardcraft')

local Performer = require('scripts.Bardcraft.performer')
local Editor = require('scripts.Bardcraft.editor')
local Song = require('scripts.Bardcraft.util.song').Song
local Data = require('scripts.Bardcraft.data')

local configPlayer = require('scripts.Bardcraft.config.player')
local configGlobal = require('scripts.Bardcraft.config.global')

local performersInfo = {}

local function populateKnownSongs()
    local bardData = storage.globalSection('Bardcraft')
    local storedSongs = bardData:getCopy('songs/preset') or {}
    local race = self.type.record(self).race
    for _, song in pairs(storedSongs) do
        local record = Data.StartingSongs[song.id]
        if record then
            local raceMatches = record == 'any' or record == race
            if raceMatches and not Performer.stats.knownSongs[song.id] then
                Performer:addKnownSong(song)
            end
        end
    end
end

local currentCell = nil
local bannedVenueTrespassTimer = nil
local bannedVenueTrespassDuration = 30 -- seconds

local function unbanFromVenue(cellName)
    if Performer.stats.bannedVenues[cellName] then
        Performer.stats.bannedVenues[cellName] = nil
        performersInfo[self.id] = Performer.stats
        Editor.performersInfo = performersInfo
    end
end

local function banFromVenue(cellName, startTime, days)
    if Performer.stats.bannedVenues[cellName] then
        return Performer.stats.bannedVenues[cellName]
    end
    local startDay = math.ceil(startTime / time.day)
    local endDay = startDay + days
    local endTime = endDay * time.day
    local currentTime = core.getGameTime()
    if currentTime >= startTime and currentTime < endTime then
        Performer.stats.bannedVenues[cellName] = endTime
        currentCell = nil
        performersInfo[self.id] = Performer.stats
        Editor.performersInfo = performersInfo
        return endTime
    end
    return nil
end

local performancePart = nil
local queuedMilestone = nil
local practiceSong = nil

local performOverlayNoteMap = {}
local performOverlayNoteIdToIndex = {}
local performOverlayNoteIndexToContentId = {}
local performOverlay = nil
local performOverlayNotesWrapper = nil
local performOverlayNoteFlashTimes = {}
local performOverlayNoteSuccess = {}
local performOverlayNoteFadeTimes = {}
local performOverlayNoteFadeAlphaStart = {}
local performOverlayTargetBgrOpacity = 0.4
local performOverlayTargetNoteOpacity = 0.6
local performOverlayFadeInTimer = 0
local performOverlayFadeInDuration = 0.3
local performOverlayScaleX = 8 -- Every 8 ticks is 1 pixel
local performOverlayScaleY = 0
local performOverlayTick = 0
local performOverlayNoteBounds = {129, 0}
local performOverlayRepopulateTimeWindow = 2 -- seconds; only render notes within this time window to avoid crazy lag
local performOverlayRepopulateTime = performOverlayRepopulateTimeWindow 
local performOverlayNoteLayouts = {}
local performOverlayLastShakeFactor = 0

local performOverlayToggle = true

local overlays = {
    hurt = {
        element = ui.create {
            layer = 'Notification',
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = 'textures/bardcraft/overlay_hurt.dds' },
                relativeSize = util.vector2(1, 1),
                alpha = 0,
            },
        },
        alpha = 0,
    },
    tpFade = {
        element = ui.create {
            layer = 'Notification',
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = 'white' },
                relativeSize = util.vector2(1, 1),
                color = Editor.uiColors.BLACK,
                alpha = 0,
            },
        },
        timer = nil,
    }
}

local performInstrument = nil
local lastCameraMode = nil
local resetAnimNextTick = false
local setVfxNextFrame = false
local nearbyPlayingTimer = 0

local function getPracticeNoteMap()
    if not practiceSong then return {} end
    local baseNoteMap = practiceSong:noteEventsToNoteMap(practiceSong.notes)
    local noteMap = {}
    performOverlayNoteBounds = {129, 0}
    for i, data in pairs(baseNoteMap) do
        if data.part == performancePart then
            table.insert(noteMap, {
                note = data.note,
                time = data.time,
                duration = data.duration,
                index = data.id,
            })
            performOverlayNoteBounds[1] = math.min(performOverlayNoteBounds[1], data.note)
            performOverlayNoteBounds[2] = math.max(performOverlayNoteBounds[2], data.note)
        end
    end
    table.sort(noteMap, function(a, b) return a.time < b.time end)
    performOverlayScaleY = 128 / ((performOverlayNoteBounds[2] - performOverlayNoteBounds[1]) + 2)
    return noteMap
end

local function lerp(t, a, b)
    return a + (b - a) * t
end

local function lerpColor(t, a, b)
    return util.color.rgb(
        lerp(t, a.r, b.r),
        lerp(t, a.g, b.g),
        lerp(t, a.b, b.b)
    )
end

local function getHudSize()
    local layerIndex = ui.layers.indexOf('HUD')
    local layer = layerIndex and ui.layers[layerIndex]
    if not layer then return ui.screenSize() end
    return layer.size
end

local function initPerformOverlayNotes()
    if not performOverlayNotesWrapper then return end

    local screenWidth = getHudSize().x

    performOverlayNoteLayouts = {}
    local i = 1
    for _, data in pairs(performOverlayNoteMap) do
        performOverlayNoteIdToIndex[data.index] = i
        local note = {
            type = ui.TYPE.Image,
            props = {
                index = data.index,
                resource = ui.texture { path = 'textures/bardcraft/ui/pianoroll-note.dds' },
                size = util.vector2(data.duration * performOverlayScaleX - performOverlayScaleX, performOverlayScaleY * 4),
                tileH = true,
                tileV = false,
                baseY = math.floor((performOverlayNoteBounds[2] - data.note) * performOverlayScaleY) * 2,
                position = util.vector2(data.time * performOverlayScaleX + screenWidth / 2, math.floor((performOverlayNoteBounds[2] - data.note) * performOverlayScaleY) * 2),
                alpha = 0.2,
            },
        }
        table.insert(performOverlayNoteLayouts, note)
        i = i + 1
    end
end

local performOverlayLyricsWrapper = nil

local function populatePerformOverlayNotes()
    local windowXOffset = performOverlayTick * performOverlayScaleX - performOverlayScaleX
    local tickDiff = practiceSong:dtToTicks(performOverlayTick, performOverlayRepopulateTimeWindow)
    local windowXSize = getHudSize().x + tickDiff * performOverlayScaleX
    local content = ui.content {}
    performOverlayNoteIndexToContentId = {}

    local count = 0
    for i, note in pairs(performOverlayNoteLayouts) do
        local notePos = note.props.position.x
        local noteSize = note.props.size.x

        if notePos >= windowXOffset + windowXSize then
            break
        end
        if notePos + noteSize >= windowXOffset then
            content:add(note)
            count = count + 1
            performOverlayNoteIndexToContentId[i] = count
        end
    end

    performOverlayNotesWrapper.layout.content[1].content = content
    performOverlayNotesWrapper:update()
end

local function setPerformOverlayLyricPhrase(index)
    if not performOverlayLyricsWrapper or not practiceSong then return end
    local phrase = practiceSong.lyrics[index]
    if not phrase then return end
    local content = ui.content {}
    local syllableCount = 0
    local playerOptions = configPlayer.options
    for i, syllable in ipairs(phrase) do
        local text = syllable.text or ""
        local displayText = text
        local addSpace = true

        if i == #phrase then
            -- Last syllable, no space after it
            addSpace = false
        elseif text == "" then
            -- Blank or nil, insert as-is, no space
            addSpace = false
        elseif text:sub(-2) == "\\-" then
            -- Ends with \-, strip backslash, keep hyphen, no space
            displayText = text:sub(1, -3) .. "-"
            addSpace = false
        elseif text:sub(-1) == "-" then
            -- Ends with -, strip hyphen, no space
            displayText = text:sub(1, -2)
            addSpace = false
        end

        if text ~= "" then
            syllableCount = syllableCount + 1
        end

        content:add({
            template = I.MWUI.templates.textNormal,
            props = {
                text = displayText .. (addSpace and " " or ""),
                textColor = Editor.uiColors.DEFAULT,
                textSize = playerOptions.iLyricsTextSize,
            },
        })
    end
    performOverlayLyricsWrapper.layout.content[1].content[1].content = content
    performOverlayLyricsWrapper.layout.props.visible = playerOptions.bEnableLyrics and syllableCount > 0
    performOverlayLyricsWrapper:update()
end

local function onPerformOverlayLyricSyllable(index)
    if not performOverlayLyricsWrapper or not performOverlayLyricsWrapper.layout or not performOverlayLyricsWrapper.layout.content then return end
    local content = performOverlayLyricsWrapper.layout.content[1].content[1].content
    local syllable = content[index]
    if syllable and syllable.props then
        syllable.props.textColor = Editor.uiColors.DEFAULT_LIGHT
    end
    performOverlayLyricsWrapper:update()
end

local function createPerformOverlay()
    local alreadyShowing = false
    local alpha = 0
    if performOverlay then
        alreadyShowing = true
        alpha = performOverlay.layout.props.alpha
        auxUi.deepDestroy(performOverlay)
    elseif configPlayer.options.bDisablePerformOverlay then
        performOverlayToggle = false
    end
    performOverlayNoteMap = getPracticeNoteMap()
    performOverlayScaleX = 6 * (practiceSong.tempo * practiceSong.tempoMod / 120) / (practiceSong.resolution / 96)

    performOverlayNotesWrapper = ui.create {
        type = ui.TYPE.Container,
        props = {
            relativeSize = util.vector2(1, 1),
            alpha = alpha,
        },
        content = ui.content{
            {
                type = ui.TYPE.Container,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
                content = ui.content {},
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'textures/bardcraft/ui/practice-overlay-line.dds' },
                    position = util.vector2(practiceSong:barToTick(practiceSong.loopBars[2]) * performOverlayScaleX + getHudSize().x / 2, 0),
                    size = util.vector2(8, 256),
                    color = Editor.uiColors.CYAN,
                },
            }
        },
    }

    performOverlayLyricsWrapper = ui.create {
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = util.vector2(0, 260),
            anchor = util.vector2(0.5, 0),
            relativePosition = util.vector2(0.5, 0),
            visible = false,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {},
                    }
                }
            }
        }
    }

    local bgrPath, centerline
    local style = configPlayer.options.sPerformOverlayBgrStyle
    if style == 'Style_Bordered' then
        bgrPath = 'black'
        centerline = {
            name = 'centerline',
            template = I.MWUI.templates.verticalLine,
            props = {
                anchor = util.vector2(0.5, 0),
                relativePosition = util.vector2(0.5, 0),
                relativeSize = util.vector2(0, 0),
                size = util.vector2(2, 256),
                alpha = alpha,
            },
        }
    else
        bgrPath = 'textures/bardcraft/ui/practice-overlay.dds'
        centerline = {
            name = 'centerline',
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = 'textures/bardcraft/ui/practice-overlay-line.dds' },
                anchor = util.vector2(0.5, 0),
                relativePosition = util.vector2(0.5, 0),
                size = util.vector2(8, 256),
                color = Editor.uiColors.DEFAULT_LIGHT,
                alpha = alpha,
            },
        }
    end

    performOverlay = ui.create {
        layer = 'HUD',
        props = {
            relativeSize = util.vector2(1, 0),
            size = util.vector2(0, 320),
            visible = performOverlayToggle,
        },
        content = ui.content {
            {
                name = 'background',
                type = ui.TYPE.Image,
                props = {
                    --relativeSize = util.vector2(1, 0),
                    resource = ui.texture { path = bgrPath },
                    relativeSize = util.vector2(1, 0),
                    size = util.vector2(0, 256),
                    tileH = true,
                    tileV = false,
                    alpha = alpha,
                },
            },
            performOverlayNotesWrapper,
            centerline,
            performOverlayLyricsWrapper,
            {
                name = 'border',
                template = style == 'Style_Bordered' and I.MWUI.templates.horizontalLineThick or nil,
                props = {
                    position = util.vector2(0, 256),
                }
            },
        },
    }
    if not alreadyShowing then
        performOverlayFadeInTimer = performOverlayFadeInDuration
    end

    performOverlayTick = practiceSong.playbackTickCurr
    initPerformOverlayNotes()
    populatePerformOverlayNotes()
    performOverlayNoteFlashTimes = {}
    performOverlayNoteFadeTimes = {}
    performOverlayNoteFadeAlphaStart = {}
    performOverlayNoteSuccess = {}
    performOverlayRepopulateTime = performOverlayRepopulateTimeWindow 
    performOverlayLastShakeFactor = -1
end

local function togglePerformOverlay()
    if performOverlay then
        performOverlayToggle = not performOverlayToggle
        performOverlay.layout.props.visible = performOverlayToggle
        if not performOverlayToggle then
            performOverlayFadeInTimer = 0
            performOverlay.layout.props.alpha = 0
        else
            performOverlayFadeInTimer = performOverlayFadeInDuration
            performOverlay.layout.props.alpha = 1
        end
    end
end

local function destroyPerformOverlay()
    if performOverlay then
        auxUi.deepDestroy(performOverlay)
        performOverlay = nil
    end
end

local function updatePerformOverlay()
    if not performOverlay or not performOverlayNotesWrapper then return end
    performOverlayNotesWrapper.layout.props.position = util.vector2(-performOverlayTick * performOverlayScaleX, 0)
    if performOverlayRepopulateTime > 0 then
        performOverlayRepopulateTime = math.max(performOverlayRepopulateTime - core.getRealFrameDuration(), 0)
    else
        performOverlayRepopulateTime = performOverlayRepopulateTimeWindow
        populatePerformOverlayNotes()
    end
    performOverlayNotesWrapper:update()
    performOverlayLyricsWrapper:update()
    performOverlay:update()
end

local function doHurt(amount)
    overlays.hurt.alpha = 0.25
    self.type.stats.dynamic.health(self).current = self.type.stats.dynamic.health(self).current - amount
    ambient.playSoundFile('sound\\fx\\body hit.wav')
end

local function playSwoosh()
    ambient.playSoundFile('sound\\fx\\swoosh ' .. math.random(1, 3) .. '.wav')
end

local function startTrespassTimer()
    bannedVenueTrespassTimer = 0
    ui.showMessage(l10n('UI_Msg_Warn_Trespass'))
end

local function setPerformerInfo()
    performersInfo[self.id] = Performer.stats
    Editor.performersInfo = performersInfo
end

local function verifyPerformInstrument()
    if performInstrument then
        local inventory = self.type.inventory(self)
        if not inventory:find(performInstrument.id) then
            performInstrument = nil
            core.sendGlobalEvent('BO_StopPerformance')
        end
    end
end

local function confirmModal(onYes, onNo)
    if Performer.playing then
        Editor:playerConfirmModal(self, onYes, onNo)
    end
end

local function onStanceChange(stance)
    if not Performer.playing then return end
    confirmModal(function()
        core.sendGlobalEvent('BO_StopPerformance')
        self.type.setStance(self, stance)
    end,
    function()
        self.type.setStance(self, self.type.STANCE.Nothing)
    end)
    self.type.setStance(self, self.type.STANCE.Nothing)
end

input.registerTriggerHandler('ToggleWeapon', async:callback(function()
    if not core.isWorldPaused() and I.UI.getMode() == nil then
        onStanceChange(self.type.STANCE.Weapon)
    end
end))

input.registerTriggerHandler('ToggleSpell', async:callback(function()
    if not core.isWorldPaused() and I.UI.getMode() == nil then
        onStanceChange(self.type.STANCE.Spell)
    end
end))

input.registerActionHandler('Use', async:callback(function(e)
    if e and not core.isWorldPaused() and I.UI.getMode() == nil then
        onStanceChange(self.type.STANCE.Weapon)
    end
end))

local previewHoldStart = nil
local previewHoldStartMode = nil

input.registerActionHandler('TogglePOV', async:callback(function(e)
    if Performer.playing and not core.isWorldPaused() then
        if e then
            previewHoldStart = core.getRealTime()
            previewHoldStartMode = camera.getMode()
        end
        if not e then
            if camera.getMode() == camera.MODE.Preview and previewHoldStart and core.getRealTime() - previewHoldStart > 0.25 then
                camera.setMode(previewHoldStartMode, true)
                if previewHoldStartMode ~= camera.MODE.Preview then
                    resetAnimNextTick = true
                end
                previewHoldStart = nil
                previewHoldStartMode = nil
                return false
            end

            if camera.getMode() ~= camera.MODE.FirstPerson then
                camera.setMode(camera.MODE.FirstPerson, true)
                resetAnimNextTick = true
            else
                camera.setMode(camera.MODE.ThirdPerson, true)
                resetAnimNextTick = true
            end
            previewHoldStart = nil
        end
        return false
    end
end))

local music = {
    selfPlaying = false,
    nearbyPlaying = false,
    editorPlaying = false,
    silenced = false,
}

local function isAnyPlaying()
    return music.selfPlaying or music.nearbyPlaying or music.editorPlaying
end

local function silenceAmbientMusic()
    if I.S3maphore then
        storage.playerSection('Bardcraft'):set('S3maphoreSilenced', true)
        self:sendEvent('S3maphoreToggleMusic', false)
    else
        ambient.streamMusic("sound\\Bardcraft\\silence.opus", { fadeOut = 0.5 })
    end
    music.silenced = true
end

local function unsilenceAmbientMusic()
    if I.S3maphore then
        storage.playerSection('Bardcraft'):set('S3maphoreSilenced', false)
        self:sendEvent('S3maphoreToggleMusic', true)
    else
        ambient.stopMusic()
    end
    music.silenced = false
end

local function setAmbientMusic()
    if music.silenced then
        if not isAnyPlaying() then
            unsilenceAmbientMusic()
        end  
    else
        if isAnyPlaying() and configPlayer.options.bSilenceAmbientMusic then
            silenceAmbientMusic()
        end
    end
end

local function updateAmbientMusic()
    music.selfPlaying = Performer.playing
    music.editorPlaying = Editor.active and Editor.state == Editor.STATE.SONG
    setAmbientMusic()
end

local function getRandomSong(pool)
    -- Keep trying until we find a song that the player doesn't know, or we run out of choices
    local availableChoices = {}

    -- Create a copy of the choices array to safely modify it
    for _, sourceFile in ipairs(pool) do
        table.insert(availableChoices, sourceFile)
    end

    -- Try to find a song the player doesn't know yet
    while #availableChoices > 0 do
        local index = math.random(1, #availableChoices)
        local sourceFile = availableChoices[index]
        local candidateSong = Performer.getSongBySourceFile(sourceFile)
        
        if candidateSong and not Performer.stats.knownSongs[candidateSong.id] then
            -- Found a song the player doesn't know
            return candidateSong
        end
        
        -- Remove this choice regardless of whether we found a usable song
        table.remove(availableChoices, index)
    end

    -- If no unknown songs were found, pick a random valid song
    if #pool > 0 then
        local shuffledChoices = {}
        for _, sourceFile in ipairs(pool) do
            table.insert(shuffledChoices, sourceFile)
        end
        -- Shuffle the choices
        for i = #shuffledChoices, 2, -1 do
            local j = math.random(1, i)
            shuffledChoices[i], shuffledChoices[j] = shuffledChoices[j], shuffledChoices[i]
        end
        -- Pick the first valid song from the shuffled list
        for _, sourceFile in ipairs(shuffledChoices) do
            local song = Performer.getSongBySourceFile(sourceFile)
            if song then return song end
        end
    end
end

local function precacheSongSamples(data)
    setmetatable(data.song, Song)
    local samples = {}
    for _, event in ipairs(data.song.notes) do
        if event.type == 'noteOn' and data.playedParts[event.part] then
            local part = data.song:getPartByIndex(event.part)
            if part then
                local instrument = part.instrument
                local profile = Song.getInstrumentProfile(instrument)
                local noteName = Song.noteNumberToName(event.note)
                local filePath = 'sound\\Bardcraft\\samples\\' .. profile.name .. '\\' .. profile.name .. '_' .. noteName .. '.wav'
                samples[filePath] = true
            end
        end
    end
    for filePath, _ in pairs(samples) do
        ambient.playSoundFile(filePath, { volume = 0.0 })
    end
end

return {
    engineHandlers = {
        onInit = function()
            Editor:init()
            setPerformerInfo()
        end,
        onLoad = function(data)
            if not data then return end
            Performer:onLoad(data)
            anim.removeAllVfx(self)
            Editor:init()

            if data.BC_PerformersInfo then
                performersInfo = data.BC_PerformersInfo
            end
            if data.BC_EditorBookmarks then
                Editor.bookmarkedSongs = data.BC_EditorBookmarks
            end
            core.sendGlobalEvent('BC_ParseMidis')
            setPerformerInfo()
            core.sendGlobalEvent('BC_RecheckTroupe', { player = self, })
        end,
        onSave = function()
            local data = Performer:onSave()
            data.BC_PerformersInfo = performersInfo
            data.BC_EditorBookmarks = Editor.bookmarkedSongs
            return data
        end,
        onActive = function()
            Performer:setSheatheVfx()
            core.sendGlobalEvent('BC_RecheckTroupe', { player = self, })

            if storage.playerSection('Bardcraft'):get('S3maphoreSilenced') and not music.silenced then
                if I.S3maphore then
                    self:sendEvent('S3maphoreToggleMusic', true)
                    storage.playerSection('Bardcraft'):set('S3maphoreSilenced', false)
                end
            end
        end,
        onUpdate = function(dt)
            if dt == 0 then return end

            if Performer.playing then
                if resetAnimNextTick then
                    resetAnimNextTick = false
                    Performer.resetAnim()
                    Performer.resetVfx()
                end
                local queuedMode = camera.getQueuedMode()
                if queuedMode == camera.MODE.FirstPerson or queuedMode == camera.MODE.Preview then
                    camera.setMode(queuedMode, true)
                    resetAnimNextTick = true
                else
                    camera.setMode(camera.getMode(), false)
                end
            end
            Performer:onUpdate(dt)
            if self.cell then
                if not currentCell or currentCell ~= self.cell then
                    currentCell = self.cell

                    core.sendGlobalEvent('BC_RecheckCell', { player = self, })
                    core.sendGlobalEvent('BC_RecheckTroupe', { player = self, })

                    local banEndTime = Performer.stats.bannedVenues[currentCell.name]
                    if banEndTime and core.getGameTime() < banEndTime then
                        -- Player is in a banned venue
                        startTrespassTimer()
                    else
                        -- Player is not in a banned venue
                        unbanFromVenue(currentCell.name)
                        bannedVenueTrespassTimer = nil
                    end
                end
            end
            if bannedVenueTrespassTimer then
                bannedVenueTrespassTimer = math.min(bannedVenueTrespassTimer + dt, bannedVenueTrespassDuration)
                if bannedVenueTrespassTimer >= bannedVenueTrespassDuration then
                    core.sendGlobalEvent('BC_Trespass', { player = self, })
                    bannedVenueTrespassTimer = 0
                end
            end

            if nearbyPlayingTimer > 0 then
                nearbyPlayingTimer = math.max(nearbyPlayingTimer - dt, 0)
                if nearbyPlayingTimer <= 0 then
                    music.nearbyPlaying = false
                end
            else
                music.nearbyPlaying = false
            end
        end,
        onMouseButtonPress = function()
            Editor.controllerMode = false
        end,
        onKeyPress = function(e)
            Editor.controllerMode = false
            if e.code == configPlayer.keybinds.kOpenInterface then
                if input.isAltPressed() then
                    togglePerformOverlay()
                elseif not Performer.playing then
                    setPerformerInfo()
                    Editor:onToggle()
                else
                    confirmModal(function()
                        core.sendGlobalEvent('BO_StopPerformance')
                    end)
                end
            elseif Editor.active and e.code == input.KEY.Space then
                Editor:togglePlayback(input.isCtrlPressed())
            end
        end,
        onControllerButtonPress = function(id)
            Editor.controllerMode = true
            local binding = configPlayer.keybinds.kOpenInterfaceGamepad
            local button = input.CONTROLLER_BUTTON[binding]
            if button and id == button then
                if input.isAltPressed() then
                    togglePerformOverlay()
                elseif not Performer.playing then
                    setPerformerInfo()
                    Editor:onToggle()
                else
                    confirmModal(function()
                        core.sendGlobalEvent('BO_StopPerformance')
                    end)
                end
            elseif Editor.active and id == input.CONTROLLER_BUTTON.Y then
                Editor:togglePlayback(input.isControllerButtonPressed(input.CONTROLLER_BUTTON.LeftShoulder))
            end
        end,
        onConsoleCommand = function(mode, command)
            -- Parse into tokens
            local tokens = {}
            for token in command:gmatch('%S+') do
                table.insert(tokens, token)
            end
            if string.lower(tokens[1]) == 'luabclevel' then
                if not tonumber(tokens[2]) then return end
                local skillStat = I.SkillFramework.getSkillStat('bardcraft')
                skillStat.base = tonumber(tokens[2])
                ui.showMessage('DEBUG: Set Bardcraft level to ' .. skillStat.base)
            elseif string.lower(tokens[1]) == 'luabcreset' then
                Performer:resetAllStats()

                if tokens[2] and string.lower(tokens[2]) == '--all' then
                    -- Send reset event to all troupe members
                    for _, actor in pairs(nearby.actors) do
                        if actor.type == types.NPC and Editor.troupeMembers[actor.id] then
                            actor:sendEvent('BC_ResetPerformer')
                        end
                    end
                end

                populateKnownSongs()
                ui.showMessage('DEBUG: Reset Bardcraft stats')
            elseif string.lower(tokens[1]) == 'luabcteachall' then
                Performer:teachAllSongs()
                ui.showMessage('DEBUG: Taught all songs')
            elseif string.lower(tokens[1]) == 'luabcdummylogs' then
                -- Populate performance logs with 25 dummy logs
                Performer.stats.performanceLogs = {}
                for i = 1, 25 do
                    local log = {}
                    -- Randomly pick type
                    if math.random() < 0.5 then
                        log.type = Song.PerformanceType.Tavern
                        -- Pick a tavern name
                        local taverns = Data.Venues.tavern
                        local tavernNames = {}
                        for name, _ in pairs(taverns) do
                            table.insert(tavernNames, name)
                        end
                        log.cell = tavernNames[math.random(1, #tavernNames)]
                        log.payment = math.random(50, 300)
                        log.tips = math.random(10, 100)
                    else
                        log.type = Song.PerformanceType.Street
                        -- Pick a city/town/village/metropolis
                        local streetTypes = { "metropolises", "cities", "towns", "villages" }
                        local which = streetTypes[math.random(1, #streetTypes)]
                        local list = Data.Venues.street[which]
                        log.cell = list[math.random(1, #list)]
                        log.payment = 0
                        log.tips = math.random(2, 20)
                    end
                    log.quality = math.random(0, 100)
                    log.disp = math.random(-25, 25)
                    log.oldDisp = math.random(0, 100)
                    log.newDisp = util.clamp(log.oldDisp + log.disp, 0, 100)
                    log.level = 100
                    log.levelGain = 0
                    -- rep: -2 to 2, correlate to quality
                    if log.quality >= 80 then
                        log.rep = 2
                    elseif log.quality >= 60 then
                        log.rep = 1
                    elseif log.quality >= 40 then
                        log.rep = 0
                    elseif log.quality >= 20 then
                        log.rep = -1
                    else
                        log.rep = -2
                    end
                    log.publicanComment = "test comment"
                    log.patronComments = {}
                    local numComments = math.random(1, 3)
                    for j = 1, numComments do
                        table.insert(log.patronComments, {
                            name = "Test NPC " .. j,
                            comment = "test patron comment " .. j
                        })
                    end
                    table.insert(Performer.stats.performanceLogs, log)
                end
                ui.showMessage('DEBUG: Populated 25 dummy logs')
            elseif string.lower(tokens[1]) == 'luabcreparse' then
                core.sendGlobalEvent('BC_ParseMidis', { force = true })
            elseif string.lower(tokens[1]) == 'luabcglobalclear' then
                core.sendGlobalEvent('BC_ClearGlobalData')
            elseif string.lower(tokens[1]) == 'luabccustomclear' then
                storage.playerSection('Bardcraft'):set('songs/custom', nil)
            end
        end,
        onMouseWheel = function(v, h)
            Editor:onMouseWheel(v, h)
        end,
        onFrame = function(dt)
            if setVfxNextFrame then
                setVfxNextFrame = false
                Performer:setSheatheVfx()
            end
            local camMode = camera.getMode()
            if camMode ~= lastCameraMode then
                lastCameraMode = camMode
                setVfxNextFrame = true
            end
            Editor:onFrame()
            Performer:onFrame()
            updateAmbientMusic()
            
            if performOverlay and practiceSong then
                performOverlayTick = practiceSong:secondsToTicks(Performer.musicTime)
                if performOverlayFadeInTimer > 0 then
                    performOverlayFadeInTimer = performOverlayFadeInTimer - core.getRealFrameDuration()
                    if performOverlayFadeInTimer <= 0 then
                        performOverlayFadeInTimer = 0
                    end
                end

                for id, time in pairs(performOverlayNoteFlashTimes) do
                    if time > 0 then
                        performOverlayNoteFlashTimes[id] = math.max(time - dt, 0)
                        local note = performOverlayNotesWrapper.layout.content[1].content[performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[id]]]
                        if note then
                            note.props.alpha = lerp((1.5 - performOverlayNoteFlashTimes[id]) / 1.5, 1, 0.4)
                            note.props.color = performOverlayNoteSuccess[id] and Editor.uiColors.DEFAULT or Editor.uiColors.DARK_RED
                        end
                        if performOverlayNoteFlashTimes[id] <= 0 then
                            performOverlayNoteFlashTimes[id] = nil
                        end
                    end
                end

                for id, time in pairs(performOverlayNoteFadeTimes) do
                    if time > 0 then
                        performOverlayNoteFadeTimes[id] = math.max(time - dt, 0)
                        if performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[id]] then
                            local note = performOverlayNotesWrapper.layout.content[1].content[performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[id]]]
                            if note then
                                note.props.alpha = lerp((0.5 - performOverlayNoteFadeTimes[id]) / 0.5, performOverlayNoteFadeAlphaStart[id], 0)
                                local startColor = performOverlayNoteSuccess[id] and Editor.uiColors.DEFAULT or Editor.uiColors.DARK_RED
                                local endColor = performOverlayNoteSuccess[id] and Editor.uiColors.GRAY or Editor.uiColors.DARK_RED_DESAT
                                note.props.color = lerpColor((0.5 - performOverlayNoteFadeTimes[id]) / 0.5, startColor, endColor)
                            end
                            if performOverlayNoteFadeTimes[id] <= 0 then
                                performOverlayNoteFadeTimes[id] = nil
                                performOverlayNoteFadeAlphaStart[id] = nil
                                performOverlayNoteSuccess[id] = nil
                            end
                        end
                    end
                end

                local currentShakeFactor = Performer.currentConfidence < 0.75 and (0.75 - Performer.currentConfidence) / 0.75 or 0
                -- Smooth shake factor
                if performOverlayLastShakeFactor == -1 then
                    performOverlayLastShakeFactor = currentShakeFactor
                end
                local shakeFactor = performOverlayLastShakeFactor * 0.99 + currentShakeFactor * 0.01
                performOverlayLastShakeFactor = shakeFactor

                for _, note in pairs(performOverlayNotesWrapper.layout.content[1].content) do
                    if note and note.props then
                        if not performOverlayNoteSuccess[note.props.index] then
                            note.props.position = util.vector2(note.props.position.x, note.props.baseY + shakeFactor * 5 * math.sin((core.getRealTime()) * 25 + note.props.index))
                        else
                            note.props.position = util.vector2(note.props.position.x, note.props.baseY)
                        end
                    end
                end

                local wrapperOpacity = lerp((performOverlayFadeInDuration - performOverlayFadeInTimer) / performOverlayFadeInDuration, 0, 1)
                local bgrOpacity = wrapperOpacity * performOverlayTargetBgrOpacity
                local noteOpacity = wrapperOpacity * performOverlayTargetNoteOpacity
                performOverlay.layout.props.alpha = wrapperOpacity
                performOverlayNotesWrapper.layout.props.alpha = noteOpacity
                performOverlay.layout.content['background'].props.alpha = bgrOpacity
                performOverlay.layout.content['centerline'].props.alpha = noteOpacity
                updatePerformOverlay()
            end
            if overlays.hurt.alpha > 0 then
                overlays.hurt.alpha = math.max(overlays.hurt.alpha - core.getRealFrameDuration(), 0)
                overlays.hurt.element.layout.props.alpha = overlays.hurt.alpha
                overlays.hurt.element:update()
            end
            if queuedMilestone and not Performer.playing then
                local message
                if queuedMilestone < 100 then
                    message = l10n('UI_LvlUp_Performance_' .. queuedMilestone / 10)
                else
                    local roll = math.random() * 100
                    if roll < 80 then
                        message = l10n('UI_LvlUp_Performance_10')
                    elseif roll < 99 then
                        message = l10n('UI_LvlUp_Performance_10_Rare' .. math.random(1, 5))
                    else
                        message = l10n('UI_LvlUp_Performance_10_UltraRare')
                    end
                end
                ui.showMessage(message)
                ambient.playSoundFile('sound\\Bardcraft\\lvl_up1.wav')
                queuedMilestone = nil
            end

            if overlays.tpFade.timer then
                overlays.tpFade.timer = math.min(overlays.tpFade.timer + core.getRealFrameDuration(), 3)
                overlays.tpFade.element.layout.props.alpha = 1 - (overlays.tpFade.timer / 3)
                if overlays.tpFade.timer >= 3 then
                    overlays.tpFade.timer = nil
                    overlays.tpFade.element.layout.props.alpha = 0
                end
                overlays.tpFade.element:update()
            end
        end,
    },
    eventHandlers = {
        BO_ConductorEvent = function(data)
            local success = Performer.handleConductorEvent(data)
            if data.type == 'PerformStart' then
                practiceSong = data.song
                performancePart = data.part.index
                setmetatable(practiceSong, Song)
                createPerformOverlay()
                performInstrument = types.Miscellaneous.record(data.item)
            elseif data.type == 'PerformStop' then
                destroyPerformOverlay()
                performInstrument = nil
            elseif data.type == 'NoteEvent' then
                if performOverlay and performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[data.id]] then
                    local content = performOverlayNotesWrapper.layout.content[1].content
                    local note = content[performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[data.id]]]
                    if note then
                        performOverlayNoteFlashTimes[data.id] = 1.5
                        performOverlayNoteSuccess[data.id] = success
                        --note.props.alpha = 1
                    end
                end
            elseif data.type == 'NoteEndEvent' then
                if performOverlay and performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[data.id]] then
                    local content = performOverlayNotesWrapper.layout.content[1].content
                    local note = content[performOverlayNoteIndexToContentId[performOverlayNoteIdToIndex[data.id]]]
                    if note then
                        performOverlayNoteFadeTimes[data.id] = 0.5
                        performOverlayNoteFadeAlphaStart[data.id] = note.props.alpha
                        if performOverlayNoteFlashTimes[data.id] then
                            performOverlayNoteFlashTimes[data.id] = nil
                        end
                    end
                end
            elseif data.type == 'LyricEvent' then
                if data.newPhrase then
                    setPerformOverlayLyricPhrase(data.index)
                else
                    onPerformOverlayLyricSyllable(data.index)
                end
            end
        end,
        BC_GainConfidence = function(data)
            local message
            if data.newConfidence > data.oldConfidence then
                message = l10n('UI_Msg_Confidence_Up')
            elseif data.newConfidence < data.oldConfidence then
                message = l10n('UI_Msg_Confidence_Down')
            else
                message = l10n('UI_Msg_Confidence_NoChange')
            end
            ui.showMessage(message:gsub('%%{songTitle}', data.songTitle):gsub('%%{partTitle}', data.partTitle):gsub('%%{confidence}', string.format('%.2f', data.newConfidence * 100)))
        end,
        BC_PracticeEfficiency = function(data)
            if configGlobal.options.bEnablePracticeEfficiency == true then
                local message = l10n('UI_Msg_PracticeEfficiency'):gsub('%%{efficiency}', string.format('%d', data.efficiency * 100))
                ui.showMessage(message)
            end
            setPerformerInfo()
        end,
        BC_PerformerInfo = function(data)
            performersInfo[data.actor.id] = data.stats
            Editor.performersInfo = performersInfo
        end,
        BC_PerformanceEvent = function(data)
            if data.type == 'ThrownItem' then
                ui.showMessage(data.message)
                if data.damage > 0 then
                    doHurt(data.damage)
                else
                    playSwoosh()
                end
            elseif data.type == 'Gold' then
                local message = data.message:gsub('%%{amount}', data.amount)
                ui.showMessage(message)
                ambient.playSoundFile(data.sound)
            elseif data.type == 'Flavor' then
                ui.showMessage(data.message)
            end
        end,
        BC_SpeechcraftXP = function(data)
            local options = {
                skillGain = data.amount,
                useType = I.SkillProgression.SKILL_USE_TYPES.Speechcraft_Success,
            }
            I.SkillProgression.skillUsed('speechcraft', options)
        end,
        BC_PerformanceLog = function(data)
            data.oldRep = Performer.stats.reputation
            Performer:modReputation(data.rep)
            data.newRep = Performer.stats.reputation
            if data.kickedOut then
                data.banEndTime = banFromVenue(data.cell, data.gameTime, 1)
            end
            Editor:showPerformanceLog(data)

            if data.type == Song.PerformanceType.Tavern then
                local crowdSound
                if data.quality >= 90 and data.density > 5 then
                    crowdSound = 'clap1.wav'
                elseif data.quality >= 70 then
                    crowdSound = 'clap3.wav'
                elseif data.quality >= 50 then
                    crowdSound = 'clap-polite.wav'
                elseif data.quality < 30 then
                    crowdSound = 'boo' .. math.random(1, 4) .. '.wav'
                end

                if crowdSound then
                    ambient.playSoundFile('sound\\Bardcraft\\crowd\\' .. crowdSound)
                end
            end
            table.insert(Performer.stats.performanceLogs, data)
        end,
        BC_StartPerformanceSuccess = function(data)
            Editor:onToggle()
            self.type.setStance(self, self.type.STANCE.Nothing)
            if configPlayer.options.bPrecacheSamples then
                precacheSongSamples(data)
            end
        end,
        BC_StartPerformanceFail = function(data)
            ui.showMessage(data.reason)
        end,
        BC_FinalizeDraft = function(data)
            Performer:teachSong(data.song)
            ui.showMessage(l10n('UI_Msg_FinalizedDraft'):gsub('%%{songTitle}', data.song.title))
            ambient.playSoundFile('sound\\Bardcraft\\finalize_draft.wav')
        end,
        BC_SheatheInstrument = function(data)
            ambient.playSoundFile('sound\\Bardcraft\\equip.wav')
            Performer:setSheathedInstrument(data.recordId)
        end,
        BC_BookReadResult = function(data)
            if data.success then
                local id = data.id
                local songBook = Data.SongBooks[id]
                if not songBook then return end

                local songBookPoolSourceFiles = {}
                local seen = {}

                if songBook.pools and #songBook.pools > 0 then
                    for _, poolId in ipairs(songBook.pools) do
                        local pool = Data.SongPools[poolId]
                        if pool and #pool > 0 then
                            for _, songIdInPool in ipairs(pool) do
                                local sourceFile = Data.SongIds[songIdInPool]
                                if sourceFile and not seen[sourceFile] then
                                    table.insert(songBookPoolSourceFiles, sourceFile)
                                    seen[sourceFile] = true
                                end
                            end
                        end
                    end
                elseif songBook.songs and #songBook.songs > 0 then
                    for _, songId in ipairs(songBook.songs) do
                        local sourceFile = Data.SongIds[songId]
                        if sourceFile and not seen[sourceFile] then
                            table.insert(songBookPoolSourceFiles, sourceFile)
                            seen[sourceFile] = true
                        end
                    end
                end

                if #songBookPoolSourceFiles == 0 then return end

                local song = getRandomSong(songBookPoolSourceFiles)
                local success = false
                success = song and Performer:teachSong(song) or false

                if success then
                    ui.showMessage(l10n('UI_Msg_LearnSong_Success'):gsub('%%{songTitle}', song.title))
                    ambient.playSoundFile('Sound\\fx\\inter\\levelUP.wav')
                elseif song then
                    ui.showMessage(l10n('UI_Msg_LearnSong_Fail'):gsub('%%{songTitle}', song.title))
                end
            else
                ui.showMessage(l10n('UI_Msg_BookReadFail'))
            end
        end,
        BC_MusicBoxActivate = function(data)
            local object = data.object
            Editor:playerChoiceModal(self, l10n('UI_MusicBox'), {
                {
                    text = l10n('UI_MusicBox_TogglePlaying'),
                    callback = function()
                        local musicBox = Data.MusicBoxes[object.recordId]
                        if not musicBox then return end

                        local musicBoxPoolSourceFiles = {}
                        local seen = {}

                        if musicBox.pools and #musicBox.pools > 0 then
                            for _, poolId in ipairs(musicBox.pools) do
                                local pool = Data.SongPools[poolId]
                                if pool and #pool > 0 then
                                    for _, songIdInPool in ipairs(pool) do
                                        local sourceFile = Data.SongIds[songIdInPool]
                                        if sourceFile and not seen[sourceFile] then
                                            table.insert(musicBoxPoolSourceFiles, sourceFile)
                                            seen[sourceFile] = true
                                        end
                                    end
                                end
                            end
                        elseif musicBox.songs and #musicBox.songs > 0 then
                            -- This music box has its own list of songs
                            for _, songId in ipairs(musicBox.songs) do
                                local sourceFile = Data.SongIds[songId]
                                if sourceFile and not seen[sourceFile] then
                                    table.insert(musicBoxPoolSourceFiles, sourceFile)
                                    seen[sourceFile] = true
                                end
                            end
                        end
                        
                        if #musicBoxPoolSourceFiles == 0 then return end -- No songs found to pick from

                        local song = getRandomSong(musicBoxPoolSourceFiles)
                        
                        if song then -- Check if getRandomSong found a suitable song
                            object:sendEvent('BC_MusicBoxToggle', { actor = self, prefSong = song.sourceFile, })
                        end
                    end
                },
                {
                    text = l10n('UI_MusicBox_PickUp'),
                    callback = function()
                        object:sendEvent('BC_MusicBoxPickup', { actor = self, })
                        ambient.playSoundFile('Sound\\fx\\item\\item.wav')
                    end,
                }
            }, data.songName)
        end,
        BC_NearbyPlaying = function()
            nearbyPlayingTimer = 10
            music.nearbyPlaying = true
        end,
        BC_TeachSong = function(data)
            local song = data.song
            if song then
                local success = Performer:teachSong(song)
                if success then
                    ui.showMessage(l10n('UI_Msg_LearnSong_Success'):gsub('%%{songTitle}', song.title))
                    ambient.playSoundFile('Sound\\fx\\inter\\levelUP.wav')
                end
            end
        end,
        BC_ForgetSong = function(data)
            local id = data.id
            if id then
                Performer:forgetSong(id)
            end
            -- Inform all troupe members
            for _, actor in pairs(nearby.actors) do
                if actor.type == types.NPC and Editor.troupeMembers[actor.id] then
                    actor:sendEvent('BC_ForgetSong', { id = id })
                end
            end
        end,
        BC_TroupeStatus = function(data)
            local members = {}
            for _, member in ipairs(data.members) do
                members[member.id] = true
            end
            Editor.troupeMembers = members
            if Editor.troupeSize ~= #data.members and Performer.playing then
                core.sendGlobalEvent('BO_StopPerformance')
                Editor.performancePartAssignments = {}
            end
            Editor.troupeSize = #data.members
        end,
        BC_TPFadeIn = function()
            overlays.tpFade.timer = 0
            ambient.playSoundFile('sound\\Bardcraft\\gohome.wav')
        end,
        BC_MidisParsed = function()
            populateKnownSongs()
            setPerformerInfo()
        end,
        BC_ToggleUI = function()
            I.UI.setMode(nil)
            setPerformerInfo()
            Editor:onToggle()
        end,
        UiModeChanged = function(data)
            Performer:verifySheathedInstrument()
            verifyPerformInstrument()
            if data.newMode == nil then
                Editor:onUINil()
                if data.oldMode == 'Dialogue' then
                    core.sendGlobalEvent('BC_RecheckTroupe', { player = self, })
                end
            elseif data.newMode == 'Scroll' or data.newMode == 'Book' then
                local book = data.arg
                local id = book.recordId
                if Data.SongBooks[id] then
                    core.sendGlobalEvent('BC_BookRead', { player = self, book = book })
                end
            end
            performOverlayTargetBgrOpacity = configPlayer.options.fPerformOverlayBgrOpacity
            performOverlayTargetNoteOpacity = configPlayer.options.fPerformOverlayNoteOpacity
        end,
    }
}