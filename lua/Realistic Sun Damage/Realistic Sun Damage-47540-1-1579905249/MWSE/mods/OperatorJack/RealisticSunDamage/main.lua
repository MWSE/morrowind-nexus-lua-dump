-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200123) then
    local function warning()
        tes3.messageBox(
            "[Realistic Sun Damage ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

event.register("calcSunDamageScalar", function(e) e.damage = e.damage * math.random(50, 150) / 100 end)