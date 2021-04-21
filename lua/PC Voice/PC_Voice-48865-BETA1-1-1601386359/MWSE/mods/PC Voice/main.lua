local config = require("PC Voice.config")
local squelch
local PC
local targetRace
local lastNPC
--local v = config.helloVol
--local p = config.helloPitch

local function resetHello()
  squelch = 0
end

local function AFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF001.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF009.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF010.mp3"}) return
    end
    local greet = math.random(9)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF139.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF029.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF023.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF022.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF021.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF000c.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF000b.mp3"})
    elseif greet == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF000a.mp3"})
    elseif greet == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF004.mp3"})
    end
end

local function AMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM001.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM009.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM010.mp3"}) return
    end
    local greet = math.random(8)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM139.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM060.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM042.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM023.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM000a.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM000b.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM000c.mp3"})
    elseif greet == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM000d.mp3"})
    end
end

local function BFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF040.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF038.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF037.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF036.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF035.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF034.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF033.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF032.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF031.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF039.mp3"}) return
    end
    local greet = math.random(7)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF046.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF027.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF024.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF018.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF014.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_BF01.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_BF02.mp3"})
    end
end
local function BMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM040.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM038.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM037.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM036.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM035.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM034.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM033.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM032.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM031.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM039.mp3"}) return
    end
    local greet = math.random(7)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM029.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM028.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM027.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM024.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM014.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM009.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_BM01.mp3"})
    end
end

local function DFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF009.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF030.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF010.mp3"}) return
    end
    local greet = math.random(8)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_DF02.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_DF03.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_DF01.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF021.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF027.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF000b.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\tHlo_DF009.mp3"})
    elseif greet == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF017.mp3"})
    end
end
local function DMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DF057.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DF055.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM064.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM053.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM052.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM051.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM050.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM049.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM048.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM056.mp3"}) return
    end
    local greet = math.random(8)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_DM01.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_DM02.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_DM03.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM017.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM027.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\tHlo_DM009.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\tHlo_DM035.mp3"})
    elseif greet == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\tHlo_DM011.mp3"})
    end
end

local function HFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF009.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF000d.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF010.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF082.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF056.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF055.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF000d.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_HF01.mp3"})
    end
end
local function HMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM009.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Srv_HM006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM010.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM040.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM056.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM055.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM059.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Srv_HM006.mp3"})
    end
end

local function IFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF023.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF021.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF020.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF019.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF018.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF017.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF016.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF015.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF014.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF022.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF069.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF056.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF031.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\tIdl_IF012.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\bIdl_IF003.mp3"})
    end
end

local function IMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM023.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM021.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM020.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM019.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM018.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM017.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM016.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM015.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM014.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM022.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM109.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM056.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM031.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Srv_IM012.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\tIdl_IM001.mp3"})
    end
end

local function KFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF010.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF011.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF009.mp3"}) return
    end
    local greet = math.random(3)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF027.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF030.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF000d.mp3"})
    end
end
local function KMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM010.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM011.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM009.mp3"}) return
    end
    local greet = math.random(4)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM001.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM053.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM027.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM017.mp3"})
    end
end

local function NFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF010.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF001.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF009.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF060.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF059.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF053.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF029.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF021.mp3"})
    end
end
local function NMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM010.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM001.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM009.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM060.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM059.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM053.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM029.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM021.mp3"})
    end
end

local function OFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Idl_OF040.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF038.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF037.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF036.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF035.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF034.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF033.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF054.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF032.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF039.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF026.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF025.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF024.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF023.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF021.mp3"})
    end
end
local function OMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM040.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM038.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM037.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM036.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM035.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM034.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM033.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM054.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM032.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM039.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM026.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM025.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM024.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM023.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM021.mp3"})
    end
end

local function RFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF010.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_RF01.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF009.mp3"}) return
    end
    local greet = math.random(6)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF056.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF054.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF053.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF024.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF021.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF000d.mp3"})
    end
end
local function RMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM010.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM008.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM007.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM006.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM005.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM004.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM002.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Ins_RM01.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM009.mp3"}) return
    end
    local greet = math.random(7)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM056.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM054.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM053.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM025.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM024.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM022.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM021.mp3"})
    end
end

local function WFmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF039.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF038.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF037.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF036.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF035.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF034.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF033.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF032.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF031.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF019.mp3"}) return
    end
    local greet = math.random(7)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Srv_WF009.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF047.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF028.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF024.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF021.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF016.mp3"})
    elseif greet == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF000d.mp3"})
    end
end
local function WMmean()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM039.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM038.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM037.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM036.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM035.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM034.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM033.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM032.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM031.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM019.mp3"}) return
    end
    local greet = math.random(6)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM016.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM021.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM024.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM028.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM047.mp3"})
    elseif greet == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM057.mp3"})
    end
end

local function AFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF101.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF100.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF099.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF098.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF097.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF096.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF095.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF094.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF102.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF133.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF135.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF109.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF086.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF082.mp3"})
    end
end

local function AMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM101.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM100.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM099.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM098.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM097.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM096.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM095.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM094.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM102.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM133.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM135.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM109.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM086.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM082.mp3"})
    end
end

local function BFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFB.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFI.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFN.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFR.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BFW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF117.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF114.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF111.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF110.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF108.mp3"})
    end
end
local function BMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMG1.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM116.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMI.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMN.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMR.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_BMW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM132.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM117.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM114.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM110.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM109.mp3"})
    end
end

local function DFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF202.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF203.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF172.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF201.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF200.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF199.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF198.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF197.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF196.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF204.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_DFG1.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF181.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF170.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF150.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\tHlo_DF163.mp3"})
    end
end
local function DMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM202.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM203.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM172.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM201.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM200.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM199.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM198.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM197.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM196.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM204.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_DMG1.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM181.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM170.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_DM150.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\tHlo_DM191.mp3"})
    end
end

local function HFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF101.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF099.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF098.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF117.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF097.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF096.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF095.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF094.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\h\f\\Hlo_HF093.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF100.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF134.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF112.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF092.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF041.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF087.mp3"})
    end
end
local function HMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM101.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM099.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM098.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM117.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM097.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM096.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM095.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM094.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM093.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM100.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM134.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM112.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM092.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM041.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Hlo_HM087.mp3"})
    end
end

local function IFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFA.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFB.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF119.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFN.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFR.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IFW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF160.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF152.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF151.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF122.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\tHlo_IF103.mp3"})
    end
end

local function IMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMA.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMB.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM119.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMN.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMR.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_IMW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM122.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM152.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM160.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM132.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM151.mp3"})
    end
end

local function KFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF129.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF127.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF126.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF125.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF124.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF135.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF123.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF122.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF121.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF128.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF134.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF112.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF109.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF086.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF085.mp3"})
    end
end
local function KMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM129.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM127.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM126.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM125.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM124.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM135.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM123.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM122.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM121.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM128.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM134.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM112.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM109.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM086.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM085.mp3"})
    end
end

local function NFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFA.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFB.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFI.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF113.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFR.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_NFW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF115.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF109.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF092.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF078.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF058.mp3"})
    end
end
local function NMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM072.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM070.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM069.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM068.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM067.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM066.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM113.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM065.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM064.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM071.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM115.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM109.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM092.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM078.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM058.mp3"})
    end
end

local function OFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Idl_OF003.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF071.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF070.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF069.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF068.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF067.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF066.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF065.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF064.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF072.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF113.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF112.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF091.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF086.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Idl_OF003.mp3"})
    end
end
local function OMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM072.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM070.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM069.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM068.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM067.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM066.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM065.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM111.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM064.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM071.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM113.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM112.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM091.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM086.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Idl_OM007.mp3"})
    end
end

local function RFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFA.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFB.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFI.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFN.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF134.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF136.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF135.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF134.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF132.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF108.mp3"})
    end
end
local function RMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMA.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMB.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMD.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMH.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMI.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMK.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMN.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RMO.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM134.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\0s\\Hlo_RFW.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM136.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM135.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM134.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM132.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM108.mp3"})
    end
end

local function WFhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF101.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF100.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF099.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF098.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF097.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF096.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF095.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF094.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF093.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF135.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF134.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF132.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF113.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF112.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF090.mp3"})
    end
end
local function WMhello()
    local greetRace = math.random(100)
    if greetRace >= 60 and targetRace == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM101.mp3"}) return
    elseif greetRace >= 60 and targetRace == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM100.mp3"}) return
    elseif greetRace >= 60 and targetRace == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM099.mp3"}) return
    elseif greetRace >= 60 and targetRace == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM098.mp3"}) return
    elseif greetRace >= 60 and targetRace == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM097.mp3"}) return
    elseif greetRace >= 60 and targetRace == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM096.mp3"}) return
    elseif greetRace >= 60 and targetRace == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM095.mp3"}) return
    elseif greetRace >= 60 and targetRace == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM094.mp3"}) return
    elseif greetRace >= 60 and targetRace == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM093.mp3"}) return
    elseif greetRace >= 60 and targetRace == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM131.mp3"}) return
    end
    local greet = math.random(5)
    if greet == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM134.mp3"})
    elseif greet == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM132.mp3"})
    elseif greet == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM113.mp3"})
    elseif greet == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM112.mp3"})
    elseif greet == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Hlo_WM090.mp3"})
    end
end


local function AFattack()
    local attack = math.random(5)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\f\\Hlo_AF053.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\f\\Atk_AF017.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Atk_AF014.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Atk_AF013.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\f\\Hlo_AF049.mp3"})
    end
end

local function AMattack()
    local attack = math.random(7)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Atk_AM014.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Atk_AM013.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM049.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Atk_AM012.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Hlo_AM053.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Atk_AM015.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\a\\m\\Atk_AM010.mp3"})
    end
end

local function BFattack()
    local attack = math.random(7)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Atk_BF015.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Atk_BF014.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Atk_BF010.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Atk_BF009.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Atk_BF008.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Atk_BF004.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\f\\Hlo_BF027.mp3"})
    end
end

local function BMattack()
    local attack = math.random(7)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Atk_BM014.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Atk_BM015.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Atk_BM010.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Atk_BM009.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Atk_BM008.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Atk_BM006.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\b\\m\\Hlo_BM062.mp3"})
    end
end

local function DFattack()
    local attack = math.random(6)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF035.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Hlo_DF027.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Atk_DF008.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Atk_DF005.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Atk_DF012.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\f\\Atk_DF004.mp3"})
    end
end

local function DMattack()
    local attack = math.random(6)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Atk_Dm007.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Atk_Dm011.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_Dm035.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_Dm027.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Atk_Dm004.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\d\\m\\Hlo_Dm021.mp3"})
    end
end

local function HFattack()
    local attack = math.random(9)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF000d.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF019.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Atk_HF007.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Atk_HF015.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Atk_HF012.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Atk_HF011.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Atk_HF013.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Atk_HF014.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\f\\Hlo_HF024.mp3"})
    end
end

local function HMattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM015.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM001.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM002.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM003.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM005.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM006.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM007.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM011.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM012.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\h\\m\\Atk_HM014.mp3"})
    end
end

local function IFattack()
    local attack = math.random(7)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF112.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Atk_IF015.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Atk_IF010.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Atk_IF006.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Atk_IF014.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Hlo_IF108.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\f\\Atk_IF005.mp3"})
    end
end

local function IMattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM007.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM010.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM014.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM013.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM009.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM006.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM008.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM000d.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Hlo_IM007.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\i\\m\\Atk_IM002.mp3"})
    end
end

local function KFattack()
    local attack = math.random(8)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Atk_KF013.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Atk_KF0014.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Atk_KF007.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Atk_KF001.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF017.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Atk_KF012.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF011.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\f\\Hlo_KF001.mp3"})
    end
end

local function KMattack()
    local attack = math.random(7)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM001.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Atk_KM012.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Atk_KM007.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Atk_KM005.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Atk_KM015.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM011.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\k\\m\\Hlo_KM017.mp3"})
    end
end

local function NFattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF030.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Atk_NF015.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Atk_NF014.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Atk_NF010.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Atk_NF007.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\\n\\f\\Atk_NF006.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Atk_NF001.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Atk_NF004.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF029.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\f\\Hlo_NF028.mp3"})
    end
end

local function NMattack()
    local attack = math.random(9)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM021.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Atk_NM010.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Atk_NM007.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Atk_NM006.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Atk_NM001.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Atk_NM020.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM030.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM022.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\n\\m\\Hlo_NM029.mp3"})
    end
end

local function OFattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF021.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Hlo_OF025.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF015.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF014.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF013.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF012.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF010.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF005.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF003.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\f\\Atk_OF001.mp3"})
    end
end

local function OMattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM026.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM000d.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Atk_OM002.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Atk_OM001.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Atk_OM005.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Atk_OM011.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Atk_OM010.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Atk_OM014.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM021.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\o\\m\\Hlo_OM025.mp3"})
    end
end

local function RFattack()
    local attack = math.random(9)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF021.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Hlo_RF024.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF010.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF015.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF014.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF005.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF013.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF007.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\f\\Atk_RF009.mp3"})
    end
end

local function RMattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM002.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM001.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM003.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM014.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM004.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM005.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM013.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM007.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Atk_RM010.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\r\\m\\Hlo_RM024.mp3"})
    end
end

local function WFattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF009.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF012.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF004.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF008.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF001.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF013.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF000d.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF003.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Atk_WF006.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\f\\Hlo_WF015.mp3"})
    end
end

local function WMattack()
    local attack = math.random(10)
    if attack == 1 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM002.mp3"})
    elseif attack == 2 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM018.mp3"})
    elseif attack == 3 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM013.mp3"})
    elseif attack == 4 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM012.mp3"})
    elseif attack == 5 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM009.mp3"})
    elseif attack == 6 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM008.mp3"})
    elseif attack == 7 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM006.mp3"})
    elseif attack == 8 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM004.mp3"})
    elseif attack == 9 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM003.mp3"})
    elseif attack == 10 then
        tes3.say({ reference = PC, soundPath = "vo\\w\\m\\Atk_WM003.mp3"})
    end
end

local function playerNice()
    if (config.helloRace == 1 and config.helloFem == true) then AFhello()
    elseif (config.helloRace == 1 and config.helloFem == false) then AMhello()
    elseif (config.helloRace == 2 and config.helloFem == true) then BFhello()
    elseif (config.helloRace == 2 and config.helloFem == false) then BMhello()
    elseif (config.helloRace == 3 and config.helloFem == true) then DFhello()
    elseif (config.helloRace == 3 and config.helloFem == false) then DMhello()
    elseif (config.helloRace == 4 and config.helloFem == true) then HFhello()
    elseif (config.helloRace == 4 and config.helloFem == false) then HMhello()
    elseif (config.helloRace == 5 and config.helloFem == true) then IFhello()
    elseif (config.helloRace == 5 and config.helloFem == false) then IMhello()
    elseif (config.helloRace == 6 and config.helloFem == true) then KFhello()
    elseif (config.helloRace == 6 and config.helloFem == false) then KMhello()
    elseif (config.helloRace == 7 and config.helloFem == true) then NFhello()
    elseif (config.helloRace == 7 and config.helloFem == false) then NMhello()
    elseif (config.helloRace == 8 and config.helloFem == true) then OFhello()
    elseif (config.helloRace == 8 and config.helloFem == false) then OMhello()
    elseif (config.helloRace == 9 and config.helloFem == true) then RFhello()
    elseif (config.helloRace == 9 and config.helloFem == false) then RMhello()
    elseif (config.helloRace == 10 and config.helloFem == true) then WFhello()
    elseif (config.helloRace == 10 and config.helloFem == false) then WMhello()
    end
end

local function playerMean()
    if (config.helloRace == 1 and config.helloFem == true) then AFmean()
    elseif (config.helloRace == 1 and config.helloFem == false) then AMmean()
    elseif (config.helloRace == 2 and config.helloFem == true) then BFmean()
    elseif (config.helloRace == 2 and config.helloFem == false) then BMmean()
    elseif (config.helloRace == 3 and config.helloFem == true) then DFmean()
    elseif (config.helloRace == 3 and config.helloFem == false) then DMmean()
    elseif (config.helloRace == 4 and config.helloFem == true) then HFmean()
    elseif (config.helloRace == 4 and config.helloFem == false) then HMmean()
    elseif (config.helloRace == 5 and config.helloFem == true) then IFmean()
    elseif (config.helloRace == 5 and config.helloFem == false) then IMmean()
    elseif (config.helloRace == 6 and config.helloFem == true) then KFmean()
    elseif (config.helloRace == 6 and config.helloFem == false) then KMmean()
    elseif (config.helloRace == 7 and config.helloFem == true) then NFmean()
    elseif (config.helloRace == 7 and config.helloFem == false) then NMmean()
    elseif (config.helloRace == 8 and config.helloFem == true) then OFmean()
    elseif (config.helloRace == 8 and config.helloFem == false) then OMmean()
    elseif (config.helloRace == 9 and config.helloFem == true) then RFmean()
    elseif (config.helloRace == 9 and config.helloFem == false) then RMmean()
    elseif (config.helloRace == 10 and config.helloFem == true) then WFmean()
    elseif (config.helloRace == 10 and config.helloFem == false) then WMmean()
    end
end

local function onActivationTargetChanged(e)
    if e.current == nil then return end
    if tes3.mobilePlayer.isSneaking == true then return end
    if squelch == 1 then return end
    if e.current.baseObject.objectType ~= tes3.objectType.npc then return end
    if tes3.getCurrentAIPackageId(e.current.mobile) == tes3.aiPackage.follow then return end
    local animState = e.current.mobile.actionData.animationAttackState
	if (animState == tes3.animationState.dying or animState == tes3.animationState.dead) then return end
    if lastNPC == e.current then
        return
    else
        lastNPC = e.current
    end
    --tes3.say({ reference = PC, volume = v, pitch = p, soundPath = "vo\\d\\m\\Hlo_DM218.mp3"}) return --test volume
    local race = e.current.baseObject.race
    if race.id:lower() == "argonian" then
        targetRace = 1
    elseif race.id:lower() == "breton" then
        targetRace = 2
    elseif race.id:lower() == "dark elf" then
        targetRace = 3
    elseif race.id:lower() == "high elf" then
        targetRace = 4
    elseif race.id:lower() == "imperial" then
        targetRace = 5
    elseif race.id:lower() == "khajiit" then
        targetRace = 6
    elseif race.id:lower() == "nord" then
        targetRace = 7
    elseif race.id:lower() == "orc" then
        targetRace = 8
    elseif race.id:lower() == "redguard" then
        targetRace = 9
    elseif race.id:lower() == "wood elf" then
        targetRace = 10
    else
        targetRace = 0
    end
    squelch = 1
    timer.start({iterations = 1, duration = config.helloTime, callback = resetHello, type = timer.simulate })
    local per = tes3.mobilePlayer.personality.current
    if per >= config.helloPer then
        playerNice()
    else
        playerMean()
    end
end

local function onWeaponReadied(e)
    if (tes3.mobilePlayer.isSneaking == true) then return end
    if squelch == 1 then return end
    if not e.mobile == PC then return end
    squelch = 1
    timer.start({iterations = 1, duration = config.helloTime, callback = resetHello, type = timer.simulate })
    if (config.helloRace == 1 and config.helloFem == true) then AFattack()
    elseif (config.helloRace == 1 and config.helloFem == false) then AMattack()
    elseif (config.helloRace == 2 and config.helloFem == true) then BFattack()
    elseif (config.helloRace == 2 and config.helloFem == false) then BMattack()
    elseif (config.helloRace == 3 and config.helloFem == true) then DFattack()
    elseif (config.helloRace == 3 and config.helloFem == false) then DMattack()
    elseif (config.helloRace == 4 and config.helloFem == true) then HFattack()
    elseif (config.helloRace == 4 and config.helloFem == false) then HMattack()
    elseif (config.helloRace == 5 and config.helloFem == true) then IFattack()
    elseif (config.helloRace == 5 and config.helloFem == false) then IMattack()
    elseif (config.helloRace == 6 and config.helloFem == true) then KFattack()
    elseif (config.helloRace == 6 and config.helloFem == false) then KMattack()
    elseif (config.helloRace == 7 and config.helloFem == true) then NFattack()
    elseif (config.helloRace == 7 and config.helloFem == false) then NMattack()
    elseif (config.helloRace == 8 and config.helloFem == true) then OFattack()
    elseif (config.helloRace == 8 and config.helloFem == false) then OMattack()
    elseif (config.helloRace == 9 and config.helloFem == true) then RFattack()
    elseif (config.helloRace == 9 and config.helloFem == false) then RMattack()
    elseif (config.helloRace == 10 and config.helloFem == true) then WFattack()
    elseif (config.helloRace == 10 and config.helloFem == false) then WMattack()
    end
end

local function onLoaded()
    squelch = 0
    PC = tes3.mobilePlayer
    event.register("activationTargetChanged", onActivationTargetChanged)
    event.register("weaponReadied", onWeaponReadied)
    --mwse.log("PC Voice Loaded")
end

local function initialized()
    event.register("loaded", onLoaded)
    --mwse.log("PC Voice Initialized")
end
event.register("initialized", initialized)

local function registerModConfig()
	require("PC Voice.mcm")
end
event.register("modConfigReady", registerModConfig)