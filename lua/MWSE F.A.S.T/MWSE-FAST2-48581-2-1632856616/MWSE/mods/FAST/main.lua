local function onCalcMoveSpeed(e)
  local mspeed
  local cfat = e.mobile.fatigue.current
  local bfat = e.mobile.fatigue.base
  if bfat == 0 then --should never happen but just in case
    tes3.messagebox("divide by zero error in MWSE FAST, mobile base fatigue is 0")
    mwse.log("divide by zero error in MWSE FAST, mobile base fatigue is 0")
    return
  end
  local rfat = (cfat / bfat) -- fatigue ratio
  if rfat < .5 then
    mspeed = ((cfat * 2) / bfat)
    if mspeed < .5 then mspeed = .5 end
    e.speed = e.speed * mspeed
  end
  if rfat >= .75 then
    mspeed = (rfat + .25)
    e.speed = e.speed * mspeed
  end
end
event.register("calcMoveSpeed", onCalcMoveSpeed)