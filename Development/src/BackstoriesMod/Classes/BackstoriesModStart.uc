// [Backstories Mod (2021)]

class BackstoriesModStart extends ModStart;

function OnStart(CorePlayerController Core)
{
  Core.AddPlugin(new class'BackstoriesModListener');
}

