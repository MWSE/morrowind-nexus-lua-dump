event.register(tes3.event.save, function(e)
    if not e.filename then
        local number = 0
        local newFileName = string.format("%s%04d", e.name, number)
        local path = tes3.installDirectory.."\\Saves\\"
        while lfs.fileexists(path..newFileName..".ess") and number < 9999 do
            number = number + 1
            newFileName = string.format("%s%04d", e.name, number)
        end
        e.filename = newFileName..".ess"
    end
end)