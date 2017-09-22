$utf8 = [Text.Encoding]::UTF8

function chop($s){
    #I'd just like to take a moment here to complain about HOW FUCKING ANNOYING IT IS
    #TO JUST CHOP OFF THE SINGLE FUCKING CHARACTER AT THE END OF A STRING. Like for fucks
    #sake you couldn't just fucking have "string"[:-1] or "string"[..-1] could you? You
    #couldn't even just let me have "string".substring(0, -1). You had to make me type out
    #THE FULL FUCKING VERBOSE BULLSHIT and now I'm typing out even more things because I
    #can't let this rant go untyped
    return $s.substring(0, $s.length - 1)
}

function convert_unix_time($seconds){
    $epoch = get-date -date 1 -month 1 -year 1970
    return $epoch.addSeconds($seconds)
}

function convert_byte_size($bytes, $metric=$false){
    if($metric){
        $unit_size = 1000
    } else {
        $unit_size = 1KB
    }

    if($bytes -le $unit_size){
        return "$bytes bytes"
    }

    $units = 'KMGTPEZY'
    $power = [math]::floor([math]::log($bytes) / [math]::log(1KB))
    $prefix = $units[$power - 1]
    if(!$metric){
        #Yeah, that's right, when _not_ metric, add an i to the prefix. You know
        #when people say a kilobyte is 1024 bytes? That's actually a kibibyte. Look it up.
        $prefix += "i"
    }
    $rounded = [math]::round($bytes / [math]::pow($unit_size, $power), 2)
    return "$rounded $prefix`B"
}

function get_steam_path(){
    #TODO Don't hardcode Steam install path, use registry (HKCU\Software\Valve\Steam\SteamPath)
    return "C:\Program Files (x86)\Steam\"
}

function default_userid($userid){
    if($userid -eq $null){
        return ([array](get_user_ids))[0]
    } else {
        return $userid
    }
}

function get_user_ids(){
    $steam = get_steam_path
    return gci "$steam\userdata" | % {$_.Name}
}

function parse_steamkv($path){
    #Now _this_ is a messy as fuck function
    #FIXME Not only is this messy, it's slow as fucking fuck
    $reader = new-object IO.BinaryReader ([IO.File]::openRead($path)), $utf8
    [void]$reader.readChar() #Should be "
    
    #Could actually put this in the result. Don't feel like it and don't need to
    $current_tag = read_terminated_string $reader $utf8.getBytes('"')
    
    function read_object($reader){
        $o = new-object pscustomobject
        
        $name = ''
        $has_name = $false
        while($true){
            $nextChar = [char]$reader.peekChar()
            if($nextChar -eq '}'){
                [void]$reader.readChar()
                break
            } 

            if([char]::isWhitespace($nextChar)){
                [void]$reader.readChar()
                continue
            }
        
            if($nextChar -eq '{'){
                [void]$reader.readChar()
                if($has_name){
                    $value = read_object $reader
                    #Can't just use add-member $name $value actually, because that screws up if $name is something like "1"
                    $o | add-member -type NoteProperty -name $name -value $value
                    $has_name = $false
                }
            } elseif ($nextChar -eq '"') {   
                [void]$reader.readChar()
                if($has_name){
                    $value = read_terminated_string $reader $utf8.getBytes('"')
                    $o | add-member -type NoteProperty -name $name -value $value
                    $has_name = $false
                } else {
                    $name = read_terminated_string $reader $utf8.getBytes('"')
                    $has_name = $true
                }
            } else {
                #hmm
                [void]$reader.readChar()
            }
        }
        return $o
    }
    
    $kv = read_object $reader   
    $reader.close()
    return $kv
}

function read_terminated_string([IO.BinaryReader]$reader, [byte[]]$terminator = 0, $encoding = $utf8){ 
    $buf = new-object Collections.Generic.List[byte]
    while($true){
        $bytes = $reader.readBytes($terminator.length)
        if((compare-object -SyncWindow 0 $bytes $terminator).length -eq 0){
            break
        }

        $buf.addRange($bytes)

    }
    
    return $encoding.getString($buf)
}

function get_profiler_module(){
    $url = 'https://raw.githubusercontent.com/Microsoft/Windows-classic-samples/master/Samples/PowerShell/AbstractSyntaxTreeProfiler/cs/PSProfiler.cs'
    $code = (Invoke-WebRequest $url).content

    add-type -TypeDefinition $code -OutputAssembly "$env:temp\PSProfiler.dll"
    import-module "$env:temp\PSProfiler.dll"
}