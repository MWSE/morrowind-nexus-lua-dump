local SkillsModule = include("SkillsModule")
if not SkillsModule then return end

local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

local ashfall = include("mer.ashfall.interop")

if not tes3.isModActive("ScrollCrafting.ESP") then
    return
end

--New Skills (Using Skills Module)
local skill = SkillsModule.registerSkill{
    id = "scrollCrafting",
    name = "Scrollcrafting",
    description = "The scrollcrafting skill determines how well you can inscribe magic scrolls.",
    value = 10,
    icon = "icons/SCF/inkwell.dds",
    }

  SkillsModule.registerBaseModifier{
        id = "dictionary",
        skill = "scrollCrafting",
        callback = function()
            local hasDictionary = tes3.getItemCount(
            { reference = tes3.player, 
            item = "SCF_dictionary" })
            if hasDictionary >= 1 then
                return 25
            end
        end
    }

    SkillsModule.registerBaseModifier{
        id = "inscribing_stand",
        skill = "scrollCrafting",
        callback = function()
            local hasStand = tes3.getItemCount(
            { reference = tes3.player, 
            item = "SCF_scribe_2" })
            if hasStand >= 1 then
                return 10
            end
        end
    }

local materials = {
    {
        id = "leather",
        name = "Leather",
        ids = {
            "ashfall_leather",
            "ingred_netch_leather_01",
            "ingred_boar_leather"
        }
    },
    {
        id = "inkwell",
        name = "Inkwell",
        ids = {
            "Misc_Inkwell",
            "T_Bre_RedGlassInkwell_01",
            "T_De_BluewareInkwell01",
            "T_De_EbonyInkwell_01",
            "T_Rga_Inkwell_01",
            "SCF_inkwell"
        }
    },

}
CraftingFramework.Material:registerMaterials(materials)

CraftingFramework.Tool:new{
    id = "imbuedQuill",
    name = "Imbued Quill",
    ids = {
        "SCF_imbued_quill"
    }
}



local scroll_recipes = {
    { 
        id = "rec_imbued_quill",
        craftableId = "SCF_imbued_quill",
        description = "A Quill imbued with the heartsblood of a daedra, a necessary tool for the crafting of scrolls.",
        materials = {
            { material = "Misc_Quill", count = 1 },
            { material = "ingred_daedras_heart_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Tool"

    },
    { 
        id = "rec_alteration_ink",
        craftableId = "SCF_ink_a",
        description = "Vials of ink imbued with ground sapphire, necessary for inscribing alteration effects on scrolls.",
        materials = {
            { material = "inkwell", count = 1 },
            { material = "T_IngMine_Sapphire_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Ink",
        resultAmount = 10
    },
    { 
        id = "rec_conjuration_ink",
        craftableId = "SCF_ink_c",
        description = "Vials of ink imbued with void salts, necessary for inscribing conjuration effects on scrolls.",
        materials = {
            { material = "inkwell", count = 1 },
            { material = "ingred_void_salts_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Ink",
        resultAmount = 10

    },
    { 
        id = "rec_destruction_ink",
        craftableId = "SCF_ink_d",
        description = "Vials of ink imbued with fire salts, necessary for inscribing destruction effects on scrolls.",
        materials = {
            { material = "inkwell", count = 1 },
            { material = "ingred_fire_salts_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Ink",
        resultAmount = 10

    },
    { 
        id = "rec_illusion_ink",
        craftableId = "SCF_ink_i",
        description = "Vials of ink imbued with ground emerald, necessary for inscribing illusion effects on scrolls.",
        materials = {
            { material = "inkwell", count = 1 },
            { material = "ingred_emerald_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Ink",
        resultAmount = 10

    },
    { 
        id = "rec_mysticism_ink",
        craftableId = "SCF_ink_m",
        description = "Vials of ink imbued with ground ruby, necessary for inscribing mysticism effects on scrolls.",
        materials = {
            { material = "inkwell", count = 1 },
            { material = "ingred_ruby_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Ink",
        resultAmount = 10

    },
    { 
        id = "rec_restoration_ink",
        craftableId = "SCF_ink_r",
        description = "Vials of ink imbued with frost salts, necessary for inscribing restoration effects on scrolls.",
        materials = {
            { material = "inkwell", count = 1 },
            { material = "ingred_frost_salts_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Ink",
        resultAmount = 10

    },
    { 
        id = "rec_parchment",
        craftableId = "SCF_parchment",
        description = "Parchment made of scraped leather and ground pearls, necessary for making scrolls.",
        materials = {
            { material = "leather", count = 2 },
            {material ="ingred_pearl_01", count = 1}
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Material",
        resultAmount = 4
    },
    { 
        id = "rec_parchment_sc",
        craftableId = "SCF_daedric_p",
        description = "Parchment made of the skin of daedra, due to its magical nature, other ingrediens are unnecessary.",
        materials = {
            { material = "ingred_scamp_skin_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Material",
        resultAmount = 2
    },
    { 
        id = "rec_parchment_sc",
        craftableId = "SCF_daedric_p",
        description = "Parchment made of the skin of daedra, due to its magical nature, other ingrediens are unnecessary.",
        materials = {
            { material = "ingred_daedra_skin_01", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Material",
        resultAmount = 10
    },
    { 
        id = "rec_empty_scroll",
        craftableId = "SCF_empty",
        description = "A scroll crafted specifically to be inscribed for the crafting of spellscrolls.",
        materials = {
            { material = "SCF_parchment", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Material",
        resultAmount = 2
    },
    { 
        id = "rec_empty_scroll_d",
        craftableId = "SCF_empty",
        description = "A scroll crafted specifically to be inscribed for the crafting of spellscrolls.",
        materials = {
            { material = "SCF_daedric_p", count = 1 },
        },
        timeTaken = 0.25,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },  
        category = "Material",
        resultAmount = 4
    },
   
    --scrolls at skill level 10
    { 
        id = "rec_almsivi",
        craftableId = "sc_almsiviintervention",
        description = "A scroll of almsivi intervention: teleports you to the nearest temple.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },

        { 
        id = "rec_divine",
        craftableId = "sc_divineintervention",
        description = "A scroll of divine intervention: teleports you to the nearest imperial shrine.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_daydene",
        craftableId = "sc_daydenespanacea",
        description = "A scroll of daydene's panacea: cures common diseases.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_reynos",
        craftableId = "sc_reynosbeastfinder",
        description = "A scroll of reynos' beastfinder: detects creatures.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_grey_despair",
        craftableId = "sc_greydespair",
        description = "A scroll of grey despair: drains an enemy's willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_grey_fate",
        craftableId = "sc_greyfate",
        description = "A scroll of grey fate: drains an enemy's luck.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_grey_mind",
        craftableId = "sc_greymind",
        description = "A scroll of grey mind: drains an enemy's intelligence.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_grey_scorn",
        craftableId = "sc_greyscorn",
        description = "A scroll of grey scorn: drains an enemy's personality.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_grey_sloth",
        craftableId = "sc_greysloth",
        description = "A scroll of grey sloth: drains an enemy's agility.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_grey_weakness",
        craftableId = "sc_greyweakness",
        description = "A scroll of grey weakness: drains an enemy's strength.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_bloodfire",
        craftableId = "sc_bloodfire",
        description = "A scroll of bloodfire: restores your fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_healing",
        craftableId = "sc_healing",
        description = "A scroll of healing: restores your health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        timeTaken = 1,
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_first_barrier",
        craftableId = "sc_firstbarrier",
        description = "A scroll of the first barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 5 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_second_barrier",
        craftableId = "sc_secondbarrier",
        description = "A scroll of the second barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_summon_skel",
        craftableId = "sc_summonskeletalservant",
        description = "A scroll of the summon skeleton: summons a skeleton under your control.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"

    },
    { 
        id = "rec_flamebane",
        craftableId = "sc_flamebane",
        description = "A scroll of flamebane: weakens an enemy to fire.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_frostbane",
        craftableId = "sc_frostbane",
        description = "A scroll of frostbane: weakens an enemy to cold.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_shockbane",
        craftableId = "sc_shockbane",
        description = "A scroll of shockbane: weakens an enemy to lightning.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_brightball",
        craftableId = "sc_princeovsbrightball",
        description = "A scroll of prince ov's brightbal: creates a light on your person.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },

    --scrolls at skill level 25
    { 
        id = "rec_red_despair",
        craftableId = "sc_reddespair",
        description = "A scroll of red despair: absorbs your enemy's willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_red_fate",
        craftableId = "sc_redfate",
        description = "A scroll of red fate: absorbs your enemy's luck.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_red_mind",
        craftableId = "sc_redmind",
        description = "A scroll of red mind: absorbs your enemy's intelligence.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_red_scorn",
        craftableId = "sc_redscorn",
        description = "A scroll of red scorn: absorbs your enemy's personality.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_red_sloth",
        craftableId = "sc_redsloth",
        description = "A scroll of red sloth: absorbs your enemy's agility.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_red_weakness",
        craftableId = "sc_redweakness",
        description = "A scroll of red weakness: absorbs your enemy's strength.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_red_death",
        craftableId = "sc_reddeath",
        description = "A scroll of red desdeathpair: absorbs your enemy's health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_manarape",
        craftableId = "sc_manarape",
        description = "A scroll of manarape: absorbs your enemy's willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_elevram_sty",
        craftableId = "sc_elevramssty",
        description = "A scroll of elevram's sty: blinds your enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_fader",
        craftableId = "sc_fadersleadenflesh",
        description = "A scroll of fader's leaden flesh: burdens your enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_dedres_eye",
        craftableId = "sc_dedresmasterfuleye",
        description = "A scroll of dedres' masterful eye: calms a creature.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_didalas_knack",
        craftableId = "sc_didalasknack",
        description = "A scroll of didala's knack: charms someone.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_lesser_dom",
        craftableId = "sc_lesserdomination",
        description = "A scroll of lesser domination: controls a person or creature.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"

    },
    { 
        id = "rec_daerir_mir",
        craftableId = "sc_daerirsmiracle",
        description = "A scroll of daerir's miracle: cures your blight disease.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },

    { 
        id = "rec_mage_eye",
        craftableId = "sc_mageseye",
        description = "A scroll of mage's eye: detects enchantments.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_tevral",
        craftableId = "sc_tevralshawkshaw",
        description = "A scroll of tevral's hawkshaw: detects keys.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_radrene",
        craftableId = "sc_radrenesspellbreaker",
        description = "A scroll of radrene's spellbreaker: dispels magical effects on you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_grey_death",
        craftableId = "sc_greydeath",
        description = "A scroll of grey death: drains an enemy's health",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_taldam_scorcher",
        craftableId = "sc_taldamsscorcher",
        description = "A scroll of taldam's scorcher: does fire damage to an enemy",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_fiery_Ward",
        craftableId = "sc_selisfieryward",
        description = "A scroll of selis' fiery ward: creates a fire shield",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_mageweal",
        craftableId = "sc_mageweal",
        description = "A scroll of mageweal: fortifies your magicka.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_gonars_goad",
        craftableId = "sc_gonarsgoad",
        description = "A scroll of gonar's goad: frenzies a creature.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_mondens_inst",
        craftableId = "sc_mondensinstigator",
        description = "A scroll of monden's instigator: frenzies a humanoid.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_winter_guest",
        craftableId = "sc_drathiswinterguest",
        description = "A scroll of drathis' winter guest: does frost damage to an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_icy_mask",
        craftableId = "sc_radiyasicymask",
        description = "A scroll of radiya's icy mask: creates a frost shield.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_stormward",
        craftableId = "sc_stormward",
        description = "A scroll of stormward: creates a lightning shield.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_galmes_seal",
        craftableId = "sc_galmsesseal",
        description = "A scroll of galmes' seal: locks something.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_mark",
        craftableId = "sc_mark",
        description = "A scroll of mark: marks a location for later recall.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_glowing_eye",
        craftableId = "sc_llirosglowingeye",
        description = "A scroll of Lliros'Glowing Eye: lets you see in the dark.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_ondusi",
        craftableId = "sc_ondusisunhinging",
        description = "A scroll of Ondusi's Unhinging: opens a lock.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_abiding_beast",
        craftableId = "sc_toususabidingbeast",
        description = "A scroll of Tousu's Abiding Beast: rallies a creature.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_telvins_courage",
        craftableId = "sc_telvinscourage",
        description = "A scroll of Telvin's Courage: rallies a humanoid.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_leaguestep",
        craftableId = "sc_leaguestep",
        description = "A scroll of Leaguestep: recalls to a marked location.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_vigor",
        craftableId = "sc_vigor",
        description = "A scroll of vigor: restores your fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_vitality",
        craftableId = "sc_vitality",
        description = "A scroll of vitality: restores your health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_third_barrier",
        craftableId = "sc_thirdbarrier",
        description = "A scroll of the third barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_fourth_barrier",
        craftableId = "sc_fourthbarrier",
        description = "A scroll of the fourth barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 }, --rebalancing adjustment
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_inas_chastening",
        craftableId = "sc_inaschastening",
        description = "A scroll of inas' chastening: does lightning damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_gem_feeder",
        craftableId = "sc_fphyggisgemfeeder",
        description = "A scroll of fphyggi's gem-feeder: traps souls.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_messenger",
        craftableId = "sc_messengerscroll",
        description = "A scroll of messenger: summons a scamp.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"

    },
    { 
        id = "rec_mystic_finger",
        craftableId = "sc_inasismysticfinger",
        description = "A scroll of inasi's mystic finger: lets you use telekinesis.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_mist_slippers",
        craftableId = "sc_selynsmistslippers",
        description = "A scroll of selyn's mist slippers: lets you walk on water.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },

    --skill 50 scrolls
    { 
        id = "rec_tevils_peace",
        craftableId = "sc_tevilspeace",
        description = "A scroll of Tevil's Peace: calms creatures and humanoids.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_vaerminas_promise",
        craftableId = "sc_vaerminaspromise",
        description = "A scroll of Vaermina's Promise: charms someone.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_salens_vivication",
        craftableId = "sc_salensvivication",
        description = "A scroll of Salen's Vivication: cures disease, paralysis and poison.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_daerirs_blessing",
        craftableId = "sc_cureblight_ranged",
        description = "A scroll of Daerir's Blessing: cures blight disease on someone else.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_black_despair",
        craftableId = "sc_blackdespair",
        description = "A scroll of Black Despair: damages an enemy's willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_black_fate",
        craftableId = "sc_blackfate",
        description = "A scroll of Black Fate: damages an enemy's luck.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_black_mind",
        craftableId = "sc_blackmind",
        description = "A scroll of Black Mind: damages an enemy's intelligence.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_black_scorn",
        craftableId = "sc_blackscorn",
        description = "A scroll of Black Scorn: damages an enemy's personality.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_black_sloth",
        craftableId = "sc_blacksloth",
        description = "A scroll of Black Sloth: damages an enemy's agility.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_black_weakness",
        craftableId = "sc_blackweakness",
        description = "A scroll of Black weakness: damages an enemy's strength.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_black_death",
        craftableId = "sc_blackdeath",
        description = "A scroll of Black Death: damages an enemy's health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_alvusias_warping",
        craftableId = "sc_alvusiaswarping",
        description = "A scroll of Alvusia's Warping: dispels magic on someone else.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_ulm_feather",
        craftableId = "sc_ulmjuicedasfeather",
        description = "A scroll of Ulm Juceda Feather: lightens the load you carry.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_elemntalburst_fire",
        craftableId = "sc_elementalburstfire",
        description = "A scroll of Elemental Burst Fire: does fire damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_dawn_sprite",
        craftableId = "sc_dawnsprite",
        description = "A scroll of The Dawnsprite: fortifies your agility.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_insight",
        craftableId = "sc_insight",
        description = "A scroll of Insight: fortifies your intelligence.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    
    { 
        id = "rec_gamblers_prayer",
        craftableId = "sc_gamblersprayer",
        description = "A scroll of The Gambler's Prayer: fortifies your luck.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_heartwise",
        craftableId = "sc_heartwise",
        description = "A scroll of Heartwise: fortifies your personality.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_celerity",
        craftableId = "sc_celerity",
        description = "A scroll of Celerity: fortifies your speed.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_savage_might",
        craftableId = "sc_savagemight",
        description = "A scroll of Savage Might: fortifies your strength.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_oathfast",
        craftableId = "sc_oathfast",
        description = "A scroll of The Oathfast: fortifies your willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_elemental_frost",
        craftableId = "sc_elementalburstfrost",
        description = "A scroll of Elemental Burst Frost: does cold damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_brevas_eyes",
        craftableId = "sc_brevasavertedeyes",
        description = "A scroll of Breva's Averted Eyes: makes you invisible.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_invisibility",
        craftableId = "sc_invisibility",
        description = "A scroll of Invisibility: makes you invisible.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_tinurs_hoptoad",
        craftableId = "sc_tinurshoptoad",
        description = "A scroll of Tinur's Hoptoad: lets you jump higher and slows your fall.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_sertis_porphyry",
        craftableId = "sc_sertisesporphyry",
        description = "A scroll of Sertises' Porphyry: paralyzes your enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_tranasas_spelltrap",
        craftableId = "sc_tranasasspelltrap",
        description = "A scroll of Tranasa's Spelltrap: reflects magic back to the caster.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_tranasas_spelltwist",
        craftableId = "sc_tranasasspelltwist",
        description = "A scroll of Tranasa's Spelltwist: reflects magic back to the caster.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_flameguard",
        craftableId = "sc_flameguard",
        description = "A scroll of Flameguard: lets you resist fire.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_frostguard",
        craftableId = "sc_frostguard",
        description = "A scroll of Frostguard: lets you resist cold.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_shockguard",
        craftableId = "sc_shockguard",
        description = "A scroll of Shockguard: lets you resist lightning.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_restoration",
        craftableId = "sc_restoration",
        description = "A scroll of Restoration: restores your health, magicka and fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"

    },
    { 
        id = "rec_fifth_barrier",
        craftableId = "sc_fifthbarrier",
        description = "A scroll of the Fifth Barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },--rebalancing adjustment
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },
    { 
        id = "rec_elemental_shock",
        craftableId = "sc_elementalburstshock",
        description = "A scroll of Elemental Burst Shock: does lightning damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"

    },
    { 
        id = "rec_nerusis_lockjaw",
        craftableId = "sc_nerusislockjaw",
        description = "A scroll of Nerusi's Lockjaw: silences your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"

    },
    { 
        id = "rec_tranasa_spellmire",
        craftableId = "sc_tranasasspellmire",
        description = "A scroll of Tranasa's Spellmire: lets you absorb magic.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"

    },
    { 
        id = "rec_flame_atronach",
        craftableId = "sc_summonflameatronach",
        description = "A scroll of Summon Flame Atronach: summons a flame atronach.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"

    },
    { 
        id = "rec_frost_atronach",
        craftableId = "sc_summonfrostatronach",
        description = "A scroll of Summon Frost Atronach: summons a frost atronach.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"

    },
    { 
        id = "rec_airy_bubble",
        craftableId = "sc_daynarsairybubble",
        description = "A scroll of Daynar's Airy Bubble: lets you breathe water.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"

    },



    --skill level 75 
    { 
        id = "rec_black_storm",
        craftableId = "sc_blackstorm",
        description = "A scroll of The Black Storm: damages an enemy's magicka and does lightning damage.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_blood_thief",
        craftableId = "sc_bloodthief",
        description = "A scroll of The Blood Thief: absorbs an enemy's agility, endurance, speed and strength.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 4 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"
    },
    { 
        id = "rec_mind_feeder",
        craftableId = "sc_mindfeeder",
        description = "A scroll of The Mind Feeder: absorbs an enemy's intelligence, luck, willpower and personality.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 4 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"
    },
    { 
        id = "rec_greater_dom",
        craftableId = "sc_greaterdomination",
        description = "A scroll of Greater Domination: lets you control creatures and humanoids.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_drathis_soulrot",
        craftableId = "sc_drathissoulrot",
        description = "A scroll of Drathis' Soulrot: pralyzes an enemy, does poison damage and damages endurance and willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_corrupt_aracnix",
        craftableId = "sc_corruptarcanix",
        description = "A scroll of Corrupt Arcanix: dispels magical effects.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"
    },
    { 
        id = "rec_fiercly_roasting",
        craftableId = "sc_FiercelyRoastThyEnemy_unique",
        description = "A scroll of Fiercly Roasting: does fire damage in a massive area.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_hellfire",
        craftableId = "sc_hellfire",
        description = "A scroll of Hellfire: does fire damage to your enemies and weakens them to fire.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_sixth_barrier",
        craftableId = "sc_sixthbarrier",
        description = "A scroll of The Sixth Barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },--rebalancing adjustment
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_warriors_blessing",
        craftableId = "sc_warriorsblessing",
        description = "A scroll of The Warrior's Blessing: restores your health and fatigue, and fortifies your attack.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_illneas_breath",
        craftableId = "sc_illneasbreath",
        description = "A scroll of Illnea's Breath: paralyzes and does frost damage to an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_argent_glow",
        craftableId = "sc_argentglow",
        description = "A scroll of Argent Glow: restores your health, magicka and fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_reynos_fins",
        craftableId = "sc_reynosfins",
        description = "A scroll of Reynos' Fins: lets you breathe water and swim quickly.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },

    --level 100 skill
    { 
        id = "rec_baleful_suffering",
        craftableId = "sc_balefulsuffering",
        description = "A scroll of Baleful Suffering: blinds, burdens and demoralizes your enemy, and disintegrates their weapons and armor.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_i", count = 3 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_lord_mhas",
        craftableId = "sc_lordmhasvengeance",
        description = "A scroll of Lord Mhas' Vengeance: binds a suite of armer and a battle axe.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 6 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_supreme_dom",
        craftableId = "sc_supremedomination",
        description = "A scroll of Supreme Domination: controls creatures and humanoids.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_windform",
        craftableId = "sc_windform",
        description = "A scroll of Windform: lets you fly invisibly.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_windwalker",
        craftableId = "sc_windwalker",
        description = "A scroll of Windwalker: lets you fly invisibly.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_ekash",
        craftableId = "sc_ekashslocksplitter",
        description = "A scroll of Ekash's Locksplitter: opens locks.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_golden_saint",
        craftableId = "sc_summongoldensaint",
        description = "A scroll of Summon Golden Saint: summmons a golden saint.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_milyn_farm",
        craftableId = "sc_summondaedroth_hto",
        description = "A Milyn Faram's Scroll: summmons a daedroth.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_psychic_prison",
        craftableId = "sc_psychicprison",
        description = "A scroll of Psychic Prison: paralyzes and soultraps a target.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_ninth_barrier",
        craftableId = "sc_ninthbarrier",
        description = "A scroll of The Ninth Barrier: shields you and protects you from fire cold and lightning, but also poisons you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_r", count = 3 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_purity_body",
        craftableId = "sc_purityofbody",
        description = "A Scroll of Purity of Body: cures common and blight disease and restores health and fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 4 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    ---TD recipes
    { 
        id = "rec_celestial_ben",
        craftableId = "T_EnSc_Ayl_Blessed",
        description = "A Scroll of Celstial Benediction: restores health and fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_subterrane_ax",
        craftableId = "T_EnSc_Ayl_CavernsOfTruth",
        description = "A Scroll of Subterrene Axioms: creates a ligh on you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_distracting_clam",
        craftableId = "T_EnSc_Com_DistractingClamor",
        description = "A Scroll of Distracting Clamor: makes your enemies hear a loud noise.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_ephemeral_light",
        craftableId = "T_EnSc_Com_EphemeralLight",
        description = "A Scroll of Ephemeral Light: briefly cast a bright light on someone else.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_ephemeral_lucidity",
        craftableId = "T_EnSc_Com_EphemeralLucidity",
        description = "A Scroll of Ephemeral Lucidity: briefly cast a bright light on you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_galmes_latch",
        craftableId = "T_EnSc_Com_GalmesLatch",
        description = "A Scroll of Galmes' Latch: locks something.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_makkuns_hand",
        craftableId = "T_EnSc_Com_MakkunsHeavyHand",
        description = "A Scroll of Makkun's Heavy Hand: makes someone's load heavier.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_thunderous_pain",
        craftableId = "T_EnSc_Com_ThunderousPain",
        description = "A Scroll of Thunderous Pain: does lightning damage to an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_helokis_unlocking",
        craftableId = "T_EnSc_Nor_HelokisUnlocking",
        description = "A Scroll of Helokis Unlocking: unlocks something.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_kynes_whisper",
        craftableId = "T_EnSc_Nor_KynesWhisper",
        description = "A Scroll of Kynes Whisper: lets you detect animals.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"
    },
    { 
        id = "rec_raven_eye",
        craftableId = "T_EnSc_Nor_RavenEye",
        description = "A Scroll of Raven Eye: lets you see in the dark.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },

    ---TD level 25 skill
    { 
        id = "rec_alet_wave",
        craftableId = "T_EnSc_Ayl_FoamingWave1",
        description = "A Scroll of Alate Wave: lets you charm someone.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_invalidation",
        craftableId = "T_EnSc_Ayl_Destroyed",
        description = "A Scroll of Invalidation: damages an enemy's health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_lucent_prov",
        craftableId = "T_EnSc_Ayl_FromLight",
        description = "A Scroll of Lucent Provenance: does fire damage to an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_spurred_inc",
        craftableId = "T_EnSc_Ayl_DaedricHerald1",
        description = "A Scroll of Spurred Incomers: summons a clannfear.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_alvunc_ice",
        craftableId = "T_EnSc_Com_AlvhunsIcicle",
        description = "A Scroll of Alvhun's Icicle: does cold damage to an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_didals_rad",
        craftableId = "T_EnSc_Com_DidalasRadiance",
        description = "A Scroll of Didala's Radiance: charms someone.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_inas_flash",
        craftableId = "T_EnSc_Com_FuriousFlash",
        description = "A Scroll of Inas'Furious Flash: does fire damage to an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_inner_lum",
        craftableId = "T_EnSc_Com_InnerLuminescence",
        description = "A Scroll of Inner Luminescence: lets you see in the dark.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_last_light",
        craftableId = "T_EnSc_Com_LastingLight",
        description = "A Scroll of Lasting Light: lets you cast a bright light on someone.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_last_luc",
        craftableId = "T_EnSc_Com_LastingLucidity",
        description = "A Scroll of Lasting Lucidity: lets you cast a bright light on yourself.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_mepp_mism",
        craftableId = "T_EnSc_Com_MeppsMismending",
        description = "A Scroll of Mepp's Mismending: heals someone, but also damages their health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_siniths_wasp",
        craftableId = "T_EnSc_Com_SinithsWasp",
        description = "A Scroll of Sinith's Wasp: poisons an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_stilges_hubris",
        craftableId = "T_EnSc_Com_StilgesHubris",
        description = "A Scroll of Stilge's Hubris: fortifies your magicka.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_falling_barrier",
        craftableId = "T_EnSc_Com_FallingBarrier",
        description = "A Scroll of Falling Barrier: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 10, maxProgress = 60 },--Rebalance
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_inner_sun",
        craftableId = "T_EnSc_Com_InnerPaleSun",
        description = "A Scroll of Inner Pale Sun: fortifies your fatigue and hand-to-hand skill and lets you see in the dark.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 2 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_venomous_sting",
        craftableId = "T_EnSc_Com_VenomousSting",
        description = "A Scroll of Venomous Sting: poisons an enemy.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_deafening_hue",
        craftableId = "T_EnSc_Nor_DeafeningHue",
        description = "A Scroll of Deafening Hue: distracts someone with loud noises.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_greater_raven",
        craftableId = "T_EnSc_Nor_RavenEyeGreater",
        description = "A Scroll of Greater Raven Eye: lets you see in the dark.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_jhunals_interc",
        craftableId = "T_EnSc_Nor_JhunalsIntercession",
        description = "A Scroll of Jhunals Intercession: reflects magic back to the caster.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"
    },
    { 
        id = "rec_lorrods_rel",
        craftableId = "T_EnSc_Nor_LorrhodsRelease",
        description = "A Scroll of Lorrhods Release: dispels magic on yourself.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Mysticism Scroll"
    },
    { 
        id = "rec_malign_presence",
        craftableId = "T_EnSc_Nor_MalignPresence",
        description = "A Scroll of Malign Presence: summons an ancestral ghost and drains an enemy's health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 25, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    ---TD 50 skill
    { 
        id = "rec_base_philosophies",
        craftableId = "T_EnSc_Ayl_Wisdom1",
        description = "A Scroll of Base Philosophies: restores your agility, strength, luck and willpower.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 4 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_deific_function",
        craftableId = "T_EnSc_Ayl_GodlyPower1",
        description = "A Scroll of Deific Function: controls a humanoid.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_erudite_philosophies",
        craftableId = "T_EnSc_Ayl_Wisdom2",
        description = "A Scroll of Erudite Philosophies: restores your endurance, intelligence, personality and speed.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 4 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_exeptions",
        craftableId = "T_EnSc_Ayl_LoreArmor2",
        description = "A Scroll of Exeptions: lets you resist normal weapons.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_muted_proverbs",
        craftableId = "T_EnSc_Ayl_GodlyPower2",
        description = "A Scroll of Muted Proverbs: lets you demoralize a humanoid.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_tacit_ingress",
        craftableId = "T_EnSc_Ayl_Enter",
        description = "A Scroll of Tacit Ingress: lets you open a lock.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_alvins_bearer",
        craftableId = "T_EnSc_Com_AlvemsBurdenBearer",
        description = "A Scroll of Alvem's Burden Bearer: lightens the load you carry.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_candles",
        craftableId = "T_EnSc_Dae_Candles",
        description = "A Scroll of Candles: briefly summons two flame atronachs and does fire damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 2 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_deadly_attrition",
        craftableId = "T_EnSc_Com_DeadlyAttrition",
        description = "A Scroll of Deadly Attrition: damages you enemy's health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_didalas_splendor",
        craftableId = "T_EnSc_Com_DidalasSplendor",
        description = "A Scroll of Didala's Splendor: lets you charm someone.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_inas_touch",
        craftableId = "T_EnSc_Com_ElectricTouch",
        description = "A Scroll of Inas' Electric Touch: does lightning damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_jogdaals_ire",
        craftableId = "T_EnSc_Com_JogdaalsIre",
        description = "A Scroll of Jogdaal's Ire: does fire damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_lighthning_ball",
        craftableId = "T_EnSc_Com_LightningBall",
        description = "A Scroll of Lightning Ball: does fire and lightning damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_flaming_hand",
        craftableId = "T_EnSc_Com_FlamingHand",
        description = "A Scroll of The Flaming Hand: does fire damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_scorching_hand",
        craftableId = "T_EnSc_Com_ScorchingHand",
        description = "A Scroll of The Scorching Hand: does fire damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_springtails_leap",
        craftableId = "T_EnSc_Com_SpringTailLeap",
        description = "A Scroll of Springtail's Leap: lightens the load you carry and fortifies your athletics and acrobatics.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 2 },
            { material = "SCF_ink_a", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_trenchant_hand",
        craftableId = "T_EnSc_Com_TrenchantHand",
        description = "A Scroll of The Trenchant Hand: fortifies your attack.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_translucence",
        craftableId = "T_EnSc_Com_Translucence",
        description = "A Scroll of Translucence: lets you blend in with your surroundings.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_venomous_grasp",
        craftableId = "T_EnSc_Com_VenomousGrasp",
        description = "A Scroll of Venomous Grasp: lets you poison your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 3 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_winters_fangs",
        craftableId = "T_EnSc_Com_WintersFangs",
        description = "A Scroll of Winter's Fangs: does cold damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_wizards_awe",
        craftableId = "T_EnSc_Com_WizardsAwe",
        description = "A Scroll of Wizard's Awe: lets you silence your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Illusion Scroll"
    },
    { 
        id = "rec_garmands_guidance",
        craftableId = "T_EnSc_Nor_GarmjandsGuidance",
        description = "A Scroll of Garmand's Guidance: lets you control a creature.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_tergans_blaze",
        craftableId = "T_EnSc_Nor_TergansBlaze",
        description = "A Scroll of Tergan's Blaze: does fire damage to your enemies and destroys their armor.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_ysmirs_breath",
        craftableId = "T_EnSc_Nor_YsmirsBreath",
        description = "A Scroll of Ysmirs Breath: weakens an enemy to cold and does cold damge to them.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_trollish_health",
        craftableId = "T_EnSc_Nor_TrollishHealth",
        description = "A Scroll of Trollish Health: restores your health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 50, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    --TD 75 skill
    { 
        id = "rec_strange_incomers",
        craftableId = "T_EnSc_Ayl_DaedricHerald2",
        description = "A Scroll of Strange Incomers: summons a daedroth.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_dagons_door",
        craftableId = "T_EnSc_Com_SummonDremora",
        description = "A Scroll of Strange Incomers: summons a dremora.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_magnus_glare",
        craftableId = "T_EnSc_Com_MagnusGlare",
        description = "A Scroll of Magnus' Glare: does fire damage to an enemy and lights them up.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
            { material = "SCF_ink_i", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_starfall",
        craftableId = "T_EnSc_Com_Starfall",
        description = "A Scroll of Starfall: lets you absorb spells, fortifies your health and gives you a light.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_m", count = 1 },
            { material = "SCF_ink_i", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_tar_thief",
        craftableId = "T_EnSc_Com_TarThief",
        description = "A Scroll of The Tar Thief: summons a hunger.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
    { 
        id = "rec_winters_caress",
        craftableId = "T_EnSc_Com_WintersCaress",
        description = "A Scroll of Winter's Caress: does cold damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_borgjens_bloodfeast",
        craftableId = "T_EnSc_Nor_BorgjensBloodfeast",
        description = "A Scroll of Borgjen's Bloodfeast: summons a battleaxe and fortifies your strength and your health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
            { material = "SCF_ink_r", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_disasterous_visions",
        craftableId = "T_EnSc_Nor_DisastrousVisions",
        description = "A Scroll of Disasterous Visions: blinds an enemy and drains their agility and fatigue.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
            { material = "SCF_ink_d", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_dragon_breath",
        craftableId = "T_EnSc_Nor_DragonBreath",
        description = "A Scroll of Dragon Breath: does fire damage to your enemies.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_mountain_wind",
        craftableId = "T_EnSc_Nor_MountainWind",
        description = "A Scroll of Mountain Wind: paralyzes enemies and does cold damge to them.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_i", count = 1 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 75, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    --TD skill 100
    { 
        id = "rec_doctrine_panoply",
        craftableId = "T_EnSc_Ayl_LoreArmor1",
        description = "A Scroll of Doctrine Panoply: shields you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Alteration Scroll"
    },
    { 
        id = "rec_apogees",
        craftableId = "T_EnSc_Ayl_FoamingWave2",
        description = "A Scroll of the Apogees: fortifies your personality.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Restoration Scroll"
    },
    { 
        id = "rec_forbidden_dom",
        craftableId = "T_EnSc_Dae_ForbiddenDomination",
        description = "A Scroll of Forbidden Domination: lets you control a creature or humanoid, while doing poison damage to you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 2 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_seventh_barrier",
        craftableId = "T_EnSc_Com_SeventhBarrier",
        description = "A Scroll of The Seventh Barrier: shields you and lets you resist fire.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_r", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_eight_barrier",
        craftableId = "T_EnSc_Com_EighthBarrier",
        description = "A Scroll of The Eigth Barrier: shields you and lets you resist fire and cold.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_r", count = 2 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_fifth_pennants",
        craftableId = "T_EnSc_Dae_FifthPennant",
        description = "A Scroll of the Fifth Pennant: drains your enemy's health.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_d", count = 8 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Destruction Scroll"
    },
    { 
        id = "rec_tenth_barrier",
        craftableId = "T_EnSc_Com_TenthBarrier",
        description = "A Scroll of The Tenth Barrier: shields you and lets you resist magicka, but blinds, paralyzes and poisons you.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_a", count = 1 },
            { material = "SCF_ink_r", count = 1 },
            { material = "SCF_ink_i", count = 2 },
            { material = "SCF_ink_d", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Multiple-School Scroll"
    },
    { 
        id = "rec_twin_hours",
        craftableId = "T_EnSc_Com_TwinHours",
        description = "A Scroll of The Twin Hours: summons a winged twilight.",
        materials = {
            { material = "SCF_empty", count = 1 },
            { material = "SCF_ink_c", count = 1 },
        },
        timeTaken = 1,
        skillRequirements = {
            { skill = "scrollCrafting", requirement = 100, maxProgress = 60 },
        },
        toolRequirements = {
            {tool = "imbuedQuill", count = 1}
        },
        category = "Conjuration Scroll"
    },
   

}


--Ashfall integration
if ashfall then
local bushcraftingRecipes={
    {
        id = "rec_scribe_table",
        craftableId = "SCF_scribe",
        description = "A flat surface necessary for scrollcrafting",
        materials = {
            { material = "wood", count = 2}
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 10, maxProgress = 60}
        },
        category = "Scrollcrafting Items"
    },

    {
        id = "rec_quill",
        craftableId = "Misc_Quill",
        description = "A Quill Pen",
        materials = {
            { material = "ingred_racer_plumes_01", count = 1}
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 10, maxProgress = 60}
        },
        category = "Scrollcrafting Items"
    },
    {
        id = "rec_prim_well",
        craftableId = "SCF_inkwell",
        description = "A Primitive Inkwell, crafted with charcoal.",
        materials = {
            { material = "wood", count = 1},
            { material = "charcoal", count = 5}
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 10, maxProgress = 60}
        },
        category = "Scrollcrafting Items"
    },
}
event.register("Ashfall:ActivateBushcrafting:Registered", function(e)
    e.menuActivator:registerRecipes(bushcraftingRecipes)
end)
end

CraftingFramework.MenuActivator:new{
    id =  "SCF_scribe",
    type = "equip",
    name = "Scrollcrafting Menu",
    recipes =  scroll_recipes,
    defaultFilter = "skill",
    doesTimePass = function(self)
        return true
    end,
    collapseByDefault = true,
}

CraftingFramework.MenuActivator:new{
    id =  "SCF_scribe_2",
    type = "equip",
    name = "Scrollcrafting Menu",
    recipes =  scroll_recipes,
    defaultFilter = "skill",
    doesTimePass = function(self)
        return true
    end,
    collapseByDefault = true,
}

--merchants
local inventory ={
    SCF_scribe = 1,
    SCF_scribe_2 = math.random(0,1),
    SCF_parchment = math.random(20),
    SCF_empty = math.random(10),
    SCF_imbued_quill = 1,
    Misc_Inkwell = math.random(5),
    Misc_Quill = math.random(3),
    SCF_ink_a = math.random(3),
    SCF_ink_c = math.random(3), 
    SCF_ink_d = math.random(3),
    SCF_ink_i = math.random(3),
    SCF_ink_m = math.random(3), 
    SCF_ink_r = math.random(3),
}


local containers = {
        {
            merchantId = "ra'virr",
            contents = inventory,
        },
        {
            merchantId = "arrille",
            contents = inventory
        },
        {
            merchantId = "tiras sadus",
            contents = inventory
        },
        {
            merchantId = "mevel fererus",
            contents = inventory
        },
        {
            merchantId = "elegal",
            contents = inventory
        },
        {
            merchantId = "shulki ashunbabi",
            contents = inventory
        },
        {
            merchantId = "verick gemain",
            contents = inventory
        },
        {
            merchantId = "mebestian ence",
            contents = inventory
        },
        {
            merchantId = "ralds oril",
            contents = inventory
        },
        {
            merchantId = "vasesius viciulus",
            contents = inventory
        },
        {
            merchantId = "urfing",
            contents = inventory
        },
        {
            merchantId = "baissa",
            contents = inventory
        },
        {
            merchantId = "ancola",
            contents = inventory
        },
        {
            merchantId = "balen andrano",
            contents = inventory
        },
        {
            merchantId = "berwen",
            contents = inventory
        },
        {
            merchantId = "fadase selvayn",
            contents = inventory
        },
        {
            merchantId = "thongar",
            contents = inventory
        },
    }
    
    local myMerchantManager= CraftingFramework.MerchantManager.new{
        modName = "ScrollCrafting",
        containers = containers,
        logger = mwse.Logger.new{
            name ="ScrollCrafting",
            logLevel = "INFO"
        }
    }

    myMerchantManager:registerEvents()
