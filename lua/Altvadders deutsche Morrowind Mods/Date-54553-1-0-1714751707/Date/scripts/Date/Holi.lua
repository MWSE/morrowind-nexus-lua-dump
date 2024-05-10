local core = require('openmw.core')
local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')

local fHD = {"Heute ist das Fest des neuen Lebens. Damit wird die Geburt eines neuen Jahres und der Tod des alten gefeiert. Heute ist auch der Beschwörungstag von Clavicus Vile.", "Heute ist der Scheuertag! Es ist ein Fest in Hochfels, das ursprünglich dazu diente, nach dem Basar des Neuen Lebens aufzuräumen. Heute ist es ein eigenes Fest.", "Heute ist Ovank'a! Heute ist Ovank'a! Ein Tag, an dem die Bewohner der Alik'r-Wüste Gebete an Stendarr richten, in der Hoffnung auf ein mildes und gnädiges Jahr.", "Heute ist Meridias Beschwörungstag", "Heute ist der Gebetstag der Südwinde! Es ist ein Tag, der von allen Religionen Tamriels sehr ernst genommen wird. Sie beten für eine gute Pflanzsaison, und Bürger mit allen in Tamriel bekannten Leiden strömen zu den Diensten in den Tempeln der Städte, da an diesem Tag kostenlose Heilungen stattfinden.", "Heute ist der Tag des Lichts! Dieser Tag wird von vielen Dörfern in Hammerfell an der Iliac-Bucht als heiliger Tag gefeiert. Es ist ein sehr ernster Feiertag, an dem sie für gute Landwirtschaft und Fischerei beten. In der Stadt Dämmerstern in Himmelsrand werden zur Feier des Tages kleine Süßigkeiten verteilt, aber es ist nicht bekannt, ob diese Ereignisse miteinander in Verbindung stehen.", "Heute ist der Tag des Erwachens! Dieser uralte Feiertag wurde von den Menschen in Yeorth Burrowland eingeführt, um die Geister der Natur nach einem langen, kalten Winter zu wecken. Heute feiert man damit das Ende des Winters.", "Heute ist der Tag des verrückten Pelagius! In Hochfels wird dem verrückteste Kaiser der jüngeren Geschichte, Pelagius Septim III, ein Denkmal gesetzt! Es ist auch der Beschwörungstag von Sheogorath.", "Heute ist Othroktide! Die Menschen in Dwynnen feiern den Tag, an dem Baron Othrok Dwynnen von den untoten Mächten nahm, die es in der Schlacht von Wightmoor einnahmen.", "Heute ist der Tag der Befreiung! Die Menschen in Glenumbra erinnern sich an die Schlacht zwischen Aiden Direnni und der Alessianischen Armee in der ersten Ära. Dieser Tag wird mit großem... Elan gefeiert.", "Heute ist das Fest der Toten! In Himmelsrand's Windhelm wird ein großes Fest abgehalten, und während des Festes werden die Namen der Fünfhundert Gefährten von Ysgramor rezitiert.", "Heute ist der Tag des Herzens! Heute wird den jüngeren Generationen die Legende der Liebenden Polydor und Eloisa vorgesungen. Viele Gasthäuser in verschiedenen Städten bieten kostenlose Zimmer für Besucher an, denn wenn man den Liebenden so freundlich begegnet wäre, würde es auf der Welt immer Frühling sein. Heute ist auch der Beschwörungstag von Sanguine.", "Heute ist der Tag der Beharrlichkeit! Einst war es ein feierlicher Gedenktag für diejenigen, die im Kampf gegen den kamoranischen Usurpator gefallen sind. Heute jedoch ist er in Ykalon zu einem wahren Fest geworden!", "Heute ist Aduros Nau! Die Dörfer in Bantha feiern am Aduros Nau die niederen Triebe, die mit der Frühlingszeit kommen. Die Traditionen sind zwar von Dorf zu Dorf unterschiedlich, aber keine von ihnen ist übermäßig tugendhaft.", "Heute ist Hermaeus Moras Beschwörungstag", "Heute ist der Tag der Erstbepflanzung! Es ist ein Fest, an dem die Samen der Herbsternte gepflanzt werden. Es ist auch das Fest des Neubeginns, sowohl für die Pflanzen als auch für die Menschen und die Mer überall. Nachbarn werden in ihren Streitigkeiten versöhnt, Beschlüsse gefasst, schlechte Gewohnheiten abgelegt und Kranke geheilt. Kleriker bieten heute oft kostenlose Heilungsdienste an!", "Heute ist der Tag des Wartens! An diesem Tag schließen sich die Siedlungen in den Drachenschwanzbergen ein, denn jedes Jahr soll an diesem Tag ein Drache aus der Wüste kommen und die Bösen verschlingen.", "Heute ist Azuras Beschwörungstag", "Heute ist Blumentag! In Hochfels pflücken die Kinder die neuen Frühlingsblumen, während die älteren Bretonen die Saison mit Tanz und Gesang begrüßen.", "Heute ist das Basar-Fest! Die Bewohner der Alik'r-Wüste feiern den Sieg der ersten Rothwardonen über eine Rasse riesiger Goblins und ihren Gott Malooc. Die Geschichte wird von vielen Gelehrten als Mythos betrachtet, aber es ist trotzdem ein sehr beliebter Feiertag in der Wüste.", "Heute ist der Tag der Gardtide! Die Menschen in Tamarilyn Point veranstalten ein Fest zu Ehren von Druagaa, der alten Göttin der Blumen. Obwohl die eigentliche Verehrung der Göttin so gut wie ausgestorben ist, ist das Fest immer ein großer Erfolg.", "Heute ist Beschwörungstag der Peryite", "Heute ist der Tag der Toten! In Dolchsturz glaubt man, dass sich die Toten an diesem Feiertag erheben, um Rache an den Lebenden zu üben. In 3E 404 begann König Lysandus' Gespenst an diesem Tag seinen Spuk.", "Heute ist der Tag der Schande. An der Küste von Hammerfell verlässt niemand sein Haus. Man glaubt, dass an diesem Tag ein Karminrotes Schiff mit Opfern der Knahaten-Plage, denen vor Hunderten von Jahren die Zuflucht verweigert wurde, zurückkehrt.", "Heute ist das Basar der Narren! An diesem Tag ermutigen Truppen von Narren und Närrinnen die Menschen aller Gesellschaftsschichten, das Närrische und Absurde zu feiern. Schausteller ziehen durch die Straßen und verspotten die Mächtigen, und die Städte feiern mit festlichen Streichen und albernen Spielen!", "Heute ist der Tag der zweiten Pflanzung! Dieser Tag ist ähnlich wie die erste Aussaat, aber mit dem Schwerpunkt auf Verbesserungen der ersten Aussaat und der Seele. Die kostenlosen Kliniken der Tempel sind zum letzten Mal in diesem Jahr geöffnet und bieten Heilung für alle, die an einer Krankheit oder einem Gebrechen leiden. Da zu dieser Zeit der Frieden betont wird, werden Kampfverletzungen nur zum vollen Preis geheilt.", "Heute ist der Tag des Marukh! Einige Gemeinschaften im Skeffington Wald feiern, indem sie sich mit dem tugendhaften Propheten Marukth vergleichen. Die Menschen beten um die Kraft, der Versuchung zu widerstehen. Heute ist auch Namiras Beschwörungstag.", "Heute ist das Feuerfest! In Nordmoor, Hochfels, feiern die Menschen, was in alten Tagen als pompöse Zurschaustellung von Magie und militärischer Stärke begann. Heute ist einfach ein Fest.", "Heute ist der Tag des Fischfangs! Die Bretonen, die an der Iliac-Bucht leben, feiern den Reichtum, den die Bucht bietet. An diesem Tag neigen sie dazu, so viel Lärm zu machen, dass die Fische wochenlang verscheucht werden!", "Heute ist Drigh R'Zimb! In Abibon-Gora feiern die Rothwardonen in der heißesten Zeit des Jahres ein Fest für die Sonne Daibethe", "Heute ist Hircines Beschwörungstag", "Heute ist das Fest zur Jahresmitte! Die Tempel bieten Segnungen für nur die Hälfte der üblichen Spende an. Einige, die gesegnet werden, fühlen sich sicher genug, um gefährliche Verliese zu betreten, auf die sie nicht vorbereitet sind, und so ist dieses freudige Fest dafür bekannt, ein Tag der Niederlage und Tragödie zu werden.", "Heute ist der Tag des Tanzes! In Dolchsturz hat der Rote Prinz Atryck diesen Tag in der zweiten Ära populär gemacht. Es ist ein Anlass für großen Pomp und Fröhlichkeit für das gesamte Volk von Dolchsturz.", "Heute ist Tibedetha! Das Volk von Alcaire feiert Tiber Septim, der dort geboren wurde.", "Heute ist das Basar-Fest der Kaufleute! Heute haben alle Marktplätze und Ausrüstungsgeschäfte ihre Preise um mindestens die Hälfte gesenkt! Der einzige, der die Preise nicht senkt, ist die Magiergilde. Heute ist auch Vaernimas Beschwörungstag.", "Heute ist Divad Etep't! Das Volk von Antiphyllos betrauert heute den Tod eines der größten Helden der frühen Rothwardonen, Divant.", "Heute ist Sonnenruhe! Heute sind die meisten Geschäfte geschlossen, da die meisten Bürger diesen Tag der Entspannung und nicht dem Handel oder dem Gebet widmen wollen. Tempel, Tavernen und die Magiergilde sind jedoch weiterhin geöffnet.", "Heute ist Feuernacht! Heute feiern die Bewohner der Alik'r-Wüste den heißesten Tag des Jahres. Es ist ein lebhaftes Fest mit einer Bedeutung, die in der Antike verloren ging.", "Heute ist Jungfrau Katrica! Die Einwohner von Ayasofya zeigen ihre Wertschätzung für den Krieger, der ihr Land gerettet hat. Dies ist ihr größtes Fest des Jahres.", "Heute ist Koomu Alezer'i! Dieser Feiertag bedeutet 'Wir erkennen an' und wird in Sentinel seit Tausenden von Jahren gefeiert. Sie danken den Göttern feierlich für ihre Gaben und beten darum, der Gnade der Götter würdig zu sein.", "Heute ist das Fest des Tigers! Im Bantha-Regenwald feiern sie in jedem Dorf ein großes Fest, um die reiche Ernte zu preisen!", "Heute ist der Tag der Anerkennung! In der Provinz Anticlere betrachten die Menschen diesen Tag als einen heiligen und besinnlichen Tag, der ihrer Schutzgöttin Mara gewidmet ist.", "Heute ist das Ende der Ernte! Die Arbeit des Jahres ist vorbei! Das Säen, Säen und Ernten ist getan! Jetzt ist es an der Zeit, zu feiern und die Früchte der Ernte zu genießen! Die Tavernen bieten den ganzen Tag über kostenlose Getränke an!", "Heute ist der Tag der Märchen und Talare! Die Älteren, die abergläubisch sind, sprechen den ganzen Tag nicht, aus Angst, dass die bösen Geister der Toten in ihren Körper eindringen könnten. Die Jüngeren genießen den Tag, vermeiden es aber trotzdem, in der Nacht auszugehen, denn jeder weiß, dass die Toten in der Nacht wandeln.", "Heute ist Khurat! Jede Stadt in den Wrothgarischen Bergen feiert diesen Tag, an dem die besten jungen Gelehrten in die verschiedenen Priesterschaften aufgenommen werden. Selbst diejenigen, die keine Kinder im Alter haben, gehen hin, um für die Weisheit und das Wohlwollen des Klerus zu beten.", "Heute ist Riglametha! Die Menschen in Lainlyn feiern die vielen Segnungen ihrer Stadt. Es werden Feste zu Themen wie dem Ghraewaj abgehalten, als die Daedra-Anbeter in Lainlyn für ihre Blasphemie in Harpyien verwandelt wurden.", "Heute ist Kindertag! Ursprünglich ein Gedenktag für Dutzende von Kindern, die von Vampiren aus Betony entführt und nie wieder gesehen wurden. Heute ist es ein Fest der Jugend.", "Heute ist Dirij Tereur! In der Alik'r-Wüste ist heute ein heiliger Tag zu Ehren von Frandar Hund, dem geistigen Führer der Rothwardonen, der sie nach Hammerfell geführt hat.", "Heute ist Malacaths Beschwörungstag", "Heute ist das Hexenfest! An diesem Tag werden Geister, Dämonen und böse Geister verspottet. Bettler fragen auf der Straße nach Almosen, während Kinder nach Festtagsleckereien fragen und die Menschen verpflichtet sind, sie ihnen zu geben. Heute ist auch der Beschwörungstag von Mephala", "Heute ist der Tag der zerbrochenen Diamanten. In Glen gedenkt man des Todes von Kintyra Septim II. Sie wurde auf Befehl ihres Cousins und Usurpators Uriel III. getötet. Es ist ein stiller Tag des Gebets für die Weisheit und das Wohlwollen der kaiserlichen Familie von Tamriel.", "Heute ist der Tag des Kaisers! Dies ist der Geburtstag des Kaisers. In der kaiserlichen Stadt unterhalten große Wanderkarnevals die Massen, während der Adel die alljährliche Goblinjagd zu Pferd genießt.", "Heute ist Boethias Beschwörungstag", "Heute ist der Tanz der Schlange! In Satakalaam war dieser Tag ursprünglich ein ernsthafter religiöser Feiertag, der einem Schlangengott gewidmet war. Heute ist er nur noch ein Grund für ein Straßenfest.", "Heute ist das Mondfest! In den Glenumbra-Mooren feiern die Bretonen das Mondfest. Es ist ein fröhlicher Feiertag zu Ehren von Secunda, der Göttin des Mondes.", "Heute ist Hel Anseilak! Für das Volk von Pothago ist dies der heiligste Tag. Der Tag bedeutet 'Gemeinschaft mit den Heiligen des Schwertes' und feiert das reiche Erbe des alten Weges der Hel Ansei.", "Heute ist das Basar-Fest der Krieger! An diesem Tag verkaufen Ausrüstungsgeschäfte und Schmiede Waffen zum halben Preis! Das führt oft dazu, dass untrainierte Jungen in Amateurscharmützel verwickelt werden. Heute ist auch der Beschwörungstag von Mehrunes Dagon.", "Heute ist der Gebetstag der Nordwinde! Heute danken die Menschen den Göttern für eine gute Ernte und einen milden Winter. Die Tempel bieten alle ihre Dienste für die Hälfte des normalen Spendenbetrags an.", "Heute ist Baranth Do! Dieser Feiertag bedeutet 'Abschied von der Bestie des letzten Jahres' und wird in der Alik'r-Wüste gefeiert. Heute sind Feste mit dämonischen Darstellungen des alten Jahres beliebt.", "Heute ist Chil'a! Der heutige Tag, der 'Segen des neuen Jahres' bedeutet, ist sowohl ein heiliger Tag als auch ein Fest. Erzpriester und Baronin weihen jeweils die Asche des alten Jahres in einer feierlichen Zeremonie, gefolgt von Straßenumzügen, Bällen und Turnieren. Heute ist auch der Beschwörungstag von Molag Bal.", "Heute ist Saturalia! Einst ein Feiertag für den Gott der Ausschweifung, hat sich dieser Tag zu einer Zeit des Schenkens, der Feste und der Paraden entwickelt.", "Heute ist das Basar-Fest des alten Lebens! Dies ist eine Zeit, in der die Menschen Botschaften zum Gedenken an ihre verstorbenen Angehörigen schreiben und vielleicht gelegentlich eine Antwort von Aetherius erhalten. Es ist eine Zeit, in der man über das vergangene Jahr nachdenkt."}

local function seti()
  local t = calendar.formatGameTime('*t')
  if t.day == 1 and t.month == 1 then i = 1
   return i
  elseif t.day == 2 and t.month == 1 then i = 2
   return i
  elseif t.day == 12 and t.month == 1 then i = 3
   return i
  elseif t.day == 13 and t.month == 1 then i = 4
   return i
  elseif t.day == 15 and t.month == 1 then i = 5
   return i
  elseif t.day == 16 and t.month == 1 then i = 6
   return i
  elseif t.day == 18 and t.month == 1 then i = 7
   return i
  elseif t.day == 2 and t.month == 2 then i = 8
   return i
  elseif t.day == 5 and t.month == 2 then i = 9
   return i
  elseif t.day == 8 and t.month == 2 then i = 10
   return i
  elseif t.day == 13 and t.month == 2 then i = 11
   return i
  elseif t.day == 16 and t.month == 2 then i = 12
   return i
  elseif t.day == 27 and t.month == 2 then i = 13
   return i
  elseif t.day == 28 and t.month == 2 then i = 14
   return i
  elseif t.day == 5 and t.month == 3 then i = 15
   return i
  elseif t.day == 7 and t.month == 3 then i = 16
   return i
  elseif t.day == 9 and t.month == 3 then i = 17
   return i
  elseif t.day == 21 and t.month == 3 then i = 18
   return i
  elseif t.day == 25 and t.month == 3 then i = 19
   return i
  elseif t.day == 26 and t.month == 3 then i = 20
   return i
  elseif t.day == 1 and t.month == 4 then i = 21
   return i
  elseif t.day == 9 and t.month == 4 then i = 22
   return i
  elseif t.day == 13 and t.month == 4 then i = 23
   return i
  elseif t.day == 20 and t.month == 4 then i = 24
   return i
  elseif t.day == 28 and t.month == 4 then i = 25
   return i
  elseif t.day == 7 and t.month == 5 then i = 26
   return i
  elseif t.day == 9 and t.month == 5 then i = 27
   return i
  elseif t.day == 20 and t.month == 5 then i = 28
   return i
  elseif t.day == 30 and t.month == 5 then i = 29
   return i
  elseif t.day == 1 and t.month == 6 then i = 30
   return i
  elseif t.day == 5 and t.month == 6 then i = 31
   return i
  elseif t.day == 16 and t.month == 6 then i = 32
   return i
  elseif t.day == 23 and t.month == 6 then i = 33
   return i
  elseif t.day == 24 and t.month == 6 then i = 34
   return i
  elseif t.day == 10 and t.month == 7 then i = 35
   return i
  elseif t.day == 12 and t.month == 7 then i = 36
   return i
  elseif t.day == 20 and t.month == 7 then i = 37
   return i
  elseif t.day == 29 and t.month == 7 then i = 38
   return i
  elseif t.day == 2 and t.month == 8 then i = 39
   return i
  elseif t.day == 11 and t.month == 8 then i = 40
   return i
  elseif t.day == 14 and t.month == 8 then i = 40
   return i
  elseif t.day == 21 and t.month == 8 then i = 42
   return i
  elseif t.day == 27 and t.month == 8 then i = 43
   return i
  elseif t.day == 3 and t.month == 9 then i = 44
   return i
  elseif t.day == 6 and t.month == 9 then i = 45
   return i  
  elseif t.day == 12 and t.month == 9 then i = 46
   return i
  elseif t.day == 19 and t.month == 9 then i = 47
   return i
  elseif t.day == 5 and t.month == 10 then i = 48
   return i
  elseif t.day == 8 and t.month == 10 then i = 49
   return i
  elseif t.day == 13 and t.month == 10 then i = 50
   return i   
  elseif t.day == 23 and t.month == 10 then i = 51
   return i
  elseif t.day == 30 and t.month == 10 then i = 52
   return i
  elseif t.day == 2 and t.month == 11 then i = 53
   return i
  elseif t.day == 3 and t.month == 11 then i = 54
   return i
  elseif t.day == 8 and t.month == 11 then i = 55
   return i
  elseif t.day == 18 and t.month == 11 then i = 56
   return i
  elseif t.day == 20 and t.month == 11 then i = 57
   return i
  elseif t.day == 15 and t.month == 12 then i = 58
   return i
  elseif t.day == 18 and t.month == 12 then i = 59
   return i
  elseif t.day == 24 and t.month == 12 then i = 60
   return i
  elseif t.day == 25 and t.month == 12 then i = 61
   return i
  elseif t.day == 31 and t.month == 12 then i = 62
   return i                                          
  else i = 0
   return i
  end
end

i = seti()


local function HdayU()
  if i >= 1 then
  ui.showMessage(fHD[i])
  end
end


local timer = nil
local hday = nil
local function startUpdating()   
  timer = time.runRepeatedly(seti, 1 * time.minute, { type = time.GameTime})   
  hday = time.runRepeatedly(HdayU, 1 * time.day, { type = time.GameTime})
end

startUpdating()

return {
  engineHandlers = {  
   onKeyPress = function(key)
    if key.code == input.KEY.H then
      ui.showMessage(fHD[i])
      end
  end,  
    }
}

