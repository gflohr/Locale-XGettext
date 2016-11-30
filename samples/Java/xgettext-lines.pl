#! /usr/bin/env perl

use strict;

use File::Spec;

my $xgettext;

my $code;

BEGIN {
    my @spec = File::Spec->splitpath(__FILE__);
    $spec[2] = 'JavaXGettext.java';
    my $java_filename = File::Spec->catpath(@spec);
    open HANDLE, "<$java_filename"
        or die "Cannot open '$java_filename': $!\n";
    $code = join '', <HANDLE>;
}

use Inline Java => $code;

Locale::XGettext::Lines->newFromArgv(\@ARGV)->run->output;

package Locale::XGettext::Lines;

use strict;

use base 'Locale::XGettext';

sub new {
    my ($class, @args) = @_;

    my $self = $xgettext = $class->SUPER::new(@args);
    $self->{__java_extractor} = JavaXGettext->new;

    return $self;
}

sub readFile {
    my ($self, $filename) = @_;

    $self->{__java_extractor}->readFile($filename);
}

# See the comments in JavaXGettext.java for more information about the 
# following optional methods.
sub extractFromNonFiles {
    my ($self) = @_;
    
    return $self->SUPER::extractFromNonFiles()
        if !$self->can('extractFromNonFiles');
    
    return $self->{__java_extractor}->extractFromNonFiles;
}

# We have to translate that from Java.
sub defaultKeywords {
	my ($self) = @_;

    return $self->SUPER::defaultKeywords()
        if !JavaXGettext->can('defaultKeywords');
    
    # Turn the array of arrays returned by the Java class method into a Perl
    # Hash.  The array returned from Java is an Inline::Java::Array which
    # does not support splice().  We therefore have to copy it into a
    # plain array.
    my %keywords = map { 
        my @keyword = @{$_};
    	$keyword[0] => [splice @keyword, 1] 
    } @{JavaXGettext->defaultKeywords};

    return %keywords;
}

sub getLanguageSpecificOptions {
	my ($self) = @_;
	
    return $self->SUPER::extractFromNonFiles() 
        if !JavaXGettext->can('getLanguageSpecificOptions');

    return JavaXGettext->getLanguageSpecificOptions;
}

sub fileInformation {
    my ($self) = @_;
    
    return $self->SUPER::fileInformation() 
        if !JavaXGettext->can('fileInformation');
    
    return JavaXGettext->fileInformation;
}

sub canExtractAll {
    my ($self) = @_;
    
    return $self->SUPER::canExtractAll() 
        if !JavaXGettext->can('canExtractAll');
    
    return JavaXGettext->canExtractAll; 
}

sub canKeywords {
    my ($self) = @_;
    
    return $self->SUPER::canKeywords() 
        if !JavaXGettext->can('canKeywords');
    
    return JavaXGettext->canKeywords; 
}

sub canFlags {
    my ($self) = @_;
    
    return $self->SUPER::canFlags() 
        if !JavaXGettext->can('canFlags');
    
    return JavaXGettext->canFlags; 
}

# This will not win a prize for clean software design.  You cannot invoke
# methods of Perl object from Java.  We therefore keep the most "current"
# instance of the extractor class in a variable $xgettext and call
# the methods on this instance.  This works without problems inside of a
# script which is sufficient for our needs.

package Locale::XGettext::Callbacks;

use strict;

sub addEntry {
    my ($class, %entry) = @_;

    $xgettext->addEntry(\%entry);

    return 1;
}
