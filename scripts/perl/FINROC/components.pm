# You received this file as part of Finroc
# A framework for integrated robot control
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
# \file    components.pm
#
# \author  Tobias Foehst
#
# \date    2011-11-01
#
#----------------------------------------------------------------------
package FINROC::components;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/ComponentInfo/;


use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;


sub ComponentInfo($)
{
    my ($component_name) = @_;

    return { 'type' => "exec", 'language' => "java", 'directory' => "make_builder" } if $component_name eq "make_builder";

    my ($directory, $language, $type);
    
    my @name_parts = split "-", $component_name;
    ERRORMSG sprintf "Invalid number of '-' in source component '%s'\n", $component_name if scalar @name_parts > 2;
    $language = scalar @name_parts == 2 ? $name_parts[1] : "cpp";
    $directory = $name_parts[0];
    $type = "lib";

    $directory =~ s/^rrlib_simvis3d_resources_/..\/..\/resources\/simvis3d\//;

    if ($language eq "java")
    {
        $directory =~ s/^rrlib_/org\/rrlib\//;
        $directory =~ s/^finroc_plugins_/org\/finroc\/plugins\//;
        $directory =~ s/^finroc_libraries_/org\/finroc\/libraries\//;
        $directory =~ s/^finroc_tools_gui_plugins_/org\/finroc\/tools\/gui\/plugins\//;
        $directory =~ s/^finroc_tools_/org\/finroc\/tools\//;
        $directory =~ s/^finroc_projects_/org\/finroc\/projects\//;
        $directory =~ s/^finroc_/org\/finroc\//;
    }

    $directory =~ s/^rrlib_/rrlib\//;
    $directory =~ s/^finroc_plugins_/plugins\//;
    $directory =~ s/^finroc_libraries_/libraries\//;
    $directory =~ s/^finroc_tools_gui_plugins_/tools\/gui\/plugins\//;
    $directory =~ s/^finroc_tools_/tools\//;
    $directory =~ s/^finroc_projects_/projects\//;
    $directory =~ s/^finroc_//;

    $type = "exec" if $component_name =~ /(projects|tools)/ and $component_name !~ /plugins/;

    return { 'type' => $type, 'language' => $language, 'directory' => sprintf "sources/%s/%s", $language, $directory };
}



1;
