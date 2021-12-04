return function(o)
  o.effects = {
    [tes3.effect.drainFatigue]  = tes3.magicSchool.destruction,
    [tes3.effect.damageFatigue] = tes3.magicSchool.destruction,
    [tes3.effect.absorbFatigue] = tes3.magicSchool.mysticism
  }

  return o
end