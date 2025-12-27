#!/usr/bin/env raku
use v6;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;

#`{ 
 sychronise my boxes 
}

use BackupAndSync;
use Terminal::Gauge;

if ! insure-config-is-present() {
    die "problem with config files";
}

=begin pod

=head1 App::Sync

=begin head2

Table of Contents

=end head2

=item1 L<NAME|#name>
=item1 L<AUTHOR|#author>
=item1 L<VERSION|#version>
=item1 L<TITLE|#title>
=item1 L<SUBTITLE|#subtitle>
=item1 L<COPYRIGHT|#copyright>
=item1 # L<Introduction|#introduction>
=item2 # L<sync.raku|#syncraku>

=NAME sync.raku 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.3
=TITLE sync.raku
=SUBTITLE A B<Raku> application for synchronising a set of boxes.

=COPYRIGHT
LGPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/backup/blob/main/LICENSE>

L<Top of Document|#table-of-contents>

=head1 Introduction

 A B<Raku> application for synchronising a set of boxes. 

=end pod

# the hosts to keep synchronised #
#my Str @hosts = qw{rakbat killashandra pern};
my Str @hosts = hosts-val();

# the dirs to synchronise #
my Str @sync-dirs = dirs-val();

# the individual files to sync #
my Str @sync-files = files-val();

# the individual files or directory's to independently backup #
my Str @sync-specials = specials-val();

=begin pod

=head1 sync.raku

=begin code :lang<bash>

sync.raku --help
Usage:
  sync.raku -- Synchronise systems in hosts file.

=end code

=end pod

multi sub MAIN(Bool:D :v(:$version) = False, Str:D :c(:$bar-char) = '⧫', Str:D :e(:$empty-char) = ' ',
                Str:D :P(:$prefix-foreground) = "bold,red", Str:D :p(:$prefix-background) = "green",
                    Str:D :G(:$gauge-foreground) = "bold,red", Str:D :g(:$gauge-background) = "cyan",
                        Str:D :S(:$suffix-foreground) = "bold,green", Str:D :s(:$suffix-background) = 'blue', 
                            Str:D :$sub-bar-char = '❚', Str:D :$sub-empty-char = ' ', Str:D :$sub-gauge-foreground = "bold,green",
                                Str:D :$sub-gauge-background = "red", Str:D :$sub-suffix-foreground = "bold,red", 
                                    Str:D :$sub-suffix-background = "cyan", Bool:D :r(:$progress) = False, Bool:D :d(:$delete) = False --> Int) {
    clean-up-mon-sync();
    my Str:D $prog = $*PROGRAM-NAME.IO.basename;
    if $version {
        my Str:D $mod-version    = version();
        my Str:D $version-suffix = version-suffix();
        $*ERR.say: "$prog {$mod-version}-$version-suffix";
        exit(0);
    }
    set-bar-char($bar-char);
    set-empty-char($empty-char);
    set-prefix-foreground($prefix-foreground);
    set-prefix-background($prefix-background);
    set-gauge-foreground($gauge-foreground);
    set-gauge-background($gauge-background);
    set-suffix-foreground($suffix-foreground);
    set-suffix-background($suffix-background);
    set-sub-bar-char($sub-bar-char);
    set-sub-empty-char($sub-empty-char);
    set-sub-gauge-foreground($sub-gauge-foreground);
    set-sub-gauge-background($sub-gauge-background);
    set-sub-suffix-foreground($sub-suffix-foreground);
    set-sub-suffix-background($sub-suffix-background);
    my ($result, %results) = sync-me-master($progress, $delete);
    #dd %results;
    %results.gist.say;
    exit $result;
} #`««« multi sub MAIN(Bool:D :v(:$version) = False, Str:D :c(:$bar-char) = '⧫', Str:D :e(:$empty-char) = ' ',
                Str:D :F(:$prefix-foreground) = "bold,red", Str:D :B(:$prefix-background) = "green",
                    Str:D :F(:$gauge-foreground) = "bold,red", Str:D :B(:$gauge-background) = "cyan",
                        Str:D :S(:$suffix-foreground) = "bold,green", Str:D :s(:$suffix-background) = 'blue', 
                            Str:D :$sub-bar-char = '◼', Str:D :$sub-empty-char = ' ', Str:D :$sub-gauge-foreground = "bold,green",
                                Str:D :$sub-gauge-background = "red", Str:D :$sub-suffix-foreground = "bold,red", 
                                    Str:D :$sub-suffix-background = "cyan", Bool:D :r(:$progress) = False, Bool:D :d(:$delete) = False --> Int) »»»
#= Synchronise systems in hosts file.

multi sub MAIN('configs', 'list') returns Int {
    "$config:".say;
    for @config-files -> $file {
        printf "%15s:\t%-55s\n\n", $file, describe-config-file($file);
    }
    exit 0;
}
#= list the configuration files.

multi sub MAIN('set', 'device', Str:D $device) returns Int {
   if set-device($device) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('add', 'guieditor', Str:D $guieditor) returns Int {
   if add-guieditor($guieditor) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('add', 'host', Str:D $host-name) returns Int {
   if add-host($host-name) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('add', 'file-exclusion', Str:D $pattern) returns Int {
   if add-file-exclusion($pattern) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('edit', 'configs') returns Int {
   if edit-configs() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('help') returns Int {
    $*USAGE.say;
    exit 0;
}

multi sub MAIN('usage') returns Int {
    $*USAGE.say;
    exit 0;
}

multi sub MAIN('remove', Bool :s(:$silent) = False, Bool :y(:$yes) = False, *@files) returns Int {
    if remove-files-on-all-synced-systems(@hosts, $thishost, $silent, $yes, |@files) {
        exit 0;
    } else {
        exit -2;
    }
}

multi sub MAIN('move', Str $dest, Bool :s(:$silent) = False, Bool :y(:$yes) = False, *@files) returns Int {
    if move-files-on-all-synced-systems(@hosts, $thishost, $silent, $yes, $dest, |@files) {
        exit 0;
    } else {
        exit -2;
    }
}

multi sub MAIN('put-in-dirs', Int $first, Int $last, Bool :s(:$silent) = False, Bool :y(:$yes) = False, *@files) returns Int {
    if put-in-dirs(@hosts, $thishost, $silent, $yes, $first, $last, |@files) {
        exit 0;
    } else {
        exit -2;
    }
}

# vim: :set filetype=raku #
