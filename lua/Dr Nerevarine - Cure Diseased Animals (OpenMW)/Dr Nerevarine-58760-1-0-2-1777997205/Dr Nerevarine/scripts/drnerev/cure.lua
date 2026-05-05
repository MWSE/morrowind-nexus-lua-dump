-- подключ. внеш. модулей
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')

local msg = core.l10n('drnerev', 'en')

local exceptionsCreature = {
    ["creatureId"] = true
}

local illHealfy = {
    ["shalk_diseased"] = "shalk",
    ["cliff racer_diseased"] = "cliff racer",
    ["alit_diseased"] = "alit",
    ["kagouti_diseased"] = "kagouti",
    ["kwama worker diseased"] = "kwama worker",
    ["scrib diseased"] = "scrib",
    ["rat_diseased"] = "rat",
    ["shalk_diseased_hram"] = "shalk",
    ["mudcrab-diseased"] = "mudcrab",
    ["durzog_diseased"] = "durzog",

    ["t_mw_fau_beetleblds_01"] = "t_mw_fau_beetlebl_01",
    ["t_mw_fau_beetlebrds_01"] = "t_mw_fau_beetlebr_01",
    ["t_mw_fau_beetlegrds_01"] = "t_mw_fau_beetlegr_01",
    ["t_mw_fau_beetlehrds_01"] = "t_mw_fau_beetlehr_01",
    ["t_mw_fau_thresherds_01"] = "t_mw_fau_thresher_01",
    ["t_mw_fau_kwawrds_01"] = "kwama worker",
    ["t_mw_fau_kwafrgds_01"] = "kwama forager",
    ["t_mw_fau_kwaqnds_01"] = "kwama queen",
    ["t_mw_fau_molecds_01"] = "t_mw_fau_molec_01",
    ["t_mw_fau_netbtyds_01"] = "netch_betty",
    ["t_mw_fau_netblds_01"] = "netch_bull",
    ["t_mw_fau_nixhds_01"] = "nix-hound",
    ["t_mw_fau_parads_01"] = "t_mw_fau_para_01",
    ["t_glb_fau_ratds_01"] = "rat",
    ["t_mw_fau_sharaihopds_01"] = "t_mw_fau_sharaihoppe_01",

    ["shalk_blighted"] = "shalk",
    ["cliff racer_blighted"] = "cliff racer",
    ["alit_blighted"] = "alit",
    ["kagouti_blighted"] = "kagouti",
    ["kwama warrior blighted"] = "kwama warrior",
    ["kwama worker blighted"] = "kwama worker",
    ["kwama forager blighted"] = "kwama forager",
    ["nix-hound blighted"] = "nix-hound",
    ["scrib blighted"] = "scrib",
    ["rat_blighted"] = "rat"

}

local blight = {"ash woe blight", "ash-chancre", "black-heart blight", "chanthrax blight"}

local disease = {"ataxia", "chills", "collywobbles", "crimson_plague", "dampworm", "greenspore", "helljoint", "rattles",
                 "rockjoint", "rotbone", "rust chancre", "serpiginous dementia", "swamp fever", "witbane",
                 "witchwither", "wither", "yellow tick"}

local disease =  {
    ["shalk"] = {"collywobbles", "dampworm"},
    ["cliff racer"] = {"helljoint"},
    ["alit"] = {"rockjoint"},
    ["kagouti"] = {"yellow tick"},
    ["kwama worker"] = {"droops"},
    ["scrib"] = {"droops"},
    ["rat"] = {"rust chancre", "witbane"},
    ["mudcrab"] = {"swamp fever"},
    ["durzog"] = {"rotbone"},

    ["t_mw_fau_beetlebl_01"] = {"dampworm"},
    ["t_mw_fau_beetlebr_01"] = {"dampworm"},
    ["t_mw_fau_beetlegr_01"] = {"dampworm"},
    ["t_mw_fau_beetlehr_01"] = {"dampworm"},
    ["t_mw_fau_thresher_01"] = {"dampworm"},
    ["kwama forager"] = {"droops"},
    ["kwama queen"] = {"droops"},
    ["t_mw_fau_molec_01"] = {"dampworm"},
    ["netch_betty"] = {"dampworm"},
    ["netch_bull"] = {"dampworm"},
    ["nix-hound"] = {"rattles"},
    ["t_mw_fau_para_01"] = {"dampworm"},
    ["t_mw_fau_sharaihoppe_01"] = {"dampworm"},
}

local function getInfected(type, creatureId)

    local spellid
    local resist
    if type == "blight" then
        spellid = blight[math.random(1, #blight)]
        resist = types.Actor.activeEffects(self):getEffect("resistcommondisease")
    elseif type == "common" then
        local dis = disease[creatureId]
        if dis then 
            spellid = dis[math.random(1, #dis)]
            resist = types.Actor.activeEffects(self):getEffect("resistblightdisease")
        end
    end

    local chance = 0.25*(1-math.min(resist.magnitude, 100)/100)
    if math.random() >= chance then
        return
    end


    if spellid then
        types.Actor.spells(self):add(spellid)
        self:sendEvent("OnActorInfected", {
            spellId = spellid
        })
        ui.showMessage(msg("drnrInfected"))
    end
end


-- Основная функция проверки эффектов на актёре
local function checkEffectsOnActor(data)

    local dist = data.distance
    local actor = data.actor

    local activeEffectsList
    if data.effects then
        activeEffectsList = data.effects
    else
        activeEffectsList = types.Actor.activeEffects(actor)
    end

    local healfyId = illHealfy[actor.recordId]
    if not healfyId then
        -- print(actor.recordId)
        -- print(actor.id)
        return
    end

    -- Перебираем все активные эффекты
    for _, effect in pairs(activeEffectsList) do
        -- print(effect.id, effect.recordId)
        local inRange = (effect.range == core.magic.RANGE.Touch and dist <= 200) or
                            (effect.range == core.magic.RANGE.Target and dist <= 2000)

        if inRange and effect.id == "curecommondisease" and string.find(actor.recordId, "diseased") and effect.range ~=
            core.magic.RANGE.Self then
            --print("curecommondisease", dist, actor)
            core.sendGlobalEvent("drnrReplaceCreature", {
                ill = actor,
                healfy = healfyId
            })

            if inRange and effect.range == core.magic.RANGE.Touch then
                getInfected("common", healfyId)
            end
        elseif inRange and effect.id == "cureblightdisease" and string.find(actor.recordId, "blighted") and effect.range ~=
            core.magic.RANGE.Self then
            --print("cureblightdisease", dist, actor)
            core.sendGlobalEvent("drnrReplaceCreature", {
                ill = actor,
                healfy = healfyId
            })

            if inRange and effect.range == core.magic.RANGE.Touch then
                getInfected("blight", healfyId)
            end
        end
    end

end

-- регистрация
return {
    checkEffectsOnActor = checkEffectsOnActor
}
