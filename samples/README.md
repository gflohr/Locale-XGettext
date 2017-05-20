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

This time nothing should happen.  Don't worry, no news is good news.  A file
`messages.po` was created with one PO entry per line.

The other good news is: You're done! At least in many cases, this is already
sufficient and you can now focus on writing a real parser for your source
files.

## Implementation in one single file

The Perl wrapper script `xgettext-lines.pl` reads the python codde from a 
separate file, the Python module `PythonXGettext.py` so that the two 
languages are separated cleanly.  The script `xgettext-lines.py` shows 
another approach.  It still contains Perl code at the top but the Python
code is added to the bottom.  The overall layout of the script looks like
this:

    #! /usr/bin/env perl
    
    # Boilerplate Perl code.
    # ...
    
    use Inline Python => 'DATA'
    
    # More boilerplate Perl code.
    # ...
    
    __DATA__
    __Python__

    class PythonXGettext:
        def __init__(self, xgettext):
            self.xgettext = xgettext
    
        def readFile(self, filename):
            with open(filename) as f:
                for line in f:
                    # You don't have to check that the line is empty.  The
                    # PO header gets added after input has been processed.
                    self.xgettext.addEntry({'msgid': line});

The line `use Inline Python => 'DATA'` has the effect that Perl, resp.
the Inline module will look for the Python code to compile at the end of
the file, after two lines containing the special markers `__DATA__` and
`__Python__` (or `__Ruby__`, or `__Java__` for other programming
languages).

Instead of `__DATA__` you can also use `__END__`.  It has the same effect
in this particular case.

The script works standalone, without a separate Python module:

    $ ./xgettext-lines.py
    ./xgettext-lines.py: no input file given
    Try './xgettext-lines.py --help' for more information!

If `Locale::XGettext` is not yet installed, you have to specify the path
to the Perl library:

    $ perl -I../../lib xgettext-lines.py
    ./xgettext-lines.py: no input file given
    Try './xgettext-lines.py --help' for more information!

Whether you want to mix Perl and Python in one file, or keep them separate
- as described above - is a matter of taste.

## Reading Strings From Other Data Sources

Sometimes you want to read strings from another data source that is not
a file.  One option is to simply interpret the command-line arguments not
as filenames but as identifiers for your data sources, for example
URLs, and then change the method `readFile()` to read from that data
source.

Another option is to override the method `extractFromNonFiles`.  This
method is invoked after all input files have been but before the output
is created:

    def extractFromNonFiles(self):
        # Read, for example from a database.
        for string in database_records:
            self.xgettext.addEntry({'msgid': line})

## Extending the CLI

When you run your extractor script with the option `--help` you see a lot
of usage information from `Locale::XGettext`.  The API allows you to modify 
the command line interface of your extractor to a certain degree.

### Describing the Expected Input

If you implement the method fileInformation() you can describe the type
of your input files.

    def fileInformation(self):
        return "Input files are plain text files and are converted into one PO entry\nfor every non-empty line."

Look at the usage information:

    $ ./xgettext-lines.pl --help
    Usage: ./xgettext-lines.pl [OPTION] [INPUTFILE]...
    
    Extract translatable strings from given input files.  
    
    Input files are plain text files and are converted into one PO entry
    for every non-empty line.

    ...

Your description is now printed after the generic usage information.

### Language-specific Options

In order to add your own command-line options you have to override the method
`getLanguageSpecificOptions`.  See this example:

    def getLanguageSpecificOptions(self, options = None):
        return [
                   [
                       'test-binding',
                       'test_binding',
                       '    --test-binding',
                       'print additional information for testing the language binding'
                   ]
        ];

Additional commandline options are defined as an array of arrays.  Each
definition has four elements:

The first element (`'test-binding'`) contains the option specification.
The default are binary options that do not take arguments.  For a string
argument you would use `'test-binding=s'`, for an integer argument
`'test-binding=i'`.  For a complete description please see
[http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm](http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm).

