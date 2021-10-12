using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using LiveSplit.UI.Components.AutoSplit;
using LiveSplit.ComponentUtil;
using LiveSplit.Model;


namespace SubnauticaZeroComponentSplit
{
    class SubnauticaZeroSplitter : IAutoSplitter
    {
        private Process game;
        private Timer timer;
        private readonly SubnauticaZeroSettings settings;
        public static IntPtr nullptr = IntPtr.Zero;

        const int playerSigOffset = 2;
        const string playerSignature = "48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 48 89 30 48 89 45 c0 48 b9 ?? ?? ?? ?? ?? ?? ?? ?? 90";
        const int uGUISigOffset = 10;
        const string uGUISignature = "55 48 8b ec 48 83 ec 20 48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 48 8b 08 33 d2 48 8d ad ?? ?? ?? ?? 49 bb ?? ?? ?? ?? ?? ?? ?? ?? 41 ff d3 85 c0 74 2c 48 b8";
        const int isIntroActiveSigOffset = 27;
        const string isIntroActiveSignature = "33 d2 48 8d 64 24 00 90 49 bb ?? ?? ?? ?? ?? ?? ?? ?? 41 ff d3 85 c0 75 0f 48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 0fb6 00 eb 05 b8 01000000 48 8d 65 00 5d c3";
        const int storyGoalManagerSigOffset = 6;
        const string storyGoalManagerSignature = "48 89 45 a0 48 b8 ?? ?? ?? ?? ?? ?? ?? ?? 48 89 30 48 89 45 88 48 b9 ?? ?? ?? ?? ?? ?? ?? ?? 48 8d ad";

        SigScanTarget playerTarget = new SigScanTarget(playerSigOffset, playerSignature);
        IntPtr playerCodePointer = nullptr;

        SigScanTarget uGUITarget = new SigScanTarget(uGUISigOffset, uGUISignature);
        IntPtr uGUICodePointer = nullptr;

        SigScanTarget isIntroActiveTarget = new SigScanTarget(isIntroActiveSigOffset, isIntroActiveSignature);
        IntPtr isIntroActiveCodePointer = nullptr;

        SigScanTarget storyGoalManagerTarget = new SigScanTarget(storyGoalManagerSigOffset, storyGoalManagerSignature);
        IntPtr storyGoalManagerCodePointer = nullptr;


        internal SubnauticaZeroSplitter(SubnauticaZeroSettings settings)
        {
            this.settings = settings;
        }

        public bool ShouldStart(LiveSplitState state)
        {
            if(game is null)
            {
                game = Process.GetProcessesByName("SubnauticaZero").FirstOrDefault(p => !p.HasExited);
                if(!(game is null))
                {
                    timer = new Timer(CheckMemory, null, 0, 2000);
                }
                return false;
            }
            return false;
        }

        public void CheckMemory(object o)
        {

            int p = 0;
            foreach (var page in game.MemoryPages())
            {
                p++;
                var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

                if (playerCodePointer == nullptr && (playerCodePointer = scanner.Scan(playerTarget)) != nullptr) {}

                if (uGUICodePointer == nullptr && (playerCodePointer = scanner.Scan(uGUITarget)) != nullptr) {}

                if (isIntroActiveCodePointer == nullptr && (isIntroActiveCodePointer = scanner.Scan(isIntroActiveTarget)) != nullptr) {}

                if (storyGoalManagerCodePointer == nullptr && (storyGoalManagerCodePointer = scanner.Scan(storyGoalManagerTarget)) != nullptr) {}

                if (playerCodePointer != nullptr && uGUICodePointer != nullptr && isIntroActiveCodePointer != nullptr && storyGoalManagerCodePointer != nullptr)
                {
                    timer.Dispose();
                    break;
                }
            }
        }

        public TimeSpan? GetGameTime(LiveSplitState state) { return null; }

        public bool IsGameTimePaused(LiveSplitState state) { return false; }

        public bool ShouldSplit(LiveSplitState state) { return false; }

        public bool ShouldReset(LiveSplitState state) { return false; }
    }
}
