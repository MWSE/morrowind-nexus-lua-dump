local lastBounty = 0

local function getCrimeLevel()
    if not tes3.player.data.NWNC then
        tes3.player.data.NWNC = {}
    end
    return tes3.player.mobile.bounty
end

local function setCrimeLevel(number)
    if number < 0 then
        print("Attempted to set crime to " .. tostring(number))
        number = 0
    end
    tes3.player.mobile.bounty = number
end
local function getObjectID(obj)
    return obj.id
end
local function crimeWitnessed(e)
    
    if not tes3.player.data.NWNC then
        tes3.player.data.NWNC = {}
    end
    
    if not tes3.player.data.NWNC.witnesses then
        tes3.player.data.NWNC.witnesses = {}
    end
    for index, value in ipairs(e.witness.mobile.friendlyActors) do
        if value.reference.id == tes3.player.id then
            return 
        end
    end
    local bountyAdded = getCrimeLevel() - lastBounty
    local witness =getObjectID(e.witness) 
    lastBounty = getCrimeLevel()
    local witnessFound = false
    for index, value in ipairs( tes3.player.data.NWNC.witnesses) do
        if value == witness then
            witnessFound = true
            
        end
    end
    if bountyAdded > 0  and not e.witnessMobile.isDead then
        tes3.player.data.NWNC.bountyPending = tes3.player.data.NWNC.bountyPending + bountyAdded
    end
    if not witnessFound and not e.witnessMobile.isDead then
        table.insert(tes3.player.data.NWNC.witnesses,witness)
    end
end
local function loadedCallback(e)
    if not tes3.player.data.NWNC then
        tes3.player.data.NWNC = {}
    end
    
    if not tes3.player.data.NWNC.witnesses then
        tes3.player.data.NWNC.witnesses = {}
    end
    lastBounty = getCrimeLevel()
end
local function cellChangedCallback(e)
    if not tes3.player.data.NWNC then
        tes3.player.data.NWNC = {}
    end
    
    if not tes3.player.data.NWNC.witnesses then
        tes3.player.data.NWNC.witnesses = {}
    end
    lastBounty = getCrimeLevel()
    tes3.player.data.NWNC.bountyPending = 0
    tes3.player.data.NWNC.witnesses = {}
end
local function deathCallback(e)
    local actorId = getObjectID(e.reference )
    local wasRemoved = false
    local witnessCount = 0
    local removeIndex = -1
    for index, value in ipairs(tes3.player.data.NWNC.witnesses) do
        if value == actorId then
            removeIndex = index
        else
            witnessCount = witnessCount + 1

        end
    end
    if removeIndex ~= -1 then
        
        table.remove(tes3.player.data.NWNC.witnesses,removeIndex)
        wasRemoved = true
      --  tes3.messageBox("Removing witness" .. actorId)
    end
    if witnessCount == 0 and wasRemoved then
        if tes3.player.data.NWNC.bountyPending > 0 then
        setCrimeLevel(getCrimeLevel() - tes3.player.data.NWNC.bountyPending)
        tes3.messageBox(
            "Last witness killed. " .. tostring(tes3.player.data.NWNC.bountyPending) .. " bounty removed.")
        end
        tes3.player.data.NWNC.bountyPending = 0
            
    else
    end
end
event.register(tes3.event.death, deathCallback)
event.register(tes3.event.cellChanged, cellChangedCallback)
event.register(tes3.event.loaded, loadedCallback)
event.register(tes3.event.crimeWitnessed, crimeWitnessed)