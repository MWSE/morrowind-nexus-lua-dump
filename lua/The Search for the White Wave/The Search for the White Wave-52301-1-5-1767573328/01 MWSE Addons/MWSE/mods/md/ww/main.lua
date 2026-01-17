--[[
    The Search for the White Wave
--]]

if not tes3.isModActive("TheSearchForTheWhiteWave.esp")
    and not tes3.isModActive("TheSearchForTheWhiteWave.esm")
then
    return
end

event.register("initialized", function()
    dofile("md.ww.achievements.interop")
    dofile("md.ww.music.music")
    dofile("md.ww.ssqn.interop")
    dofile("md.ww.tooltipscomplete.interop")
end)