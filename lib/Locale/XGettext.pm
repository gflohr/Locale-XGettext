#! /bin/false
# vim: ts=4:et

# Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warrant y of
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
use Scalar::Util qw(reftype blessed);
use Locale::Recode;
use Getopt::Long qw(GetOptionsFromArray);

use Locale::XGettext::Util::POEntries;
use Locale::XGettext::Util::Keyword;

# Helper method, not exported!
sub empty($) {
    my ($what) = @_;

    return if defined $what && length $what;

    return 1;
}

sub new {
    my ($class, $options, @files) = @_;

    my $self;
    if (ref $class) {
        $self = $class;
    } else {
        $self = bless {}, $class;
    }

    $self->{__options} = $options;
    $self->{__comment_tag} = undef;
    $self->{__files} = [@files];
    $self->{__exclude} = {};

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

    if (exists $options->{exclude_file} && !ref $options->{exclude_file}) {
    	$options->{exclude_file} = [$options->{exclude_file}];
    }

    $self->__readExcludeFiles($options->{exclude_file});

    return $self;
}

sub newFromArgv {
	my ($class, $argv) = @_;

    my $self;
    if (ref $class) {
    	$self = $class;
    } else {
    	$self = bless {}, $class;
    }

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
    return [];
}

sub defaultFlags {
	return [];
}

sub run {
    my ($self) = @_;

    if ($self->{__run}++) {
        require Carp;
        Carp::croak(__"Attempt to re-run extractor");
    }

    my $po = $self->{__po} = Locale::XGettext::Util::POEntries->new;
    
    if ($self->option('join_existing')) {
    	my $output_file = $self->__outputFilename;
    	if ('-' eq $output_file) {
    		$self->__usageError(__"--join-existing cannot be used when output"
    		                      . " is written to stdout");
    	}
    	$self->readPO($output_file);
    }
    
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

sub __setAutomaticComment {
    my ($self, $entry) = @_;

    my $keyword = delete $entry->{keyword};
    return if !defined $keyword;

    my $keywords = $self->option('keyword');
    if (exists $keywords->{$keyword}) {
        my $comment = $keywords->{$keyword}->comment;
        $entry->{automatic} = $comment if !empty $comment;
    }

    return $self;
}

sub addFlaggedEntry {
	my ($self, $entry, $comment) = @_;
    
    if (!$self->{__run}) {
        require Carp;
        Carp::croak(__"Attempt to add entries before run");
    }

    # Simplify calling from languages that do not have hashes.
    if (!ref $entry) {
        my @args = splice @_, 1;
        if (@args % 2) {
            # Odd number of arguments.  A comment was passed.
            $comment = pop @args;
        } else {
            undef $comment;
        }

        $entry = {@args};
    }

    $self->__setAutomaticComment($entry);

    $entry = $self->__promoteEntry($entry);
    
    my ($msgid) = $entry->msgid;
    if (!empty $msgid) {
    	my $ctx = $entry->msgctxt;
    	$ctx = '' if empty $ctx;
    	
    	return $self if exists $self->{__exclude}->{$msgid}->{$ctx};
    }
    
    my $comment_keywords = $self->option('add_comments');
    if (defined $comment && $comment_keywords) {
    	foreach my $keyword (@$comment_keywords) {
    		if ($comment =~ /($keyword.*)/s) {
    			$entry->automatic($1);
    			last;
    		}
    	}
    }
    
    $self->{__po}->add($entry);
}

sub addEntry {
	my ($self, $entry, $comment) = @_;

    # Simplify calling from languages that do not have hashes.
    if (!ref $entry) {
        my @args = splice @_, 1;
        if (@args % 2) {
            # Odd number of arguments.  A comment was passed.
            $comment = pop @args;
        } else {
            undef $comment;
        }

        $entry = {@args};
    }
	
    $self->__setAutomaticComment($entry);

	if (defined $comment) {
        $entry = $self->__promoteEntry($entry);
        
		# Does it contain an "xgettext:" comment?  The original implementation
		# is quite relaxed here, even recogizing comments like "exgettext:".
		my $cleaned = '';
		$comment =~ s{
		          (.*?)xgettext:(.*?(?:\n|\Z))
		      }{
	              my ($lead, $string) = ($1, $2);
		          my $valid;
		                    
		          my @tokens = split /[ \x09-\x0d]+/, $string;
		                    
		          foreach my $token (@tokens) {
		              if ($token eq 'fuzzy') {
		                  $entry->fuzzy(1);
		                  $valid = 1;
		              } elsif ($token eq 'no-wrap') {
		              	  $entry->add_flag('no-wrap');
		              	  $valid = 1;
		              } elsif ($token eq 'wrap') {
                          $entry->add_flag('wrap');
                          $valid = 1;
		              } elsif ($token =~ /^[a-z]+-(?:format|check)$/) {
		              	  $entry->add_flag($token);
		              	  $valid = 1;
		              }
		          }
		                    
		          $cleaned .= "${lead}xgettext:${string}" if !$valid;
		      }exg;

        $cleaned .= $comment;
        $comment = $cleaned;
	}
	
	$self->addFlaggedEntry($entry, $comment);
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

sub options {
	shift->{__options};
}

sub option {
	my ($self, $key) = @_;

	return if !exists $self->{__options}->{$key};
	
	return $self->{__options}->{$key};
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
    my $filename = $self->__outputFilename;

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

sub languageSpecificOptions {}

# In order to simplify the code in other languages, we allow returning
# a flat list instead of an array of arrays.  This wrapper checks the
# return value and converts it accordingly.
sub __languageSpecificOptions {
    my ($self) = @_;

    my @options = $self->languageSpecificOptions;
    return $options[0] if @options & 0x3;

    # Number of items is a multiple of 4.
    my @retval;
    while (@options) {
            push @retval, [splice @options, 0, 4];
    }

    return \@retval;
}

sub printLanguageSpecificUsage {
    my ($self) = @_;
  
    my $options = $self->__languageSpecificOptions;
    
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
                if (@description && $pos > 77 - length $description[-1]) {
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

sub bugTrackingAddress {}

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

sub canFlags {
    shift;
}

sub needInputFiles {
	shift;
}

sub __readExcludeFiles {
	my ($self, $files) = @_;
	
	return $self if !$files;
	
	foreach my $file (@$files) {
	   my $entries = Locale::PO->load_file_asarray($file)
        or die __x("error reading '{filename}': {error}!\n",
                   filename => $file, error => $!);
    
		foreach my $entry (@$entries) {
			my $msgid = $entry->msgid;
			next if empty $msgid;
			
			my $ctx = $entry->msgctxt;
			$ctx = '' if empty $ctx;
			
			$self->{__exclude}->{$msgid}->{$ctx} = $entry;
		}
	}
	
	return $self;
}

sub __promoteEntry {
	my ($self, $entry) = @_;
	
	if (!blessed $entry) {
        my $po_entry = Locale::PO->new;
        foreach my $method (keys %$entry) {
            $po_entry->$method($entry->{$method});
        }
        $entry = $po_entry;
    }

	return $entry;
}
sub __conversionError {
    my ($self, $reference, $cd) = @_;
    
    die __x("{reference}: {conversion_error}\n",
            reference => $reference,
            conversion_error => $cd->getError);
}

sub __outputFilename {
	my ($self) = @_;
	
	my $options = $self->{__options};
    if (exists $options->{output}) {
        if (File::Spec->file_name_is_absolute($options->{output})
            || '-' eq $options->{output}) {
            return $options->{output}; 
        } else {
            return File::Spec->catfile($options->{output_dir},
                                       $options->{output})
        }
    } elsif ('-' eq $options->{default_domain}) {
        return '-';
    } else {
        return File::Spec->catfile($options->{output_dir}, 
                                   $options->{default_domain} . '.po');
    }
	
	# NOT REACHED!
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

sub __getOptions {
    my ($self, $argv) = @_;
    
    my %options;
    
    my $lang_options = $self->__languageSpecificOptions;
    my %lang_options;
    
    foreach my $optspec (@$lang_options) {
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
        
        # We allow multiple files.
        'x|exclude-file=s@' => \$options{exclude_file},
        'c|add-comments:s@' => \$options{add_comments},

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
sub __setKeywords {
    my ($self, $options) = @_;
   
    my $keywords = $self->defaultKeywords;
    my %keywords;

    if ('HASH' eq reftype $keywords) {
        %keywords = %$keywords;
    } else {
        %keywords = $self->__makeHash(@$keywords);
    }

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

sub __makeHash {
    my ($self, @values) = @_;

    if (1 == @values) {
        if ('HASH' eq reftype $values[0]) {
            return %{$values[0]};
        } else {
            return @{$values[0]};
        }
    }

    return @values;
}

sub __makeArray {
    my ($self, @values) = @_;
    
    return $self->__makeHash(@values);
}

sub __parseFlag {
	my ($self, $flag) = @_;
	
	return if $flag !~ s/:([^:]+)$//;
	my $format = $1;
	
    return if $flag !~ s/:([^:]+)$//;
	my $argnum = $1;
	
	my $function = $flag;
	return if !length $function;
	
	return;
}

sub __setFlags {
    my ($self, $options) = @_;
    
    my @defaults = @{$self->defaultFlags};
    
    foreach my $flag (@defaults, @$options) {
    	my @spec = $self->__parseFlag($flag)
    	    or die __x("A --flag argument doesn't have the"
    	               . " <keyword>:<argnum>:[pass-]<flag> syntax: {flag}",
    	               $flag);
    }
    
    return $self;
}

sub __displayUsage {
	my ($self) = @_;
	
	if ($self->needInputFiles) {
        print __x("Usage: {program} [OPTION] [INPUTFILE]...\n", program => $0);
        print "\n";
    
        print __(<<EOF);
Extract translatable strings from given input files.  
EOF
	} else {
        print __x("Usage: {program} [OPTION]\n", program => $0);
        print "\n";
    
        print __(<<EOF);
Extract translatable strings.  
EOF
	}
	
    if (defined $self->fileInformation) {
    	print "\n";
    	my $description = $self->fileInformation;
    	chomp $description;
    	print "$description\n";
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

    my $url = $self->bugTrackingAddress;

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

This section describes the usage of extractors based on this library.
See L</SUBCLASSING> and the sections following it for the API 
documentation!

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

=head2 OPERATION MODE

=over 4

=item B<-j>

=item B<--join-existing>

Join messages with existing files.  This is a shortcut for adding the
output file to the list of input files.  The output file is read, and
then all messages from other input files are added.

For obvious reasons, you cannot use this option if output is written
to standard output.

=item B<-x FILE.po>

=item B<--exclude-file=FILE.po>

PO entries that are present in F<FILE.po> are not extracted.

=item B<-c TAG>

=item B<--add-comments=TAG>

Place comment blocks starting with B<TAG> in the output
if they precede a keyword line.

=item B<-c>

=item B<--add-comments>

Place all comment blocks that precede a keyword line in the output.

=back

=head2 LANGUAGE-SPECIFIC-OPTIONS

=over 4

=item B<-a>

=item B<--extract-all>

Extract B<all> strings, not just the ones marked with keywords.

B<Not all extractors support this option!>

=item B<-k WORD>

=item B<--keyword=WORD>

Use B<WORD> as an additional keyword.

B<Not all extractors support this option!>

=item B<-k>

=item B<--keyword>

Do not use default keywords!  If you define your own keywords, you
use usually give the option '--keyword' first without an argument to
reset the keyword list to empty, and then you give a '--keyword'
option for everyt keyword wanted.

B<Not all extractors support this option!>

=item B<--flag=WORD:ARG:FLAG>

Not yet implemented.  The option is ignored for compatibility reasons.

Individual extractors may define more language-specific options.

=back

=head2

=over 4

=item B<--force-po>

Write PO file even if empty.  Normally, empty PO files are not written,
and existing output files are not overwritten if they would be empty.

=item B<--no-location>

Do not write '#: filename:line' lines into the output PO files.

=item B<-n>

=item B<--add-location>

Generate '#: filename:line' lines in the output PO files.  This is the
default.

=item B<-s>

=item B<--sort-output>

Sort output entries alphanumerically.

=item B<-F>

=item B<--sort-by-file>

Sort output entries by source file location.

=item B<--omit-header>

Do not write header with meta information.  The meta information is
normally included as the "translation" for the empty string.

If you want to hava a translation for an empty string you should also
consider using message contexts.

=item B<--copyright-holder=STRING>

Set the copyright holder to B<STRING> in the output PO file.

=item B<--foreign-user>

Omit FSF copyright in output for foreign user.

=item B<--package-name=PACKAGE>

Set package name in output

=item B<--package-version=VERSION>

Set package version in output.

=item B<--msgid-bugs-address=EMAIL@ADDRESS>

Set report address for msgid bugs.

=item B<-m[STRING]>

=item B<--msgstr-prefix[=STRING]>

Use STRING or "" as prefix for msgstr values.

=item B<-M[STRING]>

=item B<--msgstr-suffix[=STRING]>

Use STRING or "" as suffix for msgstr values.

=back

=head2 INFORMATIVE OUTPUT

=over 4

=item B<-h>

=item B<--help>

Display short help and exit.

=item B<-V>

=item B<--version>

Output version information and exit.

=back

=head1 SUBCLASSING

Writing a complete extractor script in Perl with B<Locale::XGettext>
is as simple as:

    #! /usr/bin/env perl

    use Locale::Messages qw(setlocale LC_MESSAGES);
    use Locale::TextDomain qw(YOURTEXTDOMAIN);

    use Locale::XGettext::YOURSUBCLASS;

    Locale::Messages::setlocale(LC_MESSAGES, "");
    Locale::XGettext::YOURSUBCLASS->newFromArgv(\@ARGV)->run->output;

Writing the extractor class is also trivial:

    package Locale::XGettext::YOURSUBCLASS;

    use base 'Locale::XGettext';

    sub readFile {
        my ($self, $filename) = @_;

        foreach my $found (search_for_strings_in $filename) {
            $self->addEntry({
                msgid => $found->{string},
                # More possible fields following, see 
                # addEntry() below!
            }, $found->{possible_comment});
        }

        # The return value is actually ignored.
        return $self;
    }

All the heavy lifting happens in the method B<readFile()> that you have
to implement yourself.  All other methods are optional.

See the section L</METHODS> below for information on how to
additionally modify the behavior your extractor.

=head1 CONSTRUCTORS

=over 4

=item B<new $OPTIONS, @FILES>

B<OPTIONS> is a hash reference containing the above commandline
options but with every hyphen replaced by an underscore.  You
should normally not use this constructor!

=item B<newFromArgv $ARGV>

B<ARGV> is a reference to a an array of commandline arguments
that is passed verbatim to B<Getopt::Long::GetOptionsFromArray>.
After processing all options and arguments, the constructor
B<new()> above is then invoked with the cooked commandline
arguments.

This is the constructor that you should normally use in 
custom extractors that you write.

=back

=head1 METHODS

B<Locale::XGettext> is an abstract base class.  All public methods
may be overridden by subclassed extractors.

=over 4

=item B<readFile FILENAME>

You have to implement this method yourself.  In it, read B<FILENAME>,
extract all relevant entries, and call B<addEntry()> for each entry
found.

The method is not invoked for filenames ending in ".po" or ".pot"!
For those files, B<readPO()> is invoked instead.

This method is the only one that you have to implement!

=item B<addEntry ENTRY[, COMMENT]>

You should invoke this  method for every entry found.  

B<COMMENT> is an optional comment that you may have extracted along 
with the message.  Note that B<addEntry()> checks whether this
comment should make it into the output.  Therefore, just pass any
comment that you have found preceding the keyword.

B<ENTRY> should be a reference to a hash with these possible
keys:

=over 8

=item B<msgid>

The entry's message id.

=item B<msgid_plural>

A possible plural form.

=item B<msgctxt>

A possible message context.

=item B<reference>

A source reference in the form "FILENAME: LINENO".

=item B<add_flag>

Set a flag for this entry, for example "perl-brace-format" or
"no-perl-brace-format".

=item B<fuzzy>

True if the entry is fuzzy.  There is no reason to use this.

=item B<automatic>

Do not use! Well, okay, if you know Locale::PO(3pm) you may
understand it and use it.  But it's not recommended.

=back 

=item B<options>

Get all commandline options as a hash reference.

=item B<option OPTION>

Get the value for command line option B<OPTION>.

=item B<languageSpecificOptions>

The default representation returns nothing.

Your own implementation can return an reference to an array of
arrays, each of them containing one option specification
consisting of four items:

=over 8

=item *

The option specification for Getopt::Long(3pm), for example
"-f|--filename=s" for an option expexting a mandatory
string argument.

=item *

The name of the option.  This is what gets passed to option()
above.  It should generally be the long option name with hyphens
converted to underscores.

=item *

The option description for the usage information, for example
"-f, --files=STRING" for options taking arguments or 
something like "    --verbose" for long-only options.  This
is printed in the left column, when you invoke your extractor
with "--help".

=item *

The description of this option.  This is printed in the right
column, when you invoke your extractor with "--help".

=back

=item B<printLanguageSpecificOptions>

Prints all language-specific options to standard output, calls
languageSpecificOptions() internally.  This is used for the
output for the option "--help".

=item B<fileInformation>

Returns nothing by default.  You can return a string describing
the expected input format, when invoked with "--help".

=item B<bugTrackingAddress>

Returns nothing by default.  You can return a string describing
the bug tracking address, when invoked with "--help".

=item B<canExtractAll>

Returns false by default.  Return a truthy value if your extractor
supports the option "--extract-all".

=item B<canKeywords>

Returns true by default.  Return a false value if your extractor
does not support the option "--keyword".

=item B<canFlags>

Returns true by default.  Return a false value if your extractor
does not support the option "--flag".

=item B<needInputFiles>

Returns true by default.  Return a false value if your extractor
does not support input from files.  In this case you should
implement readFromNonFiles().

=item B<run>

Runs the extractor once.  The default implementation scans all
input sources for translatable strings and collects them.

=item B<output>

Print the output as a PO file to the specified output location.

=item B<extractFromNonFiles>

This method is invoked after all input files have been processed.
The default implementation does nothing.  You may use the method
for extracting strings from additional sources like a database.

=item B<resolveFilename FILENAME>

Given an input filename B<FILENAME> the method returns the absolute
location of the file.  The default implementation honors the
option "-D, --directory".

=item B<defaultKeywords>

Returns a reference to an emtpy array.

Subclasses may return a reference to an array with default keyword
definitions for the specific language.  The default keywords 
(actually just a subset for it) for the language C would look like 
this (expressed in JSON):

    {
        "gettext": [1],
        "ngettext": [1, 2],
        "pgettext": ["1c", 2],
        "npgettext": ["1c", 2, 3]
    }

Instead of a hasn reference you can also pass an array reference
or a list.  The reason for that is that other languages than Perl
may not support hashes or lists.

In either case, each entry consists of a keyword and an argument
specification.  The first position specification without a 
modifier (only "c" is possible) is the position of the message
id.  The second one is the position of the plural form.  The
location specification with a trailing "c" denoteas the position
of the message context.

=item B<defaultFlags>

Not yet implemented.  Do not use!

=item B<recodeEntry ENTRY>

Gets invoked for every PO entry but I<after> it has been
promoted to a B<Locale::PO(3pm)> object.  The implementation
of this method is likely to be changed in the future.

Do not use!

=item B<readPO FILENAME>

Reads B<FILENAME> as .po or .pot file.  There is no reason why
you should override or invoke this method.

=item B<po>

Returns a list of PO entries represented by hash references.
Do not use or override this method!

=back

=head1 BUGS

Flags are not yet supported.

=head1 COPYRIGHT

Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>,
all rights reserved.

=head1 SEE ALSO

Getopt::Long(3pm), xgettext(1), perl(1)
