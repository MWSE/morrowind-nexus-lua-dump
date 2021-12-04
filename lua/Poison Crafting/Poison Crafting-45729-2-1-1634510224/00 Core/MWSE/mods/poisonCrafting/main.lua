--[[
    Poison Crafting
    By Greatness7
--]]

if lfs.fileexists("\\data files\\mwse\\lua\\g7\\a\\mod_init.lua") then
    error("[Poison Crafting] Old versions must be removed before updating")
end

event.register("initialized", function()
    if tes3.isModActive("mwse_PoisonCrafting.esp") then
        -- load modules
        dofile("poisonCrafting.apparatus")
        dofile("poisonCrafting.poison")
        -- register mcm
        dofile("poisonCrafting.mcm")
    end
end)
