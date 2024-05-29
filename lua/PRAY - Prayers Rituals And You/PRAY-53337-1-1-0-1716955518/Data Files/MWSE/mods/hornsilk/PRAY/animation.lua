-- Define an empty table to store animation functions
local this = {}

-- https://mwse.github.io/MWSE/references/animation-groups/
-- try `the sitting mod` for some better animations
-- Use tes3.loadAnimation to play custom animations

-- Disable player controls --
local function setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
    tes3.mobilePlayer.mouseLookDisabled = state
end
local function disableControls()
    setControlsDisabled(true)
end
local function enableControls()
    setControlsDisabled(false)
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
end

-- Define a function to begin the default animation
this.defaultAnimationBegin = function()
    -- Enable vanity mode to allow custom animations
    tes3.setVanityMode{enabled = true, checkVanityDisabled = false}

    disableControls()

    -- Play a custom animation (idle8) for the player reference
    tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle8})
end

-- Define a function to end the default animation
this.defaultAnimationEnd = function()
    -- Disable vanity mode to revert to normal animations
    tes3.setVanityMode{enabled = false, checkVanityDisabled = false}

    enableControls()

    -- Load the default animation for the player reference
    tes3.loadAnimation{reference = tes3.player}
end

-- Return the table containing animation functions
return this
