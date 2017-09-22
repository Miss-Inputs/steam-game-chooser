import-module (join-path $PSScriptRoot common)

function get_shortcuts_file_path($userid){
    $userid = default_userid $userid
    return "C:\Program Files (x86)\Steam\userdata\$userid\config\shortcuts.vdf"
}

function read_game([IO.BinaryReader]$reader){
    $o = new-object pscustomobject

    $reached_end = $false
    while(!$reached_end){
        $type = $reader.readByte()
        
        $key = read_terminated_string $reader

        if($type -eq 1){
            #string/filename/etc
            $value = read_terminated_string $reader
        } elseif ($type -eq 2){
            #bool
            #TODO LastPlayTime isn't a bool, and starts with STX
            $value = $reader.readByte() -eq 1
            [void]$reader.readBytes(3) #Consume NULNULNUL terminator
        } elseif ($type -eq 0){
            #tag list
            $tag_list = @()
            
            while($true){
                $soh = $reader.readByte() #Normally, starts with a SOH byte, unless at the end
                if($soh -eq 8 -and $reader.peekChar() -eq 8){
                    [void]$reader.readByte() #Consume the other BS byte
                    $reached_end = $true
                    break
                }
                 
                $tag_index = read_terminated_string $reader
                $tag_name = read_terminated_string $reader
                $tag_list += new-object pscustomobject -prop @{index=$tag_index; name=$tag_name}
            }
            $value = $tag_list
            
        }
        if($key -eq $null -or $key.length -eq 0){
            #What the fuck? Oh well
            continue
        }
        $o | add-member -type NoteProperty -name $key -value $value
    }
    
    return $o
}

function parse_shortcuts_file($path){
    $shortcuts_file = new-object IO.BinaryReader ([IO.File]::openRead($path))
    
    $b = $shortcuts_file.readByte()
    if($b -ne 0){
        throw "No null byte at beginning, found " + $b + " instead"
    }
    
    $buf = read_terminated_string $shortcuts_file   
    if($buf -ne "shortcuts"){
        throw "No 'shortcuts' in header, found " + $b + " instead"
    }
    
    $games = @()    
    while($true) {
        [void]$shortcuts_file.readByte() #Consume null byte preceding game index
        $game_index = read_terminated_string $shortcuts_file
        $game = read_game $shortcuts_file
        
        $game | add-member index $game_index
        $game | add-member game_type non_steam
        $games += $game

        if($shortcuts_file.peekChar() -eq 8){
            #Ideally, we'd peek 2 chars here and detect for 2 backspaces
            break
        }
    }
    
    return $games
}