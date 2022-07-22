local function getEncumbRatio(mob)
    return mob.encumbrance.current / mob.encumbrance.base
end

local function getJumpFatigueCost()
    local jumpBase = tes3.findGMST(tes3.gmst.fFatigueJumpBase).value
    local jumpMult = tes3.findGMST(tes3.gmst.fFatigueJumpMult).value
    local encRatio = getEncumbRatio(tes3.mobilePlayer)
    return jumpBase + encRatio * jumpMult
end

local function onJump(e)
  if e.mobile == tes3.mobilePlayer then
    if tes3.mobilePlayer.fatigue.current < getJumpFatigueCost() then
      tes3.setStatistic{reference = tes3.player, name = "fatigue", current = -1}
      e.velocity:negate()
      tes3.mobilePlayer.velocity:negate()
      tes3.messageBox({message = "You are too fatigued to jump! You fall over from exhaustion"})
    end
  end
end

event.register(tes3.event.jump, onJump)