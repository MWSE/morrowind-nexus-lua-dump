--[[
Format for Mods:
- ID can be for any soundID, mesh filepath, or texture filepath. Must be lowercase (CSO accounts for this using ':lower()', but better to be safe).
- Land uses texture path, items use .nif path.
- Category hooks into the tables above, so the first value will be the name of the desired table, and the second the desired value within it.
    Anything getting added to ignoreList must have an empty category of: ""
    Anything getting added to corpseMapping must have a category of: "Body"
- Define your soundType so it's properly sorted, for instance 'soundType = land' to specify texture material type.
- Typically the only objects you need to add to the ignoreList are those with large bounding boxes that might be picked up instead of the terrain, such as the Vivec bridge banners.

ADDITIONALLY:
- As of 2.0, CSO covers magic sounds, including a framework for custom sounds per spell effect, including failure sounds (hardcoded in the CS).
- If you'd like custom spell effect sounds, simply follow the file structure in 'sound\CSO\effects\' for each spell ID you're working with.
- Spell IDs can be referenced here: https://mwse.github.io/MWSE/references/magic-effects/
--]]

local cso = include("Character Sound Overhaul.interop")
event.register(tes3.event.initialized, function()
    if cso then
        local soundData = {
            -- Land, Carpet:
            --{ id = "oaab\\ab_rug_small_06", category = cso.landTypes.carpet, soundType = "land" },
	    	--{ id = "oaab\\canvaswrapseamless", category = cso.landTypes.carpet, soundType = "land" },
	    	--{ id = "oaab\\canvaswrap_dk", category = cso.landTypes.carpet, soundType = "land" },
            --{ id = "oaab\\fabric_burgundy_01", category = cso.landTypes.carpet, soundType = "land" },
            --{ id = "oaab\\fabricDeskGreen", category = cso.landTypes.carpet, soundType = "land" },

            -- Land, Dirt:
            --{ id = "oaab\\corpseburnedatlas", category = cso.landTypes.dirt, soundType = "land" },

            -- Land, Grass:
            --{ id = "oaab\\ab_straw_01", category = cso.landTypes.grass, soundType = "land" },

            -- Land, Gravel:
            --{ id = "oaab\\rem\\mv\\tx_mv_ground_04", category = cso.landTypes.gravel, soundType = "land" },

            -- Land, Ice:
            --{ id = "oaab\\skelpiletexture", category = cso.landTypes.ice, soundType = "land" },

            -- Land, Metal:
            --{ id = "oaab\\dr_tbl_staff_01", category = cso.landTypes.metal, soundType = "land" },

            -- Land, Mud:
            --{ id = "oaab\\corpsefreshatlas", category = cso.landTypes.mud, soundType = "land" },

	    	-- Land, Sand:
        
	    	-- Land, Snow:

            -- Land, Stone:
            --{ id = "oaab\\rem\\mv\\tx_mv_ground_01", category = cso.landTypes.stone, soundType = "land" },

            -- Land, Water:
            --{ id = "oaab\\dr_tx_blood_512x", category = cso.landTypes.water, soundType = "land" },

            -- Land, Wood:
            --{ id = "oaab\\rem\\mv\\tx_mv_bark_01", category = cso.landTypes.wood, soundType = "land" },

            -- Items, Book:
            --{ id = "oaab\\m\\bk_ruined_folio.nif", category = cso.itemTypes.book, soundType = "item" },

            -- Items, Clothing:
           --{ id = "oaab\\m\\misc_cloth_01a.nif", category = cso.itemTypes.clothing, soundType = "item" },,

            -- Items, Gold:
            --{ id = "oaab\\m\\dram_001.nif", category = cso.itemTypes.gold, soundType = "item" },

            -- Items, Gems:
            --{ id = "oaab\\n\\soulgem_black.nif", category = cso.itemTypes.gems, soundType = "item" },
        
	    	-- Items, Generic:
        
	    	-- Items, Ingredient:

            -- Items, Lockpicks/Keys
            --{ id = "oaab\\m\\misc_keyring.nif", category = cso.itemTypes.lockpick, soundType = "item" },
        
	    	-- Items, Jewelry:

            -- Items, Repair:
            --{ id = "oaab\\m\\dwrvtoolclamp.nif", category = cso.itemTypes.repair, soundType = "item" },

            -- Items, Scrolls:
            --{ id = "oaab\\m\\crumpledpaper.nif", category = cso.itemTypes.scrolls, soundType = "item" },

            -- Corpse Containers:
            --{ id = "oaab\\o\\corpse_arg_01.nif", category = cso.specialTypes.body, soundType = "corpse" },

            -- Creatures (For corpse containers and impact sounds - Only 'ghost' or 'metal', skeletons are detected based on creature type)
            --{ id = "oaab\\r\\dwspecter_f.nif", category = cso.specialTypes.ghost, soundType = "creature" },

        }

        for _,data in ipairs(soundData) do
            cso.addSoundData(data.id, data.category, data.soundType)
        end
    end
end)    