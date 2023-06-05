local function onInitialized()
    if tes3.isModActive("Leeches.esp") then
        dofile("leeches.core")
        require("leeches.quests")
        require("leeches.physics")
    end
end
event.register("initialized", onInitialized)
