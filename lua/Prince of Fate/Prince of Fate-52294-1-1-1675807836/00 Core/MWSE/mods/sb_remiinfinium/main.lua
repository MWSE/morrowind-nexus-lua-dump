local globalSkill = "Rem_HM_Global"

--- @param e skillRaisedEventData
local function skillRaisedCallback(e)
  if (tes3.getGlobal(globalSkill) == 1) then
    tes3.modStatistic({ reference = tes3.mobilePlayer, skill = e.skill, base = 1, current = 1, value = 1 })   
  end
end

event.register(tes3.event.skillRaised, skillRaisedCallback)