
event.register("activate", function (e)
    if (e.activator == tes3.player and tes3.mobilePlayer.isSneaking == false and e.target.objectType ~= tes3.objectType.door and e.target.object.script == nil) then
        if (tes3.hasOwnershipAccess({target = e.target}) == false) then
            tes3.messageBox("You stop yourself, realizing you do not want to interfere with someone else's property.")
            return false
        end
    end
end, {priority = 1e+06})