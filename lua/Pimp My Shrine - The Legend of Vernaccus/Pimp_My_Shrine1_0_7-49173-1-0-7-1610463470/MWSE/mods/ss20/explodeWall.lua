local common = require('ss20.common')
local function removeWall(e)
    if e.wall then
        e.wall:disable()
    end
end
local function explodeWall(e)
    if e.wall then
        common.log:debug("Exploding wall")
        local animWall = e.wall
        tes3.playSound{ sound = "destruction area", reference = e.wall}
        animWall.data.ss20DoDestroy = true
        animWall.modified = true
        tes3.createReference{
            object = 'ss20_FX_explosion',
            position = animWall.position:copy(),
            orientation = animWall.orientation:copy(),
            cell = animWall.cell
        }
        tes3.playAnimation({
            reference = animWall ,
            group = tes3.animationGroup.idle2,
            startFlag = tes3.animationStartFlag.immediate
        })
        timer.start{
            duration = 4,
            callback = function()
                removeWall({wall = animWall })
            end
        }
    end
end

event.register("SS20:DestroyWall", explodeWall)



local function onActivate(e)
    --Triggered from mwscript, so no activator
    if e.activator == nil then
        if e.target.baseObject.id:lower() == 'ss20_in_daebarrierwell' then
            e.target.data.ss20DoDestroy = true
            timer.start{
                type = timer.real,
                duration = 27.5,
                callback = function()
                    event.trigger("SS20:DestroyWall", { wall = e.target })
                end
            } 
        end
    end
end
event.register("activate", onActivate)


local function disableWallsOnLoad()
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.activator) do
        if ref.data.ss20DoDestroy == true then
            removeWall({ wall = ref })
        end
    end
end
event.register("loaded", disableWallsOnLoad)