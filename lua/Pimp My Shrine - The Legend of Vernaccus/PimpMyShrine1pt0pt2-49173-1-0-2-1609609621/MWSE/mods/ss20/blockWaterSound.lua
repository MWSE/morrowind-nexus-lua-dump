local function blockSound(e)
    if e.cell.id == 'Shrine of Vernaccus' then
        local sound = tes3.getSound("Water Layer")
        if sound then 
            sound.volume = 0 
        end
    end
end
event.register("cellChanged", blockSound)
