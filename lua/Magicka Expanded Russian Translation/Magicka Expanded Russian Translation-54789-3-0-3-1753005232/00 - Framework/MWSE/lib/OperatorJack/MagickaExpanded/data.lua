---@class MagickaExpanded.Data
local this = {}
this.ids = {
    objects = {
        static = {
            vfxEmpty = "oj_me_vfx_empty",
            vfxLightningStrike = "oj_me_vfx_lightn_strike",
            vfxLightningExplode = "oj_me_vfx_lightn_expl"
        },
        light = {vfxLightningLight = "oj_me_vfx_lightn_light"}
    }
}
this.names = {shaders = {fog = "oj_me_fog_box"}}
this.paths = {
    -- Generic stencil property
    stencils = {
        player1st = "OJ\\ME\\stencils\\mask_char1st.nif",
        player = "OJ\\ME\\stencils\\mask_char.nif",
        playerMirror = "OJ\\ME\\stencils\\mask_char_mirror.nif",
        npc = "OJ\\ME\\stencils\\mask_npc.nif",
        npcMirror = "OJ\\ME\\stencils\\mask_npc_mirror.nif",
        creature = "OJ\\ME\\stencils\\mask_creature.nif",
        weapon = "OJ\\ME\\stencils\\mask_weapon.nif"
    },
    vfx = {},
    shaders = {fog = "XEshaders\\oj_me_fog_box.fx"}
}
return this
