local settings = require("scripts.openmw_books_enhanced.settings")

-- Notes on how I generated the `characterSizeFactorsRelevantToFontSize` table:
-- I used opentype.js to access the font used by the game and get the "advanceWidth".
-- ( by the way see https://www.imagemagick.org/Usage/text/#font_info )
-- Then (see previous version of this code) I took the '%' symbol as base and
-- and assumed 789 advanceWidth is 0.82. Here's the code I used:
-- ###############################################################
-- <!DOCTYPE html>
-- <html lang="en">
-- <title>opentype.js font inspector</title>
-- <script src="https://opentype.js.org/dist/opentype.js"></script>
-- <script>
-- //MysticCards.ttf placed in the same folder as this html
-- const font = opentype.load('MysticCards.ttf').then(data => {
--     for (const key in data.glyphs.glyphs) {
--         if (Object.hasOwnProperty.call(data.glyphs.glyphs, key)) {
--             const glyph = data.glyphs.glyphs[key];
--             let stringOut = "['"
--             stringOut += String.fromCharCode(glyph.unicode)
--             stringOut += "'] = {"
--             stringOut += "width = "
--             stringOut += (glyph.advanceWidth * (0.82 / 789))
--             stringOut += " }"
--             console.log(stringOut)
--         }
--     }
-- })
-- </script>
-- </html>
-- ###############################################################
-- Oh and I had to set up a small server to load this html. I know next to nothing
-- about these things so I just googled around and combined few stack overflow hints.
-- Sorry for not pointing to relevant posts, I lost them. But here's the python script:
-- ###############################################################
-- #!/usr/bin/env python3
-- from http.server import HTTPServer, SimpleHTTPRequestHandler, test
-- import sys
-- class CORSRequestHandler (SimpleHTTPRequestHandler):
--     def end_headers (self):
--         self.send_header('Access-Control-Allow-Origin', '*')
--         SimpleHTTPRequestHandler.end_headers(self)
-- class MyHTTPServer(HTTPServer):
--     allowed_hosts = (('127.0.0.1', 80),)
--     def do_GET(self):
--         if self.client_address not in allowed_hosts:
--             self.send_response(401, 'request not allowed')
--         else:
--             super(MyHTTPServer, self).do_Get()
-- if __name__ == '__main__':
--     test(CORSRequestHandler, HTTPServer, port=int(sys.argv[1]) if len(sys.argv) > 1 else 8000)
-- ###############################################################
local characterSizeFactorsRelevantToFontSize = {
    [''] = { width = 0.0 },
    ['�'] = { width = 0.38869455006337134 },
    ['\n'] = { width = 0.020785804816223066 },
    ['\r'] = { width = 0.020785804816223066 },
    [' '] = { width = 0.4520912547528517 },
    ['!'] = { width = 0.23695817490494298 },
    ['"'] = { width = 0.3938910012674271 },
    ['#'] = { width = 0.6048669201520912 },
    ['$'] = { width = 0.5809632446134347 },
    ['%'] = { width = 0.82 },
    ['&'] = { width = 0.7825855513307984 },
    ['\''] = { width = 0.19122940430925223 },
    ['('] = { width = 0.4177946768060837 },
    [')'] = { width = 0.4177946768060837 },
    ['*'] = { width = 0.521723700887199 },
    ['+'] = { width = 0.6069455006337136 },
    [','] = { width = 0.2826869455006337 },
    ['-'] = { width = 0.3741444866920152 },
    ['.'] = { width = 0.25358681875792144 },
    ['/'] = { width = 0.3627122940430925 },
    ['0'] = { width = 0.5300380228136882 },
    ['1'] = { width = 0.5300380228136882 },
    ['2'] = { width = 0.5300380228136882 },
    ['3'] = { width = 0.5300380228136882 },
    ['4'] = { width = 0.5300380228136882 },
    ['5'] = { width = 0.5300380228136882 },
    ['6'] = { width = 0.5300380228136882 },
    ['7'] = { width = 0.5300380228136882 },
    ['8'] = { width = 0.5300380228136882 },
    ['9'] = { width = 0.5300380228136882 },
    [':'] = { width = 0.26397972116603297 },
    [';'] = { width = 0.29307984790874525 },
    ['<'] = { width = 0.6485171102661597 },
    ['='] = { width = 0.6350063371356147 },
    ['>'] = { width = 0.6485171102661597 },
    ['?'] = { width = 0.42195183776932826 },
    ['@'] = { width = 0.8937896070975919 },
    ['A'] = { width = 0.7753105196451204 },
    ['B'] = { width = 0.76595690747782 },
    ['C'] = { width = 0.7243852978453739 },
    ['D'] = { width = 0.7649176172370089 },
    ['E'] = { width = 0.7462103929024081 },
    ['F'] = { width = 0.5768060836501901 },
    ['G'] = { width = 0.8251964512040557 },
    ['H'] = { width = 0.8158428390367554 },
    ['I'] = { width = 0.5352344740177439 },
    ['J'] = { width = 0.4791128010139417 },
    ['K'] = { width = 0.7420532319391635 },
    ['L'] = { width = 0.7617997465145754 },
    ['M'] = { width = 0.9395183776932826 },
    ['N'] = { width = 0.9977186311787072 },
    ['O'] = { width = 0.9031432192648923 },
    ['P'] = { width = 0.8137642585551331 },
    ['Q'] = { width = 0.9031432192648923 },
    ['R'] = { width = 0.9010646387832699 },
    ['S'] = { width = 0.7129531051964512 },
    ['T'] = { width = 0.7566032953105196 },
    ['U'] = { width = 0.8179214195183777 },
    ['V'] = { width = 0.7472496831432193 },
    ['W'] = { width = 1.2274017743979722 },
    ['X'] = { width = 0.7025602027883396 },
    ['Y'] = { width = 0.6713814955640051 },
    ['Z'] = { width = 0.7025602027883396 },
    ['['] = { width = 0.3543979721166033 },
    ['\\'] = { width = 0.392851711026616 },
    [']'] = { width = 0.3543979721166033 },
    ['^'] = { width = 0.4988593155893536 },
    ['_'] = { width = 0.5705703422053232 },
    ['`'] = { width = 0.2161723700887199 },
    ['a'] = { width = 0.5123700887198986 },
    ['b'] = { width = 0.5539416983523447 },
    ['c'] = { width = 0.45105196451204055 },
    ['d'] = { width = 0.5809632446134347 },
    ['e'] = { width = 0.454169835234474 },
    ['f'] = { width = 0.3564765525982256 },
    ['g'] = { width = 0.5684917617237009 },
    ['h'] = { width = 0.6131812420785805 },
    ['i'] = { width = 0.35335868187579217 },
    ['j'] = { width = 0.34504435994930294 },
    ['k'] = { width = 0.5684917617237009 },
    ['l'] = { width = 0.2899619771863118 },
    ['m'] = { width = 0.8594930291508238 },
    ['n'] = { width = 0.5934347275031686 },
    ['o'] = { width = 0.5373130544993663 },
    ['p'] = { width = 0.5549809885931559 },
    ['q'] = { width = 0.6246134347275032 },
    ['r'] = { width = 0.48846641318124207 },
    ['s'] = { width = 0.43754119138149555 },
    ['t'] = { width = 0.4572877059569075 },
    ['u'] = { width = 0.5352344740177439 },
    ['v'] = { width = 0.5466666666666666 },
    ['w'] = { width = 0.8989860583016477 },
    ['x'] = { width = 0.5830418250950571 },
    ['y'] = { width = 0.5497845373891002 },
    ['z'] = { width = 0.5508238276299113 },
    ['{'] = { width = 0.3918124207858048 },
    ['|'] = { width = 0.3097084917617237 },
    ['}'] = { width = 0.42299112801013944 },
    ['~'] = { width = 0.5716096324461344 },
    ['¡'] = { width = 0.25566539923954373 },
    ['¨'] = { width = 0.2722940430925222 },
    ['­'] = { width = 0.3668694550063371 },
    ['¯'] = { width = 0.3668694550063371 },
    ['°'] = { width = 0.32425855513307983 },
    ['±'] = { width = 0.6069455006337136 },
    ['´'] = { width = 0.2161723700887199 },
    ['¸'] = { width = 0.5300380228136882 },
    ['¿'] = { width = 0.3377693282636248 },
    ['À'] = { width = 0.7753105196451204 },
    ['Á'] = { width = 0.7753105196451204 },
    ['Â'] = { width = 0.7753105196451204 },
    ['Ã'] = { width = 0.7753105196451204 },
    ['Ä'] = { width = 0.7753105196451204 },
    ['Å'] = { width = 0.7753105196451204 },
    ['Æ'] = { width = 1.0528010139416983 },
    ['Ç'] = { width = 0.7243852978453739 },
    ['È'] = { width = 0.7462103929024081 },
    ['É'] = { width = 0.7462103929024081 },
    ['Ê'] = { width = 0.7462103929024081 },
    ['Ë'] = { width = 0.7462103929024081 },
    ['Ì'] = { width = 0.5352344740177439 },
    ['Í'] = { width = 0.5352344740177439 },
    ['Î'] = { width = 0.5352344740177439 },
    ['Ï'] = { width = 0.5352344740177439 },
    ['Ð'] = { width = 0.7649176172370089 },
    ['Ñ'] = { width = 0.9977186311787072 },
    ['Ò'] = { width = 0.9031432192648923 },
    ['Ó'] = { width = 0.9031432192648923 },
    ['Ô'] = { width = 0.9031432192648923 },
    ['Õ'] = { width = 0.9031432192648923 },
    ['Ö'] = { width = 0.9031432192648923 },
    ['×'] = { width = 0.5830418250950571 },
    ['Ø'] = { width = 0.7763498098859316 },
    ['Ù'] = { width = 0.8179214195183777 },
    ['Ú'] = { width = 0.8179214195183777 },
    ['Û'] = { width = 0.8179214195183777 },
    ['Ü'] = { width = 0.8179214195183777 },
    ['Ý'] = { width = 0.6713814955640051 },
    ['Þ'] = { width = 0.5996704689480354 },
    ['ß'] = { width = 0.5903168567807351 },
    ['à'] = { width = 0.5123700887198986 },
    ['á'] = { width = 0.5123700887198986 },
    ['â'] = { width = 0.5123700887198986 },
    ['ã'] = { width = 0.5123700887198986 },
    ['ä'] = { width = 0.5123700887198986 },
    ['å'] = { width = 0.5123700887198986 },
    ['æ'] = { width = 0.7462103929024081 },
    ['ç'] = { width = 0.4344233206590621 },
    ['è'] = { width = 0.454169835234474 },
    ['é'] = { width = 0.454169835234474 },
    ['ê'] = { width = 0.454169835234474 },
    ['ë'] = { width = 0.454169835234474 },
    ['ì'] = { width = 0.32217997465145753 },
    ['í'] = { width = 0.32217997465145753 },
    ['î'] = { width = 0.32217997465145753 },
    ['ï'] = { width = 0.32217997465145753 },
    ['ð'] = { width = 0.5414702154626109 },
    ['ñ'] = { width = 0.5934347275031686 },
    ['ò'] = { width = 0.5373130544993663 },
    ['ó'] = { width = 0.5373130544993663 },
    ['ô'] = { width = 0.5373130544993663 },
    ['õ'] = { width = 0.5373130544993663 },
    ['ö'] = { width = 0.5373130544993663 },
    ['÷'] = { width = 0.3699873257287706 },
    ['ø'] = { width = 0.5269201520912548 },
    ['ù'] = { width = 0.5352344740177439 },
    ['ú'] = { width = 0.5352344740177439 },
    ['û'] = { width = 0.5352344740177439 },
    ['ü'] = { width = 0.5352344740177439 },
    ['ý'] = { width = 0.5497845373891002 },
    ['þ'] = { width = 0.5560202788339671 },
    ['ÿ'] = { width = 0.5497845373891002 },
    ['Ā'] = { width = 0.7753105196451204 },
    ['ā'] = { width = 0.5123700887198986 },
    ['Ă'] = { width = 0.7753105196451204 },
    ['ă'] = { width = 0.5123700887198986 },
    ['Ą'] = { width = 0.7753105196451204 },
    ['ą'] = { width = 0.5061343472750317 },
    ['Ć'] = { width = 0.7243852978453739 },
    ['ć'] = { width = 0.45105196451204055 },
    ['Ĉ'] = { width = 0.7243852978453739 },
    ['ĉ'] = { width = 0.45105196451204055 },
    ['Ċ'] = { width = 0.7243852978453739 },
    ['ċ'] = { width = 0.45105196451204055 },
    ['Č'] = { width = 0.7243852978453739 },
    ['č'] = { width = 0.45105196451204055 },
    ['Ď'] = { width = 0.7649176172370089 },
    ['ď'] = { width = 0.6474778200253486 },
    ['Đ'] = { width = 0.7649176172370089 },
    ['đ'] = { width = 0.5809632446134347 },
    ['Ē'] = { width = 0.7462103929024081 },
    ['ē'] = { width = 0.454169835234474 },
    ['Ĕ'] = { width = 0.7462103929024081 },
    ['ĕ'] = { width = 0.454169835234474 },
    ['Ė'] = { width = 0.7462103929024081 },
    ['ė'] = { width = 0.454169835234474 },
    ['Ę'] = { width = 0.7462103929024081 },
    ['ę'] = { width = 0.454169835234474 },
    ['Ě'] = { width = 0.7462103929024081 },
    ['ě'] = { width = 0.454169835234474 },
    ['Ĝ'] = { width = 0.8251964512040557 },
    ['ĝ'] = { width = 0.5684917617237009 },
    ['Ğ'] = { width = 0.8251964512040557 },
    ['ğ'] = { width = 0.5684917617237009 },
    ['Ġ'] = { width = 0.8251964512040557 },
    ['ġ'] = { width = 0.5684917617237009 },
    ['Ģ'] = { width = 0.8251964512040557 },
    ['ģ'] = { width = 0.5684917617237009 },
    ['Ĥ'] = { width = 0.8158428390367554 },
    ['ĥ'] = { width = 0.6131812420785805 },
    ['Ħ'] = { width = 0.8158428390367554 },
    ['ħ'] = { width = 0.6131812420785805 },
    ['Ĩ'] = { width = 0.5352344740177439 },
    ['ĩ'] = { width = 0.5404309252217997 },
    ['Ī'] = { width = 0.5352344740177439 },
    ['ī'] = { width = 0.33257287705956906 },
    ['Ĭ'] = { width = 0.5352344740177439 },
    ['ĭ'] = { width = 0.38245880861850445 },
    ['Į'] = { width = 0.5352344740177439 },
    ['į'] = { width = 0.35335868187579217 },
    ['İ'] = { width = 0.5352344740177439 },
    ['ı'] = { width = 0.32217997465145753 },
    ['Ĳ'] = { width = 0.8491001267427123 },
    ['ĳ'] = { width = 0.4822306717363752 },
    ['Ĵ'] = { width = 0.4791128010139417 },
    ['ĵ'] = { width = 0.4323447401774398 },
    ['Ķ'] = { width = 0.7420532319391635 },
    ['ķ'] = { width = 0.5684917617237009 },
    ['ĸ'] = { width = 0.47495564005069707 },
    ['Ĺ'] = { width = 0.7617997465145754 },
    ['ĺ'] = { width = 0.2899619771863118 },
    ['Ļ'] = { width = 0.7617997465145754 },
    ['ļ'] = { width = 0.2899619771863118 },
    ['Ľ'] = { width = 0.7617997465145754 },
    ['ľ'] = { width = 0.3772623574144487 },
    ['Ŀ'] = { width = 0.7617997465145754 },
    ['ŀ'] = { width = 0.3855766793409379 },
    ['Ł'] = { width = 0.7617997465145754 },
    ['ł'] = { width = 0.2899619771863118 },
    ['Ń'] = { width = 0.9977186311787072 },
    ['ń'] = { width = 0.5934347275031686 },
    ['Ņ'] = { width = 0.9977186311787072 },
    ['ņ'] = { width = 0.5934347275031686 },
    ['Ň'] = { width = 0.9977186311787072 },
    ['ň'] = { width = 0.5934347275031686 },
    ['ŉ'] = { width = 0.7056780735107732 },
    ['Ŋ'] = { width = 0.5560202788339671 },
    ['ŋ'] = { width = 0.5560202788339671 },
    ['Ō'] = { width = 0.9031432192648923 },
    ['ō'] = { width = 0.5373130544993663 },
    ['Ŏ'] = { width = 0.9031432192648923 },
    ['ŏ'] = { width = 0.5373130544993663 },
    ['Ő'] = { width = 0.9031432192648923 },
    ['ő'] = { width = 0.5373130544993663 },
    ['Œ'] = { width = 1.1203548795944234 },
    ['œ'] = { width = 0.6921673003802281 },
    ['Ŕ'] = { width = 0.9010646387832699 },
    ['ŕ'] = { width = 0.48846641318124207 },
    ['Ŗ'] = { width = 0.9010646387832699 },
    ['ŗ'] = { width = 0.48846641318124207 },
    ['Ř'] = { width = 0.9187325728770596 },
    ['ř'] = { width = 0.5050950570342205 },
    ['Ś'] = { width = 0.7129531051964512 },
    ['ś'] = { width = 0.43754119138149555 },
    ['Ŝ'] = { width = 0.7129531051964512 },
    ['ŝ'] = { width = 0.43754119138149555 },
    ['Ş'] = { width = 0.7129531051964512 },
    ['ş'] = { width = 0.43754119138149555 },
    ['Š'] = { width = 0.7129531051964512 },
    ['š'] = { width = 0.43754119138149555 },
    ['Ţ'] = { width = 0.7566032953105196 },
    ['ţ'] = { width = 0.4572877059569075 },
    ['Ť'] = { width = 0.7566032953105196 },
    ['ť'] = { width = 0.4427376425855513 },
    ['Ŧ'] = { width = 0.7566032953105196 },
    ['ŧ'] = { width = 0.4572877059569075 },
    ['Ũ'] = { width = 0.8179214195183777 },
    ['ũ'] = { width = 0.5352344740177439 },
    ['Ū'] = { width = 0.8179214195183777 },
    ['ū'] = { width = 0.5352344740177439 },
    ['Ŭ'] = { width = 0.8179214195183777 },
    ['ŭ'] = { width = 0.5352344740177439 },
    ['Ů'] = { width = 0.8179214195183777 },
    ['ů'] = { width = 0.5352344740177439 },
    ['Ű'] = { width = 0.8179214195183777 },
    ['ű'] = { width = 0.5352344740177439 },
    ['Ų'] = { width = 0.8179214195183777 },
    ['ų'] = { width = 0.5352344740177439 },
    ['Ŵ'] = { width = 1.2274017743979722 },
    ['ŵ'] = { width = 0.8989860583016477 },
    ['Ŷ'] = { width = 0.6713814955640051 },
    ['ŷ'] = { width = 0.5497845373891002 },
    ['Ÿ'] = { width = 0.6713814955640051 },
    ['Ź'] = { width = 0.7025602027883396 },
    ['ź'] = { width = 0.5508238276299113 },
    ['Ż'] = { width = 0.7025602027883396 },
    ['ż'] = { width = 0.5508238276299113 },
    ['Ž'] = { width = 0.7025602027883396 },
    ['ž'] = { width = 0.5508238276299113 },
    ['ˇ'] = { width = 0.4988593155893536 },
    ['ˈ'] = { width = 1.064233206590621 },
    ['˘'] = { width = 0.4177946768060837 },
    ['˛'] = { width = 0.45105196451204055 },
    ['Ё'] = { width = 0.7462103929024081 },
    ['А'] = { width = 0.7753105196451204 },
    ['Б'] = { width = 0.7888212927756654 },
    ['В'] = { width = 0.76595690747782 },
    ['Г'] = { width = 0.6350063371356147 },
    ['Д'] = { width = 0.7898605830164765 },
    ['Е'] = { width = 0.7462103929024081 },
    ['Ж'] = { width = 1.0538403041825095 },
    ['З'] = { width = 0.7326996197718632 },
    ['И'] = { width = 0.8179214195183777 },
    ['Й'] = { width = 0.8179214195183777 },
    ['К'] = { width = 0.7420532319391635 },
    ['Л'] = { width = 0.8387072243346008 },
    ['М'] = { width = 0.9395183776932826 },
    ['Н'] = { width = 0.8158428390367554 },
    ['О'] = { width = 0.9031432192648923 },
    ['П'] = { width = 0.8096070975918884 },
    ['Р'] = { width = 0.8137642585551331 },
    ['С'] = { width = 0.7243852978453739 },
    ['Т'] = { width = 0.7566032953105196 },
    ['У'] = { width = 0.6121419518377693 },
    ['Ф'] = { width = 1.022661596958175 },
    ['Х'] = { width = 0.7025602027883396 },
    ['Ц'] = { width = 0.758681875792142 },
    ['Ч'] = { width = 0.7981749049429658 },
    ['Ш'] = { width = 1.0070722433460075 },
    ['Щ'] = { width = 1.0559188846641319 },
    ['Ъ'] = { width = 0.8179214195183777 },
    ['Ы'] = { width = 1.1868694550063372 },
    ['Ь'] = { width = 0.7877820025348542 },
    ['Э'] = { width = 0.7576425855513308 },
    ['Ю'] = { width = 1.0559188846641319 },
    ['Я'] = { width = 0.9021039290240811 },
    ['а'] = { width = 0.5123700887198986 },
    ['б'] = { width = 0.5165272496831432 },
    ['в'] = { width = 0.48742712294043095 },
    ['г'] = { width = 0.42610899873257285 },
    ['д'] = { width = 0.4926235741444867 },
    ['е'] = { width = 0.454169835234474 },
    ['ж'] = { width = 0.6994423320659062 },
    ['з'] = { width = 0.4572877059569075 },
    ['и'] = { width = 0.5560202788339671 },
    ['й'] = { width = 0.5560202788339671 },
    ['к'] = { width = 0.47495564005069707 },
    ['л'] = { width = 0.5799239543726236 },
    ['м'] = { width = 0.650595690747782 },
    ['н'] = { width = 0.5238022813688213 },
    ['о'] = { width = 0.5373130544993663 },
    ['п'] = { width = 0.5508238276299113 },
    ['р'] = { width = 0.5549809885931559 },
    ['с'] = { width = 0.45105196451204055 },
    ['т'] = { width = 0.8251964512040557 },
    ['у'] = { width = 0.5497845373891002 },
    ['ф'] = { width = 0.7212674271229405 },
    ['х'] = { width = 0.5830418250950571 },
    ['ц'] = { width = 0.5435487959442332 },
    ['ч'] = { width = 0.48638783269961977 },
    ['ш'] = { width = 0.8730038022813689 },
    ['щ'] = { width = 0.8989860583016477 },
    ['ъ'] = { width = 0.5653738910012674 },
    ['ы'] = { width = 0.6807351077313054 },
    ['ь'] = { width = 0.48015209125475283 },
    ['э'] = { width = 0.46664131812420784 },
    ['ю'] = { width = 0.7378960709759189 },
    ['я'] = { width = 0.49158428390367553 },
    ['ё'] = { width = 0.454169835234474 },
    ['ẞ'] = { width = 0.677617237008872 },
    ['‐'] = { width = 0.3263371356147022 },
    ['‑'] = { width = 0.3263371356147022 },
    ['‒'] = { width = 0.42506970849176173 },
    ['–'] = { width = 0.42403041825095056 },
    ['—'] = { width = 0.6495564005069708 },
    ['‘'] = { width = 0.17875792141951838 },
    ['’'] = { width = 0.17875792141951838 },
    ['“'] = { width = 0.352319391634981 },
    ['”'] = { width = 0.352319391634981 },
    ['․'] = { width = 0.26605830164765526 },
    ['‥'] = { width = 0.48846641318124207 },
    ['…'] = { width = 0.7223067173637516 },
}

local CZ = {}

function CZ.calculateWidth(text)
    local fontSize = settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()
    local width = 0.0
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local addition = 0.0
        if characterSizeFactorsRelevantToFontSize[char] ~= nil then
            addition = (fontSize * characterSizeFactorsRelevantToFontSize[char].width)
        else
            addition = fontSize
        end
        width = width + addition
    end

    return width
end

function CZ.createCharacterSizingTools()
    local fontSize = settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()
    local charTable = {}
    for key, value in pairs(characterSizeFactorsRelevantToFontSize) do
        charTable[key] = (fontSize * value.width)
    end
    local result = {
        fontSize = fontSize,
        characterSize = charTable,
        hashedPhraseSizes = {},
    }
    result.getSize = function(text)
        if result.hashedPhraseSizes[text] then
            return result.hashedPhraseSizes[text]
        end

        local width = 0.0

        for _, thisCharacterByte in utf8.codes(text) do
            local char = utf8.char(thisCharacterByte)
            local addition = 0.0
            if result.characterSize[char] ~= nil then
                addition = result.characterSize[char]
            else
                addition = result.fontSize
            end
            width = width + addition
        end

        result.hashedPhraseSizes[text] = width

        return width
    end
    return result
end

return CZ
