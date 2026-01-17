local core = require 'openmw.core'
local util = require('openmw.util')

local usingANH = core.contentFiles.has('a new hope - chargen reworked.esp')
return {
    CellName = 'The Outer Rim, Freighter',

    InteriorTeleportPosition = usingANH and util.vector3(4081, 7249, 15221) or util.vector3(3947, 5156, 15353),
    InteriorTeleportRotation = util.transform.rotateZ(math.rad(270), util.transform.identity),

    ButtonRecordIdsToDestinationCells = {
        ['sw_buttondan'] = 'dantooine, ballast',
        ['sw_buttonmana'] = 'manaan, docking bay',
        ['sw_buttonnar'] = 'nar shaddaa, north hanger',
        ['sw_buttongamorr'] = 'gamorr, ucksmug',
        ['sw_buttonhoth'] = 'hoth, wasteland',
        ['sw_buttontaris'] = 'taris, central plaza',
        ['sw_buttontat'] = 'tatooine, sandriver',
        ['sw_buttonkash'] = 'kashyyk, boyle research facility',
        ['sw_buttonm4'] = 'm4-78: landing arm',
        ['sw_buttondathomir'] = 'dathomir, exterior',

    },

    Destinations = {
        ['dantooine, ballast'] = {
            planetActivator = 'sw_freightplandant',
            teleportTo = {
                pos = util.vector3(5916, -1030, 145),
                rot = 0,
            },
        },

        ['dathomir, exterior'] = {
            planetActivator = 'sw_freightplandath',
            teleportTo = {
                pos = util.vector3(1163, 1423, 12468),
                rot = 97,
            },
        },

        ['derelict station, antechamber'] = {
            planetActivator = 'sw_freightderelict1',
            teleportTo = {
                pos = util.vector3(10249, 6049, 14377),
                rot = 360,
            }
        },

        ['gamorr, ucksmug'] = {
            planetActivator = 'sw_freightplangamor',
            teleportTo = {
                pos = util.vector3(3014, -1093, 147),
                rot = 40,
            },
        },

        ['hoth, wasteland'] = {
            planetActivator = 'sw_freightplanhoth',
            teleportTo = {
                pos = util.vector3(8090, 6426, 13141),
                rot = 193,
            },
        },

        ['kashyyk, boyle research facility'] = {
            planetActivator = 'sw_freightplankash',
            teleportTo = {
                pos = util.vector3(9726, -4728, 13393),
                rot = 237,
            },
        },

        ['lok, graveridge'] = {
            planetActivator = 'sw_freightplanlok',
            teleportTo = {
                pos = util.vector3(11491, 15117, 727),
                rot = -123,
            },
        },

        ['m4-78: landing arm'] = {
            planetActivator = 'sw_freightplanm478',
            teleportTo      = {
                pos = util.vector3(4708, 8282, 17356),
                rot = 183,
            },
        },

        ['manaan, docking bay'] = {
            planetActivator = 'sw_freightplanmana',
            teleportTo = {
                pos = util.vector3(6935, 11504, 7848),
                rot = 142,
            },
        },

        ['nar shaddaa, north hanger'] = {
            planetActivator = 'sw_freightplannar',
            teleportTo = {
                pos = util.vector3(3249, 4341, 13450),
                rot = 166,
            },
        },

        ['taris, central plaza'] = {
            planetActivator = 'sw_freightplantaris',
            teleportTo = {
                pos = util.vector3(3394, 9979, 12843),
                rot = 274,
            },
        },

        ['tatooine, sandriver'] = {
            planetActivator = 'sw_freighterplantat',
            teleportTo = {
                pos = util.vector3(7687, 6619, 12366),
                rot = 314,
            },
        },

    },

    DoorsToRemove = {
        ['sw_freightertodantooine'] = false,
        ['sw_freightertodathomir'] = false,
        ['sw_freightertoderelict'] = false,
        ['sw_freightertoextra'] = false,
        ['sw_freightertogamorr'] = false,
        ['sw_freightertohoth'] = false,
        ['sw_freightertokashyyk'] = false,
        ['sw_freightertolok'] = false,
        ['sw_freightertom4'] = false,
        ['sw_freightertomanaan'] = false,
        ['sw_freightertonarshad'] = true,
        ['sw_freightertonone'] = false,
        ['sw_freightertotaris'] = false,
        ['sw_freightertotatooine'] = false,

    },

    Models = {
        Door = 'meshes/ig/activators/door1.nif',
        Freighter = 'meshes/ig/spshipfreight.nif',
        LightSpeed = 'meshes/ig/freightltspeed.nif',

    },

    Sfx = {
        Travel = 'sound/ig/flyingsound.wav',
        Door = 'sound/fx/trans/drmtl_opn.wav',

    },

    ShipsToReplace = {
        ['sw_playershipnew'] = true,
        ['sw_playershipnewtaris'] = true,
        ['sw_playersshipmana'] = true,

    },

}
