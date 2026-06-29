local scripted_objects = {}

local function setupScriptedObject(refId, on_activate_func)
    scripted_objects[refId] = on_activate_func
end

local function initCasinoData(pid)
    if Players[pid].data.customVariables.casinoData then return end

    local casinoData = {chips = 0}
    Players[pid].data.customVariables.casinoData = casinoData

    return casinoData
end

local function getCasinoData(pid)
    local casinoData = Players[pid].data.customVariables.casinoData
    return casinoData or initCasinoData(pid)
end

local function getChips(pid)
    return getCasinoData(pid).chips
end

local function setChips(pid, chips)
    initCasinoData(pid)
    Players[pid].data.customVariables.casinoData.chips = chips
end

local function addChips(pid, chips)
    setChips(pid, getChips(pid) + chips)
end

local function getCasinoGameData(pid, gameName, key)
    local casinoData = getCasinoData(pid)

    if casinoData[gameName] then
        return casinoData[gameName][key]
    end
end

local function setCasinoGameData(pid, gameName, key, value)
    local casinoData = getCasinoData(pid)

    if not casinoData[gameName] then
        casinoData[gameName] = {}
    end

    casinoData[gameName][key] = value
end

local buyChipsGuid = 7772
local sellChipsGuid = 7773

local coinFlipGame = "CoinFlip"
local coinGameSetBetGuid = 7771

local diceGame = "Dice"
local diceGameSetBetGuid = 7774

local chipRunGame = "ChipRun"

local function roundChips(chips)
    if math.floor(chips) == chips then
        return tostring(math.floor(chips))
    end

    return string.format("%.1f", chips)
end

local function getWinningsDisplay(pid, gameName)
    local winnings = getCasinoGameData(pid, gameName, "winnings") or 0
    return roundChips(winnings)
end

local function checkBetLogic(pid, gameName)
    local bet = getCasinoGameData(pid, gameName, "bet") or 0
    tes3mp.MessageBox(pid, -1, "You have "..tostring(getChips(pid)).." chips with "..getWinningsDisplay(pid, gameName).." winnings to cash out. Desired bet is "..tostring(bet)..".")
end

local function setBetLogic(pid, gameGuid)
    if getChips(pid) <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no chips.")
        return
    end

    tes3mp.CustomMessageBox(pid, gameGuid, "Select your bet.", "Cancel;1;10;100;1000;10000;All")
end

local function doubleBetLogic(pid, gameName)
    if getChips(pid) <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no chips.")
        return
    end

    local bet = getCasinoGameData(pid, gameName, "bet")

    if bet then
        bet = bet * 2
    else
        bet = 1
    end

    bet = math.min(getChips(pid), bet)

    setCasinoGameData(pid, gameName, "bet", bet)
    tes3mp.MessageBox(pid, -1, "Bet set to "..tostring(bet).." chips.")
end

local function halfBetLogic(pid, gameName)
    if getChips(pid) <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no chips.")
        return
    end

    local bet = getCasinoGameData(pid, gameName, "bet")

    if bet then
        bet = math.max(1, math.floor(bet / 2))
    else
        bet = 1
    end

    bet = math.min(getChips(pid), bet)

    setCasinoGameData(pid, gameName, "bet", bet)
    tes3mp.MessageBox(pid, -1, "Bet set to "..tostring(bet).." chips.")
end

local function cashOutLogic(pid, gameName)
    local winnings = getCasinoGameData(pid, gameName, "winnings") or 0
    local chipsFromWinnings = math.floor(winnings)

    if chipsFromWinnings <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no winnings.")
        return
    end

    tes3mp.MessageBox(pid, -1, "You have been given "..tostring(chipsFromWinnings).." chips.")

    addChips(pid, chipsFromWinnings)
    setCasinoGameData(pid, gameName, "winnings", winnings - chipsFromWinnings)
end

setupScriptedObject("krl_casino_check", function(pid, cellName, object) -- Check Chips
    tes3mp.MessageBox(pid, -1, "You have "..tostring(getChips(pid)).." chips.")
end)

setupScriptedObject("krl_casino_crank_check", function(pid, cellName, object) -- Check Chips
    tes3mp.MessageBox(pid, -1, "You have "..tostring(getChips(pid)).." chips.")
end)

setupScriptedObject("krl_casino_1_1", function(pid, cellName, object) -- Set Bet
    setBetLogic(pid, coinGameSetBetGuid)
end)

setupScriptedObject("krl_casino_1_2", function(pid, cellName, object) -- Double Bet
    doubleBetLogic(pid, coinFlipGame)
end)

setupScriptedObject("krl_casino_1_3", function(pid, cellName, object) -- Half Bet
    halfBetLogic(pid, coinFlipGame)
end)

local function flipCoin(pid, choseHeads)
    local winnings = getCasinoGameData(pid, coinFlipGame, "winnings") or 0

    if winnings < 1 then
        local bet = getCasinoGameData(pid, coinFlipGame, "bet") or 0

        if bet <= 0 then
            tes3mp.MessageBox(pid, -1, "You have no bet set.")
            return
        end
        
        if bet > getChips(pid) then
            tes3mp.MessageBox(pid, -1, "Your bet is higher than your chips. Please set a new bet.")
            return
        end

        addChips(pid, -bet)
        winnings = winnings + bet
        tes3mp.MessageBox(pid, -1, "You bet "..tostring(bet).." chips.")
    end

    local coinFlip = math.random(2)
    local coinFlipDisplay = coinFlip == 1 and "Heads" or "Tails"
    local correct = (coinFlip == 1 and choseHeads) or (coinFlip == 2 and not choseHeads)

    if correct then
        winnings = winnings * 1.95
    else
        winnings = 0
    end

    setCasinoGameData(pid, coinFlipGame, "winnings", winnings)

    tes3mp.MessageBox(pid, -1, "It was "..tostring(coinFlipDisplay).."!\n".."Your winnings are now "..getWinningsDisplay(pid, coinFlipGame)..".")
end

setupScriptedObject("krl_casino_1_4", function(pid, cellName, object) -- Heads
    flipCoin(pid, true)
end)

setupScriptedObject("krl_casino_1_7", function(pid, cellName, object) -- Tails
    flipCoin(pid, false)
end)

setupScriptedObject("krl_casino_1_5", function(pid, cellName, object) -- Cash Out
    cashOutLogic(pid, coinFlipGame)
end)

setupScriptedObject("krl_casino_1_6", function(pid, cellName, object) -- Check
    checkBetLogic(pid, coinFlipGame)
end)

setupScriptedObject("krl_casino_2_1", function(pid, cellName, object) -- Buy Chips
    tes3mp.CustomMessageBox(pid, buyChipsGuid, "Buy chips.", "Cancel;Buy 10 chips for 1 gold.;Buy 100 chips for 10 gold.;Buy 1000 chips for 100 gold.;Buy 10,000 chips for 1000 gold.;Spend all your gold on chips.")
end)

setupScriptedObject("krl_casino_2_2", function(pid, cellName, object) -- Sell Chips
    tes3mp.CustomMessageBox(pid, sellChipsGuid, "Sell chips.", "Cancel;Sell 10 chips for 1 gold.;Sell 100 chips for 10 gold.;Sell 1000 chips for 100 gold.;Sell 10,000 chips for 1000 gold.;Sell all your chips.")
end)

setupScriptedObject("krl_casino_3", function(pid, cellName, object) -- Buy Lottery Ticket
    local chips = getChips(pid)

    if chips <= 0 then
        tes3mp.MessageBox(pid, -1, "You do not have any chips.")
        return
    end

    addChips(pid, -1)

    local lotteryNumber = math.random(100000)
    local lotteryTicket = math.random(100000)

    local lotteryNumberDisplay = string.format("%06d", lotteryNumber)
    local lotteryTicketDisplay = string.format("%06d", lotteryTicket)

    local lotteryMessage = "Ticket number:  "..tostring(lotteryTicketDisplay).."\nLottery number: "..tostring(lotteryNumberDisplay)

    if lotteryNumber == lotteryTicket then
        tes3mp.MessageBox(pid, -1, "You won 100,000 chips!")
        addChips(pid, 100000)
    else
        lotteryMessage = lotteryMessage.."\n@you_got_nothing@"
    end

    tes3mp.MessageBox(pid, -1, lotteryMessage)
end)

setupScriptedObject("krl_casino_4_1", function(pid, cellName, object) -- Check
    local bet = getCasinoGameData(pid, diceGame, "bet") or 0
    tes3mp.MessageBox(pid, -1, "You have "..tostring(getChips(pid)).." chips. Desired bet is "..tostring(bet)..".")
end)

setupScriptedObject("krl_casino_4_2", function(pid, cellName, object) -- Half Bet
    halfBetLogic(pid, diceGame)
end)

setupScriptedObject("krl_casino_4_3", function(pid, cellName, object) -- Set Bet
    setBetLogic(pid, diceGameSetBetGuid)
end)

setupScriptedObject("krl_casino_4_4", function(pid, cellName, object) -- Double Bet
    doubleBetLogic(pid, diceGame)
end)

setupScriptedObject("krl_casino_4_5", function(pid, cellName, object) -- Roll Dice
    local bet = getCasinoGameData(pid, diceGame, "bet") or 0

    if bet <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no bet set.")
        return
    end

    if bet > getChips(pid) then
        tes3mp.MessageBox(pid, -1, "Your bet is higher than your chips. Please set a new bet.")
        return
    end

    addChips(pid, -bet)

    local diceRoll = math.random(100)
    local diceMult = diceRoll / 51
    local diceMultDisplay = string.format("%.2f", diceMult)
    local chipsToReturn = bet * diceMult

    -- redundant, but don't feel like re-writing chips to be decimals
    local winnings = getCasinoGameData(pid, diceGame, "winnings") or 0
    winnings = winnings + chipsToReturn

    setCasinoGameData(pid, diceGame, "winnings", winnings)

    local chipsFromWinnings = math.floor(winnings)

    if chipsFromWinnings > 0 then
        addChips(pid, chipsFromWinnings)
        setCasinoGameData(pid, diceGame, "winnings", winnings - chipsFromWinnings)
    end

    local diceMessage = "You bet "..tostring(bet).." and rolled a "..tostring(diceRoll).." ("..tostring(diceMultDisplay).."x)!\n"
    diceMessage = diceMessage.."You get "..roundChips(chipsToReturn).." chips back and now have "..tostring(getChips(pid)).." chips total."

    tes3mp.MessageBox(pid, -1, diceMessage)
end)

setupScriptedObject("krl_chiprun_start", function(pid, cellName, object)
    setCasinoGameData(pid, chipRunGame, "startTime", os.time())
    tes3mp.MessageBox(pid, -1, "Run started!")
end)

setupScriptedObject("krl_chiprun_easy", function(pid, cellName, object)
    local startTime = getCasinoGameData(pid, chipRunGame, "startTime")
    local bestEasyRunTime = getCasinoGameData(pid, chipRunGame, "bestEasyRunTime")

    if not startTime then
        tes3mp.MessageBox(pid, -1, "You must go back to the beginning to start another Chip Run.")

        if bestEasyRunTime then
            tes3mp.MessageBox(pid, -1, "Your personal best is "..tostring(bestEasyRunTime).." seconds.")
        end

        return
    end

    if not bestEasyRunTime then
        bestEasyRunTime = math.huge
    end

    local runTime = os.time() - startTime
    local chipsReward = 1

    if runTime < bestEasyRunTime then
        chipsReward = chipsReward * 2
        setCasinoGameData(pid, chipRunGame, "bestEasyRunTime", runTime)
        tes3mp.MessageBox(pid, -1, "Easy run completed in "..tostring(runTime).." seconds. That's a new personal best! You have been given "..tostring(chipsReward).." chips.")
    else
        tes3mp.MessageBox(pid, -1, "Easy run completed in "..tostring(runTime).." seconds. You have been given "..tostring(chipsReward).." chip.")
    end

    addChips(pid, chipsReward)

    setCasinoGameData(pid, chipRunGame, "startTime", nil)
end)

setupScriptedObject("krl_chiprun_hard", function(pid, cellName, object)
    local startTime = getCasinoGameData(pid, chipRunGame, "startTime")
    local bestHardRunTime = getCasinoGameData(pid, chipRunGame, "bestHardRunTime")

    if not startTime then
        tes3mp.MessageBox(pid, -1, "You must go back to the beginning to start another Chip Run.")

        if bestHardRunTime then
            tes3mp.MessageBox(pid, -1, "Your personal best is "..tostring(bestHardRunTime).." seconds.")
        end

        return
    end

    if not bestHardRunTime then
        bestHardRunTime = math.huge
    end

    local runTime = os.time() - startTime
    local chipsReward = 50

    if runTime < bestHardRunTime then
        chipsReward = chipsReward * 2
        setCasinoGameData(pid, chipRunGame, "bestHardRunTime", runTime)
        tes3mp.MessageBox(pid, -1, "Hard run completed in "..tostring(runTime).." seconds. That's a new personal best! You have been given "..tostring(chipsReward).." chips.")
    else
        tes3mp.MessageBox(pid, -1, "Hard run completed in "..tostring(runTime).." seconds. You have been given "..tostring(chipsReward).." chips.")
    end

    addChips(pid, chipsReward)

    setCasinoGameData(pid, chipRunGame, "startTime", nil)
end)

customEventHooks.registerValidator("OnObjectActivate", function(_, pid, cellName, objects, players)
    for _, object in pairs(objects) do
        local refId = object.refId

        if refId and scripted_objects[refId] then
            scripted_objects[refId](pid, cellName, object)
        end
    end
end)

local function setBetGuiLogic(pid, gameName, selection)
    local desiredBet = 0
    local chips = getChips(pid)

    if selection == 0 then
        return
    elseif selection == 1 then
        desiredBet = 1
    elseif selection == 2 then
        desiredBet = 10
    elseif selection == 3 then
        desiredBet = 100
    elseif selection == 4 then
        desiredBet = 1000
    elseif selection == 5 then
        desiredBet = 10000
    elseif selection == 6 then
        desiredBet = chips
    end

    local chipsToBet = math.min(chips, desiredBet)

    tes3mp.MessageBox(pid, -1, "Bet set to "..tostring(chipsToBet).." chips.")
    setCasinoGameData(pid, gameName, "bet", chipsToBet)
end

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= coinGameSetBetGuid then return end

    local selection = tonumber(data)
    setBetGuiLogic(pid, coinFlipGame, selection)
end)

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= diceGameSetBetGuid then return end

    local selection = tonumber(data)
    setBetGuiLogic(pid, diceGame, selection)
end)

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= buyChipsGuid then return end

    local gold = KRL_GetPlayerItem(pid, "Gold_001")
    local goldCount = gold and gold.count

    if not goldCount or goldCount <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no gold.")
        return
    end

    goldCount = goldCount - 1 -- try to ensure player always has 1 gold

    local desiredChips = 0
    local selection = tonumber(data)

    if selection == 0 then
        return
    elseif selection == 1 then
        desiredChips = 10
    elseif selection == 2 then
        desiredChips = 100
    elseif selection == 3 then
        desiredChips = 1000
    elseif selection == 4 then
        desiredChips = 10000
    elseif selection == 5 then
        desiredChips = goldCount * 10
    end

    local chipsToGive = math.min(desiredChips, goldCount * 10)
    local goldSpent = math.floor(chipsToGive / 10)

    tes3mp.MessageBox(pid, -1, "Purchased "..tostring(chipsToGive).." chips for "..tostring(goldSpent).." gold.")
    
    KRL_RemovePlayerItem(pid, "Gold_001", goldSpent)

    addChips(pid, chipsToGive)
end)

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= sellChipsGuid then return end

    local gold = KRL_GetPlayerItem(pid, "Gold_001")
    local goldCount = gold and gold.count

    -- there's a weird bug with inventory helper where spamming this with 0 gold can dupe your gold
    if not goldCount or goldCount <= 0 then
        tes3mp.MessageBox(pid, -1, "You must have at least 1 gold to use this.")
        return
    end

    local chips = getChips(pid) or 0

    if chips <= 0 then
        tes3mp.MessageBox(pid, -1, "You have no chips.")
        return
    end

    local chipsToSell = 0
    local selection = tonumber(data)

    if selection == 0 then
        return
    elseif selection == 1 then
        chipsToSell = 10
    elseif selection == 2 then
        chipsToSell = 100
    elseif selection == 3 then
        chipsToSell = 1000
    elseif selection == 4 then
        chipsToSell = 10000
    elseif selection == 5 then
        chipsToSell = chips
    end

    chipsToSell = math.min(chips, chipsToSell)

    local goldToGive = math.floor(chipsToSell / 10)

    if goldToGive <= 0 then 
        tes3mp.MessageBox(pid, -1, "You need at least 10 chips to redeem any gold.")
        return 
    end

    local chipsToTake = goldToGive * 10

    tes3mp.MessageBox(pid, -1, "Sold "..tostring(chipsToTake).." chips for "..tostring(goldToGive).." gold.")

    KRL_GivePlayerItem(pid, "Gold_001", goldToGive)

    addChips(pid, -chipsToTake)
end)

function KRL_ResumeChipRun(pid)
    local deathCellPos = Players[pid].data.customVariables.deathCellPos

    if deathCellPos then
        tes3mp.SetPos(pid, deathCellPos[1], deathCellPos[2], deathCellPos[3])
        tes3mp.SendPos(pid)

        local deathCellTeleportTime = Players[pid].data.customVariables.deathCellTeleportTime
        local startTime = getCasinoGameData(pid, chipRunGame, "startTime")

        if startTime and startTime > 0 and deathCellTeleportTime and deathCellTeleportTime > 0 and deathCellTeleportTime > startTime then
            local timeSoFar = deathCellTeleportTime - startTime
            setCasinoGameData(pid, chipRunGame, "startTime", os.time() - timeSoFar)
            Players[pid].data.customVariables.deathCellTeleportTime = nil
        end

        Players[pid].data.customVariables.deathCellPos = nil
    end
end
