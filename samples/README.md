# Using Locale::XGettext From Other Programming Languages

In this subdirectory you will find implementations of a very simple
string extractor in a number of languages.  The extractor will split
its input into lines and make every line not containing only whitespace
into a PO entry.

The examples all use the "Inline" Perl module that allows to embed
code written in other languages directly into Perl code.

In order to use the example scanners you usually have to do the following:

    sudo cpan install Inline::LANGUAGE
    perl -Ilib samples/LANGUAGE/xgettext-lines.pl --help
    perl -Ilib samples/LANGUAGE/xgettext-lines.pl README.md

Replace LANGUAGE with the language you want to test.  In the case of
Java you have to run the command "sudo cpan install Inline::Java::Class"
(not just "Inline::Java").
