��    M      �  g   �      �  @   �  :   �  L     6   R  L   �  D   �  G     9   c  ?   �  K   �  ;   )	  u   e	  B   �	  2   
    Q
  N   `  @   �  9   �  ?   *    j  u   x  J   �  =   9  K   w  5   �  E   �  *   ?  ?   j  R   �  !   �  +        K  7   g  !   �  %   �  1   �  !     5   ;     q  ,   �  ;   �     �          *  j   @  C   �     �  k     7   w  6   �  A   �  
   (  a   3     �  2   �     �     �       E     !   `  2   �     �  )   �     �       V   %  %   |     �  N   �  /     I   5       �  �  Q     (   k      �  �  �  I   x  I   �  p     9   }  L   �  R     R   W  @   �  @   �  L   ,  M   y  �   �  C   o  <   �  �  �  J   �!  G   �!  @   D"  H   �"  .  �"  �   �#  U   �$  H   �$  I   E%  :   �%  G   �%  -   &  [   @&  S   �&  9   �&  N   *'  *   y'  A   �'  6   �'  1   (  B   O(  8   �(  H   �(  -   )  E   B)  T   �)     �)      �)     *  }   0*  T   �*  '   +  �   ++  @   �+  :   �+  I   4,     ~,  f   �,     �,  @   -     L-     b-      ~-  e   �-  0   .  8   6.     o.  -   �.     �.  !   �.  t   �.  8   k/     �/  h   �/  6    0  X   W0     �0  �  �0  [   a2  *   �2      �2         C   .          1   /   %   I   4   0   ;       L         B   6          G              A              H       5   E       *   #         $   F                    '   (   >   ?   :   -   
       3           8   @       +                  K   D   9               2   =       )                   M       ,             <       	   7   &   "                 J          !                   --copyright-holder=STRING  set copyright holder in output
       --force-po              write PO file even if empty
       --foreign-user          omit FSF copyright in output for foreign user
       --from-code=NAME        encoding of input files
       --msgid-bugs-address=EMAIL@ADDRESS  set report address for msgid bugs
       --no-location           do not write '#: filename:line' lines
       --omit-header           don't write header with 'msgid ""' entry
       --package-name=PACKAGE  set package name in output
       --package-version=VERSION  set package version in output
   -D, --directory=DIRECTORY   add DIRECTORY to list for input files search
   -F, --sort-by-file          sort output by file location
   -M[STRING], --msgstr-suffix[=STRING]  use STRING or "" as suffix for msgstr
                                values
   -V, --version               output version information and exit
   -a, --extract-all           extract all strings
   -cTAG, --add-comments=TAG   place comment blocks starting with TAG and
                                preceding keyword lines in output file
  -c, --add-comments          place all comment blocks preceding keyword lines
                                in output file
   -d, --default-domain=NAME   use NAME.po for output (instead of messages.po)
   -f, --files-from=FILE       get list of input files from FILE
   -h, --help                  display this help and exit
   -j, --join-existing         join messages with existing file
   -kWORD, --keyword=WORD      look for WORD as an additional keyword
  -k, --keyword               do not to use default keywords"));
      --flag=WORD:ARG:FLAG    additional flag for strings inside the argument
                              number ARG of keyword WORD
   -m[STRING], --msgstr-prefix[=STRING]  use STRING or "" as prefix for msgstr
                                values
   -n, --add-location          generate '#: filename:line' lines (default)
   -o, --output=FILE           write output to specified file
   -p, --output-dir=DIR        output files will be placed in directory DIR
   -s, --sort-output           generate sorted output
   -x, --exclude-file=FILE.po  entries from FILE.po are not extracted
   INPUTFILE ...               input files
 --join-existing cannot be used when output is written to stdout A --flag argument doesn't have the <keyword>:<argnum>:[pass-]<flag> syntax: {flag} Attempt to add entries before run Attempt to output from extractor before run Attempt to re-run extractor By default the input files are assumed to be in ASCII.
 Error opening '{file}': {error}!
 Error reading '{filename}': {error}!
 Error resolving file name '{filename}': {error}!
 Error writing '{file}': {error}.
 Extract translatable strings from given input files.
 Extract translatable strings.
 If input file is -, standard input is read.
 If output file is -, output is written to standard output.
 Informative output:
 Input file interpretation:
 Input file location:
 Input files are interpreted as plain text files with each paragraph being
a separately translatable unit.
 Invalid argument specification '{spec}' for function '{function}'!
 Language specific options:
 Mandatory arguments to long options are mandatory for short options too.
Similarly for optional arguments.
 Multiple automatic comments for function '{function}'!
 Multiple context arguments for function '{function}'!
 Multiple meanings for argument #{num} for function '{function}'!
 No PO data Non-ASCII string at '{reference}'.
    Please specify the source encoding through '--from-code'.
 Operation mode:
 Option 'add_comments' must be an array reference.
 Output details:
 Output file location:
 Report bugs at <{URL}>!
 The argument to '--add-location' must be 'full', 'file', or 'never'.
 Too many forms for '{function}'!
 Try '{program_name} --help' for more information!
 Usage: {program} [OPTION]
 Usage: {program} [OPTION] [INPUTFILE]...
 conflicting flags conflicting plural forms error calling method '{method}' with value '{value}' on Locale::PO instance: {error}.
 error reading '{filename}': {error}!
 no input file given warning: '{from_code}' is not a valid encoding name.  Using ASCII as fallback. {new_ref}: conflicts with ...
{old_ref}: {msg}
 {package} is an abstract base class and must not be instantiated directly {program_name}: {error}
 {program} (Locale-XGettext) {version}
Copyright (C) {years} Cantanea EOOD (http://www.cantanea.com/).
License LGPLv3+: GNU Lesser General Public Licence version 3 
or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
 {program} ({package}) {version}
Please see the source for copyright information!
 {reference}: invalid multibyte sequence
 {reference}: {conversion_error}
 Project-Id-Version: Locale-XGettext 0.1
Report-Msgid-Bugs-To: guido.flohr@cantanea.com
POT-Creation-Date: 2017-12-31 09:07+0200
PO-Revision-Date: 2017-08-23 18:12+0200
Last-Translator: Guido Flohr <guido.flohr@cantanea.com>
Language-Team: Guido Flohr <guido.flohr@cantanea.com>
Language: de
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=(n != 1);
X-Generator: Poedit 2.0.1
       --copyright-holder=KETTE   Uhrheberrechtsinhaber in Ausgabe setzen
       --force-po              PO-Datei erstellen, auch wenn sie leer ist
       --foreign-user          keine Zeile mit FSF-Copyright in Ausgabe
                               einfügen
       --from-code=NAME        Kodierung für die Eingabe
       --msgid-bugs-address=EMAIL@ADRESSE  Adresse für msgid-Fehler angeben
       --no-location           Zeilen mit „#: Datei:Zeilennr.“ nicht schreiben
       --omit-header            „msgid ""“-Eintrag im Kopfteil nicht erstellen
       --package-name=PAKET    Paketname für die Ausgabe setzen
       --package-version=VERSION  Paketversion in Ausgabe setzen
   -D, --directory=VERZ        VERZ der Liste der Eingabedateien hinzufügen
   -F, --sort-by-file          Ausgabe gemäß Vorkommen in Dateien erstellen
   -M[ZEICHENKETTE], --msgstr-suffix[=ZEICHENKETTE]
                                ZEICHENKETTE oder "" als Suffix für msgstr
                                 nehmen
   -V, --version                Versionsnummer anzeigen und beenden
   -a, --extract-all          alle Zeichenketten extrahieren
   -cKENNUNG, --add-comments=KENNUNG
                              Kommentare, die mit KENNUNG beginnen und welche
                               einer Zeile mit Schlüsselworten vorausgehen in
                               die Ausgabedatei schreiben.
  -c, --add-comments          Alle Kommentarblöcke, die einer Zeile mit
                               Schlüsselworten vorausgehen, in die
                               Ausgabedatei schreiben.
   -d, --default-domain=NAME   Ausgabe in NAME.po (anstatt in messages.po)
   -f, --files-from=DATEI      Namen der Eingabedateien aus DATEI holen
   -h, --help                   diese Hilfe anzeigen und beenden
   -j, --join-existing         Meldungen an existierende Datei anhängen
   -kWORD, --keyword=WORD      zusätzliches Schlüsselwort, nach dem gesucht
                                wird.
  -k, --keyword               
      --flag=WORT:ARG:FLAG    zusätzliches Flag für Zeichenketten innerhalb der
                                Argumentzahl ARG des Schlüsselworts WORT
   -m[ZEICHENKETTE], --msgstr-prefix[=ZEICHENKETTE]
                                ZEICHENKETTE oder "" als Präfix für msgstr
                                 nehmen
   -n, --add-location          Zeilen mit „#: Datei:Zeilennr.“ erhalten (Vorgabe)
   -o, --output=DATEI          Ausgabe in die angegebene DATEI schreiben
   -p, --output-dir=VERZ       Ausgabedateien in Verzeichnis VERZ ablegen
   -s, --sort-output           sortierte Ausgabe erstellen
   -x, --exclude-file=DATEI.po Einträge aus DATEI.po nicht herausholen
   EINGABEDATEI...             Eingabedateien
 „--join-existing“ kann nicht benutzt werden, wenn nach Standardausgabe
geschrieben wird Ein --flag-Argument folgt nicht der <keyword>:<argnum>:[pass-]<flag>-Syntax: {flag} Fehler, Einträge vor Aufruf der Methode run() zuzufügen Versuch, die Ausgabe des Extrahierers zu starten, bevor run() aufgerufen wurde Versuch, den Extrahierer erneut zu starten Die Vorgabe ist, dass für Eingabedateien ASCII angenommen wird.
 Fehler beim Öffnen der Datei  „{file}“: {error}!
 Fehler beim Lesen von „{filename}“: {error}!
 Fehler beim Auflösen des Dateinamens  „{filename}“: {error}!
 Fehler beim Schreiben der Datei  „{file}“: {error}!
 Aus den Eingabedateien die zu übersetzenden Meldungen herausschreiben.
 Zu übersetzenden Meldungen herausschreiben.
 Wenn die Eingabedatei „-“ ist, wird die Standardeingabe gelesen.
 Ergebnisse werden nach der Standardausgabe geschrieben, wenn „-“ angegeben ist.
 Informative Ausgabe:
 Überprüfung der Eingabedatei:
 Angaben zu Eingabedateien:
 Eingabedateien werden als einfache Textdateien ausgewertet, wobei jeder
Absatz zu einer separaten Übersetzungseinheit wird.
 Unzulässige Argumentspezifikation „{spec}“ für die Funktion „{function}“!
 Besondere Optionen bei „Language“:
 Notwendige Argumente für Optionen in Langform sind auch für die Kurzform
notwendig. Dies gilt in gleicher Weise für optionale Argumente.
 Mehrere automatische Kommentare für Funktion „{function}“!
 Mehrere Kontextargumente für Funktion  „{function}“!
 Mehrere Bedeutungen für Argument #{num} für Funktion „{function}“!
 Keine PO-Daten {reference}: Nicht-ASCII-String.
  Bitte die Kodierung des Quelltextes mit „--from-code“ angeben!
 Art der Verarbeitung:
 Die Option  „--add-location“ muss eine Array-Referenz sein.
 Details zur Ausgabe:
 Angaben zu Ausgabedateien:
 Fehler bitte an <{URL}> melden!
 Das Argument für „--add-location“ must entweder „full“, „file“ oder „never“ lauten!
 Zu viele Formen für Funktion „{function}“!
 „{program_name} --help“ gibt weitere Informationen.
 Aufruf: {program} [OPTION]
 Aufruf: {program} [OPTION] [EINGABEDATEI]...
 in Konflikt stehende Flags in Konflikt stehende Pluralformen Fehler beim Aufruf der Methode „{method}“ mit dem Wert „{value}“ für eine Instanz von Locale::PO: {error}.
 Fehler beim Lesen der Datei  „{filename}“: {error}!
 Eingabedatei fehlt  „{from_code}“ ist kein gültiger Name für eine Zeichenkodierung. ASCII wird ersatzweise verwendet. {new_ref}: steht in Konflikt mit ...
{old_ref}: {msg}
 „{package}“ ist eine abstrakte Basisklasse und kann nicht direkt instantiiert werden {program_name}: {error}
 {program} (Locale-XGettext) {version}
Copyright (C) {years} Cantanea EOOD (http://www.cantanea.com/).
License LGPLv3+: GNU Lesser General Public Licence version 3 
oder neuer <http://gnu.org/licenses/gpl.html>.
Dies ist freie Software: es sterht Ihnen frei, sie zu verändern und weiterzugeben.
Es gibt KEINE GARANTIE, soweit gesetzlich zulässig.
Geschrieben von Guido Flohr (http://www.guido-flohr.net/).
 {program} ({package}) {version}
Lesen Sie den Quelltext für Urherberrechts-Informationen!
 {reference}: Ungültige Multibyte-Sequenz
 {reference}: {conversion_error}
 