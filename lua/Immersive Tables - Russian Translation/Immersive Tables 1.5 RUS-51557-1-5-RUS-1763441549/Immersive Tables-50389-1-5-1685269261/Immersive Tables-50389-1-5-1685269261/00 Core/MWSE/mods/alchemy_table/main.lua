-- Temporarily copy all accessible apparatus to player inventory.

local function collectApparatus()
    local apparatus = {}
    local mortar = nil

    local position = tes3.player.position
    local inventory = tes3.player.object.inventory

    -- scan current cell apparatus
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.apparatus) do
            local item = ref.object
            if not (
                apparatus[item]
                or ref.disabled
                or ref.deleted
                or ref.position:distance(position) > 768
                or tes3.hasOwnershipAccess{target=ref} == false
                or inventory:contains(item)
            ) then
                apparatus[item] = true
                if item.type == tes3.apparatusType.mortarAndPestle then
                    mortar = item
                end
            end
        end
    end

    -- check for mortar and pestle
    if not mortar then
        for _, stack in pairs(tes3.player.object.inventory) do
            local item = stack.object
            if item.objectType == tes3.objectType.apparatus
                and item.type == tes3.apparatusType.mortarAndPestle
            then
                mortar = item
                break
            end
        end
    end

    -- copy apparatus to inventory
    if mortar then
        -- add temporary apparatus
        for item in pairs(apparatus) do inventory:addItem{item=item} end
        tes3.updateInventoryGUI{reference=tes3.player}
        -- remove after menu close
        timer.delayOneFrame(function()
            for item in pairs(apparatus) do inventory:removeItem{item=item} end
            tes3.updateInventoryGUI{reference=tes3.player}
        end)
    end

    return mortar
end

local function startAlchemy()
    local mortar = collectApparatus()
    
    if not mortar then
        -- No mortar and pestle found
        -- Return 50 gold
        tes3.addItem{reference=tes3.player, item="gold_001", count=50}
        tes3.messageBox("Не найдена ступка и пестик")
        return
    end
    
    -- Mortar found, equip and open menu
    mwscript.equip{reference=tes3.player, item=mortar}
    tes3.showAlchemyMenu()
end

local function checkGold()
    if tes3.getItemCount{reference = tes3.player, item = "gold_001"} >= 50 then
        tes3.removeItem{reference = tes3.player, item = "gold_001", count = 50}
        startAlchemy()
    else
        tes3.messageBox("У вас недостаточно золота")
    end
end

local function onActivate(e)
    -- only interested in objects with alchemy table script
    if tostring(e.target.object.script) ~= "cor_alchemy_table" then return end
    -- only interested if its the player activing the table
    if e.activator ~= tes3.player then return end

    tes3.messageBox({
        message = "Вы хотите заплатить 50 золота за использование этого алхимического стола?",
        buttons = {"Да", "Нет"},
        callback = function(msgbox)
            if msgbox.button == 0 then
                timer.delayOneFrame(checkGold)
            end
        end
    })
end


local function onInitialized(e)
    if tes3.isModActive("Immersive Tables.esp") then
        mwse.log("Enabling Immersive Tables")
        event.register("activate", onActivate)
    else
        mwse.log("Immersive Tables are disabled")
    end
end

event.register("initialized", onInitialized)