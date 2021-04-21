-- Check MWSE Build.
if (mwse.buildDate == nil) or (mwse.buildDate < 20191220) then
    local function warning()
        tes3.messageBox(
            "[Anchor Teleportation ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local function onSpellResist(e)
    for _, effect in pairs(e.sourceInstance.source.effects) do
        if (effect.id == tes3.effect.recall) then
            timer.delayOneFrame(
                function()
                    tes3.clearMarkLocation()
                end
            )
        end
    end
end
event.register("spellResist", onSpellResist)