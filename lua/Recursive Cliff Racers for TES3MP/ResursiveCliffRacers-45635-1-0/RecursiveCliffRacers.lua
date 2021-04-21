-- put this file in ...\tes3mp\mp-stuff\scripts folder
-- add to server.lua:
-- RecursiveCliffRacers = require("RecursiveCliffRacers")   at top
-- RecursiveCliffRacers.HitIt(pid)                          at OnPlayerKillCount

-- Written by Skvysh/Сквиш/NerevarineLoL/NectarineGriefer for Morrowind May Modathon Month 2018 competition.
require("color")
Methods = {}
Methods.HitIt = function(pid)
    local killID  -- get the ID of the killed creature by this player (wonky on pre-0.7 because the PID with autohority in the cell is the PID sent)
    local cliffRacerIDs = {"cliff racer", "cliff racer_diseased", "cliff racer_blighted"} -- cliff racer IDs, add more if your mods have more cliff racer variations
    local consoleCommand -- console command string
    local message -- message string
    local sendMessage = true -- set to false if you don't want to see any messages in chat
    local cliffRacerCount = 2 -- how many cliff racers to spawn for each cliff racer killed
    local i, j -- loop variables
    for i = 1, 3 do -- increase the second number if you have more cliff racer IDs
        for j = 0, tes3mp.GetKillChangesSize(pid) - 1 do
            killID = tes3mp.GetKillRefId(pid, j)
            if killID == cliffRacerIDs[i] then
                consoleCommand = "placeatpc,\"" .. killID .. "\"," .. cliffRacerCount .. ",1,1"
                if sendMessage == true then
                    tes3mp.MessageBox(pid, -1, color.Red .. "The cliff racer God laughs at you" .. color.Default)
                end
                myMod.RunConsoleCommandOnPlayer(pid, consoleCommand)
            end
        end
    end
end
return Methods
