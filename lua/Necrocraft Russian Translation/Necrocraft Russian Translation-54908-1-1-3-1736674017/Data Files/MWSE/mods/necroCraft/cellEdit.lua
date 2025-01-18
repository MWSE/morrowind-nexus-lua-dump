local utility = require("NecroCraft.utility")

local this = {}

this.ashpitWhitelist = {
    ["Ald Redaynia, Tower"] = true,
    ["Serynthul, Infirmary"] = true,
    ["Tur Julan, Crossing of Wings: Waiting Door"] = true,
    ["Roa Dyr, Crossing of Lamps"] = true,
    ["Maar Gan, Outpost"] = true,
    ['Molag Mar, Canalworks'] = true,
    ["Vivec, High Fane"] = true,
    ["Vivec, Redoran Ancestral Vaults"] = true,
    ["Vivec, St. Olms Storage"] = true,
    ["Vivec, Telvanni Monster Lab"] = true,
    ["Vivec, The Abbey of St. Delyn the Wise"] = true,
    ["Vos, Vos Chapel"] = true,
    ["Mugan Crypt"] = true,
    ["Romithren Monastery"] = true,
    ["Ranyon-ruhn, Catacombs"] = true,
    ["Ranyon-ruhn, Catacombs: Inner Sanctum"] = true,
    ["Assurbalhet"] = true,
    ["Nebulud"] = true,
    ["Kur Grotto"] = true,
    ["Udai"] = true
}

this.ashpitBlacklist = {
    ["Vivec, Temple"] = true,
    ["Necrom, Waterfront"] = true,
}


local cellBooksReplacement = {
	["Dagon Fel, Sorkvild's Tower"] = {
		["bk_reflectionsoncultworship..."] = "nc_bk_skeleton_war",
		["bk_NGastaKvataKvakis_c"] = "nc_bk_corpse3",
		--"nc_bk_corpse2",
	},
	["Hanud, Tower"] = {
		["bk_truenatureoforcs"] = "nc_bk_skeleton_cr"
	},
	["Vas, Tower"] = {
		["bk_OverviewOfGodsAndWorship"] = "nc_bk_bonespider"
	},
	["Mawia"] = {
		["bk_reflectionsoncultworship..."] = "nc_bk_skeleton_ch",
		["bk_truenatureoforcs"] = "nc_bk_bonelord",
		["bk_onoblivion"] = "nc_bk_corpse2"
	},
	["Odirniran, Tower"] = {
		["Vivec and Mephala"] = "nc_bk_corpse1",
		["bk_truenatureoforcs"] = "nc_bk_bonelord"
	},
	["Shal"] = {
		["BookSkill_Alchemy3"] = "nc_bk_corpse2"
	},
	["Shara"] = {
		["bk_AnnotatedAnuad"] = "nc_bk_skeleton_war",
		["bk_ChangedOnes"] = "nc_bk_corpse1"
	},
	["Venim Ancestral Tomb"] = {
		["bk_darkestdarkness"] = "nc_bk_boneoverlord"
	},
    ["Dulandos, Living Quarters"] = {
        ["bk_corpsepreperation1_c"] = "nc_bk_skeleton_cr",
        ["bk_corpsepreperation2_c"] = "nc_bk_bonespider"
    },

    ["Dulandos, Ruined House"] = {
        ["bk_vivecandmephala"] = "nc_bk_corpse2"
    },

    ["Dulandos, Shrine"] = {
        ["bk_poisonsong5"] = "nc_bk_skeleton_war"
    },

    ["Dulandos, Vicarage"] = {
        ["bk_AedraAndDaedra"] = "nc_bk_boneoverlord"
    },

    ["Udai"] = {
        ["bk_corpsepreperation1_c"] = "nc_bk_skeleton_war"
    },

    ["Udai, Dome"] = {
        ["bk_reflectionsoncultworship..."] = "nc_bk_corpse3",
        ["bk_BookDawnAndDusk"] = "nc_bk_bonelord"
    },

    ["Wavebreaker Keep, Great Hall"] = {
        ["bk_NGastaKvataKvakis_o"] = "nc_bk_skeleton_ch"
    }

}

-- m//Text_Octavo_05.nif
-- OAAB//m//ab_octavo_03.nif
-- OAAB//m//ab_octavo_08.nif

this.replaceBooks = function(cell)


	local replacementBooks = cellBooksReplacement[cell.id]
	
	if not replacementBooks then 
		return 
	end
	if tes3.player.data.necroCraft.replacedBooksInCell[cell.id] then
		return
	end

	for oldBook in cell:iterateReferences(tes3.objectType.book) do
		-- if oldBook.object.mesh == "m\\Text_Octavo_05.nif" then
        local newBook = replacementBooks[oldBook.id]
        if newBook then
			newBook = utility.replace(oldBook, newBook, cell)
            replacementBooks[oldBook.id] = nil
		end
	end
	tes3.player.data.necroCraft.replacedBooksInCell[cell.id] = true
end

this.replaceAshpits = function(cell)

    -- if tes3.player.data.necroCraft.replacedInCell[cell.id] then return end
    if not this.ashpitWhitelist[cell.id] then 
        return 
    end

	local ashpit
	local ashpits = {
		["in_velothi_ashpit_01"] = "nc_ashpit_01",
		["in_velothi_ashpit_02"] = "nc_ashpit_02", 
		["in_redoran_ashpit_01"] = "nc_ashpit_r_01", 
		["in_redoran_ashpit_02"] = "nc_ashpit_r_02",
		["ex_vivec_g_02"] = "nc_ashpit_g_02",
		["ex_vivec_g_r_02"] = "nc_ashpit_gr_02"

	}
	for ref in cell:iterateReferences(tes3.objectType.static) do
		ashpit = ashpits[ref.id]
		if ashpit then
            ashpit = utility.replace(ref, ashpit, cell)
			tes3.setOwner({
				reference = ashpit,
				owner = tes3.getFaction("Temple"),
				requiredRank = 8
			})
		end
	end
end

this.init = function()
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if not this.ashpitBlacklist[cell.id] then
            if string.find(cell.id, "Necrom") then
                this.ashpitWhitelist[cell.id] = true
            end
            if string.find(cell.id, " Temple") then
                this.ashpitWhitelist[cell.id] = true
            end
            if string.find(cell.id, " Tomb") then
                this.ashpitWhitelist[cell.id] = true
            end
            if string.find(cell.id, "Vivec") and string.find(cell.id, "Canalworks") then
                this.ashpitWhitelist[cell.id] = true
            end
        end
    end
end

return this