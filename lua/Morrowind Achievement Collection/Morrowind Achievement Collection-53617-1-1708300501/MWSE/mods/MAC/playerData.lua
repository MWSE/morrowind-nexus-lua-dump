local pData = {
    colours = {
        bronze  = { 165 / 255, 165 / 255, 20 / 255 },
        silver  = { 200 / 255, 200 / 255, 200 / 255 },
        gold    = { 203 / 255, 190 / 255, 53 /255},
        plat    = { 230 / 255, 230 / 255, 255 / 255}
    }
}
local defaults = {
    fallflag = false,
    beginz = 0,
    finalz = 0,
    jail = 0,
    inJail = false,
    achievnoBounty = true,
    soulachieve = false,
    Potion = 0,
    Enchant = 0,
    Quests = 0,
    Stolen = 0,
    Ordinator = false,
    DwemerRuinsCount = 0,
    DwemerRuins = {
        aleft = false,
        ["arkngthand, hall of centrifuge"] = false,
        ["arkngthunch-sturdumz"] = false,
        ["gnisis, bethamez"] = false,
        bthanchend = false,
        bthuand = false,
        bthungthumz = false,
        ["dagoth ur, outer facility"] = false,
        ["druscashti, upper level"] = false,
        ["endusal, kagrenac's study"] = false,
        ["galom daeus, entry"] = false,
        ["mudan, lost dwemer checkpoint"] = false,
        mzahnch = false,
        mzanchend = false,
        mzuleft = false,
        nchardahrk = false,
        nchardumz = false,
        nchuleft = false,
        ["nchuleftingth, upper levels"] = false,
        nchurdamz = false,
        ["odrosal, dwemer training academy"] = false,
        ["tureynulal, kagrenac's library"] = false,
        ["vemynal, outer fortress"] = false,
        ["bamz-amschend, hearthfire hall"] = false
    },
    DaedraCount = 0,
    Daedra = {
        atronach_flame = false,
        atronach_frost = false,
        atronach_storm = false,
        clannfear = false,
        daedroth = false,
        dremora = false,
        ["golden saint"] = false, --yes,
        hunger = false,
        ogrim = false,
        scamp = false,
        ["winged twilight"] = false --I'm that lazy
    },
    DagothsCount = 0,
    Dagoths = {},
    BooksCount = 0,
    BooksRead = {},
    InitialCount = 0,
    FinalCount = 0
}
--pulled from the player data example in the MWSE Docs
local function initTableValues(data, t)
    for k, v in pairs(t) do
        -- If a field already exists - we initialized the data
        -- table for this character before. Don't do anything.
        if data[k] == nil then
            if type(v) ~= "table" then
                data[k] = v
            elseif v == {} then
                data[k] = {}
            else
                -- Fill out the sub-tables
                data[k] = {}
                initTableValues(data[k], v)
            end
        end
    end
end
function pData.countBooks(e)
    local myData = pData.getData()
    if (not myData["BooksRead"][e.book.id]) then
        myData["BooksCount"] = myData["BooksCount"] + 1
        myData["BooksRead"][e.book.id] = true
        mwse.log("Book read" .. myData["BooksRead"][e.book.id])
    end
end
function pData.countKills(e)
    local myData = pData.getData()
    if (myData["Daedra"][e.reference.baseObject.id:lower()] == false) then
        myData["Daedra"][e.reference.baseObject.id:lower()] = true
        myData["DaedraCount"] = myData["DaedraCount"] + 1
    elseif (string.find(e.reference.baseObject.id:lower(),"dagoth") and not myData["Dagoths"][e.reference.baseObject.id:lower()]) then
        myData["Dagoths"][e.reference.baseObject.id:lower()] = true
        myData["DagothsCount"] = myData["DagothsCount"] + 1
    else
        return
    end
end
function pData.countQuests(e)
    --count every time a quest is finished
    local myData = pData.getData()
    if (e.info.isQuestFinished) then
        myData["Quests"] = myData["Quests"] + 1
    end
end
function pData.onMenuExit()
    local myData = pData.getData()
    if (tes3.mobilePlayer.inJail == false) then
        event.unregister(tes3.event.menuExit, pData.onMenuExit)
        myData["inJail"] = false
    end
end
function pData.countEnchantments()
    local myData = pData.getData()
    myData["Enchant"] = myData["Enchant"] + 1
end
function pData.countDwem(e)
    local myData = pData.getData()
    if (myData["DwemerRuins"][e.cell.editorName:lower()] == false) then
        mwse.log(e.cell.editorName:lower())
        myData["DwemerRuins"][e.cell.editorName:lower()] = true
        myData["DwemerRuinsCount"] = myData["DwemerRuinsCount"] + 1
    else
        return
    end
end
function pData.calcFall()
    local myData = pData.getData()
    local zDiff = 0
    if (not myData["fallflag"]) then
        if (tes3.mobilePlayer.isFalling or tes3.mobilePlayer.isJumping) then
            myData["fallflag"] = true
            myData["beginz"] = tes3.mobilePlayer.position.z
        end
    else
        if ((not tes3.mobilePlayer.isFalling) and (not tes3.mobilePlayer.isJumping)) then
            myData["fallflag"] = false
            myData["finalz"] = tes3.mobilePlayer.position.z
            zDiff = myData["beginz"] - myData["finalz"]
        end
    end
    if (math.ceil(zDiff) >= 2460) then
        return true
    end
    return false
end
function pData.gotKeening()
    --Keening shares a journal ID with Sunder so the journal event isn't reliable
    local myData = pData.getData()
    if (tes3.player.object.inventory:contains("keening")) then
        return true
    end
end
function pData.findStolen()
    local numStolen = 0
    for _, itemStack in pairs(tes3.player.object.inventory) do
        local item = itemStack.object
        if (#item.stolenList ~= 0) then
            numStolen = numStolen + 1
        end
    end
    return numStolen
end
function pData.closedCallback()
    local myData = pData.getData()
    myData.FinalCount = pData.findStolen()
    myData["Stolen"] = myData["Stolen"] + (myData.FinalCount - myData.InitialCount)
    event.unregister(tes3.event.menuExit, pData.closedCallback)
end
function pData.soulFilter(e)
    local myData = pData.getData()
    e.filter = true
    ---@Cast target baseObject
    if (e.reference.baseObject.objectType == tes3creature and e.reference.baseObject.soul > 600) then
        myData["soulachieve"] = true
        event.unregister(tes3.event.filterSoulGemTarget, function() end)
    end
end
function pData.stealOrdActivate(e)
    local myData = pData.getData()
    if (e.activator == tes3.player) then
        if (e.target.baseObject.objectType == (tes3.objectType["ammunition"] or tes3.objectType["armor"])) then --add rest of object types
            if (tes3.getOwner({ reference = e.target}) ~= nil) then
                myData["Stolen"] = myData["Stolen"] + 1
            end
        elseif (e.target.baseObject.objectType == tes3.objectType["container"] ) then
            myData.InitialCount = pData.findStolen()
            event.register(tes3.event.menuExit, pData.closedCallback)
            --thanks Herbert for the idea of counting stolen items before and after to determine how much was stolen
        elseif (e.target.baseObject.objectType == tes3.objectType["npc"]) then
            myData.InitialCount = pData.findStolen()
            event.register(tes3.event.menuExit, pData.closedCallback)
        end
        if (string.find(string.lower(e.target.id), string.lower("ordinator"))) then
            if (tes3.getGlobal("WearingOrdinatorUni") == 1) then
                myData["Ordinator"] = true
            end
        end
    end
end
function pData.getData()
    return tes3.player.data.achieveData
end
function pData.initAchieveData()
    local data = tes3.player.data
    data.achieveData = data.achieveData or {}
    local myData = data.achieveData
    initTableValues(myData, defaults)
    --Trying to prevent events from registering that are no longer needed. no idea if that's really worth it
    if(myData["Stolen"] < 100 and myData["Ordinator"] == false and not event.isRegistered(tes3.event.activate, pData.stealOrdActivate)) then
        event.register(tes3.event.activate, pData.stealOrdActivate)
    end
    if (myData["DwemerRuinsCount"] < 24 and not event.isRegistered(tes3.event.cellChanged, pData.countDwem)) then
        event.register(tes3.event.cellChanged, pData.countDwem)
    end
    if (myData["Quests"] < 50 and not event.isRegistered(tes3.event.journal, pData.countQuests)) then
        event.register(tes3.event.journal, pData.countQuests)
    end
    if (myData["BooksCount"] < 50 and not event.isRegistered(tes3.event.bookGetText, pData.countBooks)) then
        --Thanks to Merlords's Bookworm mod for the idea to use bookGetText here
        event.register(tes3.event.bookGetText, pData.countBooks)
    end
    if (myData["soulachieve"] == false and not event.isRegistered(tes3.event.filterSoulGemTarget, pData.soulFilter)) then
        event.register(tes3.event.filterSoulGemTarget, pData.soulFilter)
    end
    event.register(tes3.event.crimeWitnessed, function(e)
        if (tes3.mobilePlayer.bounty > 0) then
            myData["noBounty"] = false
        end
    end)
    if (myData["DagothsCount"] < 47) then
        if (myData["DaedraCount"] < 11 and not event.isRegistered(tes3.event.death, pData.countKills)) then
            event.register(tes3.event.death, pData.countKills)
        end
    end
    event.register(tes3.event.potionBrewed, function()
        myData["Potion"] = myData["Potion"] + 1
    end)
    if (myData["Enchant"] < 100 and not event.isRegistered(tes3.event.enchantedItemCreated, pData.countEnchantments)) then
        event.register(tes3.event.enchantedItemCreated, pData.countEnchantments)
    end
end

return pData