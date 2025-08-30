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

  * [Introduction](#introduction)

    * [backup.raku specials](#backupraku-specials)

NAME
====

BackupAndSync.rakumod 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.1.2

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

0.1.2

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
    "specials"
) returns Int
```

backup special files and directories to per system special location.

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

0.1.2

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
multi sub MAIN() returns Int
```

Synchronise systems in hosts file.

