event.register("initialized", function()
    if (mwse.buildDate == nil) or (mwse.buildDate < 20240522) then
        tes3.messageBox(
            "[The Popular Plague] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end

    if tes3.isModActive("The Popular Plague.esp") then
        dofile("The-Popular-Plague.music")
        dofile("The-Popular-Plague.quest")
        dofile("The-Popular-Plague.ssqn")
    end
end)
