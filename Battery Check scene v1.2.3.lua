--[[
%% properties
%% globals
--]]

--[[
-----------------------------------------------------------------------------
-- BATTERY CHECK SCENE
-----------------------------------------------------------------------------
Copyright (c) 2017 Zoran Sankovic - Sankotronic. All Rights Reserved.
Version 1.2.3

-- SCENE DESCRIPTION --------------------------------------------------------
    This scene searches for all battery operated devices included to gateway
and then checks status of the batteries. If any battery found that is bellow
set levels it will add it to the list and send list to e-mail of all users
listed. If all batteries found OK then no e-mail is sent. it is ehough for
scene to run once per day. You can use scheduler, for example my
Main scene for time based events (Main scene FTBE) to run this scene.

-- VERSION HISTORY ----------------------------------------------------------
1.2.3 - added translations for Norwegian, French, Romanian, Russian and
        Ukrainian languages.
1.2.2 - If reported battery level is 255 then it is shown as 0 %
1.2.1 - Corrected level for devices that report 255 since Sensative strips
        can report battery level higher than 100%. Corrected translations for
        Polish, German, Dutch, Slovak, Croatian, Serbian, Bosnian, Slovenian,
        Chinese, Italian languages. Removed testing code that was accidentally
        left for checking devices with rechargeable batteries in v1.2
1.2   - added possibility to define excluded and rechargeable devices. Added 3
        new messages and added translations for German, Czech, Swedish, Danish
        and French, but need translation for new 3 messages.
1.1.1 - Added translation for Polish, Dutch and Slovak
1.1   - First public release. Thanks to petergebruers for help with part of code
        that searches and sorts list of battery operated devices.
-- COPYRIGHT NOTICE ---------------------------------------------------------
Redistribution and use of this source code, with or without modification, 
is permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. The name of the author may not be used to endorse or promote products 
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY  COPYRIGHT OWNER  "AS IS"  AND ANY  EXPRESS  OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY  AND FITNESS FOR A  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT  SHALL THE AUTHOR  BE  LIABLE  FOR ANY  DIRECT,  INDIRECT, INCIDENTAL, 
SPECIAL,  EXEMPLARY,  OR CONSEQUENTIAL  DAMAGES  (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT  OF SUBSTITUTE  GOODS OR  SERVICES;  LOSS OF USE,  DATA,  OR 
PROFITS;  OR BUSINESS INTERRUPTION)  HOWEVER  CAUSED  AND  ON  ANY THEORY OF 
LIABILITY,  WHETHER  IN  CONTRACT,  STRICT  LIABILITY,  OR  TORT  (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

-- PART FOR USERS TO DEFINE GLOBALS AND STUFF with explanation --------------------
-- GLOBAL VARIABLES ---------------------------------------------------------------
-- get the table of device & scene ID's from global variable HomeTable. If using
-- then uncomment bellow line else leave it as it is!
-- local jT = json.decode(fibaro:getGlobalValue("HomeTable"));

-- SETUP E-MAIL USERS -------------------------------------------------------------
local userID = {2}

-- SETUP LANGUAGE -----------------------------------------------------------------
--[[
This are available languages. If your language is not translated yet please
translate it and send it to me to include it in next release. Thank you very much
for your help! Already translated languages are marked with OK.
HC included languages and for this you don't need to do setup  
  English              = "en" OK
  Polski               = "pl" OK
  Deutsch              = "de" OK
  Svenska              = "sv"
  Portugues            = "pt"
  Italiano             = "it" OK
  Francais             = "fr" OK
  Nederlands           = "nl" OK
  Roman                = "ro" OK
  Brazilian Portuguese = "br"
  Estonian             = "et"
  Latvian              = "lv"
  Chinese              = "cn" OK
  Russian              = "ru" OK
  Denmark              = "dk" OK
  Finland              = "fi"
  Czech Republic       = "cz"
  US English           = "us" OK
  Spanish              = "es"
Additional languages supported by this version:
Set it up for local lng two letterrs between quotes
  Slovak               = "sk" OK
  Croatian             = "hr" OK
  Bosnian              = "ba" OK
  Serbian              = "rs" OK
  Slovenian            = "si" OK
  Norwegian            = "no" OK
  Ukrainian            = "ua" OK  ]]
local lng = ''

-- SETUP DEVICES TO IGNORE --------------------------------------------------------
-- add devices ID that you want to ignore between curled brackets separated by comma
local ignoreDevicesId = {}

-- SETUP DEVICES TO RECHARGE ------------------------------------------------------
-- add devices type that you need notification when to recharge their battery
local rechargeDevicesType = {"com.fibaro.FGT001"}

-- DEBUGGING VARIABLES ------------------------------------------------------------
-- setup debugging, true is turned on, false turned off. If set to false
-- only ERROR messages will be shown in debug window
local deBug         = true

-- END OF CODE PART FOR USERS TO EDIT AND SETUP --------------------------

-- BELLOW CODE NO NEED TO MODIFY BY USER ---------------------------------

-- if there is more than one instance of scene kill the rest
if (fibaro:countScenes() > 1) then
  fibaro:abort();
end    
local version           = "1.2.3"
local preWarningLevel   = 35
local warningLevel      = 25
local replaceLevel      = 15
local rechargeLevel     = 20
local allBattDevices    = {}
local filterBattDevices = {}
local emailTitle        = ""
local emailMessage      = ""
local emailFlag         = false
local ignoreDevice      = false
local rechargeDevice    = false
local sy  = {info='\226\157\151\239\184\143', reminder='\240\159\147\139',
             warning='\226\154\160\239\184\143',
             recharge='\226\154\161\239\184\143',
             exclude='\226\157\140',
             ok='\240\159\148\139'
            }
local lT  = {
  ["en"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "English"
            },
  ["pl"] = {
            title    = "Poziom Naładowania Baterii",
            subTitle = "Następujące urządzenia wymagają uwagi:",
            info     = "INFO! id: %s - %s %s poziom baterii %s %%",
            remind   = "PRZYPOMNIENIE! id: %s - %s %s poziom baterii %s %%",
            warning  = "UWAGA! id: %s - %s %s poziom baterii %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "NAŁADUJ! id: %s - %s %s battery is on %s %%",
            found    = "Znaleziono %s urządzeń zasilanych bateryjnie",
            tobuy    = "INFO! Zamów baterię na wymianę",
            soon     = "PRZYPOMNIENIE! Wkrótce wymagana wymiana!",
            replace  = "UWAGA! Jak najszybciej wymień baterię",
            charge   = "AKUMULATOR ROZŁADOWANY! Podłącz do ładowania!",
            lang     = "Polski"
            },
  ["de"] = {            title    = "Batteriekontrolle",            subTitle = "Folgende Ger\195\164te brauchen Ihre Aufmerksamkeit:",            info     = "INFO! id: %s - %s %s Batterie ist auf %s %%",            remind   = "MAHNUNG! id: %s - %s %s Batterie ist auf %s %%",            warning  = "WARNUNG! id: %s - %s %s Batterie ist auf %s %%",            excluded = "AUSGESCHLOSSEN! id: %s - %s %s Batterie ist auf %s %%",
            recharge = "AUFLADEN! id: %s - %s %s Batterie ist auf %s %%",
            found    = "Gefunden %s batteriebetriebene Ger\195\164te",            tobuy    = "INFO! Bitte Ersatz-Batterie bestellen",            soon     = "MAHNUNG! Muss bald ersetzt werden!",            replace  = "WARNUNG! Ersetzen Sie Bitte die Batterie so schnell wie m\195\182glich",            charge   = "AUFLADEN! Bitte die Batterie aufladen!",
            lang     = "Deutsch"            },  ["sv"] = {
            title    = "Batterikontroll",            subTitle = "F\195\182ljande enheter beh\195\182ver kontrolleras:",            info     = "INFO! id: %s - %s %s batteriet \195\164r p\195\165  %s %%",            remind   = "P\195\133MINNELSE! id: %s - %s %s batteriet \195\164r p\195\165 %s %%",            warning  = "VARNING! id: %s - %s %s batteriet \195\164r p\195\165 %s %%",            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Hittade %s batteridrivna enheter",            tobuy    = "INFO! Sn\195\164lla best\195\164ll nytt batteri",            soon     = "P\195\133MINNELSE! Beh\195\182ver bytas snart!",            replace  = "VARNING! Sn\195\164lla byt batteri snarast",            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Svenska"
            },
  ["pt"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Portugues"
            },
  ["it"] = {
            title    = "Controllo della batteria",
            subTitle = "I seguenti dispositivi richiedono l\226\128\153attenzione:",
            info     = "INFO! La batteria del sensore id: %s - %s %s \195\168 sul %s %%",
            remind   = "PROMEMORIA! La batteria del sensore id: %s - %s %s \195\168 sul %s %%",
            warning  = "AVVERTIMENTO! La batteria del sensore id: %s - %s %s \195\168 sul %s %%",
            excluded = "ESCLUSI! La batteria del sensore id: %s - %s %s \195\168 sul %s %%",
            recharge = "RICARICARE! La batteria del sensore id: %s - %s %s \195\168 sul %s %%",
            found    = "Trovato %s dispositivi a batteria",
            tobuy    = "INFO! Ordinate la batteria di ricambio",
            soon     = "PROMEMORIA! Devono essere sostituiti presto!",
            replace  = "AVVERTIMENTO! Sostituire la batteria il pi\195\185 presto possibile",
            charge   = "RICARICARE! Ricaricare la batteria!",
            lang     = "Italiano"
            },
  ["fr"] = {            title    = "Verifications batteries",            subTitle = "Les appareils suivants ont besoin de votre attention:",            info     = "INFO! id: %s - %s %s batterie est a %s %%",            remind   = "RAPPEL! id: %s - %s %s batterie est a %s %%",            warning  = "ATTENTION! id: %s - %s %s batterie est a %s %%",            excluded = "EXCLU! id: %s - %s %s batterie est a %s %%",            recharge = "RECHARGE! id: %s - %s %s batterie est a %s %%",            found    = "Trouv\195\169 %s appareils a batterie",            tobuy    = "INFO! Commander une batterie de rechange",            soon     = "RAPPEL! Besoin d'\195\170tre remplac\195\169 bient\195\180t!",            replace  = "ATTENTION! Remplacez la batterie le plus t\195\180t possible",            charge   = "RECHARGE! Rechargez la batterie!",            lang     = "Francais"            },
  ["nl"] = {            title    = "Batterij contr\195\180le",            subTitle = "Volgende apparaten hebben aandacht nodig:",            info     = "INFO! id: %s - %s %s batterij is op %s %%",            remind   = "HERINNERING! id: %s - %s %s batterij is op %s %%",            warning  = "WAARSCHUWING! id: %s - %s %s batterij is op %s %%",            excluded = "UITGESLOTEN! id: %s - %s %s batterij is op %s %%",
            recharge = "OPLADEN! id: %s - %s %s batterij is op %s %%",
            found    = "Gevonden %s batterij gevoedde apparaten",            tobuy    = "INFO! Bestel vervangingsbatterij a.u.b.",            soon     = "HERINNERING! Vervanging spoedig benodigd!",            replace  = "WAARSCHUWING! Vervang de batterij zo snel mogelijk",            charge   = "OPLADEN! Laad de batterij op a.u.b!",
            lang     = "Nederlands"            },  ["ro"] = {
            title    = "Verificare baterii",
            subTitle = "Urmatoarele module au nevoie de verificare:",
            info     = "NOTIFICARE! id: %s - %s %s bateria este la %s %%",
            remind   = "REAMINTIRE! id: %s - %s %s bateria este la %s %%",
            warning  = "ATENTIE! id: %s - %s %s bateria este la %s %%",
            excluded = "EXCLUS! id: %s - %s %s bateria este la %s %%",
            recharge = "REINCARCA! id: %s - %s %s bateria este la %s %%",
            found    = "Am gasit %s module cu baterii",
            tobuy    = "NOTIFICARE! Va rog comandati baterii de rezerva",
            soon     = "REAMINTIRE! Bateria va trebui inlocuita in curand!",
            replace  = "ATENTIE! Va rog inlocuiti bateria cat de curand posibil",
            charge   = "REINCARCA! Va rog reincarcati bateria!",
            lang     = "Romanian"
            },
  ["br"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Brasilian Portuguese"
            },
  ["et"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Estonian"
            },
  ["lv"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Latvian"
            },
  ["cn"] = {
            title    = "电池检查",
            subTitle = "以下设备需要您的注意:",
            info     = "信息! id: %s - %s %s 电池在 %s %%",
            remind   = "提醒! id: %s - %s %s 电池在 %s %%",
            warning  = "警告! id: %s - %s %s 电池在 %s %%",
            excluded = "排除! id: %s - %s %s 电池在 %s %%",
            recharge = "排除! id: %s - %s %s 电池在 %s %%",
            found    = "找到 %s 个电池供电的设备",
            tobuy    = "信息! 请订购更换电池",
            soon     = "提醒! 需要很快更换!",
            replace  = "警告! 请尽快更换电池",
            charge   = "排除! 请给电池充电!",
            lang     = "中文"
            },
  ["ru"] = {
            title    = "Проверка батареи",
            subTitle = "Обратите внимания на следующие устройства:",
            info     = "УВЕДОМЛЕНИЕ! id: %s - %s %s батарея заряжена на %s %%",
            remind   = "НАПОМИНАНИЕ! id: %s - %s %s батарея заряжена на %s %%",
            warning  = "ПРЕДУПРЕЖДЕНИЕ! id: %s - %s %s батарея заряжена на %s %%",
            excluded = "ВНИМАНИЕ! id: %s - %s %s батарея заряжена на %s %%",
            recharge = "ПЕРЕЗАРЯДКА! id: %s - %s %s батарея заряжена на %s %%",
            found    = "Обнаружено %s устройств с питанием от батареи",
            tobuy    = "УВЕДОМЛЕНИЕ! Пожалуйста, закажите новую батарею для замены",
            soon     = "НАПОМИНАНИЕ! Нужно будет заменить батарею!",
            replace  = "ПРЕДУПРЕЖДЕНИЕ! Пожалуйста, замените батарею как можно скорее",
            charge   = "ПЕРЕЗАРЯДКА! Пожалуйста, зарядите батарею!",
            lang     = "Русский"
            },
  ["ua"] = {
            title    = "Перевірка батареі",
            subTitle = "Зверніть увагу на наступні пристрої:",
            info     = "ПОВІДОМЛЕННЯ! id: %s - %s %s батарея заряджена на %s %%",
            remind   = "НАГАДУВАННЯ! id: %s - %s %s батарея заряджена на %s %%",
            warning  = "ПОПЕРЕДЖЕННЯ! id: %s - %s %s батарея заряджена на %s %%",
            excluded = "УВАГА! id: %s - %s %s батарея заряджена на %s %%",
            recharge = "ПЕРЕЗАРЯДКА! id: %s - %s %s батарея заряджена на %s %%",
            found    = "Виявлено %s пристроїв з живленням від батареї",
            tobuy    = "ПОВІДОМЛЕННЯ! Будь ласка, замовте нову батарею для заміни",
            soon     = "НАГАДУВАННЯ! Потрібно буде замінити батарею!",
            replace  = "ПОПЕРЕДЖЕННЯ! Будь ласка, заменіть батарею якомога швидше",
            charge   = "ПЕРЕЗАРЯДКА! Будь ласка, зарядіть батарею!",
            lang     = "Українська"
            },
  ["dk"] = {            title    = "Batteri tjek",            subTitle = "F\195\184lgende enheder har brug for din opm\195\166rksomhed:",            info     = "INFO! id: %s - %s %s batteri er p\195\165 %s %%",            remind   = "P\195\133MINDELSE! id: %s - %s %s batteri er p\195\165 %s %%",            warning  = "ADVARSEL! id: %s - %s %s batteri er p\195\165 %s %%",            excluded = "UDELUKKET! id: %s - %s %s batter er p\195\165 %s %%",
            recharge = "GENOPLAD! id: %s - %s %s batteri er p\195\165 %s %%",
            found    = "Fundet %s batteri betjente enheder",            tobuy    = "INFO! Venligst bestil nye batterier hjem",            soon     = "P\195\133MINDELSE! Skal skiftes snart!",            replace  = "P\195\133MINDELSE! Venligst skift batterier hurtigst muligt",            charge   = "GENOPLAD! Venligst genoplad batteri!",
            lang     = "Dansk"
            },
  ["fi"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Finland"
            },
  ["cz"] = {
            title    = "Kontrola baterií",
            subTitle = "Následující zařízení vyžadují vaší pozornost:",
            info     = "INFO! id: %s - %s %s Baterie je na %s %%",
            remind   = "Připomínka! id: %s - %s %s Baterie je na %s %%",
            warning  = "Varování! id: %s - %s %s Baterije je na %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Bylo nalezeno %s bateriových zařízení",
            tobuy    = "INFO! Prosím objednejte náhradní baterie",
            soon     = "Připomínka! Baterie musí být brzo vyměněna!",
            replace  = "Varování! Prosím, co nejdříve vyměňte baterii",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Český"
            },
  ["us"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "US English"
            },
  ["es"] = {
            title    = "Battery check",
            subTitle = "Following devices need your attention:",
            info     = "INFO! id: %s - %s %s battery is on %s %%",
            remind   = "REMINDER! id: %s - %s %s battery is on %s %%",
            warning  = "WARNING! id: %s - %s %s battery is on %s %%",
            excluded = "EXCLUDED! id: %s - %s %s battery is on %s %%",
            recharge = "RECHARGE! id: %s - %s %s battery is on %s %%",
            found    = "Found %s battery operated devices",
            tobuy    = "INFO! Please order replacement battery",
            soon     = "REMINDER! Need to be replaced soon!",
            replace  = "WARNING! Please replace battery as soon as possible",
            charge   = "RECHARGE! Please recharge battery!",
            lang     = "Spanish"
            },
  ["sk"] = {
            title    = "Kontrola batérií",
            subTitle = "Nasledujúce zariadenia potrebujú vašu pozornosť:",
            info     = "INFO! id: %s - %s %s bat\195\169ria je na %s %%",
            remind   = "PRIPOMIENKA! id: %s - %s %s bat\195\169ria je na %s %%",
            warning  = "POZOR! id: %s - %s %s bat\195\169ria je na %s %%",
            excluded = "VYLÚČENÉ! id: %s - %s %s bat\195\169ria je na %s %%",
            recharge = "DOBI! id: %s - %s %s bat\195\169ria je na %s %%",
            found    = "Nájdených %s aparátov na bat\195\169riu",
            tobuy    = "INFO! Prosím objednajte výmenu bat\195\169rie",
            soon     = "PRIPOMIENKA! Čoskoro treba vymeniť!",
            replace  = "POZOR! Vymeňte bat\195\169riu čo najskôr!",
            charge   = "DOBI! Pros\195\173m dobi bat\195\169riu!",
            lang     = "Slovenčina"
            },
  ["hr"] = {
            title    = "Provjera baterija",
            subTitle = "Sljedeći uređaji trebaju vašu pozornost:",
            info     = "OBAVIJEST! id: %s - %s %s baterija je na %s %%",
            remind   = "PODSJETNIK! id: %s - %s %s baterija je na %s %%",
            warning  = "UPOZORENJE! id: %s - %s %s baterija je na %s %%",
            excluded = "ISKLJUČEN! id: %s - %s %s baterija je na %s %%",
            recharge = "NAPUNITI! id: %s - %s %s baterija je na %s %%",
            found    = "Pronađeno je %s uređaja na baterije",
            tobuy    = "OBAVIJEST! Molim naručite zamjensku bateriju",
            soon     = "PODSJETNIK! Uskoro će trebati zamijeniti bateriju!",
            replace  = "UPOZORENJE! Molim zamijenite bateriju što prije!",
            charge   = "NAPUNITI! Molim napunite bateriju!",
            lang     = "Hrvatski"
            },
  ["ba"] = {
            title    = "Provjera baterija",
            subTitle = "Sljedeći uređaji trebaju vašu pozornost:",
            info     = "OBAVIJEST! id: %s - %s %s baterija je na %s %%",
            remind   = "PODSJETNIK! id: %s - %s %s baterija je na %s %%",
            warning  = "UPOZORENJE! id: %s - %s %s baterija je na %s %%",
            excluded = "ISKLJUČEN! id: %s - %s %s baterija je na %s %%",
            recharge = "NAPUNITI! id: %s - %s %s baterija je na %s %%",
            found    = "Pronađeno je %s uređaja na baterije",
            tobuy    = "OBAVIJEST! Molim naručite zamjensku bateriju",
            soon     = "PODSJETNIK! Uskoro će trebati zamijeniti bateriju!",
            replace  = "UPOZORENJE! Molim zamijenite bateriju što prije!",
            charge   = "NAPUNITI! Molim napunite bateriju!",
            lang     = "Bosanski"
            },
  ["rs"] = {
            title    = "Tест батерија",
            subTitle = "Потребно је обратити пажњу на следеће уређаје:",
            info     = "ОБАВЕСТ! id: %s - %s %s батерија је на %s %%",
            remind   = "ПОДСЕТНИК! id: %s - %s %s батерија је на %s %%",
            warning  = "УПОЗОРЕЊЕ! id: %s - %s %s батерија је на %s %%",
            excluded = "ИСКЉУЧЕН! id: %s - %s %s батерија је на %s %%",
            recharge = "НАПУНИТИ! id: %s - %s %s батерија је на %s %%",
            found    = "Пронађено је %s уређаја на батеријe",
            tobuy    = "ОБАВЕСТ! Молимо наручите нову батерију",
            soon     = "ПОДСЕТНИК! Ускоро ће требати заменити батерију!",
            replace  = "УПОЗОРЕЊЕ! Замените батерију што је прије могуће!",
            charge   = "НАПУНИТИ! Молим напуните батерију!",
            lang     = "Српски"
            },
  ["si"] = {
            title    = "Preverite baterijo",
            subTitle = "Naslednje naprave potrebujejo vašo pozornost:",
            info     = "OBVESTILO! id: %s - %s %s baterijo je na %s %%",
            remind   = "OPOMNIK! id: %s - %s %s baterijo je na %s %%",
            warning  = "OPOZORILO! id: %s - %s %s baterijo je na %s %%",
            excluded = "IZKLJUČEN! id: %s - %s %s baterijo je na %s %%",
            recharge = "POLNJENJE! id: %s - %s %s baterijo je na %s %%",
            found    = "Na baterijah je bilo najdenih %s naprav",
            tobuy    = "OBVESTILO! Prosim, naročite rezervno baterijo",
            soon     = "OPOMNIK! Kmalu bo treba zamenjati baterijo!",
            replace  = "OPOZORILO! Zamenjajte baterijo čim prej!",
            charge   = "POLNJENJE! Please recharge battery!",
            lang     = "Slovenski"
            },
  ["no"] = {
            title    = "Batterisjekk",            subTitle = "F\195\184lgende enheter trenger tilsyn:",            info     = "INFO! id: %s - %s %s batteri er p\195\165 %s %%",            remind   = "P\195\133MINNELSE! id: %s - %s %s batteri er p\195\165 %s %%",            warning  = "ADVARSEL! id: %s - %s %s batteri er p\195\165 %s %%",            excluded = "EKSKLUDERT! id: %s - %s %s batteri er p\195\165 %s %%",            recharge = "LAD OPP! id: %s - %s %s batteri er p\195\165 %s %%",            found    = "Funnet %s batteridrevne enheter",            tobuy    = "INFO! Vennligst bestill nytt batteri",            soon     = "P\195\133MINNELSE! M\195\165 erstattes snart!",            replace  = "ADVARSEL! Vennlist bytt batteri s\195\165 snart som mulig",            charge   = "LAD OPP! Vennligst lad batteriet!",            lang     = "Norsk"            },
  }

-- debugging function in color
function logbug(color, message)
  for line in message:gmatch("[^\010\013]+") do
    local txt = line:gsub("([\038\060\062])",
      function(c)
        return "&#"..string.byte(c)..";"
      end)
    fibaro:debug(('<span style="color:%s">%s</span>'):format(color,txt))
  end
end

-- get language
function getLanguage()
  if lng == '' then
    local sT = api.get("/settings/info")
    lng = sT.defaultLanguage
  end
  if deBug then logbug("yellow", string.format("Selected language is '%s' - %s", lng, lT[lng].lang)) end
end

-- function which gets all battery operated devices and sorts them by ID
function getBatteryDevices()
  local prevNodeId = nil
  allBattDevices   = fibaro:getDevicesId({interfaces = {"battery"}, enabled = true, visible = true})

  table.sort(allBattDevices,
    function(a,b)
      local na=tonumber(fibaro:getValue(a, "nodeId"))
      local nb=tonumber(fibaro:getValue(b, "nodeId"))
      if na==nb then
        return a<b
      else
        return na<nb
      end
    end)
    -- filtering doubles
    for i, deviceId in ipairs(allBattDevices) do
      local nodeId = fibaro:getValue(deviceId, "nodeId")
      if (prevNodeId ~= nodeId) then
        table.insert(filterBattDevices, deviceId)
        prevNodeId =
        nodeId
      end
    end
    table.sort(filterBattDevices)
    if deBug then logbug("yellow", string.format(lT[lng].found, #filterBattDevices))
  end

  -- send email notification
  function sendMail(title, message)
    if #userID > 0 then
      for k, v in pairs(userID) do
        fibaro:call(v, "sendEmail", title, message); -- Send message to flagged users
        if deBug then logbug("orange", "e-mail notification sent to user "..fibaro:getName(v)) end;
      end
    else
      logbug("red", "ERROR - No users defined. Please define users to receive e-mail")
    end
  end
end
-- loop through all battery operated sensors
function checkBatteryDevices()
  emailMessage = lT[lng].subTitle.."\n\n"
  for _, d in pairs(filterBattDevices) do
    if #ignoreDevicesId > 0 then
      ignoreDevice = false
      for _, id in pairs(ignoreDevicesId) do
        if d == id then ignoreDevice = true end
      end
    end
    local v = api.get("/devices/"..d)
    if not ignoreDevice then
      if #rechargeDevicesType > 0 then
        rechargeDevice = false
        for _, t in pairs(rechargeDevicesType) do
          if v.type == t then rechargeDevice = true end
        end
      end
      if not rechargeDevice then
        if v.properties.batteryLevel <= replaceLevel then
          emailMessage = emailMessage..string.format(sy.warning.." "..lT[lng].warning, 
                         v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel).." "..
                         lT[lng].replace.."\n\n";
          logbug('red', string.format(sy.warning.." "..lT[lng].warning, 
                        v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
          emailFlag = true;
        elseif v.properties.batteryLevel <= warningLevel then
          emailMessage = emailMessage..string.format(sy.reminder.." "..lT[lng].remind,
                         v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel).." "..
                         lT[lng].soon.."\n\n";
          logbug('orange', string.format(sy.reminder.." "..lT[lng].remind,
                           v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
          emailFlag = true;
        elseif v.properties.batteryLevel <= preWarningLevel then
          emailMessage = emailMessage..string.format(sy.info.." "..lT[lng].info,
                         v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel).." "..
                         lT[lng].tobuy.."\n\n";
          logbug('yellow', string.format(sy.info.." "..lT[lng].info,
                           v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
          emailFlag = true;
        elseif v.properties.batteryLevel > 200 then
          emailMessage = emailMessage..string.format(sy.warning.." "..lT[lng].warning,
                         v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", 0).." "..
                         lT[lng].replace.."\n\n";
          logbug('red', string.format(sy.warning.." "..lT[lng].warning,
                        v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", 0))
          emailFlag = true;
        else
          logbug('lightgreen', string.format(sy.ok.." "..lT[lng].info, 
                               v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
        end
      else
        if v.properties.batteryLevel <= rechargeLevel then
          emailMessage = emailMessage..string.format(sy.recharge.." "..lT[lng].recharge,
                         v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel).." "..
                         lT[lng].charge.."\n\n";
          logbug('red', string.format(sy.recharge.." "..lT[lng].recharge,
                        v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
          emailFlag = true;
        else
          logbug('lightgreen', string.format(sy.ok.." "..lT[lng].info, 
                               v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
        end
      end
    else
      logbug('orange', string.format(sy.exclude.." "..lT[lng].excluded, 
                       v.id, v.name, "("..fibaro:getRoomNameByDeviceID(v.id)..")", v.properties.batteryLevel))
    end
  end 
end

function main()
  logbug("green", string.format("START - Battery check scene version %s - (c) 2017 Sankotronic", version))
  getLanguage()
  getBatteryDevices()
  checkBatteryDevices()
  if emailFlag then
    aP = api.get("/settings/info")
    emailTitle = aP.hcName.." "..lT[lng].title
    sendMail(emailTitle, emailMessage)
  else
    logbug("lightgreen", "All device's batteries are OK, no e-mail sent")
  end
  logbug("green", "END - Battery check scene")
end
-- MAIN CODE ----------------------------------------------------------------
main()