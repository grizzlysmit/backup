unit module BackupAndSync:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;
use IO::Glob;



# the name of this host   #
constant $thishost is export = qx<hostname>.chomp;

# the home dir #
constant $home is export = %*ENV<HOME>.Str();

# config files
constant $config is export = "$home/.local/share/backup-and-sync";

# the user name #
constant $user is export = %*ENV<USER>.Str();

my @signal;

# the editor to use #
my Str $editor = '';
if %*ENV<GUI_EDITOR>:exists {
    $editor = %*ENV<GUI_EDITOR>.Str();
} elsif %*ENV<VISUAL>:exists {
    $editor = %*ENV<VISUAL>.Str();
} elsif %*ENV<EDITOR>:exists {
    $editor = %*ENV<EDITOR>.Str();
} else {
    my Str $gvim = qx{/usr/bin/which gvim 2> /dev/null };
    my Str $vim  = qx{/usr/bin/which vim  2> /dev/null };
    my Str $vi   = qx{/usr/bin/which vi   2> /dev/null };
    if $gvim {
        $editor = $gvim;
    } elsif $vim {
        $editor = $vim;
    } elsif $vi {
        $editor = $vi;
    }
}

# The default name of the backup device #
my Str @backup-devices = slurp("$config/device").split("\n").map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep: { !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / };
my Str $backup-device = "";
my Str @guieditors;
#@backup-devices.raku.say;
if @backup-devices {
    #@backup-devices.raku.say;
    for @backup-devices -> $device {
        #"'$device'".say;
        #"Got here $?FILE [$?LINE]".say;
        if $device ~~ rx/ ^^ 'device' \s* '=' $<dev> = [ .+ ] $$ / {
            #"Got here $?FILE [$?LINE]".say;
            $backup-device = ~$<dev>;
            #"'$backup-device'".say;
            $backup-device .=trim;
            #"'$backup-device'".say;
        } elsif $device ~~ rx/ ^^ \s* 'guieditors' \s* '+'? '=' $<dev> = [ .+ ] $$ / {
            my Str $guieditor = ~$<dev>;
            $guieditor .=trim;
            @guieditors.append($guieditor);
        }
    }
}
if %*ENV<GUI_EDITOR>:exists {
    my Str $guieditor = ~%*ENV<GUI_EDITOR>;
    if ! @guieditors.grep( { $_ eq $guieditor.IO.basename } ) {
        @guieditors.prepend($guieditor.IO.basename);
    }
}
if $backup-device ~~ rx/ ^^ \s* $$ / {
    "No backup device specified!!!".say;
    exit -1;
} else {
    $backup-device ~~ s:g/ \{ 'user' \} /$user/;
    $backup-device ~~ s:g/ \{ 'hostname' \} /$thishost/;
    $backup-device ~~ s:g/ \{ 'home' \} /$home/;
}

sub backup-device-val(--> Str) is export {
    return $backup-device;
}

# the hosts to keep synchronised #
#my Str @hosts = qw{rakbat killashandra pern};
my Str @internal-hosts = slurp("$config/hosts").split("\n").map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep: { !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / };

sub hosts-val() returns Array[Str] is export {
    return @internal-hosts;
}

# the dirs to synchronise or backup #
my Str @internal-dirs = slurp("$config/dirs").split("\n").map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep: { !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / };


sub dirs-val() returns Array[Str] is export {
    return @internal-dirs;
}

# the individual files to sync or backup #
my Str @internal-files = slurp("$config/files").split("\n").map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep: { !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / };

sub files-val(--> Array[Str]) is export {
    return @internal-files;
}

unless "$config/specials".IO ~~ :f {
    "$config/specials".IO.spurt(qq[
        # specials put files and directory's to be backed #
        # up with out synchronising with other systems    #
    ]);
}

# the individual specials to sync or backup #
my Str @internal-specials = slurp("$config/specials").split("\n").map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep: { !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / };

sub specials-val(--> Array[Str]) is export {
    return @internal-specials;
}

# The config files to test for #
constant @config-files is export = qw{device dirs exclude-files files hosts specials};

if $config.IO !~~ :d {
    $config.IO.mkdir();
}

sub generate-configs(Str $file) returns Bool:D {
    my Bool $result = True;
    my IO::CatHandle:D $fd = "$config/$file".IO.open: :w;
    given $file {
        when 'device' {
            my Str $content = q:to/END/;
            # the device to backup to #
            # this is a sample file you will probably need to change it #
            # is unlikely to you have a device called grizzlys2TBssd    #
            # {user}     will be replaced by the username. 
            # {hostnmae} will be replaced by the hostname.
            # {home}     will be replaced by the home directory of the user it is running under.
            # if multi device lines are entered only the last will be in effect.
                device      =      /media/{user}/grizzlys2TBssd/backup/{hostname}         # the backup device to use

            # these editors are gui editors
            # you can define multiple lines like these 
            # and the system will add to an array of strings 
            # to treat as guieditors (+= is prefered but = can be used).
            END
            $content .=trim-trailing;
            for qw[gvim xemacs kate gedit] -> $guieditor {
                @guieditors.append($guieditor);
            }
            for @guieditors -> $guieditor {
                $content ~= "\n        guieditors  +=  $guieditor";
            }
            my Bool $r = $fd.put: $content;
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
        }
        when 'dirs' {
            my Bool $r = $fd.put: q:to/END/;
            #.wireguard-stuff
            #Projects
            Pictures
            Videos
            bin
            #AndroidStudioProjects
            Documents
            Downloads
            mobile
            Music
            Templates
            #work
            #wallpaper # my walpapers 
            #.elvish/lib/gzz
            #.julia/config # the comfigs for julia language #
            # the files that define what to backup or sync #
            .local/share/backup-and-sync
            .vim
                                
            END
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
        }
        when 'exclude-files' {
            my Bool $r =  $fd.put: q:to/END/;
            # vim/gvim buffer files
            .*.swp
            # backup files I used 2 as the first only seamed #
            # to work with stuff with no extension.          #
            *~
            *.*~
            END
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
        }
        when 'files' {
            my Bool $r = $fd.put: q:to/END/;
            #database.kdbx
            #.elvish/rc.elv
            #.elvish/lib/dev-elvish-Projects/epm-domain.cfg
            # a python linter flake8
            #.flake8
            .bashrc
            .profile
            .vimrc
            .gvimrc
            END
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
        }
        when 'hosts' {
            my Bool $r = $fd.put: q:to/END/;
            example
            rakbat
            killashandra
            # the new box ip will be 192.168.1.15
            pern
            END
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
        }
    } # given $file #
    my Bool $r = $fd.close;
    "error closing file: $config/$file".say if ! $r;
    $result ?&= $r;
    return $result;
}

sub insure-config-is-present() returns Bool:D is export {
    my Bool $result = True;
    my Bool:D $please-edit = False;
    for @config-files -> $file {
        CATCH {
            default { 
                    $please-edit = True;
                    $*ERR.say: .message; 
                    $*ERR.say: "some kind of IO exception was caught!"; 
                    my Str $content;
                    given $file {
                        when 'device' {
                            $content = q:to/END/;
                            # the device to backup to #
                            # this is a sample file you will probably need to change it #
                            # is unlikely to you have a device called grizzlys2TBssd    #
                            # {user}     will be replaced by the username. 
                            # {hostnmae} will be replaced by the hostname.
                            # {home}     will be replaced by the home directory of the user it is running under.
                            # if multi device lines are entered only the last will be in effect.
                                device      =      /media/{user}/grizzlys2TBssd/backup/{hostname}         # the backup device to use

                            # these editors are gui editors
                            # you can define multiple lines like these 
                            # and the system will add to an array of strings 
                            # to treat as guieditors (+= is prefered but = can be used).
                            END
                            $content .=trim-trailing;
                            for qw[gvim xemacs kate gedit] -> $guieditor {
                                @guieditors.append($guieditor);
                            }
                            for @guieditors -> $guieditor {
                                $content ~= "\n        guieditors  +=  $guieditor";
                            }
                        }
                        when 'dirs' {
                            $content = q:to/END/;
                            #.wireguard-stuff
                            #Projects
                            Pictures
                            Videos
                            bin
                            #AndroidStudioProjects
                            Documents
                            Downloads
                            mobile
                            Music
                            Templates
                            #work
                            #wallpaper # my walpapers 
                            #.elvish/lib/gzz
                            #.julia/config # the comfigs for julia language #
                            # the files that define what to backup or sync #
                            .local/share/backup-and-sync
                            .vim
                                                
                            END
                        }
                        when 'exclude-files' {
                            $content = q:to/END/;
                            # vim/gvim buffer files
                            .*.swp
                            # backup files I used 2 as the first only seamed #
                            # to work with stuff with no extension.          #
                            *~
                            *.*~
                            END
                        }
                        when 'files' {
                            $content = q:to/END/;
                            #database.kdbx
                            #.elvish/rc.elv
                            #.elvish/lib/dev-elvish-Projects/epm-domain.cfg
                            # a python linter flake8
                            #.flake8
                            .bashrc
                            .profile
                            .vimrc
                            .gvimrc
                            END
                        }
                        when 'hosts' {
                            $content = q:to/END/;
                            example
                            rakbat
                            killashandra
                            # the new box ip will be 192.168.1.15
                            pern
                            END
                        }
                        when 'specials' {
                            $content = q:to/END/;
                            # specials put files and directory's to be backed #
                            # up with out synchronising with other systems    #
                            END
                        }
                    } # given $file #
                    $content .=trim-trailing;
                    if "$config/$file".IO !~~ :e || "$config/$file".IO.s == 0 {
                        "$config/$file".IO.spurt: $content, :append;
                    }
                    if $please-edit {
                        edit-configs();
                        exit 0;
                    }
                    return True;
               }
        }
        if "$config/$file".IO !~~ :e {
            $please-edit = True;
            if "/etc/skel/.local/share/backup-and-sync/$file".IO ~~ :f {
                try {
                    CATCH {
                        when X::IO::Copy { 
                            "could not copy /etc/skel/.local/share/backup-and-sync/$file -> $config/$file".say;
                            my Bool $r = generate-configs($file); 
                            $result ?&= $r;
                        }
                    }
                    my Bool $r = "/etc/skel/.local/share/backup-and-sync/$file".IO.copy("$config/$file".IO, :createonly);
                    if $r {
                        "copied /etc/skel/.local/share/backup-and-sync/$file -> $config/$file".say;
                    } else {
                        "could not copy /etc/skel/.local/share/backup-and-sync/$file -> $config/$file".say;
                    }
                    $result ?&= $r;
                }
            } else {
                my Bool $r = generate-configs($file);
                "generated $config/$file".say if $r;
                $result ?&= $r;
            } # else clause #
        } # if "$config/$file".IO !~~ :f #
    } # for @config-files -> $file #
    if $please-edit {
        edit-configs();
        exit 0;
    }
    return $result;
}

sub describe-config-file(Str $file) returns Str:D is export {
    my Str $result = '';
    given $file {
        when 'device' {
            $result = "define your backup device here (only used by backup.raku).";
        }
        when 'dirs' {
            $result = "The directories to synchronise or backup.";
        }
        when 'exclude-files' {
            $result = "Do not backup or synchronise anything matching these patterns.";
        }
        when 'files' {
            $result = "The files to synchronise or backup.";
        }
        when 'hosts' {
            $result = "The host to synchronise (only used by sync.raku).";
        }
    }
    return $result;
}

sub backup-me(Str $thishost, Str $backup-to, Str @backup-dirs, Str @backup-files, @backup-specials) returns List is export {
    "$thishost.local <---> $backup-to".say;
    if $backup-to.IO !~~ :e && $backup-to.IO.dirname.IO !~~ :e {
        my $rr = run 'mkdir', '-pv', $backup-to;
        if $rr.exitcode != 0 {
            "error cannot mkdir: $backup-to, perhaps backup drive is not mounted".say;
            return -1;
        }
    }
    my %results;
    my $exclude-option = "--exclude-from=$config/exclude-files";
    my Int $result = 0;
    for @backup-dirs -> $dir {
        say "[$dir/]";
        my Str $t = "$backup-to/$dir/".IO.dirname;
        if $t.IO !~~ :e {
            my Proc $res = run 'mkdir', '-pv', $t;
            if $res.exitcode != 0 {
                "error cannot mkdir: $t, perhaps backup drive is not mounted".say;
                next;
            }
        }
        say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$home/$dir/", "$backup-to/$dir/";
        my Proc $r = run "rsync", "-auv", "--progress", $exclude-option, "$home/$dir/", "$backup-to/$dir/";
        %results{$dir} = $r.exitcode unless $r.exitcode == 0;
        $result +|= $r.exitcode;
        say "";
    }
    for @backup-files -> $file {
        say "[$file]";
        my Str $t = "$backup-to/$file".IO.dirname;
        if $t.IO !~~ :e {
            my Proc $res = run 'mkdir', '-pv', $t;
            if $res.exitcode != 0 {
                "error cannot mkdir: $t, perhaps backup drive is not mounted".say;
                next;
            }
        }
        say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$home/$file", "$backup-to/$file";
        my Proc $r = run "rsync", "-auv", "--progress", $exclude-option, "$home/$file", "$backup-to/$file";
        %results{$file} = $r.exitcode unless $r.exitcode == 0;
        "Error: failed to read/write $home/$file --> $backup-to/$file".say unless $r.exitcode == 0;
        $result +|= $r.exitcode;
        say "";
    }
    say join ' ', "mkdir", "-pv", "$home/specials/$thishost";
    my Proc $res0 = run "mkdir", "-pv", "$home/specials/$thishost";
    if $res0.exitcode != 0 {
        "error cannot mkdir: $home/specials/$thishost, perhaps $home is not writeable".say;
        $result +|= $res0.exitcode;
        return $result, %results;
    }
    my $t3 = "$backup-to/specials";
    my Proc $res = run "mkdir", "-pv", "$t3/$thishost";
    if $res.exitcode != 0 {
        "error cannot mkdir: $t3, perhaps backup drive is not mounted or is not writeable".say;
        $result +|= $res.exitcode;
        return $result, %results;
    }
    say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$home/specials/", $t3;
    my Proc $rr = run "rsync", "-auv", "--progress", $exclude-option, "$home/specials/", $t3;
    %results{"specials/"} = $rr.exitcode unless $rr.exitcode == 0;
    $result +|= $rr.exitcode;
    dd %results;
    say "";
    return $result, %results;
} # sub backup-me(Str $thishost, Str $backup-to, Str @backup-dirs, Str @backup-files, @backup-specials) returns List is export #

sub specials(Str $thishost, Str @backup-specials --> List) is export {
    "$thishost.local <---> specials".say;
    my %results;
    my $exclude-option = "--exclude-from=$config/exclude-files";
    my Int $result = 0;
    say join ' ', "mkdir", "-pv", "$home/specials/$thishost";
    my Proc $res0 = run "mkdir", "-pv", "$home/specials/$thishost";
    if $res0.exitcode != 0 {
        "error cannot mkdir: $home/specials/$thishost, perhaps $home is not writeable".say;
        $result +|= $res0.exitcode;
        return $result, %results;
    }
    for @backup-specials -> $special {
        my Str $t = "$home/$special";
        say "[$special]";
        if $t.IO ~~ :d && $t.IO !~~ :l {
            say "[$special/]";
            if $t.IO ~~ :e {
                ####################
                #                  #
                #   save locally   #
                #                  #
                ####################
                my $t4 = "$home/specials/$thishost/$special".IO.dirname;
                my Proc $res0 = run "mkdir", "-pv", $t4;
                if $res0.exitcode != 0 {
                    "error cannot mkdir: $t4, perhaps $home is not writeable".say;
                    next;
                }
                say join ' ', "rsync", "-auv", "--progress", "$home/$special/", $exclude-option, "$home/specials/$thishost/$special/";
                my Proc $rr = run "rsync", "-auv", "--progress", "$home/$special/", $exclude-option, "$home/specials/$thishost/$special/";
                dd $rr;
                dd $result;
                %results{"$home/specials/$thishost/$special"} = $rr.exitcode unless $rr.exitcode == 0;
                $result +|= $rr.exitcode;
            }
        } elsif $t.IO ~~ :d {
            say "[$special/]";
            if $t.IO ~~ :e {
                ####################
                #                  #
                #   save locally   #
                #                  #
                ####################
                my $t4 = "$home/specials/$thishost/$special".IO.dirname;
                my Proc $res0 = run "mkdir", "-pv", $t4;
                if $res0.exitcode != 0 {
                    "error cannot mkdir: $t4, perhaps $home is not writeable".say;
                    next;
                }
                say join ' ', "rsync", "-auv", "--progress", "$home/$special/", $exclude-option, "$home/specials/$thishost/$special/";
                my Proc $rr = run "rsync", "-auv", "--progress", "$home/$special/", $exclude-option, "$home/specials/$thishost/$special/";
                dd $rr;
                dd $result;
                %results{"$home/specials/$thishost/$special"} = $rr.exitcode unless $rr.exitcode == 0;
                $result +|= $rr.exitcode;
            }
        } else {
            say "[$special]";
            if $t.IO ~~ :e {
                ####################
                #                  #
                #   save locally   #
                #                  #
                ####################
                my $t4 = "$home/specials/$thishost/$special".IO.dirname;
                my Proc $res0 = run "mkdir", "-pv", $t4;
                if $res0.exitcode != 0 {
                    "error cannot mkdir: $t4, perhaps $home is not writeable".say;
                    next;
                }
                say join ' ', "rsync", "-auv", "--progress", "$home/$special", $exclude-option, "$home/specials/$thishost/$special";
                my Proc $rr = run "rsync", "-auv", "--progress", "$home/$special", $exclude-option, "$home/specials/$thishost/$special";
                dd $rr;
                dd $result;
                %results{"$home/specials/$thishost/$special"} = $rr.exitcode unless $rr.exitcode == 0;
                $result +|= $rr.exitcode;
            }
        }
        say "";
    }
    dd %results;
    say "";
    return $result, %results;
} # sub specials(Str $thishost, Str @backup-specials --> List) is export #

sub restore-me(Str $thishost, Str $restore-from, $to, Bool $force, Str @backup-dirs, Str @backup-files) returns Int is export {
    "$thishost.local <---> $restore-from".say;
    my $options = '-auv';
    my $exclude-option = "--exclude-from=$config/exclude-files";
    my $cmd     = 'rsync';
    if $force {
        $options = '-afv';
        $cmd     = 'cp';
        $exclude-option = '--';
    }
    if $restore-from.IO !~~ :e {
        "error cannot find $restore-from, perhaps backup drive is not mounted".say;
        return -1;
    }
    my Int $result = 0;
    for @backup-dirs -> $dir {
        say "[$dir/]";
        my Str $t = "$to/$dir/".IO.dirname;
        if $t.IO !~~ :e {
            run 'mkdir', '-pv', $t;
        }
        say join ' ', $cmd, $options, $exclude-option, "$restore-from/$dir/", "$to/$dir/";
        my Proc $r = run $cmd, $options, $exclude-option, "$restore-from/$dir/", "$to/$dir/";
        $result +|= $r.exitcode;
        say "";
    }
    for @backup-files -> $file {
        say "[$file]";
        my Str $t = "$to/$file".IO.dirname;
        if $t.IO !~~ :e {
            run 'mkdir', '-pv', $t;
        }
        say join ' ', $cmd, $options, $exclude-option, "$restore-from/$file", "$to/$file";
        my Proc $r = run $cmd, $options, $exclude-option, "$restore-from/$file", "$to/$file";
        $result +|= $r.exitcode;
        say "";
    }
    return $result;
} # sub restore-me(Str $thishost, Str $restore-from, $to, Bool $force, Str @backup-dirs, Str @backup-files) returns Int is export #

sub clean-up-mon-sync( --> Bool) is export {
    my Bool $result = True;
    if "$home/.sync-flags".IO ~~ :d {
        for "$home/.sync-flags".IO.dir(test => *) -> $file {
            next if $file.path eq "$home/.sync-flags/." || $file.path eq "$home/.sync-flags/..";
            "{$file.path}.IO.unlink;".say;
            $result =  $result && $file.unlink;
        }
    } else {
        $result = False;
    }
    return $result;
} # sub clean-up-mon-sync( --> Bool) is export #

sub sync-me(Str $thishost, Str $host, Str @sync-dirs, Str @sync-files, Str @sync-specials) returns List is export {
    CATCH {
        default {
            #"$home/.sync-flags/$host".IO.unlink;
            while @signal {
                my &elt = @signal.pop;
                &elt();
            }
            .rethrow;
        }
    }
    @signal.push: {
        "$home/.sync-flags/$host".IO.unlink;
    };
    my &stack = sub ( --> Nil) {
        while @signal {
            my &elt = @signal.pop;
            &elt();
        }
    };
    signal(SIGINT, SIGHUP, SIGQUIT, SIGTERM, SIGQUIT).tap( { &stack(); say "$_ Caught"; exit 0 } );
    "$thishost.local <---> $host.local".say;
    my Int $result = 0;
    my Int:D $cnt = 0;
    my $sync-flags = "$home/.sync-flags";
    unless $sync-flags.IO ~~ :d {
        $sync-flags.IO.mkdir();
    }
    "$sync-flags/$host".IO.spurt: $cnt;
    my $exclude-option = "--exclude-from=$config/exclude-files";
    my %results;
    for @sync-dirs -> $dir {
        say "[$dir/]";
        my Str $t = "$home/$dir/";
        if $t.IO ~~ :e {
            my $t0 = $t.IO.dirname;
            run 'ssh', "$user@$host.local", "mkdir -pv '$t0'";
            say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$home/$dir/", "$user@$host.local:$home/$dir/";
            my Proc $r = run "rsync", "-auv", "--progress", "$home/$dir/", $exclude-option, "$user@$host.local:$home/$dir/";
            dd $r;
            dd $result;
            %results{$dir} = $r.exitcode unless $r.exitcode == 0;
            $result +|= $r.exitcode;
        }
        if run 'ssh', "$user@$host.local", "ls -d $t" {
            my $t0 = $t.IO.dirname;
            run 'mkdir', '-pv', $t0;
            say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$user@$host.local:$home/$dir/", "$home/$dir/";
            my Proc $r = run "rsync", "-auv", "--progress", $exclude-option, "$user@$host.local:$home/$dir/", "$home/$dir/";
            %results{$dir} = $r.exitcode unless $r.exitcode == 0;
            dd $r;
            dd $result;
            $result +|= $r.exitcode;
        }
        say "";
        $cnt++;
        "$sync-flags/$host".IO.spurt: $cnt;
    }
    for @sync-files -> $file {
        say "[$file]";
        my Str $t = "$home/$file";
        if $t.IO ~~ :e {
            my $t0 = $t.IO.dirname;
            run 'ssh', "$user@$host.local", "mkdir -pv '$t0'";
            say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$home/$file", "$user@$host.local:$home/$file";
            my Proc $r = run "rsync", "-auv", "--progress", $exclude-option, "$home/$file", "$user@$host.local:$home/$file";
            %results{$file} = $r.exitcode unless $r.exitcode == 0;
            dd $r;
            dd $result;
            $result +|= $r.exitcode;
        }
        if run 'ssh', "$user@$host.local", "ls -d '$t'" {
            my $t0 = $t.IO.dirname;
            run 'mkdir', '-pv', $t0;
            say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$user@$host.local:$home/$file", "$home/$file";
            my Proc $r = run "rsync", "-auv", "--progress", $exclude-option, "$user@$host.local:$home/$file", "$home/$file";
            %results{$file} = $r.exitcode unless $r.exitcode == 0;
            dd $r;
            dd $result;
            $result +|= $r.exitcode;
        }
        say "";
        $cnt++;
        "$sync-flags/$host".IO.spurt: $cnt;
    }
    unless "$home/specials".IO ~~ :e {
        my Proc $res = run "mkdir", "-pv", "'$home/specials'";
        if $res.exitcode != 0 {
            "error cannot mkdir: $home/specials, perhaps $home is not writeable".say;
            $result +|= $res.exitcode;
            return $result, %results;
        }
    }
    my $t3 = "specials/";
    my Proc $res = run 'ssh', "$user@$host.local", "mkdir", "-pv", "'$t3'";
    if $res.exitcode != 0 {
        "error cannot mkdir: $t3, on remote system $user@$host.local".say;
        $result +|= $res.exitcode;
        return $result, %results;
    }
    say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$home/specials/", "$user@$host.local:$t3";
    my Proc $rr = run "rsync", "-auv", "--progress", $exclude-option, "$home/specials/", "$user@$host.local:$t3";
    $cnt++;
    "$sync-flags/$host".IO.spurt: $cnt;
    %results{"specials/"} = $rr.exitcode unless $rr.exitcode == 0;
    $result +|= $rr.exitcode;
    say join ' ', "rsync", "-auv", "--progress", $exclude-option, "$user@$host.local:$t3", "$home/specials/";
    my Proc $r0 = run "rsync", "-auv", "--progress", $exclude-option, "$user@$host.local:$t3", "$home/specials/";
    $cnt++;
    "$sync-flags/$host".IO.spurt: $cnt;
    %results{"$user@$host.local:$t3"} = $r0.exitcode unless $r0.exitcode == 0;
    $result +|= $r0.exitcode;
    dd %results;
    say "";
    $cnt++;
    "$sync-flags/$host".IO.spurt: $cnt;
    while @signal {
        my &elt = @signal.pop;
        &elt();
    }
    signal().tap({ exit $_ });
    return $result, %results;
} # sub sync-me(Str $thishost, Str $host, Str @sync-dirs, Str @sync-files, Str @sync-specials) returns List is export #

sub resolve-dir(Str $dir, Bool $relitive-to-home = True) returns Str is export {
    my Str $Dir = $dir;
    #$Dir.say;
    $Dir = $home if $Dir eq '~';
    $Dir ~~ s! ^^ '~' \/ !$home\/!;
    if $Dir ~~ rx! ^^ $<start> = [ '~' <-[ \/ ]> +  ] \/ ! {
        my Str $start = ~$<start>;
        given $start {
            when '~root' { $Dir ~~ s! ^^ '~' !\/!; }
            default {
                my Str @candidates = dir('/home', test => { "/home/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
                my Str $start_d = $start.substr(1);
                my Str $candidate = @candidates.grep: { rx/ \/ $start_d $$ / };
                if $candidate {
                    $Dir ~~ s! ^^ $start \/ !$candidate\/!;
                } else {
                    "cannot resolve $start".say;
                    return $dir;
                }
            }
        }
    }
    $Dir = "$home/$Dir" if $relitive-to-home && $Dir !~~ rx! ^^ \/ !;
    #$Dir.say;
    return $Dir;
}

sub resolve-up-to(Str $dir is copy, IO::Path $base = $*CWD --> Str) is export {
    $dir = resolve-dir($dir, False);
    my Str $basename = $dir.IO.basename;
    my Str $dirname = $dir.IO.dirname.Str;
    if $dirname eq '.' || $dirname eq '' {
        $dirname = $*CWD.Str;
    }
    try {
        CATCH {
            when X::IO::Resolve {
                "Error: could not resolve: $dirname".say;
            }
        }
        $dirname = $dirname.IO.resolve( :completely ).Str;
        $dirname.say;
        $dirname = $dirname.IO.absolute($base).Str;
        $dirname.say;
    }
    return $dirname.IO.add($basename).Str;
}

sub menu(Str $dir is copy = $backup-device, Str $message = "", Bool $list-all = False) returns Str is export {
    my Str @candidates;
    if $list-all {
        $dir = $dir.IO.dirname.Str;
        my Str @bases = dir($dir, test => { "$dir/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
        for @bases -> $base {
            my Str @tmp-candidates = dir($base, test => { "$base/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
            @candidates.push(|@tmp-candidates);
        }
    } else {
        @candidates = dir($dir, test => { "$dir/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
    }
    @candidates = @candidates.sort();
    @candidates.append('cancel');
    $message.say if $message;
    for @candidates.kv -> $indx, $candidate {
        "%10d\t%-20s\n".printf($indx, $candidate)
    }
    "use cancel, bye, bye bye, quit, q, or {+@candidates - 1} to quit".say;
    my $choice = -1;
    say "choose a backup to restore";
    loop {
        $choice = prompt("choose a candiate 0..{+@candidates - 1} =:> ");
        $choice = +@candidates - 1 if $choice ~~ rx:i/ ^^ \s* [ 'cancel' || 'bye' [ \s* 'bye' ] ? || 'quit' || 'q' ] \s* $$ /;
        if $choice !~~ rx/ ^^ \s* \d* \s* $$ / {
            "$choice: is not a valid option".say;
            redo
        }
        unless 0 <= $choice < +@candidates {
            "$choice: is not a valid option".say;
            redo;
        }
        last;
    }
    my Str $Dir = @candidates[$choice];
    #$Dir.say;
    return $Dir;
}

sub list-all(Str $dir is copy = $backup-device, Bool $all = False) returns Int is export {
    if $all {
        $dir = $dir.IO.dirname.Str; 
        $dir.say;
        if $dir.IO !~~ :d {
            "$dir does not exits perhaps the device is not attached".say;
            return 1;
        }
        my Str @bases = dir($dir, test => { "$dir/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
        my Str @all-candidates;
        for @bases -> $base {
            my Str @candidates = dir($base, test => { "$base/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
            @all-candidates.push(|@candidates);
        }
        @all-candidates = @all-candidates.sort();
        for @all-candidates -> $candidate {
            $candidate.say;
        }
        "{+@all-candidates} backups in total".say;
        return 0;
    }
    "$dir:".say;
    if $dir.IO !~~ :d {
        "$dir does not exits perhaps the device is not attached".say;
        return 1;
    }
    my Str @candidates = dir($dir, test => { "$dir/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
    @candidates = @candidates.sort();
    for @candidates -> $candidate {
        $candidate.say;
    }
    "{+@candidates} backups in total".say;
    return 0;
}

sub set-device(Str:D $device-name) returns Bool:D is export {
    my Str $dev = resolve-dir($device-name, False);
    $dev = $dev.IO.resolve.absolute;
    $dev ~~ s! ^^ $home '/' !\{home\}\/!;
    $dev ~~ s:g! '/' $thishost '/' !\/\{hostname\}\/!;
    $dev ~~ s! ^^ $thishost '/' !\{hostname\}\/!;
    $dev ~~ s! '/' $thishost $$ !\/\{hostname\}!;
    $dev ~~ s:g! '/' $user '/' !\/\{user\}\/!;
    $dev ~~ s! ^^ $user '/' !\{user\}\/!;
    $dev ~~ s! '/' $user $$ !\/\{user\}!;
    $dev ~~ s/ \/ $$ //;
    my Str $content = qq:to/END/;
        # the device to backup to #
        # \{user}     will be replaced by the username. 
        # \{hostnmae} will be replaced by the hostname.
        # \{home}     will be replaced by the home directory of the user it is running under.
        # if multi device lines are entered only the last will be in effect.
            device      =      $dev         # the backup device to use

        # these editors are gui editors
        # you can define multiple lines like these 
        # and the system will add to an array of strings 
        # to treat as guieditors (+= is prefered but = can be used).
    END
    $content .=trim-trailing;
    for @guieditors -> $guieditor {
        $content ~= "\n        guieditors  +=  $guieditor";
    }
    "$config/device".IO.spurt: $content;
    return True;
}

sub add-guieditor(Str:D $guieditor) returns Bool:D is export {
    my Str $dev = resolve-dir($backup-device, False);
    $dev = $dev.IO.resolve.absolute;
    $dev ~~ s! ^^ $home '/' !\{home\}\/!;
    $dev ~~ s:g! '/' $thishost '/' !\/\{hostname\}\/!;
    $dev ~~ s! ^^ $thishost '/' !\{hostname\}\/!;
    $dev ~~ s! '/' $thishost $$ !\/\{hostname\}!;
    $dev ~~ s:g! '/' $user '/' !\/\{user\}\/!;
    $dev ~~ s! ^^ $user '/' !\{user\}\/!;
    $dev ~~ s! '/' $user $$ !\/\{user\}!;
    $dev ~~ s/ \/ $$ //;
    my Str $content = qq:to/END/;
        # the device to backup to #
        # \{user}     will be replaced by the username. 
        # \{hostnmae} will be replaced by the hostname.
        # \{home}     will be replaced by the home directory of the user it is running under.
        # if multi device lines are entered only the last will be in effect.
            device      =      $dev         # the backup device to use

        # these editors are gui editors
        # you can define multiple lines like these 
        # and the system will add to an array of strings 
        # to treat as guieditors (+= is prefered but = can be used).
    END
    $content .=trim-trailing;
    if ! @guieditors.grep( { $_ eq $guieditor.IO.basename } ) {
        @guieditors.prepend($guieditor.IO.basename);
    }
    for @guieditors -> $guieditor {
        $content ~= "\n        guieditors  +=  $guieditor";
    }
    "$config/device".IO.spurt: $content;
    return True;
}

sub add-host(Str:D $host-name) returns Bool:D is export {
    my Str $host = $host-name;
    $host ~~ s/ '.local' $$ //;
    "$config/hosts".IO.spurt: qq:to/END/, :append;
    $host
    END
    return True;
}

sub add-file-exclusion(Str:D $pattern) returns Bool:D is export {
    "$config/exclude-files".IO.spurt: qq:to/END/, :append;
    $pattern
    END
    return True;
}

sub edit-configs() returns Bool:D is export {
    if $editor {
        my $option = '';
        my @args;
        my $edbase = $editor.IO.basename;
        if $edbase eq 'gvim' {
            $option = '-p';
            @args.append('-p');
        }
        my Str $cmd = "$editor $option ";
        @args.append(|@config-files);
        for @config-files -> $file {
            $cmd ~= "'$config/$file' ";
        }
        $cmd ~= '&' if @guieditors.grep: { rx/ ^^ $edbase $$ / };
        chdir($config.IO);
        #my $proc = run( :in => '/dev/tty', :out => '/dev/tty', :err => '/dev/tty', $editor, |@args);
        my $proc = run($editor, |@args);
        return $proc.exitcode == 0 || $proc.exitcode == -1;
    } else {
        "no editor found please set GUI_EDITOR, VISUAL or EDITOR to your preferred editor.".say;
        "e.g. export GUI_EDITOR=/usr/bin/gvim".say;
        return False;
    }
}

sub rmtree(Str $rm-from is copy, Bool $silent = False --> Bool) is export {
    my @files-to-delete = dir($rm-from, test => { $_ ne '.' && $_ ne '..' }).map: { $_.Str };
    my Bool $result = True;
    my Bool $verbose = !$silent;
    for @files-to-delete -> $file {
        if $file.IO ~~ :l {
            my Bool $r = $file.IO.unlink;
            if !$r {
                "Error could not unlink $file".say;
            } elsif $verbose {
                "removed $file".say;
            }
            $result ?&= $r;
        } elsif $file.IO !~~ :w {
            my Int $mode = $file.IO.mode().Int;
            $mode +|= 0o0444;
            my Bool $chmod = $file.IO.chmod: $mode;
            if !$chmod {
                "Error: could not change permissions on $file".say;
            } elsif $verbose {
                "changed perms on $file: a+w".say;
            }
        }
        if $file.IO ~~ :d {
            if $file.IO ~~ :x {
                my Int $mode = $file.IO.mode().Int;
                $mode +|= 0o0111;
                my Bool $chm = $file.IO.chmod: $mode;
                if !$chm {
                    "Error: could not change permissions on $file".say;
                } elsif $verbose {
                    "changed perms on $file: a+x".say;
                }
            }
            my Bool $r = rmtree($file, $silent);
            if !$r {
                "Error could not unlink $file/".say;
            } elsif $verbose {
                "removed $file/".say;
            }
            $result ?&= $r;
        } else {
            my Bool $r = $file.IO.unlink;
            if !$r {
                "Error could not unlink $file".say;
            } elsif $verbose {
                "removed $file".say;
            }
            $result ?&= $r;
        }
    }
    if $result {
        with $rm-from.IO.rmdir -> $rr {
            if !$rr {
                "Error could not unlink $rm-from This should never happen weird".say;
            } elsif $verbose {
                "removed $rm-from".say;
            }
            $result ?&= $rr;
        } else {
            "Error: could not remove $rm-from: {.exception.message}.".say;
            $result = False;
        }
    }
    return $result;
} #`««« sub rmtree(Str $rm-from is copy, Bool $silent = False --> Bool) is export »»»

sub get-files(Str $restore-from, Str $to, Bool $force, Bool $list-all = False, *@files --> Int) is export {
    my Str $To = resolve-dir($to);
    if $restore-from.IO !~~ :e {
        "no device $restore-from present".say;
        exit 1;
    }
    my $rest-from = menu($restore-from, "Choose a backup to restore from:", $list-all);
    exit 0 if $rest-from eq 'cancel';
    my $options = '-auv';
    my $exclude-option = "--exclude-from=$config/exclude-files";
    my $cmd     = 'rsync';
    if $force {
        $options = '-afv';
        $exclude-option = '--';
        $cmd     = 'cp';
    }
    my Int $result = 0;
    for @files -> $file {
        my Str $t = "$To/$file".IO.dirname;
        if $t.IO !~~ :e {
            run 'mkdir', '-pv', $t;
        }
        my $r;
        if "$rest-from/$file".IO ~~ :d {
            say "[$file/]";
            say join ' ', $cmd, $options, $exclude-option, "$rest-from/$file/", "$To/$file/";
            $r = run $cmd, $options, $exclude-option, "$rest-from/$file/", "$To/$file/";
        } else {
            "[$file]".say;
            say join ' ', $cmd, $options, $exclude-option, "$rest-from/$file", "$To/$file";
            $r = run $cmd, $options, $exclude-option, "$rest-from/$file", "$To/$file";
        }
        $result +|= $r.exitcode;
        say "";
    }
    return $result;
} #`««« sub get-files(Str $restore-from, Str $to, Bool $force, Bool $list-all = False, *@files --> Int) is export »»»

my Bool $yes-to-all = False;

sub are-you-sure(Str:D $message --> Bool) is export {
    my Str $reply = prompt($message);
    $reply .=trim;
    loop {
        last if $reply ~~ rx:i/^ [ 'yes' || 'no' || 'all' ] $ /;
        "Bad reply \`$reply', say yes, all or no".say;
        $reply = prompt($message);
        $reply .=trim;
    }
    if $reply eq 'all' {
        $yes-to-all = True;
        $reply = 'yes';
    }
    return ($reply ~~ rx:i/ ^ 'yes' $ /) ?? True !! False;
} # sub are-you-sure(Str:D $message --> Bool) is export #

sub quote(Str:D $str is copy --> Str:D) is export {
    $str ~~ s:g! \' !\\\'!;
    $str ~~ s:g! \" !\\\"!;
    return $str;
}

sub remove-files-on-all-synced-systems(Str @hosts, Str $thishost,
                                        Bool $silent, Bool $yes is copy,
                                        *@files --> Bool) is export {
    $yes = $yes-to-all if !$yes;
    my Bool $result = True;
    my @options = ('--force', '--remove', '--zero');
    push @options,  '--verbose' if !$silent;
    for  @files -> $file {
        my Str $resolved-filename = resolve-up-to($file);
        dd $resolved-filename;
        for @hosts -> $host {
            dd $host, $thishost;
            if $host eq $thishost {
                "$host.local".say if !$silent;
                if $resolved-filename.IO ~~ :l {
                    if $yes || are-you-sure("are you sure you want to delete $file [yes/no/all] ? ") {
                        $yes = True if $yes-to-all;
                        try {
                            CATCH {
                                when X::IO::Unlink {
                                    "could not unlink $resolved-filename".say;
                                }
                            }
                            my Bool $r = $resolved-filename.IO.unlink;
                            "removed '$resolved-filename'".say if $r && ! $silent;
                            $result ?&= $r;
                        } # try #
                    } # if $yes || are-you-sure("are you sure you want to delete $file [yes/no/all] ? ") #
                } elsif $resolved-filename.IO ~~ :d {
                    try {
                        CATCH {
                            when X::IO::Resolve {
                                "Error: could not resolve: '$resolved-filename'".say;
                                $result = False;
                            }
                        } # CATCH #
                        my $r = rmtree($resolved-filename, $silent) if $yes || are-you-sure("are you sure you want to delete '$resolved-filename' [yes/no/all] ? ");
                        $yes = True if $yes-to-all;
                        $result ?&= $r;
                    } # try #
                } elsif $resolved-filename.IO ~~ :e {
                    if $yes || are-you-sure("are you sure you want to delete '$resolved-filename' [yes/no/all] ? ") {
                        $yes = True if $yes-to-all;
                        try {
                            CATCH {
                                when X::IO::Unlink {
                                    "could not unlink '$resolved-filename'".say;
                                }
                            } # CATCH #
                            say join ' ', '/usr/bin/shred', |@options, "{$resolved-filename.Str}" if !$silent; 
                            my Proc $r = run '/usr/bin/shred', |@options, $resolved-filename.Str;
                            $result ?&= $r.exitcode == 0;
                        } # try #
                    } # if $yes || are-you-sure("are you sure you want to delete $resolved-filename [yes/no/all] ? ") #
                } elsif !$silent {
                    "'$resolved-filename' does not exist or is offline".say;
                }
            } elsif ! shell("ping -c 1 $host.local > /dev/null 2>&1 ") {
                "$host.local does not exist  or is down".say;
                "$host.local: skipped".say;
            } else {
                "$host.local".say if !$silent;
                try {
                    CATCH {
                        when X::IO::Resolve {
                            "Error: could not resolve: '$resolved-filename'".say;
                            $result = False;
                        }
                    }
                    if $yes || are-you-sure("are you sure you want to delete {$resolved-filename.Str} on $host.local [yes/no/all] ? ") {
                        $yes = True if $yes-to-all;
                        say join ' ', 'ssh', "$user@$host.local", '/usr/bin/shred', |@options, "{$resolved-filename.Str}" if !$silent; 
                        my Proc $r = run 'ssh', "$user@$host.local", '/usr/bin/shred', |@options, $resolved-filename.Str;
                        $result ?&= $r.exitcode == 0;
                    }
                } # try #
            } # else #
        } # for @hosts -> $host #
    } # for @files -> $file #
    return $result;
} #`««« sub remove-files-on-all-synced-systems(Str @hosts, Str $thishost,
                                                Bool $silent, Bool $yes is copy,
                                                *@files --> Bool) is export »»»

sub move-files-on-all-synced-systems(Str @hosts, Str $thishost, Bool $silent, Bool $yes is copy,
                                     Str $dest is copy, *@files --> Bool) is export {
    $yes = $yes-to-all if !$yes;
    my Bool $result = True;
    my $options = '-f';
    $options   ~= 'v' if !$silent;
    $dest = resolve-up-to($dest);
    if $dest.IO !~~ :e {
        try {
            CATCH {
                when X::IO::Mkdir {
                    "Could not mkdir $dest".say;
                }
            }
            $dest.IO.mkdir;
        }
    }
    my IO::Path $Dest = $dest.IO;
    if $Dest !~~ :d {
        "Error: $dest is not a directory".say;
        return False;
    }
    for  @files -> $file {
        my IO::Path $dest-file = "$dest/$file".IO;
        my Str $resolved-filename = resolve-up-to($file);
        for @hosts -> $host {
            if $host eq $thishost {
                "$host.local".say if !$silent;
                if $resolved-filename.IO ~~ :d {
                    if $yes || are-you-sure("are you sure you want to move '$file/' to '$dest/$file/' [yes/no/all] ? ") {
                        $yes = True if $yes-to-all;
                        try {
                            CATCH {
                                when X::IO::Resolve {
                                    "Error: could not resolve: '$resolved-filename'".say;
                                    $result = False;
                                }
                            }
                            say join ' ', 'mv', $options, "'{$resolved-filename.Str}'", "'{$dest-file.Str}'" if !$silent; 
                            my Proc $r = run 'mv', $options, "'{$resolved-filename.Str}'", "'{$dest-file.Str}'";
                            $result ?&= $r.exitcode == 0;
                        } # try #
                    } # if $yes || are-you-sure("are you sure you want to delete $file [yes/no/all] ? ") #
                } elsif $resolved-filename.IO ~~ :e {
                    if $yes || are-you-sure("are you sure you want to move '$file' to '$dest/$file' [yes/no/all] ? ") {
                        $yes = True if $yes-to-all;
                        try {
                            CATCH {
                                when X::IO::Move {
                                    "could not move '$resolved-filename' to '$dest/$file'".say;
                                }
                            }
                            my Bool $r = $resolved-filename.IO.move($dest-file);
                            "moved '$resolved-filename' --> '$dest/$file'".say if $r && ! $silent;
                            $result ?&= $r;
                        } # try #
                    } # if $yes || are-you-sure("are you sure you want to delete $file [yes/no/all] ? ") #
                } elsif !$silent {
                    "'$resolved-filename' does not exist or is offline".say;
                }
            } elsif ! shell("ping -c 1 $host.local > /dev/null 2>&1 ") {
                "$host.local does not exist  or is down".say;
                "$host.local: skipped".say;
            } else {
                "$host.local".say if !$silent;
                try {
                    CATCH {
                        when X::IO::Resolve {
                            "Error: could not resolve: '$resolved-filename'".say;
                            $result = False;
                        }
                    }
                    run 'ssh', "$user@$host.local", "mkdir -pv '$dest'";
                    if $yes || are-you-sure("are you sure you want to move '{$resolved-filename.Str}' to '{$dest-file.Str}' on $host.local [yes/no/all] ? ") {
                        $yes = True if $yes-to-all;
                        say join ' ', 'ssh', "$user@$host.local", 'mv', $options, "'{$resolved-filename.Str}'", "'{$dest-file.Str}'" if !$silent; 
                        my Proc $r = run 'ssh', "$user@$host.local", 'mv', $options, "'{$resolved-filename.Str}'", "'{$dest-file.Str}'";
                        $result ?&= $r.exitcode == 0;
                    }
                } # try #
            } # else #
        } # for @hosts -> $host #
    } # for @files -> $file #
    return $result;
} #`««« sub move-files-on-all-synced-systems(Str @hosts, Str $thishost, Bool $silent, Bool $yes is copy,
                                     Str $dest is copy, *@files --> Bool) is export »»»

sub put-in-dirs(Str @hosts, Str $thishost, Bool $silent, Bool $yes is copy, Int $first where { $first > 0 },
                    Int $last where { $first <= $last }, *@files --> Bool) is export {
    my Bool $result = True;
    for $first .. $last -> $current {
        #"$current".IO.mkdir();
        my Str @candidates = glob("{$current}*").map: { $_.Str };
        @candidates = @candidates.grep: { !rx/ ^^ $current $$ / };
        my $res = move-files-on-all-synced-systems(@hosts, $thishost, $silent, $yes, $current.Str, |@candidates);
        $result ?&= $res;
    }
    my $res = move-files-on-all-synced-systems(@hosts, $thishost, $silent, $yes, $first.Str, |@files);
    $result ?&= $res;
    return $result;
} #`««« sub put-in-dirs(Str @hosts, Str $thishost, Bool $silent, Bool $yes is copy, Int $first where { $first > 0 },
                    Int $last where { $first <= $last }, *@files --> Bool) is export »»»
