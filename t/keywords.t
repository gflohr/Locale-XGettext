#! /usr/bin/env perl

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

use strict;

use Test::More tests => 15;

BEGIN {
    my $test_dir = __FILE__;
    $test_dir =~ s/[-a-z0-9]+\.t$//i;
    chdir $test_dir or die "cannot chdir to $test_dir: $!";
    unshift @INC, '.';
}

use TestLib qw(use_keywords);

my (%keywords, $okay);

%keywords = (foo => ['']);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

%keywords = (foo => [''], bar => ['1']);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

# Invalid method name.
%keywords = ('foo bar' => ['']);
$okay = eval { use_keywords \%keywords };
ok !$okay;

# Too many elements.
%keywords = (foo => ['1', '2', '3', '4', '5']);
$okay = eval { use_keywords \%keywords };
ok !$okay;

# Extract first argument.
%keywords = (foo => []);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

# The same. 
%keywords = (foo => [undef]);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

# And again the same. 
%keywords = (foo => ['']);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

# Scalar.
%keywords = (foo => '1c,2,3');
$okay = eval { use_keywords \%keywords };
ok !$okay;

# Hash reference. 
%keywords = (foo => {});
$okay = eval { use_keywords \%keywords };
ok !$okay;

# Multiple specifications of position.
%keywords = (foo => ['1c', 3, 1]);
$okay = eval { use_keywords \%keywords };
ok !$okay;

# Automatic comments.
%keywords = (foo => ['1', '"a comment"']);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

# No strict syntax for automatic comments.
%keywords = (foo => ['1', '"a "comment""']);
$okay = eval { use_keywords \%keywords };
ok $okay, $@;

# Multiple comments.
%keywords = (foo => ['1', '"a comment"', '"another comment"']);
$okay = eval { use_keywords \%keywords };
ok !$okay, $@;

# Multiple context specifications.
%keywords = (foo => ['1c', 2, '3c']);
$okay = eval { use_keywords \%keywords };
ok !$okay, $@;

# Ambiguous
%keywords = (foo => [1, '', 3]);
$okay = eval { use_keywords \%keywords };
ok !$okay;
