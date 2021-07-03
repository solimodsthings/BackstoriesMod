// [Backstories Mod (2021)]

class BackstoriesModListener extends EventListener;

DefaultProperties
{
    Id = "Backstories"
}

const Blank = "";
const DefaultPlace = "the world";

function OnPawnAdded(RPGTacPawn AddedPawn) 
{
    AddedPawn.CharacterNotes $= GetIntroText(AddedPawn);
    AddedPawn.CharacterNotes $= GetSpecialText(AddedPawn);
}

function string GetIntroText(RPGTacPawn AddedPawn)
{
    return AddedPawn.CharacterName
        $ " originally joined as a level " $ AddedPawn.CharacterLevel
        $ " " $ AddedPawn.CharacterClasses[AddedPawn.CurrentCharacterClass].ClassName
        $ " while the army was traveling through " $ GetCurrentPlaceName() $ "."
        $ " "; // Gotta always remember to add that trailing space
}

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

function string GetCurrentPlaceName()
{
    local LevelStreaming Level;
    local int i;
    for(i = 0; i < Manager.World.StreamingLevels.Length; i++)
    {
        Level = Manager.World.StreamingLevels[i];
        if (Level != None && (Level.bIsVisible || Level.bHasLoadRequestPending))
        {
            if(!Level.bIsFullyStatic)
            {
                return ToFriendlyName(Level.PackageName);
            }
        }
    }

    return DefaultPlace;
}

// Order matters in this function! Generic names should
// be placed near the bottom (eg. region names) and more granular 
// names (eg. cities or points of interest) should be at the top.
// Todo: Move this out to a config or localization file
function string ToFriendlyName(Name LevelName)
{
    if(StartsWith(LevelName, "Main_Desert_Ramliyah"))
    {
        return "Al-Ramliyah";
    }
    else if(StartsWith(LevelName, "Main_Satsuma"))
    {
        return "Satsuma";
    }
    else if(StartsWith(LevelName, "Main_Utakawa"))
    {
        return "Utakawa";
    }
    else if(StartsWith(LevelName, "Main_Sunrise"))
    {
        return "Sunrise Falls";
    }
    else if(StartsWith(LevelName, "Main_Desert"))
    {
        return "the Ittihad al-Janub";
    }
    else if(StartsWith(LevelName, "Main_Shadow"))
    {
        return "the Shadowlands";
    }
    else if(StartsWith(LevelName, "Main_IcyReach"))
    {
        return "the Icy Reach";
    }
    else
    {
        return DefaultPlace;
    }
}

function bool StartsWith(Name LevelName, string Substring)
{
    return InStr(LevelName, Substring) == 0;
}