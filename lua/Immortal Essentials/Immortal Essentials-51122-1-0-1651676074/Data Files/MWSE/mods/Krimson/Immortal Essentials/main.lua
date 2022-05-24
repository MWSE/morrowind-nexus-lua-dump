local essential = {
    "addhiranirr", "apelles matius", "asciene rane", "athyn sarethi", "barenziah", "Blatta Hateria", "brara morvayn", "caius cosades", "crassius curio", "crazy_batou",
    "danso indules", "divayth fyr", "dram bero", "dutadalk", "effe_tei", "endryn llethan", "falura llervu", "falx carius", "fedris hler", "garisa llethri",
    "gavas drin", "gilvas barelo", "han-ammu", "hasphat antabolis", "hassour zainsubani", "hlaren ramoran", "huleeya", "karrod", "kaushad", "kausi",
    "King Hlaalu Helseth", "manirai", "mehra milo", "miner arobar", "nevena ules", "nibani maesa", "raesa pullia", "savile imayn", "sharn gra-muzgob", "sinnammu mirpal",
    "sonummu zabamat", "sul-matuul", "tharsten heart-fang", "tholer saryoni", "Tienius Delitian", "uupse fyr", "varvur sarethi", "velanda omani", "yenammu", "zabamund"
}

local function onDamaged()
    for _, npc in pairs(essential) do
        local actor = tes3.getReference(npc)
        if actor.mobile ~= nil then
            tes3.setStatistic({ name = "health", reference = actor, value = 500000 })
        end
    end
end

local function onLoaded()
    for _, npc in pairs(essential) do
        local actor = tes3.getReference(npc)
        if actor.mobile ~= nil then
            tes3.setStatistic({ name = "health", reference = actor, value = 500000 })
        end
    end
end

local function initialized(e)
    event.register("damaged", onDamaged)
    event.register("loaded", onLoaded)
    mwse.log("[Krimson] Immortal Essentials")
end

event.register("initialized", initialized)