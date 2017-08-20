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

package Locale::XGettext::Util::Keyword;

use strict;

use Locale::TextDomain qw(Locale-XGettext);

sub new {
    my ($class, $method, @args) = @_;

    die __x("Invalid method name '{method}'!\n", method => $method)
        if $method !~ /^[a-zA-Z][_a-zA-Z0-9]*$/;
   
    
    my %seen;
    my $comment;
    my $comment_seen;
    my $context_seen;
    my $self = {
    	method => $method,
        singular => 0,
        plural => 0,
    };
        
    foreach my $arg (@args) {
        $arg = 1 if !defined $arg;
        $arg = 1 if !length $arg;
        if ($arg =~ /^([1-9][0-9]*)(c?)$/) {
            my ($pos, $is_ctx) = ($1, $2);
            die __x("Multiple meanings for argument #{num} for method '{method}'!\n",
                     method => $method, num => $pos)
    		    if ($seen{$pos}++);
    		if ($is_ctx) {
                die __x("Multiple context arguments for method '{method}'!\n",
                         method => $method) 
                    if $context_seen++;
                $self->{context} = $pos;
            } elsif ($self->{plural}) {
                die __x("Too many forms for '{method}'!\n",
                        method => $method); 
    		} elsif ($self->{singular}) {
    		    $self->{plural} = $pos;
    		} else {
                $self->{singular} = $pos;
            }
        } elsif ($arg =~ /^"(.*)"$/) {
              die __x("Multiple automatic comments for method '{method}'!\n",
                      method => $method)
                  if $comment_seen++;
              $self->{comment} = $1;
    	} else {
              die __x("Invalid argument specification '{spec}' for method '{method}'!\n",
                      method => $method, spec => $arg);
    	}
    }

    $self->{singular} ||= 1;

    bless $self, $class;
}

sub newFromString {
	my ($class, $spec) = @_;
	
    my ($method, $string) = split /:/, $spec, 2;
    $method =~ s/^\s+//;
    $method =~ s/\s+$//;
    
    die __x("Invalid method name in keyword specification '{spec}'!\n",
            spec => $spec)
        if $method !~ /^[a-zA-Z][_a-zA-Z0-9]*$/;
        
	$string = '' if !defined $string;
	
	
	my @tokens;
    push @tokens, '' if $string =~ s/^,//;
    my @chunks = split /(\s*".*"\s*|[^,]*)/, $string;
    for (my $i = 0; $i < @chunks; $i += 2) {
        my $token = $chunks[$i + 1];
        $token =~ s/^\s+//;

        if ($token =~ s/^(".*")\s*$//) {
            # This is what GNU xgettext does.
            $token = $1;
            $token =~ s/"//g;
            $token = qq{"$token"};
        }
        push @tokens, $token;
    }
	
	@tokens = (1) if !@tokens;
	
	return $class->new($method, @tokens);
}

sub method {
    shift->{method};
}

sub singular {
	shift->{singular};
}

sub plural {
    shift->{plural}
}

sub context {
	shift->{context};
}

sub comment {
    shift->{comment};
}

1;

=head1 NAME

Locale::XGettext::Util::Keyword - A Keyword Used By xgettext

=head1 SYNOPSIS

    use Locale::XGettext::Util::Keyword;

    $keyword = Locale::XGettext::Keyword->new('npcgettext',
                                              '1c', 2, 3,
                                              '"Plural form"');
    $keyword = Locale::XGettext::Keyword->newFromString('npcgettext:1c,2,3,"Plural form"');

Flags are not yet supported.

=head1 DESCRIPTION

The module encapsulates a keyword specification for xgettext like
string extractors.  It is only interesting for authors of extractors
based on L<Locale::XGettext>.

=head1 CONSTRUCTORS

=over 4

=item B<new METHOD[, ARGSPEC ...]>

Creates a new keyword for method B<METHOD>.  Without B<ARGSPEC> it is assumed
that the singular form is the first argument.

B<ARGSPEC> can be one of the following:

=over 8

=item B<N>

An integer B<N> greater than 0.  The first one encountered specifies the 
position of the singular form, the second one the position of the plural 
form.

=item B<Nc>

An integer B<N> greater than 0 followed by the character "c".  B<N> specifies
the position of the message context argument.

=item B<"COMMENT">

Every PO entry for this keyword should get the automatic comment 
B<COMMENT>.  Note that the surroudning "double quotes" are required!

=back

=item B<newFromString COMMAND_LINE_ARG>

B<COMMAND_LINE_ARG> has the same semantcis as the argument to
"--keyword" of L<xgettext(1)>.

=back

=head1 METHODS

=over 4

=item B<method>

Get the method name of the keyword.

=item B<singular>

Get the position of the argument for the singular form.

=item B<plural>

Get the position of the argument for the plural form or 0 if there is no
plural form.

=item B<context>

Get the position of the argument for the plural form or 0 if there is no
plural form.

=item B<comment>

The automatic comment for this keyword or the undefined value.

=back

=head1 COPYRIGHT

Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>,
all rights reserved.

=head1 SEE ALSO

L<Locale::XGettext>, L<xgettext(1)>, L<perl(1)>
