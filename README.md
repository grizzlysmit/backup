BackupAndSync
=============

Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

    * [sub backup-device-val(--> Str) is export](#sub-backup-device-val---str-is-export)

  * [Introduction](#introduction)

NAME
====

BackupAndSync.rakumod 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.2.0

TITLE
=====

BackupAndSync.rakumod

SUBTITLE
========

A **Raku** module for supporting the backup and sync of a set of boxes.

COPYRIGHT
=========

LGPL V3.0+ [LICENSE](https://github.com/grizzlysmit/GUI-Editors/blob/main/LICENSE)

[Top of Document](#table-of-contents)

Introduction
============

    A B<Raku> module for supporting the backup and sync of a set of boxes.

sub backup-device-val(--> Str) is export 
=========================================

```raku
sub backup-device-val(--> Str) is export
```

[Top of Document](#table-of-contents)

### sub put-in-dirs

```raku
sub put-in-dirs(
    Str @hosts,
    Str $thishost,
    Bool $silent,
    Bool $yes is copy,
    Int $first where { ... },
    Int $last where { ... },
    *@files
) returns Bool
```

# put all files matching current* (excluding current itself) into directory current where current is succesively each value from first to last and then put files into first

