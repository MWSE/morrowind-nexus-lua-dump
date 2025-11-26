require("scripts.CanonicalGear.globalValues")

function Log(msg)
    if not Debug:get("printToConsole") then return end
    print(msg)
end