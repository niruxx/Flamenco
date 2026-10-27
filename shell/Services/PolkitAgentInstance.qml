import Quickshell.Services.Polkit

// Quickshell's polkit agent, in a file of its own so PolkitAuth can load it with a
// Loader: on a Quickshell built without polkit, only this fails to load, not the shell.
PolkitAgent {}
