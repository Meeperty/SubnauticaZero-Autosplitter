state ("SubnauticaZero") 
{
    bool playerInputEnabled: "UnityPlayer.dll", 0x1795118, 0x20, 0xd0, 0x8, 0x60, 0x40, 0x48, 0x68;
    bool introPlaying: "UnityPlayer.dll", 0x17c2f50, 0x1b0, 0x30, 0x38, 0x28, 0x0, 0x258, 0xf8;
}

update
{
}

start
{
    if (current.introPlaying && !old.playerInputEnabled && current.playerInputEnabled) { return true; }
}