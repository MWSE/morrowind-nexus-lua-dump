
local voiceLines = {
    bad = {
        ['argnonian'] = {
            male = {
                "vo\\a\\m\\Fle_AM001.mp3",
                "vo\\a\\m\\Fle_AM002.mp3",
                "vo\\a\\m\\Fle_AM003.mp3",
                "vo\\a\\m\\Fle_AM004.mp3",
                "vo\\a\\m\\Fle_AM005.mp3",
                "vo\\a\\m\\Atk_AM013.mp3",
            }, --done
            female = {
                "vo\\a\\f\\Fle_AF001.mp3",
                "vo\\a\\f\\Fle_AF002.mp3",
                "vo\\a\\f\\Fle_AF003.mp3",
                "vo\\a\\f\\Fle_AF004.mp3",
                "vo\\a\\f\\Fle_AF005.mp3",
                "vo\\a\\f\\Atk_AF014.mp3",
            },
        },
        ['breton'] = {
            male = {
                --"vo\\b\\m\\Fle_BM001.mp3",
                "vo\\b\\m\\Fle_BM002.mp3",
                "vo\\b\\m\\Fle_BM003.mp3",
                "vo\\b\\m\\Fle_BM004.mp3",
                "vo\\b\\m\\Fle_BM005.mp3",
                "vo\\b\\m\\Atk_BM005.mp3",
            },--done
            female = {
                "vo\\b\\f\\Fle_BF001.mp3",
                "vo\\b\\f\\Fle_BF002.mp3",
                "vo\\b\\f\\Fle_BF003.mp3",
                "vo\\b\\f\\Fle_BF004.mp3",
                "vo\\b\\f\\Fle_BF005.mp3",
                "vo\\b\\f\\Atk_BF005.mp3",
                "vo\\b\\f\\Idl_BF001.mp3",
            },--done
        },
        ['dark elf'] = {
            male = {
                "vo\\d\\m\\Fle_DM001.mp3",
                --"vo\\d\\m\\Fle_DM002.mp3",
                "vo\\d\\m\\Fle_DM003.mp3",
                "vo\\d\\m\\Fle_DM004.mp3",
                "vo\\d\\m\\Fle_DM005.mp3",
                "vo\\d\\m\\Atk_DM001.mp3",
                "vo\\d\\m\\Atk_DM002.mp3",
                "vo\\d\\m\\Atk_DM004.mp3",
                "vo\\d\\m\\bIdl_DM005.mp3",
                "vo\\d\\m\\bIdl_DM012.mp3",
            },--done
            female = {
                "vo\\d\\f\\Fle_DF001.mp3",
                --"vo\\d\\f\\Fle_DF002.mp3",
                "vo\\d\\f\\Fle_DF003.mp3",
                "vo\\d\\f\\Fle_DF004.mp3",
                --"vo\\d\\f\\Fle_DF005.mp3",
                "vo\\d\\f\\Atk_DF004.mp3",
                "vo\\d\\f\\tIdl_DF015.mp3",
            },--done
        },
        ['high elf'] = {
            male = {
                "vo\\h\\m\\Fle_HM001.mp3",
                --"vo\\h\\m\\Fle_HM002.mp3",
                "vo\\h\\m\\Fle_HM003.mp3",
                "vo\\h\\m\\Fle_HM004.mp3",
                --"vo\\h\\m\\Fle_HM005.mp3",
                "vo\\h\\m\\Atk_HM013.mp3",
            },--done
            female = {
                "vo\\h\\f\\Fle_HF001.mp3",
                "vo\\h\\f\\Fle_HF002.mp3",
                "vo\\h\\f\\Fle_HF003.mp3",
                "vo\\h\\f\\Fle_HF004.mp3",
                "vo\\h\\f\\Fle_HF005.mp3",
                "vo\\h\\f\\Atk_HF013.mp3",
            },--done
        },
        ['imperial'] = {
            male = {
                "vo\\i\\m\\Fle_IM001.mp3",
                "vo\\i\\m\\Fle_IM002.mp3",
                "vo\\i\\m\\Fle_IM003.mp3",
                "vo\\i\\m\\Fle_IM004.mp3",
                "vo\\i\\m\\bIdl_IM020.mp3",
                "vo\\i\\m\\bIdl_IM029.mp3",
                "vo\\i\\m\\bIdl_IM034.mp3",
            },--done
            female = {
                --"vo\\i\\f\\Fle_IF001.mp3",
                "vo\\i\\f\\Fle_IF002.mp3",
                "vo\\i\\f\\Fle_IF003.mp3",
                "vo\\i\\f\\Fle_IF004.mp3",
                "vo\\i\\f\\Fle_IF005.mp3",
                "vo\\i\\f\\Atk_IF013.mp3",
                "vo\\i\\f\\Atk_IF014.mp3",
                "vo\\i\\f\\Idl_IF002.mp3",
            },
        },
        ['khajiit'] = {
            male = {
                "vo\\k\\m\\Fle_KM001.mp3",
                --"vo\\k\\m\\Fle_KM002.mp3",
                "vo\\k\\m\\Fle_KM003.mp3",
                "vo\\k\\m\\Fle_KM004.mp3",
                --"vo\\k\\m\\Fle_KM005.mp3",
                "vo\\k\\m\\Idl_KM005.mp3",
            },
            female = {
                "vo\\k\\f\\Fle_KF001.mp3",
                --"vo\\k\\f\\Fle_KF002.mp3",
                "vo\\k\\f\\Fle_KF003.mp3",
                "vo\\k\\f\\Fle_KF004.mp3",
                --"vo\\k\\f\\Fle_KF005.mp3",
                "vo\\k\\f\\Idl_KF005.mp3",
            },--done
        },
        ['nord'] = {
            male = {
                "vo\\n\\m\\Fle_NM001.mp3",
                "vo\\n\\m\\Fle_NM002.mp3",
                --"vo\\n\\m\\Fle_NM003.mp3",
                --"vo\\n\\m\\Fle_NM004.mp3",
                --"vo\\n\\m\\Fle_NM005.mp3",
                "vo\\n\\m\\Atk_NM004.mp3",
                "vo\\n\\m\\bIld_NM025.mp3",
                "vo\\n\\m\\bIld_NM030.mp3",
            },--done
            female = {
                "vo\\n\\f\\Fle_NF001.mp3",
                "vo\\n\\f\\Fle_NF002.mp3",
                --"vo\\n\\f\\Fle_NF003.mp3",
                --"vo\\n\\f\\Fle_NF004.mp3",
                --"vo\\n\\f\\Fle_NF005.mp3",
                "vo\\n\\f\\Atk_NF004.mp3",
            },--done
        },
        ['orc'] = {
            male = {
                --"vo\\o\\m\\Fle_OM001.mp3",
                "vo\\o\\m\\Fle_OM002.mp3",
                --"vo\\o\\m\\Fle_OM003.mp3",
                "vo\\o\\m\\Fle_OM004.mp3",
                "vo\\o\\m\\Fle_OM005.mp3",
                "vo\\o\\m\\Atk_OM004.mp3",
            },--done
            female = {
                --"vo\\o\\f\\Fle_OF001.mp3",
                "vo\\o\\f\\Fle_OF002.mp3",
                --"vo\\o\\f\\Fle_OF003.mp3",
                "vo\\o\\f\\Fle_OF004.mp3",
                "vo\\o\\f\\Fle_OF005.mp3",
                "vo\\o\\f\\Atk_OF004.mp3",
                "vo\\o\\f\\Idl_OF007.mp3",
            },--done
        },
        ['redguard'] = {
            male = {
                "vo\\r\\m\\Fle_RM001.mp3",
                "vo\\r\\m\\Fle_RM002.mp3",
                --"vo\\r\\m\\Fle_RM003.mp3",
                "vo\\r\\m\\Fle_RM004.mp3",
                "vo\\r\\m\\Fle_RM005.mp3",
            },
            female = {
                "vo\\r\\f\\Fle_RF001.mp3",
                "vo\\r\\f\\Fle_RF002.mp3",
                --"vo\\r\\f\\Fle_RF003.mp3",
                "vo\\r\\f\\Fle_RF004.mp3",
                "vo\\r\\f\\Fle_RF005.mp3",
                "vo\\r\\f\\Atk_RF004.mp3",
                "vo\\r\\f\\Idl_RF002.mp3",
            },--done
        },
        ['wood elf'] = {
            male = {
                "vo\\w\\m\\Fle_WM001.mp3",
                "vo\\w\\m\\Fle_WM002.mp3",
                --"vo\\w\\m\\Fle_WM003.mp3",
                --"vo\\w\\m\\Fle_WM004.mp3",
                "vo\\w\\m\\Fle_WM005.mp3",
                "vo\\w\\m\\Atk_WM002.mp3",
            },
            female = {
                "vo\\w\\f\\Fle_WF001.mp3",
                "vo\\w\\f\\Fle_WF002.mp3",
                --"vo\\w\\f\\Fle_WF003.mp3",
                --"vo\\w\\f\\Fle_WF004.mp3",
                "vo\\w\\f\\Fle_WF005.mp3",
                "vo\\w\\f\\Atk_WF002.mp3",
            },
        }
    }
}

return voiceLines