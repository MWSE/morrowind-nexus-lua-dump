--[[
    Firemoth Reclaimed
    by team Ceaseless Centurions
    MMM 2022
--]]

if tes3.getFileExists("MWSE\\mods\\hrnchamd\\weatheradjust\\main.lua") then
    dofile("firemoth.weather.skyController")
end

event.register("initialized", function()
    if tes3.isModActive("FiremothReclaimed.esp") then
        require("firemoth.quests")

        require("firemoth.shaders.tonemap")
        require("firemoth.shaders.fogExterior")
        require("firemoth.shaders.fogInterior")

        require("firemoth.weather.camera")
        require("firemoth.weather.lightningController")
        require("firemoth.weather.fogDensityController")

        require("firemoth.music.controller")
        require("firemoth.sounds.controller")

        dofile("Data Files\\MWSE\\mods\\firemoth\\mcm\\menu.lua")
    end
end)
