local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local settings = storage.globalSection('SaneMagicSettingsGlobal')
local msg = core.l10n('SaneMagic', 'en')

local skills = types.NPC.stats.skills
local EFF = core.magic.EFFECT_TYPE
local player = nearby.players[1]

local underEffect = {}
local charmCount = 0
local charmFailCount = 0
local sneakLimit = 50
local defaultSneakLimit = 50

local function string_ends_with(str, ending)
    local len = string.len(str)
    local end_len = string.len(ending)
    if end_len > len then
        return false
    end
    return string.sub(str, -end_len) == ending
end

local function checkPlayerSneak(data)
    local sneak = skills.sneak(player).modified
    local class = types.NPC.record(self).class
    
    local isTrader = false
    if class == "trader service" or class == "bookseller" or class == "pawnbroker" 
        or string_ends_with(class, "service")
    then
        isTrader = true
    end    

    if sneak < sneakLimit then
        charmFailCount = charmFailCount+1
        if charmFailCount == 1 then
            --print("First charm sneak not enough")
            types.NPC.setBaseDisposition(self, player, 0)
            if isTrader then
                types.NPC.stats.skills.mercantile(self).base = 100
            end
        else
            -- print("Second charm sneak not enough", isTrader)
            if isTrader then
                core.sendGlobalEvent("punishCharm", {victim = self})
            end      

            AI.startPackage({type='Combat', target=player})            
            --data.actor:sendEvent('StartAIPackage', {type='Combat', target=player})    
        end
    end
    if sneak >= sneakLimit then
        charmCount = charmCount+1
        sneakLimit = math.min(sneakLimit + 10, 100) -- лимит 100
        if charmCount < 6 and sneak <= sneakLimit then
            player:sendEvent('dcShowMessage', {message = msg("smNextCharm")})
        else
            types.NPC.setBaseDisposition(self, player, 0)
        end
        --print("Not first charm sneak enough")
    end
end

local function checkEffectsOnNPC()
    local spells = types.Actor.activeSpells(self)
    local hasEffect = {}
    
    for spellid, param in pairs(spells) do
        if param.temporary and param.caster.type == types.Player then
            for _, effect in ipairs(param.effects) do
                if not underEffect[effect.id] then
                    underEffect[effect.id] = true
                    --EFFECT START
                    if effect.id == EFF.FrenzyHumanoid and settings:get("smFrenzyCrime")  then
                        core.sendGlobalEvent("punishFrenzy", { victim = self})
                    elseif (effect.id == EFF.Charm or effect.id == EFF.CommandHumanoid) and settings:get("smCharm") then
                        local sneak = skills.sneak(player).modified
                        if sneakLimit == 100 then
                            AI.startPackage({type='Combat', target=player})            
                        elseif sneak >= sneakLimit then
                            if charmCount <= 6 then
                                player:sendEvent('dcShowMessage', {message = msg("smFirstCharm")})
                            end
                        else
                            player:sendEvent('dcShowMessage', {message = msg("smFirstCharmNotEnough")})
                        end

                    end 
                end
                hasEffect[effect.id] = true
            end
        end
    end

    for effectId, wasUnderEffect in pairs(underEffect) do
        if not hasEffect[effectId] and wasUnderEffect then
            --EFFECT GONE
            underEffect[effectId] = false
            if (effectId == EFF.Charm or effectId == EFF.CommandHumanoid) and settings:get("smCharm") then
                checkPlayerSneak()
            end
        end
    end

end


--  I.Settings.registerUpdateHandler('PlayerConfigChanged', function(eventData)
--                 print("read settings")

--                 settingsCharm = eventData.settingsCharm
--                 settingsFrenzy = eventData.settingsFrenzy
--             end)


local function onUpdate(dt)
    checkEffectsOnNPC()
end

local function onLoad(data)
    charmCount = data and data.charmCount or 0
    charmFailCount = data and data.charmFailCount or 0
    sneakLimit = data and data.sneakLimit or defaultSneakLimit
    underEffect = data and data.underEffect or {}
end
local function onSave()
    return {charmCount = charmCount, charmFailCount=charmFailCount, sneakLimit=sneakLimit, underEffect=underEffect}
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave
    },

}
