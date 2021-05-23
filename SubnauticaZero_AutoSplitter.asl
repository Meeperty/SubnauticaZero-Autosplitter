// Subnautica: Below Zero; Autosplitter by Kainalo and probably others later

// State
state("SubnauticaZero")
{
	uint cinematicActive : "UnityPlayer.dll", 0x17C1508, 0x8, 0x10, 0x30, 0x58, 0x28, 0x37C;
	
}

// Initialization
init
{
	vars.split = 0;
}

// Updating
update
{

}

// Startup
startup
{
    //settings.Add("option1", true, "Load Removal");
	//settings.SetToolTip("option1", "Load Description");
}

 // Start Timer
start
{
	if (current.cinematicActive == 0 && old.cinematicActive == 1)
    {
        return true;
    }
}

// Split
split
{	

}

// Reset
reset
{

}

isLoading
{

}