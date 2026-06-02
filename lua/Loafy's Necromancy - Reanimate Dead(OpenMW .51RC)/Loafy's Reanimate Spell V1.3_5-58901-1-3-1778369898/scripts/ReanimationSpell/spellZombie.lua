local types     = require('openmw.types')
local self      = require('openmw.self')
local core      = require('openmw.core')
local anim      = require('openmw.animation')
local util      = require('openmw.util')

--Settings bullshit
local requireMasterySetting

--Initialize variables for the zombie functions to use
local reanimateSpellId  = nil
local summoner          = nil
local isDead            = false
local isThrall          = false
local zombieStats       = {}
local vfxTimer = 0
local sfxTimer = 0

--initialize functions
local zombieInitialized
local equipInventory
local playSummonVfx
local playDeathVfx
local playAliveVfx
local playFliesSfx

local function setZombieStats()
    --Fucking kill me
    types.Actor.stats.level(self).current = zombieStats.level
    types.Actor.stats.dynamic.health(self).base = math.floor((zombieStats.strength + zombieStats.endurance) / 2 + ((zombieStats.level - 1) * (zombieStats.endurance / 10)))
    types.Actor.stats.dynamic.health(self).current = math.floor((zombieStats.strength + zombieStats.endurance) / 2 + ((zombieStats.level - 1) * (zombieStats.endurance / 10)))
    types.Actor.stats.dynamic.magicka(self).base = zombieStats.magicka
    types.Actor.stats.dynamic.magicka(self).current = zombieStats.magicka
    types.Actor.stats.dynamic.fatigue(self).base = zombieStats.fatigue
    types.Actor.stats.dynamic.fatigue(self).current = zombieStats.fatigue

    types.Actor.stats.attributes.strength(self).base = zombieStats.strength
    types.Actor.stats.attributes.agility(self).base = zombieStats.agility
    types.Actor.stats.attributes.speed(self).base = zombieStats.speed
    types.Actor.stats.attributes.intelligence(self).base = zombieStats.intelligence
    types.Actor.stats.attributes.luck(self).base = zombieStats.luck
    types.Actor.stats.attributes.endurance(self).base = zombieStats.endurance
    types.Actor.stats.attributes.personality(self).base = zombieStats.personality
    types.Actor.stats.attributes.willpower(self).base = zombieStats.willpower

    if types.NPC.objectIsInstance(self) then
        types.NPC.stats.skills.acrobatics(self).base = zombieStats.acrobatics
        types.NPC.stats.skills.alchemy(self).base = zombieStats.alchemy
        types.NPC.stats.skills.alteration(self).base = zombieStats.alteration
        types.NPC.stats.skills.armorer(self).base = zombieStats.armorer
        types.NPC.stats.skills.athletics(self).base = zombieStats.athletics
        types.NPC.stats.skills.axe(self).base = zombieStats.axe
        types.NPC.stats.skills.bluntweapon(self).base = zombieStats.bluntweapon
        types.NPC.stats.skills.block(self).base = zombieStats.block
        types.NPC.stats.skills.conjuration(self).base = zombieStats.conjuration
        types.NPC.stats.skills.destruction(self).base = zombieStats.destruction
        types.NPC.stats.skills.enchant(self).base = zombieStats.enchant
        types.NPC.stats.skills.handtohand(self).base = zombieStats.handtohand
        types.NPC.stats.skills.illusion(self).base = zombieStats.illusion
        types.NPC.stats.skills.lightarmor(self).base = zombieStats.lightarmor
        types.NPC.stats.skills.longblade(self).base = zombieStats.longblade
        types.NPC.stats.skills.marksman(self).base = zombieStats.marksman
        types.NPC.stats.skills.mediumarmor(self).base = zombieStats.mediumarmor
        types.NPC.stats.skills.mercantile(self).base = zombieStats.mercantile
        types.NPC.stats.skills.mysticism(self).base = zombieStats.mysticism
        types.NPC.stats.skills.restoration(self).base = zombieStats.restoration
        types.NPC.stats.skills.security(self).base = zombieStats.security
        types.NPC.stats.skills.shortblade(self).base = zombieStats.shortblade
        types.NPC.stats.skills.sneak(self).base = zombieStats.sneak
        types.NPC.stats.skills.spear(self).base = zombieStats.spear
        types.NPC.stats.skills.unarmored(self).base = zombieStats.unarmored

        for _, spell in ipairs(zombieStats.spellList) do
            types.Actor.spells(self):add(spell)
           -- print("Adding spell to zombie: "..spell)
        end
    end

end

local function onInit(data)
    reanimateSpellId = data.reanimateSpellId
    summoner         = data.summoner
    isThrall         = data.mastery
    zombieStats      = data.zombieStats
    setZombieStats()
    requireMasterySetting = data.requireMasterySetting

    --equipInventory()

    self:sendEvent("equipInventory")

    if summoner then
      self:sendEvent('RemoveAIPackages')
      self:sendEvent('StartAIPackage', {
        type = 'Follow',
		target = summoner,
        ai = nil,
		cancelOther = true,
		sideWithTarget = true,
		isRepeat = true
      })
    end
    self:sendEvent("playSummonVfx")
end

playFliesSfx = function(dt)
    core.sound.playSound3d("flies", self, {
    loop = false,
    volume = 1,
    pitch = 0.6, 
    lazy = true   
     })

end

playSummonVfx = function()

    local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Sanctuary]
        local pos = self.position + util.vector3(0, 0, 0)
        local model = types.Static.records[effect.castStatic].model
          core.sendGlobalEvent('SpawnVfx', {
            model = model, 
            position = pos, 

            options = {
                 useAmbientLight = true, 
                 vfxId = "summoneffect",
                 scale = 1,
                 mwMagicVfx = false,
                 particleTextureOverride = "ReanimationSpell/vfx_z_sum2.dds"
                }})  
end

playAliveVfx = function()
    local record = types.Static.record("reanimate_active2_vfx")

    anim.addVfx(self,record.model, {
        useAmbientLight = true,
        bonename = "Bip01 Head",
        vfxId = "summoneffect",
        --particleTextureOverride = "ReanimationSpell/vfx_z_sum_cast.dds",
        loop = false
    })


     record = types.Static.record("reanimate_active_vfx")

            anim.addVfx(self,record.model, {
                useAmbientLight = false,
                bonename = "Bip01 Head",
                vfxId = "summoneffect2",
                scale = 1,
                loop = false
            })
    
    
end
playDeathVfx = function()
    core.sound.stopSound3d("flies",self)
    core.sound.playSound3d("conjuration cast", self, {
    loop = false,
    volume = 1,
    pitch = 0.6, 
    lazy = true   
     })
    
    local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Chameleon]
    local pos = self.position + util.vector3(0, 0, 20)
    local model = types.Static.records[effect.castStatic].model
          core.sendGlobalEvent('SpawnVfx', {
            model = model, 
            position = pos, 

            options = {
                useAmbientLight = true, 
                vfxId = "summoneffect",
                scale = 1,
                mwMagicVfx = false,
                particleTextureOverride = "ReanimationSpell/vfx_z_sum.dds"
            }})  
end

equipInventory = function()
    for _, item in ipairs( types.Actor.inventory(self):getAll()) do
        if item.type == types.Weapon or item.type == types.Armor or item.type == types.Clothing then
            -- Send the global event to force the actor to equip/evaluate the item
            core.sendGlobalEvent('UseItem', {
                object = item, 
                actor = self, 
                force = true 
            })
        end
    end
end

local function killZombie()
    --put a check in just to make  sure we're not deleting the spell effect
    if not isDead then
        types.Actor.stats.dynamic.health(self).current = 0
        --self:sendEvent("playDeathVfx")
        isDead = true
    end

end

local function onUpdate(dt)
    if  types.Actor.stats.dynamic.health(self).current > 0 then
        -- Check for players conjuration mastery to make sure they're not just setting it above 100 for a split cast unless we have the setting checked
        local mastery 
        if requireMasterySetting then
            mastery = types.NPC.stats.skills.conjuration(summoner).base >= 100
        else
            mastery = true
        end

        if not mastery then isThrall = false end

        local vfxInterval = 1.5
        local sfxInterval = 6.0

        vfxTimer = vfxTimer + dt
        if vfxTimer >= vfxInterval then
            vfxTimer = 0
            playAliveVfx()
        end
        
        sfxTimer = sfxTimer + dt
        if sfxTimer >= sfxInterval then
            sfxTimer = 0
            playFliesSfx()
        end

    end

end

local function died()
     if types.Actor.isDeathFinished(self) then playDeathVfx() end
     if summoner and reanimateSpellId then
        core.sendGlobalEvent("clearZombie", {
            spellId = reanimateSpellId,
            summonerId = summoner.id,
            zombieObj = self,
            isThrall = isThrall
         })
        reanimateSpellId = nil
    end
end

local function onSave()
    return 
    {
        summoner         = summoner,
        reanimateSpellId = reanimateSpellId,
        isThrall         = isThrall
    }
end

local function onLoad(data)
    if data then
        summoner = data.summoner
        reanimateSpellId = data.reanimateSpellId
        isThrall         = data.isThrall
        core.sendGlobalEvent("loadZombie",{
            summoner         = summoner,
            reanimateSpellId = reanimateSpellId,
            zombieObj        = self
        })
        print("Zombie: "..types.NPC.record(self).name.." Back from the save grave.")
    end
end


return {
    eventHandlers = {
    killZombie           = killZombie,
    equipInventory       = equipInventory,
    playSummonVfx        = playSummonVfx,
    playDeathVfx         = playDeathVfx,
    playAliveVfx         = playAliveVfx,
    Died                 = died
    },
    
    engineHandlers = {
    onInit = onInit,
    onUpdate = onUpdate,
    onSave = onSave,
    onLoad = onLoad
   }
}