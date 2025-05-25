-- Poleplay

-- Set up the configuration
local default_config = {
log_level               = "ERROR",
enabled                 = true,
min_hit_chance_staff    = 50,
min_hit_chance_spear    = 50,
hand_to_hand_modifier   = 30,
staff_modifier          = 30,
spear_modifier          = 25,
stun_enabled            = true,
stun_base_chance        = 50,
enable_staff_mechanics  = true,
enable_spear_mechanics  = true,

}
local confPath    = "sa_poleplay_config"
local config      = mwse.loadConfig (confPath, default_config)

-- Setting up the logger
local logger    = require("logging.logger")
local log       = logger.new{
    name        = "Poleplay",
    logLevel    = config.log_level,
}

--[[References

    Physical Attack Types
    Index	    Value
    none	    0
    slash	    1
    chop	    2
    thrust	    3
    projectile	4
    creature1	5
    creature2	6
    creature3	7

    Weapon Types
    These values are available in Lua by their index in the tes3.weaponType table. For example, tes3.weaponType.bluntOneHand has a value of 3.
    Index	            Value	Description
    shortBladeOneHand	0	    Short Blade, One Handed
    longBladeOneHand	1	    Long Blade, One Handed
    longBladeTwoClose	2	    Lon Blade, Two Handed
    bluntOneHand	    3	    Blunt Weapon, One Handed
    bluntTwoClose	    4   	Blunt Weapon, Two Handed (Warhammers)
    bluntTwoWide	    5   	Blunt Weapon, Two Handed (Staffs)
    spearTwoWide	    6   	Spear, Two Handed
    axeOneHand	        7   	Axe, One Handed
    axeTwoHand	        8	    Axe, Two Handed
    marksmanBow	        9	    Marksman, Bow
    marksmanCrossbow	10	    Marksman, Crossbow
    marksmanThrown	    11	    Marksman, Thrown
    arrow	            12  	Arrows
    bolt	            13	    Bolts
    ]]


-- Modifying the attack chance
local function hitChanceManipulation(e)
  if not config.enabled then return end
    -- Check if the attacker is the player or an NPC, and we filter out nils as well.
    if not ((e.attackerMobile.objectType == tes3.objectType.mobileNPC) or (e.attackerMobile.objectType == tes3.objectType.mobilePlayer)) then log:trace("Hit chance not calculated: Not a player or NPC") return end  

    -- Check if we have a weapon equipped
    if not e.attackerMobile.readiedWeapon then log:trace("Hit chance not calculated: Attacker has no weapon") return end

    -- Check if the attacker is hitting anything
    if not e.targetMobile then log:trace("Hit chance not calculated: Attacker has no target mobile to hit") return end

    -- Get the weapon type. It was nill checked above
    local weapon        = e.attackerMobile.readiedWeapon.object -- This should return a tes3weapon
    local attackType    = e.attackerMobile.actionData.physicalAttackType -- This should return a number


    -- Let's nil check again just to be sure
    if not ((weapon ~= nil) and (attackType ~= nil)) then log:trace("Hit chance not calculated: Weapon or attack type are nil") return end

    if weapon.type == tes3.weaponType.bluntTwoWide and config.enable_staff_mechanics then
        -- If we are using a staff
        log:trace(string.format("Staff attack - Initial chance: %s", e.hitChance))

        e.hitChance = math.max(e.hitChance, config.min_hit_chance_staff)

        log:trace(string.format("Staff attack - New chance: %s", e.hitChance))

    elseif weapon.type == tes3.weaponType.spearTwoWide and config.enable_spear_mechanics then
        -- If we are using a spear, check if the attack is slash or chop
        log:trace(string.format("Spear attack - Initial chance: %s", e.hitChance))

        if attackType == 1 or attackType == 2 then
            e.hitChance = math.max(e.hitChance, config.min_hit_chance_spear)
        end

        log:trace(string.format("Spear attack - New chance: %s", e.hitChance))
    end
end

-- Modifying the damage
local function modifyDamage(e)
  if not config.enabled then return end
  -- Check if the damage source is an attack.
    if not e.source == tes3.damageSource.attack then log:trace("Damage not modified: Not an attack") return end

  -- Caution! There is a change in naming from hitchance to damage. attackerMobile is now simply attacker, and targetMobile is simply mobile

    -- Check if the attacker is the player or an NPC, and we filter out nils as well.
    if not ((e.attacker.objectType == tes3.objectType.mobileNPC) or (e.attacker.objectType == tes3.objectType.mobilePlayer)) then log:trace("Damage not modified: Not a player or NPC") return end  

    -- Check if we have a weapon equipped
    if not e.attacker.readiedWeapon then log:trace("Damage not modified: Attacker has no weapon") return end

    -- Check if the attacker is hitting anything
    if not e.mobile then log:trace("Damage not modified: Attacker has no target mobile to hit") return end

    -- Get the weapon type, attack type, and the attacker skills
    local weapon        = e.attacker.readiedWeapon.object           -- This should return a tes3weapon
    local attackType    = e.attacker.actionData.physicalAttackType  -- This should return a number
    local kungfu        = e.attacker:getSkillValue(26)              -- This should also return a number. 26 is hand to hand
    local spear         = e.attacker:getSkillValue(7)               -- Same as above. 7 is for spears
    local stick         = e.attacker:getSkillValue(4)               -- and 4 is for blunt weapon
    local fatigueDamage = 0                                         -- Initializing the auxiliary value for fatigue damage
    local stunChance    = 0                                         -- Initializing the auxiliary value for stun chance


    -- Let's nil check again just to be sure
    if not ((weapon ~= nil) and (attackType ~= nil) and (kungfu ~= nil) and (spear ~= nil) and (stick ~= nil)) then log:error("Damage not calculated: Initialization of values went wrong") return end

    -- Ok, that should be enough. Now, lets start modifying the damage
    if weapon.type == tes3.weaponType.bluntTwoWide and config.enable_staff_mechanics then
        -- If we are using a staff
        log:trace("Staff attack - Trying to cause stamina damage")
        
        -- Calculate fatigue damage
        fatigueDamage = math.floor(0.5*(kungfu*config.hand_to_hand_modifier/100 + stick*config.staff_modifier/100))
        -- Log the damage    
        log:trace(string.format("Staff attack - Fatigue damage: %s", fatigueDamage))
        -- Apply fatigue damage
        e.mobile:applyFatigueDamage(fatigueDamage)

        
      if config.stun_enabled then
       -- Calculate stun chance
        stunChance = math.clamp(math.random(0, 75) + math.random(0, kungfu), 0, 100)
        log:trace(string.format("Stun chance: %s", stunChance))
       
        if stunChance >= (100-config.stun_base_chance) then
          e.mobile:hitStun()
          log:trace("Stun succeeded")
        else
          log:trace("Stun failed")
        end
      end
        
  


    elseif weapon.type == tes3.weaponType.spearTwoWide and config.enable_spear_mechanics then
        -- If we are using a spear, check if the attack is slash or chop
        if attackType == 1 or attackType == 2 then
            log:trace(string.format("Spear attack - Trying to cause fatigueDamage"))

            fatigueDamage = math.floor(spear*config.spear_modifier/100)
            e.mobile:applyFatigueDamage(fatigueDamage)
            log:trace(string.format("Spear attack - Fatigue damage: %s", fatigueDamage))
        
             if config.stun_enabled then
              -- Calculate stun chance
              stunChance = math.clamp(math.random(0, 75) + math.random(0, kungfu), 0, 100)
              log:trace(string.format("Stun chance: %s", stunChance))

              if stunChance >= (100-config.stun_base_chance) then
              e.mobile:hitStun()
              log:trace("Stun succeeded")
              else
              log:trace("Stun failed")
              end
            end

        end
    end
end







-- Initializing the mod
local function initialized()
    -- Register the hitchance event
    event.register(tes3.event.calcHitChance, hitChanceManipulation, { priority = -10 })
    -- Register the damage event
    event.register(tes3.event.damage, modifyDamage, { priority = -10 })
    
    -- Print a "Ready!" statement to the MWSE.log file.
    print("[Poleplay: INFO] Poleplay has been initialized")
end


-- MCM stuff
local function modConfigReady()
  local mcm = mwse.mcm
	local template = mcm.createTemplate("Poleplay")
  template:saveOnClose(confPath, config)

  
    local page = template:createSideBarPage{
        sidebarComponents = {
            mcm.createInfo{ 
			text = "Poleplay\n \nBy Storm Atronach\n \nHave you ever wanted to play a monk, or an effective spearman? With this mod, additional mechanics are added to improve on these two awesome weapons.\n \nHit chance improvement: When you use a staff, or use the spear to chop or slash, your hit chance is improved to a minimum. You are wielding a big stick after all!\n \nFatigue damage: When using a staff, you also cause fatigue damage. Release the inner monk!\n \nWhen using a spear, and choping or slashing, you can also cause fatigue damage.\n \nStun chance: The attacks with staff or spear (except thrust) have a chance to cause stun\n \nUse responsibly or crank it up to the max and embrace the cheese! your choice :)"},
        }
    }
	
    
  local main_settings = page:createCategory("Settings")
  
  -- Master enable/disable button
 
  main_settings:createOnOffButton{
      label = "Poleplay",
      description = "Enable or disable the entire Poleplay mod.",
      variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
  }


  -- Staff and spear mechanics buttons
  main_settings:createOnOffButton{
    label = "Staff mechanics",
    description = "Toggle staff mechanics (fatigue, hit chance, stun).",
    variable = mwse.mcm.createTableVariable{ id = "enable_staff_mechanics", table = config } 
  }

  main_settings:createOnOffButton{
    label = "Spear mechanics",
    description = "Toggle spear mechanics (fatigue, hit chance, stun).",
    variable = mwse.mcm.createTableVariable{ id = "enable_spear_mechanics", table = config } 
  }

    -- Stun chance button
    main_settings:createOnOffButton{
      label = "Stun chance",
      description = "Toggle whether an additional stun chance is granted during attack. Default: Enabled",
      variable = mwse.mcm.createTableVariable{ id = "stun_enabled", table = config }
  }
  
  -- Stun chance slider
    main_settings:createSlider{
		label = "Base stun chance",
		description = [[
    This is the base chance for the stun.
    
    Default: 50%
    ]],
		variable = mwse.mcm.createTableVariable{ id = "stun_base_chance", table = config },
		min = 0, max = 100, step = 1, jump = 10
	}
    -- Logging level dropdown
    main_settings:createDropdown{
        label = "Logging Level",
        description = [[
          How much mod will spam your MWSE log.
          ERROR level is enough for most users (will report only potential issues)
          Anything higher is for debugging.
        ]],
        options = {
          { label = "TRACE", value = "TRACE"},
          { label = "DEBUG", value = "DEBUG"},
          { label = "INFO", value = "INFO"},
          { label = "ERROR", value = "ERROR"},
          { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "log_level", table = config },
        callback = function(self)
          log:setLogLevel(self.variable.value)
        end
      }
  
    main_settings:createSlider{
		label = "Minimum hit chance for staff",
		description = [[
    This is the minimum hit chance when attacking with a staff.
    
    Default: 50%
    ]],
		variable = mwse.mcm.createTableVariable{ id = "min_hit_chance_staff", table = config },
		min = 0, max = 100, step = 1, jump = 10
	}
    
    main_settings:createSlider{
		label = "Minimum hit chance for spear",
		description = [[
    This is the minimum hit chance slashing or chopping with a spear. Thrust is not affected.
    Default: 50%
    ]],
		variable = mwse.mcm.createTableVariable{ id = "min_hit_chance_spear", table = config },
		min = 0, max = 100, step = 1, jump = 10
	}
    
    main_settings:createSlider{
		label = "Hand to hand modifier",
		description = [[
    This is the contribution of the hand to hand skill to fatigue damage when using a staff.
    
    Default: 30%
    ]],
		variable = mwse.mcm.createTableVariable{ id = "hand_to_hand_modifier", table = config },
		min = 0, max = 100, step = 1, jump = 10
	}

    main_settings:createSlider{
		label = "Staff skill modifier",
		description = [[
    This is the contribution of the blunt weapon skill to fatigue damage when using a staff.
    
    Default: 30%
    ]],
		variable = mwse.mcm.createTableVariable{ id = "staff_modifier", table = config },
		min = 0, max = 100, step = 1, jump = 10
	}

    main_settings:createSlider{
		label = "Spear skill modifier",
		description = [[
    This is the contribution of the spear skill to fatigue damage when using a spear.
    
    Default: 25%
    ]],
		variable = mwse.mcm.createTableVariable{ id = "spear_modifier", table = config },
		min = 0, max = 100, step = 1, jump = 10
	}


    mwse.mcm.register(template)
end
-- Register our initialized function to the initialized event.
event.register(tes3.event.initialized, initialized)
event.register('modConfigReady', modConfigReady)
