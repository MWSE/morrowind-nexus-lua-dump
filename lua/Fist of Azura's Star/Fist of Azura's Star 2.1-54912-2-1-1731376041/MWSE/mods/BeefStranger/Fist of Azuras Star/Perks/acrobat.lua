local bs = require("BeefStranger.Fist of Azuras Star.common")

---@type bsAzuraAcrobat
local ACROBAT = bs.ACROBAT

---@class bs_Azura_Acrobat
local this = {}
local jumpCount = 0

--- @param e jumpEventData
function this.onJump(e)
    jumpCount = jumpCount + 1
    e.velocity.y = e.velocity.y * ACROBAT.XY_MULT
    e.velocity.x = e.velocity.x * ACROBAT.XY_MULT
    e.velocity.z = e.velocity.z * ACROBAT.Z_MULT
end

function this.doubleJump()
    if tes3.mobilePlayer.isJumping then
        if jumpCount < ACROBAT.MAX_JUMPS then
            tes3.mobilePlayer:doJump({ allowMidairJumping = true })
        end
    else
        jumpCount = 0
    end
end

return this
