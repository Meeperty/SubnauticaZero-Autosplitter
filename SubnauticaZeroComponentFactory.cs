using System;
using LiveSplit.Model;
using LiveSplit.UI.Components;
using SubnauticaZeroComponentSplit;

[assembly :ComponentFactory(typeof(SubnauticaZeroComponentFactory))]

namespace SubnauticaZeroComponentSplit
{
    class SubnauticaZeroComponentFactory : IComponentFactory
    {
        public IComponent Create(LiveSplitState state) => new SubnauticaZeroComponent(state);
        public string ComponentName => "Subnautica Below Zero Autosplitter";
        public string Description => "Automatic splits for Subnautica Below Zero";
        public ComponentCategory Category => ComponentCategory.Control;
        public string UpdateName => ComponentName;
        public string XMLURL => UpdateURL + "SubnauticaZeroAutosplitter.xml";
        public string UpdateURL => "https://raw.githubusercontent.com/";
        public Version Version => new Version("0.0.1");
    }
}