--[[
Mod: Wizard's Staff for Wizards 
Adds a Wizard's Staff to all NPCs in the Mage's Guild rank wizard or higher with exceptions.
]]

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

local MGFactionIDs = {
    ["mages guild"] = true,
    ["t_cyr_magesguild"] = true,
    ["t_mw_magesguild"] = true,
    ["t_sky_magesguild"] = true,
    ["t_ham_magesguild"] = true,
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
--check if NPC is correct rank
local function qualifiesForStaff(npc)
    local faction = npc.faction
    if faction and MGFactionIDs[faction.id:lower()] then
        local rank = npc.factionRank
        return rank >= MGRank["wizard"] and not hasWizardStaff(npc)
    end
    return false
end

-- trebonius already has a staff, so he doesn't get a new one
local function addStaffToNPC(npc)
    if npc.id ~= "trebonius artorius" and qualifiesForStaff(npc) then
        npc.inventory:addItem({ item = StaffID })
    end
end

local function onInitialized()
    -- iterate through all NPCs and add the staff to qualifying ones
    for npc in tes3.iterateObjects(tes3.objectType.npc) do
        addStaffToNPC(npc)
    end
end

event.register("initialized", onInitialized)
