local this = {}

function this.delayForFrameCount( frameCount, callback )
  assert( frameCount > 0, "Cannot delay a callback for a zero or negative frame count." )

  if( frameCount == 1 ) then
    timer.delayOneFrame( callback )
    return
  end

  timer.delayOneFrame( function()
    this.delayForFrameCount( frameCount - 1, callback )
  end )
end

return this