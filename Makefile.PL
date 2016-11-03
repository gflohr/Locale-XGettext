#! /usr/bin/env perl

# Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.7.3;
use ExtUtils::MakeMaker;

push @extra, 'META_MERGE' => {
        resources => {
        	# Does not work at the moment.
            #repository => {
            #	type =>'git',
            #    url => 'git://github.com/gflohr/qgoda.git',
            #    web => 'https://github.com/gflohr/qgoda',
            #},
            repository => 'git://github.com/gflohr/locale-xgettext.git',
            bugtracker => 'https://rt.perl.org/rt3/',
            homepage   => 'http://www.guido-flohr.net/en/projects#locale-xgettext',
        },
        release_status => 'stable'
    } unless $ExtUtils::MakeMaker::VERSION < 6.46;

WriteMakefile (
    NAME                => 'Locale::XGettext',
    VERSION_FROM        => 'lib/Locale/XGettext.pm',
    ABSTRACT            => 'Extract strings into PO files in Perl',
    AUTHOR              => 'Guido Flohr <guido.flohr@cantanea.com>',
    PREREQ_PM => {
        'Locale::TextDomain' => '1.20',
        'Locale::PO' => '0.27',
    },
    EXE_FILES => [],
    PL_FILES => {},
    (MM->can ('signature_target') ? (SIGN => 1) : ()),
    LICENSE => 'lgpl',
    @extra
);

sub MY::postamble {
   	q ( 
all :: ReleaseNotes

ReleaseNotes: NEWS
	cat NEWS >$@
	);
}
