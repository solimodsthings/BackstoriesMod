// [Backstories Mod (2021)]

class BackstoriesModStart extends EventMutator;

function OnEventManagerCreated(EventManager Manager)
{
	Manager.AddListener(new class'BackstoriesModListener');
}

