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
    my @forms;
    my $self = {
    	method => $method,
        forms => \@forms,
    };
    
    # If you specify just the method name on the commandline you want to
    # extract the first argument.
    if (!@args || (1 == @args && (!defined $args[0] || '' eq $args[0]))) {
    	@args = '1';
    }
    
    foreach my $arg (@args) {
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
    		} else {
    		    push @forms, $pos;
                die __x("Too many forms for '{method}'!\n",
                        method => $method) 
                    if @forms > 2;
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

sub forms {
	shift->{forms};
}

sub context {
	shift->{context};
}

sub comment {
    shift->{comment};
}

1;
