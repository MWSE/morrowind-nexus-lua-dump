local core   = require('openmw.core')
local types  = require('openmw.types')
local world  = require('openmw.world')
local I      = require('openmw.interfaces')

local shared = require('scripts.bastard_shared')
local GOLD_IDS = shared.GOLD_IDS

local LOCAL_SCRIPT = 'scripts/bastard_npc.lua'

-- ======================================================================================================
-- pickup sound resolution

local function pickupSoundFor(item)
    if not item or not item:isValid() then return 'Item Misc Up' end
    local id = (item.recordId or ''):lower()
    if GOLD_IDS[id]                              then return 'Item Gold Up' end
    if types.Weapon.objectIsInstance(item) then
        local rec = types.Weapon.record(item)
        local t = rec and rec.type
        if t == types.Weapon.TYPE.MarksmanBow
           or t == types.Weapon.TYPE.MarksmanCrossbow
           or t == types.Weapon.TYPE.Arrow
           or t == types.Weapon.TYPE.Bolt
           or t == types.Weapon.TYPE.MarksmanThrown then
            return 'Item Ammo Up'
        end
        return 'Item Weapon Shortblade Up'
    end
    if types.Book.objectIsInstance(item)         then return 'Item Book Up' end
    if types.Apparatus.objectIsInstance(item)    then return 'Item Apparatus Up' end
    if types.Clothing.objectIsInstance(item)     then return 'Item Clothes Up' end
    if types.Armor.objectIsInstance(item)        then return 'Item Armor Medium Up' end
    if types.Ingredient.objectIsInstance(item)   then return 'Item Ingredient Up' end
    if types.Potion.objectIsInstance(item)       then return 'Item Potion Up' end
    if types.Lockpick.objectIsInstance(item)     then return 'Item Lockpick Up' end
    if types.Probe.objectIsInstance(item)        then return 'Item Probe Up' end
    if types.Repair.objectIsInstance(item)       then return 'Item Repair Up' end
    return 'Item Misc Up'
end

local logEnabled = shared.DEFAULTS.LOG

local function log(...)
    if logEnabled then
        print('[Bastard][global]', ...)
    end
end

local function Bastard_SetLog(value)
    logEnabled = value and true or false
end

local function ensureLocalScript(npc)
    if npc and npc:isValid() and not npc:hasScript(LOCAL_SCRIPT) then
        npc:addScript(LOCAL_SCRIPT)
    end
end

-- ======================================================================================================
-- crime reporting
-- type: 'theft' | 'assault'
-- arg: bounty add (theft only)
-- victim: NPC
-- faction: optional faction id (string), one extra call against the faction

local function commitCrime(player, kind, victim, arg, faction, victimAware)
    if not player or not player:isValid() then return end
    local OFFENSE = types.Player.OFFENSE_TYPE
    if not OFFENSE then
        log('Crimes API offense table missing; aborting commitCrime')
        return
    end

    local typeId
    if kind == 'theft' then
        typeId = OFFENSE.Theft
    elseif kind == 'assault' then
        typeId = OFFENSE.Assault
    else
        log('commitCrime unknown kind:', kind)
        return
    end

    local inputs = {
        type         = typeId,
        victim       = victim,
        victimAware  = victimAware == true,
        arg          = arg or 0,
    }
    log('commitCrime', kind, 'arg=', inputs.arg, 'victimAware=', tostring(inputs.victimAware))
    I.Crimes.commitCrime(player, inputs)

    if faction and faction ~= '' then
        local factionInputs = {
            type        = typeId,
            victim      = victim,
            victimAware = inputs.victimAware,
            arg         = arg or 0,
            faction     = faction,
        }
        log('commitCrime (faction)', kind, faction)
        I.Crimes.commitCrime(player, factionInputs)
    end
end

local function Bastard_ReportCrime(data)
    log('Bastard_ReportCrime received')
    local player  = data.player
    local victim  = data.victim
    local kind    = data.kind          -- 'theft' or 'assault'
    local arg     = data.arg or 0
    local faction = data.faction
    local aware   = data.victimAware

    commitCrime(player, kind, victim, arg, faction, aware)
end

-- ======================================================================================================
-- item transfer

local function Bastard_TransferLoot(data)
    log('Bastard_TransferLoot received')
    local npc        = data.npc
    local player     = data.player
    local itemRefs   = data.items or {}     -- list of GameObjects
    local takeGold   = data.takeGold ~= false

    if not npc or not npc:isValid() or types.Actor.isDead(npc) then
        log('TransferLoot: bad NPC')
        return
    end
    if not player or not player:isValid() then
        log('TransferLoot: bad player')
        return
    end

    local playerInv = types.Actor.inventory(player)
    local totalValue = 0

    -- gold
    local goldMoved = 0
    if takeGold then
        local npcInv = types.Actor.inventory(npc)
        for _, item in ipairs(npcInv:getAll()) do
            if item:isValid() and GOLD_IDS[item.recordId] then
                local cnt = item.count
                item:moveInto(playerInv)
                totalValue = totalValue + cnt
                goldMoved = goldMoved + cnt
                log('moved gold', item.recordId, 'x', cnt)
            end
        end
    end
    if goldMoved > 0 then
        core.sound.playSound3d('Item Gold Up', player)
    end

    -- items
    for _, item in ipairs(itemRefs) do
        if item and item:isValid() and item.parentContainer == npc then
            local val = 0
            local rec = item.type and item.type.record and item.type.record(item)
            if rec and rec.value then val = rec.value end
            totalValue = totalValue + (val * (item.count or 1))
            local sound = pickupSoundFor(item)
            item:moveInto(playerInv)
            core.sound.playSound3d(sound, player)
            log('moved item', item.recordId, 'value=', val, 'sound=', sound)
        end
    end

    -- tell the player how much was taken (for crime arg / message)
    if data.replyEvent and player:isValid() then
        player:sendEvent(data.replyEvent, {
            value = totalValue,
            npc   = npc,
        })
    end
end

-- ======================================================================================================
-- hostility

local function Bastard_NPCGiveIn(data)
    log('Bastard_NPCGiveIn received')
    local npc = data.npc
    if not npc or not npc:isValid() or types.Actor.isDead(npc) then return end
    ensureLocalScript(npc)
    npc:sendEvent('Bastard_PlayGiveIn', { player = data.player })
end

local function Bastard_NPCFight(data)
    log('Bastard_NPCFight received')
    local npc    = data.npc
    local player = data.player
    if not npc or not npc:isValid() or types.Actor.isDead(npc) then return end
    ensureLocalScript(npc)
    npc:sendEvent('Bastard_StartFight', { player = player })
end

local function Bastard_NPCPursue(data)
    log('Bastard_NPCPursue received')
    local npc    = data.npc
    local player = data.player
    if not npc or not npc:isValid() or types.Actor.isDead(npc) then return end
    ensureLocalScript(npc)
    npc:sendEvent('Bastard_StartPursue', { player = player })
end

-- ======================================================================================================
-- disposition reset on give-in

local function Bastard_DropDisposition(data)
    local self   = data.player
    local actor  = data.npc
    if not self or not actor or not actor:isValid() then return end
    if not types.NPC.objectIsInstance(actor) then return end
    local cur = types.NPC.getDisposition(actor, self)
    if cur > 0 then
        types.NPC.modifyBaseDisposition(actor, self, -cur)
    end
end

local function Bastard_RequestRemoval(actor)
    if not actor or not actor:isValid() then return end
    if actor:hasScript(LOCAL_SCRIPT) then
        actor:removeScript(LOCAL_SCRIPT)
        log('removed local script from', actor.recordId)
    end
end

local function Bastard_NPCSay(data)
    log('Bastard_NPCSay received', data and data.category)
    local npc = data and data.npc
    if not npc or not npc:isValid() or types.Actor.isDead(npc) then return end
    
    if not types.NPC.objectIsInstance(npc) then return end

    local rec = types.NPC.record(npc)
    if not rec then return end

    local raceKey = (shared.RACE_TO_VOICE_KEY or {})[(rec.race or ''):lower()]
    if not raceKey then return end

    local genderKey = rec.isMale and 'male' or 'female'

    local cat = shared.VOICELINES and shared.VOICELINES[data.category]
    if not cat then return end
    
    local byRace = cat[raceKey]
    if not byRace then return end
    
    local stems = byRace[genderKey]
    if not stems or #stems == 0 then return end

    local stem = stems[math.random(#stems)]
    local sound = (shared.VOICE_BASE_PATH or '') .. stem .. '.mp3'
    core.sound.say(sound, npc)
end

local function Bastard_OpenGuardDialogue(data)
    log('Bastard_OpenGuardDialogue received')
    local player = data.player
    local guard  = data.guard
    if not player or not player:isValid() then
        log('OpenGuardDialogue: invalid player'); return
    end
    if not guard or not guard:isValid() or types.Actor.isDead(guard) then
        log('OpenGuardDialogue: invalid/dead guard'); return
    end
    log('OpenGuardDialogue: opening dialogue with', guard.recordId)
    player:sendEvent('AddUiMode', { mode = 'Dialogue', target = guard })
end

local function init()
end

return {
    engineHandlers = {
        onInit = init,
        onLoad = init,
    },
    eventHandlers = {
        Bastard_SetLog          = Bastard_SetLog,
        Bastard_ReportCrime     = Bastard_ReportCrime,
        Bastard_TransferLoot    = Bastard_TransferLoot,
        Bastard_NPCGiveIn       = Bastard_NPCGiveIn,
        Bastard_NPCFight        = Bastard_NPCFight,
        Bastard_NPCPursue       = Bastard_NPCPursue,
        Bastard_DropDisposition = Bastard_DropDisposition,
        Bastard_RequestRemoval  = Bastard_RequestRemoval,
        Bastard_NPCSay          = Bastard_NPCSay,
        Bastard_OpenGuardDialogue = Bastard_OpenGuardDialogue,
    },
}