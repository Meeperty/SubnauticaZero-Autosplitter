using System;
using System.Xml;
using System.Collections.Generic;
using System.Text;
using System.Windows.Forms;
using LiveSplit.Model;
using LiveSplit.UI;
using LiveSplit.UI.Components.AutoSplit;
using System.Diagnostics;

namespace SubnauticaZeroComponentSplit
{
    public sealed class SubnauticaZeroComponent : AutoSplitComponent
    {
        public override string ComponentName => "Subnautica Below Zero Autosplitter";

        private readonly static SubnauticaZeroSettings settings = new SubnauticaZeroSettings();

        public override void Update(IInvalidator invalidator, LiveSplitState state, float width, float height, LayoutMode mode)
        {
            splitter.Update();
        }

        public override void SetSettings(XmlNode settings)
        {
        
        }

        public override XmlNode GetSettings(XmlDocument document)
        {
            XmlElement settings_Node = document.CreateElement("Settings");
            return settings_Node;
        }

        public override Control GetSettingsControl(LayoutMode m)
        {
            return settings;
        }

        public override void Dispose() { }

        static SubnauticaZeroSplitter splitter = new SubnauticaZeroSplitter(settings);

        internal SubnauticaZeroComponent(LiveSplitState state) : base(splitter, state) { }
    }
}
