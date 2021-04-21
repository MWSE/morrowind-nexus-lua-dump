--[[
--]]

local function coinPlaced(e)
    if e.reference.id == "av_seacoin01" then
        local mesh

        if e.reference.stackSize >= 50 then
            mesh = "av\\m\\av_seacoin50.nif"
        elseif e.reference.stackSize >= 10 then
            mesh = "av\\m\\av_seacoin10.nif"
        elseif e.reference.stackSize >= 5 then
            mesh = "av\\m\\av_seacoin05.nif"
        else
            return
        end

        local node = tes3.loadMesh(mesh)
        e.reference.sceneNode:detachChildAt(1)
        e.reference.sceneNode:attachChild(node, true)
    end
end


local function coinActivated(e)
    if e.target.id:lower():find("^av_seacoin%d+") then
        local n = tonumber( e.target.id:match("%d+") )
        if (n ~= nil) and (n >= 5) then
            tes3.addItem{reference=tes3.player, item="av_seacoin01", count=n}
            mwscript.disable{reference=e.target}
            mwscript.setDelete{reference=e.target}
            return false
        end
    end
end
-- King Orgnum's Coffer

local skipActivate
local function cofferActivated(e)
    local ref = e.target

    if ref.id ~= "av_coffer" then
        return
    end
    if skipActivate == true then
        skipActivate = false
        return
    end

    -- trigger journal on first activation
    if tes3.getJournalIndex{id="AV_QSeacoin"} < 1300 then
        tes3.setJournalIndex{id="AV_QSeacoin", index=1300}
        tes3.setGlobal("av_near_coffer", 10)
        return false
    end

    local today = tes3.getGlobal("DaysPassed")
    local respawnDay = ref.data.respawnDay or 0

    tes3.messageBox{
        message = "What do you want to do?",
        buttons = {"Search the coffer", "Pick up the coffer"},
        callback = function(e)
            if e.button == 0 then
                if today < respawnDay then
                    tes3.messageBox("Orgnum's coffer is barren for now.")
                else
                    local n = math.random(100, 500)
                    tes3.messageBox("You find %d Sea Coins within.", n)
                    tes3.addItem{reference=tes3.player, item="av_seacoin01", count=n}
                    ref.data.respawnDay = (today + 3)
                end
            elseif e.button == 1 then
                timer.delayOneFrame(function() skipActivate = true; tes3.player:activate(ref) end)
            end
        end,
    }

    return false
end


local exteriorCells
local function showHideGuarWreck(e)
    if not exteriorCells[e.cell] then return end

    local wreck = tes3.getReference("av_guarcart_ruined")
    local disable = tes3.getJournalIndex{id="AV_BloodSweatTears"} < 25

    if (wreck == nil) or (wreck.disabled == disable) then
        return
    end

    assert(wreck.sourceMod == "Tales of Ald Velothi.esp")

    for i, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            if (ref.sourceMod ~= nil
                and ref.sourceMod == ("Tales of Ald Velothi.esp")
                and ref.object.objectType ~= tes3.objectType.npc
                and ref.position:distance(wreck.position) < 280
                )
            then
                if disable then ref:disable() else ref:enable() end
            end
        end
    end
end


local function initialized(e)
    if not tes3.isModActive("Tales of Ald Velothi.esp") then
        mwse.log("[mwse/mods/aldvelothi] The required plugin not enabled! (Tales of Ald Velothi.esp)")
        return
    end

    exteriorCells = {
        [tes3.getCell{x = -12, y = 14}] = true,
        [tes3.getCell{x = -12, y = 15}] = true,
        [tes3.getCell{x = -12, y = 16}] = true,
        [tes3.getCell{x = -11, y = 14}] = true,
        [tes3.getCell{x = -11, y = 15}] = true,
        [tes3.getCell{x = -11, y = 16}] = true,
        [tes3.getCell{x = -10, y = 14}] = true,
        [tes3.getCell{x = -10, y = 15}] = true,
        [tes3.getCell{x = -10, y = 16}] = true,
    }
    event.register("cellChanged", showHideGuarWreck)
    event.register("loaded", function() showHideGuarWreck{cell=tes3.player.cell} end)

    event.register("referenceSceneNodeCreated", coinPlaced)
    event.register("activate", coinActivated)

    event.register("activate", cofferActivated, {priority = -3000})

    mwse.log("[Tales of Ald Velothi.esp] Initialized.")
end
event.register("initialized", initialized)



-- mwse.overrideScript("av_travel", function(e)
--     if tes3.menuMode() then return end
--     mwscript.aiTravel{
--         reference = e.reference,
--         x = e.script.context.xPos,
--         y = e.script.context.yPos,
--         z = e.script.context.zPos,
--     }
--     mwscript.stopScript{script="av_travel"}
-- end)
