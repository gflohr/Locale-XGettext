#! /usr/bin/env perl

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

use strict;

use Test::More tests => 6;

use Locale::XGettext::Text;

my $test_dir = __FILE__;
$test_dir =~ s/[-a-z0-9]+\.t$//i;
chdir $test_dir or die "cannot chdir to $test_dir: $!";

my @po = Locale::XGettext::Text->new({}, 'files/hello.txt')->run->po;
like $po[0]->comment, qr/\nCopyright \(C\) YEAR THE PACKAGE'S COPYRIGHT HOLDER\n/;

@po = Locale::XGettext::Text->new({}, 'files/hello.txt')->run->po;
like $po[0]->comment, qr/\nThis file is distributed under the same license as the PACKAGE package.\n/;

@po = Locale::XGettext::Text->new({}, 'files/hello.txt')->run->po;
unlike $po[0]->comment, qr/\nThis file is put in the public domain\.\n/;

@po = Locale::XGettext::Text->new({foreign_user => 1}, 'files/hello.txt')
                            ->run->po;
unlike $po[0]->comment, qr/\nCopyright \(C\) YEAR THE PACKAGE'S COPYRIGHT HOLDER\n/;

@po = Locale::XGettext::Text->new({foreign_user => 1}, 'files/hello.txt')
                            ->run->po;
unlike $po[0]->comment, qr/\nThis file is distributed under the same license as the PACKAGE package.\n/;

@po = Locale::XGettext::Text->new({foreign_user => 1}, 'files/hello.txt')
                            ->run->po;
like $po[0]->comment, qr/\nThis file is put in the public domain\.\n/;

