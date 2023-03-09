local interop = {}

interop.uniqueMagnitude = {
    [tes3.effect.cureCommonDisease] = {
        T_Use_DaydenesPanacea = 25,
        sc_purityofbody = 100
    },
    [tes3.effect.cureBlightDisease] = {
        sc_purityofbody = 100
    },
    [tes3.effect.curePoison] = {},
    [tes3.effect.cureParalyzation] = {}
}

interop.setCureCommonMagnitude = function(objectId, value)
    interop.uniqueMagnitude[tes3.effect.cureCommonDisease][objectId] = value
end

interop.setCureBlightMagnitude = function(objectId, value)
    interop.uniqueMagnitude[tes3.effect.cureBlightDisease][objectId] = value
end

interop.setCurePoisonMagnitude = function(objectId, value)
    interop.uniqueMagnitude[tes3.effect.curePoison][objectId] = value
end

interop.setCureParalyzationMagnitude = function(objectId, value)
    interop.uniqueMagnitude[tes3.effect.cureParalyzation][objectId] = value
end


return interop