App::Backup
===========

Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

  * [Introduction](#introduction)

    * [backup.raku specials](#backupraku-specials)

NAME
====

Backup 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.2.7

TITLE
=====

Backup

SUBTITLE
========

A **Raku** application for backing up a box.

COPYRIGHT
=========

LGPL V3.0+ [LICENSE](https://github.com/grizzlysmit/backup/blob/main/LICENSE)

[Top of Document](#table-of-contents)

Introduction
============

    A B<Raku> application for backing up a box.

backup.raku specials
====================

```bash
backup.raku specials --help
Usage:
  backup.raku specials -- backup special files and directories to per system special location.
```

[Top of Document](#table-of-contents)

### multi sub MAIN

```raku
multi sub MAIN(
    "specials",
    Bool:D :v(:$version) = Bool::False,
    Str:D :c(:$bar-char) = "⧫",
    Str:D :e(:$empty-char) = " ",
    Str:D :P(:$prefix-foreground) = "bold,red",
    Str:D :p(:$prefix-background) = "green",
    Str:D :G(:$gauge-foreground) = "bold,red",
    Str:D :g(:$gauge-background) = "cyan",
    Str:D :S(:$suffix-foreground) = "bold,green",
    Str:D :s(:$suffix-background) = "blue",
    Bool:D :r(:$progress) = Bool::False,
    Bool:D :d(:$delete) = Bool::False
) returns Int
```

# backup special files and directories to per system special location

### multi sub MAIN

```raku
multi sub MAIN(
    "new",
    Bool:D :v(:$version) = Bool::False,
    Str:D :c(:$bar-char) = "⧫",
    Str:D :e(:$empty-char) = " ",
    Str:D :P(:$prefix-foreground) = "bold,red",
    Str:D :p(:$prefix-background) = "green",
    Str:D :G(:$gauge-foreground) = "bold,red",
    Str:D :g(:$gauge-background) = "cyan",
    Str:D :S(:$suffix-foreground) = "bold,green",
    Str:D :s(:$suffix-background) = "blue",
    Str :t(:$time) = Code.new,
    Str :b(:$backup-to) is copy = Code.new,
    Bool:D :r(:$progress) = Bool::False,
    Bool:D :d(:$delete) = Bool::False
) returns Int
```

# create a new backup on device.

### multi sub MAIN

```raku
multi sub MAIN(
    "add-to-last",
    Bool:D :v(:$version) = Bool::False,
    Str:D :c(:$bar-char) = "⧫",
    Str:D :e(:$empty-char) = " ",
    Str:D :P(:$prefix-foreground) = "bold,red",
    Str:D :p(:$prefix-background) = "green",
    Str:D :G(:$gauge-foreground) = "bold,red",
    Str:D :g(:$gauge-background) = "cyan",
    Str:D :S(:$suffix-foreground) = "bold,green",
    Str:D :s(:$suffix-background) = "blue",
    Str :t(:$time) = Code.new,
    Str :b(:$backup-to) is copy = Code.new,
    Bool:D :r(:$progress) = Bool::False,
    Bool:D :d(:$delete) = Bool::False
) returns Int
```

# add to the last backup on the device

### multi sub MAIN

```raku
multi sub MAIN(
    "restore",
    "last",
    Str :t(:$time) = Code.new,
    Str :r(:$restore-from) is copy = Code.new,
    Str :T(:$to) = Code.new,
    Bool :f(:$force) = Bool::False
) returns Int
```

# restore from the last bacup on the device

### multi sub MAIN

```raku
multi sub MAIN(
    "restore",
    "menu",
    Str :r(:$restore-from) = Code.new,
    Str :T(:$to) = Code.new,
    Bool :f(:$force) = Bool::False,
    Bool :l(:$list-all) = Bool::False
) returns Int
```

# prompt with a menu to seclect and restore from backups on the device

### multi sub MAIN

```raku
multi sub MAIN(
    "get",
    "files",
    Str :r(:$restore-from) = Code.new,
    Str :T(:$to) = Code.new,
    Bool :f(:$force) = Bool::False,
    Bool :l(:$list-all) = Bool::False,
    *@files
) returns Int
```

# restore these files from the backup bacup is specified by menu

### multi sub MAIN

```raku
multi sub MAIN(
    "remove",
    Str :r(:$remove-from) = Code.new,
    Bool :s(:$silent) = Bool::False,
    Bool :l(:$list-all) = Bool::False
) returns Int
```

# remove backup chosen by menu from device

### multi sub MAIN

```raku
multi sub MAIN(
    "list",
    Bool :a(:$all) = Bool::False,
    Str :d(:$dir) = Code.new
) returns Int
```

# list all backups

### multi sub MAIN

```raku
multi sub MAIN(
    "configs",
    "list"
) returns Int
```

# list and describe all configfiles

### multi sub MAIN

```raku
multi sub MAIN(
    "set",
    "device",
    Str:D $device
) returns Int
```

# set the device for backups to the device file

### multi sub MAIN

```raku
multi sub MAIN(
    "add",
    "guieditor",
    Str:D $guieditor
) returns Int
```

# add a gui ewditor to the configuration file device

### multi sub MAIN

```raku
multi sub MAIN(
    "add",
    "file-exclusion",
    Str:D $pattern
) returns Int
```

# add a pattern to the configuration file exclude-files

### multi sub MAIN

```raku
multi sub MAIN(
    "edit",
    "configs"
) returns Int
```

# edit all config files in the gui editorof your choice.

### multi sub MAIN

```raku
multi sub MAIN(
    "help"
) returns Int
```

# display help message

### multi sub MAIN

```raku
multi sub MAIN(
    "usage"
) returns Int
```

# display usage message

