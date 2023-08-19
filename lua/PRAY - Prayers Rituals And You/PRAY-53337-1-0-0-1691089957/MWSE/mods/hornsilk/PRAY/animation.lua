-- Define an empty table to store animation functions
local this = {}

-- https://mwse.github.io/MWSE/references/animation-groups/
-- try `the sitting mod` for some better animations
-- Use tes3.loadAnimation to play custom animations

-- Define a function to begin the default animation
this.defaultAnimationBegin = function()
    -- Enable vanity mode to allow custom animations
    tes3.setVanityMode{enabled = true, checkVanityDisabled = false}

    -- Play a custom animation (idle8) for the player reference
    tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle8})
end

-- Define a function to end the default animation
this.defaultAnimationEnd = function()
    -- Disable vanity mode to revert to normal animations
    tes3.setVanityMode{enabled = false, checkVanityDisabled = false}

    -- Load the default animation for the player reference
    tes3.loadAnimation{reference = tes3.player}
end

-- Return the table containing animation functions
return this
