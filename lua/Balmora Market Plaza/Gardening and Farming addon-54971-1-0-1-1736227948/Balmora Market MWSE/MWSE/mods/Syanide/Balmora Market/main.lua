local function checkModsAndAddItems()
    local marketBalmoraActive = tes3.isModActive("MarketBalmora.esp")
    local gardeningAndFarmingActive = tes3.isModActive("GardeningandFarming.esp")

    if marketBalmoraActive and gardeningAndFarmingActive then
        mwse.log("Both MarketBalmora.esp and GardeningandFarming.esp are active. Adding items to 'He-Who-Collects'.")

        local function addItemToNPC()
            local npc = tes3.getReference("1farmer")
            if npc then
                
                if tes3.getItemCount({ reference = npc, item = "trib_marshmerrow_seed_01" }) < 5 then
                    tes3.addItem({ reference = npc, item = "trib_marshmerrow_seed_01", count = 5 - tes3.getItemCount({ reference = npc, item = "trib_marshmerrow_seed_01" }) })
                end
                if tes3.getItemCount({ reference = npc, item = "trib_comberry_seed_01" }) < 5 then
                    tes3.addItem({ reference = npc, item = "trib_comberry_seed_01", count = 5 - tes3.getItemCount({ reference = npc, item = "trib_marshmerrow_seed_01" }) })
                end
                if tes3.getItemCount({ reference = npc, item = "trib_saltrice_seed_01" }) < 5 then
                    tes3.addItem({ reference = npc, item = "trib_saltrice_seed_01", count = 5 - tes3.getItemCount({ reference = npc, item = "trib_marshmerrow_seed_01" }) })
                end
            else
                mwse.log("NPC 'He-Who-Collects' not found!")
            end
        end

        addItemToNPC()
    else
        mwse.log("Required mods are not active.")
    end
end

mwse.log("[Balmora Market] Initialized")

event.register("loaded", checkModsAndAddItems)