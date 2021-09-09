// [Backstories Mod (2021)]

class OriginTextListener extends OriginTextContent;


const DefaultPlace = "the world";
const Blank = "";

enum Origin
{
    Default, // Basically humans
    Summon,  // Joined through druidry
    Alchemy,
    Engineering,
    Necromancy
};

var bool IsCrafting;
// var bool newCampaignStarted;
var Origin CraftingOrigin;
var int ArmySizeSnapshot;

DefaultProperties
{
    Id = "EnhancedRecruits.OriginText"
    IsCrafting = false;
    // newCampaignStarted = true;
    CraftingOrigin = Default;
}

// This is an Events Mod listener function. 
// Called when this listener is registered with Events Mod.
function OnInitialization() 
{
    ArmySizeSnapshot = Core.Army.length;
}

// This is an Events Mod listener function. 
// Called when AddPawn() is called in the player controller
// and it returns true.
function OnPawnAdded(RPGTacPawn AddedPawn) 
{
    if(AddedPawn.CharacterNotes == Blank)
    {
        AddOriginStory(AddedPawn);
    }

    ArmySizeSnapshot = Core.Army.length;
}

// This is an Events Mod listener function. 
// Called when player enters any area that's not
// the world map.
function OnEnterArea()
{
    IsCrafting  = false;
    CraftingOrigin = Default;
    ArmySizeSnapshot = Core.Army.length;
}

// This is an Events Mod listener function. 
// Called when player enters the world map.
function OnEnterWorldMap()
{
    IsCrafting  = false;
    CraftingOrigin = Default;
    ArmySizeSnapshot = Core.Army.length;
}

// This is an Events Mod listener function.
// Called when a savefile is being loaded.
function Deserialize(JSonObject ListenerData) 
{
    // We use this function to check whether a new
    // campaign is being started or not.
    // newCampaignStarted = false;
}

// This is an Events Mod listener function. 
// Called whenever a CauseEvent command is detected.
// This is used to detect when the crafting menus
// are opened or closed by player
function OnCauseEvent(optional Name Event)
{
    local int i;

    if(Event == 'CraftingDruidry')
    {
        IsCrafting = true;
        CraftingOrigin = Summon;
        ArmySizeSnapshot = Core.Army.length;
    }
    else if(Event == 'CraftingAlchemy')
    {
        IsCrafting = true;
        CraftingOrigin = Alchemy;
        ArmySizeSnapshot = Core.Army.length;
    }
    else if(Event == 'CraftingEngineering')
    {
        IsCrafting = true;
        CraftingOrigin = Engineering;
        ArmySizeSnapshot = Core.Army.length;
    }
    else if(Event == 'CraftingNecromancy') // not tested yet
    {
        IsCrafting = true;
        CraftingOrigin = Necromancy;
        ArmySizeSnapshot = Core.Army.length;
    }
    else if(Event == 'ShopClosed')
    {
        if(IsCrafting)
        {
            // There's a loop here because it's possible for players
            // to create/summon new characters more than once in the
            // crafting menu
            for(i = ArmySizeSnapshot; i < Core.Army.Length; i++)
            {
                if(Core.Army[i].CharacterNotes == Blank) // To prevent adding notes twice (through OnPawnAdded())
                {
                    AddOriginStory(Core.Army[i], CraftingOrigin);
                }
            }
        }

        IsCrafting  = false;
        CraftingOrigin = Default;
        ArmySizeSnapshot = Core.Army.length;
    }
    /*
    else
    {
        `log("DEBUG: CauseEvent: $ " $ Event);
    }
    */

}

// Adds origin story text to the specified character's notes field.
// The origin story differs depending on the Origin provided. The default
// origin is the one used for new human recruits (ie. the ones you hire).
private function AddOriginStory(RPGTacPawn AddedPawn, optional Origin OriginStory = Default)
{
    local string StarterCharacterText;
    local string Notes;
    local string Quote;

    Notes = Blank;
    StarterCharacterText = GetStarterCharacterText(AddedPawn);

    if(StarterCharacterText != Blank) // If it comes back blank, they weren't a starter character
    {
        Notes $= StarterCharacterText;
    }
    else
    {
        Notes $= GetRecruitableCharacterText(AddedPawn, OriginStory);
        Notes $= GetSpecialCharacterText(AddedPawn); // This can come back blank and it's ok

        Quote = GetRandomQuote(AddedPawn);

        if(Quote != Blank)
        {
            Notes $= "\n\n''" $ Quote $ "''";
        }
    }

    Notes = Repl(Notes, "{name}",  AddedPawn.CharacterName);
    Notes = Repl(Notes, "{level}", AddedPawn.CharacterLevel);
    Notes = Repl(Notes, "{class}", AddedPawn.CharacterClasses[AddedPawn.CurrentCharacterClass].ClassName);
    Notes = Repl(Notes, "{place}", GetCurrentPlaceName());
    Notes = Repl(Notes, "{group}", GetGroupText());

    AddedPawn.CharacterNotes $= Notes;

}

// Text that only applies to the starting party members
private function string GetStarterCharacterText(RPGTacPawn Pawn)
{
    local RPGTacPawn Type;
    Type = RPGTacPawn(Pawn.ObjectArchetype);

    // The quotes are from actual speech options
    switch(Type)
    {
        case Aya: return "{name} is the youngest daughter of House Furukawa and originally from Sunrise Falls." 
                $ "\n\n''I'll try my best.''";
        case Emi: return "{name} is a member of House Furukawa. She is the older sister of Aya and younger sister of Yumi." 
                $ "\n\n''Now you'll see what I can do.''";
        case Yumi:  return "{name} is originally from Sunrise Falls. She is the eldest of the Furukawa sisters." 
                $ "\n\n''Our cause is just. God will see us to victory.''";
        case Kakiko: return "{name} is originally from Sunrise Falls and a companion of the Furukawa sisters." 
                $ "\n\n''Arooo!''";
        case AyaFairy: return GetStarterFairyText(Pawn);           
        default: return Blank;
    } 
}

private function string GetStarterFairyText(RPGTacPawn Fairy)
{
    local string FairyText;
    local string Quote;

    if(GetCurrentPlaceName() == "Sunrise Falls")
    {
        // newCampaignStarted = false;
        FairyText = "{name} was born from Aya's fairy bulb and originally joined the {group} as a {class}.";

        Quote = GetRandomQuote(Fairy);

        if(Quote != Blank)
        {
            FairyText $= "\n\n''" $ Quote $ "''";
        }

        return FairyText;
    }
    else
    {
        return Blank; // This will force normal druid origin text
    }
}

// Generates text applies to recruits, including those who join via crafting
// TODO: Move this out to a configurable file?
private function string GetRecruitableCharacterText(RPGTacPawn AddedPawn, optional Origin OriginStory = Default)
{
    local string IntroText;

    if(OriginStory == Summon)
    {
        IntroText = "{name} was summoned as a level {level} {class} in {place}.";
    }
    else if(OriginStory == Alchemy)
    {
        IntroText = "{name} was created through the power of alchemy in {place}. They were originally a level {level} {class}.";
    }
    else if(OriginStory == Engineering)
    {
        IntroText = "{name} was originally built in {place} as a level {level} {class}.";
    }
    else if(OriginStory == Necromancy)
    {
        switch(Rand(2))
        {
            case 1:  IntroText = "{name} was brought to life in {place}. They originally joined the {group} as a level {level} {class}."; break;
            default: IntroText = "{name} was reanimated in {place} as a level {level} {class}."; break;
        }
    }
    else
    {
        switch(Rand(3))
        {
            case 1:  IntroText =  "{name} joined the {group} while the {group} was in {place}. They were originally a level {level} {class}."; break;
            case 2:  IntroText =  "{name} joined as a level {level} {class} while the {group} was journeying in {place}."; break;
            default: IntroText =  "{name} originally joined as a level {level} {class} while the {group} was traveling through {place}."; break;
        }
    }

    return IntroText $ " "; // Gotta always remember to add that trailing space
}

// Generates some additional text for special recruits.
// TODO: Move this out to a configurable file
private function string GetSpecialCharacterText(RPGTacPawn Pawn)
{
    local RPGTacPawn Type;
    Type = RPGTacPawn(Pawn.ObjectArchetype);
    
    switch(Type)
    {
        case Asher: return "He is also known as Asher of Balek.";
        case Bellamy: return "He is also known as the bandit prince.";
        case BlihBonehead: return "He was discovered in the basement of a House of Life. ";
        case Boneman: return "He wanted to go on an adventure after being reanimated.";
        case Brady: return "He and his brother Caleb once sold everything they owned to order a legendary wheel of cheese.";
        case Caleb: return "He and his brother Brady have pledged their lives to the legendary Cheese Finder, Aya.";
        case Dresdid: return "He was once in the business of revenge.";
        case Hari: return "{name} is an old friend of Salah. He is also known as Bey Hariprasad or simply Uncle Hari to the Furukawa sisters.";
        case Harktavius: return "{name} joined the Furukawa sisters looking to go into the Shadowlands himself.";
        case Jacob: return "{name}'s wife, Maise, became ill after staying in the Shadowlands for too long. ";
        case Kalakanda: return "He once adventured the deserts with Salah and Hari.";
        case Kwame: return "{name} is a professor and the former tutor of Aya, Emi, and Yumi.";
        case Lucien: return "He was once a captain of House Furukawa and served under Salah.";
        case Malika: return "She has important insight regarding Master Griswold's projects.";
        case Maximus: return "He was once the greatest fighter in the Scrapyard arena.";
        case Precious: return "He once promised to take his cat on an adventure, but waited too long.";
        case Profuse: return "He is a connoisseur of Ittihadi currant wine.";
        case Roto: return "He was once an adventurer wandering Ittihad.";
        case Wigglesworth: return "She is also known as Professor Edwina {name}.";
        default: return Blank;
    } 
}

private function string GetRandomQuote(RPGTacPawn Pawn)
{
    local array<string> QuoteOptions;
    local string Quote;
    local int Count;

    foreach Pawn.SpeechOptions.WhenMadeSquadLeader_Localized(Quote)
    {
        QuoteOptions.AddItem(Quote);
    }

    foreach Pawn.SpeechOptions.Attacking_Localized(Quote)
    {
        QuoteOptions.AddItem(Quote);
    }

    Quote = Blank;

    Count = Pawn.SpeechOptions.WhenMadeSquadLeader_Localized.length + Pawn.SpeechOptions.Attacking_Localized.length;

    if(Count > 0)
    {
        Quote = QuoteOptions[Rand(Count)];
    }

    return Quote;
    
}

private function string GetGroupText()
{
    if(Core.Army.length < 30)
    {
        return "group";
    }
    else
    {
        return "army";
    }
}

private function bool StartsWith(Name LevelName, string Substring)
{
    return InStr(LevelName, Substring) == 0;
}

// Attempts to guess where the player is currently located
// for the purposes of generating origin story text. It can be
// a little tricky as there can be multiple levels active at the
// same time.
private function string GetCurrentPlaceName()
{
    local LevelStreaming Level;
    local string PlaceName;
    local int i;
    
    for(i = Core.World.StreamingLevels.Length - 1; i >= 0 ; i--)
    {
        
        Level = Core.World.StreamingLevels[i];
        
        if (Level != None && (Level.bIsVisible || Level.bHasLoadRequestPending))
        {
            
            PlaceName = ToFriendlyName(Level.PackageName);
            
            // If there isn't a name available, continue and check the next streaming level
            if(PlaceName != Blank) 
            {
                return PlaceName;
            }
            
        }
        
    }
     

    return DefaultPlace;
}

// Order matters in this function! Generic names should
// be placed near the bottom (eg. region names) and more granular 
// names (eg. cities or points of interest) should be at the top.
//
// If there is no friendly name for the level specified this function
// will purposely return an empty string.
//
// TODO: Move this out to a configurable file
private function string ToFriendlyName(Name LevelName)
{
    
    // Ignore
    if(LevelName == 'Main_Shadow_Caravan_01')
    {
        return Blank;
    }
    
    // Northern Shores
    else if(StartsWith(LevelName, "Main_Halgdalir"))
    {
        return "Halgdalir";
    }
    else if(StartsWith(LevelName, "Main_Grenafylki"))
    {
        return "Grenafylki";
    }
    else if(StartsWith(LevelName, "Main_Snow_DruidGrove"))
    {
        return "the Druid Grove";
    }
    else if(LevelName == 'Main_SnowWorld_02')
    {
        return "the Northern Shores";
    }

    // Yamatai (Satsuma is not listed here because you can't recruit anyone in that town)
    else if(StartsWith(LevelName, "Main_Utakawa") || StartsWith(LevelName, "Main_Yamatai_Utakawa"))
    {
        return "Utakawa";
    }
    else if(StartsWith(LevelName, "Main_ImperialCity") || StartsWith(LevelName, "Main_Yamatai_Imperial"))
    {
        return "the Imperial City of Yamatai";
    }
    else if(StartsWith(LevelName, "Main_Yamatai"))
    {
        return "Yamatai";
    }
    

    // Starter areas
    else if(LevelName == 'Main_Boreland')
    {
        return "Ellismuir";
    }
    else if(LevelName == 'Main_SunriseFalls')
    {
        return "Sunrise Falls";
    }

    // Icy Reach
    else if(LevelName == 'Main_SnowWorld_01' || StartsWith(LevelName, "Main_IcyReach_Castle"))
    {
        return "the Icy Reach";
    }

    // Ittihad al-Janub
    else if(LevelName == 'Main_Desert_Scrapyard')
    {
        return "the Scrapyard";
    }
    else if(LevelName == 'Main_Desert_Desert_WahatShali')
    {
        return "Shali Oasis";
    }
    else if(StartsWith(LevelName, "Main_Desert_Ramliyah"))
    {
        return "Al-Ramliyah";
    }
    else if(StartsWith(LevelName, "Main_DesertWorld")) // Anchor
    {
        return "the Ittihad al-Janub";
    }

    // Shadowlands
    else if(StartsWith(LevelName, "Main_Shadow_World")) // Anchor
    {
        return "the Shadowlands";
    }

    else
    {
        // We do not return the default place name here because we
        // want a chance to check other streaming levels.
        return Blank;
    }
}
