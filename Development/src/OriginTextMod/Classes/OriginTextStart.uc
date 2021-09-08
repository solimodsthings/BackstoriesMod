// [Backstories Mod (2021)]

class OriginTextStart extends ModStart;

function OnStart(CorePlayerController Core)
{
  Core.AddPlugin(new class'OriginTextListener');
}

