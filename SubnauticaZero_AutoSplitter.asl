state("SubnauticaZero") {}

startup
{
	vars.Dbg = (Action<dynamic>) ((output) => print("[Subnatica: BZ ASL] " + output));
}

init
{
	var classes = new Dictionary<string, int>
	{ //  name, data
		{ "uGUI", 0x68 }
	};

	vars.CancelSource = new CancellationTokenSource();
	vars.MonoThread = new Thread(() =>
	{
		vars.Dbg("Starting mono thread.");

		int size = 0;
		IntPtr image = IntPtr.Zero, cache = IntPtr.Zero, uGUI = IntPtr.Zero;
		var mono = new Dictionary<string, IntPtr>();

		var token = vars.CancelSource.Token;
		while (!token.IsCancellationRequested)
		{
			if (game.ModulesWow64Safe().FirstOrDefault(m => m.ModuleName == "mono-2.0-bdwgc.dll") != null)
				break;

			vars.Dbg("Mono module not found. Retrying.");
			Thread.Sleep(2000);
		}

		while (!token.IsCancellationRequested)
		{
			size = new DeepPointer("mono-2.0-bdwgc.dll", 0x4980C0, 0x18).Deref<int>(game);
			image = new DeepPointer("mono-2.0-bdwgc.dll", 0x4980C0, 0x10, 0x8 * (int)(0xFA381AED % size)).Deref<IntPtr>(game);
			for (; image != IntPtr.Zero; image = game.ReadPointer(image + 0x10))
			{
				if (new DeepPointer(image, 0x0).DerefString(game, 32) != "Assembly-CSharp")
					continue;

				size = new DeepPointer(image + 0x8, 0x4D8).Deref<int>(game);
				cache = new DeepPointer(image + 0x8, 0x4E0).Deref<IntPtr>(game);
				break;
			}

			if (cache != IntPtr.Zero)
			{
				vars.Dbg("Found Assembly-CSharp.");
				break;
			}

			vars.Dbg("Assembly-CSharp not found. Retrying.");
			Thread.Sleep(2000);
		}

		while (!token.IsCancellationRequested)
		{
			bool allFound = false;
			for (int i = 0; i < size; ++i)
			{
				var klass = game.ReadPointer(cache + 0x8 * i);
				for (; klass != IntPtr.Zero; klass = game.ReadPointer(klass + 0x108))
				{
					string class_name = new DeepPointer(klass + 0x48, 0x0).DerefString(game, 64);
					if (!classes.Keys.Contains(class_name))
						continue;

					vars.Dbg("Klass is " + klass.ToString("X"));
					var ptr = new DeepPointer(klass + 0xD0, 0x8, classes[class_name]).Deref<IntPtr>(game);
					if (ptr == IntPtr.Zero) continue;

					mono[class_name] = ptr;
					vars.Dbg("Found " + class_name + " at 0x" + ptr.ToString("X"));
				}

				if (allFound = mono.Count == classes.Count) break;
			}

			if (allFound)
			{
				vars.Respawning = new MemoryWatcher<bool>(new DeepPointer(mono["uGUI"] + 0x10, 0x38, 0x20, 0x20, 0x20));

				vars.Dbg("All pointers found successfully.");
				break;
			}

			vars.Dbg("Not all classes found. Retrying.");
			Thread.Sleep(5000);
		}

		vars.Dbg("Exiting mono thread.");
	});

	vars.MonoThread.Start();
}

update
{
	if (vars.MonoThread.IsAlive) return false;

	vars.Respawning.Update(game);

	if (vars.Respawning.Old != vars.Respawning.Current)
	{ vars.Dbg("Respawning has changed from " + vars.Respawning.Old.ToString() + " to " + vars.Respawning.Current.ToString()); }
}

isLoading
{
	if (vars.Respawning.Current) { return true; }
	else { return false; }
}

start
{

}

exit
{
	vars.CancelSource.Cancel();
}

shutdown
{
	vars.CancelSource.Cancel();
}