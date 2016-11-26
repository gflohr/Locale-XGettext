#! /bin/false
# vim: ts=4:et

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

package Locale::XGettext;

use strict;

our $VERSION = '0.1';

use Locale::TextDomain qw(Locale-XGettext);
use File::Spec;
use Locale::PO 0.27;
use Scalar::Util qw(reftype);
use Locale::Recode;
use Getopt::Long qw(GetOptionsFromArray);

use Locale::XGettext::Util::POEntries;
use Locale::XGettext::Util::Keyword;

sub empty($) {
    my ($what) = @_;

    return if defined $what && length $what;

    return 1;
}

sub new {
    my ($class, $options, @files) = @_;

    my $self = ref $class ? $class : {};
    
    $self->{__options} = $options;
    $self->{__comment_tag} = undef;
    $self->{__files} = [@files];
    
    bless $self, $class;

    if (__PACKAGE__ eq ref $self) {
    	require Carp;
    	Carp::croak(__x("{package} is an abstract base class and must not"
    	                . " be instantiated directly",
    	                package => __PACKAGE__));
    }
    
    $options->{default_domain} = 'messages' if empty $options->{default_domain};
    $options->{from_code} = 'ASCII' if empty $options->{default_domain};
    $options->{output_dir} = '.' if empty $options->{output_dir};

    if (exists $options->{add_location}) {
        my $option = $options->{add_location};
        if (empty $option) {
            $option = 'full';
        }
        die __"The argument to '--add-location' must be 'full', 'file', or 'never'.\n"
            if $option ne 'full' && $option ne 'file' && $option ne 'never';
    }

    if (exists $options->{check}) {
        my $option = $options->{check};

        die __x("Syntax check '{type}' unknown.\n", type => $option)
            if $option ne 'ellipsis-unicode'
               && $option ne 'space-ellipsis'
               && $option ne 'quote-unicode'
               && $option ne 'bullet-unicode';
    }

    if (exists $options->{sentence_end}) {
        my $option = $options->{sentence_end};

        die __x("Sentence end type '{type}' unknown.\n", type => $option)
            if $option ne 'single-space'
               && $option ne 'double-space';
    }
    
    if (exists $options->{add_comments}) {
        if (!ref $options->{add_comments} 
            && 'ARRAY' ne $options->{add_comments}) {
        	die __"Option 'add_comments' must be an array reference.\n";
        }
        
        foreach my $comment (@{$options->{add_comments}}) {
        	$comment =~ s/^[ \t\n\f\r\013]+//;
        	$comment = quotemeta $comment;
        }
    }
    
    $options->{from_code} = 'ASCII' if empty $options->{from_code};

    my $from_code = $options->{from_code};
    my $cd = Locale::Recode->new(from => $from_code,
                                 to => 'utf-8');
    if ($cd->getError) {        
        warn __x("warning: '{from_code}' is not a valid encoding name.  "
                 . "Using ASCII as fallback.",
                 from_code => $from_code);
        $options->{from_code} = 'ASCII';
    } else {
        $options->{from_code} = 
            Locale::Recode->resolveAlias($options->{from_code});
    }
    
    $self->__readFilesFrom($options->{files_from});
    if ($self->needInputFiles) {
        $self->__usageError(__"no input file given") if !@{$self->{__files}};
    }
    
    $options->{keyword} = $self->__setKeywords($options->{keyword});
    $options->{flag} = $self->__setFlags($options->{flags});

    # TODO: Read exclusion file for --exclude-file.

    return $self;
}

sub newFromArgv {
	my ($class, $argv) = @_;

    my $self = {};
    bless $self, $class;

    my %options = eval { $self->__getOptions($argv) };
    if ($@) {
    	$self->__usageError($@);
    }
    
    $self->__displayUsage if $options{help};
    
    if ($options{version}) {
        print $self->versionInformation;
        exit 0;
    }
    
    return $class->new(\%options, @$argv);
}

sub defaultKeywords {
    return;
}

sub defaultFlags {
	return;
}

sub run {
    my ($self) = @_;

    if ($self->{__run}++) {
        require Carp;
        Carp::croak(__"Attempt to re-run extractor");
    }

    my $po = $self->{__po} = Locale::XGettext::Util::POEntries->new;
    foreach my $filename (@{$self->{__files}}) {
        my $path = $self->resolveFilename($filename)
            or die __x("Error resolving '{filename}': {error}!\n",
                       filename => $filename, error => $!);
        if ($path =~ /\.pot?$/i) {
            $self->readPO($path);
        } else {
        	$self->readFile($path);
        }
    }

    $self->extractFromNonFiles;
    
    # FIXME! Sort po!
    
    if (($po->entries || $self->{__options}->{force_po})
        && !$self->{__options}->{omit_header}) {
        $po->prepend($self->__poHeader);
    }

    return $self;
}

sub extractFromNonFiles { shift }

sub readPO {
	my ($self, $path) = @_;
	
	my $entries = Locale::PO->load_file_asarray($path)
	    or die __x("error reading '{filename}': {error}!\n",
	               filename => $path, error => $!);
	
	foreach my $entry (@$entries) {
		if ('""' eq $entry->msgid
		    && empty $entry->dequote($entry->msgctxt)) {
			next;
		}
		$self->addEntry($entry);
	}
	
	return $self;
}

sub addEntry {
	my ($self, $entry) = @_;
	
	if (!$self->{__run}) {
        require Carp;
        Carp::croak(__"Attempt to add entries before run");
    }
	
	$self->{__po}->add($entry);
}

sub recodeEntry {
	my ($self, $entry) = @_;
	
	my $from_code = $self->{__options}->{from_code};
    $from_code = Locale::Recode->resolveAlias($from_code);
    
    my $cd;
    if ($from_code ne 'US-ASCII' && $from_code ne 'UTF-8') {
        $cd = Locale::Recode->new(from => $from_code, to => 'utf-8');
        die $cd->getError if defined $cd->getError;
    }

    my $toString = sub {
        my ($entry) = @_;

        return join '', map { defined $_ ? $_ : '' }
            $entry->msgid, $entry->msgid_plural, 
            $entry->msgctxt, $entry->comment;
    };
    
    if ($from_code eq 'US-ASCII') {        
        # Check that everything is 7 bit.
        my $flesh = $toString->($entry);
        if ($flesh !~ /^[\000-\177]*$/) {
            die __x("Non-ASCII string at {reference}.\n"
                    . "    Please specify the source encoding through "
                    . "--from-code.\n",
                    reference => $entry->reference);
        }
    } elsif ($from_code eq 'UTF-8') {
        # Check that utf-8 is valid.
        require utf8; # [SIC!]
        
        my $flesh = $toString->($entry);
        if (!utf8::valid($flesh)) {
            die __x("{reference}: invalid multibyte sequence\n",
                    reference => $entry->reference);
        }
    } else {
        # Convert.
        my $msgid = Locale::PO->dequote($entry->msgid);
        if (!empty $msgid) {
            $cd->recode($msgid) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgid($msgid);
        }
        
        my $msgid_plural = Locale::PO->dequote($entry->msgid_plural);
        if (!empty $msgid_plural) {
            $cd->recode($msgid_plural) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgid($msgid_plural);
        }
        
        my $msgstr = Locale::PO->dequote($entry->msgstr);
        if (!empty $msgstr) {
            $cd->recode($msgstr) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgid($msgstr);
        }
        
        my $msgstr_n = Locale::PO->dequote($entry->msgstr_n);
        if ($msgstr_n) {
            my $msgstr_0 = Locale::PO->dequote($msgstr_n->{0});
            $cd->recode($msgstr_0) 
                or $self->__conversionError($entry->reference, $cd);
            my $msgstr_1 = Locale::PO->dequote($msgstr_n->{1});
            $cd->recode($msgstr_1) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgstr_n({
                0 => $msgstr_0,
                1 => $msgstr_1,
            })
        }
        
        my $comment = $entry->comment;
        $cd->recode($comment) 
            or $self->__conversionError($entry->reference, $cd);
        $entry->comment($comment);
    }

    return $self;    	
}

sub __conversionError {
    my ($self, $reference, $cd) = @_;
    
    die __x("{reference}: {conversion_error}\n",
            reference => $reference,
            conversion_error => $cd->getError);
}

sub resolveFilename {
    my ($self, $filename) = @_;
    
    my $directories = $self->{__options}->{directory} || [''];
    foreach my $directory (@$directories) {
    	my $path = length $directory 
    	    ? File::Spec->catfile($directory, $filename) : $filename;
    	stat $path && return $path;
    }
    
    return;
}

sub po {
    shift->{__po}->entries;
}

sub output {
    my ($self) = @_;
    
    if (!$self->{__run}) {
        require Carp;
        Carp::croak(__"Attempt to output from extractor before run");
    }
    
    if (!$self->{__po}) {
        require Carp;
        Carp::croak(__"No PO data");
    }
    
    return if !$self->{__po}->entries && !$self->{__options}->{force_po};

    my $options = $self->{__options};
    my $filename;
    if (exists $options->{output}) {
        if (File::Spec->file_name_is_absolute($options->{output})
            || '-' eq $options->{output}) {
            $filename = $options->{output};	
        } else {
        	$filename = File::Spec->catfile($options->{output_dir},
        	                                $options->{output})
        }
    } elsif ('-' eq $options->{default_domain}) {
        $filename = '-';
    } else {
        $filename = File::Spec->catfile($options->{output_dir}, 
                                        $options->{default_domain} . '.po');
    }
    
    open my $fh, ">$filename"
        or die __x("Error writing '{file}': {error}.\n",
                   file => $filename, error => $!);
    
    foreach my $entry ($self->{__po}->entries) {
        print $fh $entry->dump
            or die __x("Error writing '{file}': {error}.\n",
                       file => $filename, error => $!);
    }
    close $fh
        or die __x("Error writing '{file}': {error}.\n",
                   file => $filename, error => $!);
    
    return $self;
}

sub options {
	shift->{__options};
}

sub __poHeader {
    my ($self) = @_;

    my $options = $self->{__options};
    
    my $user_info;
    if ($options->{foreign_user}) {
        $user_info = <<EOF;
This file is put in the public domain.
EOF
    } else {
        my $copyright = $options->{copyright_holder};
        $copyright = "THE PACKAGE'S COPYRIGHT HOLDER" if !defined $copyright;
        
        $user_info = <<EOF;
Copyright (C) YEAR $copyright
This file is distributed under the same license as the PACKAGE package.
EOF
    }
    chomp $user_info;
    
    my $entry = Locale::PO->new;
    $entry->fuzzy(1);
    $entry->comment(<<EOF);
SOME DESCRIPTIVE TITLE.
$user_info
FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR.
EOF
    $entry->msgid('');

    my @fields;
    
    my $package_name = $options->{package_name};
    if (defined $package_name) {
        my $package_version = $options->{package_version};
        $package_name .= ' ' . $package_version 
            if defined $package_version && length $package_version; 
    } else {
        $package_name = 'PACKAGE VERSION'
    }
    
    push @fields, "Project-Id-Version: $package_name";

    my $msgid_bugs_address = $options->{msgid_bugs_address};
    $msgid_bugs_address = '' if !defined $msgid_bugs_address;
    push @fields, "Report-Msgid-Bugs-To: $msgid_bugs_address";    
    
    push @fields, 'Last-Translator: FULL NAME <EMAIL@ADDRESS>';
    push @fields, 'Language-Team: LANGUAGE <LL@li.org>';
    push @fields, 'Language: ';
    push @fields, 'MIME-Version: ';
    # We always write utf-8.
    push @fields, 'Content-Type: text/plain; charset=UTF-8';
    push @fields, 'Content-Transfer-Encoding: 8bit';
    
    $entry->msgstr(join "\n", @fields);    
    return $entry;
}

sub __getEntriesFromFile {
    my ($self, $filename) = @_;

    open my $fh, "<$filename" 
        or die __x("Error reading '{filename}': {error}!\n",
                   filename => $filename, error => $!);
    
    my @entries;
    my $chunk = '';
    my $last_lineno = 1;
    while (my $line = <$fh>) {
        if ($line =~ /^[\x09-\x0d ]*$/) {
            if (length $chunk) {
                my $entry = Locale::PO->new;
                chomp $chunk;
                $entry->msgid($chunk);
                $entry->reference("$filename:$last_lineno");
                push @entries, $entry;
            }
            $last_lineno = $. + 1;
            $chunk = '';
        } else {
            $chunk .= $line;
        }
    }
    
    if (length $chunk) {
        my $entry = Locale::PO->new;
        $entry->msgid($chunk);
        chomp $chunk;
        $entry->reference("$filename:$last_lineno");
        push @entries, $entry;
    }

    return @entries;
}

sub __readFilesFrom {
    my ($self, $list) = @_;
    
    my %seen;
    my @files;
    foreach my $file (@{$self->{__files}}) {
        my $canonical = File::Spec->canonpath($file);
        push @files, $file if !$seen{$canonical}++;
    }
    
    # This matches the format expected by GNU xgettext.  Lines where the
    # first non-whitespace character is a hash sign, are ignored.  So are
    # empty lines (after whitespace stripping).  All other lines are treated
    # as filenames with trailing (not leading!) space stripped off.
    foreach my $potfile (@$list) {
        open my $fh, "<$potfile"
            or die __x("Error opening '{file}': {error}!\n",
                       file => $potfile, error => $!);
        while (my $file = <$fh>) {
            next if $file =~ /^[ \x09-\x0d]*#/;
            $file =~ s/[ \x09-\x0d]+$//;
            next if !length $file;
            
            my $canonical = File::Spec->canonpath($file);
            next if $seen{$canonical}++;

            push @files, $file;
        }
    }
    
    $self->{__files} = \@files;
    
    return $self;
}

sub scriptMode {
	my ($self, $mode) = @_;
	
	if (@_ > 1) {
		if ($mode) {
			$self->{__script_mode} = 1;
		} else {
			delete $self->{__script_mode};
		}
	}
	
	return $self if $self->{__script_mode};
	
	return;
}

sub __getOptions {
    my ($self, $argv) = @_;
    
    my %options;
    
    my $lang_options = $self->getLanguageSpecificOptions(\%options);
    my %lang_options;
    foreach my $optspec (@{$lang_options || []}) {
    	my ($optstring, $optvar,
    	    $usage, $description) = @$optspec;
        $lang_options{$optstring} = \$options{$optvar};
    }
    
    Getopt::Long::Configure('bundling');
    $SIG{__WARN__} = sub {
    	$SIG{__WARN__} = 'DEFAULT';
    	die shift;
    };
    GetOptionsFromArray($argv,
        # Are always overridden by standard options.
        %lang_options,
        
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
        'flag:s@' => \$options{flag},
         
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
    );
    $SIG{__WARN__} = 'DEFAULT';
    
    foreach my $key (keys %options) {
        delete $options{$key} if !defined $options{$key};
    }
    
    return %options;   
}

sub getLanguageSpecificOptions {}

sub printLanguageSpecificUsage {
    my ($self) = @_;
    
    my $options = $self->getLanguageSpecificOptions;
    
    foreach my $optspec (@{$options || []}) {
        my ($optstring, $optvar,
            $usage, $description) = @$optspec;
        
        print "  $usage ";
        my $pos = 3 + length $usage;
        
        my @description = split /[ \x09-\x0d]+/, $description;
        my $lineno = 0;
        while (@description) {
            my $limit = $lineno ? 31 : 29;
            if ($pos < $limit) {
                print ' ' x ($limit - $pos);
                $pos = $limit;
            }
            
            while (@description) {
                my $word = shift @description;
                print " $word";
                $pos += 1 + length $word;
                if (@description && $pos > 77 - length $word) {
                	++$lineno;
                	print "\n";
                	$pos = 0;
                	last;
                }
            }
        }
        print "\n";
    }
    
    return $self;
}

sub fileInformation {}

sub getBugTrackingAddress {}

sub __setKeywords {
    my ($self, $options) = @_;
    
    my %keywords = $self->defaultKeywords;
    while (my ($method, $argspec) = each %keywords) {
        $keywords{$method} = Locale::XGettext::Util::Keyword->new($method, 
                                                                  @$argspec);
    }
    
    foreach my $option (@$options) {
        if ('' eq $option) {
            undef %keywords;
            next;
        }

        my $keyword;
        if (ref $option) {
        	$keyword = $option;
        } else {
        	$keyword = Locale::XGettext::Util::Keyword->newFromString($option);
        }
        $keywords{$keyword->method} = $keyword;
    }

    return \%keywords;
}

sub __setFlags {
	
}

sub __displayUsage {
	my ($self) = @_;
	
    print __x("Usage: {program} [OPTION] [INPUTFILE]...\n", program => $0);
    print "\n";
    
    print __(<<EOF);
Extract translatable strings from given input files.  
EOF

    if (defined $self->fileInformation) {
    	print "\n";
    	print $self->fileInformation;
    }

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

    if ($self->canExtractAll) {
        print __(<<EOF);
  -a, --extract-all           extract all strings
EOF
    }

    if ($self->canKeywords) {
        print __(<<EOF);
  -kWORD, --keyword=WORD      look for WORD as an additional keyword
  -k, --keyword               do not to use default keywords"));
      --flag=WORD:ARG:FLAG    additional flag for strings inside the argument
                              number ARG of keyword WORD
EOF
    }

    $self->printLanguageSpecificUsage;

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

    my $url = $self->getBugTrackingAddress;

    printf "\n";

    if (defined $url) {
        # TRANSLATORS: The placeholder indicates the bug-reporting address
        # for this package.  Please add _another line_ saying
        # "Report translation bugs to <...>\n" with the address for translation
        # bugs (typically your translation team's web or email address).
        print __x("Report bugs at <{URL}>!\n", URL => $url);
    }

    exit 0;
}

sub __usageError {
	my ($self, $message) = @_;

    if ($message) {
        $message =~ s/\s+$//;
        $message = __x("{program_name}: {error}\n",
                       program_name => $0, error => $message);
    } else {
        $message = '';
    }
    
    die $message . __x("Try '{program_name} --help' for more information!\n",
                       program_name => $0);
}

sub versionInformation {
	my ($self) = @_;
	
	my $package = ref $self;
	
	my $version = eval { eval "$package::VERSION" };
	$version = '' if !defined $version;
	
    $package =~ s/::/-/g;
	
	return __x('{program} ({package}) {version}
Please see the source for copyright information!
', program => $0, package => $package, version => $version);
}

sub canExtractAll {
	return;
}

sub canKeywords {
	shift;
}

sub needInputFiles {
	shift;
}

1;

=head1 NAME

Locale::XGettext - Extract Strings To PO Files

=head1 SYNOPSIS

    use base 'Locale::XGettext';
    
=head1 DESCRIPTION

B<Locale::XGettext> is the base class for various string extractors.  These
string extractors can be used as standalone programs on the commandline or
as a module as a part of other software.

See L<https://github.com/gflohr/Locale-XGettext> for an overall picture of
the software.

=head1 USAGE

    xgettext-LANG [OPTIONS] [INPUTFILE]...

B<LANG> will be replaced by an identifier for the language that a specific
extractor was written for, for example "xgettext-txt" for plain text files
or "xgettext-tt2" for templates for the Template Toolkit version 2 (see
L<Template>).

By default, string extractors based on this module extract strings from
one or more B<INPUTFILES> and write the output to a file "messages.po" if
any strings had been found.  

=head1 OPTIONS

The command line options are mostly compatible to
F<xgettext> from L<GNU
Gettext|https://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html>.

=head2 INPUT FILE LOCATION

=over 4

=item B<INPUTFILE...>

All non-option arguments are interpreted as input files containing strings to
be extracted.  If the input file is "-", standard input is read.

=item B<-f FILE>

=item B<--files-from=FILE>

Read the names of the input files from B<FILE> instead of getting them from the
command line.

B<Note!> Unlike xgettext from GNU Gettext, extractors based on 
B<Locale::XGettext> accept this option multiple times, so that you can read 
the list of input files from multiple files.

=item B<-D DIRECTORY>

=item B<--directory=DIRECTORY>

Add B<DIRECTORY> to the list of directories. Source files are searched 
relative to this list of directories. The resulting .po file will be written 
relative to the current directory, though. 

=back

=head2 OUTPUT FILE LOCATION

=over 4

=item B<-d NAME>

=item B<--default-domain=NAME>

Use B<NAME>.po for output (instead of F<messages.po>).

=item B<-o FILE>

=item B<--output=FILE>

Write output to specified F<B<FILE>> (instead of F<B<NAME>.po> or 
F<messages.po>).

=item B<-p DIR>

=item B<--output-dir=DIR>

Output files will be placed in directory B<DIR>.

If the output file is B<-> or F</dev/stdout>, the output is written to standard 
output. 

=back

=head2 INPUT FILE INTERPRETATION

=over 4

=item B<--from-code=NAME>

Specifies the encoding of the input files. This option is needed only if some 
untranslated message strings or their corresponding comments contain non-ASCII 
characters.

By default the input files are assumed to be in ASCII.

B<Note!> Some extractors have a fixed input set, UTF-8 most of the times.

=back
