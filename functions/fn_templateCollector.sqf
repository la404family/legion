#include "..\macros.hpp"

/*
 * TAG_fnc_templateCollector
 *
 * Description:
 *   (Serveur uniquement) Collecte les unités template_XX placées dans l'éditeur,
 *   enregistre leur apparence (classe, chargement, genre, visage, pitch) dans
 *   la variable globale MISSION_CivilianTemplates, puis supprime ces unités de la carte.
 *   Initialise les bases de données de noms persans/afghans (masculin/féminin).
 *   Définit MISSION_fnc_applyCivilianTemplate et installe le gestionnaire
 *   EntityCreated pour les civils, indépendants et ennemis spawnés ultérieurement.
 *
 * Convention de genre (INFO.md) :
 *   template_01 à template_16 → femmes (classe contient "woman")
 *   template_17 et au-delà   → hommes
 *   La détection se fait par le nom de classe (plus robuste que le numéro).
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Server
 */

if (!isServer) exitWith {};

// ============================================================
// === BASES DE DONNÉES DE NOMS (Perse / Afghan / Takistanais)
// ============================================================

MISSION_CivilianNames_Male = [
    ["Afaq Khan", "Afaq", "Khan"],
    ["Akhtar Durrani", "Akhtar", "Durrani"],
    ["Anis Kakar", "Anis", "Kakar"],
    ["Azad Mousavi", "Azad", "Mousavi"],
    ["Faisal Karimi", "Faisal", "Karimi"],
    ["Habib Noori", "Habib", "Noori"],
    ["Jalil Hashemi", "Jalil", "Hashemi"],
    ["Karim Jafari", "Karim", "Jafari"],
    ["Omar Faizi", "Omar", "Faizi"],
    ["Rashid Taheri", "Rashid", "Taheri"],
    ["Abbas Alizadeh", "Abbas", "Alizadeh"],
    ["Abdullah Wardak", "Abdullah", "Wardak"],
    ["Adel Termos", "Adel", "Termos"],
    ["Adnan Malik", "Adnan", "Malik"],
    ["Ahmad Shah", "Ahmad", "Shah"],
    ["Ali Rezaei", "Ali", "Rezaei"],
    ["Amin Maalouf", "Amin", "Maalouf"],
    ["Amir Hosseini", "Amir", "Hosseini"],
    ["Amjad Sabri", "Amjad", "Sabri"],
    ["Arash Kamali", "Arash", "Kamali"],
    ["Arsalan Kazemi", "Arsalan", "Kazemi"],
    ["Asadullah Khalid", "Asadullah", "Khalid"],
    ["Ashraf Baradar", "Ashraf", "Baradar"],
    ["Atiq Rahimi", "Atiq", "Rahimi"],
    ["Ayman Odeh", "Ayman", "Odeh"],
    ["Aziz Ansari", "Aziz", "Ansari"],
    ["Babur Dostum", "Babur", "Dostum"],
    ["Bahram Radan", "Bahram", "Radan"],
    ["Baktash Siawash", "Baktash", "Siawash"],
    ["Bashir Ahmad", "Bashir", "Ahmad"],
    ["Bassam Tibi", "Bassam", "Tibi"],
    ["Behrouz Vosooghi", "Behrouz", "Vosooghi"],
    ["Bilal Mansour", "Bilal", "Mansour"],
    ["Boulos Khoury", "Boulos", "Khoury"],
    ["Cyrus Zarei", "Cyrus", "Zarei"],
    ["Danish Karokhel", "Danish", "Karokhel"],
    ["Dariush Eghbali", "Dariush", "Eghbali"],
    ["Dawood Sarkhosh", "Dawood", "Sarkhosh"],
    ["Ehsan Aman", "Ehsan", "Aman"],
    ["Elias Yasin", "Elias", "Yasin"],
    ["Emal Zakarya", "Emal", "Zakarya"],
    ["Esmail Khoi", "Esmail", "Khoi"],
    ["Fahim Dashty", "Fahim", "Dashty"],
    ["Farhad Darya", "Farhad", "Darya"],
    ["Farid Zaland", "Farid", "Zaland"],
    ["Farzad Farzin", "Farzad", "Farzin"],
    ["Fawad Ramiz", "Fawad", "Ramiz"],
    ["Faysal Qureshi", "Faysal", "Qureshi"],
    ["Fouad Ajami", "Fouad", "Ajami"],
    ["Ghafoor Bakhsh", "Ghafoor", "Bakhsh"],
    ["Ghassan Kanafani", "Ghassan", "Kanafani"],
    ["Ghulam Haider", "Ghulam", "Haider"],
    ["Gulbuddin Hekmatyar", "Gulbuddin", "Hekmatyar"],
    ["Hafez Assad", "Hafez", "Assad"],
    ["Hamid Karzai", "Hamid", "Karzai"],
    ["Hamza Yusuf", "Hamza", "Yusuf"],
    ["Haroon Yusufi", "Haroon", "Yusufi"],
    ["Hassan Rouhani", "Hassan", "Rouhani"],
    ["Hekmat Khalil", "Hekmat", "Khalil"],
    ["Hesam Din", "Hesam", "Din"],
    ["Homayoun Shajarian", "Homayoun", "Shajarian"],
    ["Hossein Alizadeh", "Hossein", "Alizadeh"],
    ["Ibrahim Maalouf", "Ibrahim", "Maalouf"],
    ["Idris Sadiqi", "Idris", "Sadiqi"],
    ["Ilyas Kashmiri", "Ilyas", "Kashmiri"],
    ["Imran Khan", "Imran", "Khan"],
    ["Ismael Jalal", "Ismael", "Jalal"],
    ["Jabbar Patel", "Jabbar", "Patel"],
    ["Jafar Panahi", "Jafar", "Panahi"],
    ["Jalal Talabani", "Jalal", "Talabani"],
    ["Jamal Khashoggi", "Jamal", "Khashoggi"],
    ["Jamil Sadeqi", "Jamil", "Sadeqi"],
    ["Javed Akhtar", "Javed", "Akhtar"],
    ["Jawad Sharif", "Jawad", "Sharif"],
    ["Kabir Bedi", "Kabir", "Bedi"],
    ["Kamal Salibi", "Kamal", "Salibi"],
    ["Kamran Hooman", "Kamran", "Hooman"],
    ["Kasra Nouri", "Kasra", "Nouri"],
    ["Kaveh Ahangar", "Kaveh", "Ahangar"],
    ["Khalid Hosseini", "Khalid", "Hosseini"],
    ["Khalil Zad", "Khalil", "Zad"],
    ["Khosrow Shakibai", "Khosrow", "Shakibai"],
    ["Kianoush Ayari", "Kianoush", "Ayari"],
    ["Latif Pedram", "Latif", "Pedram"],
    ["Mahdi Darius", "Mahdi", "Darius"],
    ["Mahmood Khan", "Mahmood", "Khan"],
    ["Majid Majidi", "Majid", "Majidi"],
    ["Malek Jahan", "Malek", "Jahan"],
    ["Mansour Bahrami", "Mansour", "Bahrami"],
    ["Marwan Barghouti", "Marwan", "Barghouti"],
    ["Masoud Shojaei", "Masoud", "Shojaei"],
    ["Mehdi Mahdavikia", "Mehdi", "Mahdavikia"],
    ["Mirwais Nejat", "Mirwais", "Nejat"],
    ["Mohammad Reza", "Mohammad", "Reza"],
    ["Mohsen Makhmalbaf", "Mohsen", "Makhmalbaf"],
    ["Morteza Pashaei", "Morteza", "Pashaei"],
    ["Munir Bashir", "Munir", "Bashir"],
    ["Mustafa Sandal", "Mustafa", "Sandal"],
    ["Nabil Shoail", "Nabil", "Shoail"],
    ["Nader Shah", "Nader", "Shah"],
    ["Naguib Mahfouz", "Naguib", "Mahfouz"],
    ["Najibullah Ahmadzai", "Najibullah", "Ahmadzai"],
    ["Naseeruddin Shah", "Naseeruddin", "Shah"],
    ["Nasser Al-Attiyah", "Nasser", "Al-Attiyah"],
    ["Navid Negahban", "Navid", "Negahban"],
    ["Nizar Qabbani", "Nizar", "Qabbani"],
    ["Omid Djalili", "Omid", "Djalili"],
    ["Osman Mir", "Osman", "Mir"],
    ["Parviz Parastui", "Parviz", "Parastui"],
    ["Payam Dehkordi", "Payam", "Dehkordi"],
    ["Qais Ulfat", "Qais", "Ulfat"],
    ["Qasim Soleimani", "Qasim", "Soleimani"],
    ["Rafik Hariri", "Rafik", "Hariri"],
    ["Rahim Shah", "Rahim", "Shah"],
    ["Rahman Baba", "Rahman", "Baba"],
    ["Rami Malek", "Rami", "Malek"],
    ["Ramzi Yousef", "Ramzi", "Yousef"],
    ["Reza Attaran", "Reza", "Attaran"],
    ["Rostam Farrokhzad", "Rostam", "Farrokhzad"],
    ["Saami Yusuf", "Saami", "Yusuf"],
    ["Saeed Rad", "Saeed", "Rad"],
    ["Salahuddin Rabbani", "Salahuddin", "Rabbani"],
    ["Salim Shaheen", "Salim", "Shaheen"],
    ["Salman Khan", "Salman", "Khan"],
    ["Saman Jalili", "Saman", "Jalili"],
    ["Sardar Azmoun", "Sardar", "Azmoun"],
    ["Shahrukh Khan", "Shahrukh", "Khan"],
    ["Shahzad Ismaily", "Shahzad", "Ismaily"],
    ["Shams Langroudi", "Shams", "Langroudi"],
    ["Sohrab Sepehri", "Sohrab", "Sepehri"],
    ["Sulaiman Layeq", "Sulaiman", "Layeq"],
    ["Tahir Qadri", "Tahir", "Qadri"],
    ["Tarek Fatah", "Tarek", "Fatah"],
    ["Tariq Ramadan", "Tariq", "Ramadan"],
    ["Ubaidullah Jan", "Ubaidullah", "Jan"],
    ["Vahid Amiri", "Vahid", "Amiri"],
    ["Walid Al-Shehri", "Walid", "Al-Shehri"],
    ["Waseem Badami", "Waseem", "Badami"],
    ["Yasin Malik", "Yasin", "Malik"],
    ["Yasser Arafat", "Yasser", "Arafat"],
    ["Yousef Chahine", "Yousef", "Chahine"],
    ["Zalmay Khalilzad", "Zalmay", "Khalilzad"],
    ["Zarif Zarif", "Zarif", "Zarif"],
    ["Zayn Malik", "Zayn", "Malik"],
    ["Zia Massoud", "Zia", "Massoud"]
];

MISSION_CivilianNames_Female = [
    ["Aadila Nouri", "Aadila", "Nouri"],
    ["Aaliyah Massoud", "Aaliyah", "Massoud"],
    ["Amani Rahimi", "Amani", "Rahimi"],
    ["Anisa Wahab", "Anisa", "Wahab"],
    ["Bahar Pars", "Bahar", "Pars"],
    ["Fatima Bhutto", "Fatima", "Bhutto"],
    ["Ghazal Sadat", "Ghazal", "Sadat"],
    ["Jamila Afghani", "Jamila", "Afghani"],
    ["Kubra Khademi", "Kubra", "Khademi"],
    ["Latifa Nabizada", "Latifa", "Nabizada"],
    ["Malalai Joya", "Malalai", "Joya"],
    ["Sima Samar", "Sima", "Samar"],
    ["Abir Al-Sahlani", "Abir", "Al-Sahlani"],
    ["Afra Jalil", "Afra", "Jalil"],
    ["Aisha Wardak", "Aisha", "Wardak"],
    ["Aleena Khan", "Aleena", "Khan"],
    ["Alia Zadeh", "Alia", "Zadeh"],
    ["Almas Durrani", "Almas", "Durrani"],
    ["Amal Alamuddin", "Amal", "Alamuddin"],
    ["Amira Casar", "Amira", "Casar"],
    ["Anahita Ratebzad", "Anahita", "Ratebzad"],
    ["Anbar Nadiya", "Anbar", "Nadiya"],
    ["Aqsa Parvez", "Aqsa", "Parvez"],
    ["Ara Qadir", "Ara", "Qadir"],
    ["Areeba Habib", "Areeba", "Habib"],
    ["Arezoo Tanha", "Arezoo", "Tanha"],
    ["Arwa Damon", "Arwa", "Damon"],
    ["Asal Badiee", "Asal", "Badiee"],
    ["Asma Jahangir", "Asma", "Jahangir"],
    ["Asra Nomani", "Asra", "Nomani"],
    ["Atefeh Razavi", "Atefeh", "Razavi"],
    ["Azadeh Moaveni", "Azadeh", "Moaveni"],
    ["Aziza Siddiqui", "Aziza", "Siddiqui"],
    ["Azra Akrami", "Azra", "Akrami"],
    ["Badra Ali", "Badra", "Ali"],
    ["Bahira Sherif", "Bahira", "Sherif"],
    ["Balqis Ahmed", "Balqis", "Ahmed"],
    ["Banu Ghazanfar", "Banu", "Ghazanfar"],
    ["Baran Kosari", "Baran", "Kosari"],
    ["Baria Alamuddin", "Baria", "Alamuddin"],
    ["Basma Hassan", "Basma", "Hassan"],
    ["Batool Fakoor", "Batool", "Fakoor"],
    ["Bayan Mahmoud", "Bayan", "Mahmoud"],
    ["Beheshta Arghand", "Beheshta", "Arghand"],
    ["Behnaz Jafari", "Behnaz", "Jafari"],
    ["Benafsha Yaqoobi", "Benafsha", "Yaqoobi"],
    ["Bushra Maneka", "Bushra", "Maneka"],
    ["Dalia Mogahed", "Dalia", "Mogahed"],
    ["Dana Ghazi", "Dana", "Ghazi"],
    ["Dania Khatib", "Dania", "Khatib"],
    ["Darya Safai", "Darya", "Safai"],
    ["Deena Aljuhani", "Deena", "Aljuhani"],
    ["Delaram Karkhir", "Delaram", "Karkhir"],
    ["Delbar Nazari", "Delbar", "Nazari"],
    ["Dorsa Derakhshani", "Dorsa", "Derakhshani"],
    ["Dua Khalil", "Dua", "Khalil"],
    ["Durkhanai Ayubi", "Durkhanai", "Ayubi"],
    ["Elaha Soroor", "Elaha", "Soroor"],
    ["Elham Shahin", "Elham", "Shahin"],
    ["Elnaz Shakerdoost", "Elnaz", "Shakerdoost"],
    ["Esra Bilgic", "Esra", "Bilgic"],
    ["Faiza Darkhani", "Faiza", "Darkhani"],
    ["Fakhria Khalil", "Fakhria", "Khalil"],
    ["Farah Pahlavi", "Farah", "Pahlavi"],
    ["Farangis Yeganegi", "Farangis", "Yeganegi"],
    ["Farhana Qasimi", "Farhana", "Qasimi"],
    ["Fariba Hachtroudi", "Fariba", "Hachtroudi"],
    ["Farkhunda Zahra", "Farkhunda", "Zahra"],
    ["Farzaneh Kaboli", "Farzaneh", "Kaboli"],
    ["Fatemeh Motamed", "Fatemeh", "Motamed"],
    ["Fawzia Koofi", "Fawzia", "Koofi"],
    ["Fereshteh Kazemi", "Fereshteh", "Kazemi"],
    ["Fida Qasemi", "Fida", "Qasemi"],
    ["Forough Farrokhzad", "Forough", "Farrokhzad"],
    ["Fozia Koofi", "Fozia", "Koofi"],
    ["Freshta Karim", "Freshta", "Karim"],
    ["Geeti Pasha", "Geeti", "Pasha"],
    ["Gelareh Abbasi", "Gelareh", "Abbasi"],
    ["Ghadir Mounib", "Ghadir", "Mounib"],
    ["Golshifteh Farahani", "Golshifteh", "Farahani"],
    ["Habiba Sarabi", "Habiba", "Sarabi"],
    ["Hadia Tajik", "Hadia", "Tajik"],
    ["Hafsa Zayyan", "Hafsa", "Zayyan"],
    ["Haifa Wehbe", "Haifa", "Wehbe"],
    ["Hala Gorani", "Hala", "Gorani"],
    ["Hamida Barmaki", "Hamida", "Barmaki"],
    ["Hangama Zohra", "Hangama", "Zohra"],
    ["Hania Amir", "Hania", "Amir"],
    ["Hasina Safi", "Hasina", "Safi"],
    ["Hawa Alam", "Hawa", "Alam"],
    ["Hayat Mirshad", "Hayat", "Mirshad"],
    ["Hediyeh Tehrani", "Hediyeh", "Tehrani"],
    ["Hina Rabbani", "Hina", "Rabbani"],
    ["Hind Rostom", "Hind", "Rostom"],
    ["Homa Darabi", "Homa", "Darabi"],
    ["Homira Qaderi", "Homira", "Qaderi"],
    ["Huda Kattan", "Huda", "Kattan"],
    ["Iman Abdulmajid", "Iman", "Abdulmajid"],
    ["Kamila Sidiqi", "Kamila", "Sidiqi"],
    ["Kawsar Sharifi", "Kawsar", "Sharifi"],
    ["Khadija Bashir", "Khadija", "Bashir"],
    ["Laila Freivalds", "Laila", "Freivalds"],
    ["Laila Haidari", "Laila", "Haidari"],
    ["Layla Murad", "Layla", "Murad"],
    ["Leena Alam", "Leena", "Alam"],
    ["Leila Hatami", "Leila", "Hatami"],
    ["Lima Azimi", "Lima", "Azimi"],
    ["Lina Ben Mhenni", "Lina", "Ben Mhenni"],
    ["Mahbouba Seraj", "Mahbouba", "Seraj"],
    ["Mahira Khan", "Mahira", "Khan"],
    ["Manal al-Sharif", "Manal", "al-Sharif"],
    ["Mariam Durrani", "Mariam", "Durrani"],
    ["Mariam Ghani", "Mariam", "Ghani"],
    ["Marjane Satrapi", "Marjane", "Satrapi"],
    ["Marwa Elselehdar", "Marwa", "Elselehdar"],
    ["Maryam Monsef", "Maryam", "Monsef"],
    ["Massouda Jalal", "Massouda", "Jalal"],
    ["Meena Keshwar", "Meena", "Keshwar"],
    ["Mehrnaz Dabir", "Mehrnaz", "Dabir"],
    ["Mina Mangal", "Mina", "Mangal"],
    ["Mitra Hajjar", "Mitra", "Hajjar"],
    ["Mona Zaki", "Mona", "Zaki"],
    ["Mozhdah Jamalzadah", "Mozhdah", "Jamalzadah"],
    ["Muna Wassef", "Muna", "Wassef"],
    ["Muniba Mazari", "Muniba", "Mazari"],
    ["Nadia Anjuman", "Nadia", "Anjuman"],
    ["Naghma Shaperai", "Naghma", "Shaperai"],
    ["Nahid Persson", "Nahid", "Persson"],
    ["Nargis Fakhri", "Nargis", "Fakhri"],
    ["Nargis Nehan", "Nargis", "Nehan"],
    ["Nasrin Sotoudeh", "Nasrin", "Sotoudeh"],
    ["Nawal El Saadawi", "Nawal", "El Saadawi"],
    ["Nelofer Pazira", "Nelofer", "Pazira"],
    ["Niki Karimi", "Niki", "Karimi"],
    ["Niloufar Ardalan", "Niloufar", "Ardalan"],
    ["Niloufar Bayat", "Niloufar", "Bayat"],
    ["Noor Jahan", "Noor", "Jahan"],
    ["Palwasha Hassan", "Palwasha", "Hassan"],
    ["Parvin Etesami", "Parvin", "Etesami"],
    ["Parwana Amiri", "Parwana", "Amiri"],
    ["Qamar Gul", "Qamar", "Gul"],
    ["Rabea Balkhi", "Rabea", "Balkhi"],
    ["Rahima Jami", "Rahima", "Jami"],
    ["Rania Al-Abdullah", "Rania", "Al-Abdullah"],
    ["Reem Abdullah", "Reem", "Abdullah"],
    ["Rola Ghani", "Rola", "Ghani"],
    ["Roxana Saberi", "Roxana", "Saberi"],
    ["Roya Mahboob", "Roya", "Mahboob"],
    ["Saba Qamar", "Saba", "Qamar"],
    ["Sahraa Karimi", "Sahraa", "Karimi"],
    ["Sajal Aly", "Sajal", "Aly"],
    ["Salma Zadeh", "Salma", "Zadeh"],
    ["Samira Makhmalbaf", "Samira", "Makhmalbaf"],
    ["Sanam Baloch", "Sanam", "Baloch"],
    ["Sarah Shahi", "Sarah", "Shahi"],
    ["Seeta Qasemi", "Seeta", "Qasemi"],
    ["Shabana Azmi", "Shabana", "Azmi"],
    ["Shaharzad Akbar", "Shaharzad", "Akbar"],
    ["Shirin Ebadi", "Shirin", "Ebadi"],
    ["Shukria Barakzai", "Shukria", "Barakzai"],
    ["Soheila Siddiq", "Soheila", "Siddiq"],
    ["Soraya Tarzi", "Soraya", "Tarzi"],
    ["Tahmina Alvi", "Tahmina", "Alvi"],
    ["Tahmineh Milani", "Tahmineh", "Milani"],
    ["Taraneh Alidoosti", "Taraneh", "Alidoosti"],
    ["Vida Samadzai", "Vida", "Samadzai"],
    ["Wazhma Frogh", "Wazhma", "Frogh"],
    ["Yalda Hakim", "Yalda", "Hakim"],
    ["Yasmin Levy", "Yasmin", "Levy"],
    ["Zainab Salbi", "Zainab", "Salbi"],
    ["Zara Kayani", "Zara", "Kayani"],
    ["Zarghona Walid", "Zarghona", "Walid"],
    ["Zarifa Ghafari", "Zarifa", "Ghafari"],
    ["Zohra Karimi", "Zohra", "Karimi"]
];

publicVariable "MISSION_CivilianNames_Male";
publicVariable "MISSION_CivilianNames_Female";

// ============================================================
// === POOLS D'ACTIFS VISUELS
// ============================================================

// Visages masculins perses/takistanais — classes confirmées (identityManager)
MISSION_CivilianMaleFaces = [
    "PersianHead_A3_01", "PersianHead_A3_02", "PersianHead_A3_03",
    "GreekHead_A3_01",   "GreekHead_A3_02",   "GreekHead_A3_03",
    "GreekHead_A3_04",   "GreekHead_A3_05",   "GreekHead_A3_06"
];

// Couvre-chefs masculins CUP Takistan
// Note : INFO.md utilise "CPU_H_..." → le prefix correct pour CUP est "CUP_H_..."
MISSION_CivilianHats = [
    "CUP_H_TKI_Lungee_Open_01", "CUP_H_TKI_Lungee_Open_02", "CUP_H_TKI_Lungee_Open_03",
    "CUP_H_TKI_Lungee_Open_04", "CUP_H_TKI_Lungee_Open_05", "CUP_H_TKI_Lungee_Open_06",
    "CUP_H_TKI_Pakol_1_01",     "CUP_H_TKI_Pakol_1_02",     "CUP_H_TKI_Pakol_1_03",
    "CUP_H_TKI_Pakol_1_04",     "CUP_H_TKI_Pakol_1_05",
    "CUP_H_TKI_SkullCap_01",    "CUP_H_TKI_SkullCap_02",    "CUP_H_TKI_SkullCap_03",
    "CUP_H_TKI_SkullCap_04",    "CUP_H_TKI_SkullCap_05",    "CUP_H_TKI_SkullCap_06"
];

// Barbes masculines CUP
MISSION_CivilianBeards = ["CUP_Beard_Brown", "CUP_Beard_Black"];

publicVariable "MISSION_CivilianMaleFaces";
publicVariable "MISSION_CivilianHats";
publicVariable "MISSION_CivilianBeards";

// ============================================================
// === COLLECTE DES TEMPLATES DEPUIS L'ÉDITEUR
// ============================================================

MISSION_CivilianTemplates = [];
private _toDelete = [];

{
    private _unit    = _x;
    private _varName = vehicleVarName _unit;

    // Sélection des unités dont le nom de variable commence par "template_" (insensible à la casse)
    if ((toLower _varName) find "template_" == 0) then {

        private _class    = typeOf _unit;
        private _loadout  = getUnitLoadout _unit;

        // Détection du genre via la classe : les femmes (mod Takistan) contiennent "woman"
        private _isFemale = "woman" in (toLower _class);

        // Visage : les femmes conservent leur visage de modèle (chaîne vide = défaut)
        //          les hommes reçoivent un visage perse aléatoire
        private _face = if (_isFemale) then { "" } else { selectRandom MISSION_CivilianMaleFaces };

        // Pitch : les femmes ont un pitch élevé pour simuler une voix féminine
        //         (voix "Male..PER" pitchée, technique standard ArmA 3)
        private _pitch = if (_isFemale) then { selectRandom [1.3, 1.4] } else { 1.0 };

        // Format : [classe, chargement, estFemme, visage, pitch]
        MISSION_CivilianTemplates pushBack [_class, _loadout, _isFemale, _face, _pitch];
        _toDelete pushBack _unit;

        if (DEBUG_MODE) then {
            diag_log format [
                "[TAG][templateCollector] '%1' collecté → classe : %2 | genre : %3 | visage : %4 | pitch : %5",
                _varName, _class,
                if (_isFemale) then {"F"} else {"M"},
                _face, _pitch
            ];
        };
    };

} forEach (allMissionObjects "Man");

// Suppression APRÈS la collecte complète pour éviter les effets de bord
{ deleteVehicle _x; } forEach _toDelete;

publicVariable "MISSION_CivilianTemplates";

if (DEBUG_MODE) then {
    diag_log format [
        "[TAG][templateCollector] %1 template(s) collecté(s) et supprimé(s) de la carte.",
        count MISSION_CivilianTemplates
    ];
    // Vérification post-suppression : liste tout ce qui aurait dû être supprimé mais ne l'est pas
    private _remaining = allMissionObjects "Man" select { (toLower vehicleVarName _x) find "template_" == 0 };
    if (count _remaining > 0) then {
        diag_log format [
            "[TAG][templateCollector] AVERTISSEMENT : %1 template(s) NON supprimé(s) sur la carte !",
            count _remaining
        ];
        { diag_log format ["  → varName='%1' | classe='%2' | isNull=%3 | alive=%4",
            vehicleVarName _x, typeOf _x, isNull _x, alive _x]; } forEach _remaining;
    } else {
        diag_log "[TAG][templateCollector] Vérification OK : aucun template résiduel détecté.";
    };
};

// ============================================================
// === FONCTION D'APPLICATION DU TEMPLATE À UNE UNITÉ
// ============================================================
//
// Utilisable pour les civils, indépendants et ennemis.
// Le BLUFOR (west) est exclu — il possède son propre système d'identité.
// Appelée côté serveur uniquement ; setUnitLoadout / addGoggles / addHeadgear
// sont locaux et fonctionnent car les IA sont locales au serveur à la création.

MISSION_fnc_applyCivilianTemplate = {
    params ["_agent"];

    if (isNull _agent)                                         exitWith {};
    if (!alive _agent)                                         exitWith {};
    if (isPlayer _agent)                                       exitWith {};
    if (side _agent == west)                                   exitWith {};
    
    // SÉCURITÉ ABSOLUE : Si l'unité est un template (ou femme/homme civil de base) 
    // ET qu'elle vient juste d'apparaître aux premières secondes du jeu : ON DÉTRUIT.
    private _LC = toLower(typeOf _agent);
    private _LV = toLower(vehicleVarName _agent);
    if ((_LV find "template_" == 0) || (_LV find "max_" == 0) || (_LC find "max_tak" >= 0) || (_LC find "cup_c_tk_" >= 0) && time < 10) exitWith {
        _agent hideObjectGlobal true;
        deleteVehicle _agent;
    };
    
    if (_agent getVariable ["MISSION_TemplateApplied", false]) exitWith {};
    if (count MISSION_CivilianTemplates == 0) exitWith {
        if (DEBUG_MODE) then {
            diag_log format ["[TAG][applyCivilianTemplate] AVERTISSEMENT : aucun template disponible pour %1.", _agent];
        };
    };

    _agent setVariable ["MISSION_TemplateApplied", true, true];

    // --- Sélection aléatoire d'un template ---
    private _template = selectRandom MISSION_CivilianTemplates;
    _template params ["_class", "_loadout", "_isFemale", "_face", "_pitch"];

    // --- Vêtements / équipement (local au serveur car IA server-local) ---
    _agent setUnitLoadout _loadout;

    // --- Accessoires masculins : barbe (slot lunettes) + couvre-chef aléatoires ---
    if (!_isFemale) then {
        private _beard = selectRandom MISSION_CivilianBeards;
        private _hat   = selectRandom MISSION_CivilianHats;
        removeGoggles   _agent;
        _agent addGoggles   _beard;
        removeHeadgear  _agent;
        _agent addHeadgear  _hat;
    };

    // --- Identité (nom, visage, langue perse, pitch) diffusée à tous les clients ---
    private _namesDB  = if (_isFemale) then { MISSION_CivilianNames_Female } else { MISSION_CivilianNames_Male };
    private _nameData = selectRandom _namesDB;
    private _speaker  = selectRandom ["Male01PER", "Male02PER", "Male03PER"];

    // remoteExec avec _agent comme JIP-ID : l'identité est réappliquée aux JIP
    // et annulée automatiquement si l'unité est détruite
    [_agent, _nameData, _face, _speaker, _pitch] remoteExec ["TAG_fnc_applyIdentity", 0, _agent];
};

// ============================================================
// === SUPPRESSION DE SÉCURITÉ PAR NOM DE VARIABLE ET CLASSE ===
// ============================================================
//
// On supprime directement et de force TOUTES les unités civiles (femmes Max_Tak 
// et hommes CUP_C_TK_...) qui étaient présentes au lancement sur la carte, 
// car on ne veut garder en jeu que les joueurs au tout début.

{
    private _u = _x;
    private _lowerClass = toLower (typeOf _u);
    private _lowerVar = toLower (vehicleVarName _u);

    // Supprimer si c'est un template, si c'est une femme du mod, ou si c'est un homme CUP
    if (
        (_lowerVar find "template_" == 0) || 
        (_lowerClass find "max_tak" >= 0) || 
        (_lowerClass find "max_taky" >= 0) ||
        (_lowerClass find "cup_c_tk_" >= 0)
    ) then {
        // Cacher l'unité instantanément pour qu'elle ne soit pas visible, puis la supprimer
        _u hideObjectGlobal true;
        _u setPos [0,0,0];
        deleteVehicle _u;
    };
} forEach (allMissionObjects "Man");

// Une deuxième méthode de filet par noms pour être 100% certains (les noms de femmes spécifiés)
private _specificNamesToDelete = [];
for "_i" from 1 to 100 do {
    private _padded = if (_i < 10) then { "0" + str _i } else { str _i };
    _specificNamesToDelete pushBack ("template_" + _padded);
};
// Noms spécifiques des femmes Max_Tak donnés dans le INFO.md
for "_i" from 1 to 6 do { _specificNamesToDelete pushBack ("Max_Tak_woman" + str _i); };
for "_i" from 1 to 5 do { _specificNamesToDelete pushBack ("Max_Taky_woman" + str _i); };
for "_i" from 1 to 5 do { _specificNamesToDelete pushBack ("Max_Tak2_woman" + str _i); };

{
    private _unit = missionNamespace getVariable [_x, objNull];
    if (!isNull _unit) then {
        _unit hideObjectGlobal true;
        _unit setPos [0,0,0];
        deleteVehicle _unit;
    };
} forEach _specificNamesToDelete;

// ============================================================
// === APPLICATION AUX UNITÉS DÉJÀ PRÉSENTES ET GESTIONNAIRE FUTURS SPAWNS
// ============================================================

[] spawn {
    sleep 0; // Cède le frame courant pour s'assurer que tous les deleteVehicle sont traités

    // Supprime encore une fois s'ils ont survécu dans l'autre frame
    {
        private _lowerClass2 = toLower (typeOf _x);
        private _lowerVar2 = toLower (vehicleVarName _x);
        if (
            (_lowerVar2 find "template_" == 0) || 
            (_lowerClass2 find "max_tak" >= 0) || 
            (_lowerClass2 find "cup_c_tk_" >= 0)
        ) then {
            deleteVehicle _x;
        };
    } forEach (allMissionObjects "Man");

    // Application aux unités déjà présentes (hors templates déjà supprimés)
    {
        [_x] call MISSION_fnc_applyCivilianTemplate;
    } forEach (allUnits select { !isNull _x && alive _x && !isPlayer _x });

    // Gestionnaire pour les unités spawnées ultérieurement
    addMissionEventHandler ["EntityCreated", {
        params ["_entity"];
        if (isNull _entity)                exitWith {};
        if !(_entity isKindOf "CAManBase") exitWith {};

        // Délai d'une seconde : laisse le moteur initialiser la locality et le chargement
        [_entity] spawn {
            params ["_entity"];
            sleep 1;
            if (isNull _entity || !alive _entity || isPlayer _entity) exitWith {};
            [_entity] call MISSION_fnc_applyCivilianTemplate;
        };
    }];

    if (DEBUG_MODE) then {
        diag_log "[TAG][templateCollector] Initialisation terminée. EntityCreated actif.";
    };
};
