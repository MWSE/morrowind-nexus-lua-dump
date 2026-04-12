local I = require("openmw.interfaces")
local self = require("openmw.self")
I.LMM_MagicInterface.monitorEffect("multimark_mark")
I.LMM_MagicInterface.monitorEffect("multimark_recall")
I.LMM_MagicInterface.registerSpell("multimark_mark_spell",50,"mark")
I.LMM_MagicInterface.registerSpell("multimark_recall_spell",50,"recall")

local function EffectStarted(effectData)
    print(effectData.effectId,"Load")
    if effectData.effectId == "multimark_mark" then
        self:sendEvent("saveMarkLoc")

    elseif effectData.effectId == "multimark_recall" then
        self:sendEvent("openMarkMenu")
    end
end
return {
    eventHandlers = {
        EffectStarted = EffectStarted
    }
}
