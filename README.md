# SteamGameChooser
Script to randomly select a game from the user's Steam library, written in PowerShell because I'm too lazy to use a real language at the moment. Well, it works.

Currently, this just displays the game in the command line, as well as info. Ideally there'd be a GUI, as well as a button to actually launch the game.

It searches both Steam games and non-Steam shortcuts added to Steam. At the moment it searches all of them (as long as they're actually installed, unlike most web-based tools that do similar things that choose games you don't like anymore and uninstalled as a result), I plan to let the user exclude categories (in case you add non-game applications to Steam to launch them conveniently, or whatever), or only show games of a specific category if you're in a particular mood.

This project's existence is greatly helped by the existence of [SteamShard](https://github.com/PsychoTheHedgehog/SteamShard/wiki/shortcuts.vdf) and [pysteam](https://github.com/scottrice/pysteam), while it doesn't use their code in any way, they provided excellent documentation on the various file formats and locations. If you're the developer of either of these and you're reading this, I love you.
