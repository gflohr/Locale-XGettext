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

use Test::More tests => 13;

use Locale::XGettext::Text;

BEGIN {
    my $test_dir = __FILE__;
    $test_dir =~ s/[-a-z0-9]+\.t$//i;
    chdir $test_dir or die "cannot chdir to $test_dir: $!";
    unshift @INC, '.';
}

use TestLib qw(find_entries);

my ($xgettext, @po);

my $entry = { msgid => 'Hello, world!'};

$xgettext = Locale::XGettext::Test->new;
$xgettext->_feedEntry($entry, <<EOF);
TRANSLATORS: There was no comment keyword specified!
EOF
@po = $xgettext->run->po;
is scalar @po, 2;
ok !defined $po[1]->automatic, "no comment keyword specified";

my $comment1 = "TRANSLATORS: This comment should go into the PO file!\n";
$xgettext = Locale::XGettext::Test->new({add_comments => ['TRANSLATORS:']});
$xgettext->_feedEntry($entry, $comment1);
@po = $xgettext->run->po;
is scalar @po, 2;
is $po[1]->automatic, $comment1, "regular comment";

$xgettext = Locale::XGettext::Test->new({add_comments => ['TRANSLATORS:',
                                                          'CODERS:']});
my $multi_comment = <<EOF;
Leading garbage
More leading garbage TRANSLATORS: Where should this go?
garbage againxgettext: no-perl-brace-format c-format trailing garbage
Into the PO file!
EOF
$xgettext->_feedEntry($entry, $multi_comment);
my $comment2 = "CODERS: Think before you type!\n";
my $entry2 = { msgid => "Hello, underworld!" };
$xgettext->_feedEntry($entry2, $comment2);
@po = $xgettext->run->po;
is scalar @po, 3;
is $po[1]->automatic, <<EOF, "interrupted comment";
TRANSLATORS: Where should this go?
Into the PO file!
EOF
is $po[2]->automatic, <<EOF, "2nd comment keyword";
CODERS: Think before you type!
EOF

$xgettext = Locale::XGettext::Test->new({add_comments => ['TRANSLATORS:']});
my $multi_comment2 = <<EOF;
TRANSLATORS: You can use
The string "xgettext:" in order to set flags in comments.
EOF
$xgettext->_feedEntry($entry, $multi_comment2);
@po = $xgettext->run->po;
is scalar @po, 2;
is $po[1]->automatic, $multi_comment2, '"xgettext:" without valid flags';

$xgettext = Locale::XGettext::Test->new({keyword => ['greet:1,"Hello!"']});
$xgettext->_feedEntry({msgid => 'world', keyword => 'greet'});
@po = $xgettext->run->po;
is scalar @po, 2;
is $po[1]->automatic, "Hello!", "automatic keyword comment not used";

$xgettext = Locale::XGettext::Test->new({keyword => ['greet:1,"world!"'],
                                         add_comments => ['TRANSLATORS:']});
my $comment3 = "TRANSLATORS: Hello,";
$DB::single = 1;
$xgettext->_feedEntry({msgid => 'world', keyword => 'greet'}, $comment3);
@po = $xgettext->run->po;
is scalar @po, 2;
is $po[1]->automatic, "TRANSLATORS: Hello,\nworld!", 
   "automatic comments not joined";
