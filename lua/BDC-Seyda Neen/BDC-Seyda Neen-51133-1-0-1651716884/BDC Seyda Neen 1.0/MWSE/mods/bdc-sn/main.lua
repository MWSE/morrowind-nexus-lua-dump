event.register("initialized", function()
    if tes3.isModActive("BDC Seyda Neen.esp") then
        dofile("bdc-sn.functions.lua")
        dofile("bdc-sn.exerciseSkills.lua")
        dofile("bdc-sn.vodunius.lua")
        dofile("bdc-sn.hrisskar.lua")
        mwse.log("[BDC] BDC Seyda Neen Registered")
    end
end)
