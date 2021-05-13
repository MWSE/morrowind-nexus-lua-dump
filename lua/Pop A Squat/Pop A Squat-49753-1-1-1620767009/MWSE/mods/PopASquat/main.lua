local squatState                                                                ---Declaring a new local variable called 'squatState'. This is our "is the player squatting?" variable. Has a default value of 'nil' as we haven't assigned a value yet, ie - the player isn't squatting.

local function animAct(e)                                                       ---This is the function that plays our animations.

  --mwse.log("Checking if any menu is open.")
  if tes3.menuMode() then                                                       ---If the menu is open...
    return
  end                                                                           ---...don't do squat.
  --mwse.log("Menu check complete.")

  if ( e.isAltDown and squatState == nil ) then                                 ---If 'Alt' is pressed and the "is the player squatting?" variable is 'no'...
    --mwse.log("Keypress detected. squatState = nil.")
    squatState = 1                                                              ---Set the "is the player squatting?" variable to 'yes'.
    --mwse.log("squateState set to 1")
    tes3.force3rdPerson()                                                       ---Sets the camera mode to 3rd person. So we can see the animation.
    --mwse.log("3rd Person Forced")
    tes3.playAnimation({                                                        ---This invokes our animation.

      reference = tes3.player,                                                  ---Setting the player as our actor.
      group = tes3.animationGroup.idle9,                                        ---This is the animation group in which squat.nif resides.
      mesh = "squat.nif",                                                       ---This is the actual animation file.
      startFlag = tes3.animationStartFlag.immediate,                            ---Plays the animation immediately.
      loopCount = -1                                                            ---'-1' tells the animation to loop indefinitely, in this case, the player will remain squatting. Make sure the appropriate 'loop start/stop' text keys are set up correctly in Blender!
    })
    --mwse.log("Squat = Popped")

  else                                                                          ---If 'Alt' is pressed and the "is the player squatting?" variable is 'yes'...

    if tes3.menuMode() then                                                     ---Checking whether a menu is open and, if so, don't do anything.
      return
    end
    tes3.cancelAnimationLoop({reference=tes3.player})                           ---Cancel the animation loop (player is already squatting) ie - stand up.
    --mwse.log("Keypress detected. squatState = 1.")
    squatState = nil                                                            ---Set the "is the player squatting?" variable to 'no'.
    --mwse.log("squatState set to nil")
    tes3.force3rdPerson()                                                       ---Switch to 3rd person view to see the animation.
    --mwse.log("3rd Person Forced")
    --mwse.log("Player Stood Up")
  end
end

local function initialized()                                                    ---When the game has initialized, this function fires.
  event.register("keyDown", animAct, { filter = tes3.scanCode.g } )             ---Detect when the 'G' key is pressed.
  mwse.log("[squat.nif] Initialized")
end

event.register("initialized", initialized)
