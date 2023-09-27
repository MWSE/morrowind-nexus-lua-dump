local this = {}

this.raceNames = {
    ["Argonian"] = "a",
    ["Breton"] = "b",
    ["Dark Elf"] = "d",
    ["High Elf"] = "h",
    ["Imperial"] = "i",
    ["Khajiit"] = "k",
    ["Orc"] = "o",
    ["Nord"] = "n",
    ["Redguard"] = "r",
    ["Wood Elf"] = "w"
}

this.commonVoices = {
    ["a"] = {
        ["f"] = {
            "Srv_AF001",
            "Srv_AF006",
            "Hlo_AF081",
            "Hlo_AF082",
            "Hlo_AF083",
            "Hlo_AF084",
            "Hlo_AF087",
            "Hlo_AF088",
            "Hlo_AF089",
            "Hlo_AF090",
            "Hlo_AF112",
            "Hlo_AF113",
            "Hlo_AF114",
            "Hlo_AF116",
            "Hlo_AF117",
        },
        ["m"] = {
            "Srv_AM001",
            "Srv_AM002",
            "Srv_AM005",
            "Hlo_AM081",
            "Hlo_AM082",
            "Hlo_AM083",
            "Hlo_AM084",
            "Hlo_AM087",
            "Hlo_AM088",
            "Hlo_AM089",
            "Hlo_AM090",
            "Hlo_AM112",
            "Hlo_AM113",
            "Hlo_AM114",
            "Hlo_AM116",
            "Hlo_AM117",
        },
    },
    ["b"] = {
        ["f"] = {
            "Srv_BF002",
            "Srv_BF004",
            "Srv_BF005",
            "Srv_BF008",
            "Srv_BF011",
            "Srv_BF019",
            "Srv_BF020",
            "Srv_BF025",
            "Srv_BF026",
        },
        ["m"] = {
            "Srv_BM002",
            "Srv_BM010",
            "Srv_BM011",
            "Srv_BM013",
            "Srv_BM014",
        },
    },
    ["d"] = {
        ["f"] = {
            "Srv_DF002",
            "Srv_DF014",
            "Srv_DF025",
            "Srv_DF026",
            "Srv_DF031",
            "Srv_DF032",
            "Srv_DF035",
            "Srv_DF046",
            "Srv_DF047",
            "Hlo_DF149",
            "Hlo_DF173",
            "Hlo_DF175",
            "Hlo_DF176",
            "Hlo_DF179",
            "Hlo_DF180",
            "Hlo_DF183",
            "Hlo_DF194",
            "tHlo_DF157",
            "tHlo_DF160",
            "tHlo_DF164",
            "tHlo_DF169"
        },
        ["m"] = {
            "Srv_DM025",
            "Srv_DM032",
            "Srv_DM035",
            "Hlo_DM082",
            "Hlo_DM095",
            "Hlo_DM096",
            "Hlo_DM112",
            "Hlo_DM119",
            "Hlo_DM123",
            "Hlo_DM145",
            "Hlo_DM146",
            "Hlo_DM147",
            "Hlo_DM148",
            "Hlo_DM149",
            "Hlo_DM151",
            "Hlo_DM173",
            "Hlo_DM175",
            "Hlo_DM179",
            "Hlo_DM180",
            "Hlo_DM184",
            "Hlo_DM188",
            "Hlo_DM189",
            "Hlo_DM190",
            "Hlo_DM193",
            "Hlo_DM194",
            "Hlo_DM209",
            "Hlo_DM225",
            "tHlo_DM006",
            "tHlo_DM032",
            "tHlo_DM048",
            "tHlo_DM090",
            "tHlo_DM192",
            "tHlo_DM197",
            "tHlo_DM198",
        },
    },
    ["h"] = {
        ["f"] = {
            "Srv_HF001",
            "Srv_HF008",
            "Srv_HF010",
            "Srv_HF013",
            "Srv_HF014",
            "Srv_HF016",
            "Srv_HF017",
        },
        ["m"] = {
            "Srv_HM001",
            "Srv_HM004",
            "Srv_HM005",
            "Srv_HM007",
            "Srv_HM011",
            "Srv_HM013",
            "Srv_HM014",
            "Srv_HM016",
            "Srv_HM017",
            "Srv_HM019",
            "Srv_HM020",
            "Srv_HM022",
            "Srv_HM023",
            "Srv_HM024",
            "Srv_HM025",
        },
    },
    ["i"] = {
        ["f"] = {
            "Hlo_IF060",
            "Hlo_IF061",
            "Hlo_IF062",
            "Hlo_IF063",
            "Hlo_IF064",
            "Hlo_IF065",
            "Hlo_IF073",
            "Hlo_IF079",
            "Hlo_IF087",
            "Hlo_IF088",
            "Srv_IF002",
            "Srv_IF005",
            "Srv_IF008",
            "Srv_IF010",
            "Srv_IF011",
            "Srv_IF013",
            "Srv_IF014",
            "Srv_IF016",
            "Srv_IF017",
            "Srv_IF019",
            "Srv_IF020",
            "tHlo_IF085",
            "tHlo_IF086",
            "tHlo_IF087",
            "tHlo_IF089",
            "tHlo_IF092",
            "tHlo_IF093",
            "tHlo_IF094",
            "tHlo_IF096",
            "tHlo_IF099",
            "tHlo_IF100",
            "tHlo_IF101",
            "tHlo_IF102",
            "tHlo_IF103",
            "tHlo_IF104",
            "tHlo_IF109",
            "tHlo_IF110",
        },
        ["m"] = {
            "Srv_IM004",
            "Srv_IM005",
            "Srv_IM010",
            "Srv_IM014",
            "Srv_IM016",
            "Srv_IM017",
            "Srv_IM020",
            "Srv_IM022",
            "Srv_IM028",
            "Srv_IM029",
            "Srv_IM032",
            "Srv_IM033",
            "Srv_IM034",
            "tHlo_IM093",
            "tHlo_IM099",
            "tHlo_IM100",
        },
    },
    ["k"] = {
        ["f"] = {
            "Srv_KF010",
            "Hlo_KF000a",
            "Hlo_KF081",
            "Hlo_KF082",
            "Hlo_KF083",
            "Hlo_KF084",
            "Hlo_KF085",
            "Hlo_KF088",
            "Hlo_KF089",
            "Hlo_KF090",
            "Hlo_KF093",
            "Hlo_KF112",
            "Hlo_KF114",
            "Hlo_KF115",
            "Hlo_KF117",
        },
        ["m"] = {
            "Srv_KM005",
            "Srv_KM007",
            "Idl_KM003",
            "Hlo_KM082",
            "Hlo_KM084",
            "Hlo_KM086",
            "Hlo_KM088",
            "Hlo_KM089",
            "Hlo_KM090",
            "Hlo_KM093",
            "Hlo_KM112",
            "Hlo_KM113",
            "Hlo_KM114",
            "Hlo_KM115",
            "Hlo_KM117",
        },
    },
    ["o"] = {
        ["f"] = {
            "Srv_OF001",
            "Srv_OF002",
            "Hlo_OF057",
            "Hlo_OF058",
            "Hlo_OF059",
            "Hlo_OF060",
            "Hlo_OF090",
        },
        ["m"] = {
            "Srv_OM001",
            "Srv_OM007",
            "Srv_OM008",
            "Srv_OM010",
        },
    },
    ["n"] = {
        ["f"] = {
            "Srv_NF001",
            "Srv_NF002",
        },
        ["m"] = {
            "Srv_NM001",
            "Srv_NM004",
            "Srv_NM005",
            "Hlo_NM136",
        },
    },
    ["r"] = {
        ["f"] = {
            "Srv_RF001",
            "Srv_RF002",
            "Srv_RF004",
            "Srv_RF005",
        },
        ["m"] = {
            "Srv_RM001",
            "Srv_RM002",
            "Srv_RM007",
            "Srv_RM008",
            "Srv_RM010",
            "Srv_RM011",
        },
    },
    ["w"] = {
        ["f"] = {
            "Srv_WF005",
            "Srv_WF007",
            "Srv_WF008",
            "Hlo_WF083",
            "Hlo_WF084",
            "Hlo_WF085",
            "Hlo_WF087",
            "Hlo_WF088",
            "Hlo_WF091",
        },
        ["m"] = {
            "Srv_WM002",
            "Hlo_WM087",
            "Hlo_WM088",
            "Hlo_WM090",
            "Hlo_WM077",
        },
    }
}

this.travelVoices = {
    ["a"] = {
        ["f"] = {
            "Flw_AF001",
            "Srv_AF001",
            "Srv_AF001"
        },
        ["m"] = {
            "Flw_AM001",
            "Srv_AM001",
            "Srv_AM001"
        },
    },
    ["b"] = {
        ["f"] = {
            "Srv_BF010",
            "Srv_BF011",
        },
        ["m"] = {
            "Srv_BM010",
            "Srv_BM013",
            "Srv_BM014",
        },
    },
    ["d"] = {
        ["f"] = {
            "Srv_DF037",
            "Srv_DF038",
            "Srv_DF002",
            "Srv_DF014",
            "Srv_DF025",
            "Srv_DF026",
            "Srv_DF031",
            "Srv_DF032",
            "Srv_DF035",
            "Srv_DF046",
            "Srv_DF047",
            "Hlo_DF227",
        },
        ["m"] = {
            "Srv_DM037",
            "Srv_DM038",
            "Srv_DM025",
            "Srv_DM032",
            "Srv_DM035",
            "Hlo_DM227",
            "Hlo_DM228",
        },
    },
    ["h"] = {
        ["f"] = {
            "Srv_HF001",
            "Srv_HF014",
            "Hlo_HF089",
        },
        ["m"] = {
            "Srv_HM005",
            "Srv_HM017",
            "Hlo_HM089",
        },
    },
    ["i"] = {
        ["f"] = {
            "Srv_IF013",
            "Srv_IF014",
            "Hlo_IF087",
            "Hlo_IF088",
        },
        ["m"] = {
            "Srv_IM010",
            "Srv_IM016",
            "Srv_IM017",
            "Srv_IM025",
            "Srv_IM031",
        },
    },
    ["k"] = {
        ["f"] = {
            "Srv_KF008",
            "Srv_KF010",
            "Hlo_KF085",
            "Hlo_KF088",
            "Hlo_KF089"
        },
        ["m"] = {
            "Srv_KM007",
            "Srv_KM005",
            "Hlo_KM085",
            "Hlo_KM086",
            "Hlo_KM088",
            "Hlo_KM089",
            "Hlo_KM090",
            "Hlo_KM091",
        },
    },
    ["o"] = {
        ["f"] = {
            "Hlo_OF057",
            "Srv_OF002",
            "Hlo_OF085",
            "Hlo_OF086",
            "Hlo_OF060",
            "Hlo_OF061",
            "Hlo_OF062",
        },
        ["m"] = {
            "Hlo_OM085",
            "Hlo_OM086",
            "Hlo_OM090",
            "Hlo_OM091",
            "Hlo_OM092"
        },
    },
    ["n"] = {
        ["f"] = {
            "Srv_NF004",
            "Srv_NF005",
        },
        ["m"] = {


        },
    },
    ["r"] = {
        ["f"] = {


        },
        ["m"] = {


        },
    },
    ["w"] = {
        ["f"] = {


        },
        ["m"] = {


        },
    }

}

this.spellVoices = {
    ["a"] = {
        ["f"] = {

        },
        ["m"] = {

        },
    },
    ["b"] = {
        ["f"] = {
            "Srv_BF010",
            "Srv_BF019",
            "Srv_BF002",
            "Srv_BF004",
            "Srv_BF005",
            "Srv_BF008",
            "Srv_BF011",
            "Srv_BF019",
            "Srv_BF020",
            "Srv_BF025",
            "Srv_BF026",
        },
        ["m"] = {


        },
    },
    ["d"] = {
        ["f"] = {


        },
        ["m"] = {


        },
    },
    ["h"] = {
        ["f"] = {
            "Srv_HF001",
            "Srv_HF005",
            "Srv_HF006",
            "Srv_HF008",
            "Srv_HF011",
        },
        ["m"] = {
            "Srv_HM007",
            "Srv_HM008",
            "Srv_HM011",
            "Srv_HM025",
        },
    },
    ["i"] = {
        ["f"] = {
            "Srv_IF004",
            "Srv_IF013",
            "Srv_IF014",
            "Hlo_IF087",
            "Hlo_IF088",
        },
        ["m"] = {
            "Srv_IM004",
            "Srv_IM010",
            "Srv_IM011",
            "Srv_IM014",
            "Srv_IM016",
            "Srv_IM017",
            "Srv_IM028",
            "Srv_IM029",
            "Srv_IM033",
            "Srv_IM034",
        },
    },
    ["k"] = {
        ["f"] = {


        },
        ["m"] = {


        },
    },
    ["o"] = {
        ["f"] = {
            "Srv_OF001",
            "Srv_OF002",
            "Hlo_OF057",
            "Hlo_OF058",
            "Hlo_OF059",
            "Hlo_OF060"
        },
        ["m"] = {


        },
    },
    ["n"] = {
        ["f"] = {


        },
        ["m"] = {


        },
    },
    ["r"] = {
        ["f"] = {


        },
        ["m"] = {


        },
    },
    ["w"] = {
        ["f"] = {
            "Srv_WF004",
            "Srv_WF005",
        },
        ["m"] = {


        },
    }

}


this.trainingVoices = {
    ["a"] = {
        ["f"] = {
            "Srv_AF001",
            "Srv_AF009",
        },
        ["m"] = {
            "Srv_AM001",
            "Srv_AM010",
        },
    },
    ["b"] = {
        ["f"] = {
            "Srv_BF010",
            "Srv_BF011",
            "Srv_BF016",
            "Srv_BF017",
        },
        ["m"] = {
            "Srv_BM007",
            "Srv_BM008",
            "Srv_BM010",
            "Srv_BM011",
        },
    },
    ["d"] = {
        ["f"] = {
            "Srv_DF002",
            "Srv_DF016",
            "Srv_DF017",
            "Srv_DF020",
        },
        ["m"] = {
            "Srv_DM002",
            "Srv_DM013",
            "Srv_DM014",
            "Srv_DM020",
        },
    },
    ["h"] = {
        ["f"] = {
            "Srv_HF001",
            "Srv_HF005",
        },
        ["m"] = {
            "Srv_HM020",
            "Srv_HM025",
        },
    },
    ["i"] = {
        ["f"] = {
            "Srv_IF013",
            "Srv_IF014",
            "Srv_IF020",
        },
        ["m"] = {
            "Srv_IM007",
            "Srv_IM008",
            "Srv_IM010",
            "Srv_IM016",
            "Srv_IM017",
            "Srv_IM023",
            "Srv_IM026",
            "Srv_IM034",
        },
    },
    ["k"] = {
        ["f"] = {
            "Srv_KF004",
            "Srv_KF005",
            "Srv_KF008",
        },
        ["m"] = {
            "Srv_KM005",
            "Hlo_KM109",
            "Hlo_KM115",
            "Hlo_KM120",
        },
    },
    ["o"] = {
        ["f"] = {
            "Srv_OF002",
            "Hlo_OF057",
            "Hlo_OF058",
            "Hlo_OF059",
            "Hlo_OF060",
            "Hlo_OF084",
            "Hlo_OF089",
            "Hlo_OF088",
        },
        ["m"] = {
            "Srv_OM002",
            "Srv_OM004",
            "Srv_OM005",
            "Srv_OM011",
        },
    },
    ["n"] = {
        ["f"] = {
            "Srv_NF001",
            "Hlo_NF114",
            "Hlo_NF136",
            "Hlo_NF085",
            "Hlo_NF082",
        },
        ["m"] = {
            "Hlo_NM136",
            "Hlo_NM111",
            "Hlo_NM110",
            "Hlo_NM117",
            "Hlo_NM082",
            "Hlo_NM083",
            "Hlo_NM084",
            "Hlo_NM085",
        },
    },
    ["r"] = {
        ["f"] = {
            "Hlo_RF086",
            "Hlo_RF087",
            "Hlo_RF088",
        },
        ["m"] = {
            "Srv_RM001",
            "Srv_RM002",
            "Srv_RM004",
            "Srv_RM005",
        },
    },
    ["w"] = {
        ["f"] = {
            "Srv_WF005",
            "Srv_WF008",
            "Hlo_WF083",
            "Hlo_WF084",
            "Hlo_WF085",
            "Hlo_WF087",
            "Hlo_WF088",
            "Hlo_WF091",
        },
        ["m"] = {
            "Srv_WM004",
            "Srv_WM005",
            "Hlo_WM091",
        },
    }

}


return this
