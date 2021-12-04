local function calcRestInterruptCallback(e)
  local friends = 0
  for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
    if actor then
      friends = (friends + 1)
    end
  end
  if friends > 1 then
    e.count = 0
  end
end
event.register("calcRestInterrupt", calcRestInterruptCallback)