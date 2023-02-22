local function startAlchemy()
    tes3.addItem{reference=tes3.player, item="apparatus_a_alembic_01", playSound=false}
    tes3.addItem{reference=tes3.player, item="apparatus_a_calcinator_01", playSound=false}
    tes3.addItem{reference=tes3.player, item="apparatus_a_mortar_01", playSound=false}
    tes3.addItem{reference=tes3.player, item="apparatus_a_retort_01", playSound=false}
    mwscript.equip{reference=tes3.player, item="apparatus_a_alembic_01"}
    timer.delayOneFrame(function()
        tes3.removeItem{reference=tes3.player, item="apparatus_a_alembic_01", playSound=false}
        tes3.removeItem{reference=tes3.player, item="apparatus_a_calcinator_01", playSound=false}
        tes3.removeItem{reference=tes3.player, item="apparatus_a_mortar_01", playSound=false}
        tes3.removeItem{reference=tes3.player, item="apparatus_a_retort_01", playSound=false}
    end)
end

local function onActivate(e)
    -- only interested in objects with alchemy table script
    if tostring(e.target.object.script) ~= "cor_alchemy_table" then return end

    -- only interested if its the player activing the table
    if e.activator ~= tes3.player then return end

    tes3.messageBox({
        message = "Do you want to pay the 50 gold fee to use this alchemy table?",
        buttons = {"Yes", "No"},
        callback = function(msgbox)
            if msgbox.button == 0 then
                timer.delayOneFrame(startAlchemy)
            end
        end
    })
end
event.register("activate", onActivate)
