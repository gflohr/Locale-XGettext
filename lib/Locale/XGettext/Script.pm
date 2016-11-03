#! /bin/false

# Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

package Locale::XGettext::Script;

use strict;

use base 'Exporter';
use vars qw(@EXPORT $VERSION);
@EXPORT = qw($VERSION);
$VERSION = '0.1.1';

use Locale::TextDomain qw(Locale-XGettext);
use Getopt::Long qw(GetOptionsFromArray);

use Locale::XGettext::Keyword;

use base qw(Locale::XGettext);

sub new {
    my ($class, $argv) = @_;

    my $self = {};
    bless $self, $class;
    my %options = $self->__getOptions($argv);
    
    $self->__displayUsage if $options{help};
    $self->__displayVersion if $options{version};
    
    $options{keyword} = $self->__setKeywords($options{keyword});

    return $class->SUPER::new(\%options, @$argv);
}

sub run {
	my ($self) = @_;
	
	eval { $self->SUPER::run() };
	if ($@) {
		chomp $@;
	    die "$0: $@\n";
	}
	
	return $self;
}

sub output {
	my ($self) = @_;

    eval { $self->SUPER::output() };
    if ($@) {
        chomp $@;
        die "$0: $@\n";
    }
    
    return $self;
}

sub __getOptions {
    my ($self, $argv) = @_;
    
    my %options;
    
    Getopt::Long::Configure('bundling');
    GetOptionsFromArray($argv,
        # Input file location:
        'f|files-from=s@' => \$options{files_from},
        'D|directory=s@' => \$options{directory},

        # Output file location:
        'd|default-domain=s' => \$options{default_domain},
        'o|output=s' => \$options{output},
        'p|output-dir=s' => \$options{output_dir},

        # Input file interpretation.
        'from-code=s' => \$options{from_code},
       
        # Operation mode:
        'j|join-existing' => \$options{join_existing},
        # FIXME! Is this allowed multiple times?
        'x|exclude-file=s' => \$options{exclude_file},
        'c|add-comments:s@' => \$options{add_comments},
        'check=s@' => \$options{check},
        'sentence_end=s' => \$options{sentence_end},

        # Language specific options:
        'a|extract-all' => \$options{extract_all},
        'k|keyword:s@' => \$options{keyword},
         
        # Output details:
        'force-po' => \$options{force_po},
        'no-location' => \$options{no_location},
        'n|add-location' => \$options{add_location},
        's|sort-output' => \$options{sort_output},
        'F|sort-by-file' => \$options{sort_by_file},
        'omit-header' => \$options{omit_header},
        'copyright-holder=s' => \$options{copyright_holder},
        'foreign-user' => \$options{foreign_user},
        'package_name=s' => \$options{package_name},
        'package_version=s' => \$options{package_version},
        'msgid-bugs-address=s' => \$options{msgid_bugs_address},
        'm|msgstr-prefix:s' => \$options{msgid_str_prefix},
        'M|msgstr-suffix:s' => \$options{msgid_str_suffix},

        # Informative output.
        'h|help' => \$options{help},
        'V|version' => \$options{version},
    ) or exit 1;
    
    foreach my $key (keys %options) {
    	delete $options{$key} if !defined $options{$key};
    }
    
    return %options;   
}

sub __setKeywords {
    my ($self, $options) = @_;
    
    my %keywords = Locale::XGettext->defaultKeywords;
    while (my ($method, $argspec) = each %keywords) {
    	$keywords{$method} = Locale::XGettext::Keyword->new($method, @$argspec);
    }
    my %keywords;
    
    foreach my $option (@$options) {
    	if ('' eq $option) {
    	    undef %keywords;
    	    next;
    	}

        my $keyword = Locale::XGettext::Keyword->newFromString($option);
        $keywords{$keyword->method} = $keyword;
    }

    return \%keywords;
}

sub __displayUsage {
    print __x("Usage: {program} [OPTION] [INPUTFILE]...\n", program => $0);
    
    print "\n";
    
    print __(<<EOF);
Extract translatable strings from given input files.  
EOF
    print __(<<EOF);
Input files are interpreted as Template Toolkit version 2 templates.  
EOF

    print "\n";
    
    print __(<<EOF);
Mandatory arguments to long options are mandatory for short options too.
Similarly for optional arguments.
EOF

    print "\n";

    print __(<<EOF);
Input file location:
EOF

    print __(<<EOF);
  INPUTFILE ...               input files
EOF

    print __(<<EOF);
  -f, --files-from=FILE       get list of input files from FILE\
EOF

    print __(<<EOF);
  -D, --directory=DIRECTORY   add DIRECTORY to list for input files search
EOF

    printf __(<<EOF);
If input file is -, standard input is read.
EOF

    print "\n";

    printf __(<<EOF);
Output file location:
EOF

    printf __(<<EOF);
  -d, --default-domain=NAME   use NAME.po for output (instead of messages.po)
EOF

    print __(<<EOF);
  -o, --output=FILE           write output to specified file
EOF

    print __(<<EOF);
  -p, --output-dir=DIR        output files will be placed in directory DIR
EOF

    print __(<<EOF);
If output file is -, output is written to standard output.
EOF

    print "\n";

    print __(<<EOF);
Input file interpretation:
EOF

    print __(<<EOF);
      --from-code=NAME        encoding of input files
EOF
    print __(<<EOF);
By default the input files are assumed to be in ASCII.
EOF

    printf "\n";

    print __(<<EOF);
Operation mode:
EOF

    print __(<<EOF);
  -j, --join-existing         join messages with existing file
EOF

    print __(<<EOF);
  -x, --exclude-file=FILE.po  entries from FILE.po are not extracted
EOF

    print __(<<EOF);
  -cTAG, --add-comments=TAG   place comment blocks starting with TAG and
                                preceding keyword lines in output file
  -c, --add-comments          place all comment blocks preceding keyword lines
                                in output file
EOF

    print __(<<EOF);
      --check=NAME            perform syntax check on messages
                                (ellipsis-unicode, space-ellipsis,
                                 quote-unicode, bullet-unicode)
EOF
    print __(<<EOF);
      --sentence-end=TYPE     type describing the end of sentence
                                (single-space, which is the default,
                                 or double-space)
EOF

    print "\n";

    print __(<<EOF);
Language specific options:
EOF

    print __(<<EOF);
  -a, --extract-all           extract all strings
EOF

    print __(<<EOF);
  -kWORD, --keyword=WORD      look for WORD as an additional keyword
  -k, --keyword               do not to use default keywords"));
EOF

    # FIXME! Other plug-in name? Or combine it with the keywords, like
    # --keyword=Maketext.blabla?

    print "\n";

    print __(<<EOF);
Output details:
EOF

    print __(<<EOF);
      --force-po              write PO file even if empty
EOF

    print __(<<EOF);
      --no-location           do not write '#: filename:line' lines
EOF

    print __(<<EOF);
  -n, --add-location          generate '#: filename:line' lines (default)
EOF

    print __(<<EOF);
  -s, --sort-output           generate sorted output
EOF

    print __(<<EOF);
  -F, --sort-by-file          sort output by file location
EOF

    print __(<<EOF);
      --omit-header           don't write header with 'msgid ""' entry
EOF

    print __(<<EOF);
      --copyright-holder=STRING  set copyright holder in output
EOF

    print __(<<EOF);
      --foreign-user          omit FSF copyright in output for foreign user
EOF

    print __(<<EOF);
      --package-name=PACKAGE  set package name in output
EOF

    print __(<<EOF);
      --package-version=VERSION  set package version in output
EOF

    print __(<<EOF);
      --msgid-bugs-address=EMAIL\@ADDRESS  set report address for msgid bugs
EOF

    print __(<<EOF);
  -m[STRING], --msgstr-prefix[=STRING]  use STRING or "" as prefix for msgstr
                                values
EOF

    print __(<<EOF);
  -M[STRING], --msgstr-suffix[=STRING]  use STRING or "" as suffix for msgstr
                                values
EOF

    printf "\n";

    print __(<<EOF);
Informative output:
EOF

    print __(<<EOF);
  -h, --help                  display this help and exit
EOF

    print __(<<EOF);
  -V, --version               output version information and exit
EOF

    printf "\n";

    # TRANSLATORS: The placeholder indicates the bug-reporting address
    # for this package.  Please add _another line_ saying
    # "Report translation bugs to <...>\n" with the address for translation
    # bugs (typically your translation team's web or email address).
    print __"Report bugs at <https://github.com/gflohr/template-plugin-gettext/issues>!\n";

    exit 0;
}

sub __usageError {
    my $message = shift;
    if ($message) {
        $message =~ s/\s+$//;
        $message = "$0: $message\n";
    }
    else {
        $message = '';
    }
    die <<EOF;
${message}Usage: $0 [OPTIONS]
Try '$0 --help' for more information!
EOF
}

sub __displayVersion {
    my $msg = __x('{program} (Template-Plugin-Gettext) {version}
Copyright (C) {years} Cantanea EOOD (http://www.cantanea.com/).
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
', program => $0, years => 2016, version => $Locale::XGettext::TT2::VERSION);

    print $msg;

    exit 0;
}

1;
