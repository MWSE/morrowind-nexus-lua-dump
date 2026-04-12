local self = require('openmw.self')

local quests = {

    {
        id = "KS_JulanRedMountain",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Speak with Julan after he refuses to continue a journey."
    },

    {
        id = "KS_JulanBetrayed",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Speak with Julan after a serious disagreement."
    },

    {
        id = "KS_Jul_BookDance",
        name = "Book - A Dance in Fire",
        category = "Books",
        subcategory = "Book Series",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_Jul_BookAlc2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookWfQn",
        name = "Book - The Wolf Queen",
        category = "Books",
        subcategory = "Book Series",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_Jul_BookAlc1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookUna1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSpe1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookChKo",
        name = "Book - Charwich-Koniige",
        category = "Books",
        subcategory = "Book Series",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_Jul_BookTalu",
        name = "Book - The Mystery of Talara",
        category = "Books",
        subcategory = "Book Series",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_Jul_BookSpr1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_Book2920",
        name = "Book - 2920, The Last Year of the First Era",
        category = "Books",
        subcategory = "Book Series",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_Jul_BookAlc3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAlt1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAlt2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAlt3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAlt5",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookArm1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookArm2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAxe1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAxe2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookAxe3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookBlk1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookBlk2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookBnt1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookBnt2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookBnt3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookCon5",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookDes2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookDes1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookDes3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookDes4",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookEnc5",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookH2H1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookH2H5",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookHvA1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookHvA3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookHvA4",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookIll2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookIll3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookLtA1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookLtA2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookLtA3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookMdA1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookMer1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookMys1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookRes2",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookRes3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSec3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSec4",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSec5",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSBd1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookLBd1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSnk3",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSnk4",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_Jul_BookSec1",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_ShaniGuardsH",
        name = "Guarding Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Bring Shani a Hlaalu guard helm."
    },

    {
        id = "KS_ShaniGuardsT",
        name = "Guarding Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Bring Shani a Telvanni guard helm."
    },

    {
        id = "KS_ShaniGuardsR",
        name = "Guarding Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Bring Shani a Redoran guard helm."
    },

    {
        id = "KS_ShaniGuardsO",
        name = "Guarding Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Bring Shani an Ordinator helm."
    },

    {
        id = "KS_JulanEndModX",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Julan's story has come to an end."
    },

    {
        id = "KS_Jul_BookBne",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_JulanMashti",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Travel with Julan to seek his mother's advice."
    },

    {
        id = "KS_Jul_BookFey",
        name = "Book - Feyfolken",
        category = "Books",
        subcategory = "Book Series",
        master = "Julan",
        text = "Look for more books for Julan."
    },

    {
        id = "KS_JulanFather",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Help Julan recover his father's remains."
    },

    {
        id = "KS_Jul_BookPal",
        name = "Skillbook",
        category = "Books",
        subcategory = "Skillbooks",
        master = "Julan",
        text = "Bring Julan a book to read."
    },

    {
        id = "KS_ShaniGuards",
        name = "Guarding Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Find guard helms for Shani."
    },

    {
        id = "KS_JulanShani",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Ask around about Shani."
    },

    {
        id = "KS_JulanCaius",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Speak with Caius without Julan present."
    },

    {
        id = "KS_MashtiPast",
        name = "Mashti's Story",
        category = "Companion",
        subcategory = "Mashti",
        master = "Julan",
        text = "Learn more about Mashti's past."
    },

    {
        id = "KS_Jul_Amulet",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Accept a gift from Julan."
    },

    {
        id = "KS_JulanSSBet",
        name = "A bet with Julan",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Complete a wager made with Julan."
    },

    {
        id = "KS_JulanIntro",
        name = "Assisting an Ald'ruhn Trader",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Assist a trader traveling toward Ghostgate."
    },

    {
        id = "KS_JulanGone",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Find Julan after he disappears."
    },

    {
        id = "KS_ShaniComp",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Speak with Shani after Julan's return."
    },

    {
        id = "KS_ShaniComR",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Ask about Shani's reputation."
    },

    {
        id = "KS_ShaniComM",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Ask about Shani's interests."
    },

    {
        id = "KS_ShaniComG",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Ask about Shani's character."
    },

    {
        id = "KS_ShaniNosy",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Speak with Shani after she starts asking personal questions."
    },

    {
        id = "KS_ShaniRomX",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "End a relationship with Shani."
    },

    {
        id = "KS_JulanMet",
        name = "Julan Kaushibael",
        category = "Companion",
        subcategory = "Julan",
        master = "Julan",
        text = "Help an injured Ashlander traveler."
    },

    {
        id = "KS_ShaniRom",
        name = "Shani",
        category = "Companion",
        subcategory = "Shani",
        master = "Julan",
        text = "Decide where things stand with Shani."
    },

    {
        id = "KS_MashtiGM",
        name = "Mashti's Matter of Family",
        category = "Companion",
        subcategory = "Mashti",
        master = "Julan",
        text = "Deliver a message for Mashti's family."
    },

    {
        id = "KS_AMoveG1",
        name = "Moving the Ahemmusa",
        category = "Ahemmusa",
        subcategory = "Clan Quests",
        master = "Julan",
        text = "Lead a lost guar back to camp."
    },

    {
        id = "KS_AMoveG2",
        name = "Moving the Ahemmusa",
        category = "Ahemmusa",
        subcategory = "Clan Quests",
        master = "Julan",
        text = "Lead an escaped guar back to camp."
    },

    {
        id = "KS_AMove",
        name = "Moving the Ahemmusa",
        category = "Ahemmusa",
        subcategory = "Clan Quests",
        master = "Julan",
        text = "Speak with Sinnammu Mirpal in the Ahemmusa camp."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 86