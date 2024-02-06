local game = tes3.getGame()

local function changeViewRange(shouldIncrease)
  -- increases or decreases view range 10x by +/- 512 with limits of 2500-7168
  for i = 10,1,-1 
  do
    if shouldIncrease then
      mge.macros.increaseViewRange()
    else
      mge.macros.decreaseViewRange()
    end
  end
end

local function adjustViewRangeByCellType(isExterior)
  if (isExterior and game.renderDistance == 7168) then
    changeViewRange()
  elseif (not isExterior and game.renderDistance == 2500) then
    changeViewRange(true)
  end
end

local function cellChangedCallback(e)
  adjustViewRangeByCellType(e.cell.isOrBehavesAsExterior)
end

event.register(tes3.event.cellChanged, cellChangedCallback)
