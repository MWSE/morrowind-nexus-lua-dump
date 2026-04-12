--[[
Faction Perk Pack for OpenMW using ErnPerkFramework.
All 10 vanilla joinable factions. 40 perks total.

ESP REQUIREMENTS - Created in FactionPerkSpells.ESP
  

    TG:
        FPerks_TG1_Passive               = Ability, +5 Agility, +10 Sneak, +10 Security
        FPerks_TG2_Passive               = Ability, +15 Agility, +25 Sneak, +25 Acrobatics
        FPerks_TG3_Passive               = Ability, +25 Agility, +50 Sneak, +50 Mercantile
        FPerks_TG4_Passive               = Ability, +25 Luck, +75 Security
        FPerks_TG3_Cham                  - Ability, 25 Chameleon
        FPerks_TG4_Cham                  - Ability, 50 Chameleon

    MT:
        FPerks_MT1_Passive               - +5 Speed, +10 Short Blade, +10 Speechcraft
        FPerks_MT2_Passive               - +15 Speed, +25 Short Blade, +25 Light Armour 
        FPerks_MT3_Passive               - +25 Speed, +50 Sneak, +50 Short Blade
        FPerks_MT4_Passive               - +25 Strength, +75 Short Blade, +75 Sneak
        FPerks_MT2_Frenzy                - Spell, Frenzy, free, unlimited
        FPerks_MT4_Invisibility          - Spell, Invisibility, free, unlimited
        FPerks_MT4_Lifesteal             - Spell Effect, Absorb Life 25pts 5s

    HH:
        FPerks_HH1_Passive          - +5 Personality, +10 Speechcraft
        FPerks_HH2_Passive          - +15(10) Personality, +25(15) Speechcraft, +25 Illusion
        FPerks_HH3_Passive          - +25(10) Personality, +50(25) Mercantile
        FPerks_HH4_Passive          - +25 Personality, +75(25) Speechcraft

    FG:

        FPerks_FG1_Passive              - +5 Strength, +10 Fortify Health
        FPerks_FG2_Passive              - +15 Strength, +25 Fortify Health
        FPerks_FG3_Passive              - +25 Strength, +50 Fortify Health
        FPerks_FG4_Passive              - +25 Endurance, +75 Fortify Health, Restore Health 1pt/s, Restore Fatigue 1pt/s
        FPerks_FG3_Enrage               - Power, Fortify Health 50pts, Fortify Fatigue 200pts, Fortify Attack 100pts, 30s duration.

    IL:
        FPerks_IL1_Passive          - +5 Endurance, +10 Fortify Fatigue, +10 Medium Armour, +10 Heavy Armour
        FPerks_IL2_Passive          - +15 Endurance, +25 Fortify Fatigue, +25 Block
        FPerks_IL3_Passive          - +25 Endurance, +50 Fortify Fatigue, +50 Athletics
        FPerks_IL4_Passive          - +25 Strength, +75 Fortify Fatigue, +75 Heavy Armour,
        FPerks_IL4_Restore_Phys     - Restore Health 1pt/s, Restore Fatigue 1pt/s

    Non-table spells (granted once, not removed on rank-up):
        FPerks_IL3_Prowess          - Power (granted at P3, removed on full respec only)

   IC:
        FPerks_IC1_Passive          - +5 Willpower, +10 Resist Disease, +10 Resist Poison,
                                      +10 Resist Normal Weapons
        FPerks_IC2_Passive          - +15 Willpower, +25 Resist Disease, +25 Resist Poison,
                                      +25 Resist Normal Weapons
        FPerks_IC3_Passive          - +25 Willpower, +50 Resist Disease, +50 Resist Poison,
                                      +50 Resist Normal Weapons
        FPerks_IC4_Passive          - +25 Personality, +75 Resist Disease, +75 Resist Poison,
                                      +75 Resist Normal Weapons

        Non-table spells (granted once, not removed on rank-up):
        "divine intervention"       Vanilla spell (P1)
        FPerks_IC4_AllAttributes    Power (P4)

    MG:
        FPerks_MG1_Passive          - +5 Intelligence, +10 Fortify Magicka
        FPerks_MG2_Passive          - +15 Intelligence, +25 Fortify Magicka
        FPerks_MG3_Passive          - +25 Intelligence, +50 Fortify Magicka,
                                      Fortify Maximum Magicka 0.5x Intelligence (magnitude 5)
        FPerks_MG4_Passive          - +25 Willpower, +75 Fortify Magicka,
                                      Fortify Maximum Magicka 1.0x Intelligence (magnitude 10)

    TT:
        FPerks_TT1_Passive          - +5 Intelligence, +10 Reflect, +10 Resist Paralysis,
                                      +10 Resist Blight Disease
        FPerks_TT2_Passive          - +15 Intelligence, +25 Reflect, +25 Resist Paralysis,
                                      +25 Resist Blight Disease
        FPerks_TT3_Passive          - +25 Intelligence, +50 Reflect, +50 Resist Paralysis,
                                      +50 Resist Blight Disease
        FPerks_TT4_Passive          - +25 Personality, +75 Reflect, +75 Resist Paralysis,
                                      +75 Resist Blight Disease

    Non-table spells (granted once, not removed on rank-up):
        FPerks_TT2_Cure_All         Power (P2)
        FPerks_TT4_Summon_Army      Power (P4)
        
   HR:
        FPerks_HR1_Passive          - +5 Endurance, +10 Spear, +10 Athletics
        FPerks_HR2_Passive          - +15(10) Endurance, +25(15) Heavy Armor, +25 Block
        FPerks_HR3_Passive          - +25(10) Endurance, +50(25) Spear, +50(25) Block
        FPerks_HR4_Passive          - +25 Strength, +75(25) Spear, +75(25) Heavy Armor

    HT:
        FPerks_HT1_Passive          - +5 Intelligence, +10 Enchant, +10 Alchemy,
                                      +10 Spell Absorption
        FPerks_HT2_Passive          - +15 Intelligence, +25 Enchant, +25 Alchemy,
                                      +25 Spell Absorption
        FPerks_HT3_Passive          - +25 Intelligence, +50 Enchant, +50 Alchemy,
                                      +50 Spell Absorption,
                                      Fortify Maximum Magicka 0.5x Intelligence (magnitude 5)
        FPerks_HT4_Passive          - +25 Willpower, +75 Enchant, +75 Alchemy,
                                      +75 Spell Absorption,
                                      Fortify Maximum Magicka 1.0x Intelligence (magnitude 10)


  Vanilla spell IDs used directly:
  "divine intervention"  IC Perk 1
  "almsivi intervention" TT Perk 1
  "strong levitate"      HT Perk 1
  "mark"                 HT Perk 2
  "recall"               HT Perk 2

]]

local ns         = require("scripts.FactionPerks.namespace")
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')

-- ============================================================
--  MORAG TONG SNEAK ATTACKS
-- ============================================================

local selfIsPlayer = self.type == types.Player
PlayerIsSneaking = false

function UpdatePlayerSneakStatus(currentSneakStatus)
    PlayerIsSneaking = currentSneakStatus
end

local function MT4AttackSuccessful(attack)

    -- Successful attack check
    if not (attack.sourceType == interfaces.Combat.ATTACK_SOURCE_TYPES.Melee or attack.sourceType == interfaces.Combat.ATTACK_SOURCE_TYPES.Ranged) then--If it's NOT a successful hit with a weapon, back out
        return false
    end 


    -- Proceed

     -- player crouch check
    if attack.attacker.type == types.Player and not PlayerIsSneaking then --If the attacker is the player, and PlayerIsSneaking is false back out
        return false
    end

    --Proceed

    return true --If all are true, then the attack is a successful one
end

function DoMT4Attack(attack)

    if not MT4AttackSuccessful(attack) then return end --If the attack wasn't successful, the modifier isn't applied

    -- if the blow did health damage, produce the magic effect
     if attack.damage.health >= 0 then
        types.Actor.activeSpells(self):add({
        id = "FPerks_MT4_Lifesteal", -- Applies Mephala's Kiss
        effects = {0}, -- Applies effect 0; the Absorb Health effect

        --Sets caster to the player, so that the drain applies properly
        caster = attack.attacker,
        
        --Ignores all resistances and reflections to apply no matter what
        ignoreReflect = true,
        ignoreResistances = true,
        ignoreSpellAbsorption = true
        }) 

        -- mesage for debugging
        print("Mephala's Kiss Triggered!")

    else
        return
    end
end

