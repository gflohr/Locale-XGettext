# Locale-XGettext

Extract strings from arbitrary formats into PO files

## Description

When using 
[GNU gettext](https://www.gnu.org/software/gettext/)
you often find yourself extracting translatable
strings from more or less exotic file formats that cannot be handled
by xgettext from the
[GNU gettext](https://www.gnu.org/software/gettext/)
suite directly.  This package simplifies
the task of writing a string extractor in Perl, Python, Java, Ruby or
other languages by providing a common base needed for such scripts.

## Usage

Included is a sample string extractor for plain text files.  It simply
splits the input into paragraphs, and turns each paragraph into an
entry of a PO file.

## Common Workflow

The idea of the package is that you just a write a parser plug-in for
Locale::XGettext and use all the boilerplate code for generating the
PO file and for processing script options from this library.  One such
example is a parser plug-in for strings in templates for the
Template Toolkit version 2 included in the package 
[Template-Plugin-Gettext](https://github.com/gflohr/Template-Plugin-Gettext).
that contains a script `xgettext-tt2` which can only extract
strings from this particular template language.

If this is the only source of translatable strings you are mostly done.
Often times you will, however, have to merge strings from all different
input formats into one single PO file.  Let's assume that your project
is written in Perl and C and that it also contains Template Toolkit
templates and plain text files that have to be translated.

1. Use `xgettext-txt` from this package to extract strings from all
   plain text files and write the output into `text.pot`.

2. Use `xgettext-tt2` from 
   [Template-Plugin-Gettext](https://github.com/gflohr/Template-Plugin-Gettext)
   to extract all strings
   from your templates into another file `templates.pot`.

3. Finally use `xgettext` from
   [GNU gettext](https://www.gnu.org/software/gettext/)
   for extracting strings from
   all source files written in Perl and C, _and_ from the previously
   created pot files `text.pot` and `templates.pot`.  This works
   because `xgettext` natively understands `.po` resp. `.pot` files.
 
By the way, all xgettext flavors based on this library `Locale::XGettext`
are also able to extract strings from `.po` or `.pot` files.  So you
can also make do completely without GNU gettext as far as string
extraction is concerned.

