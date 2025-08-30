#!/usr/bin/env raku
use v6;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;

#`{ 
 back up a box to portable hard drive
}

#use lib "{%*ENV<HOME>}/.raku";

use BackupAndSync;

if ! insure-config-is-present() {
    die "problem with config files";
}

=begin pod

=head1 App::Backup

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
=item2 # L<backup.raku specials|#backupraku-specials>

=NAME Backup 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.2
=TITLE Backup
=SUBTITLE A B<Raku> application for backing up a box.

=COPYRIGHT
LGPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/backup/blob/main/LICENSE>

L<Top of Document|#table-of-contents>

=head1 Introduction

 A B<Raku> application for backing up a box. 

=end pod

# get the backup-device from the library #
my Str $backup-device = backup-device-val();

# the dirs to backup #
my Str @backup-dirs = dirs-val();

#@backup-dirs.raku.say;
#exit 0;

# the individual files to backup #
my Str @backup-files = files-val();

# the individual files or directory's to independently backup #
my Str @backup-specials = specials-val();

=begin pod

=head1 backup.raku specials

=begin code :lang<bash>

backup.raku specials --help
Usage:
  backup.raku specials -- backup special files and directories to per system special location.

=end code

L<Top of Document|#table-of-contents>

=end pod


multi sub MAIN('specials') returns Int {
    my Int $result = 0;
    my %results;
    my ($r, %results_catch) = specials($thishost, @backup-specials);;
    %results{$thishost} = %results_catch;
    $result +|= $r;
    "\$r == $r".say;
    dd $result;
    #dd %results;
    %results.gist.say;
    exit $result;
}
#= backup special files and directories to per system special location.

multi sub MAIN('new', Str :t(:$time) = DateTime.now.Str, Str :b(:$backup-to) is copy = $backup-device) returns Int {
    my Int $result = 0;
    my %results;
    $backup-to ~= "/$time";
    $backup-to.say;
    my ($r, %results_catch) = backup-me($thishost, $backup-to, @backup-dirs, @backup-files, @backup-specials);;
    %results{$thishost} = %results_catch;
    $result +|= $r;
    "\$r == $r".say;
    dd $result;
    #dd %results;
    %results.gist.say;
    exit $result;
}

multi sub MAIN('add-to-last', Str :t(:$time) = DateTime.now.Str, Str :b(:$backup-to) is copy = $backup-device){
    my Int $result = 0;
    my %results;
    $backup-to ~= "/$time";
    $backup-to.say;
    my Str $back-to = $backup-to;
    if $back-to.IO !~~ :d {
        $back-to = $back-to.IO.dirname;
        $back-to.say;
        my Str @candidates = dir($back-to, test => { "$back-to/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
        @candidates.raku.say;
        $back-to = [max] @candidates;
    }
    $back-to.say;
    my ($r, %results_catch) = backup-me($thishost, $back-to, @backup-dirs, @backup-files, @backup-specials);;
    %results{$thishost} = %results_catch;
    $result +|= $r;
    "\$r == $r".say;
    dd $result;
    #dd %results;
    %results.gist.say;
    exit $result;
}

multi sub MAIN('restore', 'last', Str :t(:$time) = DateTime.now.Str, Str :r(:$restore-from) is copy = "$backup-device", Str :T(:$to) = "$home", Bool :f(:$force) = False) returns Int {
    my Int $result = 0;
    my %results;
    $restore-from ~= "/$time";
    my Str $To = resolve-dir($to);
    $restore-from.say;
    my Str $rest-from = $restore-from;
    if $rest-from.IO !~~ :d {
        $rest-from = $rest-from.IO.dirname;
        $rest-from.say;
        if $rest-from.IO !~~ :e {
            "no device $rest-from present".say;
            exit 1;
        }
        my Str @candidates = dir($rest-from, test => { "$rest-from/$_".IO.d && $_ ne '.' && $_ ne '..' }).map: { $_.Str };
        #@candidates.raku.say;
        $rest-from = [max] @candidates;
    }
    $rest-from.say;
    exit restore-me($thishost, $rest-from, $To, $force, @backup-dirs, @backup-files);
}

multi sub MAIN('restore', 'menu', Str :r(:$restore-from) = $backup-device, Str :T(:$to) = "$home", Bool :f(:$force) = False, Bool :l(:$list-all) = False) returns Int {
    my Str $To = resolve-dir($to);
    #$restore-from.say;
    if $restore-from.IO !~~ :e {
        "no device $restore-from present".say;
        exit 1;
    }
    my $rest-from = menu($restore-from, "Choose a backup to restore from:", $list-all);
    exit 0 if $rest-from eq 'cancel';
    exit restore-me($thishost, $rest-from, $To, $force, @backup-dirs, @backup-files);
}

multi sub MAIN('get', 'files', Str :r(:$restore-from) = $backup-device, Str :T(:$to) = "$home", Bool :f(:$force) = False, Bool :l(:$list-all) = False, *@files) returns Int {
    return get-files($restore-from, $to, $force, $list-all, |@files);
}

multi sub MAIN('remove', Str :r(:$remove-from) = $backup-device, Bool :s(:$silent) = False, Bool :l(:$list-all) = False --> Int) {
    if $remove-from.IO !~~ :e {
        "no device $remove-from present".say;
        exit 1;
    }
    my $rm-from = menu($remove-from, "Choose a backup to remove:", $list-all);
    exit 0 if $rm-from eq 'cancel';
    if rmtree($rm-from, $silent) {
        exit 0;
    } else {
        exit 1;
    }
}

multi sub MAIN('list',  Bool :a(:$all) = False, Str :d(:$dir) = $backup-device) returns Int {
    exit list-all($dir, $all);
}

multi sub MAIN('configs', 'list') returns Int {
    "$config:".say;
    for @config-files -> $file {
        printf "%15s:\t%-55s\n\n", $file, describe-config-file($file);
    }
    exit 0;
}

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

# vim: :set filetype=raku #
