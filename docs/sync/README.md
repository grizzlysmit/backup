App::Sync
=========

Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

  * [Introduction](#introduction)

    * [sync.raku](#syncraku)

NAME
====

sync.raku 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.2.8

TITLE
=====

sync.raku

SUBTITLE
========

A **Raku** application for synchronising a set of boxes.

COPYRIGHT
=========

LGPL V3.0+ [LICENSE](https://github.com/grizzlysmit/backup/blob/main/LICENSE)

[Top of Document](#table-of-contents)

Introduction
============

    A B<Raku> application for synchronising a set of boxes.

sync.raku
=========

```bash
sync.raku --help
Usage:
  sync.raku -- Synchronise systems in hosts file.
```

### multi sub MAIN

```raku
multi sub MAIN(
    Bool:D :v(:$version) = Bool::False,
    Str:D :c(:$bar-char) = "⧫",
    Str:D :e(:$empty-char) = " ",
    Str:D :P(:$prefix-foreground) = "bold,red",
    Str:D :p(:$prefix-background) = "green",
    Str:D :G(:$gauge-foreground) = "bold,red",
    Str:D :g(:$gauge-background) = "cyan",
    Str:D :S(:$suffix-foreground) = "bold,green",
    Str:D :s(:$suffix-background) = "blue",
    Str:D :$sub-bar-char = "❚",
    Str:D :$sub-empty-char = " ",
    Str:D :$sub-gauge-foreground = "bold,green",
    Str:D :$sub-gauge-background = "red",
    Str:D :$sub-suffix-foreground = "bold,red",
    Str:D :$sub-suffix-background = "cyan",
    Bool:D :r(:$progress) = Bool::False,
    Bool:D :d(:$delete) = Bool::False
) returns Int
```

# Synchronise systems in hosts file.

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

# add a gui ewditor to the config file device

### multi sub MAIN

```raku
multi sub MAIN(
    "add",
    "host",
    Str:D $host-name
) returns Int
```

# add a host to the config file hosts

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

### multi sub MAIN

```raku
multi sub MAIN(
    "remove",
    Bool :s(:$silent) = Bool::False,
    Bool :y(:$yes) = Bool::False,
    *@files
) returns Int
```

# remove the files from all hosts in hosts.

### multi sub MAIN

```raku
multi sub MAIN(
    "move",
    Str $dest,
    Bool :s(:$silent) = Bool::False,
    Bool :y(:$yes) = Bool::False,
    *@files
) returns Int
```

# move the files on all synced systems to $dest

### multi sub MAIN

```raku
multi sub MAIN(
    "put-in-dirs",
    Int $first,
    Int $last,
    Bool :s(:$silent) = Bool::False,
    Bool :y(:$yes) = Bool::False,
    *@files
) returns Int
```

# put all files matching current* (excluding current itself) into directory current where current is succesively each value from first to last and then put files into first

