--- This function returns `true` if a given mobile has
--- follow ai package with player as its target
---@param mobile tes3mobileNPC|tes3mobileCreature
---@return boolean isFollower
local function isFollower(mobile)
    local planner = mobile.aiPlanner
    if not planner then
        return false
    end

    local package = planner:getActivePackage()
    if not package then
        return false
    end
    if package.type == tes3.aiPackage.follow
    -- Depending on your needs, you can also include the actor's escorter.
    -- In the base game, AiEscort package is quite rare. Only White Guar
    -- has that package and targetActor is the player.
    or package.type == tes3.aiPackage.escort then
        local target = package.targetActor

        if target.objectType == tes3.objectType.mobilePlayer then
            return true
        end
    end
    return false
end

--- With the above function we can build a function that
--- creates a table with all of the player's followers
---@return tes3reference[] followerList
local function getFollowers()
    local followers = {}
    local i = 1

    for _, mobile in pairs(tes3.mobilePlayer.friendlyActors) do
        ---@cast mobile tes3mobileNPC|tes3mobileCreature
        if isFollower(mobile) then
            followers[i] = mobile.reference
            i = i + 1
        end
    end

    return followers, i
end
local function getTravelCost(rank)
    if rank < 3 then--under journeyman
        return 150
    elseif rank < 8 then--under wizard
        return 100
    else--wizard and above
        return 50
    end
end
local function isInMagesGuild(id)
    if not id then
        return false
    elseif id:lower() == "mages guild" then
        return true
    elseif id:lower() == "kjs_guigui_faction" then
        return true
    else
        return false
    end
end
local function calcTravelPriceCallback(e)
    local faction = e.mobile.object.faction
    local price = e.price
    local followers, count = getFollowers()
    local factionId
    if faction then
        factionId = faction.id:lower()
    end
    if isInMagesGuild(factionId) then
       e.price = getTravelCost(faction.playerRank)
       
       for index, value in ipairs(followers) do
            local rank = 0
            local followerFaction = value.object.faction
            local followerFactionId
            if followerFaction then
                followerFactionId = followerFaction.id:lower()
            end
            if isInMagesGuild(  followerFactionId )  then
                rank = value.object.factionRank
            end
            e.price = e.price + getTravelCost(rank)
       end
    end
end
event.register(tes3.event.calcTravelPrice, calcTravelPriceCallback)