# Using Locale::XGettext From Other Programming Languages

In this subdirectory you will find implementations of a very simple
string extractor in a number of languages.  The extractor will split
its input into lines and make every non-empty line into a PO entry.

The examples all use the "Inline" Perl module that allows to embed
code written in other languages directly into Perl code.

In order to use the example scanners you usually have to do the following:

    sudo cpan install Inline::LANGUAGE
    perl -Ilib samples/LANGUAGE/xgettext-lines.pl --help
    perl -Ilib samples/LANGUAGE/xgettext-lines.pl README.md

Replace LANGUAGE with the language you want to test.  In the case of
Java you have to run the command "sudo cpan install Inline::Java::Class"
(not just "Inline::Java").

# Walk-through example for Python

Let's look at a step-by-step instruction for writing an xgettext
program in Python.  The source code for the sample implementations for
other languages will give you enough information to modify the example
for your own needs.

## Installation of Inline::Python

We need the module that allows calling Python from Perl (and vice
versa):

    $ sudo cpan install Inline::Python

This will install "Inline::Python".

## Implementation with a separate module

The `Python` subdirectory contains a script `xgettext-lines.pl` and a
Python module `PythonGettext.py`.

The Perl script can be used without modification for any extractor that
you want to write in Python.  It will turn every method it finds in
`PythongGettext.py` into a Perl method.  See
[Locale::XGettext(3pm)](http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/TextDomain.pm)
for details about the methods you can implement.

## Minimal Implementation

The minimal implementation in `PythonGettext.py` will look like this:

    class PythonXGettext:
        def __init__(self, xgettext):
            self.xgettext = xgettext

The constructor is called with the instance of the Perl in the variable
`xgettext`.  Note that the Perl object is not initialzed at this point and
you should not call any methods of it.

Your extractor is already almost functional:

    $ ./xgettext-lines.pl --help
    Usage: xgettext-lines.pl [OPTION] [INPUTFILE]...
    ...

It already prints out usage information.  If you see an error message "Can't
locate Locale/XGettext.pm in @INC ..." instead, you haven't installed the
Perl module.  Either install it or tell the sample script to use the
source instead:


    $ perl -I../../lib xgettext-lines.pl --help
    Usage: xgettext-lines.pl [OPTION] [INPUTFILE]...

You can see that the Python code was really executed by the presence of a
directory `_Inline` which contains cached information from `Inline::Python`.
You can safely delete this directory at any point in time.

Now let's try our extractor with a real input file, for example the one that
you are currently reading:

    $ ./xgettext-lines.pl ../README.md
    Can't locate object method "readFile" via package "Locale::XGettext::Python" at ../../lib/Locale/XGettext.pm line 184.

The method `readFile` gets called for every input file and has to be 
implemented.  Let's add it to `PythonGettext.py`:

        def readFile(self, filename):
        with open(filename) as f:
            for line in f:
                self.xgettext.addEntry({'msgid': line})

Now try it again:

    $ ./xgettext-lines.pl ../README.md

