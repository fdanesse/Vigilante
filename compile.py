#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import commands

BASE_PATH = os.path.dirname(os.path.realpath(__file__))


def run():
    comando = "valac --pkg posix --pkg gio-2.0 --pkg gtk+-3.0 --pkg gdk-3.0 --thread"
    comando = "%s %s" % (comando, " --pkg glib-2.0 --pkg gdk-x11-3.0")
    comando = "%s %s" % (comando, " --pkg gstreamer-1.0 --pkg gstreamer-video-1.0")
    comando = "%s %s" % (comando, " main.vala")

    for (f, d, fs) in os.walk(BASE_PATH):
        for fn in fs:
            if fn != "main.vala":
                fp = os.path.join(f, fn)
                fp = fp.replace(BASE_PATH, ".")
                if os.path.splitext(fp)[1] == ".vala":
                    comando = "%s %s" % (comando, fp)

    print "*** Ejecutando Comando... ***"
    text = commands.getoutput(comando)
    print text
    print "*** Comando Utilizado:\n", comando, "\n***"
    print ">>> Errores:", not "compilation succeeded" in text.lower()


if __name__ == "__main__":
    run()
