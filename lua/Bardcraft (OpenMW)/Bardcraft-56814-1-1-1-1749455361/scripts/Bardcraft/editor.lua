--[[
-- editor.lua
-- ATTENTION: This file, despite its name, contains all of the mod's GUI logic, not just the editor.
-- Below lies code written by someone trying to meet a one-month deadline, not to ensure any semblance
-- of readability, maintainability, organization, or even remotely idiomatic Lua.
-- 
-- Don't use this as a reference for anything UI-related you want to do in your own mods.
-- You've been warned :)
]]

local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local util = require('openmw.util')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local calendar = require('openmw_aux.calendar')
local self = require('openmw.self')

local l10n = core.l10n('Bardcraft')

local luaxp = require('scripts.Bardcraft.util.luaxp')
local Song = require('scripts.Bardcraft.util.song').Song
local Instruments = require('scripts.Bardcraft.instruments').Instruments
local Data = require('scripts.Bardcraft.data')

local configPlayer = require('scripts.Bardcraft.config.player')
local configGlobal = require('scripts.Bardcraft.config.global')

local Editor = {}

Editor.STATE = {
    PERFORMANCE = 0,
    SONG = 1,
    STATS = 2,
    MODAL = 3,
}

Editor.ZOOM_LEVELS = {
    [1] = 1/8,
    [2] = 1/4,
    [3] = 1/2,
    [4] = 1.0,
    [5] = 2.0,
    [6] = 4.0,
    [7] = 8.0,
}

Editor.SNAP_LEVELS = {
    [1] = 1/32,
    [2] = 1/16,
    [3] = 1/8,
    [4] = 1/6,
    [5] = 1/4,
    [6] = 1/3,
    [7] = 1/2,
    [8] = 1.0,
    [9] = 2.0,
    [10] = 4.0,
}

Editor.SONGS_MODE = {
    PRESET = "songs/preset",
    CUSTOM = "songs/custom"
}

Editor.active = false
Editor.song = nil
Editor.songs = nil
Editor.songsMode = Editor.SONGS_MODE.CUSTOM
Editor.state = nil
Editor.noteMap = nil
Editor.snap = true
Editor.snapLevel = 5
Editor.zoomLevel = 4
Editor.activePart = nil
Editor.partsPlaying = {}

Editor.controllerMode = false
Editor.bookmarkedSongs = {}
Editor.hideSongInfo = false

Editor.deletePartIndex = nil
Editor.deletePartClickCount = 0
Editor.deletePartConfirmTimer = 0
Editor.deletePartConfirmResetTime = 1

Editor.windowXOff = 20
Editor.windowYOff = 200
Editor.windowCaptionHeight = 20
Editor.windowTabsHeight = 32
Editor.windowLeftBoxXMult = 1 / 16
Editor.windowLeftBoxXSize = 150
Editor.windowMiddleBoxXMult = 1 / 16
Editor.windowMiddleBoxXSize = 150

Editor.uiColors = {
    DEFAULT = util.color.rgb(202 / 255, 165 / 255, 96 / 255),
    DEFAULT_LIGHT = util.color.rgb(223 / 255, 201 / 255, 159 / 255),
    WHITE = util.color.rgb(1, 1, 1),
    GRAY = util.color.rgb(0.5, 0.5, 0.5),
    BLACK = util.color.rgb(0, 0, 0),
    CYAN = util.color.rgb(0, 1, 1),
    YELLOW = util.color.rgb(1, 1, 0),
    RED = util.color.rgb(1, 0, 0),
    DARK_RED = util.color.rgb(0.5, 0, 0),
    RED_DESAT = util.color.rgb(0.7, 0.3, 0.3),
    DARK_RED_DESAT = util.color.rgb(0.3, 0.05, 0.05),
    BOOK_HEADER = util.color.rgb(0.3, 0.03, 0.03),
    BOOK_TEXT = util.color.rgb(0.05, 0.05, 0.05),
    BOOK_TEXT_LIGHT = util.color.rgb(80 / 255, 64 / 255, 38 / 255),
}

Editor.noteColor = Editor.uiColors.DEFAULT
Editor.backgroundColor = Editor.uiColors.WHITE
Editor.keyboardColor = Editor.uiColors.WHITE
Editor.keyboardWhiteTextColor = Editor.uiColors.BLACK
Editor.keyboardBlackTextColor = Editor.uiColors.WHITE
Editor.beatLineColor = Editor.uiColors.DEFAULT_LIGHT
Editor.barLineColor = Editor.uiColors.DEFAULT_LIGHT
Editor.loopStartLineColor = Editor.uiColors.CYAN
Editor.loopEndLineColor = Editor.uiColors.CYAN
Editor.playbackLineColor = Editor.uiColors.YELLOW

local function createPaddingTemplate(size)
    size = util.vector2(1, 1) * size
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = size,
                },
            },
            {
                external = { slot = true },
                props = {
                    position = size,
                    relativeSize = util.vector2(1, 1),
                },
            },
            {
                props = {
                    position = size,
                    relativePosition = util.vector2(1, 1),
                    size = size,
                },
            },
        }
    }
end

local headerTextures = {
    [1] = ui.texture {
        path = 'textures/menu_head_block_top_left_corner.dds',
    },
    [2] = ui.texture {
        path = 'textures/menu_head_block_top.dds',
    },
    [3] = ui.texture {
        path = 'textures/menu_head_block_top_right_corner.dds',
    },
    [4] = ui.texture {
        path = 'textures/menu_head_block_left.dds',
    },
    [5] = ui.texture {
        path = 'textures/menu_head_block_middle.dds',
    },
    [6] = ui.texture {
        path = 'textures/menu_head_block_right.dds',
    },
    [7] = ui.texture {
        path = 'textures/menu_head_block_bottom_left_corner.dds',
    },
    [8] = ui.texture {
        path = 'textures/menu_head_block_bottom.dds',
    },
    [9] = ui.texture {
        path = 'textures/menu_head_block_bottom_right_corner.dds',
    },
}

local function headerImage(i, tile, size)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[i],
            size = size or util.vector2(0, 0),
            tileH = tile,
            tileV = false,
        },
        external = {
            grow = 1,
            stretch = 1,
        }
    }
end

local headerSection = {
    type = ui.TYPE.Flex,
    props = {
        horizontal = true,
    },
    external = {
        grow = 1,
        stretch = 1,
    },
    content = ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(2, Editor.windowCaptionHeight),
            },
            content = ui.content {
                headerImage(1, false, util.vector2(2, 2)),
                headerImage(4, false, util.vector2(2, 16)),
                headerImage(7, false, util.vector2(2, 2)),
            }
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(0, Editor.windowCaptionHeight),
            },
            content = ui.content {
                headerImage(2, true, util.vector2(0, 2)),
                headerImage(5, true, util.vector2(0, 16)),
                headerImage(8, true, util.vector2(0, 2)),
            },
            external = {
                grow = 1,
                stretch = 1,
            }
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(2, Editor.windowCaptionHeight),
            },
            content = ui.content {
                headerImage(3, false, util.vector2(2, 2)),
                headerImage(6, false, util.vector2(2, 16)),
                headerImage(9, false, util.vector2(2, 2)),
            }
        }
    }
}

local function uiButton(text, active, onClick)
    return {
        template = I.MWUI.templates.boxThick,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textColor = active and Editor.uiColors.WHITE or Editor.uiColors.DEFAULT,
                        },
                    }
                },
            },
        },
        events = {
            mouseClick = async:callback(function()
                if onClick then
                    onClick()
                end
            end),
        }
    }
end

local wrapperElement = nil
local modalElement = nil
local screenSize = nil
local playingNoteSound = nil

local onModalDecline = nil

local scrollableFocused = nil

function Editor:getScaleTexture()
    if not self.song then return end
    local modeName = Song.Mode[self.song.scale.mode]
    return ui.texture {
        path = 'textures/bardcraft/ui/scales/' .. modeName .. '.dds',
        size = util.vector2(4, 192),
    }
end

local textFocused = false

local DragType = {
    NONE = 0,
    RESIZE_LEFT = 1,
    RESIZE_RIGHT = 2,
    MOVE = 3,
}

local pianoRoll = {
    scrollX = 0,
    scrollY = 0,
    scrollXMax = 0,
    scrollYMax = 0,
    scrollLastPopulateX = 0,
    scrollPopulateWindowSize = 400,
    focused = false,
    wrapper = nil,
    keyboardWrapper = nil,
    editorWrapper = nil,
    editorMarkersWrapper = nil,
    element = nil,
    activeNote = nil,
    lastNoteSize = 0,
    dragStart = nil,
    dragOffset = nil,
    dragType = DragType.NONE,
    dragLastNoteSize = 0,
}

Editor.playback = false
local playbackStartScrollX = 0

local function getNoteSoundPath(note)
    if not Editor.activePart then return '' end
    local profile = Song.getInstrumentProfile(Editor.activePart.instrument)
    local filePath = 'sound\\Bardcraft\\samples\\' .. profile.name .. '\\' .. profile.name .. '_' .. Song.noteNumberToName(note) .. '.flac'
    return filePath
end

local function getNoteVolume()
    if not Editor.activePart then return 0 end
    local profile = Song.getInstrumentProfile(Editor.activePart.instrument)
    if not profile or not profile.volume then return 0 end
    return profile.volume
end

local function playNoteSound(note)
    local path = getNoteSoundPath(note)
    ambient.playSoundFile(path, { volume = getNoteVolume() })
    return path
end

local function stopNoteSound(note)
    ambient.stopSoundFile(getNoteSoundPath(note))
end

--[[local ZoomLevels = {
    [1] = 1.0,
    [2] = 2.0,
    [3] = 4.0,
}]]

-- This is a necessary optimization so that we don't have to render an image for each beat line (insanely taxing on performance)
local uiWholeNoteWidth = 256

local function calcBeatWidth(denominator)
    return uiWholeNoteWidth / denominator * Editor.ZOOM_LEVELS[Editor.zoomLevel]
end

local function calcBarWidth()
    if not Editor.song then return 0 end
    return calcBeatWidth(Editor.song.timeSig[2]) * Editor.song.timeSig[1]
end

local function calcOctaveHeight()
    return 16 * 12
end

local function calcOuterWindowWidth()
    if not screenSize then return 0 end
    local availableWidth = screenSize.x - Editor.windowXOff -- Subtract padding or margins
    return math.max(availableWidth, 0)
end

local function calcOuterWindowHeight()
    if not screenSize then return 0 end
    local availableHeight = screenSize.y - Editor.windowYOff -- Subtract padding or margins
    return math.max(availableHeight, 0)
end

local function calcContentWidth()
    return calcOuterWindowWidth() - 16
end

local function calcContentHeight()
    return calcOuterWindowHeight() - (Editor.windowCaptionHeight + Editor.windowTabsHeight) - 8
end

local function calcPianoRollWrapperSize()
    if not screenSize then return util.vector2(0, 0) end
    local width = calcOuterWindowWidth() - ((screenSize.x * Editor.windowLeftBoxXMult + Editor.windowLeftBoxXSize) + (screenSize.x * Editor.windowMiddleBoxXMult + Editor.windowMiddleBoxXSize)) - 8
    local height = calcContentHeight()
    return util.vector2(width, height)
end

local function calcPianoRollEditorWrapperSize()
    local wrapperSize = calcPianoRollWrapperSize()
    return util.vector2(wrapperSize.x - 96, wrapperSize.y)
end

local function calcPianoRollEditorWidth()
    if not Editor.song then return 0 end
    return Editor.song.lengthBars * calcBarWidth()
end

local function calcPianoRollEditorHeight()
    return calcOctaveHeight() * 128 / 12
end

local function calcSnapFactor()
    if not Editor.song or not Editor.snap then return 1 end
    return Editor.song.resolution * Editor.SNAP_LEVELS[Editor.snapLevel] * (4 / Editor.song.timeSig[2])
end

local function editorOffsetToRealOffset(offset)
    return offset - util.vector2(pianoRoll.scrollX, pianoRoll.scrollY)
end

local function realOffsetToNote(offset)
    -- Will return pitch and tick
    local noteIndex = math.floor((128 - (offset.y / 16)))
    local beat = offset.x / calcBeatWidth(Editor.song.timeSig[2])
    local tick = math.floor(beat * (4 / Editor.song.timeSig[2]) * Editor.song.resolution) + 1
    return noteIndex, tick
end

local notesLayout = {}
local noteNames = { "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B" }
for i = 127, 0, -1 do
    local octave = math.floor(i / 12) - 1
    local noteName = noteNames[(i % 12) + 1]
    local isBlackKey = noteName:find("b") ~= nil
    local noteY = (128 - i) * 16
    table.insert(notesLayout, {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(96, 16),
            position = util.vector2(0, noteY),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = noteName .. octave,
                    textColor = isBlackKey and Editor.keyboardBlackTextColor or Editor.keyboardWhiteTextColor,
                    anchor = util.vector2(0, 0.5),
                    relativePosition = util.vector2(0, 0.5),
                },
            },
        }
    })
end

local function updatePianoRollKeyboardLabels()
    local highestNote = 128 - math.floor(-pianoRoll.scrollY / 16)
    local lowestNote = math.floor(util.clamp(highestNote - (calcPianoRollEditorWrapperSize().y / 16), 1, 128))
    local notesToShow = {table.unpack(notesLayout, (129 - highestNote), (129 - lowestNote))}
    pianoRoll.keyboardWrapper.layout.content[1].content[2].content = ui.content(notesToShow)
    pianoRoll.keyboardWrapper.layout.content[1].content[2].props.position = util.vector2(0, 16 * (128 - highestNote))
    pianoRoll.keyboardWrapper:update()
end

local function updatePianoRollBarNumberLabels()
    -- First, calculate which bar lines are visible
    local barWidth = calcBarWidth()
    local editorSize = calcPianoRollEditorWrapperSize()
    local barCount = math.floor(editorSize.x / barWidth) + 1
    local barLines = {
        type = ui.TYPE.Widget,
        props = {
            size = editorSize,
        },
        content = ui.content {},
    }
    for i = 0, barCount do
        local xOffset = i * barWidth + pianoRoll.scrollX % barWidth
        local barNumber = i + math.floor((-pianoRoll.scrollX - (1 * Editor.ZOOM_LEVELS[Editor.zoomLevel])) / barWidth) + 2
        table.insert(barLines.content, {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(96, 16),
                position = util.vector2(xOffset + 4, 0),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = tostring(barNumber),
                        textSize = 16,
                        textColor = Editor.uiColors.DEFAULT_LIGHT,
                    },
                },
            }
        })
    end
    pianoRoll.editorMarkersWrapper.layout.content[2] = barLines
end

local editorOverlay, editorMarkers, editorNotes = nil, nil, nil

local function updatePianoRoll()
    if not Editor.song then return end
    if not pianoRoll.wrapper or not pianoRoll.editorWrapper or not pianoRoll.editorWrapper.layout or not pianoRoll.editorMarkersWrapper or not pianoRoll.editorMarkersWrapper.layout then return end
    local barWidth = calcBarWidth()
    local octaveHeight = calcOctaveHeight()
    pianoRoll.keyboardWrapper.layout.content[1].props.position = util.vector2(0, pianoRoll.scrollY)
    updatePianoRollKeyboardLabels()
    updatePianoRollBarNumberLabels()
    
    editorOverlay.props.position = util.vector2(pianoRoll.scrollX % barWidth - barWidth, pianoRoll.scrollY % octaveHeight - octaveHeight)
    editorMarkers.props.position = util.vector2(pianoRoll.scrollX, 0)
    editorNotes.props.position = util.vector2(pianoRoll.scrollX, pianoRoll.scrollY)
    pianoRoll.editorMarkersWrapper:update()
    pianoRoll.editorWrapper:update()
end

local uiTextures = {
    pianoRollKeys = ui.texture {
        path = 'textures/Bardcraft/ui/pianoroll-h.dds',
        offset = util.vector2(0, 0),
        size = util.vector2(62, 192),
    },
    pianoRollRows = ui.texture {
        path = 'textures/Bardcraft/ui/pianoroll-h.dds',
        offset = util.vector2(96, 0),
        size = util.vector2(4, 192),
    },
    pianoRollBeatLines = {},
    pianoRollNote = ui.texture {
        path = 'textures/Bardcraft/ui/pianoroll-note.dds',
    }
}

for i = 0, 7 do
    local denom = math.pow(2, i)
    local yOffset = math.log(denom) / math.log(2)
    uiTextures.pianoRollBeatLines[denom] = ui.texture {
        path = 'textures/Bardcraft/ui/pianoroll-v.dds',
        offset = util.vector2(0, yOffset),
        size = util.vector2(calcBeatWidth(denom), 1),
    }
end

local addNote, removeNote, initNotes, saveNotes
local addDraft, saveDraft, setDraft
local getSongTab, getPerformanceTab, getStatsTab
local getMainContent, setMainContent

local uiTemplates

uiTemplates = {
    wrapper = function() 
        return {
            layer = 'Windows',
            template = I.MWUI.templates.boxTransparentThick,
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = false,
                        size = util.vector2(0, 0),
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                                autoSize = false,
                                relativeSize = util.vector2(1, 0),
                                size = util.vector2(0, Editor.windowCaptionHeight)
                            },
                            content = ui.content { 
                                headerSection, 
                                {
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = '   ' .. l10n('UI_Title') .. '   ',
                                    }
                                },
                                headerSection,
                            },
                        },
                        {
                            template = I.MWUI.templates.bordersThick,
                            external = {
                                grow = 1,
                                stretch = 1,
                            },
                            content = ui.content {
                                {
                                    type = ui.TYPE.Flex,
                                    name = 'mainContent',
                                    props = {
                                        autoSize = false,
                                        relativeSize = util.vector2(1, 1),
                                    },
                                    content = ui.content {
                                        {
                                            template = I.MWUI.templates.borders,
                                            props = {
                                                size = util.vector2(0, Editor.windowTabsHeight),
                                                relativeSize = util.vector2(1, 0),
                                            },
                                            content = ui.content {
                                                {
                                                    type = ui.TYPE.Flex,
                                                    props = {
                                                        horizontal = true,
                                                        autoSize = false,
                                                        size = util.vector2(0, Editor.windowTabsHeight),
                                                        relativeSize = util.vector2(1, 0),
                                                    },
                                                    external = {
                                                        grow = 1,
                                                        stretch = 1,
                                                    },
                                                    content = ui.content {
                                                        uiButton(l10n('UI_Tab_Performance'), Editor.state == Editor.STATE.PERFORMANCE, function()
                                                            Editor:setState(Editor.STATE.PERFORMANCE)
                                                        end),
                                                        uiButton(l10n('UI_Tab_Stats'), Editor.state == Editor.STATE.STATS, function()
                                                            Editor:setState(Editor.STATE.STATS)
                                                        end),
                                                        uiButton(l10n('UI_Tab_Songwriting'), Editor.state == Editor.STATE.SONG, function()
                                                            Editor:setState(Editor.STATE.SONG)
                                                        end),
                                                    }
                                                },
                                            },
                                        },
                                    }
                                },
                            }
                        },
                    }
                }
            },
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
            },
            events = {
                keyPress = async:callback(function(e)
                end),
            }
        } 
    end,
    songManager = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.borders,
                props = {
                    size = util.vector2(ui.screenSize().x * Editor.windowLeftBoxXMult + Editor.windowLeftBoxXSize, 0),
                    relativeSize = util.vector2(0, 1),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = false,
                            relativeSize = util.vector2(1, 1),
                            size = util.vector2(0, -32),
                            grow = 1,
                            stretch = 1
                        },
                        content = ui.content {},
                    },
                },
            },
            {
                template = I.MWUI.templates.borders,
                props = {
                    size = util.vector2(ui.screenSize().x * Editor.windowMiddleBoxXMult + Editor.windowMiddleBoxXSize, 0),
                    relativeSize = util.vector2(0, 1),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            autoSize = false,
                            relativeSize = util.vector2(1, 1),
                        },
                        content = ui.content {
                            createPaddingTemplate(4),
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    autoSize = false,
                                    grow = 1,
                                    stretch = 1
                                },
                                external = {
                                    grow = 1,
                                    stretch = 1,
                                },
                                content = ui.content {},
                            },
                            createPaddingTemplate(4),
                        },
                    },
                },
            },
            {
                template = I.MWUI.templates.borders,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
                content = ui.content {
                    -- {
                    --     type = ui.TYPE.Flex,
                    --     name = 'pianoRoll',
                    --     props = {
                    --         horizontal = true,
                    --         autoSize = true
                    --     },
                    --     content = ui.content {},
                    -- },
                },
                events = {
                    focusGain = async:callback(function()
                        pianoRoll.focused = true
                    end),
                    focusLoss = async:callback(function()
                        pianoRoll.focused = false
                    end),
                }
            }
        }
    },
    baseTab = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.borders,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = false,
                            relativeSize = util.vector2(1, 1),
                            grow = 1,
                            stretch = 1,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {},
                    },
                },
            },
        }
    },
    textEdit = function(default, height, callback)
        return {
            template = I.MWUI.templates.borders,
            props = {
                size = util.vector2(0, height),
            },
            external = {
                grow = 1,
                stretch = 1,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textEditLine,
                    props = {
                        text = default,
                        textAlignV = ui.ALIGNMENT.Center,
                        relativeSize = util.vector2(1, 1),
                    },
                    events = {
                        textChanged = async:callback(function(text, self)
                            if callback then
                                callback(text, self)
                            end
                        end),
                        focusGain = async:callback(function()
                            textFocused = true
                        end),
                    }
                }
            },
        }
    end,
    labeledTextEdit = function(label, default, height, callback)
        return {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                size = util.vector2(0, height),
                relativeSize = util.vector2(1, 0),
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = label,
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
                {
                    template = createPaddingTemplate(4),
                },
                uiTemplates.textEdit(default, height, callback),
            },
        }
    end,
    select = function(items, index, addSize, localize, height, callback)
        local leftArrow = ui.texture {
            path = 'textures/omw_menu_scroll_left.dds',
        }
        local rightArrow = ui.texture {
            path = 'textures/omw_menu_scroll_right.dds',
        }
        local itemCount = #items

        local function getLabel()
            local label = items[index]
            if type(label) == 'number' then
                -- Round to 8 decimal places
                label = math.floor(label * 1e8 + 0.5) / 1e8
            end
            if localize then
                label = l10n('UI_' .. label)
            end
            return tostring(label)
        end

        local label = getLabel()
        local labelColor = nil
        if index == nil then
            labelColor = util.color.rgb(1, 0, 0)
        end
        local element = ui.create {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                size = util.vector2(addSize, height),
                arrange = ui.ALIGNMENT.Center,
                selected = index,
            },
            external = {
                grow = 1,
                stretch = 1,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = leftArrow,
                        size = util.vector2(1, 1) * 12,
                    },
                    events = {},
                },
                { template = I.MWUI.templates.interval },
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = label,
                        textColor = labelColor,
                    },
                    external = {
                        grow = 1,
                    },
                },
                { template = I.MWUI.templates.interval },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = rightArrow,
                        size = util.vector2(1, 1) * 12,
                    },
                    events = {},
                },
            },
        }

        local function update()
            element.layout.props.selected = index
            element.layout.content[3].props.text = getLabel()
            callback(index)
            element:update()
        end

        element.layout.content[1].events.mouseClick = async:callback(function()
            index = (index - 2) % itemCount + 1
            update()
        end)
        element.layout.content[5].events.mouseClick = async:callback(function()
            index = (index) % itemCount + 1
            update()
        end)

        return element
    end,
    labeledSelect = function(label, items, index, addSize, localize, height, callback)
        return {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                size = util.vector2(0, height),
                relativeSize = util.vector2(1, 0),
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = label,
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
                {
                    template = createPaddingTemplate(4),
                },
                uiTemplates.select(items, index, addSize, localize, height, callback),
            },
        }
    end,
    checkbox = function(value, trueLabel, falseLabel, onChange)
        local function getLabel()
            return l10n('UI_' .. (value and trueLabel or falseLabel))
        end

        local element = ui.create {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = getLabel(),
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
            },
            events = {
            }
        }

        element.layout.events.mouseClick = async:callback(function()
            value = not value
            element.layout.content[1].props.text = getLabel()
            if onChange then
                onChange(value)
            end
            element:update()
        end)
        return element
    end,
    partDisplay = function(part)
        local function getInstruments()
            local instruments = {}
            for k, _ in pairs(Instruments) do
                table.insert(instruments, k)
            end
            return instruments
        end

        local instruments = getInstruments()

        local function indexOf(table, i)
            for k, v in ipairs(table) do
                if v == i then
                    return k
                end
            end
            return nil
        end

        local function getInstrumentName()
            return Song.getInstrumentProfile(part.instrument).name
        end

        local partDisplay = ui.create {
            template = (part == Editor.activePart) and I.MWUI.templates.bordersThick or I.MWUI.templates.borders,
            props = {
                size = util.vector2(0, 48),
            },
            external = {
                stretch = 1,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = false,
                        size = util.vector2(0, 44),
                        relativeSize = util.vector2(1, 0),
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Image,
                            props = {
                                resource = ui.texture { path = Instruments[getInstrumentName()].icon },
                                size = util.vector2(40, 40),
                            },
                            events = {}
                        },
                        {
                            type = ui.TYPE.Flex,
                            external = {
                                grow = 1,
                                stretch = 1,
                            },
                            content = ui.content {}
                        },
                        {
                            template = I.MWUI.templates.borders,
                            props = {
                                size = util.vector2(24, 0),
                            },
                            external = {
                                stretch = 1,
                            },
                            content = ui.content {
                                {
                                    type = ui.TYPE.Image,
                                    props = {
                                        anchor = util.vector2(0.5, 0.5),
                                        relativePosition = util.vector2(0.5, 0.5),
                                        resource = ui.texture { path = 'textures/Bardcraft/ui/' .. (Editor.partsPlaying[part.index] and 'part-vol-on.dds' or 'part-vol-off.dds') },
                                        color = Editor.uiColors.DEFAULT,
                                        alpha = Editor.partsPlaying[part.index] and 1 or 0.5,
                                        size = util.vector2(16, 16),
                                    }
                                }
                            },
                            events = {}
                        },
                        {
                            template = I.MWUI.templates.borders,
                            props = {
                                size = util.vector2(24, 0),
                            },
                            external = {
                                stretch = 1,
                            },
                            content = ui.content {
                                {
                                    type = ui.TYPE.Image,
                                    props = {
                                        anchor = util.vector2(0.5, 0.5),
                                        relativePosition = util.vector2(0.5, 0.5),
                                        resource = ui.texture { path = 'textures/Bardcraft/ui/part-delete.dds' },
                                        color = Editor.uiColors.RED_DESAT,
                                        size = util.vector2(16, 16),
                                    }
                                }
                            },
                            events = {
                                mouseClick = async:callback(function()
                                    if Editor.deletePartClickCount >= 2 then
                                        Editor.deletePartClickCount = 0
                                        if part == Editor.activePart then
                                            Editor.activePart = Editor.song.parts[1]
                                        end
                                        if part then
                                            Editor.song:removePart(part.index)
                                            Editor:destroyUI()
                                            Editor:createUI()
                                        end
                                        return
                                    end
                                    if Editor.deletePartIndex ~= part.index then
                                        Editor.deletePartIndex = part.index
                                        Editor.deletePartClickCount = 0
                                    end
                                    Editor.deletePartClickCount = Editor.deletePartClickCount + 1
                                    Editor.deletePartConfirmTimer = Editor.deletePartConfirmResetTime
                                    ui.showMessage(l10n('UI_PRoll_DeletePartMsg'):gsub('%%{count}', tostring(3 - Editor.deletePartClickCount)))
                                end),
                            }
                        }
                    }
                }
            },
        }

        partDisplay.layout.content[1].content[3].events.mousePress = async:callback(function(e)
            -- Left mouse button: Mute/unmute, Right mouse button: Toggle solo
            if e.button == 1 then
                Editor.partsPlaying[part.index] = not Editor.partsPlaying[part.index]
                partDisplay.layout.content[1].content[3].content[1].props.resource = ui.texture { path = 'textures/Bardcraft/ui/' .. (Editor.partsPlaying[part.index] and 'part-vol-on.dds' or 'part-vol-off.dds') }
                partDisplay.layout.content[1].content[3].content[1].props.alpha = Editor.partsPlaying[part.index] and 1 or 0.5
                partDisplay:update()
            elseif e.button == 3 then
                local soloCount = 0
                local targetSoloed = false
                for i, isPlaying in pairs(Editor.partsPlaying) do
                    if isPlaying then
                        soloCount = soloCount + 1
                        if i == part.index then
                            targetSoloed = true
                        end
                    end
                end

                if soloCount == 1 and targetSoloed then
                    for i, _ in pairs(Editor.partsPlaying) do
                        Editor.partsPlaying[i] = true
                    end
                else
                    for i, _ in pairs(Editor.partsPlaying) do
                        Editor.partsPlaying[i] = i == part.index
                    end
                end
                
                Editor:destroyUI()
                Editor:createUI()
            end
        end)

        partDisplay.layout.content[1].content[1].events.mouseClick = async:callback(function()
            Editor.activePart = part
            Editor:destroyUI()
            Editor:createUI()
        end)

        partDisplay.layout.content[1].content[2].content = ui.content {
            uiTemplates.textEdit(part.title, 20, function(text, this)
                if text ~= part.title then
                    part.title = text
                    this.props.text = text
                    saveDraft()
                end
            end),
            uiTemplates.select(instruments, indexOf(instruments, getInstrumentName()), 0, true, 20, function(index)
                local instrumentName = instruments[index]
                local instrumentNumber = Song.getInstrumentNumber(instrumentName)
                if instrumentNumber ~= part.instrument then
                    part.instrument = instrumentNumber
                    part.numOfType = #Editor.song:getPartsOfInstrument(instrumentNumber)
                    saveDraft()
                    partDisplay.layout.content[1].content[1].props.resource = ui.texture { path = Instruments[instrumentName].icon }
                    partDisplay:update()
                end
            end),
        }
        return partDisplay
    end,
    partDisplaySmall = function(part, itemHeight, thickBorders, confidence, onClick)
        local function getInstrumentName()
            return Song.getInstrumentProfile(part.instrument).name
        end

        -- Generate RGB from confidence; 0 is gray, then blend from red to green
        local function blendRedToGreen(value)
            -- Input validation:  Check if the input is within the valid range.
            if not value or value < 0 or value > 1 then
                -- Return a default gray color for invalid input.  This is robust.
                return util.color.rgb(0.5, 0.5, 0.5)
            end
          
            if value == 0 then
                -- Return gray for value of 0
                return util.color.rgb(0.5, 0.5, 0.5)
            else
                -- Blend from red to green
                local red = 1 - value
                local green = value
                local blue = 0 -- Blue component is always 0 in this blend.
                return util.color.rgb(red, green, blue)
            end
        end
        local color = blendRedToGreen(confidence / 100)

        local partDisplaySmall = ui.create {
            template = (thickBorders and I.MWUI.templates.bordersThick or I.MWUI.templates.borders),
            props = {
                size = util.vector2(0, itemHeight),
            },
            external = {
                stretch = 1,
            },
            content = ui.content {
                thickBorders and {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'white', },
                        relativeSize = util.vector2(1, 1),
                        color = Editor.uiColors.BLACK,
                        alpha = 0.5,
                    }
                } or {},
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = false,
                        size = util.vector2(0, itemHeight),
                        relativeSize = util.vector2(1, 0),
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Image,
                            props = {
                                resource = ui.texture { path = Instruments[getInstrumentName()].icon },
                                size = util.vector2(itemHeight - 8, itemHeight - 8),
                            },
                        },
                        {
                            template = createPaddingTemplate(4),
                        },
                        {
                            type = ui.TYPE.Flex,
                            external = {
                                grow = 1,
                                stretch = 1,
                            },
                            content = ui.content {
                                {
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = part.title,
                                        textColor = thickBorders and Editor.uiColors.WHITE or Editor.uiColors.DEFAULT,
                                    },
                                },
                                {
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = l10n('UI_PartConfidence'):gsub('%%{confidence}', string.format('%.2f', confidence)),
                                        textColor = color,
                                    },
                                }
                            }
                        }
                    }
                }
            },
            events = {
                mouseClick = async:callback(function()
                    if onClick then
                        onClick()
                    end
                end),
            }
        }
        
        return partDisplaySmall
    end,
    songDisplay = function(song, itemHeight, thickBorders, onClick)
        local stars = {}
        if song.difficulty == "starter" then
            table.insert(stars, {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = "textures/Bardcraft/ui/star-half.dds", size = util.vector2(26, 25) },
                    size = util.vector2(26, 25),
                }
            })
        elseif song.difficulty == "beginner" or song.difficulty == "intermediate" or song.difficulty == "advanced" then
            local count = ({ beginner = 1, intermediate = 2, advanced = 3 })[song.difficulty] or 0
            for i = 1, count do
                table.insert(stars, {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = "textures/Bardcraft/ui/star-full.dds", size = util.vector2(26, 25) },
                        size = util.vector2(26, 25),
                    }
                })
            end
        end

        local starRow = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                align = ui.ALIGNMENT.Center,
                anchor = util.vector2(1, 0.5),
                relativePosition = util.vector2(1, 0.5),
                position = util.vector2(-8, 0),
            },
            content = ui.content(stars),
        }

        local leftIcons = {}
        local isBookmarked = Editor.bookmarkedSongs[song.id]
        if thickBorders then
            leftIcons = {
                type = ui.TYPE.Widget,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = isBookmarked and 'textures/Bardcraft/ui/icon-bookmark.dds' or 'textures/Bardcraft/ui/icon-bookmark-empty.dds' },
                            size = util.vector2(16, 16),
                            position = util.vector2(4, -4),
                            alpha = isBookmarked and 1 or 0.25,
                            propagateEvents = false,
                        },
                        events = {
                            mouseClick = async:callback(function()
                                if isBookmarked then
                                    Editor.bookmarkedSongs[song.id] = nil
                                else
                                    Editor.bookmarkedSongs[song.id] = true
                                end
                                setMainContent(getPerformanceTab())
                            end),
                        }
                    },
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = 'textures/Bardcraft/ui/icon-settings.dds' },
                            size = util.vector2(16, 16),
                            anchor = util.vector2(0, 1),
                            relativePosition = util.vector2(0, 1),
                            position = util.vector2(4, 0),
                            alpha = 0.25,
                            propagateEvents = false,
                        },
                        events = {
                            mouseClick = async:callback(function()
                                if modalElement then
                                    modalElement:destroy()
                                    modalElement = nil
                                end

                                local isCustom = not song.isPreset

                                modalElement = ui.create(uiTemplates.modal(
                                {
                                    type = ui.TYPE.Flex,
                                    props = {
                                        autoSize = false,
                                        relativeSize = util.vector2(1, 1),
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                    },
                                    content = ui.content {
                                        isCustom and uiTemplates.button(l10n('UI_Button_SongForget'), util.vector2(192, 32), function()
                                            self:sendEvent('BC_ForgetSong', { id = song.id })
                                            modalElement:destroy()
                                            modalElement = nil
                                        end,
                                        Editor.uiColors.RED_DESAT) or {},
                                        isCustom and I.MWUI.templates.interval or {},
                                        uiTemplates.button(l10n('UI_Button_SongCopy'), util.vector2(192, 32), function()
                                            modalElement:destroy()
                                            modalElement = nil
                                            Editor:setState(Editor.STATE.SONG)
                                            setDraft(Song.copy(song))
                                            saveDraft()
                                            setMainContent(getSongTab())
                                        end),
                                        I.MWUI.templates.interval,
                                        uiTemplates.button(l10n('UI_Button_Cancel'), util.vector2(192, 32), function()
                                            modalElement:destroy()
                                            modalElement = nil
                                        end),
                                    },
                                }, util.vector2(256, 160), l10n('UI_SongOptions')))
                            end),
                        }
                    }
                }
            }
        elseif isBookmarked then
            leftIcons = {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'textures/Bardcraft/ui/icon-bookmark.dds' },
                    size = util.vector2(16, 16),
                    position = util.vector2(4, -8),
                }
            }
        end

        return {
            template = (thickBorders and I.MWUI.templates.bordersThick or I.MWUI.templates.borders),
            props = {
                size = util.vector2(0, itemHeight),
            },
            external = {
                stretch = 1,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { 
                            path = 'textures/Bardcraft/ui/songbgr/' .. song.texture .. '.dds',
                            offset = util.vector2(0, 32),
                            size = util.vector2(0, 64),
                        },
                        relativeSize = util.vector2(1, 1),
                    },
                },
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { 
                            path = 'textures/Bardcraft/ui/songbgr-overlay.dds',
                            offset = util.vector2(0, 32),
                            size = util.vector2(0, 64),
                        },
                        relativeSize = util.vector2(1, 1),
                    },
                },
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = song.title,
                        textColor = thickBorders and Editor.uiColors.WHITE or Editor.uiColors.DEFAULT,
                        anchor = util.vector2(0, 0.5),
                        relativePosition = util.vector2(0, 0.5),
                        position = util.vector2(thickBorders and 24 or 8, 0),
                    },
                },
                starRow,
                leftIcons,
            },
            events = {
                mouseClick = async:callback(function()
                    if onClick then
                        onClick()
                    end
                end),
            }
        }
    end,
    performerDisplay = function(npc, itemHeight, thickBorders, onClick)
        local name = types.NPC.record(npc).name
        local performerInfo = Editor.performersInfo[npc.id]
        local level = performerInfo and performerInfo.performanceSkill and performerInfo.performanceSkill.level or 1
        local partIcon = nil
        if Editor.performanceSelectedSong and Editor.performancePartAssignments[npc.id] then
            local partIndex = Editor.performancePartAssignments[npc.id]
            local part = Editor.performanceSelectedSong:getPartByIndex(partIndex)
            if part then
                local instrumentProfile = Song.getInstrumentProfile(part.instrument)
                local instrumentIcon = Instruments[instrumentProfile.name].icon
                if instrumentIcon then
                    partIcon = {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = instrumentIcon },
                            size = util.vector2(24, 24),
                            anchor = util.vector2(0.5, 0.5),
                            relativePosition = util.vector2(0.5, 0.5),
                        }
                    }
                end
            end
        end

        return {
            template = (thickBorders and I.MWUI.templates.bordersThick or I.MWUI.templates.borders),
            props = {
                size = util.vector2(0, itemHeight),
            },
            external = {
                stretch = 1,
            },
            content = ui.content {
                thickBorders and {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'white', },
                        relativeSize = util.vector2(1, 1),
                        color = Editor.uiColors.BLACK,
                        alpha = 0.5,
                    }
                } or {},
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = name,
                        textColor = thickBorders and Editor.uiColors.WHITE or Editor.uiColors.DEFAULT,
                        position = util.vector2(8, 0),
                        anchor = util.vector2(0, 0.5),
                        relativePosition = util.vector2(0, 0.5),
                        size = util.vector2(0, itemHeight),
                    },
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = false,
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.End,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = l10n('UI_Lvl'):gsub('%%{level}', tostring(level)),
                                textColor = thickBorders and Editor.uiColors.WHITE or Editor.uiColors.DEFAULT,
                                textSize = 24,
                                anchor = util.vector2(1, 0.5),
                                relativePosition = util.vector2(1, 0.5),
                                position = util.vector2(-8, 0),
                                size = util.vector2(0, itemHeight),
                            },
                        },
                        partIcon and createPaddingTemplate(2) or {},
                        partIcon or createPaddingTemplate(4),
                        partIcon and createPaddingTemplate(2) or {},
                    }
                }
            },
            events = {
                mouseClick = async:callback(function()
                    if onClick then
                        onClick()
                    end
                end),
            }
        }
    end,
    logDisplaySmall = function(log, itemHeight, onClick)
        -- Determine venue name (cell)
        local venue = log.cell or l10n('UI_PerfLog_UnknownVenue')
        if log.type == Song.PerformanceType.Street then
            venue = l10n('UI_PerfLog_StreetsOf'):gsub('%%{city}', venue)
        end
        -- Calculate total gold gained
        local gold = (log.payment or 0) + (log.tips or 0)
        -- Format gold string
        local goldStr = l10n('UI_PerfLog_Gold'):gsub('%%{amount}', tostring(gold))
        -- Optionally, color gold text based on amount
        local goldColor = gold > 0 and Editor.uiColors.DEFAULT or Editor.uiColors.GRAY

        local qualityString
        if log.quality == 100 then
            qualityString = 'Perfect'
        elseif log.quality >= 95 then
            qualityString = 'Excellent'
        elseif log.quality >= 85 then
            qualityString = 'Great'
        elseif log.quality >= 70 then
            qualityString = 'Good'
        elseif log.quality >= 40 then
            qualityString = 'Mediocre'
        elseif log.quality >= 15 then
            qualityString = 'Bad'
        else
            qualityString = 'Terrible'
        end
        
        local starsTexture = ui.texture {
            path = 'textures/Bardcraft/ui/stars-' .. qualityString .. '.dds',
            size = util.vector2(500, 96),
        }

        return {
            template = I.MWUI.templates.borders,
            props = {
                size = util.vector2(0, itemHeight),
            },
            external = {
                stretch = 1,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = venue,
                        textColor = Editor.uiColors.DEFAULT,
                        position = util.vector2(8, 0),
                        anchor = util.vector2(0, 0.5),
                        relativePosition = util.vector2(0, 0.5),
                        size = util.vector2(0, itemHeight),
                    },
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = false,
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.End,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = goldStr .. ' | ',
                                textColor = goldColor,
                            },
                        },
                        {
                            type = ui.TYPE.Image,
                            props = {
                                resource = starsTexture,
                                size = util.vector2(itemHeight / 2 * (500/96), itemHeight / 2),
                            }
                        },
                        createPaddingTemplate(4)
                    }
                },
            },
            events = {
                mouseClick = async:callback(function()
                    Editor:showPerformanceLog(log)
                end),
            }
        }
    end,
    button = function(text, size, callback, color)
        return {
            template = I.MWUI.templates.bordersThick,
            props = {
                size = size or util.vector2(0, 0),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = false,
                        relativeSize = util.vector2(1, 1),
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = text,
                                textColor = color or Editor.uiColors.DEFAULT,
                            },
                        },
                    },
                },
            },
            events = {
                mousePress = async:callback(function()
                    if callback then
                        callback()
                    end
                end),
            }
        }
    end,
    scrollable = function(size, content, flexSize)
        local scrollLimit = flexSize and (flexSize.y - size.y) or math.huge
        local canScroll
        if flexSize then
            canScroll = flexSize.y > size.y
        else
            canScroll = true
        end
        local scrollWidget = ui.create {
            template = I.MWUI.templates.borders,
            props = {
                size = size,
                scrollLimit = scrollLimit,
                canScroll = canScroll,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = flexSize == nil,
                        size = flexSize or util.vector2(0, 0),
                        relativeSize = flexSize and util.vector2(1, 0) or util.vector2(0, 0),
                        position = util.vector2(0, 0),
                    },
                    content = content or ui.content{},
                }
            },
        }
        scrollWidget.layout.events = {
            focusGain = async:callback(function()
                scrollableFocused = scrollWidget
            end),
            focusLoss = async:callback(function(self)
                if scrollableFocused == scrollWidget then
                    scrollableFocused = nil
                end
            end),
        }
        return scrollWidget
    end,
    pianoRollKeyboard = function(timeSig)
        local bar = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(96, calcPianoRollEditorHeight()),
                position = util.vector2(0, pianoRoll.scrollY)
            },
            content = ui.content {},
            events = {
                mouseMove = async:callback(function(e)
                    if e.button == 1 and Editor.activePart then
                        local noteIndex = math.floor((128 - (e.offset.y / 16)))
                        local fileName = getNoteSoundPath(noteIndex)
                        if playingNoteSound ~= fileName then
                            ambient.playSoundFile(fileName, { volume = getNoteVolume()})
                            if playingNoteSound and Song.getInstrumentProfile(Editor.activePart.instrument).sustain then
                                ambient.stopSoundFile(playingNoteSound)
                            end
                            playingNoteSound = fileName
                        end
                    end
                end),
                mousePress = async:callback(function(e)
                    if e.button == 1 and Editor.activePart then
                        local noteIndex = math.floor((128 - (e.offset.y / 16)))
                        local fileName = getNoteSoundPath(noteIndex)
                        ambient.playSoundFile(fileName, { volume = getNoteVolume() })
                        playingNoteSound = fileName
                    end
                end),
                mouseRelease = async:callback(function(e)
                    if e.button == 1 and Editor.activePart then
                        if playingNoteSound and Song.getInstrumentProfile(Editor.activePart.instrument).sustain then
                            ambient.stopSoundFile(playingNoteSound)
                        end
                    end
                end),
            }
        }
        bar.content:add({
            type = ui.TYPE.Image,
            props = {
                resource = uiTextures.pianoRollKeys,
                size = util.vector2(96, calcPianoRollEditorHeight()),
                color = Editor.keyboardColor,
                tileH = false,
                tileV = true,
            },
        })
        bar.content:add({
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                relativeSize = util.vector2(1, 1),
                relativePosition = util.vector2(0, 0),
                horizontal = false,
            },
            content = ui.content {}
        })
        return bar
    end,
    pianoRollEditor = function()
        if not Editor.song then return {} end
        local timeSig = Editor.song.timeSig
        local barWidth = calcBarWidth() -- Width of a single bar based on time signature
        local totalWidth = barWidth * Editor.song.lengthBars -- Total width based on number of bars
        local editor = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(totalWidth, calcPianoRollEditorHeight()),
            },
            content = ui.content {
                -- {
                --     type = ui.TYPE.Flex,
                --     props = {
                --         autoSize = false,
                --         size = util.vector2(totalWidth, calcPianoRollEditorHeight()),
                --     },
                --     content = ui.content {},
                -- },
            },
        }

        local wrapperSize = calcPianoRollEditorWrapperSize()

        local editorOverlay = {
            type = ui.TYPE.Widget,
            name = 'pianoRollOverlay',
            props = {
                size = util.vector2(wrapperSize.x + calcBarWidth(), wrapperSize.y + calcOctaveHeight()), -- Add padding for when we loop the overlay
                position = util.vector2(pianoRoll.scrollX % barWidth - barWidth, pianoRoll.scrollY % calcOctaveHeight() - calcOctaveHeight())
            },
            content = ui.content {},
        }
        
        editorOverlay.content:add({
            type = ui.TYPE.Image,
            name = 'bgrRows',
            props = {
                resource = Editor:getScaleTexture(),
                relativeSize = util.vector2(1, 1),
                position = util.vector2(0, -16 * (Editor.song.scale.root - 1)),
                size = util.vector2(0, 16 * (Editor.song.scale.root - 1)),
                tileH = true,
                tileV = true,
                color = Editor.backgroundColor,
                alpha = 0.06,
            },
        })

        for i = 1, Editor.song.lengthBars + 1 do
            -- Create a vertical line for each bar
            editorOverlay.content:add({
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'white' },
                    size = util.vector2(1, 0),
                    relativeSize = util.vector2(0, 1),
                    tileH = false,
                    tileV = true,
                    alpha = 1,
                    color = Editor.barLineColor,
                    position = util.vector2(i * barWidth, 0),
                },
            })
        end
        if Editor.zoomLevel > 1 then
            editorOverlay.content:add({
                type = ui.TYPE.Image,
                name = 'bgrBars',
                props = {
                    resource = uiTextures.pianoRollBeatLines[timeSig[2] / (Editor.ZOOM_LEVELS[Editor.zoomLevel])],
                    relativeSize = util.vector2(1, 1),
                    tileH = true,
                    tileV = true,
                    color = Editor.beatLineColor,
                    alpha = 0.3,
                },
            })
        end

        local editorMarkers = {
            type = ui.TYPE.Widget,
            name = 'pianoRollMarkers',
            props = {
                size = util.vector2(totalWidth, calcPianoRollEditorHeight()),
                position = util.vector2(pianoRoll.scrollX, 0),
            },
            content = ui.content {},
        }
        local function addMarker(x, color, alpha)
            editorMarkers.content:add({
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'white' },
                    size = util.vector2(2, 0),
                    relativeSize = util.vector2(0, 1),
                    tileH = false,
                    tileV = true,
                    alpha = alpha or 1,
                    color = color,
                    position = util.vector2(x, 0),
                },
            })
        end
        -- Add playback marker
        addMarker(0, Editor.playbackLineColor, Editor.playback and 1 or 0)

        -- Add cyan lines for loop start and end bar
        local loopBars = Editor.song.loopBars
        if loopBars and #loopBars == 2 then
            if loopBars[1] > 0 then
                addMarker(loopBars[1] * barWidth, Editor.loopStartLineColor, 0.5)
            end
            addMarker(loopBars[2] * barWidth, Editor.loopEndLineColor, 0.5)
        end

        -- Add red line for end bar
        local endBar = Editor.song.lengthBars
        if endBar and endBar > 0 then
            local endBarX = endBar * barWidth
            addMarker(endBarX, util.color.rgb(1, 0, 0), 0.5)
        end

        pianoRoll.editorMarkersWrapper = ui.create {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(totalWidth, calcPianoRollEditorHeight()),
            },
            content = ui.content {
                editorMarkers,
            }
        }

        local editorNotes = {
            type = ui.TYPE.Widget,
            name = 'pianoRollNotes',
            props = {
                size = util.vector2(totalWidth, calcPianoRollEditorHeight()),
                position = util.vector2(pianoRoll.scrollX, pianoRoll.scrollY)
            },
            content = ui.content {},
        }
        editor.content:add(editorOverlay)
        editor.content:add(pianoRoll.editorMarkersWrapper)
        editor.content:add(editorNotes)
        return editor
    end,
    pianoRollNote = function(id, note, tick, duration, active)
        local noteWidth = calcBeatWidth(Editor.song.timeSig[2]) * (Editor.song:tickToBeat(duration))
        local noteHeight = calcOctaveHeight() / 12
        local noteX = calcBeatWidth(Editor.song.timeSig[2]) * (Editor.song:tickToBeat(tick))
        local noteY = (127 - note) * noteHeight
        if active == nil then
            active = true
        end
        local noteLayout = {
            type = ui.TYPE.Image,
            name = tostring(id),
            props = {
                active = active,
                resource = uiTextures.pianoRollNote,
                size = util.vector2(noteWidth, noteHeight),
                tileH = true,
                tileV = false,
                color = Editor.noteColor,
                position = util.vector2(noteX, noteY),
            },
            events = {}
        }
        if active then
            noteLayout.events.mousePress = async:callback(function(e, self)
                if not self.props.active then return end
                if e.button == 3 or (Editor.controllerMode and e.button == 1 and input.isControllerButtonPressed(input.CONTROLLER_BUTTON.LeftShoulder)) then
                    removeNote(self)
                    saveNotes()
                    return
                end
                if e.button == 1 then
                    pianoRoll.lastNoteSize = duration
                    pianoRoll.activeNote = tonumber(self.name)
                    pianoRoll.dragStart = editorOffsetToRealOffset(self.props.position + e.offset)
                    local resizeArea = math.min(8, noteWidth / 2)
                    local distFromEnd = noteWidth - e.offset.x
                    if distFromEnd < resizeArea then
                        pianoRoll.dragType = DragType.RESIZE_RIGHT
                        pianoRoll.dragOffset = util.vector2(0, 0)
                    else
                        pianoRoll.dragType = DragType.MOVE
                        pianoRoll.dragOffset = -e.offset
                    end
                    playNoteSound(note)
                end
            end)
            noteLayout.events.mouseRelease = async:callback(function()
                if not Editor.activePart then return end
                if not Song.getInstrumentProfile(Editor.activePart.instrument).sustain then return end
                stopNoteSound(note)
            end)
        end
        return noteLayout
    end,
    modal = function(content, size, title)
        return {
            layer = "Windows",
            props = {
                relativeSize = util.vector2(1, 1), -- take up the whole screen so players can't click anything else
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'white' },
                        size = util.vector2(0, 0),
                        relativeSize = util.vector2(1, 1),
                        color = Editor.uiColors.BLACK,
                        alpha = 0.5,
                    }
                },
                {
                    template = I.MWUI.templates.boxSolidThick,
                    props = {
                        size = size,
                        anchor = util.vector2(0.5, 0.5),
                        relativePosition = util.vector2(0.5, 0.5),
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                autoSize = false,
                                size = size,
                            }, 
                            content = ui.content {
                                title and {
                                    type = ui.TYPE.Flex,
                                    props = {
                                        horizontal = true,
                                        autoSize = false,
                                        relativeSize = util.vector2(1, 0),
                                        size = util.vector2(0, Editor.windowCaptionHeight)
                                    },
                                    content = ui.content { 
                                        headerSection, 
                                        {
                                            template = I.MWUI.templates.textNormal,
                                            props = {
                                                text = '   ' .. title .. '   ',
                                            }
                                        },
                                        headerSection,
                                    },
                                } or {},
                                {
                                    template = I.MWUI.templates.bordersThick,
                                    external = {
                                        grow = 1,
                                        stretch = 1,
                                    },
                                    content = ui.content { content },
                                },
                            }
                        }
                    }
                }
            }
        }
    end,
    confirmModal = function(onConfirm)
        return uiTemplates.modal(
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(1, 1),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    createPaddingTemplate(16),
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = l10n('UI_AreYouSure'),
                            textAlignH = ui.ALIGNMENT.Center,
                        },
                    },
                    createPaddingTemplate(16),
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            autoSize = false,
                            relativeSize = util.vector2(1, 0),
                            size = util.vector2(0, 32),
                            align = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            uiTemplates.button(l10n('UI_Button_Yes'), util.vector2(128, 32), function()
                                if onConfirm then
                                    onConfirm()
                                end
                                if modalElement then
                                    modalElement:destroy()
                                    modalElement = nil
                                end
                            end),
                            {
                                template = I.MWUI.templates.interval,
                            },
                            uiTemplates.button(l10n('UI_Button_No'), util.vector2(128, 32), function()
                                if modalElement then
                                    modalElement:destroy()
                                    modalElement = nil
                                end
                            end),
                        },
                    },
                    createPaddingTemplate(16),
                },
            },
            util.vector2(300, 150),
            l10n('UI_Confirmation')
        )
    end,
    choiceModal = function(title, choices)
        return uiTemplates.modal(
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(1, 1),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    createPaddingTemplate(16),
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = title or l10n('UI_ChooseAnOption'),
                            textAlignH = ui.ALIGNMENT.Center,
                        },
                    },
                    createPaddingTemplate(16),
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            autoSize = false,
                            relativeSize = util.vector2(1, 0),
                            align = ui.ALIGNMENT.Center,
                        },
                        content = (function()
                            local buttons = {}
                            for _, choice in ipairs(choices) do
                                table.insert(buttons, uiTemplates.button(choice.text, util.vector2(200, 32), function()
                                    if choice.callback then
                                        choice.callback()
                                    end
                                    if modalElement then
                                        modalElement:destroy()
                                        modalElement = nil
                                    end
                                end))
                                table.insert(buttons, createPaddingTemplate(8))
                            end
                            return buttons
                        end)(),
                    },
                    createPaddingTemplate(16),
                },
            },
            util.vector2(300, 200),
            title or l10n('UI_Choice')
        )
    end,
}

local function populateNotes()
    if not pianoRoll.editorWrapper then return end
    local unsorted = {}
    for _, noteData in pairs(Editor.noteMap) do
        local active = not Editor.activePart or (noteData.part == Editor.activePart.index)
        local id = noteData.id
        local note = noteData.note
        local tick = noteData.time
        local duration = noteData.duration
        -- Check if note is within the viewing area
        local noteX = calcBeatWidth(Editor.song.timeSig[2]) * (Editor.song:tickToBeat(tick))
        local noteWidth = calcBeatWidth(Editor.song.timeSig[2]) * (Editor.song:tickToBeat(duration))
        local wrapperSize = calcPianoRollEditorWrapperSize()

        if noteX + noteWidth >= -pianoRoll.scrollX - pianoRoll.scrollPopulateWindowSize and noteX <= -pianoRoll.scrollX + pianoRoll.scrollPopulateWindowSize + wrapperSize.x then
            -- Add note to the piano roll
            local template = uiTemplates.pianoRollNote(id, note, tick, duration, active)
            template.props.alpha = active and 1 or 0.2
            template.props.active = active
            table.insert(unsorted, template)
        end
    end
    -- Sort so that all the active notes are at the end
    table.sort(unsorted, function(a, b)
        if a.props.active == b.props.active then
            return false
        end
        return not a.props.active and b.props.active
    end)
    pianoRoll.editorWrapper.layout.content[1].content[3].content = ui.content(unsorted)
    pianoRoll.editorWrapper:update()
end

addNote = function(note, tick, duration, active)
    if not Editor.song then return end
    duration = duration or Editor.song.resolution * (4 / Editor.song.timeSig[2])
    local id = #Editor.noteMap + 1
    local noteData = {
        id = id,
        note = note,
        velocity = 127,
        part = Editor.activePart.index,
        time = tick,
        duration = duration,
    }
    table.insert(Editor.noteMap, noteData)
    pianoRoll.editorWrapper.layout.content[1].content[3].content:add(uiTemplates.pianoRollNote(id, note, tick, duration, active))
    Editor.song.noteIdCounter = Editor.song.noteIdCounter + 1
    pianoRoll.editorWrapper:update()
    --[[table.sort(Editor.noteMap, function(a, b)
        return a.time < b.time
    end)]]
    return id
end

removeNote = function(element)
    if not Editor.song then return end
    local id = element.name
    if not id then return end
    for i, noteData in pairs(Editor.noteMap) do
        if noteData.id == tonumber(id) then
            --table.remove(Editor.noteMap, i)
            Editor.noteMap[i] = nil
            break
        end
    end
    local pianoRollNotes = pianoRoll.editorWrapper.layout.content[1].content[3].content
    for i, note in ipairs(pianoRollNotes) do
        if note.name == id then
            table.remove(pianoRollNotes, i)
            break
        end
    end
    pianoRoll.editorWrapper:update()
end

initNotes = function()
    if not Editor.song then return end
    Editor.noteMap = Editor.song:noteEventsToNoteMap(Editor.song.notes)
    populateNotes()
end

saveNotes = function()
    if not Editor.song then return end
    Editor.song.notes = Editor.song:noteMapToNoteEvents(Editor.noteMap)
end

setMainContent = function(content)
    if wrapperElement then
        local mainContent = wrapperElement.layout.content[1].content[2].content.mainContent.content
        mainContent[2] = content
        wrapperElement:update()
    end
end

getMainContent = function()
    if wrapperElement then
        return wrapperElement.layout.content[1].content[2].content.mainContent.content[2]
    end
    return nil
end

local function importSong()
    if not Editor.song then return end
    if wrapperElement then
        local manager = wrapperElement.layout.content[1].content[2].content.mainContent.content[2]
        if manager then
            local importTextBox = manager.content[2].content[2].content.importExportTextBox.content[1] --TODO make this use importExport tag, not sure why it isn't working
            local songData = importTextBox.props.text
            if songData and songData ~= "" then
                local song = Song.decode(songData)
                if song then
                    setDraft(song)
                    saveDraft()
                end
            end
        end
    end
end

local function exportSong()
    if not Editor.song then return end
    if wrapperElement then
        local manager = wrapperElement.layout.content[1].content[2].content.mainContent.content[2]
        if manager then
            local exportTextBox = manager.content[2].content[2].content.importExportTextBox.content[1] --TODO make this use importExport tag, not sure why it isn't working
            exportTextBox.props.text = Editor.song:encode()
            wrapperElement:update()
        end
    end
end

local function updateSongManager()
    setMainContent(getSongTab())
end

local function initPianoRoll()
    if not Editor.song then return end
    if calcPianoRollEditorWidth() > calcPianoRollEditorWrapperSize().x then
        pianoRoll.scrollXMax = calcPianoRollEditorWidth() - calcPianoRollEditorWrapperSize().x
    else
        pianoRoll.scrollXMax = 0
    end
    if calcPianoRollEditorHeight() > calcPianoRollEditorWrapperSize().y then
        pianoRoll.scrollYMax = calcPianoRollEditorHeight() - calcPianoRollEditorWrapperSize().y
    else
        pianoRoll.scrollYMax = 0
    end 
end

local alreadyRedrewThisFrame = false

local function redrawPianoRollEditor()
    if not Editor.song then return end
    if alreadyRedrewThisFrame then return end
    alreadyRedrewThisFrame = true
    if pianoRoll.editorWrapper and pianoRoll.editorWrapper.layout then
        auxUi.deepDestroy(pianoRoll.editorWrapper.layout)
    end
    initPianoRoll()
    updateSongManager()
    updatePianoRollKeyboardLabels()
    pianoRoll.editorWrapper.layout.content[1] = uiTemplates.pianoRollEditor()
    updatePianoRollBarNumberLabels()
    initNotes()

    editorOverlay = pianoRoll.editorWrapper.layout.content[1].content.pianoRollOverlay
    editorMarkers = pianoRoll.editorMarkersWrapper.layout.content.pianoRollMarkers
    editorNotes = pianoRoll.editorWrapper.layout.content[1].content.pianoRollNotes
end

local function stopSounds(instrument)
    local profile = Song.getInstrumentProfile(instrument)
    for j = 0, 127 do
        local filePath = 'sound\\Bardcraft\\samples\\' .. profile.name .. '\\' .. profile.name .. '_' .. Song.noteNumberToName(j) .. '.flac'
        if ambient.isSoundFilePlaying(filePath) then
            ambient.stopSoundFile(filePath)
        end
    end
end

local function stopAllSounds()
    local profiles = Song.getInstrumentProfiles()
    for _, profile in pairs(profiles) do
        for j = 0, 127 do
            local filePath = 'sound\\Bardcraft\\samples\\' .. profile.name .. '\\' .. profile.name .. '_' .. Song.noteNumberToName(j) .. '.flac'
            if ambient.isSoundFilePlaying(filePath) then
                ambient.stopSoundFile(filePath)
            end
        end
    end
end

local infiniteLuteRelease = false

local function startPlayback(fromStart)
    if not Editor.song then return end
    saveNotes()
    Editor.playback = true
    if fromStart then
        playbackStartScrollX = (pianoRoll.scrollX / Editor.ZOOM_LEVELS[Editor.zoomLevel])
    end
    Editor.song:resetPlayback()
    if not fromStart then
        Editor.song.playbackTickCurr = Editor.song:beatToTick(-pianoRoll.scrollX / calcBeatWidth(Editor.song.timeSig[2]))
        Editor.song.playbackTickPrev = Editor.song.playbackTickCurr
    end
    infiniteLuteRelease = configGlobal.options.bInfiniteLuteRelease
end

local function stopPlayback()
    Editor.playback = false
    if playbackStartScrollX then
        pianoRoll.scrollX = util.clamp(playbackStartScrollX * Editor.ZOOM_LEVELS[Editor.zoomLevel], -pianoRoll.scrollXMax, 0)
        updatePianoRoll()
        pianoRoll.scrollLastPopulateX = pianoRoll.scrollX
        populateNotes()
        playbackStartScrollX = nil
    end
    Editor.song:resetPlayback()
    pianoRoll.editorMarkersWrapper:update()
    stopAllSounds()
end

setDraft = function(song)
    if Editor.song then
        saveNotes()
        saveDraft()
    end
    if song then
        Editor.song = song
        setmetatable(Editor.song, Song)
        Editor.activePart = nil
        pianoRoll.scrollX = 0
        Editor.activePart = Editor.song.parts[1] or nil
        for _, part in pairs(Editor.song.parts) do
            Editor.partsPlaying[part.index] = true
        end
        redrawPianoRollEditor()
        stopPlayback()
        pianoRoll.lastNoteSize = Editor.song.resolution * (4 / Editor.song.timeSig[2])
    else
        Editor.song = nil
    end
end

saveDraft = function()
    local songs = storage.playerSection('Bardcraft'):getCopy('songs/drafts') or {}
    local exists = false
    for i, song in ipairs(songs) do
        if song.id == Editor.song.id then
            exists = true
            songs[i] = Editor.song
            break
        end
    end
    if not exists then
        table.insert(songs, Editor.song)
    end
    storage.playerSection('Bardcraft'):set('songs/drafts', songs)
end

addDraft = function()
    local song = Song.new()
    local songs = storage.playerSection('Bardcraft'):getCopy('songs/drafts') or {}
    table.insert(songs, song)
    storage.playerSection('Bardcraft'):set('songs/drafts', songs)
    setDraft(song)
    setMainContent(getSongTab())
end

local function isPowerOfTwo(n)
	return n > 0 and math.floor(math.log(n) / math.log(2)) == math.log(n) / math.log(2)
end

local function parseTimeSignature(str)
    local numStr, denomStr = str:match("^(%d+)/(%d+)$")
    local numerator = tonumber(numStr)
    local denominator = tonumber(denomStr)

    if not numerator or not denominator then
        return nil
    end

    if numerator < 1 or denominator < 1 then
        return nil
    end

    if not isPowerOfTwo(denominator) then
        return nil
    end

    return {numerator, denominator}
end

local lastMouseDragPos = nil

Editor.performanceSelectedSong = nil
Editor.performanceSelectedPerformer = nil
Editor.performanceSelectedPart = nil
Editor.performancePartAssignments = {}
Editor.performersInfo = {}
Editor.troupeMembers = {}
Editor.troupeSize = 0
Editor.canPerform = false

local function startPerformance(type)
    if Editor.performanceSelectedSong then
        local partCount = 0
        local performers = {}
        for id, part in pairs(Editor.performancePartAssignments) do
            table.insert(performers, { actorId = id, part = part })
            partCount = partCount + 1
        end
        if partCount == 0 then
            return
        end

        core.sendGlobalEvent('BO_StartPerformance', {
            song = Editor.performanceSelectedSong,
            performers = performers,
            type = type,
            playerStats = Editor.performersInfo[self.id],
        })
    end
end

local function getSongs()
    local merged = {}
    local presetSongs = storage.globalSection('Bardcraft'):getCopy(Editor.SONGS_MODE.PRESET) or {}
    local customSongs = storage.playerSection('Bardcraft'):getCopy(Editor.SONGS_MODE.CUSTOM) or {}
    for _, song in ipairs(presetSongs) do
        table.insert(merged, song)
    end
    for _, song in ipairs(customSongs) do
        table.insert(merged, song)
    end
    table.sort(merged, function(a, b)
        return a.title < b.title
    end)
    return merged
end

local function getDrafts()
    local drafts = {}
    local draftSongs = storage.playerSection('Bardcraft'):getCopy('songs/drafts') or {}
    for _, song in ipairs(draftSongs) do
        table.insert(drafts, song)
    end
    table.sort(drafts, function(a, b)
        return a.title < b.title
    end)
    return drafts
end

local function calcSheetMusicCost()
    if not Editor.song then return 0 end
    local lengthBars = Editor.song.lengthBars
    local cost = math.max(1, math.floor((lengthBars - 2) / 8) + 1) -- 1 sheet for every 8 bars + 2, minimum 1 sheet
    return cost
end

local function onFinalizeDraft(title, desc, cost)
    if not Editor.song then return false end

    -- Check if player has enough blanks
    local player = nearby.players[1]
    if not player then return false end
    local inv = player.type.inventory(player)
    if inv:countOf('r_bc_sheetmusic_blank') < cost then
        ui.showMessage(l10n('UI_Msg_PRoll_InsufficientBlanks'))
        return false
    end
    local used = 0
    for _, item in ipairs(inv:findAll('r_bc_sheetmusic_blank')) do
        local toRemove = math.min(item.count, cost - used)
        used = used + toRemove
        core.sendGlobalEvent('BC_ConsumeItem', { item = item, count = toRemove})
        if used >= cost then
            break
        end
    end

    local song = Editor.song
    song.title = title
    song.desc = desc
    song.id = song.title .. '_' .. os.time() + math.random(10000)
    song.texture = 'generic'

    local songs = storage.playerSection('Bardcraft'):getCopy('songs/custom') or {}
    for i, cSong in ipairs(songs) do
        if cSong.id == song.id then
            song.id = song.id .. '_' .. 1
            break
        end
    end
    table.insert(songs, song)
    storage.playerSection('Bardcraft'):set('songs/custom', songs)
    player:sendEvent('BC_FinalizeDraft', { song = song })
    return true
end

local draftTitle = nil
local draftDesc = nil

local function createFinalizeDraftModal()
    if modalElement then
        modalElement:destroy()
        modalElement = nil
    end

    draftTitle = Editor.song.title
    draftDesc = nil
    modalElement = ui.create(uiTemplates.modal(
    {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            relativeSize = util.vector2(1, 1),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongTitle'), draftTitle, 32, function(text)
                draftTitle = text
            end),
            createPaddingTemplate(8),
            {
                template = I.MWUI.templates.textHeader,
                props = {
                    text = l10n('UI_PRoll_SongDescription'),
                },
            },
            {
                template = I.MWUI.templates.borders,
                props = {
                    autoSize = false,
                    size = util.vector2(0, 100),
                    relativeSize = util.vector2(1, 0),
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditBox,
                        props = {
                            wordWrap = true,
                            relativeSize = util.vector2(1, 1),
                            size = util.vector2(0, 0),
                        },
                        events = {
                            textChanged = async:callback(function(text)
                                draftDesc = text
                            end),
                        }
                    },
                },
            },
            {
                template = createPaddingTemplate(8),
            },
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = l10n('UI_PRoll_DraftCost'):gsub('%%{amount}', tostring(calcSheetMusicCost())),
                    textAlignH = ui.ALIGNMENT.Center,
                },
            },
            {
                template = createPaddingTemplate(16),
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    autoSize = false,
                    relativeSize = util.vector2(1, 0),
                    size = util.vector2(0, 32),
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    uiTemplates.button(l10n('UI_Button_Confirm'), util.vector2(128, 32), function()
                        -- Confirm logic here
                        if onFinalizeDraft(draftTitle, draftDesc, calcSheetMusicCost()) then
                            modalElement:destroy()
                            modalElement = nil
                        end
                    end),
                    {
                        template = I.MWUI.templates.interval,
                    },
                    uiTemplates.button(l10n('UI_Button_Cancel'), util.vector2(128, 32), function()
                        modalElement:destroy()
                        modalElement = nil
                    end),
                },
            },
        },
    }, util.vector2(450, 400), l10n('UI_PRoll_FinalizeDraft')))
end

local draftsScrollable = nil
local partsScrollable = nil

getSongTab = function()
    local manager = auxUi.deepLayoutCopy(uiTemplates.songManager)
    local leftBox = manager.content[1].content[1].content

    local draftScrollableHeight = calcContentHeight() - 32
    Editor.songs = getDrafts()
    local draftListContent = ui.content{}
    for i, song in ipairs(Editor.songs) do
        local selected = Editor.song and (song.id == Editor.song.id)
        draftListContent:add({
            template = selected and I.MWUI.templates.bordersThick or I.MWUI.templates.borders,
            props = {
                size = util.vector2(0, 32),
                relativeSize = util.vector2(1, 0),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = song.title,
                        textColor = selected and util.color.rgb(1, 1, 1) or util.color.rgb(0.5, 0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                        relativePosition = util.vector2(0.5, 0.5),
                    },
                },
            },
            events = {
                mouseClick = async:callback(function()
                    setDraft(song)
                end),
            }
        })
    end

    local oldDraftsY = 0
    if draftsScrollable and draftsScrollable.layout and draftsScrollable.layout.content[1] and draftsScrollable.layout.content[1].props then
        oldDraftsY = draftsScrollable.layout.content[1].props.position.y
    end
    draftsScrollable = uiTemplates.scrollable(
        util.vector2(ui.screenSize().x * Editor.windowLeftBoxXMult + Editor.windowLeftBoxXSize, draftScrollableHeight),
        draftListContent,
        util.vector2(0, 32 * #Editor.songs)
    )
    draftsScrollable.layout.content[1].props.position = util.vector2(0, oldDraftsY)
    leftBox[1] = draftsScrollable
    table.insert(manager.content[1].content, {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = util.vector2(0, 32),
            relativeSize = util.vector2(1, 0),
            align = ui.ALIGNMENT.Start,
            relativePosition = util.vector2(0, 1),
            anchor = util.vector2(0, 1),
            position = util.vector2(0, -32),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.bordersThick,
                props = {
                    size = util.vector2(0, 32),
                    relativeSize = util.vector2(1, 0),
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = l10n('UI_PRoll_NewDraft'),
                            anchor = util.vector2(0.5, 0.5),
                            relativePosition = util.vector2(0.5, 0.5),
                        },
                    },
                },
                events = {
                    mouseClick = async:callback(function()
                        addDraft()
                    end),
                }
            },
        }
    })

    if Editor.song then
        local function numMatches(field, numStr)
            return tonumber(field) == tonumber(numStr)
        end
        local function parseExp(numStr)
            local parsedExp, err = luaxp.compile(numStr)
            if not parsedExp then
                return nil, err
            end
            local num, rerr = luaxp.run(parsedExp)
            if num == nil or type(num) ~= "number" then return nil, rerr end
            return num, nil
        end

        -- Add floating '?' help button at top right
        table.insert(manager.content[2].content, {
            type = ui.TYPE.Widget,
                props = {
                    anchor = util.vector2(1, 0),
                    relativePosition = util.vector2(1, 0),
                    position = util.vector2(-8, 8),
                    size = util.vector2(28, 28),
                },
                content = ui.content {
                {
                    template = I.MWUI.templates.bordersThick,
                    props = {
                        size = util.vector2(28, 28),
                        anchor = util.vector2(1, 0),
                        relativePosition = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = "?",
                                textSize = 16,
                                textColor = Editor.uiColors.DEFAULT,
                                anchor = util.vector2(0.5, 0.5),
                                relativePosition = util.vector2(0.5, 0.5),
                            }
                        }
                    },
                    events = {
                        mouseClick = async:callback(function()
                            if modalElement then
                                modalElement:destroy()
                                modalElement = nil
                            end
                            modalElement = ui.create(uiTemplates.modal(
                                {
                                    type = ui.TYPE.Flex,
                                    props = {
                                        autoSize = false,
                                        relativeSize = util.vector2(1, 1),
                                        size = util.vector2(-32, 0),
                                        position = util.vector2(16, 0),
                                        arrange = ui.ALIGNMENT.Center,
                                    },
                                    content = ui.content {
                                        createPaddingTemplate(8),
                                        {
                                            template = I.MWUI.templates.textParagraph,
                                            props = {
                                                text = Editor.controllerMode and l10n('UI_EditorControls_Gamepad_Text') or l10n('UI_EditorControls_Text'),
                                                textAlignH = ui.ALIGNMENT.Start,
                                            },
                                            external = {
                                                grow = 1,
                                                stretch = 1,
                                            }
                                        },
                                        createPaddingTemplate(8),
                                        uiTemplates.button(l10n('UI_Button_Close') or "Close", util.vector2(128, 32), function()
                                            if modalElement then
                                                modalElement:destroy()
                                                modalElement = nil
                                            end
                                        end)
                                    }
                                },
                                util.vector2(500, 300),
                                l10n('UI_EditorControls')
                            ))
                        end)
                    }
                }
            }
        })

        table.insert(manager.content[2].content, {
            
        })

        local middleBox = manager.content[2].content[1].content[2].content

        table.insert(middleBox, createPaddingTemplate(8))
        table.insert(middleBox, {
            template = I.MWUI.templates.textHeader,
            props = {
                text = (Editor.hideSongInfo and "[+]" or "[-]") .. " " .. l10n('UI_PRoll_SongInfo'),
                textAlignH = ui.ALIGNMENT.Center,
                autoSize = false,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(0, 32),
            },
            events = {
                mouseClick = async:callback(function()
                    Editor.hideSongInfo = not Editor.hideSongInfo
                    redrawPianoRollEditor()
                end),
            },
        })

        local sizeY = Editor.hideSongInfo and 0 or 32
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongTitle'), Editor.song.title, sizeY, function(text, self)
            if not tostring(text) then
                self.props.text = Editor.song.title
            else
                Editor.song.title = text
                saveDraft()
                redrawPianoRollEditor()
            end
        end))
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongTempo'), tostring(Editor.song.tempo), sizeY, function(text, self)
            if not tonumber(text) then
                self.props.text = tostring(Editor.song.tempo)
            else
                Editor.song.tempo = tonumber(text)
                saveDraft()
                redrawPianoRollEditor()
            end
        end))
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongTimeSig'), Editor.song.timeSig[1] .. '/' .. Editor.song.timeSig[2], sizeY, function(text, self)
            local timeSig = parseTimeSignature(text)
            if not timeSig then
                self.props.text = Editor.song.timeSig[1] .. '/' .. Editor.song.timeSig[2]
            elseif not numMatches(Editor.song.timeSig[1], timeSig[1]) or not numMatches(Editor.song.timeSig[2], timeSig[2]) then
                Editor.song.timeSig = timeSig
                saveDraft()
                redrawPianoRollEditor()
            end
        end))
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongLoopStart'), tostring(Editor.song.loopBars[1]), sizeY, function(text, self)
            local parsed = parseExp(text)
            if not parsed or parsed < 0 then
                self.props.text = tostring(Editor.song.loopBars[1])
            elseif not numMatches(Editor.song.loopBars[1], parsed) then
                Editor.song.loopBars[1] = parsed
                saveDraft()
                redrawPianoRollEditor()
            end
        end))
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongLoopEnd'), tostring(Editor.song.loopBars[2]), sizeY, function(text, self)
            local parsed = parseExp(text)
            if not parsed or parsed > Editor.song.lengthBars then
                self.props.text = tostring(Editor.song.loopBars[2])
            elseif not numMatches(Editor.song.loopBars[2], parsed) then
                Editor.song.loopBars[2] = parsed
                saveDraft()
                redrawPianoRollEditor()
            end
        end))
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongLoopCount'), tostring(Editor.song.loopTimes or 0), sizeY, function(text, self)
            local parsed = parseExp(text)
            if not parsed or parsed < 0 then
                self.props.text = tostring(Editor.song.loopTimes or 0)
            elseif not numMatches(Editor.song.loopTimes or 0, parsed) then
                Editor.song.loopTimes = parsed
                saveDraft()
                redrawPianoRollEditor()
            end
        end))
        table.insert(middleBox, uiTemplates.labeledTextEdit(l10n('UI_PRoll_SongEnd'), tostring(Editor.song.lengthBars), sizeY, function(text, self)
            local parsed = parseExp(text)
            if not parsed or parsed < 1 then
                self.props.text = tostring(Editor.song.lengthBars)
            elseif not numMatches(Editor.song.lengthBars, parsed) then
                Editor.song.lengthBars = parsed
                saveDraft()
                redrawPianoRollEditor()
            end
        end))

        local function updateEditorOverlayRows()
            local bgrRows = pianoRoll.editorWrapper.layout.content[1].content[1].content[1]
            if bgrRows then
                bgrRows.props.resource = Editor:getScaleTexture()
                bgrRows.props.position = util.vector2(0, -16 * (Editor.song.scale.root - 1))
                bgrRows.props.size = util.vector2(0, 16 * (Editor.song.scale.root - 1))
                pianoRoll.editorWrapper:update()
            end
        end

        local scaleSelect = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(0, sizeY),
                arrange = ui.ALIGNMENT.Center,
                grow = 1,
                stretch = 1,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = l10n('UI_PRoll_Scale'),
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
                {
                    template = createPaddingTemplate(Editor.hideSongInfo and 0 or 4),
                },
                uiTemplates.select(Song.Note, Editor.song.scale.root, 0, false, sizeY, function(newVal)
                    Editor.song.scale.root = newVal
                    updateEditorOverlayRows()
                    saveDraft()
                end),
                uiTemplates.select(Song.Mode, Editor.song.scale.mode, 75, true, sizeY, function(newVal)
                    Editor.song.scale.mode = newVal
                    updateEditorOverlayRows()
                    saveDraft()
                end)
            }
        }
        table.insert(middleBox, scaleSelect)

        local snapSelect = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(0, sizeY),
                arrange = ui.ALIGNMENT.Center,
                grow = 1,
                stretch = 1,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = l10n('UI_PRoll_Snap'),
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
                {
                    template = createPaddingTemplate(Editor.hideSongInfo and 0 or 4),
                },
                uiTemplates.select(Editor.SNAP_LEVELS, Editor.snapLevel, 0, true, sizeY, function(newVal)
                    Editor.snapLevel = newVal
                    --pianoRollLastNoteSize = Editor.song.resolution * (4 / Editor.song.timeSig[2])
                    --updatePianoRollBarNumberLabels()
                    --updatePianoRoll()
                end),
                {
                    template = createPaddingTemplate(Editor.hideSongInfo and 0 or 4),
                },
                uiTemplates.checkbox(Editor.snap, 'CheckboxOn', 'CheckboxOff', function(checked)
                    Editor.snap = checked
                end),
            }
        }
        table.insert(middleBox, snapSelect)
        table.insert(middleBox, createPaddingTemplate(Editor.hideSongInfo and 0 or 8))

        table.insert(middleBox, {
            template = I.MWUI.templates.textHeader,
            props = {
                text = l10n('UI_PRoll_Parts'),
                textAlignH = ui.ALIGNMENT.Center,
                autoSize = false,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(0, 32),
            },
        })
        -- Calculate the height for the parts scrollable.
        -- Subtract heights of all visible song info boxes, headers, new part button, song actions, and paddings.
        local partsScrollableHeight = calcContentHeight()
        -- Subtract "Song Info" header
        partsScrollableHeight = partsScrollableHeight - 32
        -- Subtract all song info boxes (each is sizeY, which is 0 if hidden, 32 if shown, 8 boxes)
        local songInfoBoxCount = 7
        local sizeY = Editor.hideSongInfo and 0 or 32
        partsScrollableHeight = partsScrollableHeight - (songInfoBoxCount * sizeY)
        -- Subtract scale and snap selects (each is sizeY)
        partsScrollableHeight = partsScrollableHeight - (2 * sizeY)
        -- Subtract padding after song info (8 if shown, 0 if hidden)
        partsScrollableHeight = partsScrollableHeight - (Editor.hideSongInfo and 0 or 16)
        -- Subtract "Parts" header
        partsScrollableHeight = partsScrollableHeight - 32
        -- Subtract new part button (32)
        partsScrollableHeight = partsScrollableHeight - 32
        -- Subtract "Finalize Draft" and "Delete Draft" buttons (each 32)
        partsScrollableHeight = partsScrollableHeight - 64
        -- Subtract all paddings between elements
        partsScrollableHeight = partsScrollableHeight - 32

        -- Prepare the parts list content
        local parts = {}
        for _, v in ipairs(Editor.song.parts) do
            table.insert(parts, v)
        end
        table.sort(parts, function(a, b)
            return a.instrument < b.instrument
        end)
        local partsListContent = ui.content{}
        for _, part in ipairs(parts) do
            partsListContent:add(uiTemplates.partDisplay(part))
        end

        -- Save scroll position if possible
        local oldPartsY = 0
        if partsScrollable and partsScrollable.layout and partsScrollable.layout.content[1] and partsScrollable.layout.content[1].props then
            oldPartsY = partsScrollable.layout.content[1].props.position.y
        end

        -- Create the scrollable for parts
        partsScrollable = uiTemplates.scrollable(
            util.vector2(ui.screenSize().x * Editor.windowMiddleBoxXMult + Editor.windowMiddleBoxXSize - 20, partsScrollableHeight),
            partsListContent,
            util.vector2(0, 48 * #parts) -- 48 is the height of each partDisplay
        )
        partsScrollable.layout.content[1].props.position = util.vector2(0, oldPartsY)
        table.insert(middleBox, partsScrollable)

        table.insert(middleBox, {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(0, 32),
                relativeSize = util.vector2(1, 0),
                align = ui.ALIGNMENT.Start,
                relativePosition = util.vector2(0, 1),
                anchor = util.vector2(0, 1),
                position = util.vector2(0, -32),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.bordersThick,
                    props = {
                        size = util.vector2(0, 32),
                        relativeSize = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = l10n('UI_PRoll_NewPart'),
                                anchor = util.vector2(0.5, 0.5),
                                relativePosition = util.vector2(0.5, 0.5),
                            },
                        },
                    },
                    events = {
                        mouseClick = async:callback(function()
                            Editor:destroyUI()
                            Editor.activePart = Editor.song:createNewPart()
                            Editor.partsPlaying[Editor.activePart.index] = true
                            Editor:createUI()
                        end),
                    }
                },
            }
        })

        --[[table.insert(manager.content[2].content, {
            type = ui.TYPE.Flex,
            name = 'importExport',
            props = {
                autoSize = false,
                size = util.vector2(0, 96),
                relativeSize = util.vector2(1, 0),
                align = ui.ALIGNMENT.Start,
                relativePosition = util.vector2(0, 1),
                anchor = util.vector2(0, 1),
                position = util.vector2(0, -32),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.borders,
                    name = 'importExportTextBox',
                    props = {
                        size = util.vector2(0, 32),
                        relativeSize = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textEditLine,
                            props = {
                                text = default,
                                textAlignV = ui.ALIGNMENT.Center,
                                relativeSize = util.vector2(1, 1),
                            },
                            external = {
                                grow = 1,
                                stretch = 1,
                            },
                            events = {
                                textChanged = async:callback(function(text, self)
                                    if text == '' then
                                        Editor:destroyUI()
                                        Editor:createUI()
                                    else
                                        self.props.text = text
                                        wrapperElement:update()
                                    end
                                end),
                            }
                        }
                    },
                },
                {
                    template = I.MWUI.templates.bordersThick,
                    props = {
                        size = util.vector2(0, 32),
                        relativeSize = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = 'Import Song',
                                anchor = util.vector2(0.5, 0.5),
                                relativePosition = util.vector2(0.5, 0.5),
                            },
                        },
                    },
                    events = {
                        mouseClick = async:callback(function()
                            importSong()
                        end),
                    }
                },
                {
                    template = I.MWUI.templates.bordersThick,
                    props = {
                        size = util.vector2(0, 32),
                        relativeSize = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = 'Export Song',
                                anchor = util.vector2(0.5, 0.5),
                                relativePosition = util.vector2(0.5, 0.5),
                            },
                        },
                    },
                    events = {
                        mouseClick = async:callback(function()
                            exportSong()
                        end),
                    }
                },
            }
        })]]

        table.insert(manager.content[2].content, {
            type = ui.TYPE.Flex,
            name = 'songActions',
            props = {
                autoSize = false,
                size = util.vector2(0, 64),
                relativeSize = util.vector2(1, 0),
                align = ui.ALIGNMENT.Start,
                relativePosition = util.vector2(0, 1),
                anchor = util.vector2(0, 1),
                position = util.vector2(0, -32),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.bordersThick,
                    props = {
                        size = util.vector2(0, 32),
                        relativeSize = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = l10n('UI_PRoll_FinalizeDraft'),
                                anchor = util.vector2(0.5, 0.5),
                                relativePosition = util.vector2(0.5, 0.5),
                            },
                        },
                    },
                    events = {
                        mouseClick = async:callback(function()
                            createFinalizeDraftModal()
                        end),
                    }
                },
                {
                    template = I.MWUI.templates.bordersThick,
                    props = {
                        size = util.vector2(0, 32),
                        relativeSize = util.vector2(1, 0),
                    },
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = l10n('UI_PRoll_DeleteDraft'),
                                textColor = Editor.uiColors.RED_DESAT,
                                anchor = util.vector2(0.5, 0.5),
                                relativePosition = util.vector2(0.5, 0.5),
                            },
                        },
                    },
                    events = {
                        mouseClick = async:callback(function()
                            modalElement = ui.create(uiTemplates.confirmModal(function()
                                local songs = storage.playerSection('Bardcraft'):getCopy('songs/drafts') or {}
                                for i, song in ipairs(songs) do
                                    if song.id == Editor.song.id then
                                        table.remove(songs, i)
                                        break
                                    end
                                end
                                storage.playerSection('Bardcraft'):set('songs/drafts', songs)
                                -- setDraft(nil)
                                -- setMainContent(getSongTab())
                                Editor.song = nil
                                Editor:setState(Editor.STATE.SONG)
                            end))
                        end),
                    }
                },
            }
        })

        pianoRoll.editorWrapper = ui.create {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(calcPianoRollEditorWidth(), calcPianoRollEditorHeight()),
                position = util.vector2(96, 0)
            },
            content = ui.content {
                uiTemplates.pianoRollEditor(Editor.song.timeSig, 16),
            },
            events = {
                mouseMove = async:callback(function(e)
                    if input.isMouseButtonPressed(2) then
                        if textFocused then
                            Editor:destroyUI()
                            Editor:createUI()
                            textFocused = false
                        end
                        lastMouseDragPos = lastMouseDragPos or util.vector2(e.position.x, e.position.y)
                        local dx = e.position.x - lastMouseDragPos.x
                        local dy = e.position.y - lastMouseDragPos.y
                        lastMouseDragPos = util.vector2(e.position.x, e.position.y)
                        if pianoRoll.focused then
                            pianoRoll.scrollX = util.clamp(pianoRoll.scrollX + dx, -pianoRoll.scrollXMax, 0)
                            pianoRoll.scrollY = util.clamp(pianoRoll.scrollY + dy, -pianoRoll.scrollYMax, 0)
                            updatePianoRoll()
                            if math.abs(pianoRoll.scrollX - pianoRoll.scrollLastPopulateX) > pianoRoll.scrollPopulateWindowSize then
                                pianoRoll.scrollLastPopulateX = pianoRoll.scrollX
                                populateNotes()
                            end
                        end
                    end
                    if e.button == 1 and pianoRoll.dragStart then
                        local offset = editorOffsetToRealOffset(e.offset + util.vector2(pianoRoll.dragOffset and pianoRoll.dragOffset.x or 0, 0))
                        local note, tick = realOffsetToNote(offset)
                        local snap = calcSnapFactor()
                        tick = util.round(tick / snap) * snap + 1
                        
                        local noteData = Editor.noteMap[pianoRoll.activeNote]
                        if pianoRoll.dragType == DragType.MOVE then
                            noteData.time = util.clamp(tick, 1, math.huge)
                            if note ~= noteData.note then
                                playingNoteSound = playNoteSound(note)
                                if Song.getInstrumentProfile(Editor.activePart.instrument).sustain then
                                    stopNoteSound(noteData.note)
                                end
                            end
                            noteData.note = note
                        elseif pianoRoll.dragType == DragType.RESIZE_RIGHT then
                            noteData.duration = util.clamp(tick - noteData.time, snap, math.huge)
                        end
                        Editor.noteMap[pianoRoll.activeNote] = noteData
                        saveNotes()
                        local layout = pianoRoll.editorWrapper.layout.content[1].content[3].content
                        local notePos
                        for i, note in ipairs(layout) do
                            if note.name == tostring(noteData.id) then
                                notePos = i
                                break
                            end
                        end
                        layout[notePos] = uiTemplates.pianoRollNote(noteData.id, noteData.note, noteData.time, noteData.duration)
                        pianoRoll.lastNoteSize = noteData.duration
                        pianoRoll.editorWrapper:update()
                    end
                end),
                mousePress = async:callback(function(e)
                    if textFocused then
                        Editor:destroyUI()
                        Editor:createUI()
                        textFocused = false
                    end
                    if e.button ~= 1 then return end
                    if e.offset.y < 24 then
                        -- Set playback pos and start playback
                        local offset = editorOffsetToRealOffset(e.offset)
                        stopAllSounds()
                        Editor.playback = true
                        Editor.song:resetPlayback()
                        Editor.song.playbackTickCurr = Editor.song:beatToTick(editorOffsetToRealOffset(e.offset).x / calcBeatWidth(Editor.song.timeSig[2]))
                        Editor.song.playbackTickPrev = Editor.song.playbackTickCurr
                        return
                    elseif Editor.activePart then
                        local note, tick = realOffsetToNote(editorOffsetToRealOffset(e.offset))
                        local snap = calcSnapFactor()
                        tick = math.floor(tick / snap) * snap + 1
                        playingNoteSound = playNoteSound(note)
                        pianoRoll.activeNote = addNote(note, tick, pianoRoll.lastNoteSize, true)
                        pianoRoll.dragStart = editorOffsetToRealOffset(e.offset)
                        pianoRoll.dragOffset = util.vector2(0, 0)
                        pianoRoll.dragType = DragType.MOVE
                        saveNotes()
                    end
                end),
                mouseRelease = async:callback(function(e)
                    if e.button == 2 then
                        lastMouseDragPos = nil
                    end
                    if e.button == 1 and pianoRoll.activeNote then
                        pianoRoll.dragStart = nil
                        pianoRoll.dragType = DragType.NONE
                        pianoRoll.lastNoteSize = Editor.noteMap[pianoRoll.activeNote].duration
                        pianoRoll.activeNote = nil
                        pianoRoll.activeNoteElement = nil
                        if playingNoteSound and Song.getInstrumentProfile(Editor.activePart.instrument).sustain then
                            ambient.stopSoundFile(playingNoteSound)
                            playingNoteSound = nil
                        end
                        pianoRoll.editorWrapper:update()
                        saveNotes()
                    end
                end),
                focusLoss = async:callback(function()
                    lastMouseDragPos = nil
                end),
            }
        }

        initNotes()

        pianoRoll.keyboardWrapper = ui.create{
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(96, calcPianoRollEditorHeight()),
                position = util.vector2(0, 0)
            },
            content = ui.content {
                uiTemplates.pianoRollKeyboard(Editor.song.timeSig),
            },
        }

        pianoRoll.element = ui.create { 
            type = ui.TYPE.Widget,
            props = {
                size = calcPianoRollWrapperSize(),
            },
            content = ui.content { 
                pianoRoll.keyboardWrapper,
                pianoRoll.editorWrapper,
            } 
        }

        pianoRoll.wrapper = ui.create{
                type = ui.TYPE.Widget,
                name = 'pianoRoll',
                props = {
                    size = calcPianoRollWrapperSize(),
                },
                content = ui.content {
                    pianoRoll.element
                },
        }
        table.insert(manager.content[3].content, pianoRoll.wrapper)
        editorOverlay = pianoRoll.editorWrapper.layout.content[1].content.pianoRollOverlay
        editorMarkers = pianoRoll.editorMarkersWrapper.layout.content.pianoRollMarkers
        editorNotes = pianoRoll.editorWrapper.layout.content[1].content.pianoRollNotes
    end
    return manager
end

local function autoAssignParts()
    if not Editor.performanceSelectedSong then return end

    -- Clear previous assignments
    Editor.performancePartAssignments = {}

    local parts = {}
    for _, v in ipairs(Editor.performanceSelectedSong.parts) do
        table.insert(parts, v)
    end

    -- Helper: get instrument name for a part
    local function getInstrumentName(part)
        return Song.getInstrumentProfile(part.instrument).name
    end

    -- Helper: check if performer has instrument for part
    local function performerHasInstrument(performer, part)
        local inventory = types.Actor.inventory(performer)
        local partInstrument = getInstrumentName(part)
        for item, _ in pairs(Data.InstrumentItems[partInstrument] or {}) do
            if inventory:find(item) then
                return true
            end
        end
        return false
    end

    -- Helper: get confidence for performer/part
    local function getConfidence(performer, part)
        local info = Editor.performersInfo[performer.id]
        if not info then return 0 end
        local knownSong = info.knownSongs and info.knownSongs[Editor.performanceSelectedSong.id]
        if not knownSong then return 0 end
        local conf = knownSong.partConfidences[part.instrument]
        if conf then
            return conf[part.numOfType] or 0
        end
        return 0
    end

    -- Build a list of performers: non-player first, then player
    local player = nearby.players[1]
    local performers = {}
    for _, v in ipairs(nearby.actors) do
        if (v.type == types.NPC and Editor.troupeMembers[v.id]) then
            table.insert(performers, v)
        end
    end
    table.insert(performers, player)

    -- Track assigned parts
    local assignedParts = {}

    -- Assign non-player performers first
    for _, performer in ipairs(performers) do
        if performer ~= player then
            -- Find all parts this performer can play
            local candidateParts = {}
            for _, part in ipairs(parts) do
                if not assignedParts[part.index] and performerHasInstrument(performer, part) then
                    table.insert(candidateParts, part)
                end
            end
            -- Pick the one with highest confidence
            table.sort(candidateParts, function(a, b)
                return getConfidence(performer, a) > getConfidence(performer, b)
            end)
            local chosen = candidateParts[1]
            if chosen then
                Editor.performancePartAssignments[performer.id] = chosen.index
                assignedParts[chosen.index] = true
            end
        end
    end

    -- Assign player
    do
        -- Find all unassigned parts player can play
        local playerCandidateParts = {}
        for _, part in ipairs(parts) do
            if not assignedParts[part.index] and performerHasInstrument(player, part) then
                table.insert(playerCandidateParts, part)
            end
        end
        if #playerCandidateParts > 0 then
            -- Pick the one with highest confidence
            table.sort(playerCandidateParts, function(a, b)
                return getConfidence(player, a) > getConfidence(player, b)
            end)
            local chosen = playerCandidateParts[1]
            Editor.performancePartAssignments[player.id] = chosen.index
            assignedParts[chosen.index] = true
        else
            -- All parts assigned, pick the one player is most confident in and can play
            local fallbackParts = {}
            for _, part in ipairs(parts) do
                if performerHasInstrument(player, part) then
                    table.insert(fallbackParts, part)
                end
            end
            if #fallbackParts > 0 then
                table.sort(fallbackParts, function(a, b)
                    return getConfidence(player, a) > getConfidence(player, b)
                end)
                local chosen = fallbackParts[1]
                Editor.performancePartAssignments[player.id] = chosen.index
            end
        end
    end

    setMainContent(getPerformanceTab())
end

local scrollableSong = nil

getPerformanceTab = function()
    local performance = auxUi.deepLayoutCopy(uiTemplates.baseTab)
    local flexContent = performance.content[1].content[1].content
    
    local doPerformers = Editor.troupeSize > 0
    
    Editor.songs = getSongs()
    local scrollableSongContent = ui.content{}
    local itemHeight = 40
    local scrollableHeight = 450 * screenSize.y / 1080
    local scrollableWidth = 320 * screenSize.x / 1920

    if not doPerformers then
        scrollableWidth = scrollableWidth * 1.5
    end

    if screenSize.y <= 720 then
        scrollableHeight = scrollableHeight / 2
        itemHeight = 40
    end

    if Editor.performanceSelectedPerformer and Editor.performanceSelectedPerformer.id ~= self.id and not Editor.troupeMembers[Editor.performanceSelectedPerformer.id] then
        Editor.performanceSelectedPerformer = nil
    end
    for id, _ in pairs(Editor.performancePartAssignments) do
        if id ~= self.id and not Editor.troupeMembers[id] then
            Editor.performancePartAssignments[id] = nil
        end
    end

    -- Combine known songs from all troupe members (including player)
    local knownSongs = {}
    for _, actor in ipairs(nearby.actors) do
        if (actor.type == types.NPC and Editor.troupeMembers[actor.id]) or actor.type == types.Player then
            local performerInfo = Editor.performersInfo[actor.id]
            if performerInfo and performerInfo.knownSongs then
                for songId, songData in pairs(performerInfo.knownSongs) do
                    knownSongs[songId] = true
                end
            end
        end
    end

    local player = nearby.players[1]
    if not doPerformers then Editor.performanceSelectedPerformer = player end

    -- Sort songs: bookmarked first, then alphabetically
    table.sort(Editor.songs, function(a, b)
        local aBookmarked = Editor.bookmarkedSongs[a.id] and 1 or 0
        local bBookmarked = Editor.bookmarkedSongs[b.id] and 1 or 0
        if aBookmarked ~= bBookmarked then
            return aBookmarked > bBookmarked
        end
        return a.title < b.title
    end)
    for i, song in ipairs(Editor.songs) do
        if knownSongs[song.id] then
            scrollableSongContent:add(uiTemplates.songDisplay(song, itemHeight, Editor.performanceSelectedSong and song.id == Editor.performanceSelectedSong.id, function()
                if Editor.performanceSelectedSong and Editor.performanceSelectedSong.id == song.id then
                    Editor.performanceSelectedSong = nil
                else
                    Editor.performanceSelectedSong = setmetatable(song, { __index = Song})
                end
                Editor.performanceSelectedPart = nil
                Editor.performancePartAssignments = {}
                setMainContent(getPerformanceTab())
            end))
        end
    end

    local oldScrollableSongY = 0
    if scrollableSong and scrollableSong.layout and scrollableSong.layout.content[1] and scrollableSong.layout.content[1].props then
        oldScrollableSongY = scrollableSong.layout.content[1].props.position.y
    end
    scrollableSong = uiTemplates.scrollable(util.vector2(scrollableWidth, scrollableHeight), scrollableSongContent, util.vector2(0, itemHeight * #scrollableSongContent + 4))
    scrollableSong.layout.content[1].props.position = util.vector2(0, oldScrollableSongY)

    local scrollablePerformersContent = ui.content{}
    if doPerformers then
        for _, v in ipairs(nearby.actors) do
            if (v.type == types.NPC and Editor.troupeMembers[v.id]) or v.type == types.Player then
                scrollablePerformersContent:add(uiTemplates.performerDisplay(v, itemHeight, Editor.performanceSelectedPerformer and (v.id == Editor.performanceSelectedPerformer.id), function()
                    if Editor.performanceSelectedPerformer and Editor.performanceSelectedPerformer.id == v.id then
                        Editor.performanceSelectedPerformer = nil
                    else
                        Editor.performanceSelectedPerformer = v
                    end
                    setMainContent(getPerformanceTab())
                end))
            end
        end
    end
    local scrollablePerformers = uiTemplates.scrollable(util.vector2(scrollableWidth, scrollableHeight - 32), scrollablePerformersContent, util.vector2(0, itemHeight * #scrollablePerformersContent + 4))
    local autoAssignButton = uiTemplates.button(l10n('UI_Button_AutoAssignParts'), util.vector2(scrollableWidth, 32), autoAssignParts)
    autoAssignButton.props.anchor = util.vector2(0, 1)
    autoAssignButton.props.relativePosition = util.vector2(0, 1)

    local scrollablePartsContent = ui.content{}
    if Editor.performanceSelectedSong then
        local parts = {}
        for _, v in ipairs(Editor.performanceSelectedSong.parts) do
            table.insert(parts, v)
        end
        table.sort(parts, function(a, b)
            return a.instrument < b.instrument or (a.instrument == b.instrument and a.title < b.title)
        end)
        for _, part in ipairs(parts) do
            local selected = false
            local show = true
            local confidence = 0
            if Editor.performanceSelectedPerformer then
                if configPlayer.options.bHideUnplayableParts then
                    show = false
                    local inventory = types.Actor.inventory(Editor.performanceSelectedPerformer)
                    local partInstrument = Song.getInstrumentProfile(part.instrument).name
                    for item, _ in pairs(Data.InstrumentItems[partInstrument] or {}) do
                        if inventory:find(item) then
                            show = true
                            break
                        end
                    end
                end
                selected = part.index == Editor.performancePartAssignments[Editor.performanceSelectedPerformer.id]
                if Editor.performersInfo[Editor.performanceSelectedPerformer.id] then
                    local knownSong = Editor.performersInfo[Editor.performanceSelectedPerformer.id].knownSongs[Editor.performanceSelectedSong.id]
                    if knownSong then
                        confidence = knownSong.partConfidences[part.instrument] and knownSong.partConfidences[part.instrument][part.numOfType] or 0
                    end
                end
            end
            if show then
                scrollablePartsContent:add(uiTemplates.partDisplaySmall(part, itemHeight, selected, confidence * 100, function()
                    if not Editor.performanceSelectedPerformer then return end
                    if Editor.performancePartAssignments[Editor.performanceSelectedPerformer.id] == part.index then
                        Editor.performancePartAssignments[Editor.performanceSelectedPerformer.id] = nil
                    else
                        Editor.performancePartAssignments[Editor.performanceSelectedPerformer.id] = part.index
                    end
                    setMainContent(getPerformanceTab())
                end))
            end
        end
    end
    local scrollableParts = uiTemplates.scrollable(util.vector2(scrollableWidth, scrollableHeight), scrollablePartsContent, util.vector2(0, itemHeight * #scrollablePartsContent + 4))

    local selectedSongInfoTitle, selectedSongInfoDescription, selectedSongPerformButtons, practiceEfficiency = {}, {}, {}, {}
    if Editor.performanceSelectedSong then
        selectedSongInfoTitle = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = l10n('UI_PRoll_SongTitle') .. ': ',
                    }
                },
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = Editor.performanceSelectedSong.title,
                    }
                },
            }
        }
        selectedSongInfoDescription = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            external = {
                grow = 1,
                stretch = 1,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = l10n('UI_PRoll_SongDescription') .. ': ',
                    }
                },
                {
                    template = I.MWUI.templates.textParagraph,
                    props = {
                        text = Editor.performanceSelectedSong.desc or l10n('UI_Song_NoDescription'),
                    },
                    external = {
                        grow = 1,
                        stretch = 1,
                    },
                },
            }
        }
        selectedSongPerformButtons = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(0, 32),
                align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0, 1),
                anchor = util.vector2(0, 1),
                position = util.vector2(0, -96),
            },
            content = ui.content {
                uiTemplates.button(l10n('UI_Button_Perform'), util.vector2(192, 32), function()
                    startPerformance(Song.PerformanceType.Perform)
                end),
                {
                    template = I.MWUI.templates.interval,
                },
                uiTemplates.button(l10n('UI_Button_Practice'), util.vector2(192, 32), function()
                    startPerformance(Song.PerformanceType.Practice)
                end),
                {
                    template = I.MWUI.templates.interval,
                },
                uiTemplates.button(l10n('UI_Button_PlayIdly'), util.vector2(192, 32), function()
                    startPerformance(Song.PerformanceType.Ambient)
                end),
            }
        }
        practiceEfficiency = configGlobal.options.bEnablePracticeEfficiency and {
            template = I.MWUI.templates.textNormal,
            props = {
                text = l10n('UI_PracticeEfficiency'):gsub('%%{efficiency}', tostring(util.round((Editor.performersInfo[self.id] and Editor.performersInfo[self.id].practiceEfficiency or 0)* 100))),
                align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0.5, 1),
                anchor = util.vector2(0.5, 1),
                position = util.vector2(0, -64),
            }
        } or {}
    end

    table.insert(flexContent, {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            relativeSize = util.vector2(1, 1),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            createPaddingTemplate(16),
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                        },
                        content = ui.content {
                            scrollableSong,
                            {
                                template = I.MWUI.templates.interval
                            },
                            doPerformers and {
                                type = ui.TYPE.Flex,
                                content = ui.content {
                                    scrollablePerformers,
                                    autoAssignButton
                                }
                            } or {},
                            doPerformers and {
                                template = I.MWUI.templates.interval
                            } or {},
                            scrollableParts
                        }
                    },
                    {
                        template = I.MWUI.templates.interval,
                    },
                    {
                        type = ui.TYPE.Flex,
                        external = {
                            stretch = 1,
                        },
                        content = ui.content {
                            selectedSongInfoTitle,
                            selectedSongInfoDescription,
                        }
                    },
                }
            },      
        }
    })
    table.insert(performance.content[1].content, selectedSongPerformButtons)
    table.insert(performance.content[1].content, practiceEfficiency)
    return performance
end

getStatsTab = function()
    local player = nearby.players[1]
    if not player then return {} end
    local playerInfo = Editor.performersInfo[player.id]
    if not playerInfo then return {} end

    local level = playerInfo.performanceSkill.level or 1
    local maxLevel = level >= 100
    local xp = playerInfo.performanceSkill.xp or 0
    local req = playerInfo.performanceSkill.req or 10
    local progress = maxLevel and 1 or (xp / req)
    local rank = l10n('UI_Lvl_Performance_' .. math.floor(level / 10))

    local stats = auxUi.deepLayoutCopy(uiTemplates.baseTab)
    local flexContent = stats.content[1].content[1].content -- This is the main vertical flex for the tab

    -- XP Bar Section
    table.insert(flexContent, {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            relativeSize = util.vector2(1, 0), -- Takes full width, height is auto based on content
            size = util.vector2(0, 128),      -- Fixed height for this section
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            createPaddingTemplate(8),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(1, 0),
                    size = util.vector2(0, 32),
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = l10n('UI_Lvl_Rank') .. ':',
                            textSize = 24,
                        }
                    },
                    createPaddingTemplate(4),
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = rank,
                            textSize = 24,
                        }
                    },
                }
            },
            createPaddingTemplate(8),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(1, 0),
                    size = util.vector2(0, 32), -- Height of the XP bar row
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = tostring(level),
                            textSize = 16,
                            textColor = Editor.uiColors.DEFAULT,
                        }
                    },
                    createPaddingTemplate(8),
                    {
                        template = I.MWUI.templates.borders,
                        props = {
                            autoSize = false,
                            relativeSize = util.vector2(0.8, 1), -- 80% width of this row, full height
                            size = util.vector2(0, 0), -- Actual size determined by relativeSize
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = ui.texture {
                                        path = 'textures/Bardcraft/ui/xpbar.dds',
                                    },
                                    tileH = true,
                                    tileV = false,
                                    relativeSize = util.vector2(progress, 1),
                                }
                            },
                            maxLevel and {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = l10n('UI_Lvl_Max'),
                                    textSize = 16,
                                    textColor = Editor.uiColors.DEFAULT_LIGHT,
                                    anchor = util.vector2(0.5, 0.5),
                                    relativePosition = util.vector2(0.5, 0.5),
                                    relativeSize = util.vector2(0, 1),
                                    textAlignV = ui.ALIGNMENT.Center,
                                }
                            } or {},
                        }
                    },
                    createPaddingTemplate(8),
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = maxLevel and '--' or (tostring(level + 1)),
                            textSize = 16,
                            textColor = Editor.uiColors.DEFAULT,
                        }
                    },
                }
            },
            createPaddingTemplate(4),
            not maxLevel and {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = l10n('UI_Lvl_Progress'):gsub('%%{xp}', tostring(util.round(xp))):gsub('%%{req}', tostring(util.round(req))):gsub('%%{progress}', tostring(util.round(progress * 100))),
                    textSize = 16,
                    textColor = Editor.uiColors.DEFAULT,
                }
            } or {},
            createPaddingTemplate(4),
        }
    })

    -- Data Aggregation
    local reputation = playerInfo.reputation or 0
    local performanceCounts = {
        overall = 0,
        [Song.PerformanceType.Tavern] = 0,
        [Song.PerformanceType.Street] = 0,
        -- Assuming Perform is covered by Tavern/Street for logs, or add if it's a distinct log type
    }
    local goldEarned = {
        overall = 0,
        tavern = 0,
        street = 0,
    }

    local sortedPerformanceLogs = {}
    if playerInfo.performanceLogs then
        for _, log in ipairs(playerInfo.performanceLogs) do
            table.insert(sortedPerformanceLogs, log) -- Create a copy
        end
        table.sort(sortedPerformanceLogs, function(a, b)
            return (a.gameTime or 0) > (b.gameTime or 0) -- Most recent first
        end)

        for _, log in ipairs(sortedPerformanceLogs) do
            if log.type == Song.PerformanceType.Tavern or log.type == Song.PerformanceType.Street then
                performanceCounts.overall = performanceCounts.overall + 1
                if performanceCounts[log.type] ~= nil then -- Check if type exists in our map
                    performanceCounts[log.type] = performanceCounts[log.type] + 1
                end

                local goldThisPerformance = (log.payment or 0) + (log.tips or 0)
                goldEarned.overall = goldEarned.overall + goldThisPerformance
                if log.type == Song.PerformanceType.Tavern then
                    goldEarned.tavern = goldEarned.tavern + goldThisPerformance
                elseif log.type == Song.PerformanceType.Street then
                    goldEarned.street = goldEarned.street + goldThisPerformance
                end
            end
        end
    end

    -- Helper for Labeled Text
    local function createLabeledText(label, value, textSize)
        return {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = false,
                relativeSize = util.vector2(1, 0),
                size = util.vector2(0, textSize + 4), -- Fixed height for each label-value pair
            },
            content = ui.content {
                { template = I.MWUI.templates.textNormal, props = { text = label .. ": ", textSize = textSize, textColor = Editor.uiColors.DEFAULT_LIGHT, textAlignV = ui.ALIGNMENT.Center } },
                { template = I.MWUI.templates.textNormal, props = { text = tostring(value), textSize = textSize, textColor = Editor.uiColors.DEFAULT, textAlignV = ui.ALIGNMENT.Center }, external = { grow = 1 } }
            }
        }
    end

    -- Left Section Content
    local leftSectionContent = ui.content {
        createPaddingTemplate(4),
        createLabeledText(l10n('UI_Stats_Reputation'), reputation, 24),
        createPaddingTemplate(8),
        { template = I.MWUI.templates.textHeader, props = { text = l10n('UI_Stats_Performances'), textSize = 24, } },
        createLabeledText("  " .. l10n('UI_Stats_Overall'), performanceCounts.overall, 20),
        createLabeledText("  " .. l10n('UI_Stats_Tavern'), performanceCounts[Song.PerformanceType.Tavern], 20),
        createLabeledText("  " .. l10n('UI_Stats_Street'), performanceCounts[Song.PerformanceType.Street], 20),
        createPaddingTemplate(8),
        { template = I.MWUI.templates.textHeader, props = { text = l10n('UI_Stats_GoldEarned'), textSize = 24, } },
        createLabeledText("  " .. l10n('UI_Stats_Overall'), l10n('UI_Stats_Gold'):gsub('%%{amount}', tostring(goldEarned.overall)), 20),
        createLabeledText("  " .. l10n('UI_Stats_Tavern'), l10n('UI_Stats_Gold'):gsub('%%{amount}', tostring(goldEarned.tavern)), 20),
        createLabeledText("  " .. l10n('UI_Stats_Street'), l10n('UI_Stats_Gold'):gsub('%%{amount}', tostring(goldEarned.street)), 20),
        createPaddingTemplate(4),
    }

    -- Right Section - Scrollable Logs
    local scrollableLogContent = ui.content {}
    local itemHeight = 48 -- Height of each log entry in the scrollable list
    for i, log in ipairs(sortedPerformanceLogs) do
        if i > 50 then break end
        scrollableLogContent:add(uiTemplates.logDisplaySmall(log, itemHeight))
    end

    local scrollableWidth = calcContentWidth() - 360 - 48
    local scrollableHeight = calcContentHeight() - 128 - 40

    -- The scrollable widget for the right panel.
    -- Viewport width will be determined by parent flex, height is relative to parent flex.
    local scrollableLogsWidget = uiTemplates.scrollable(
        util.vector2(scrollableWidth, scrollableHeight), -- Viewport size: width 0 (auto), height 0 (auto from relativeSize)
        scrollableLogContent,
        util.vector2(0, itemHeight * #scrollableLogContent + 4) -- Total content size
    )

    -- Bottom Section (Horizontal Flex for Left Info and Right Logs)
    local bottomSection = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativeSize = util.vector2(1, 1), -- Fill available space below XP bar
            size = util.vector2(-32, -40),
        },
        content = ui.content {
            { -- Left Panel (Info)
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(0, 1), -- 40% width, full available height
                    size = util.vector2(360, 0),
                    arrange = ui.ALIGNMENT.Start, -- Vertical arrangement from top
                },
                external = { stretch = 1 },
                content = leftSectionContent,
            },
            { -- Spacer
                template = I.MWUI.templates.interval,
                props = { size = util.vector2(16, 0) } -- Fixed width spacer
            },
            { -- Right Panel (Scrollable Logs)
                type = ui.TYPE.Flex, -- This flex container will hold the scrollable
                props = {
                    autoSize = false,
                },
                external = { grow = 1, stretch = 1 },
                content = ui.content { scrollableLogsWidget }
            }
        }
    }
    table.insert(flexContent, createPaddingTemplate(8))
    table.insert(flexContent, bottomSection)

    return stats
end

local logShowing = false

local function setScreenSize()
    local uiScaleX = configPlayer.options.fUiScaleX or 1
    local uiScaleY = configPlayer.options.fUiScaleY or 1
    screenSize = ui.layers[ui.layers.indexOf('Windows')].size or ui.screenSize()
    screenSize = util.vector2(screenSize.x * uiScaleX, screenSize.y * uiScaleY)
end

function Editor:showPerformanceLog(log)
    setScreenSize()
    local sizeX = math.min(1600, screenSize.x * 5/6)
    local sizeY = sizeX * 9/16
    local scaleMod = sizeX / 1600
    
    self:destroyUI()
    I.UI.setMode(I.UI.MODE.Interface, {windows = {}})
    core.sendGlobalEvent('Pause', 'BO_Editor')
    logShowing = true

    local dateString = calendar.formatGameTime('%d %B, %Y', log.gameTime):match("0*(.+)")
    local baseTextSize = math.max(16 * scaleMod, 8)
    local headerSize = baseTextSize * 2
    local textSize = baseTextSize * 1.5

    local function textWithLabel(label, text, size, headerColor, textColor)
        headerColor = headerColor or Editor.uiColors.BOOK_HEADER
        textColor = textColor or Editor.uiColors.BOOK_TEXT
        size = size or textSize
        return {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = label .. ': ',
                        textSize = size,
                        textColor = headerColor,
                    },
                },
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = text,
                        textSize = size,
                        textColor = textColor,
                    },
                    external = {
                        grow = 1,
                        stretch = 1,
                    },
                },
            }
        }
    end
    local qualityString
    if log.quality == 100 then
        qualityString = 'Perfect'
    elseif log.quality >= 95 then
        qualityString = 'Excellent'
    elseif log.quality >= 85 then
        qualityString = 'Great'
    elseif log.quality >= 70 then
        qualityString = 'Good'
    elseif log.quality >= 40 then
        qualityString = 'Mediocre'
    elseif log.quality >= 15 then
        qualityString = 'Bad'
    else
        qualityString = 'Terrible'
    end
    
    local starsTexture = ui.texture {
        path = 'textures/Bardcraft/ui/stars-' .. qualityString .. '.dds',
        size = util.vector2(500, 96),
    }

    qualityString = l10n('UI_Quality_' .. qualityString)

    local tavernNotes = {}
    if log.type == Song.PerformanceType.Tavern then
        local patronComments = {}
        if log.patronComments and #log.patronComments > 0 then
            for _, comment in ipairs(log.patronComments) do
                table.insert(patronComments, {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = comment.name .. ':',
                        textSize = textSize,
                        textColor = Editor.uiColors.BOOK_TEXT,
                    }
                })
                table.insert(patronComments, {
                    template = I.MWUI.templates.textParagraph,
                    props = {
                        text = '"' .. l10n(comment.comment) .. '"',
                        textSize = textSize,
                        textColor = Editor.uiColors.BOOK_TEXT_LIGHT,
                        relativeSize = util.vector2(1, 0),
                        size = util.vector2(-32, 0),
                    },
                })
                table.insert(patronComments, createPaddingTemplate(4 * scaleMod))
            end
        end
        tavernNotes = {
            {
                template = createPaddingTemplate(4 * scaleMod),
            },
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = l10n('UI_PerfLog_NotesFromTheEvening'),
                    textSize = headerSize,
                    textColor = Editor.uiColors.BOOK_HEADER
                },
            },
            {
                template = I.MWUI.templates.horizontalLine,
            },
            {
                template = createPaddingTemplate(8 * scaleMod),
            },
            textWithLabel(l10n('UI_PerfLog_FromThePublican'), ''),
            {
                template = createPaddingTemplate(4 * scaleMod),
            },
            {
                template = I.MWUI.templates.textParagraph,
                props = {
                    text = log.publicanComment and ('"' .. l10n(log.publicanComment) .. '"') or l10n('UI_PerfLog_NoComment'),
                    textSize = textSize,
                    textColor = Editor.uiColors.BOOK_TEXT,
                    relativeSize = util.vector2(1, 0),
                    size = util.vector2(-32, 0),
                },
            },
            {
                template = createPaddingTemplate(8 * scaleMod),
            },
            textWithLabel(l10n('UI_PerfLog_FromThePatrons'), ''),
            {
                template = createPaddingTemplate(4 * scaleMod),
            },
            table.unpack(patronComments),
        }
    end

    local notMaxLevel = log.level < 100
    local xpProg = notMaxLevel and (log.xpCurr / log.xpReq) or 1

    local cellBlurb = 'UI_Blurb_' .. log.cell
    local cellBlurbLoc = l10n(cellBlurb)
    if cellBlurb ~= cellBlurbLoc then
        log.cellBlurb = cellBlurb
    end

    local cell = log.cell
    if log.type == Song.PerformanceType.Street then
        cell = l10n('UI_PerfLog_StreetsOf'):gsub('%%{city}', cell)
    end

    wrapperElement = ui.create {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(sizeX, sizeY),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture {
                        path = 'textures/Bardcraft/ui/tx_performancebook.dds',
                    },
                    relativeSize = util.vector2(1, 1),
                    anchor = util.vector2(0.5, 0.5),
                    relativePosition = util.vector2(0.5, 0.5),
                }
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(0.7, 0.92),
                    anchor = util.vector2(0.5, 0.5),
                    relativePosition = util.vector2(0.5, 0.5),
                    horizontal = true,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = false,
                            relativeSize = util.vector2(0.475, 1), -- left page of the book
                        },
                        content = ui.content {
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = l10n('UI_PerfLog'),
                                    textSize = headerSize,
                                    textColor = Editor.uiColors.BOOK_HEADER
                                },
                            },
                            {
                                template = I.MWUI.templates.horizontalLine,
                            },
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = dateString,
                                    textSize = textSize,
                                    textColor = Editor.uiColors.BOOK_TEXT,
                                },
                            },
                            {
                                template = createPaddingTemplate(4 * scaleMod),
                            },
                            textWithLabel(l10n('UI_PerfLog_Venue'), cell),
                            {
                                template = createPaddingTemplate(4 * scaleMod),
                            },
                            log.cellBlurb and {
                                template = I.MWUI.templates.textParagraph,
                                props = {
                                    text = log.cellBlurb and l10n(log.cellBlurb) or '',
                                    textSize = textSize,
                                    textColor = Editor.uiColors.BOOK_TEXT_LIGHT,
                                    relativeSize = util.vector2(1, 0),
                                    size = util.vector2(-32, 0),
                                },
                            } or {},
                            log.cellBlurb and {
                                template = createPaddingTemplate(4 * scaleMod),
                            } or {},
                            textWithLabel(l10n('UI_PerfLog_Song'), log.songName),
                            {
                                template = createPaddingTemplate(4 * scaleMod),
                            },
                            textWithLabel(l10n('UI_PerfLog_Quality'), qualityString),
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = starsTexture,
                                    size = util.vector2(500 / 2 * scaleMod, 96 / 2 * scaleMod),
                                }
                            },
                            table.unpack(tavernNotes),
                        }
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = false,
                            relativeSize = util.vector2(0.05, 1), -- space between pages
                        }
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = false,
                            relativeSize = util.vector2(0.475, 1), -- right page of the book
                        },
                        content = ui.content {
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = l10n('UI_PerfLog_Rewards'),
                                    textSize = headerSize,
                                    textColor = Editor.uiColors.BOOK_HEADER
                                },
                            },
                            {
                                template = I.MWUI.templates.horizontalLine,
                            },
                            {
                                template = createPaddingTemplate(4 * scaleMod),
                            },
                            textWithLabel(l10n('UI_PerfLog_ExpGained'), ''),
                            {
                                template = createPaddingTemplate(8 * scaleMod),
                            },
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    autoSize = false,
                                    relativeSize = util.vector2(1, 0),
                                    size = util.vector2(0, 96 * scaleMod),
                                    arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            autoSize = false,
                                            relativeSize = util.vector2(1, 0),
                                            size = util.vector2(0, 32 * scaleMod),
                                            horizontal = true,
                                            arrange = ui.ALIGNMENT.Center,
                                            align = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                            {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                    text = tostring(log.level),
                                                    textSize = textSize,
                                                    textColor = Editor.uiColors.BOOK_TEXT,
                                                }
                                            },
                                            createPaddingTemplate(8 * scaleMod),
                                            {
                                                template = I.MWUI.templates.borders,
                                                props = {
                                                    autoSize = false,
                                                    relativeSize = util.vector2(0.8, 0),
                                                    size = util.vector2(0, 32 * scaleMod),
                                                },
                                                content = ui.content {
                                                    {
                                                        type = ui.TYPE.Image,
                                                        props = {
                                                            resource = ui.texture {
                                                                path = 'textures/Bardcraft/ui/xpbar.dds',
                                                            },
                                                            tileH = true,
                                                            tileV = false,
                                                            relativeSize = util.vector2(xpProg, 1),
                                                        }
                                                    },
                                                    {
                                                        template = I.MWUI.templates.textNormal,
                                                        props = {
                                                            text = notMaxLevel and ('+' .. log.xpGain .. ' XP') or l10n('UI_Lvl_Max'),
                                                            textSize = textSize,
                                                            textColor = xpProg < 0.5 and Editor.uiColors.BOOK_TEXT or Editor.uiColors.DEFAULT_LIGHT,
                                                            anchor = util.vector2(xpProg < 0.5 and 0 or (notMaxLevel and 1 or 0.5), 0),
                                                            relativePosition = util.vector2(notMaxLevel and xpProg or 0.5, 0),
                                                            position = util.vector2(notMaxLevel and (xpProg < 0.5 and 4 or -4) or 0, 0),
                                                            relativeSize = util.vector2(0, 1),
                                                            textAlignV = ui.ALIGNMENT.Center,
                                                        }
                                                    }
                                                }
                                            },
                                            createPaddingTemplate(8 * scaleMod),
                                            {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                    text = notMaxLevel and (tostring(log.level + 1)) or '--',
                                                    textSize = textSize,
                                                    textColor = Editor.uiColors.BOOK_TEXT,
                                                }
                                            },
                                        }
                                    },
                                    createPaddingTemplate(4 * scaleMod),
                                    {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                            text = log.levelGain > 0 and l10n('UI_Lvl_Up'):gsub('%%{times}', tostring(log.levelGain)) or '',
                                            textSize = textSize,
                                            textColor = Editor.uiColors.BOOK_HEADER,
                                        }
                                    },
                                    {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                            text = notMaxLevel and l10n('UI_Lvl_Progress'):gsub('%%{xp}', tostring(log.xpCurr)):gsub('%%{req}', tostring(log.xpReq)):gsub('%%{progress}', tostring(util.round(xpProg * 100))) or '',
                                            textSize = textSize,
                                            textColor = Editor.uiColors.BOOK_TEXT,
                                        }
                                    }
                                }
                            },
                            {
                                template = createPaddingTemplate(4 * scaleMod),
                            },
                            textWithLabel(l10n('UI_PerfLog_Outcome'), ''),
                            {
                                template = createPaddingTemplate(4 * scaleMod),
                            },
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    relativeSize = util.vector2(1, 0),
                                    size = util.vector2(0, 96 * scaleMod),
                                },
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = ui.texture {
                                                path = 'textures/Bardcraft/ui/bookicon-gold.dds',
                                            },
                                            size = util.vector2(96 * scaleMod, 96 * scaleMod),
                                        }
                                    },
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            autoSize = false,
                                            relativeSize = util.vector2(1, 1),
                                            size = util.vector2(-96 * scaleMod - 8, 0),
                                            anchor = util.vector2(1, 0),
                                            relativePosition = util.vector2(1, 0),
                                            align = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                            textWithLabel(l10n('UI_PerfLog_GoldGained'), tostring((log.payment or 0) + (log.tips or 0))),
                                            log.payment and createPaddingTemplate(4 * scaleMod) or {},
                                            log.payment and textWithLabel(l10n('UI_PerfLog_GoldGained_Publican'), tostring(log.payment or 0), baseTextSize, Editor.uiColors.BOOK_TEXT_LIGHT, Editor.uiColors.BOOK_TEXT_LIGHT) or {},
                                            log.payment and textWithLabel(l10n('UI_PerfLog_GoldGained_Tips'), tostring(log.tips or 0), baseTextSize, Editor.uiColors.BOOK_TEXT_LIGHT, Editor.uiColors.BOOK_TEXT_LIGHT) or {},
                                        }
                                    }
                                }
                            },
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    relativeSize = util.vector2(1, 0),
                                    size = util.vector2(0, 96 * scaleMod),
                                },
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = ui.texture {
                                                path = 'textures/Bardcraft/ui/bookicon-rep.dds',
                                            },
                                            size = util.vector2(96 * scaleMod, 96 * scaleMod),
                                        }
                                    },
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            autoSize = false,
                                            relativeSize = util.vector2(1, 1),
                                            size = util.vector2(-96 * scaleMod - 8, 0),
                                            anchor = util.vector2(1, 0),
                                            relativePosition = util.vector2(1, 0),
                                            align = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                            textWithLabel(l10n('UI_PerfLog_Reputation'), ((log.rep and log.rep > 0) and '+' or '') .. tostring(log.rep or 0)),
                                            {
                                                template = createPaddingTemplate(4 * scaleMod),
                                            },
                                            textWithLabel(l10n('UI_PerfLog_From'), tostring(log.oldRep) .. ' -> ' .. tostring(log.newRep), baseTextSize, Editor.uiColors.BOOK_TEXT_LIGHT, Editor.uiColors.BOOK_TEXT_LIGHT),
                                        }
                                    }
                                }
                            },
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    relativeSize = util.vector2(1, 0),
                                    size = log.disp and util.vector2(0, 96 * scaleMod) or util.vector2(0, 0),
                                },
                                content = log.disp and ui.content {
                                    {
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = ui.texture {
                                                path = 'textures/Bardcraft/ui/bookicon-pub' .. (
                                                    ((log.kickedOut or log.disp < -10) and 'mad') or
                                                    ((log.disp < 10) and 'meh') or
                                                    ((log.disp < 20) and 'happy') or
                                                    'grin') .. '.dds',
                                            },
                                            size = util.vector2(96 * scaleMod, 96 * scaleMod),
                                        }
                                    },
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            autoSize = false,
                                            relativeSize = util.vector2(1, 1),
                                            size = util.vector2(-96 * scaleMod - 8, 0),
                                            anchor = util.vector2(1, 0),
                                            relativePosition = util.vector2(1, 0),
                                            align = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                            textWithLabel(l10n('UI_PerfLog_PubDisposition'), ((log.disp and log.disp > 0) and '+' or '') .. tostring(log.disp or 0)),
                                            {
                                                template = createPaddingTemplate(4 * scaleMod),
                                            },
                                            textWithLabel(l10n('UI_PerfLog_From'), tostring(log.oldDisp) .. ' -> ' .. tostring(log.newDisp), baseTextSize, Editor.uiColors.BOOK_TEXT_LIGHT, Editor.uiColors.BOOK_TEXT_LIGHT),
                                        }
                                    }
                                } or ui.content {}
                            },
                            createPaddingTemplate(16 * scaleMod),
                            {
                                template = I.MWUI.templates.textParagraph,
                                props = {
                                    text = log.kickedOut and l10n('UI_Msg_PerfTavern_KickedOut'):gsub('%%{date}', calendar.formatGameTime('%d %B', log.banEndTime)):match("0*(.+)") or '',
                                    textColor = Editor.uiColors.BOOK_HEADER,
                                    textSize = textSize,
                                    textAlignH = ui.ALIGNMENT.Center,
                                },
                                external = {
                                    grow = 1,
                                    stretch = 1,
                                },
                            }
                        }
                    }
                }
            },
            {
                type = ui.TYPE.Container,
                props = {
                    anchor = util.vector2(0.5, 1),
                    relativePosition = util.vector2(0.5, 1),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = 'white' },
                            color = Editor.uiColors.BLACK,
                            size = util.vector2(256, 32),
                        }
                    },
                    uiTemplates.button(l10n('UI_Button_Close'), util.vector2(256, 32), function()
                        self:destroyUI()
                        if self.active then
                            self:createUI()
                            I.UI.setMode(I.UI.MODE.Interface, {windows = {}})
                            core.sendGlobalEvent('Pause', 'BO_Editor')
                        else
                            I.UI.removeMode(I.UI.MODE.Interface)
                            core.sendGlobalEvent('Unpause', 'BO_Editor')
                        end
                        ambient.playSoundFile('sound\\Fx\\BOOKCLS2.wav', { volume = 0.5 })
                    end),
                }
            }
        },
    }
    wrapperElement:update()
    ambient.playSoundFile('sound\\Fx\\BOOKOPN1.wav', { volume = 0.5 })
end

local function updatePlaybackMarker()
    if pianoRoll.editorMarkersWrapper and pianoRoll.editorMarkersWrapper.layout.content.pianoRollMarkers.content[1] then
        local playbackMarker = pianoRoll.editorMarkersWrapper.layout.content.pianoRollMarkers.content[1]
        if playbackMarker then
            local playbackX = (Editor.song:tickToBeat(Editor.song.playbackTickCurr)) * calcBeatWidth(Editor.song.timeSig[2])
            playbackMarker.props.position = util.vector2(playbackX, 0)
            playbackMarker.props.alpha = playbackX > 0 and 0.8 or 0
            if Editor.playback and ((playbackX + pianoRoll.scrollX) > calcPianoRollEditorWrapperSize().x or (playbackX + pianoRoll.scrollX) < 0) then
                pianoRoll.scrollX = util.clamp(-playbackX, -pianoRoll.scrollXMax, 0)
                pianoRoll.scrollLastPopulateX = pianoRoll.scrollX
                updatePianoRoll()
                populateNotes()
            end
            pianoRoll.editorMarkersWrapper:update()
        end
    end
end

local function tickPlayback(dt)
    if not Editor.song then return end
    if Editor.playback then
        if not Editor.song:tickPlayback(dt, 
        function(filePath, velocity, instrument, note, part)
            local profile = Song.getInstrumentProfile(instrument)
            if velocity > 0 and Editor.partsPlaying[part] then
                ambient.playSoundFile(filePath, { volume = velocity / 127 * profile.volume })
            end
        end, 
        function(filePath, instrument)
            local profile = Song.getInstrumentProfile(instrument)
            local sustain = profile.sustain
            if profile.name == 'Lute' then sustain = not infiniteLuteRelease end
            if sustain then
                ambient.stopSoundFile(filePath)
            end
        end,
        nil,
        function()
            -- Stop all sustained instrument sounds for playing parts on loop
            if Editor.song and Editor.partsPlaying then
                for _, part in ipairs(Editor.song.parts) do
                    if Editor.partsPlaying[part.index] then
                        local profile = Song.getInstrumentProfile(part.instrument)
                        if profile and profile.sustain then
                            stopSounds(part.instrument)
                        end
                    end
                end
            end
        end) then
            Editor.playback = false
            Editor.song:resetPlayback()
            stopAllSounds()
        end
        updatePlaybackMarker()
    end
end

function Editor:setState(state)
    self:destroyUI()
    self.state = state
    self:createUI()
end

function Editor:setContent()
    if self.state == self.STATE.SONG then
        setMainContent(getSongTab())
        updatePianoRoll()
    elseif self.state == self.STATE.PERFORMANCE then
        setMainContent(getPerformanceTab())
    elseif self.state == self.STATE.STATS then
        setMainContent(getStatsTab())
    end
end

function Editor:createUI()
    self:destroyUI()
    local wrapper = uiTemplates.wrapper()
    setScreenSize()
    self.windowXOff = self.state == self.STATE.SONG and 20 or (screenSize.x * 1 / 3)
    wrapper.content[1].props.size = util.vector2(screenSize.x-Editor.windowXOff, screenSize.y - Editor.windowYOff)
    wrapperElement = ui.create(wrapper)
    Editor:setContent()
end

function Editor:destroyUI()
    if self.state == self.STATE.SONG and self.song then
        saveNotes()
        saveDraft()
    end
    if wrapperElement then
        auxUi.deepDestroy(wrapperElement)
        wrapperElement = nil
    end
    if modalElement then
        auxUi.deepDestroy(modalElement)
        modalElement = nil
    end
    logShowing = false
end

function Editor:closeUI()
    I.UI.removeMode(I.UI.MODE.Interface)
end

function Editor:onToggle()
    if self.active then
        self:destroyUI()
        self.active = false
        I.UI.removeMode(I.UI.MODE.Interface)
        core.sendGlobalEvent('Unpause', 'BO_Editor')
    else
        self:createUI()
        self.active = true
        I.UI.setMode(I.UI.MODE.Interface, {windows = {}})
        core.sendGlobalEvent('Pause', 'BO_Editor')
    end
end

function Editor:togglePlayback(fromStart)
    if self.state ~= self.STATE.SONG then return end
    if self.playback then
        stopPlayback()
        updatePlaybackMarker()
    else
        startPlayback(fromStart)
    end
end

function Editor:onUINil()
    if self.active and self.state == self.STATE.SONG then
        --self:createUI()
        I.UI.setMode(I.UI.MODE.Interface, {windows = {}})
        core.sendGlobalEvent('Pause', 'BO_Editor')
    else
        self:destroyUI()
        self.active = false
        core.sendGlobalEvent('Unpause', 'BO_Editor')
    end
end

function Editor:onFrame()
    alreadyRedrewThisFrame = false
    if self.deletePartConfirmTimer > 0 then
        self.deletePartConfirmTimer = self.deletePartConfirmTimer - core.getRealFrameDuration()
    else
        self.deletePartClickCount = 0
        self.deletePartIndex = nil
    end
    if self.active and self.state == self.STATE.SONG then
        if self.playback then
            tickPlayback(core.getRealFrameDuration())
        end
        if self.controllerMode then
            local controllerX = input.getAxisValue(input.CONTROLLER_AXIS.RightX)
            local controllerY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
            if math.abs(controllerX) > 0.25 or math.abs(controllerY) > 0.25 then
                if pianoRoll.focused then
                    -- Respect 0.25 deadzone for both axes
                    local changeAmtY = math.abs(controllerY) > 0.25 and controllerY * 48 or 0
                    local changeAmtX = math.abs(controllerX) > 0.25 and controllerX * 48 or 0

                    pianoRoll.scrollX = util.clamp(pianoRoll.scrollX + changeAmtX, -pianoRoll.scrollXMax, 0)
                    if math.abs(pianoRoll.scrollX - pianoRoll.scrollLastPopulateX) > pianoRoll.scrollPopulateWindowSize then
                        pianoRoll.scrollLastPopulateX = pianoRoll.scrollX
                        populateNotes()
                    end
                    pianoRoll.scrollY = util.clamp(pianoRoll.scrollY + changeAmtY, -pianoRoll.scrollYMax, 0)
                    updatePianoRoll()
                end
            end
        end
    end
end

function Editor:onMouseWheel(vertical, horizontal)
    if scrollableFocused and scrollableFocused.layout then
        if not scrollableFocused.layout.props.canScroll then return end
        local pos = scrollableFocused.layout.content[1].props.position
        scrollableFocused.layout.content[1].props.position = util.vector2(pos.x, util.clamp(pos.y + vertical * 24, -scrollableFocused.layout.props.scrollLimit, 0))
        scrollableFocused:update()
    elseif pianoRoll.focused then
        if input.isCtrlPressed() then
            local currZoom = self.ZOOM_LEVELS[self.zoomLevel]
            self.zoomLevel = util.clamp(self.zoomLevel + vertical, 1, #self.ZOOM_LEVELS)
            local diff = self.ZOOM_LEVELS[self.zoomLevel] / currZoom
            initPianoRoll()
            pianoRoll.scrollX = util.clamp(pianoRoll.scrollX * diff, -pianoRoll.scrollXMax, 0)
            redrawPianoRollEditor()
            return
        end

        local changeAmtY = vertical * 48
        local changeAmtX = horizontal * 48
        if input.isShiftPressed() then
            local y = changeAmtY
            changeAmtY = changeAmtX
            changeAmtX = y
        end

        pianoRoll.scrollX = util.clamp(pianoRoll.scrollX + changeAmtX, -pianoRoll.scrollXMax, 0)
        if math.abs(pianoRoll.scrollX - pianoRoll.scrollLastPopulateX) > pianoRoll.scrollPopulateWindowSize then
            pianoRoll.scrollLastPopulateX = pianoRoll.scrollX
            populateNotes()
        end
        pianoRoll.scrollY = util.clamp(pianoRoll.scrollY + changeAmtY, -pianoRoll.scrollYMax, 0)
        updatePianoRoll()
    end
end

function Editor:init()
    self.state = self.STATE.PERFORMANCE
    self.song = nil
    self.noteMap = nil
end

function Editor:playerConfirmModal(player, onYes, onNo)
    self:destroyUI()
    core.sendGlobalEvent('Pause', 'BO_Editor')
    I.UI.setMode(I.UI.MODE.Interface, {windows = {}})
    modalElement = ui.create(uiTemplates.modal(
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                relativeSize = util.vector2(1, 1),
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                createPaddingTemplate(16),
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = l10n('UI_StopPerforming'),
                        textAlignH = ui.ALIGNMENT.Center,
                    },
                },
                createPaddingTemplate(16),
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = false,
                        relativeSize = util.vector2(1, 0),
                        size = util.vector2(0, 32),
                        align = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        uiTemplates.button(l10n('UI_Button_Yes'), util.vector2(128, 32), function()
                            if onYes then onYes() end
                            self:closeUI()
                        end),
                        {
                            template = I.MWUI.templates.interval,
                        },
                        uiTemplates.button(l10n('UI_Button_No'), util.vector2(128, 32), function()
                            if onNo then onNo() end
                            self:closeUI()
                        end),
                    },
                },
                createPaddingTemplate(16),
            },
        },
        util.vector2(300, 150),
        l10n('UI_Confirmation')
    ))
end

function Editor:playerChoiceModal(player, title, choices, text)
    self:destroyUI()
    core.sendGlobalEvent('Pause', 'BO_Editor')
    I.UI.setMode(I.UI.MODE.Interface, {windows = {}})
    modalElement = ui.create(uiTemplates.modal(
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                relativeSize = util.vector2(1, 1),
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                createPaddingTemplate(8),
                text and {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = text,
                        textAlignH = ui.ALIGNMENT.Center,
                    },
                } or {},
                text and createPaddingTemplate(8) or {},
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = false,
                        autoSize = false,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                    },
                    external = {
                        grow = 1,
                        stretch = 1,
                    },
                    content = (function()
                        local buttons = {createPaddingTemplate(8)}
                        for _, choice in ipairs(choices) do
                            table.insert(buttons, uiTemplates.button(choice.text, util.vector2(200, 32), function()
                                if choice.callback then
                                    choice.callback()
                                end
                                self:closeUI()
                            end))
                            table.insert(buttons, createPaddingTemplate(8))
                        end
                        return ui.content(buttons)
                    end)(),
                },
                createPaddingTemplate(8),
            },
        },
        util.vector2(400, 180),
        title--"Choice"
    ))
end

return Editor