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

        while (!vars.token.IsCancellationRequested)
        {
            foreach (var page in game.MemoryPages())
            {
                var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

                if (vars.player == IntPtr.Zero && (vars.player = scanner.Scan(playerTarget)) != IntPtr.Zero) 
                    { vars.Dbg("Player main pointer found at " + vars.player.ToString("X")); }
            }
            if (vars.player != IntPtr.Zero)
            {
                vars.player = game.ReadPointer((IntPtr)vars.player);
                vars.player = game.ReadPointer((IntPtr)vars.player);
                vars.playerController = game.ReadPointer((IntPtr)vars.player + 0x338);
                vars.Dbg("All signatures found");
                vars.Dbg("Player main found at 0x" + vars.player.ToString("X"));
                vars.Dbg("Player.PlayerController found at 0x" + vars.playerController.ToString("X"));
                //vars.Dbg("Player.PlayerController.inputEnabled should be at " + vars.playerControllerToString("X"));
                break;
            }
        }
        vars.playerInputEnabled = new MemoryWatcher<bool>(new DeepPointer(vars.playerController, 0x68));
        
    });
    vars.sigScanThread.Start();
}

update
{
    if (vars.sigScanThread.IsAlive) { return false; }
    vars.playerInputEnabled.Update(game);
    vars.Dbg("playerInputEnabled is " + vars.playerInputEnabled.Current);
}

start
{
    //if (current.introPlaying && !old.playerInputEnabled && current.playerInputEnabled) { return true; }
}

isLoading
{
    //if (current.deathLoadingScreenActive && settings["loadRemove"]) { return true; }
    //else { return false; }
}