local function activateLockedDoor(e)
    local isDoor = e.target.baseObject.id:lower() == 'ss20_in_daedoorroundgs'
    local isPlayer = e.activator == tes3.player
    if isDoor and isPlayer then
        local hasKey = tes3.player.object.inventory:contains('ss20_key_priest')
        if not hasKey then
            tes3.messageBox("This door will not open without the key.")
            return false
        end
    end
end

event.register("activate", activateLockedDoor)