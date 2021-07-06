// [Backstories Mod (2021)]

class BackstoriesModListener extends BackStoriesModContent;

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
var bool newCampaignStarted;
var Origin CraftingOrigin;
var int ArmySizeSnapshot;

DefaultProperties
{
    Id = "OriginStory"
    IsCrafting = false;
    newCampaignStarted = true;
    CraftingOrigin = Default;
}

// This is an Events Mod listener function. 
// Called when this listener is registered with Events Mod.
function OnInitialization() 
{
    ArmySizeSnapshot = Manager.Army.length;
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

    ArmySizeSnapshot = Manager.Army.length;
}

// This is an Events Mod listener function. 
// Called when player enters any area that's not
// the world map.
function OnEnterArea()
{
    IsCrafting  = false;
    CraftingOrigin = Default;
    ArmySizeSnapshot = Manager.Army.length;
}

// This is an Events Mod listener function. 
// Called when player enters the world map.
function OnEnterWorldMap()
{
    IsCrafting  = false;
    CraftingOrigin = Default;
    ArmySizeSnapshot = Manager.Army.length;
}

// This is an Events Mod listener function.
// Called when a savefile is being loaded.
function Deserialize(JSonObject ListenerData) 
{
    // We use this function to check whether a new
    // campaign is being started or not.
    newCampaignStarted = false;
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
        ArmySizeSnapshot = Manager.Army.length;
    }
    else if(Event == 'CraftingAlchemy')
    {
        IsCrafting = true;
        CraftingOrigin = Alchemy;
        ArmySizeSnapshot = Manager.Army.length;
    }
    else if(Event == 'CraftingEngineering')
    {
        IsCrafting = true;
        CraftingOrigin = Engineering;
        ArmySizeSnapshot = Manager.Army.length;
    }
    else if(Event == 'CraftingNecromancy') // not tested yet
    {
        IsCrafting = true;
        CraftingOrigin = Necromancy;
        ArmySizeSnapshot = Manager.Army.length;
    }
    else if(Event == 'ShopClosed')
    {
        if(IsCrafting)
        {
            // There's a loop here because it's possible for players
            // to create/summon new characters more than once in the
            // crafting menu
            for(i = ArmySizeSnapshot; i < Manager.Army.Length; i++)
            {
                if(Manager.Army[i].CharacterNotes == Blank) // To prevent adding notes twice (through OnPawnAdded())
                {
                    AddOriginStory(Manager.Army[i], CraftingOrigin);
                }
            }
        }

        IsCrafting  = false;
        CraftingOrigin = Default;
        ArmySizeSnapshot = Manager.Army.length;
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

    StarterCharacterText = GetStarterCharacterText(AddedPawn);
    Notes = Blank;

    if(StarterCharacterText != Blank)
    {
        Notes $= StarterCharacterText;
    }
    else
    {
        Notes $= GetIntroText(AddedPawn, OriginStory);
        Notes $= GetAdditionalContextText(AddedPawn);

        Quote = GetCharacterQuote(AddedPawn);

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

    if(newCampaignStarted)
    {
        newCampaignStarted = false;
        FairyText = "{name} was born from Aya's fairy bulb and originally joined the {group} as a {class}.";

        Quote = GetCharacterQuote(Fairy);

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
private function string GetIntroText(RPGTacPawn AddedPawn, optional Origin OriginStory = Default)
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
        IntroText = "{name} was brought to life in {place}. They originally joined the {group} as a level {level} {class}.";
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
private function string GetAdditionalContextText(RPGTacPawn Pawn)
{
    local RPGTacPawn Type;
    Type = RPGTacPawn(Pawn.ObjectArchetype);
    
    switch(Type)
    {
        case Asher: return Blank;
        // case Aya: return Blank; // Not required
        case Bellamy: return Blank;
        case BlihBonehead: return "He was discovered in the basement of a House of Life. ";
        case Boneman: return Blank;
        case Brady: return "He and his brother Caleb once sold everything they owned to order a legendary wheel of cheese.";
        case Caleb: return "He and his brother Brady have pledged their lives to the legendary Cheese Finder, Aya.";
        case Cribbin: return Blank;
        case Dresdid: return Blank;
        // case Emi: return Blank; // Not required
        case Hari: return Blank;
        case Harktavius: return Blank;
        case Jacob: return Blank;
        // case Kakiko: return Blank; // Not required
        case Kalakanda: return Blank;
        case Kwame: return "{name} is a professor and was originally hired by House Furukawa to tutor Aya, Emi, and Yumi.";
        case Lara: return Blank;
        case Lucien: return "He was once a captain of House Furukawa and served under Salah.";
        case Majken: return Blank;
        case Malika: return Blank;
        case Maximus: return Blank;
        case Megumi: return Blank;
        case Precious: return Blank;
        case Profuse: return Blank;
        case Rone: return Blank;
        case Roto: return Blank;
        case Tanu: return Blank;
        case Wigglesworth: return Blank;
        // case Yumi: return Blank; // Not required
        default: return Blank;
    } 
}

private function string GetCharacterQuote(RPGTacPawn Pawn)
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
    if(Manager.Army.length < 20)
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

    for(i = Manager.World.StreamingLevels.Length - 1; i >= 0 ; i--)
    {
        Level = Manager.World.StreamingLevels[i];

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

    // -------- Unconfirmed, untested level names --------
    
    else if(StartsWith(LevelName, "Main_Satsuma")) // TODO
    {
        return "Satsuma";
    }
    else if(StartsWith(LevelName, "Main_Utakawa") || StartsWith(LevelName, "Main_Yamatai_Utakawa")) // TODO
    {
        return "Utakawa";
    }
    else if(StartsWith(LevelName, "Main_Yamatai")) // TODO
    {
        return "Yamatai";
    }
    
    // -------- Confirmed and tested level names --------
    
    // Starter areas
    else if(LevelName == 'Main_Boreland')
    {
        return "Ellismuir";
    }
    else if(LevelName == 'Main_SunriseFalls')
    {
        return "Sunrise Falls";
    }

    // Snow areas
    else if(StartsWith(LevelName, "Main_SnowWorld"))
    {
        return "the Icy Reach";
    }

    // Desert areas
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

    // Shadow areas
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
