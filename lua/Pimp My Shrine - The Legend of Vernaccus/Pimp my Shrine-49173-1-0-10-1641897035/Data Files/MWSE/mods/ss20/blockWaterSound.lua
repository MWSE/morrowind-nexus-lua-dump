local previousVolume
local function blockSound(e)
    if e.cell.id == 'Shrine of Vernaccus' then
        local sound = tes3.getSound("Water Layer")
        if sound then 
            previousVolume = sound.volume
            sound.volume = 0
        elseif previousVolume then
            sound.volume = previousVolume
            previousVolume = nil
        end
    end
end
event.register("cellChanged", blockSound)
