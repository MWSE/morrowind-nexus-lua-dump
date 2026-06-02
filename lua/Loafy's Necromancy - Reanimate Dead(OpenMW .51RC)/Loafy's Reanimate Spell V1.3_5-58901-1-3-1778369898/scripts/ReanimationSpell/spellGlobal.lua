local types = require('openmw.types')
local world = require('openmw.world')
local core  = require('openmw.core')
local I = require('openmw.interfaces')

--settings
local requireMasterySetting = nil
local requireCrimeSetting = nil
local requireExpulsion = nil
local requireMasteryUiBox = nil
local requireCastingUiBox = nil

local clearZombie

local activeZombies = {}
local createdZombieRecords = {}


local player = world.players[1]
local corpseActor 
local summoner
local reanimateSpell
local reanimateSpellId
local zombieSlot
local oldZombie
local newZombie
local ashpileRecord = types.Container.records["reanimatedead_ashpile"]

local function modifyInventory(corpseActor,zombieActor)

    local corpseInv = types.Actor.inventory(corpseActor)
    local newInv = types.Actor.inventory(zombieActor)
    
    for _, item in ipairs(newInv:getAll()) do
        item:remove()
    end

    for _, item in ipairs(corpseInv:getAll()) do
        item:moveInto(newInv)
    end
end

local function doCrimes(data)
     --Necromancy is illegal in morrowind, do crimes if seen
     
        if requireCrimeSetting then
            
                I.Crimes.commitCrime(data.summoner, {victim = data.actor, type = 2, victimAware = false})
            if requireExpulsion then
                local antiNecroFactions = {
                "mages guild",
                "temple",
                "redoran",
                "imperial cult",
                "imperial legion",
                "hlaalu",
                "morag tong",
            }
                for _, factionId in ipairs(antiNecroFactions) do
                
                    local rank = types.NPC.getFactionRank(data.summoner, factionId)
                
                        if rank > 0 and not types.NPC.isExpelled(player, factionId) then
                            types.NPC.expel(player, factionId, true)
                        
                        summoner:sendEvent('ShowMessage', { message =  "You have been expelled from the " .. factionId .. " for your dark practices."}) 
                    
                        end
                end
            end
        end
end

local function getSpell(spellId)
    if player then
        local activeSpells           =  types.Actor.activeSpells(player)
        local spellId                =  spellId
        for _, spell in pairs(activeSpells) do
           if spell.id == spellId then
                return spell
           end
        end
    end  
end

local function clearZombieRemains(remains)
    remains:removeScript("scripts/ReanimationSpell/spellAshpile.lua")
    remains:remove()
end

local function createZombieRemains(zombieObject)
   

    local zombieInvCapacity
    if zombieObject then
        zombieInvCapacity = types.Actor.getCapacity(zombieObject)
    end

    if not ashpileRecord then
        local draft = types.Container.createRecordDraft({
            id = "reanimatedead_ashpile",
            name = "Degraded Remains",
            capacity = zombieInvCapacity, 
            model = "meshes/ReanimationSpell/z_remains.nif"
        })
        ashpileRecord = world.createRecord(draft)
    end

    local newAshpile = world.createObject(ashpileRecord.id)
    
    newAshpile:teleport(zombieObject.cell, zombieObject.position, zombieObject.rotation)

    local zombieInv = types.Actor.inventory(zombieObject)
    local containerInv = types.Container.inventory(newAshpile)
    
    for _, item in ipairs(zombieInv:getAll()) do
        item:moveInto(containerInv)
    end
    newAshpile:addScript("scripts/ReanimationSpell/spellAshpile.lua", {player = player})
end

local function checkReanimateSpell()
    if not player then return end

    local activeSpells = types.Actor.activeSpells(player)
   
    if activeZombies then
    for slotId, zombie in pairs(activeZombies) do
        if zombie:isValid() then
            local spellId = slotId:match("^[^_]+_(.+)$")
            
            local hasSpell = activeSpells:isSpellActive(spellId)

            if not hasSpell then
                zombie:sendEvent("killZombie")
            end
        else
            activeZombies[slotId] = nil
        end
    end
end
end

local function getZombieHead(race,gender)
    local raceData = {
        ["dark elf"] = {
            male = "b_v_dark elf_m_head_01",
            female = "b_v_dark elf_f_head_01"
        },
        ["nord"] = {
            male = "b_v_nord_m_head_01",
            female = "b_v_nord_f_head_01"
        },
        ["khajiit"] = {
            male = "b_v_khajiit_m_head_01",
            female = "b_v_khajiit_f_head_01"
        },
        ["orc"] = {
            male = "b_v_orc_m_head_01",
            female = "b_v_orc_f_head_01"
        },
        ["redguard"] = {
            male = "b_v_redguard_m_head_01",
            female = "b_v_redguard_f_head_01"
        },
        ["wood elf"] = {
            male = "b_v_wood elf_m_head_01",
            female = "b_v_wood elf_f_head_01"
        },
        ["high elf"] = {
            male = "b_v_high elf_m_head_01",
            female = "b_v_high elf_f_head_01"
        },
        ["breton"] = {
            male = "b_v_breton_m_head_01",
            female = "b_v_breton_f_head_01"
        },
        ["argonian"] = {
            male = "b_v_argonian_m_head_01",
            female = "b_v_argonian_f_head_01"
        },
        ["imperial"] = {
            male = "b_v_imperial_m_head_01",
            female = "b_v_imperial_f_head_01"
        },
    }

  -- 1. Use lowercase for everything to ensure the lookup never fails
    local raceKey = race:lower()
    local genderKey = gender and "male" or "female"
    
    -- 2. Check if the race exists in your table
    local raceEntry = raceData[raceKey]
    if raceEntry then
    local headId = raceEntry[genderKey]                
            return headId
    end

    return nil
end

local function createNewZombie()

    --create new record and Spawn the new zombie
        local originalRecord
        local zombieRecord
        local existingRecordName
        local existingZombieRecord = nil
        local baseId = corpseActor.recordId

    for key, storedZombieId in pairs(createdZombieRecords) do
        if storedZombieId == baseId then
            existingZombieRecord = baseId
        end
    end
    if not existingZombieRecord then
        if string.sub(baseId, 1, 2) == "z_" then
            baseId = string.sub(baseId, 3)
        end
        existingRecordName = string.lower("z_" .. baseId)
    end

    if existingZombieRecord then
       newZombie = world.createObject(existingZombieRecord)
    else
        if createdZombieRecords[existingRecordName] then
            print("System: Blueprint verified in save data. Spawning -> " .. createdZombieRecords[existingRecordName])
            
            if types.Creature.objectIsInstance(corpseActor) then
                newZombie = world.createObject(createdZombieRecords[existingRecordName])
            elseif types.NPC.objectIsInstance(corpseActor)  then
                newZombie = world.createObject(createdZombieRecords[existingRecordName])
            end
        else
            if types.Creature.objectIsInstance(corpseActor) then
                originalRecord    = types.Creature.record(corpseActor.recordId)
                    print("Creating new zombie creature record:"..existingRecordName)
                    zombieRecord      = world.createRecord (
                        types.Creature.createRecordDraft({
                            template =  types.Creature.record("z_creature_template"),
                            id       = existingRecordName,
                            ai       = nil,
                            mwscript = "",
                            isRespawning = false,
                            isEssential = false,
                            attack = originalRecord.attack,
                            canSwim = originalRecord.canSwim,
                            canFly  = originalRecord.canFly,
                            canUseWeapons = originalRecord.canUseWeapons,
                            canWalk = originalRecord.canWalk,
                            combatSkill = originalRecord.combatSkill,
                            isBiped = originalRecord.isBiped,
                            magicSkill = originalRecord.magicSkill,
                            model = originalRecord.model,
                            stealthSkill = originalRecord.stealthSkill,
                            type = originalRecord.type,
                            bloodType = originalRecord.bloodType,
                            baseCreature = originalRecord.baseCreature,
                            name     = types.NPC.record(summoner.recordId).name .. "'s" .. " Zombie " .. originalRecord.name
                        })
                    )  
            elseif types.NPC.objectIsInstance(corpseActor)  then
                originalRecord    = types.NPC.record(corpseActor.recordId)
                local classReplacement
                local guardClasses = {
                    ["guard"] = true,
                    ["ordinator"] = true,
                    ["high ordinator"] = true,
                    ["royal guard"] = true,
                    ["tr_guard"] = true,
                    ["ordinator guard"] = true
                    }
                if guardClasses[originalRecord.class] then
                    classReplacement = "Warrior" 
                end
                print("Creating new zombie NPC record:"..existingRecordName)
                    zombieRecord      = world.createRecord (
                        types.NPC.createRecordDraft({
                            template = types.NPC.record("z_npc_template"),
                            ai       = nil,
                            isRespawning = false,
                            isEssential = false,
                            mwscript = "",
                            head     =  getZombieHead(string.lower(originalRecord.race), originalRecord.isMale) or originalRecord.head,
                            hair    = originalRecord.hair,
                            id       =  existingRecordName,
                            race = originalRecord.race,
                            model = originalRecord.model,
                            isMale = originalRecord.isMale,
                            class = classReplacement,
                            bloodType = originalRecord.bloodType,
                            level = originalRecord.level,
                            name     = types.NPC.record(summoner.recordId).name .. "'s" .. " Zombie " .. originalRecord.name
                        })
                    ) 
            end
            createdZombieRecords[existingRecordName] = zombieRecord.id
            newZombie = world.createObject(zombieRecord.id)
           
        end
    end
       
        modifyInventory(corpseActor,newZombie)


       

         --check for the necromancy mastery setting
            if requireMasterySetting == nil then requireMasterySetting = true end -- it'll return nil at first so we'll add a sanity check

            local mastery

            if requireMasterySetting == true then 
                -- if the setting is enabled, function as intended
                mastery = types.NPC.stats.skills.conjuration(summoner).base >= 100 
            else
                -- if not, let the player have their fun
                mastery = true
            end
             
            -------
            -- fuck my life
            local zombieStats = {
                level     = types.Actor.stats.level(corpseActor).current,
                health    = types.Actor.stats.dynamic.health(corpseActor).base,
                magicka   = types.Actor.stats.dynamic.magicka(corpseActor).base,
                fatigue   = types.Actor.stats.dynamic.fatigue(corpseActor).base,
                strength  = types.Actor.stats.attributes.strength(corpseActor).base,
                intelligence = types.Actor.stats.attributes.intelligence(corpseActor).base,
                willpower = types.Actor.stats.attributes.willpower(corpseActor).base,
                agility   = types.Actor.stats.attributes.agility(corpseActor).base,
                speed     = types.Actor.stats.attributes.speed(corpseActor).base,
                endurance = types.Actor.stats.attributes.endurance(corpseActor).base,
                personality = types.Actor.stats.attributes.personality(corpseActor).base,
                luck        = types.Actor.stats.attributes.luck(corpseActor).base
            }
          
            if types.NPC.objectIsInstance(corpseActor) then

                zombieStats.acrobatics   = types.NPC.stats.skills.acrobatics(corpseActor).base
                zombieStats.alchemy = types.NPC.stats.skills.alchemy(corpseActor).base
                zombieStats.alteration  = types.NPC.stats.skills.alteration(corpseActor).base
                zombieStats.armorer = types.NPC.stats.skills.armorer(corpseActor).base
                zombieStats.athletics = types.NPC.stats.skills.athletics(corpseActor).base
                zombieStats.axe = types.NPC.stats.skills.axe(corpseActor).base
                zombieStats.bluntweapon = types.NPC.stats.skills.bluntweapon(corpseActor).base
                zombieStats.block = types.NPC.stats.skills.block(corpseActor).base
                zombieStats.conjuration = types.NPC.stats.skills.conjuration(corpseActor).base
                zombieStats.destruction = types.NPC.stats.skills.destruction(corpseActor).base
                zombieStats.enchant = types.NPC.stats.skills.enchant(corpseActor).base
                zombieStats.handtohand = types.NPC.stats.skills.handtohand(corpseActor).base
                zombieStats.illusion = types.NPC.stats.skills.illusion(corpseActor).base
                zombieStats.lightarmor = types.NPC.stats.skills.lightarmor(corpseActor).base
                zombieStats.longblade = types.NPC.stats.skills.longblade(corpseActor).base
                zombieStats.marksman = types.NPC.stats.skills.marksman(corpseActor).base
                zombieStats.mediumarmor = types.NPC.stats.skills.mediumarmor(corpseActor).base
                zombieStats.mercantile = types.NPC.stats.skills.mercantile(corpseActor).base
                zombieStats.mysticism = types.NPC.stats.skills.mysticism(corpseActor).base
                zombieStats.restoration = types.NPC.stats.skills.restoration(corpseActor).base
                zombieStats.security = types.NPC.stats.skills.security(corpseActor).base
                zombieStats.shortblade = types.NPC.stats.skills.shortblade(corpseActor).base
                zombieStats.sneak = types.NPC.stats.skills.sneak(corpseActor).base
                zombieStats.spear = types.NPC.stats.skills.spear(corpseActor).base
                zombieStats.unarmored = types.NPC.stats.skills.unarmored(corpseActor).base
                zombieStats.spellList = {}
                for _, spell in ipairs(types.Actor.spells(corpseActor)) do
                    table.insert(zombieStats.spellList, spell.id)
                end
            end
          
            -------


        newZombie:addScript("scripts/ReanimationSpell/spellZombie.lua",{
            reanimateSpellId = reanimateSpellId,
            summoner = summoner,
            mastery = mastery,
            requireMasterySetting = requireMasterySetting,
            zombieStats = zombieStats
           
        })
        
         newZombie:teleport(corpseActor.cell, corpseActor.position, corpseActor.rotation)
        corpseActor:remove()

        if activeZombies then
            activeZombies[zombieSlot] = newZombie
        end
end

local function createZombie(data)
            corpseActor = data.corpseActor
            if corpseActor then
                if types.Actor.isDead(corpseActor) then
                summoner      = player
                reanimateSpell = getSpell(data.spellId)
                reanimateSpellId = reanimateSpell.id
                
                --Assign a key for every zombie spell we have
                zombieSlot = summoner.id .."_".. reanimateSpell.id
                if data.magnitude >= types.Actor.stats.level(corpseActor).current then
                     core.sendGlobalEvent("createNewZombie")
                    if types.NPC.objectIsInstance(corpseActor) then
                        
                        if requireCastingUiBox then summoner:sendEvent('ShowMessage', { message = "Raising ".. types.NPC.record(corpseActor).name .. " from the dead."}) end  
                    elseif types.Creature.objectIsInstance(corpseActor) then
                        if requireCastingUiBox then summoner:sendEvent('ShowMessage', { message = "Raising ".. types.Creature.record(corpseActor).name .. " from the dead."}) end  
                    end
                else
                     if requireCastingUiBox then summoner:sendEvent('ShowMessage', { message = "Corpse is too powerful for this spell."}) end
                end

               
                --createNewZombie()
                -- Check for old zombies
                if activeZombies then
                    oldZombie  = activeZombies[zombieSlot]
                    if activeZombies[zombieSlot] and activeZombies[zombieSlot]:isValid() then
                        if requireCastingUiBox then summoner:sendEvent('ShowMessage', { message = "Zombie already active for this spell, the old one will be destroyed." }) end
                        oldZombie:sendEvent('killZombie')
                    end
            end
            
        end
    end
end

clearZombie = function(data)
    player = world.players[1]
    local zombieSlot = data.summonerId .."_".. data.spellId
    if activeZombies[zombieSlot] and activeZombies[zombieSlot].id == data.zombieObj.id then
        activeZombies[zombieSlot]:removeScript("scripts/ReanimationSpell/spellZombie.lua")
        activeZombies[zombieSlot] = nil
        
        local spell = getSpell(data.spellId)
        if spell then
            types.Actor.activeSpells(player):remove(spell.activeSpellId) 
        end
    end
    -- spawn an ashpile container in the place of the zombie when it dies, and move it's inventory
    if not data.isThrall then
            if data.zombieObj then
                createZombieRemains(data.zombieObj)
            end
             data.zombieObj:remove() 
    else
        if summoner and requireMasteryUiBox then
            if types.NPC.objectIsInstance(data.zombieObj) then
                summoner:sendEvent('ShowMessage', { message = "Conjuration mastery: " .. types.NPC.record(data.zombieObj).name .. " was spared from destruction."})  
            elseif types.Creature.objectIsInstance(data.zombieObj) then
                summoner:sendEvent('ShowMessage', { message = "Conjuration mastery: " .. types.Creature.record(data.zombieObj).name .. " was spared from destruction."}) 
            end
        end
    end
end
-- engine and event handlers
local function onUpdate(dt)
  checkReanimateSpell()

end

local function loadZombie(data)
    if data.summoner.id and data.reanimateSpellId and  data.zombieObj then
        local zombieSlot = data.summoner.id .."_".. data.reanimateSpellId
        activeZombies[zombieSlot] = data.zombieObj
    end
end

local function getPlayerSettings(data)
    requireMasterySetting = data.requireMasterySetting
    requireCrimeSetting = data.requireCrimeSetting
    requireCastingUiBox = data.requireCastingUiBox
    requireExpulsion = data.requireExpulsion
    requireMasteryUiBox = data.requireMasteryUiBox

end

local function onSave()
    return {
    activeZombies = activeZombies,
    zombieRecords = createdZombieRecords,

    }
end

local function onLoad(data)
    if data then
        if data.zombieRecords then
            createdZombieRecords = data.zombieRecords
            --activeZombies        = data.activeZombies

        end
    end
end

local function zombieActivationHandler(object, actor)
    for _, zombie in pairs(activeZombies) do
        if object == zombie then
            if types.Actor.isDead(object) then
                return true
            end

            actor:sendEvent('openZombieManagement', { zombie = object })
            return false 
        end
    end
end

I.Activation.addHandlerForType(types.NPC, zombieActivationHandler)
I.Activation.addHandlerForType(types.Creature, zombieActivationHandler)

local function onActorActive(actor)
    local spells
    if actor.recordId == "felen maryon" then
        spells = types.Actor.spells(actor)
                spells:add('deadthrall')
    end
    if actor.recordId == "sharn gra-muzgob" then
      spells = types.Actor.spells(actor)
                spells:add('raisezombie')
              
                spells:add('reanimatecorpse')
    end
    if actor.recordId == "heem_la" then
          spells = types.Actor.spells(actor)
                spells:add('revenant')
                spells:add('dreadzombie')
    end
end

return{
    eventHandlers = {
        createNewZombie = createNewZombie,
        createZombie    = createZombie,
        clearZombie     = clearZombie,
        clearZombieRemains = clearZombieRemains,
        loadZombie = loadZombie,
        getPlayerSettings = getPlayerSettings,
        doCrimes = doCrimes
    }
    ,
     engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onActorActive = onActorActive
     }
}