# Plugin-XGettext

Extract strings into PO files with Perl

## Status

Pre-alpha, incomplete.

## Description

When using GNU gettext you often find yourself extracting translatable
strings from more or less exotic file formats that cannot be handled
by xgettext from the GNU gettext suite directly.  This package simplifies
the task of writing a string extractor in Perl by providing a common
base needed for such scripts.

## Usage

Included is a sample string extractor for plain text files.  It simply
splits the input into paragraphs, and turns each paragraph into an en
entry of a PO file.
