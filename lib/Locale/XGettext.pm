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

use base 'Exporter';
use vars qw(@EXPORT $VERSION);
@EXPORT = qw($VERSION);
$VERSION = '0.1.1';

use Locale::TextDomain qw(Locale-XGettext);
use File::Spec;
use Locale::PO 0.27;
use Scalar::Util qw(reftype);
use Locale::Recode;

use Locale::XGettext::POEntries;

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

    my $po = Locale::XGettext::POEntries->new; 
    foreach my $filename (@{$self->{__files}}) {
        my $path = $self->__resolveFilename($filename)
            or die __x("Error opening '{filename}': {error}!\n",
                       filename => $filename, error => $!);
        my @entries = $self->__getEntriesFromFile($path);
        foreach my $entry (@entries) {
            $self->__recodeEntry($entry, $from_code, $cd, $path);
        }
        $po->addEntries(@entries);
    }

    # FIXME! Sort po!
    
    if (($po->entries || $self->{__options}->{force_po})
        && !$self->{__options}->{omit_header}) {
        $po->prepend($self->__poHeader);
    }

    $self->{__po} = $po;
    
    return $self;
}

sub __conversionError {
    my ($self, $reference, $cd) = @_;
    
    die __x("{reference}: {conversion_error}\n",
            reference => $reference,
            conversion_error => $cd->getError);
}

sub __recodeEntry {
    my ($self, $entry, $from_code, $cd) = @_;
   
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

sub __resolveFilename {
    my ($self, $filename) = @_;
    
    my $directories = $self->{__options}->{directory} || ['.'];
    foreach my $directory (@$directories) {
    	my $path = File::Spec->catfile($directory, $filename);
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

    die __"No input file given.\n" if !@files;
    
    $self->{__files} = \@files;
    
    return $self;
}

1;
