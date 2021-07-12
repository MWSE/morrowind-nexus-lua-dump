-- HitType indicates a glance (0), hit (1), or crit (2)
local HitType = 1
-- whether the actor has been detected
local detected = 1
-- initialize TGM off
local godmode = false

-- delcarations
local CritChance
local HitChance
local GlanceChance
local equippedWeaponStack
local equippedWeaponStack_bow
local equippedWeaponStack_crossbow
local equippedWeaponStack_thrown
local CritMod
local GlanceMod
local f
local ConsoleRegister
local command


-- function to check if an element is in a table
local function tablecontains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- RolltoHit, check whether a glance, hit, or crit occured, and set the damage modifiers for each HitType
-- e = calcHitChance
local function HitCheck(e)
    -- skip if you are being attacked in godmode
    if (godmode == true and e.target == tes3.player) then 
        return
    end
    
    local RolltoHit = math.random(100)

    -- stored crit chance
    -- CritChance = math.clamp(e.hitChance - RolltoHit, 0, 100) (old calculation)
    CritChance = (e.hitChance*0.1)^2
    -- stored hit chance
    HitChance = e.hitChance - CritChance
    -- stored glance chance
    GlanceChance = 100 - e.hitChance

    -- glancing blow condition: what would have been a miss
    if (e.hitChance < RolltoHit) then 
        HitType = 0
    else
        local RolltoCrit = math.random(100)
        -- crit condition
        if (CritChance >= RolltoCrit) then
            HitType = 2
        else
            HitType = 1
        end
    end

    e.hitChance = 100 -- never miss
    
    -- check whether the actor has a marksmanship weapon equipped
    equippedWeaponStack_bow = tes3.getEquippedItem{actor = e.attacker, objectType = tes3.objectType.weapon, type = 9}
    equippedWeaponStack_crossbow = tes3.getEquippedItem{actor = e.attacker, objectType = tes3.objectType.weapon, type = 10}
    equippedWeaponStack_thrown = tes3.getEquippedItem{actor = e.attacker, objectType = tes3.objectType.weapon, type = 11}

    -- set the glance and crit modifiers
    if (equippedWeaponStack_bow or equippedWeaponStack_crossbow or equippedWeaponStack_thrown) then
        -- ranged crit
        CritMod = 1.5
    else 
        -- melee crit
        CritMod = 4
    end
    GlanceMod = 0.5

    -- balancing factor: shift would-be damage from hits into glances and crits. The result is the same average damage as the base game.
    f = (HitChance + CritChance)/(GlanceChance*GlanceMod + HitChance + CritChance*CritMod)
    
    if (detected == 0 and e.attacker == tes3.player) then -- sneak attack
        HitType = 1 -- set HitType to 1 and let morrowind automatically multiply damage by CritMod
    end

    -- fist attacks are special because they don't do damage unless the target has no fatigue, causes issues with magic unless HitChance is reset
    equippedWeaponStack = tes3.getEquippedItem{actor = e.attacker, objectType = tes3.objectType.weapon}
    if (not equippedWeaponStack) then
        if (e.targetMobile.fatigue.current > 0) then
            if (e.target == tes3.player) then
                HitType = 1 -- reset HitType for npcs, not for player because of skill increase
            end
            HitChance = nil
        end
        return -- fists are not "normal weapons" so the next if statement doesn't apply
    end
    
    -- if you miss the enemy because they are immune to normal weapons, then reset variables
    if (e.targetMobile.resistNormalWeapons == 100 and equippedWeaponStack.object.flags == 0) then
        HitChance = nil
        HitType = 1
    end

end

-- check if the attacker is detected while sneaking 
-- e = detectSneak
local function SneakCheck(e)
    if (e.isDetected == true) then
        detected = 1
    else 
        detected = 0
    end
end

-- set damage for each hit type
-- e = damage
local function SetDamage(e)    
    
    -- needed in the case of non-melee/ranged damage
    if (not HitChance) then
        return
    end

    -- glance damage
    if (HitType == 0) then
        e.damage = GlanceMod*e.damage*f
    -- hit damage
    elseif (HitType == 1) then
        e.damage = e.damage*f
    -- crit damage
    elseif (HitType == 2) then
        e.damage = CritMod*e.damage*f
    end
    -- reset HitChance
    HitChance = nil
end

-- set the sound effect for glances and crits
-- e = damaged
local function SoundChange(e)
    if (HitType == 0) then
        tes3.removeSound{sound = "Health Damage", reference = e.reference}
        tes3.playSound{sound = "Hand To Hand Hit 2", reference = e.reference} -- make glances sound like a blunt impact
        if (e.reference == tes3.player) then
            HitType = 1 -- reset HitType for npcs
        end
    elseif (HitType == 2 or detected == 0) then
        tes3.playSound{sound = "critical damage", reference = e.reference}
        if (e.reference == tes3.player) then
            HitType = 1 -- reset HitType for npcs
        end
    end
end

-- set the skill increase rate for each HitType
-- e = exercizeSkill
local function SkillChange(e)

    -- include the balancing factor to ensure average skill increase is the same as vanilla
    
    -- non-combat skill increases are unaffected
    local combatskills = {4, 5, 6, 7, 22, 23, 26}
    if (not (tablecontains(combatskills, e.skill))) then 
        return
    end

    -- glancing blow causes less increase
    if (HitType == 0) then
        e.progress = e.progress*GlanceMod*f
        HitType = 1 -- reset HitType for the player
    -- hits increase skill as normal (modified by f)
    elseif (HitType == 1) then
        e.progress = e.progress*f
    -- crits result in increased experience 
    else
        e.progress = e.progress*CritMod*f
        HitType = 1 -- reset HitType for the player
    end
end

-- TGM is case-insensitive, so in order to check for it we need a case-insensitive table
function CreateCaseInsensitiveTable()
    local metatbl = {}
  
    function metatbl.__index(table, key)
        if(type(key) == "string") then
            key = key:lower()
        end
  
        return rawget(table, key)
    end
  
    function metatbl.__newindex(table, key, value)
        if(type(key) == "string") then
            key = key:lower()
        end
  
        rawset(table, key, value)
    end
  
    local ret = {}
    setmetatable(ret, metatbl)
    return ret
end

-- keeps track of when godmode is toggled
-- e = uiEvent 
local function ConsoleEvent(e)
    local tgmtable = CreateCaseInsensitiveTable()
    tgmtable["TGM"] = true
    tgmtable["ToggleGodMode"] = true

    -- Store the command as it's being typed
    if (e.block.name == "MenuConsole_text_input") then
        command = e.block.text
    end

    -- once entered, check if it's tgm
    if (e.property == 4294934591) then -- property for entering a command in the console
        if (tgmtable[command] and godmode == false) then
            godmode = true
        elseif (tgmtable[command] and godmode == true) then
            godmode = false
        end
    end
end

local function MenuEnterFun(e)
    if (e.menu.name == "MenuConsole") then
        event.register("uiEvent", ConsoleEvent)
        ConsoleRegister = true
    end 
end

local function MenuExitFun(e)
    if (ConsoleRegister == true) then
		event.unregister("uiEvent", ConsoleEvent)
    end 
end



-- initialization function
local function initialized()
    
    -- RolltoHit; check whether a glance, hit, or crit occured; set the damage modifiers for each HitType
    event.register("calcHitChance", HitCheck)

    -- check if the attacker is detected while sneaking (the game automatically crits if not detected)
    event.register("detectSneak", SneakCheck)

    -- set damage for each hit type
    event.register("damage", SetDamage)

    -- set the sound effect for glances and crits
    event.register("damaged", SoundChange)

    -- set the skill increase rate for each HitType
    event.register("exerciseSkill", SkillChange)

    event.register("menuEnter", MenuEnterFun)

    event.register("menuExit", MenuExitFun)

    print("[GBAC 1.1.2] Glancing Blows and Crits initialized")

end

event.register("initialized", initialized)