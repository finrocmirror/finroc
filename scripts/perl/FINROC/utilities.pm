# You received this file as part of Finroc
# A framework for intelligent robot control
# 
# Copyright (C) Finroc GbR (finroc.org)
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# 
#----------------------------------------------------------------------
# \file    utilities.pm
#
# \author  Tobias Foehst
#
# \date    2012-11-06
#
#----------------------------------------------------------------------
package FINROC::utilities;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/FindWorkingCopyBaseFolders ForEachWithProgress EscapeFinrocHome/;


use strict;

use Env '$FINROC_HOME';

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;


sub AddDirectory($$$)
{
    my ($directories, $directory, $prefix) = @_;
    return unless -d $directory;
    return if defined $prefix and $prefix ne substr $directory, 0, length $prefix;

    $$directories{$directory} = 1;
}

sub FindWorkingCopyBaseFolders
{
    my ($common_prefix) = @_;
    
    my %directories;

    AddDirectory \%directories, "$FINROC_HOME/make_builder", $common_prefix;

    map { chomp; AddDirectory \%directories, $_, $common_prefix } `find -L "$FINROC_HOME/sources" -maxdepth 4 -name "core" 2> /dev/null`;

    my @classes = ( "rrlib", "libraries", "tools", "plugins", "projects" );

    foreach my $class (@classes)
    {
        foreach my $base (map { chomp; $_ } `find -L "$FINROC_HOME/sources" -name "$class" 2> /dev/null`)
        {
            map { chomp; AddDirectory \%directories, "$base/$_", $common_prefix } `ls "$base"`;
        }
    }

    AddDirectory \%directories, "$FINROC_HOME/resources/simvis3d/abstract_objects", $common_prefix;

    @classes = ( "decoration", "environments", "humans", "robots", "sensors" );
    foreach my $class (@classes)
    {
        my $base = sprintf "$FINROC_HOME/resources/simvis3d/%s", $class;
        map { chomp; AddDirectory \%directories, "$base/$_", $common_prefix } `ls "$base" 2> /dev/null`;
    }

    AddDirectory \%directories, "$FINROC_HOME", $common_prefix;
    
    return %directories;
}

sub ForEachWithProgress($$$)
{
    my ($items, $item_description, $process_item) = @_;

    my $i = 0;
    my $format_string = sprintf "%%%dd/%d", length "".scalar @$items, scalar @$items;
    foreach my $item (@$items)
    {
        my $progress = sprintf $format_string, ++$i, scalar @$items;
        INFOMSG sprintf " [%s] %s\n", $progress, &$item_description($item);
        &$process_item($item);
    }
}

sub EscapeFinrocHome($)
{
    my ($name) = @_;
    $name =~ s/$FINROC_HOME/\$FINROC_HOME/;
    return $name;    
}



1;
