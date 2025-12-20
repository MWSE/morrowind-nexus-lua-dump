local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local vfs = require('openmw.vfs')
local msg = core.l10n('DubiousConcoctions', 'en')

local player = world.players[1]
local skills = types.NPC.stats.skills
local potionCache = {}

local function isGen(itemid)
    return string.sub(itemid, 1, 9) == "Generated"
end

local function getDisposition(npc)
    return types.NPC.getDisposition(npc, player)
end


local function isPoison(potionRecord, onlyGen ) 
    -- Набор эффектов, считающихся ядом
    -- local poisonEffects = {
    --     poison = true,
    --     paralyze = true,
    --     burden = true,
    --     blind = true,
    --     silence = true
    -- }

    -- -- Ядовитые зелья по ID (включая квестовые и уникальные)    
    -- local poisonPotions = {
    --     p_paralyze_b   = true,
    --     p_paralyze_c   = true,
    --     p_paralyze_s   = true,
    --     p_paralyze_q   = true,
    --     p_paralyze_e = true,
    --     p_silence_b = true,
    --     p_silence_c   = true,
    --     p_silence_s   = true,
    --     p_silence_q   = true,
    --     p_silence_e = true,
    --     p_burden_b = true,
    --     p_burden_c = true,
    --     p_burden_e = true,
    --     p_burden_q = true,
    --     p_burden_s = true,

    -- }

    -- if poisonPotions[potionRecord.id] then return true end

    local goodEffect = 0
    local badEffect = 0

    for _, effect in ipairs(potionRecord.effects) do
        local effectRecord = core.magic.effects.records[effect.id]

        if effectRecord.harmful then
        -- if poisonEffects[effect.id] or effectRecord.school == "destruction" then
            badEffect = badEffect + 1
        else
            goodEffect = goodEffect + 1
        end
    end

    --print("Potion ", potionRecord.name, " good:", goodEffect, " bad: =", badEffect)
    return goodEffect < badEffect*3 
end

local function hasFactionRank()
    local requiredFactionRanks = {
        ["mages guild"] = 3,
        ["temple"] = 3,
        ["telvanni"] = 3,
        ["imperial cult"] = 3,
        ["hlaalu"] = 5,
        ["fighters guild"] = 5,
        ["imperial legion"] = 5,
        ["redoran"] = 5,
        ["morag tong"] = 5,
        ["east empire company"] = 5
    }

    for factionId, requiredRank in pairs(requiredFactionRanks) do
        local currentRank = types.NPC.getFactionRank(player, factionId)
        if currentRank >= requiredRank then
            return true
        end
    end

    return false
end

local function checkPoisonTrader(npc)
    local inventory = types.Actor.inventory(npc)
    local potions = inventory:getAll(types.Potion)

    for _, potion in ipairs(potions) do
        local potionRecord = types.Potion.record(potion)
        if isPoison(potionRecord) then
            return true
        end
    end
    return false
end

local function checkOnlyPoison(npc)
    local inventory = types.Actor.inventory(npc)
    local potions = inventory:getAll(types.Potion)

    for _, potion in ipairs(potions) do
        local potionRecord = types.Potion.record(potion)
        if not isPoison(potionRecord) and isGen(potionRecord.id) then
            return false
        end
    end
    return true
end

local tradersWelcomeMessage = 
{
    ["any"] = {
       NANR = "dcMSG01",
       ANR = "dcMSG02",
       NAR = "dcMSG03",
       PSN = "dcMSG13",    
    },
    ["camonna tong"] = {
        NAND = "dcMSG04",
        AND = "dcMSG05",
        NAD = "dcMSG06",
    },
    ["dark brotherhood"] = {
        NAND = "dcMSG04",
        AND = "dcMSG05",
        NAD = "dcMSG06",
    },
    ["clan berne"] = {
        NAND = "dcMSG07",
        AND = "dcMSG08",
        NAD = "dcMSG09",       
    },
    ["thieves guild"] = {
        NAND = "dcMSG10",
        AND = "dcMSG11",
        NAD = "dcMSG12",              
        PSN = "dcMSG13",              
    },
    ["clan quarra"] = {
        NAND = "dcMSG14",
        AND = "dcMSG15",
        NAD = "dcMSG16",      
    },
    ["sixth house"]  = {
        NAND = "dcMSG17",
        AND = "dcMSG18",
        NAD = "dcMSG19",      

    },
    ["clan aundae"] = {
        NANR = "dcMSG20",
        ANR = "dcMSG21",
        NAR = "dcMSG22",
    },
    ["morag tong"] = {
        NANR = "dcMSG23",
        ANR = "dcMSG24",
        NAR = "dcMSG25",
    },
    ["telvanni"] = {
        NANR = "dcMSG26",
        ANR = "dcMSG27",
        NAR = "dcMSG28",
    }
}
local function tradersWelcome(dialog, factionId, hasRank, hasDisp, hasAlchemi, noPoison )
    if not dialog then return end
    
    local tradersMessages = tradersWelcomeMessage[factionId] or tradersWelcomeMessage["any"]
    local sufix

    if noPoison then
        sufix = tradersMessages.PSN
    end       
    if not sufix and not hasAlchemi and not hasDisp then
        sufix = tradersMessages.NAND
    end
    if not sufix and not hasAlchemi and not hasRank then
        sufix = tradersMessages.NANR
    end
    if not sufix and hasAlchemi and not hasDisp then
        sufix = tradersMessages.AND
    end    
    if not sufix and hasAlchemi and not hasRank then
        sufix = tradersMessages.ANR
    end    
    if not sufix and not hasAlchemi and hasRank then
        sufix = tradersMessages.NAR
    end    
    if not sufix and not hasAlchemi and hasDisp then
        sufix = tradersMessages.NAD
    end    

    if sufix then
        player:sendEvent('dcShowMessage', {message =  msg(sufix) })
    end
end

local onlyPoison

local function getConditions(npc, dialog)
    -- Условия для исключения удаления зелий и ядов по фракциям
    local conditionPotion = {
        ["camonna tong"]      = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["dark brotherhood"]  = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["sixth house"]       = { alchemy = 15, rankRequired = false, disposition = 80 },
        ["thieves guild"]     = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["clan aundae"]       = { alchemy = 60, rankRequired = true,  disposition = 0 },
        ["clan berne"]        = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["clan quarra"]       = { alchemy = 15, rankRequired = false, disposition = 80 },
        ["morag tong"]        = { alchemy = 60, rankRequired = true,  disposition = 0 },
    }

    local conditionPoison = {
        ["camonna tong"]      = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["dark brotherhood"]  = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["sixth house"]       = { alchemy = 15, rankRequired = false, disposition = 80 },
        ["clan aundae"]       = { alchemy = 60, rankRequired = true,  disposition = 0 },
        ["clan berne"]        = { alchemy = 30, rankRequired = false, disposition = 80 },
        ["clan quarra"]       = { alchemy = 15, rankRequired = false, disposition = 80 },
        ["morag tong"]        = { alchemy = 60, rankRequired = true,  disposition = 0 },
    }

    local telvani = "telvanni" 

    local traders = {
        scamp_creeper    = { removeCheap = false, removePoison = false },
        mudcrab_unique   = { removeCheap = false, removePoison = false }
    }


    local disposition = getDisposition(npc)
    local alchemy = skills.alchemy(player).modified
    local hasRank = hasFactionRank()

    if not dialog then 
        onlyPoison = checkOnlyPoison(player)
    end
    
    local trader = traders[npc.id]
    if trader then
        return trader.removeCheap, trader.removePoison
    end

    local removeCheapPotion = true
    local removePoison = true

    -- Проверка: игрок в фракции Telvanni с достаточным рангом или высокой алхимией
    local factionId = types.NPC.getFactions(npc)[1]

    if factionId == telvani then
        local hasRankTelvani
        local hasAlchemi

        hasRankTelvani = types.NPC.getFactionRank(player, telvani) >= 2
        hasAlchemi = alchemy >= 60
        if hasRankTelvani and hasAlchemi then
            removeCheapPotion = false
            removePoison = false       
        end
        tradersWelcome(dialog, telvani, hasRankTelvani, true, hasAlchemi, onlyPoison and removePoison)
        return removeCheapPotion, removePoison  -- Telvanni имеет наивысший приоритет
    end

    -- Проверка условий для ядов
    local condPoison = conditionPoison[factionId]
    if condPoison then
        if alchemy >= condPoison.alchemy and disposition >= condPoison.disposition and
            (not condPoison.rankRequired or hasRank) then
            removePoison = false
        end
    elseif checkPoisonTrader(npc) and  alchemy >= 60 and hasRank then
        removePoison = false
    end

    -- Проверка условий для дешёвых зелий
    local condPotion = conditionPotion[factionId]
    if condPotion then
        tradersWelcome(dialog, factionId, not condPotion.rankRequired or hasRank, disposition >= condPotion.disposition , alchemy >= condPotion.alchemy, onlyPoison and removePoison)
        if alchemy >= condPotion.alchemy and disposition >= condPotion.disposition and (not condPotion.rankRequired or hasRank) then
            removeCheapPotion = false
        end
    else
        -- Для всех других фракций: если алхимия >= 60 и есть ранг — не удалять
        tradersWelcome(dialog, "any", hasRank, true, alchemy >= 60, onlyPoison and removePoison)
        if alchemy >= 60 and hasRank then
            removeCheapPotion = false
        end
    end
    
    return removeCheapPotion, removePoison
end


local function removeCheapPotion(data)
    local inventory = types.Actor.inventory(player)
    local potions = inventory:getAll(types.Potion)

    local removeCheapPotion, removePoison = getConditions(data.npc, false)

    if not removeCheapPotion and not removePoison then return end

    for _, potion in ipairs(potions) do
        local potionRecord = types.Potion.record(potion)
        local poison = isPoison(potionRecord)

        if isGen(potionRecord.id) then
            if (removeCheapPotion and not poison) or (removePoison and poison) then
                local count = inventory:countOf(potionRecord.id)
                potionCache[potionRecord.id] = count
                potion:remove(count)
            end
        end
    end
end

local function hasGenPotions()
    return next(potionCache) ~= nil 
end    

local function merchantsRemark(data)
    local npcRecord = types.NPC.record(data.npc)  
    if npcRecord.servicesOffered["Potions"] then
        if hasGenPotions() then
            local  _, _ = getConditions(data.npc, true)
        end
    end   
end

local function returnCheapPotion()
    local inventory = types.Actor.inventory(player)
    for id, count in pairs(potionCache) do
        local item = world.createObject(id, count)
        item:moveInto(inventory)
    end
    potionCache = {}
end

return {
    engineHandlers = {
        -- onUpdate = onUpdate
    },
    eventHandlers = {
        removeCheapPotion = removeCheapPotion,
        returnCheapPotion = returnCheapPotion,
        merchantsRemark = merchantsRemark
    }

}
