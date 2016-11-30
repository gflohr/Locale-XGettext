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

sub getLanguageSpecificOptions {
	my ($self) = @_;
	
    return [] if !JavaXGettext->can('getLanguageSpecificOptions');

    return JavaXGettext->getLanguageSpecificOptions;
}

sub extractFromNonFiles {
	my ($self) = @_;
	
	return $self if !JavaXGettext->can('extractFromNonFiles');
	
	return $self->{__java_extractor}->extractFromNonFiles;
}

package Locale::XGettext::Callbacks;

use strict;

sub addEntry {
    my ($class, %entry) = @_;

    $xgettext->addEntry(\%entry);

    return 1;
}
