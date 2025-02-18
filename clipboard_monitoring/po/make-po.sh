#! /bin/bash

cd `dirname $0`

XGETTEXT="${XGETTEXT:-xgettext}"
GETTEXT_PACKAGE="${GETTEXT_PACKAGE:-io.github.q962.ClipboardServer}"
XGETTEXT_KEYWORDS="${XGETTEXT_KEYWORDS:- --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 }"

top_srcdir=../src

$XGETTEXT \
          --directory="$top_srcdir" \
          --msgid-bugs-address="https://gitlab.gnome.org/GNOME/gtk/-/issues/" \
		   --package-name=$GETTEXT_PACKAGE \
          --add-comments \
          $XGETTEXT_KEYWORDS \
          --from-code=utf-8 \
          --files-from="POTFILES.in" \
		  -o $GETTEXT_PACKAGE.pot

