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

package Locale::XGettext::TT2;

use strict;

use base 'Exporter';
use vars qw(@EXPORT $VERSION);
@EXPORT = qw($VERSION);
$VERSION = '0.1.1';

use Locale::TextDomain qw(Template-Plugin-Gettext);
use File::Spec;
use Template;
use Locale::PO 0.27;
use Scalar::Util qw(reftype);
use Locale::Recode;

sub empty {
    my ($what) = @_;

    return if defined $what && length $what;

    return 1;
}

sub new {
    my ($class, $options, @files) = @_;

    my $self = {
        __options => $options,
        __comment_tag => undef,
        __files => [@files],
    };
    
    bless $self, $class;
    
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

    # TODO: Read exclusion file for --exclude-file.

    return $self;
}

sub defaultKeywords {
	return (
        gettext => [1],
        ngettext => [1, 2],
        pgettext => ['1c', 2],
        npgettext => ['1c', 2, 3],
        xgettext => [1],
        nxgettext => [1, 2],
        pxgettext => ['1c', 2],
        npxgettext => ['1c', 2, 3],
	);
}

sub run {
	my ($self) = @_;

    if ($self->{__run}++) {
        require Carp;
        Carp::croak(__"Attempt to re-run extractor");
    }

    my $from_code = $self->{__options}->{from_code};
    $from_code = Locale::Recode->resolveAlias($from_code);
    
    my $cd;
    if ($from_code ne 'US-ASCII' && $from_code ne 'UTF-8') {
    	$cd = Locale::Recode->new(from => $from_code, to => 'utf-8')
    	   or die $cd->getError;
    }
    
    my $po = Locale::XGettext::TT2::POEntries->new;
    foreach my $filename (@{$self->{__files}}) {
    	my $path = $self->__resolveFilename($filename)
    	    or die __x("Error opening '{filename}': {error}!\n",
    	               filename => $filename, error => $!);
    	my $entries = $self->__getEntriesFromFile($path);
        unless ($self->{__options}->{no_location}) {
            foreach my $entry (@$entries) {
            	$self->__addLocation($entry, $filename);
            }
        }
        foreach my $entry (@$entries) {
        	$self->__recodeEntry($entry, $from_code, $cd, $path);
        }
        $po->addEntries($entries);
    }

    # FIXME! Sort po!
    
    if ((@$po || $self->{__options}->{force_po})
        && !$self->{__options}->{omit_header}) {
        unshift @$po, $self->__poHeader;
    }

    $self->{__po} = $po;
    
    return $self;
}

sub __conversionError {
    my ($self, $filename, $lineno, $cd) = @_;
    
    die __x("{filename}:{lineno}: {conversion_error}\n",
            filename => $filename, lineno => $lineno,
            conversion_error => $cd->getError);
}

sub __recodeEntry {
	my ($self, $entry, $from_code, $cd, $filename) = @_;
	
    my $toString = sub {
    	my ($entry) = @_;

        return join '', map { defined $_ ? $_ : '' }
            $entry->msgid, $entry->msgid_plural, 
            $entry->msgctxt, $entry->comment;
    };
    
    my $lineno = $entry->{__xgettext_tt_lineno};
    if ($from_code eq 'US-ASCII') {    	
    	# Check that everything is 7 bit.
    	my $flesh = $toString->($entry);
        if ($flesh !~ /^[\000-\177]*$/) {
        	die __x("Non-ASCII string at {filename}:{lineno}.\n"
        	        . "    Please specify the source encoding through "
        	        . "--from-code.\n",
        	        filename => $filename,
        	        lineno => $lineno);
        }
    } elsif ($from_code eq 'UTF-8') {
    	# Check that utf-8 is valid.
    	require utf8; # [SIC!]
    	
        my $flesh = $toString->($entry);
        if (!utf8::valid($flesh)) {
        	die __x("{filename}:{lineno}: invalid multibyte sequence\n",
        	        filename => $filename,
        	        lineno => $lineno);
        }
    } else {
    	# Convert.
        my $msgid = Locale::PO->dequote($entry->msgid);
        if (!empty $msgid) {
            $cd->recode($msgid) 
                or $self->__conversionError($filename, $lineno, $cd);
            $entry->msgid($msgid);
        }
        
        my $msgid_plural = Locale::PO->dequote($entry->msgid_plural);
        if (!empty $msgid_plural) {
            $cd->recode($msgid_plural) 
                or $self->__conversionError($filename, $lineno, $cd);
            $entry->msgid($msgid_plural);
        }
    	
    	my $msgstr = Locale::PO->dequote($entry->msgstr);
        if (!empty $msgstr) {
            $cd->recode($msgstr) 
                or $self->__conversionError($filename, $lineno, $cd);
            $entry->msgid($msgstr);
        }
        
        my $msgstr_n = Locale::PO->dequote($entry->msgstr_n);
        if ($msgstr_n) {
            my $msgstr_0 = Locale::PO->dequote($msgstr_n->{0});
            $cd->recode($msgstr_0) 
                or $self->__conversionError($filename, $lineno, $cd);
            my $msgstr_1 = Locale::PO->dequote($msgstr_n->{1});
            $cd->recode($msgstr_1) 
                or $self->__conversionError($filename, $lineno, $cd);
            $entry->msgstr_n({
            	0 => $msgstr_0,
            	1 => $msgstr_1,
            })
        }
        
    	my $comment = $entry->comment;
    	$cd->recode($comment) 
    	    or $self->__conversionError($filename, $lineno, $cd);
    	$entry->comment($comment);
    }

	
	return $self;
}

sub __resolveFilename {
	my ($self, $filename) = @_;
	
	my $directories = $self->{__options}->{directory} || ['.'];
	foreach my $directory (@$directories) {
		my $path = File::Spec->catfile($directory, $filename);
		stat $path && return $path;
	}
	
	return;
}

sub __addLocation {
	my ($self, $entry, $filename) = @_;

    my $new_ref = "$filename:$entry->{__xgettext_tt_lineno}";
    
    my $reference = $entry->reference;
    my @lines = split "\n", $reference;
    if (!@lines) {
    	push @lines, $new_ref;
    } else {
    	my $last_line = $lines[-1];
    	my $ref_length = 1 + length $new_ref;
    	if ($ref_length > 76) {
    		push @lines, $new_ref;
    	} elsif ($ref_length + length $last_line > 76) {
    		push @lines, $new_ref;
    	} else {
    		$lines[-1] .= ' ' . $new_ref;
    	}
    }
    
    $entry->reference(join "\n", @lines);
    
    return $self;
}

sub po {
	shift->{__po};
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
    
    return if !@{$self->{__po}} && !$self->{__options}->{force_po};

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
    
    foreach my $entry (@{$self->{__po}}) {
    	print $fh $entry->dump
            or die __x("Error writing '{file}': {error}.\n",
                       file => $filename, error => $!);
    }
    close $fh
        or die __x("Error writing '{file}': {error}.\n",
                   file => $filename, error => $!);
    
    return $self;
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

    my %options = (
        INTERPOLATE => 1,
        RELATIVE => 1
    );
    
    my $parser = Locale::XGettext::TT2::Parser->new(\%options);
    
    my $tt = Template->new({
        %options,
        PARSER => $parser,
    });
 
    my $sink;
    $parser->{__xgettext}->{options} = $self->{__options};
    
    $tt->process($filename, {}, \$sink) or die $tt->error;

    my $entries = $parser->__xgettextEntries;
    
    return $entries;
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

    die __"No input file given.\n" if !@files;
    
    $self->{__files} = \@files;
    
    return $self;
}

package Locale::XGettext::TT2::POEntries;

use strict;

sub new {
	bless [], shift;
}

sub add {
	my ($self, $entry) = @_;
	
	push @$self, $entry;
	
	return $self;
}

sub addEntries {
	my ($self, $entries) = @_;
	
	push @$self, @$entries;
	
	return $self;
}

sub entries {
	my ($self) = @_;
	
	return @$self;
}

package Locale::XGettext::TT2::Parser;

use base qw(Template::Parser);

use strict;

sub split_text {
    my ($self, $text) = @_;

    my %functions = (
        gettext => [qw(s)],
        ngettext => [qw(s p)],
        pgettext => [qw(c s)],
        npgettext => [qw(c s p)],
        xgettext => [qw(s)],
        nxgettext => [qw(s p)],
        pxgettext => [qw(c s)],
        npxgettext => [qw(c s p)],
    );
    my %properties = (
        s => 'msgid',
        p => 'msgid_plural',
        c => 'msgctxt',
    );

    sub extract_args {
        my ($tokens, $offset, $function) = @_;

        return if $offset >= @$tokens;
        my $schema = $functions{$function};

        return if '(' ne $tokens->[$offset];
        $offset += 2;

        my $entry = Locale::PO->new;
        foreach my $type (@$schema) {
            return if $offset >= @$tokens;

            if ('LITERAL' eq $tokens->[$offset]) {
                my $string = substr $tokens->[$offset + 1], 1, -1;
                $string =~ s/\\([\\'])/$1/gs;
                my $method = $properties{$type};
                $entry->$method($string);
                
                $offset += 2;

                if ($type ne $schema->[-1]) {
                    return if $offset >= @$tokens;
                    return if 'COMMA' ne $tokens->[$offset];
                    $offset += 2;
                }
            } elsif ('"' eq $tokens->[$offset]) {
                $offset += 2;
                return if $offset >= @$tokens;
                return if 'TEXT' ne $tokens->[$offset];
                my $method = $properties{$type};
                $entry->$method($tokens->[$offset + 1]);
                
                $offset += 4;
            } else {
                return;
            }
        }

        if (defined $entry->msgid_plural && length $entry->msgid_plural) {
            $entry->msgstr_n({0 => '', 1 => ''});
        } else {
            $entry->msgstr('');       	
        }

        # We ignore excess elements.

        return $entry;
    }

    my $chunks = $self->SUPER::split_text($text) or return;

    my $entries = Locale::XGettext::TT2::POEntries->new;
    
    my $options = $self->{__xgettext}->{options};
    
    my $ident;
    foreach my $chunk (@$chunks) {
         my ($text, $lineno, $tokens) = @$chunk;

         next if !ref $tokens;

         if ('USE' eq $tokens->[0] && 'IDENT' eq $tokens->[2]) {
             if ('Gettext' eq $tokens->[3]
                 && (4 == @$tokens
                     || '(' eq $tokens->[4])) {
                 $ident = 'Gettext';
             } elsif ('ASSIGN' eq $tokens->[4] && 'IDENT' eq $tokens->[6]
                      && 'Gettext' eq $tokens->[7]) {
                 $ident = $tokens->[3];
             }
             next;
         }

         next if !defined $ident;
    
         if ('IDENT' eq $tokens->[0] && $ident eq $tokens->[1]
             && 'DOT' eq $tokens->[2] && 'IDENT' eq $tokens->[4]
             && exists $functions{$tokens->[5]}) {
             my $entry = extract_args $tokens, 6, $tokens->[5];
             next if !$entry;

             $entry->{__xgettext_tt_lineno} = $lineno;
             
             if ($options->{add_comments} && $text =~ /^#/) {
             	my @triggers = @{$options->{add_comments}};
             	foreach my $trigger (@triggers) {
             		if ($text =~ /^#[ \t\r\f\013]*$trigger/) {
             			my $comment = '';
             			my @lines = split /\n/, $text;
             			foreach my $line (@lines) {
             				last if $line !~ s/^[ \t\r\f\013]*#[ \t\r\f\013]?//;
             				
             			    $comment .= $line . "\n";
             			}
             			chomp $comment;
             			$entry->comment($comment);
             			last;
             		}
             	}
             }
             
             $entries->add($entry);
         }
    }

    $self->{__xgettext_entries} = $entries;

    # Stop processing here, so that for example includes are ignored.    
    return [];
}

sub __xgettextEntries {
	shift->{__xgettext_entries};
}

1;
