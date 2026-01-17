-- Bed proximity voice responses by race and gender
-- Fires when NPC following player gets within 250 units of a bed in interior cell

local bedVoiceResponses = {
    argonian = {
        female = {
            {response = "Get out of here!", file = "Vo/a/f/Hlo_AF000e.mp3"},
        },
        male = {
            {response = "Be gone!", file = "Vo/a/m/Hlo_AM022.mp3"},
            {response = "Go away!", file = "Vo/a/m/Srv_AM006.mp3"},
            {response = "I see you!", file = "Vo/a/m/Thf_AM005.mp3"},
        }
    },
    breton = {
        female = {
            {response = "Get out of here!", file = "Vo/b/f/Hlo_BF000e.mp3"},
        },
        male = {
            {response = "Get out of here!", file = "Vo/b/m/Hlo_BM000e.mp3"},
        }
    },
    darkelf = {
        female = {
            {response = "You little bastard, you're not supposed to be back here. Get lost!", file = "darkelf-fem/(11).mp3"},
            {response = "Get lost, fetcher!", file = "darkelf-fem/(167).mp3"},
            {response = "If you don't leave now, I shall call the guards.", file = "Vo/d/f/Srv_DF006.mp3"},
            {response = "It would be wise for you to leave now.", file = "Vo/d/f/Srv_DF051.mp3"},
            {response = "Get out of here!", file = "Vo/d/f/Hlo_DF000e.mp3"},
        },
        male = {
            {response = "If you don't leave now, I shall call the guards!", file = "Vo/d/m/Srv_DM006.mp3"},
            {response = "You are an annoyance. Leave, or I shall call for the guards!", file = "Vo/d/m/Srv_DM042.mp3"},
            {response = "What are you doing? Get out!", file = "Vo/ord/Int_ORM002.mp3"},
            {response = "Intruder!", file = "Vo/ord/Int_ORM001.mp3"},
        }
    },
    highelf = {
        female = {
            {response = "If you don't leave now you will wish you had.", file = "Vo/h/f/Srv_HF012.mp3"},
            {response = "Get out of here!", file = "Vo/h/f/Hlo_HF000e.mp3"},
        },
        male = {
            {response = "Leave, before I call the guards!", file = "Vo/h/m/Srv_HM018.mp3"},
            {response = "Get out of here!", file = "Vo/h/m/Hlo_HM000e.mp3"},
        }
    },
    imperial = {
        female = {
            {response = "Get out of here!", file = "Vo/i/f/Hlo_IF000e.mp3"},
        },
        male = {
            {response = "You little bastard, you're not supposed to be back here. Get lost!", file = "imp-male/(3).mp3"},
            {response = "You're still here? Shoo! Go on! Get!", file = "imp-male/(7).mp3"},
            {response = "I've worked too hard to let some upstart thief ruin everything I've built. You'd do best to remember that.", file = "imp-male/(70).mp3"},
            {response = "You dare set foot here?", file = "imp-male/(85).mp3"},
            {response = "Begone, foul creature!", file = "imp-male/(106).mp3"},
            {response = "Don't even think of starting any trouble.", file = "imp-male/(151).mp3"},
            {response = "Please leave now.", file = "Vo/i/m/Srv_IM018.mp3"},
            {response = "Get out of here!", file = "Vo/i/m/Hlo_IM000e.mp3"},
        }
    },
    khajiit = {
        female = {
            {response = "Disgusting thing. Leave now.", file = "vo/k/f/Hlo_KF016.mp3"},
            {response = "Get out of here!", file = "Vo/k/f/Hlo_KF000e.mp3"},
        },
        male = {
            {response = "Go away! Do not come back!", file = "Vo/k/m/Hlo_KM022.mp3"},
        }
    },
    nord = {
        female = {
            {response = "Get out of here!", file = "Vo/n/f/Hlo_NF000e.mp3"},
        },
        male = {
            {response = "Get out of here, before you get hurt!", file = "Vo/n/m/Hlo_NM022.mp3"},
        }
    },
    orc = {
        female = {
            {response = "Get out of here!", file = "Vo/o/f/Hlo_OF000e.mp3"},
        },
        male = {
            {response = "Leave now.", file = "Vo/o/m/Srv_OM012.mp3"},
            {response = "You seek to challenge me?", file = "Vo/o/m/Hlo_OM000d.mp3"},
        }
    },
    redguard = {
        female = {
            {response = "Get out of here!", file = "Vo/r/f/Hlo_RF000e.mp3"},
        },
        male = {
            {response = "I think it would be best if you leave, now!", file = "Vo/r/m/Hlo_RM001.mp3"},
        }
    },
    woodelf = {
        female = {
            {response = "If you do not leave, I shall call for the guards!", file = "Vo/w/f/Srv_WF003.mp3"},
            {response = "Get out of here!", file = "Vo/w/f/Hlo_WF000e.mp3"},
        },
        male = {
            {response = "You'll get more than you bargained for from me!", file = "Vo/w/m/Hlo_WM024.mp3"},
        }
    },
    -- Special races
    T_Cnq_ChimeriQuey = {
        male = {
            {response = "If you value your life, you will leave now.", file = "TR/Vo/TR_ChiM_Hlo_001.mp3"},
        }
    },
    T_Mw_Malahk_Orc = {
        female = {
            {response = "Get out of here!", file = "Vo/o/f/Hlo_OF000e.mp3"},
        },
        male = {
            {response = "You seek to challenge me?", file = "Vo/o/m/Hlo_OM000d.mp3"},
        }
    },
    T_Sky_Reachman = {
        female = {
            {response = "Get out of here!", file = "Vo/b/f/Hlo_BF000e.mp3"},
        },
        male = {
            {response = "You seek to challenge me?", file = "sky/Vo/Rc/m/Hlo_RcM000d.mp3"},
        }
    }
}

return bedVoiceResponses
