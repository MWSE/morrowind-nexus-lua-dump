local public = {}
public.perks = {}
local perks = {}

local perkFramework = require("KBLib.PerkSystem.perkSystem")
local common = require("KBLib.PerkSystem.common")

local magickaExpanded = include("OperatorJack.MagickaExpanded")

public.playerInfo = require("KBLib.PerkSystem.player")
--include("OperatorJack.EnhancedDetection")

local savedDataDefault = {}
local savedData = savedDataDefault


--menu code starts

--local function perkMenu(e)
--    local menuCheck = tes3.menuMode()
--    if menuCheck == true then
--        return
--    else
--        local perkPage = tes3ui.createMenu({
--            id = "hat_perkmenu",
--            fixedFrame = true
--        })
--        local showMenu = tes3ui.enterMenuMode(hat_perkmenu)
--        
--        return showMenu
--    end
--end
--event.register(tes3.event.keyDown, perkMenu)

--event code starts

--am big dumb dumb. just check "isSneaking" triggered on an animation change event

--local function objectSetup()
--    local params = {
--        id = "hat_perk_thiefeye",
--        name = "Thieving Perception",
--        magickaCost = nil,
--        effects = {
--            [1] = {
--                id = tes3.effect.detectDoor,
--                range = nil,
--                min = nil,
--                max = nil,
--                duration = nil,
--                radius = 5
--            },
--            [2] = {
--                id = tes3.effect.detectKey,
--                range = nil,
--                min = nil,
--                max = nil,
--                duration =nil,
--                radius = 5
--            },
--            [3] = {
--                id = tes3.effect.detectTrap,
--                range = nil,
--                min = nil,
--                max = nil,
--                duration = nil,
--                radius = 5
--            }
--        }
--    }
--end
--event.register(tes3.event.loaded, objectSetup)

local function spStartScript()
	mwse.log("[hat.somePerks.info] initialized")
end
event.register(tes3.event.initialized, spStartScript)

local function onLoad(e)
	if not tes3.player.data.hat_somePerks then 
		tes3.player.data.hat_somePerks = savedDataDefault
	end
	savedData = tes3.player.data.hat_somePerks
end
event.register(tes3.event.loaded, onLoad)

--sneak detection loop
local function isSneak(e)
    if (e.reference == tes3mobilePlayer) then
        if (e.currentGroup <= 15) then
            perk.deactivatePerk(hat_perk_nighteye)
            perk.deactivatePerk(hat_perk_thiefeye)
        else
            if (e.currentGroup == 16) then
                perk.activatePerk(hat_perk_nighteye)
                perk.activatePerk(hat_perk_thiefeye)
            end
        end
    end
end
event.register(tes3.event.playGroup, isSneak)

--gives the player enemy radar in combat if have perk and removes it when out of combat
local function alertStart(e)
    if (e.target == tes3mobileplayer) and perks.nmeHud.activated then
        tes3.addSpell({
            reference = (tes3.player),
            spell = hat_perk_alert,
            updateGUI = false
        })
    end
end
event.register(tes3.event.combatStarted, alertStart)

local function alertEnd(e)
    if (e.actor == tes3mobileplayer) and perks.nmeHud.activated then
        tes3.removeSpell({
            reference = (tes3.player),
            spell = hat_perk_alert,
            updateGUI = false
        })
    end
end
event.register(tes3.event.combatStopped, alertEnd)

local function crossbowHit(e)
    if (e.source == tes3.damageSource.attack) then
		if tes3.mobilePlayer.readiedWeapon then
            if (tes3.mobilePlayer.readiedWeapon.object.type == tes3.weaponType.marksmanCrossbow) and perks.quickShot.activated then
            local dmgMult = 1.0 + math.min((tes3mobilePlayer.speed / 100), 1.0)
            e.damage = e.damage * dmgMult
            end
        end
    end
end
event.register(tes3.event.damage, crossbowHit)

--perk code starts

local function createPerk()

    --idea:blunt weapon perk that uses blunt weapon stat to determine chance to paralyze target and stregnth to determine length of paralyze

    perks.debug = perkFramework.createPerk({
        id = "hat_debug",
        name = "debug",
        description = "this is a debug, it does nothing, but if this shows up things are working"
    })

    perks.nmeHud = perkFramework.createPerk({
        id = "hat_nmehud",
        name = "Alert Fighter",
        description = "Its important to keep track of hostiles in combat if you intend to survive. You've gained the experience to learn a trick to do that better",
        lvlReq = 8,
    })

    perks.thiefEye = perkFramework.createPerk({
        id = "hat_thiefeye",
        name = "Thieving Perception",
        description = "Like a good thief, you're always keeping an eye out for anything locked, and those who may spot your attempts to change that",
        skillReq = {security = 30},
        spells = {tes3.getObject("hat_perk_thiefeye")},
        delayActivation = true
    })

    perks.quickShot = perkFramework.createPerk({
        id = "hat_quickshot",
        name = "Quick Shot",
        description = "You're a beast with a crossbow and know how to use your agility and speed to your advantage. Increases your damage with crossbows based on your speed and agility",
        skillReq = {marksman = 50},
        attributeReq = {speed = 50, agility = 60}
    })
    perks.recoverHero = perkFramework.createPerk({
		id = "hat_recoverhero",
		name = "Heroic Recovery",
		description = "With the stamina of a true hero. You now restore +1 fatigue per second",
        spells = {tes3.getObject("hat_perk_recovery1")}
	})

    perks.recoverLegend = perkFramework.createPerk({
        id = "hat_recoverlegened",
        name = "Legendary Recovery",
        description = "The bounds of your stamina is the stuff of legends. You now restore +1 fatigue per second (this stacks with prior 'recovery' perks)",
        skillReq = {athletics = 30},
        perkReq = {"hat_recoverhero"},
        spells = {tes3.getObject("hat_perk_recovery2")},
        lvlReq = 10
    })

    perks.recoverDaedra = perkFramework.createPerk({
        id = "hat_recoverdaedra",
        name = "Daedric Recovery",
        description = "Your stamina rivals the Daedra. You now restore another +1 fatigue per second (this stacks with prior 'recovery' perks)",
        skillReq = {athletics = 60},
        perkReq = {"hat_recoverlegend"},
        spells = {tes3.getObject("hat_perk_recovery3")},
        lvlReq = 20
    })

    perks.magicMaster = perkFramework.createPerk({
        id = "hat_magicmaster",
        name = "Magic Master",
        lvlReq = 20,
        customReq = {
            function ()
                if (tes3mobilePlayer.conjuration >= 100) or (tes3mobilePlayer.destruction >= 100) or (tes3mobilePlayer.alteration >= 100) or (tes3mobilePlayer.mysticism >= 100) or (tes3mobilePlayer.restoration >= 100) or (tes3mobilePlayer.illusion >= 100) then
                    return true
                end
            end
        },
        spells = {tes3.getObject("hat_perk_magmast")}
    })
    --i think i can clean these up by using "customReq"
--    perks.magicMaster1 = perkFramework.createPerk({
--        id = "hat_magicmaster1",
--        name = "Magicka Master",
--        skillReq = {alteration = 100},
--        lvlReq = 20,
--        perkExclude = {"hat_magicmaster2", "hat_magicmaster3", "hat_magicmaster4", "hat_magicmaster5", "hat_magicmaster6"},
--        customReq = {
--            function () if tes3.hasSpell({
--                reference = "player",
--                spell = "hat_perk_magmast"
--            }) == true then
--                return false
--            else
--                return true
--            end
--        end
--        },
--        spells = {tes3.getObject("hat_perk_magmast")}
--    })
--    
--    perks.magicMaster2 = perkFramework.createPerk({
--        id = "hat_magicmaster2",
--        name = "Magicka Master",
--        skillReq = {conjuration = 100},
--        lvlReq = 20,
--        perkExclude = {"hat_magicmaster1", "hat_magicmaster3", "hat_magicmaster4", "hat_magicmaster5", "hat_magicmaster6"},
--        spells = {tes3.getObject("hat_perk_magmast")}
--    })
--
--    perks.magicMaster3 = perkFramework.createPerk({
--        id = "hat_magicmaster3",
--        name = "Magicka Master",
--        skillReq = {destruction = 100},
--        lvlReq = 20,
--        perkExclude = {"hat_magicmaster2", "hat_magicmaster1", "hat_magicmaster4", "hat_magicmaster5", "hat_magicmaster6"},
--        spells = {tes3.getObject("hat_perk_magmast")}
--    })
--
--    perks.magicMaster4 = perkFramework.createPerk({
--        id = "hat_magicmaster4",
--        name = "Magicka Master",
--        skillReq = {illusion = 100},
--        lvlReq = 20,
--        perkExclude = {"hat_magicmaster2", "hat_magicmaster3", "hat_magicmaster1", "hat_magicmaster5", "hat_magicmaster6"},
--        spells = {tes3.getObject("hat_perk_magmast")}
--    })
--
--    perks.magicMaster5 = perkFramework.createPerk({
--        id = "hat_magicmaster5",
--        name = "Magicka Master",
--        skillReq = {mysticism = 100},
--        lvlReq = 20,
--        perkExclude = {"hat_magicmaster2", "hat_magicmaster3", "hat_magicmaster4", "hat_magicmaster1", "hat_magicmaster6"},
--        spells = {tes3.getObject("hat_perk_magmast")}
--    })
--
--    perks.magicMaster6 = perkFramework.createPerk({
--        id = "hat_magicmaster6",
--        name = "Magicka Master",
--        skillReq = {restoration = 100},
--        lvlReq = 20,
--        perkExclude = {"hat_magicmaster2", "hat_magicmaster3", "hat_magicmaster4", "hat_magicmaster5", "hat_magicmaster1"},
--        spells = {tes3.getObject("hat_perk_magmast")}
--    })
--
--    perks.vampHide = perkFramework.createPerk({
--        id = "hat_vamp_hide",
--        name = "Hidden Hunter",
--        description = "The only thing deadly than a vampire is one capable of blending in with mortals. Unfortunately for your prey, you have the skills and attributes needed.",
--        skillReq = {illusion = 60},
--        attributeReq = {personality = 70, willpower = 70},
--        vampireReq = true,
--        spells = {tes3.getObject("hat_vamp_hide")}
--    })
--wanna make the following more like "friend of the night" from fallout new vegas, but currently in testing, so crouch check pending
    perks.nighteye = perkFramework.createPerk({
        id = "hat_nighteye",
        name = "Nighteye",
        description = "Your skill in stealth and illusion has grown into a natural darkvision while hiding",
        lvlReq = 10,
        skillReq = {sneak = 50, illusion = 50},
        spells = {tes3.getObject("hat_perk_nighteye")},
        delayActivation = true
    })

--traits section

    perks.healer = perkFramework.createPerk({
        id = "hat_trait_healer",
        name = "Healer",
        description = "You've always prefered helping over hurting",
        isUnique = true
    })

end
event.register(tes3.event.loaded, createPerk)

--do not enable these, traits are not in a remotely functional state

--local function traitHealer()
--    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 16,
--        current = 10,
--        limit = true
--    })
--    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 15,
--        current = 10,
--        limit = true
--    })
--    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 4,
--        current = -10,
--        limit = true
--    })
--    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 5,
--        current = -10,
--        limit = true
--    })
--    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 6,
--        current = -10,
--        limit = true
--    })
--    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 7,
--        current = 10,
--        limit = true
--    })    tes3.modStatistic({
--        reference = tes3mobilePlayer,
--        skill = 22,
--        current = -10,
--        limit = true
--    })
--end
--event.register(KBPerks:perkActivated("hat_trait_healer"), traitHealer)

--local function perkMenu(e)
--	tes3.messageBox({ message = "key detection works" })
--    perkFramework.showPerkMenu{
--        perkPoints = 1
--    }
--end
--event.register(tes3.event.keyDown, perkMenu, { filter = tes3.scanCode.l } )
--
--local function debugPerk()
--    tes3.messageBox({ message = "debug perk granted"})
--    player.grantPerk("hat_debug")
--end
--event.register(tes3.event.keyDown, debugPerk, { filter = tes3.scanCode.p })

--Perks can be registered with the createPerk{} function. createPerk accepts a table parameter and accepts the following possible values:
--    id (string)- (required), this should be a unique string, similar to an Editor ID. Since perk data is indexed by ID, this MUST be completely unique
--    name (string)- (required) the Player-Facing name of the perk
--    description(string) -(required) A short player-facing description of the perk's effects.
--    isUnique(boolean) - if set to true, this perk will not be included in the Default Perk list (see Opening the Perk Menu) Use this if you only want the perk to be awarded from a specific source, and not to be able to be acquired from KCP or any other hypothetical mods that use this framework
--    lvlReq (number)- the Required Character level that must be reached for the player to be able to select the perk. Defaults to 0 if not specified
--    attributeReq (table)- this must be a table of attribute requirements, indexed by attribute name. this does not support OR behavior, only AND behavior ex.) {strength = 50, endurance = 60}
--    skillReq (table) - similar to attributeReq, but for required skills. ex.) {illusion = 50, shortBlade = 70, handToHand = 35}
--    werewolfReq (boolean) - if set to true, only werewolf players can take the perk
--    vampireReq (boolean) - if set to true, only vampire players can take the perk
--    perkReq (table) - an array-style table of perkIDs, representing the perks must be previously acquired to take this one. ex.) {"some PerkID", "some other perkID"}
--    customReq (function) - If a function is passed here, it will be ran whenever the framework checks the requirements for a perk. If it does not return true, the perk will not be available for the player to acquire. ex.) ﻿customReq = function() if tes3.player.object.name == "fargoth" then return true else return false end end
--    --fargoth only perk lol
--    customReqText (string) - Unique text to display in the requirements section, intended to be used with customReq, but can be used on it's own
--    perkExclude (table) - this can be a table of perk IDs that player must NOT have in order to acquire the perk. This can be used to make perks that are mutually exclusive with each other
--    hideInMenu (boolean) - if set to true, the perk will only be visible in the perk selection menu if the requirements to select it are met.
--    delayActivation (boolean) - if set to true, the perk will not be immediately activated, meaning that it will not send an activation event and will not add any spells to the player. The perk can be activated later using the activatePerk() function
--    spells (table) - a table of tes3spell objects to be added to the player upon the perks activation
--    createPerk returns the table that stores the data of the perk
