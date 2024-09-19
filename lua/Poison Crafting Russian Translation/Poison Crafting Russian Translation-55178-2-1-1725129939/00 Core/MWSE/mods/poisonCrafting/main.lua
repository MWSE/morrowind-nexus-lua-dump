--[[
    Poison Crafting
    By Greatness7
--]]

if lfs.fileexists("\\data files\\mwse\\lua\\g7\\a\\mod_init.lua") then
    error("[Poison Crafting] Перед обновлением необходимо удалить старые версии")
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
