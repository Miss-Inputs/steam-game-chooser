import-module (join-path (split-path -parent $Script:PSCommandPath) steam_games.ps1)
import-module (join-path (split-path -parent $Script:PSCommandPath) non_steam_games.ps1)

function get_all_games($userid){
    $lib_list_path = get_library_list_path
    $lib_list = parse_library_list $lib_list_path
    $manifests = get_appmanifests $lib_list
    $steam_games = $manifests | % {parse_appmanifest $_}

    $shortcuts_vdf_path = get_shortcuts_file_path $userid
    $non_steam_games = parse_shortcuts_file $shortcuts_vdf_path
    
    return $steam_games + $non_steam_games
}

function choose_random_game($userid){
    write-host "Loading…"
    $games = get_all_games $userid
    write-host "Loaded!"
    return get-random $games
}

function display_game_info($game, $userid){
    if($game.game_type -eq 'steam'){
        "AppID: $($game.appid)"
        "Installation directory: $(join-path $game.library ('common\'+($game.installdir)))" 
        "Last updated on $(convert_unix_time $game.LastUpdated)"
        "Size on disk: $(convert_byte_size $game.SizeOnDisk $false) / $(convert_byte_size $game.SizeOnDisk $true)"
        "Your categories: $(get_categories $game.appid $userid)"
        "You played this last on $(get_last_played $game.appid $userid)"
    } elseif ($game.game_type -eq 'non_steam'){
        "Executable: $($game.exe)"
        "Working directory: $($game.startDir)"
        "Command line options: $($game.launchOptions)"
        "Your categories: $($game.tags | select -expand name)"
    } else {
        "Well I dunno then"
    }
}

function main($userid){
    $game = choose_random_game $userid
    if($game.game_type -eq 'steam'){
        write-host "Go play $($game.name)"
    } elseif ($game.game_type -eq 'non_steam'){
        write-host "Go play $($game.AppName)"
    }
    display_game_info $userid
}

#TODO: Add a command line parameter or prompt user or something for user id
main