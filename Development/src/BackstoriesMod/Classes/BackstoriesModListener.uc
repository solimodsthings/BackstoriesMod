// [Backstories Mod (2021)]

class BackstoriesModListener extends EventListener;

enum Origin
{
    Default, // Basically humans
    Summon,  // Joined through druidry
    Alchemy,
    Engineering
};

const DefaultPlace = "the world";
const Blank = "";

var bool IsCrafting;
var Origin CraftingOrigin;
var int ArmySizeSnapshot;

DefaultProperties
{
    Id = "OriginStories"
    IsCrafting = false;
    CraftingOrigin = Default;
}

function OnInitialization()
{
    ArmySizeSnapshot = Manager.Army.length;
}

function OnPawnAdded(RPGTacPawn AddedPawn) 
{

    if(AddedPawn.CharacterNotes == Blank)
    {
        AddOriginStory(AddedPawn);
    }

    ArmySizeSnapshot = Manager.Army.length;
    
}

function AddOriginStory(RPGTacPawn AddedPawn, optional Origin OriginStory = Default)
{
    AddedPawn.CharacterNotes $= GetIntroText(AddedPawn, OriginStory);
    AddedPawn.CharacterNotes $= GetSpecialText(AddedPawn);
}

// TODO: Move this out to a configurable file?
function string GetIntroText(RPGTacPawn AddedPawn, optional Origin OriginStory = Default)
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
    else
    {
        IntroText = GetRandomizedDefaultIntroText();
    }

    IntroText = Repl(IntroText, "{name}",  AddedPawn.CharacterName);
    IntroText = Repl(IntroText, "{level}", AddedPawn.CharacterLevel);
    IntroText = Repl(IntroText, "{class}", AddedPawn.CharacterClasses[AddedPawn.CurrentCharacterClass].ClassName);
    IntroText = Repl(IntroText, "{place}", GetCurrentPlaceName());

    return IntroText $ " "; // Gotta always remember to add that trailing space
}

function string GetRandomizedDefaultIntroText()
{
    switch(Rand(3))
    {
        case 1:  return "{name} joined the army while the army was in {place}. They were originally a level {level} {class}.";
        case 2:  return "{name} joined as a level {level} {class} while the army was journeying in {place}.";
        default: return "{name} originally joined as a level {level} {class} while the army was traveling through {place}.";
    }
}

// TODO: Move this out to a configurable file
function string GetSpecialText(RPGTacPawn AddedPawn)
{
    local string PawnName;
    PawnName = AddedPawn.CharacterName;

    if(PawnName == "Blih the Bonehead")
    {
        return "He was discovered in the basement of a House of Life. ";
    }
    else
    {
        return Blank;
    }

}

function OnCauseEvent(optional Name Event)
{
    // local Origin OriginStory;
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
        IsCrafting  = true;
        CraftingOrigin = Engineering;
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
    else
    {
        // DEBUG
        `log("Backstories: Unhandled OnCauseEvent() = " $ Event);
    }
}

function OnEnterArea()
{
    IsCrafting  = false;
    CraftingOrigin = Default;
    ArmySizeSnapshot = Manager.Army.length;
}

function OnEnterWorldMap()
{
    IsCrafting  = false;
    CraftingOrigin = Default;
    ArmySizeSnapshot = Manager.Army.length;
}

private function bool StartsWith(Name LevelName, string Substring)
{
    return InStr(LevelName, Substring) == 0;
}

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
    else if(StartsWith(LevelName, "Main_Sunrise")) // TODO
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