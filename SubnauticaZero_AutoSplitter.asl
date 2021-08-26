state ("SubnauticaZero")
{
    //bool playerInputEnabled: "UnityPlayer.dll", 0x1795118, 0x20, 0xd0, 0x8, 0x60, 0x40, 0x48, 0x68;
    //bool introPlaying: "UnityPlayer.dll", 0x179c578, 0xd0, 0xb0, 0x20, 0xd0, 0x100, 0xa0, 0xa8;

    //ushort processingCell: "UnityPlayer.dll", 0x17951d8, 0xd0, 0x8, 0x60, 0x68, 0x30, 0x38, 0x28;
    //bool largeWorldStreamerIdle: "UnityPlayer.dll", 0x1755010, 0x10, 0xd0, 0x8, 0x60, 0x68, 0x30, 0x1ab;
    //bool deathLoadingScreenActive: "UnityPlayer.dll", 0x1793f68, 0x60, 0x7c0, 0xe90, 0x38, 0x20, 0x20, 0x20;
}

startup
{
    settings.Add("loadRemove", false, "Remove death loading time (dont use yet)");

    vars.playerSigOffset = 2;
    vars.playerSignature = "48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 48 89 30 48 89 45 c0 48 b9 ?? ?? ?? ?? ?? ?? ?? ?? 90";
    vars.uGUISigOffset = 10;
    vars.uGUISignature = "55 48 8b ec 48 83 ec 20 48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 48 8b 08 33 d2 48 8d ad ?? ?? ?? ?? 49 bb ?? ?? ?? ?? ?? ?? ?? ?? 41 ff d3 85 c0 74 2c 48 b8";

    vars.Dbg = (Action<dynamic>)((output) => print("[SubnauticaZero Autosplit] " + output));
}

init
{
    vars.tokenSource = new CancellationTokenSource();
    vars.token = vars.tokenSource.Token;
    //vars.Dbg(game.MainModule.ToString());
    
    vars.sigScanThread = new Thread(() =>
    {
        vars.Dbg("starting thread");
        
        var playerTarget = new SigScanTarget(vars.playerSigOffset, vars.playerSignature);
        vars.player = IntPtr.Zero;
        var uGUITarget = new SigScanTarget(vars.uGUISigOffset, vars.uGUISignature);
        vars.uGUI = IntPtr.Zero;

        while (!vars.token.IsCancellationRequested)
        {
            int p = 0;
            foreach (var page in game.MemoryPages())
            {
                //vars.Dbg("p: " + p
                p++;
                var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

                if (vars.player == IntPtr.Zero && (vars.player = scanner.Scan(playerTarget)) != IntPtr.Zero) 
                {
                    vars.Dbg("Player main pointer found at " + vars.player.ToString("X"));
                }
                if(vars.uGUI == IntPtr.Zero && (vars.uGUI = scanner.Scan(uGUITarget)) != IntPtr.Zero)
                {
                    vars.Dbg("uGUI main pointer found at " + vars.uGUI.ToString("X"));
                }
                if (p % 50 == 0) { Thread.Sleep(20); } //for less cpu use
            }
            if (vars.player != IntPtr.Zero && vars.uGUI != IntPtr.Zero)
            {
                //DONT FORGET THE 0x !!!!
                vars.player = game.ReadPointer((IntPtr)vars.player);
                vars.player = game.ReadPointer((IntPtr)vars.player);
                vars.playerController = game.ReadPointer((IntPtr)vars.player + 0x338);

                vars.uGUI = game.ReadPointer((IntPtr)vars.uGUI); //follow the pointer to the pointer to uGUI._main
                vars.uGUI = game.ReadPointer((IntPtr)vars.uGUI); //follow the pointer to uGUI._main
                vars.SceneRespawning = game.ReadPointer((IntPtr)vars.uGUI + 0x38); //to uGUI._main.respawning
                vars.LoadingBackground = game.ReadPointer((IntPtr)vars.SceneRespawning + 0x20); //to uGUI._main.respawning.loadingBackground
                vars.LoadingBackgroundSequence = game.ReadPointer((IntPtr)vars.LoadingBackground + 0x20); // to uGUI._main.respawning.loadingBackground.sequence

                vars.Dbg("All signatures found");
                vars.Dbg("Player main found at 0x" + vars.player.ToString("X"));
                //vars.Dbg("Player.PlayerController found at 0x" + vars.playerController.ToString("X"));
                vars.Dbg("uGUI main found at 0x" + vars.uGUI.ToString("X"));
                //vars.Dbg("uGUI.SceneRespawning found at 0x" + vars.SceneRespawning.ToString("X"));
                //vars.Dbg("uGUI.SceneRespawning.loadingBackground found at 0x" + vars.LoadingBackground.ToString("X"));
                //vars.Dbg("uGUI.SceneRespawning.loadingBackground.sequence found at 0x" + vars.LoadingBackgroundSequence.ToString("X"));
                
                break;
            }
            Thread.Sleep(500);
        }
        vars.playerInputEnabled = new MemoryWatcher<bool>(vars.playerController + 0x68);
        vars.respawning = new MemoryWatcher<bool>(vars.LoadingBackgroundSequence + 0x20);
        vars.Dbg("closing thread");
    });
    vars.sigScanThread.Start();
}

update
{
    if (vars.sigScanThread.IsAlive) { return false; }
    vars.playerInputEnabled.Update(game);
    vars.respawning.Update(game);
    //vars.Dbg("respawning is " + vars.respawning.Current);
}

start
{
    
}

isLoading
{
    if (vars.respawning.Current && settings["loadRemove"]) { return true; }
    else { return false; }
}

exit
{
    vars.tokenSource.Cancel();
}

shutdown
{
    vars.tokenSource.Cancel();
}