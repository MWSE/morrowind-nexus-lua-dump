--configs--------------------------------
local musicBoxId = 'ss20_furn_musicbox'
local trackId = 'ss20_musicBoxTheme'
local closeLidSound = 'ss20\\woodCreakClose.wav'
local openLidSound = 'ss20\\woodCreakOpen.wav'
local trackDuration = 78
local closingTime = 2.4
local openingTime = 2.4
local animGroups = {
    closed = tes3.animationGroup.idle,
    opening = tes3.animationGroup.idle2,
    playing = tes3.animationGroup.idle3,
    closing = tes3.animationGroup.idle4,
}
-----------------------------------------
local musicBoxTimer

local common = require('ss20.common')
local musicBoxes = {}--for object invalidation

local function closeMusicBox(musicBox)
    if musicBoxes[musicBox] == nil then return end
    if musicBoxTimer then musicBoxTimer:cancel() end
    common.log:debug("Stopping Music Box")
    mwscript.stopSound{ reference = musicBox, sound = trackId }
    tes3.playSound{ reference = musicBox, soundPath = closeLidSound }
    tes3.playAnimation{
        reference = musicBox,
        group = animGroups.closing,
        startFlag = tes3.animationStartFlag.immediate,
        loopCount = 1
    }

    timer.start{
        duration = closingTime,
        callback = function()
            if musicBoxes[musicBox] then
                tes3.playAnimation({
                    reference = musicBox ,
                    group = animGroups.closed,
                    startFlag = tes3.animationStartFlag.normal,
                    loopCount = 1
                })
                musicBox.data.ss20playState = nil
                common.log:debug("Stopped Music Box")
            end
        end
    }
end

local function playMusicBox(musicBox)
    if musicBoxes[musicBox] == nil then return end
    musicBox.data.ss20playState = true
    tes3.playSound{ reference = musicBox, soundPath = openLidSound }
    tes3.playAnimation({
        reference = musicBox ,
        group = animGroups.opening,
        startFlag = tes3.animationStartFlag.immediate,
        loopCount = 1
    })
    common.log:debug("Opening Music Box")
    if musicBoxTimer then musicBoxTimer:cancel() end
    musicBoxTimer = timer.start{
        duration = openingTime,
        callback = function()
            if musicBoxes[musicBox] then
                tes3.playAnimation({
                    reference = musicBox ,
                    group = animGroups.playing,
                    startFlag = tes3.animationStartFlag.normal
                })
                tes3.playSound{ reference = musicBox, sound = trackId }

                common.log:debug("Started Music Box Sound")

                --close music box when track finishes playing
                musicBoxTimer = timer.start{
                    type = timer.real,
                    duration = trackDuration,
                    callback = function() 
                        common.log:debug("Track ended, closing box")
                        closeMusicBox(musicBox)
                    end
                }
            end
        end
    }
end

local function onActivateMusicBox(e)
    if e.target.baseObject.id:lower() == musicBoxId then
        local musicBox = e.target
        musicBoxes[musicBox] = true

        common.log:debug("Music Box Activated")

        common.messageBox{
            header = "Music Box",
            buttons = {
                {
                    text = "Play Music Box",
                    showRequirements = function()
                        return not musicBox.data.ss20playState
                    end,
                    callback = function() playMusicBox(musicBox) end
                },
                {
                    text = "Close Music Box",
                    showRequirements = function()
                        return not not musicBox.data.ss20playState
                    end,
                    callback = function() closeMusicBox(musicBox) end
                },
                { text = "Cancel"}
            }
        }
    end
end
event.register("activate", onActivateMusicBox)

local function onWallObjectInvalidated(e)
    if musicBoxes[e.object] then

        common.log:debug("Invalidating music box ref")

        musicBoxes[e.object] = nil
    end
end
event.register("objectInvalidated", onWallObjectInvalidated)

local function offMusicBoxOnLoad()
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.activator) do
        if ref.data.ss20playState then
            local musicBox = ref
            tes3.playAnimation{
                reference = musicBox ,
                group = animGroups.closed,
                startFlag = tes3.animationStartFlag.immediate,
                loopCount = 1
            }
            musicBox.data.ss20playState = nil
            mwscript.stopSound{ reference = musicBox, sound = trackId}

            common.log:debug("Stopping music box on load")

        end
    end
end
event.register("loaded", offMusicBoxOnLoad)