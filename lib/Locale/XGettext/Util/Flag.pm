#! /bin/false

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
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

package Locale::XGettext::Util::Flag;

use strict;

use Locale::TextDomain qw(Locale-XGettext);

sub new {
    my ($class, %args) = @_;

    return if !defined $args{function};
    return if !defined $args{flag};
    return if !defined $args{arg};
    return if !length $args{function};
    return if !length $args{flag};
    # That would break the output.
    return if $args{flag} =~ /\n/;
    return if $args{arg} !~ /^[1-9][0-9]*$/;

    if (!$args{pass} && !$args{arg}) {
        $args{pass} = 1 if $args{flag} =~ s/^pass-//;
        $args{no} = 1 if $args{flag} =~ s/^no-//;
    }

    my %seen;
    my $comment;
    my $comment_seen;
    my $context_seen;
    my $self = {
        function => $args{function},
        arg => $args{arg},
        flag => $args{flag}
    };

    $self->{pass} = 1 if $args{pass};
    $self->{no} = 1 if $args{no};

    bless $self, $class;
}

sub newFromString {
    my ($class, $orig_spec) = @_;
    
    my $spec = $orig_spec;
    $spec =~ s/\s+//g;

    my ($function, $arg, $flag) = split /:/, $spec, 3;
    
    my ($pass, $no);
    $pass = 1 if $flag =~ s/^pass-//;
    $no = 1 if $flag =~ s/^no-//;

    return $class->new(
        function => $function,
        arg => $arg,
        flag => $flag,
        no => $no,
        pass => $pass,
    );
}

sub function {
    shift->{function};
}

sub arg {
    shift->{arg};
}

sub flag {
    shift->{flag}
}

sub no {
    shift->{no};
}

sub pass {
    shift->{pass};
}

1;

=head1 NAME

Locale::XGettext::Util::Flag - A Flag Specification Used By xgettext

=head1 SYNOPSIS

    use Locale::XGettext::Util::Flag;

    $keyword = Locale::XGettext::Flag->new(function => '__x',
                                           arg => 1,
                                           flag => 'perl-brace-format',
                                           no => 0,
                                           pass => 0);

=head1 DESCRIPTION

The module encapsulates a keflagyword specification for xgettext like
string extractors.  It is only interesting for authors of extractors
based on L<Locale::XGettext>.

=head1 CONSTRUCTORS

=over 4

=item B<new ARGS>

Creates a new flag definition.  B<ARGS> must be a has (or a sequence of
key-value pairs) with the following items:

=over 8

=item B<function>

The name of the function resp. keyword.  This is mandatory.

=item B<arg>

An integer B<N> greater than 0 for the argument number.

=item B<flag>

The name of the flag to be applied, for example "perl-brace-format"
or "no-perl-brace-format".  A possible prefix of "no-" or "pass-"
is stripped off and interpreted accordingly but only if "pass" or
"no" were not explicitely specified.

=item B<no>

The entry should be marked with "no-FLAG" instead of "FLAG".

=item B<pass>

As if "pass-FLAG" had been specified on the command-line.  This is
ignored by L<Locale::XGettext>.

=back

=item B<newFromString COMMAND_LINE_ARG>

B<COMMAND_LINE_ARG> has the same semantcis as the argument to
"--flag" of L<xgettext(1)>.  Note that a prefix of "pass-" is
ignored by L<Locale::XGettext>!

=back

=head1 METHODS

=over 4

=item B<function>

Get the function name for the keyword.

=item B<arg>

Get the position of the argument.

=item B<flag>

The flag (for example "perl-brace-format", "c-format", etc.)

=item B<no>

True if entry should be marked as "no-FLAG".

=item B<pass>

True if flag was preceded by "pass-".  Ignored by L<Locale::XGettext>.

=back

=head1 COPYRIGHT

Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
all rights reserved.

=head1 SEE ALSO

L<Locale::XGettext>, L<xgettext(1)>, L<perl(1)>
