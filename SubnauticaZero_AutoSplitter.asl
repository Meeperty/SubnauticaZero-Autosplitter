// I apologize for this horrendously messy code, if you have any questions message me on Discord at Meeperty#1357

state ("SubnauticaZero")
{
    //these are just here for reference
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
    vars.getIsIntroActiveSigOffset = 27;
    vars.getIsIntroActiveSignature = "33 d2 48 8d 64 24 00 90 49 bb ?? ?? ?? ?? ?? ?? ?? ?? 41 ff d3 85 c0 75 0f 48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 0fb6 00 eb 05 b8 01000000 48 8d 65 00 5d c3";
    vars.storyGoalManagerSigOffset = 6;
    vars.storyGoalManagerSignature = "48 89 45 a0 48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 48 89 30 48 89 45 88 48 b9 ?? ?? ?? ?? ?? ?? ?? ?? 48 8d ad";

    vars.Dbg = (Action<dynamic>)((output) => print("[SubnauticaZero Autosplit] " + output));

    vars.introEndedAtCount = 0;
}

init
{
    vars.count = 0;

    vars.sigScanTokenSource = new CancellationTokenSource();
    vars.sigScanToken = vars.sigScanTokenSource.Token;
    vars.sigScanThread = new Thread(() =>
    {
        vars.Dbg("initiating main sig scan thread");

        var playerTarget = new SigScanTarget(vars.playerSigOffset, vars.playerSignature);
        vars.playerSignaturePtr = IntPtr.Zero;
        vars.player = IntPtr.Zero;
        var uGUITarget = new SigScanTarget(vars.uGUISigOffset, vars.uGUISignature);
        vars.uGUI = IntPtr.Zero;
        var isIntroActiveTarget = new SigScanTarget(vars.getIsIntroActiveSigOffset, vars.getIsIntroActiveSignature);
        vars.isIntroActiveAddress = IntPtr.Zero;
        var storyGoalManagerTarget = new SigScanTarget(vars.storyGoalManagerSigOffset, vars.storyGoalManagerSignature);
        vars.storyGoalManagerMainAddress = IntPtr.Zero;

        while (!vars.sigScanToken.IsCancellationRequested)
        {
            int p = 0;
            foreach (var page in game.MemoryPages())
            {
                //vars.Dbg("p: " + p
                p++;
                var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

                if (vars.playerSignaturePtr == IntPtr.Zero && (vars.playerSignaturePtr = scanner.Scan(playerTarget)) != IntPtr.Zero)
                {
                    vars.Dbg("Player signature pointer found at " + vars.playerSignaturePtr.ToString("X"));
                }
                if (vars.uGUI == IntPtr.Zero && (vars.uGUI = scanner.Scan(uGUITarget)) != IntPtr.Zero)
                {
                    vars.Dbg("uGUI main pointer found at " + vars.uGUI.ToString("X"));
                }
                if (vars.isIntroActiveAddress == IntPtr.Zero && (vars.isIntroActiveAddress = scanner.Scan(isIntroActiveTarget)) != IntPtr.Zero)
                {

                }
                if (vars.storyGoalManagerMainAddress == IntPtr.Zero && (vars.storyGoalManagerMainAddress = scanner.Scan(storyGoalManagerTarget)) != IntPtr.Zero)
                {
                    vars.Dbg("storyGoalManager main pointer found at " + vars.storyGoalManagerMainAddress.ToString("X"));
                }
                if (p % 50 == 0) { Thread.Sleep(25); } //for less cpu use
            }
            if (vars.playerSignaturePtr != IntPtr.Zero && vars.uGUI != IntPtr.Zero && vars.isIntroActiveAddress != IntPtr.Zero)
            {
                //DONT FORGET THE 0x !!!!
                vars.playerMain = game.ReadPointer((IntPtr)vars.playerSignaturePtr);
                vars.playerWatcher = new MemoryWatcher<IntPtr>(vars.playerMain);
                vars.player = game.ReadPointer((IntPtr)vars.playerMain);
                vars.playerController = game.ReadPointer((IntPtr)vars.player + 0x338);

                vars.uGUIMain = game.ReadPointer((IntPtr)vars.uGUI);
                vars.uGUIMainPtr = new MemoryWatcher<IntPtr>(vars.uGUIMain); //for updating the pointer when entering a new game
                vars.uGUI = game.ReadPointer((IntPtr)vars.uGUIMain); //follow the pointer to the pointer to uGUI._main
                vars.SceneRespawning = game.ReadPointer((IntPtr)vars.uGUI + 0x38); //to uGUI._main.respawning
                vars.LoadingBackground = game.ReadPointer((IntPtr)vars.SceneRespawning + 0x20); //to uGUI._main.respawning.loadingBackground
                vars.LoadingBackgroundSequence = game.ReadPointer((IntPtr)vars.LoadingBackground + 0x20); // to uGUI._main.respawning.loadingBackground.sequence

                vars.isIntroActiveAddress = game.ReadPointer((IntPtr)vars.isIntroActiveAddress);

                vars.storyGoalManagerMain = game.ReadPointer((IntPtr)vars.storyGoalManagerMainAddress);
                vars.storyGoalManagerMainWatcher = new MemoryWatcher<IntPtr>(vars.storyGoalManagerMain);
                vars.storyGoalManager = game.ReadPointer((IntPtr)vars.storyGoalManagerMain);
                vars.completedGoals = game.ReadPointer((IntPtr)vars.storyGoalManager + 0xa0);
                vars.goalsSlots = game.ReadPointer((IntPtr)vars.completedGoals + 0x18);

                vars.Dbg("completedGoals is: " + vars.completedGoals.ToString("X"));
                vars.Dbg("goalsSlots is:" + vars.goalsSlots.ToString("X"));

                vars.Dbg("All signatures found");

                vars.Dbg("Player main found at 0x" + vars.player.ToString("X"));
                vars.Dbg("Player.PlayerController found at 0x" + vars.playerController.ToString("X"));

                vars.Dbg("uGUI main found at 0x" + vars.uGUI.ToString("X"));

                vars.Dbg("storyGoalManager main found at 0x" + vars.storyGoalManager.ToString("X"));

                vars.Dbg("isIntroActive address found at 0x" + vars.isIntroActiveAddress.ToString("X"));

                break;
            }
            Thread.Sleep(250);
        }
        vars.completedGoalsCount = new MemoryWatcher<int>(vars.completedGoals + 0x30);
        vars.completedGoalsCount.Update(game);

        vars.playerInputEnabled = new MemoryWatcher<bool>(vars.playerController + 0x68);
        vars.respawning = new MemoryWatcher<bool>(vars.LoadingBackgroundSequence + 0x20);
        vars.isIntroActive = new MemoryWatcher<bool>(vars.isIntroActiveAddress);

        vars.completedGoalPointers = new IntPtr[vars.completedGoalsCount.Current];
        for (int slot = 0; slot < vars.completedGoalsCount.Current; slot++)
        {
            IntPtr pointer = vars.goalsSlots + 0x28 + (slot * 0x10);
            vars.completedGoalPointers[slot] = pointer;
            Thread.Sleep(10);
        }
        vars.Dbg("completedGoalPointers has a length of " + vars.completedGoalPointers.Length);
        vars.completedGoalStrings = new string[vars.completedGoalsCount.Current];
        for (int i = 0; i < vars.completedGoalPointers.Length; i++)
        {
            if (vars.completedGoalPointers[i] != IntPtr.Zero)
            {
                IntPtr stringLocation = game.ReadPointer((IntPtr)vars.completedGoalPointers[i]) + 0x14;
                vars.stringBuilder = new System.Text.StringBuilder(128);
                game.ReadString((IntPtr)stringLocation, ReadStringType.UTF16, (System.Text.StringBuilder)vars.stringBuilder);
                string output = vars.stringBuilder.ToString();
                vars.Dbg(output);
            }
            else { vars.Dbg("completedGoalPointer " + i.ToString() + " was null"); }
            Thread.Sleep(10);
        }

        vars.Dbg("closing main sig scan thread");
        vars.Timer = 500;
    });
    vars.sigScanThread.Priority = ThreadPriority.Lowest;
    vars.Dbg("starting main sig scan thread");
    vars.sigScanThread.Start();
}

update
{
    if (vars.sigScanThread.IsAlive) { return false; }

    vars.completedGoalsCount.Update(game);

    vars.playerWatcher.Update(game);
    vars.uGUIMainPtr.Update(game);
    vars.storyGoalManagerMainWatcher.Update(game);

    vars.playerInputEnabled.Update(game);
    vars.respawning.Update(game);
    vars.isIntroActive.Update(game);

    //if (vars.count++ % 600 == 0)
    //{
    //    vars.Dbg("isLoading: " + vars.isLoading.Current);
    //}

    //vars.Dbg("input is active " + vars.playerInputEnabled.Current);
    if (vars.Timer != 0) { vars.Timer -= 1; }
    if (vars.playerWatcher.Current != vars.playerWatcher.Old && vars.Timer == 0)
    {
        Thread.Sleep(500);
        vars.Dbg("player has changed to 0x" + vars.playerWatcher.Current.ToString("X"));
        vars.player = vars.playerWatcher.Current;
        vars.playerController = game.ReadPointer((IntPtr)vars.player + 0x338);
        vars.playerInputEnabled = new MemoryWatcher<bool>(vars.playerController + 0x68);
        vars.Dbg("player updated sucessfully");
        vars.introEndedAtCount = 0;
        vars.Timer = 50;
    }
    if (vars.uGUIMainPtr.Current != vars.uGUIMainPtr.Old)
    {
        vars.Dbg("uGUI has changed to 0x" + vars.uGUIMainPtr.Current.ToString("X"));
        vars.uGUI = vars.uGUIMainPtr.Current; //follow the pointer to uGUI._main
        vars.SceneRespawning = game.ReadPointer((IntPtr)vars.uGUI + 0x38); //to uGUI._main.respawning
        vars.LoadingBackground = game.ReadPointer((IntPtr)vars.SceneRespawning + 0x20); //to uGUI._main.respawning.loadingBackground
        vars.LoadingBackgroundSequence = game.ReadPointer((IntPtr)vars.LoadingBackground + 0x20);
        vars.respawning = new MemoryWatcher<bool>(vars.LoadingBackgroundSequence + 0x20);
        vars.Dbg("uGUI updated sucessfully");
    }
    if (vars.storyGoalManagerMainWatcher.Current != vars.storyGoalManagerMainWatcher.Old)
    {
        vars.Dbg("storyGoalManager has changed to 0x" + vars.storyGoalManagerMainWatcher.Current.ToString("X"));
    }

    if (vars.completedGoalsCount.Current != vars.completedGoalsCount.Old)
    {
        vars.Dbg("now " + vars.completedGoalsCount.Current + " story goals completed");
    }

    //for not skipping intro edge case
    if (!vars.isIntroActive.Current && vars.isIntroActive.Old)
    {
        vars.introEndedAtCount = vars.count;
    }

    if (!vars.isIntroActive.Current && vars.isIntroActive.Old && !vars.playerInputEnabled.Current)
    {
        vars.Dbg(vars.count);
    }
}

//capitalize Current for MemoryWatchers
//names of MemWatchers:
//respawning
//playerInputEnabled
//isIntroActive
start
{
    if (
        (vars.isIntroActive.Current || vars.introEndedAtCount + 2 >= vars.count) //so it works if you dont skip the intro
        && vars.playerInputEnabled.Current
        && !vars.playerInputEnabled.Old
        && vars.Timer == 0
       )
    { vars.introEndedAtCount = 0; return true; }
    //vars.Dbg(vars.count);
}

isLoading
{
    if (vars.respawning.Current && settings["loadRemove"]) { return true; }
    else { return false; }
}

exit
{
    vars.sigScanTokenSource.Cancel();
}

shutdown
{
    vars.sigScanTokenSource.Cancel();
}