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
    Id = "OriginStories"
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

    // note replacement text for class might not work here
    switch(Type)
    {
        case Aya: return "{name} is the youngest daughter of House Furukawa and originally from Sunrise Falls.";
        case AyaFairy: return GetStarterFairyText();
        case Emi: return "{name} is a member of House Furukawa. She is the older sister of Aya and younger sister of Yumi.";
        case Kakiko: return "{name} is originally from Sunrise Falls and a companion of the Furukawa sisters.";
        case Yumi:  return "{name} is originally from Sunrise Falls. She is the eldest of the Furukawa sisters.";
        default: return Blank;
    } 
}

private function string GetStarterFairyText()
{
    if(newCampaignStarted)
    {
        newCampaignStarted = false;
        return "{name} was born from a fairy bulb that Aya was taking care of in Sunrise Falls. It originally joined the {group} as a {class}.";
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
        case Aya: return Blank; // Not required
        case Bellamy: return Blank;
        case BlihBonehead: return "He was discovered in the basement of a House of Life. ";
        case Boneman: return Blank;
        case Brady: return Blank;
        case Caleb: return Blank;
        case Cribbin: return Blank;
        case Dresdid: return Blank;
        case Emi: return Blank; // Not required
        case Hari: return Blank;
        case Harktavius: return Blank;
        case Jacob: return Blank;
        case Kakiko: return Blank; // Not required
        case Kalakanda: return Blank;
        case Kwame: return Blank;
        case Lara: return Blank;
        case Lucien: return Blank;
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
        case Yumi: return Blank; // Not required
        default: return Blank;
    } 
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
    else if(LevelName == 'Main_SunriseFalls') // TODO
    {
        return "Sunrise Falls";
    }

    else if(StartsWith(LevelName, "Main_Yamatai")) // TODO
    {
        return "Yamatai";
    }
    
    // -------- Confirmed and tested level names --------
    
    // Snow areas
    else if(StartsWith(LevelName, "Main_SnowWorld")) // TODO
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
