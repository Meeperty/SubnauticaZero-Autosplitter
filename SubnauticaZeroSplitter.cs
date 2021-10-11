using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using LiveSplit;
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
        }

        public void CheckMemory(object o)
        {
            foreach(var page in game.MemoryPages())
            {
                var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

            }
        }
    }
}
