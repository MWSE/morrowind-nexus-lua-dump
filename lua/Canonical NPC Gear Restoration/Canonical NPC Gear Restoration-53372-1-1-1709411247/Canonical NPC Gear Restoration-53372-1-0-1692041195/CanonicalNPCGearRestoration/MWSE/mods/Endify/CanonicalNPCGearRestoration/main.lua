local StaffID = "ebony wizard's staff"  

local MGRank = {
    ["associate"] = 0,
    ["apprentice"] = 1,
    ["journeyman"] = 2,
    ["evoker"] = 3,
    ["conjurer"] = 4,
    ["magician"] = 5,
    ["warlock"] = 6,
    ["wizard"] = 7,
    ["masterWizard"] = 8,
    ["archMage"] = 9,
}

-- check if NPC already has a staff
local function hasWizardStaff(npc)
    for _, itemStack in pairs(npc.inventory) do
        if itemStack.object.id == StaffID then
            return true
        end
    end
    return false
end

-- add staff to all npcs that qualify, except trebonius
local function addStaffToNPC(npc)
    if npc.id ~= "trebonius artorius" and npc.faction and (npc.faction.id:lower() == "mages guild" or npc.faction.id:lower() == "t_cyr_magesguild" or npc.faction.id:lower() == "t_mw_magesguild" or npc.faction.id:lower() == "t_sky_magesguild" or npc.faction.id:lower() == "t_hsm_magesguild") then
        local rank = npc.factionRank
        if rank >= MGRank["wizard"] and not hasWizardStaff(npc) then
            npc.inventory:addItem({ item = StaffID })
        end
    end
end

local TStaffID = "silver staff of peace"	

local TelvanniRank = {
    ["hireling"] = 0,
    ["retainer"] = 1,
    ["oathman"] = 2,
    ["lawman"] = 3,
    ["mouth"] = 4,
    ["spellwright"] = 5,
    ["wizard"] = 6,
    ["master"] = 7,
    ["magister"] = 8,
    ["archmagister"] = 9,
}

-- check if NPC already has a staff
local function hasTelvanniStaff(npc)
    for _, itemStack in pairs(npc.inventory) do
        if itemStack.object.id == TStaffID then
            return true
        end
    end
    return false
end

-- add staff to all npcs that qualify, except edd theman
local function addTelvanniStaffToNPC(npc)
    if npc.id ~= "edd theman" and npc.faction and (npc.faction.id:lower() == "telvanni" or npc.faction.id:lower() == "t_mw_housetelvanni") then
        local rank = npc.factionRank
        if rank == TelvanniRank["mouth"] and not hasTelvanniStaff(npc) then
            npc.inventory:addItem({ item = TStaffID })
        end
    end
end

local RoyalWeaponID = "King's_Oath"
local OldRoyalWeaponID = "adamantium_claymore"

local RoyalGuardRank = {
    ["guard"] = 0,
    ["captain"] = 1,
}

-- check if NPC already has a King's Oath (mod added NPCs)
local function hasRoyalWeapon(npc)
    for _, itemStack in pairs(npc.inventory) do
        if itemStack.object.id == RoyalWeaponID then
            return true
        end
    end
    return false
end

-- add weapon and remove old one
local function addRoyalWeaponToNPC(npc)
    local faction = npc.faction
    local factionID = faction and faction.id:lower()
    local rank = npc.factionRank
    local npcID = npc.id

    if factionID == "royal guard" and rank == RoyalGuardRank["guard"] then
        if not hasRoyalWeapon(npc) then
            npc.inventory:addItem({ item = RoyalWeaponID })
            npc.inventory:removeItem({ item = OldRoyalWeaponID })
        end
    end
end

local SixthHBookIDs = {"bk_WaroftheFirstCouncil", "bk_SaintNerevar", "bk_NerevarMoonandStar", "bk_RealNerevar"}

local function hasSixthHBook(npc)
    for _, itemStack in pairs(npc.inventory) do
        for _, bookID in ipairs(SixthHBookIDs) do
            if itemStack.object.id == bookID then
                return true
            end
        end
    end
    return false
end

local function addSixthHBook(npc)
    if npc.id == "dorisa darvel" then
        for _, bookID in ipairs(SixthHBookIDs) do
            npc.inventory:addItem({ item = bookID })
        end
    end
end


local function onInitialized()
    for npc in tes3.iterateObjects(tes3.objectType.npc) do
        addStaffToNPC(npc)
        addTelvanniStaffToNPC(npc)
        addRoyalWeaponToNPC(npc)
        addSixthHBook(npc)
    end
end

mwse.log("[Canonical NPC Gear Restoration] Initialized Version 1.1")

event.register("initialized", onInitialized)
