# You received this file as part of Finroc
# A framework for intelligent robot control
#
# Copyright (C) Finroc GbR (finroc.org)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#----------------------------------------------------------------------
# \file    sources.pm
#
# \author  Tobias Foehst
#
# \date    2011-06-24
#
#----------------------------------------------------------------------
package FINROC::sources;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/GetAllComponents GetComponent/;


use strict;

use Env '$FINROC_HOME';
use Data::Dumper;
use XML::Simple;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

my %source_to_rank_map;
my @parsed_xml_content;
my %components;

sub GetAllComponents()
{
    return %components if %components;

    INFOMSG "Reading component lists... ";
    DEBUGMSG "\n";

    my $pad_before_first_warning = "\n";
    foreach my $source (keys %source_to_rank_map)
    {
        next unless $source ne "";

        my $offline_source = $source;
        $offline_source =~ s/[\:\/]/./g;

        if (not -f "$FINROC_HOME/.offline/$offline_source.xml" or time > ${[stat _]}[9] + 10)
        {
            my $cache = "$FINROC_HOME/.offline/$offline_source.xml";
            DEBUGMSG "Updating component information: $source\n";
            my $command = sprintf "curl -fsk --connect-timeout 5 --create-dirs -o \"%s\" %s.xml", $cache, $source;
            DEBUGMSG sprintf "Executing '%s'\n", $command;
            system $command;
            if ($?)
            {
                WARNMSG sprintf "%sCould not download component list for %s\n", $pad_before_first_warning, $source;
                $pad_before_first_warning = "";
                next unless -f "$cache";
                system "touch $cache";
            }
        }

        my $xml_content = join "", `cat "$FINROC_HOME/.offline/$offline_source.xml" 2> /dev/null`;

        if ($xml_content eq "")
        {
            WARNMSG sprintf "%sNo components found for %s\n", $pad_before_first_warning, $source;
            $pad_before_first_warning = "";
            next;
        }

        DEBUGMSG sprintf "XML Content: \n%s\n", $xml_content;

        push @parsed_xml_content, XMLin($xml_content,
                                        KeyAttr => [],
                                        NormalizeSpace => 2,
                                        SuppressEmpty => 1,
                                        ForceArray => [ 'component'] );

        DEBUGMSG sprintf "parsed_content:\n%s\n", Dumper \@parsed_xml_content;

        foreach my $component (@{${$parsed_xml_content[$#parsed_xml_content]}{'component'}})
        {
            my $name = $$component{'name'};
            delete $$component{'name'};
            $$component{'source'} = $source;
            if (exists $components{$name})
            {
                my %other = %{$components{$name}};
                ERRORMSG sprintf "Found multiple declaration of %s at %s!\nPlease file a bugreport and/or remove the broken entry from your sources.list\n", $name, $source if $source eq $other{'source'};

#                WARNMSG sprintf "Declaration of component %s (%s) from %s differs from declaration found at %s\n", $name, $$component{'url'}, $source, $other{'source'} if $other{'description'} ne $$component{'description'};

                delete $components{$name} if $source_to_rank_map{$source} < $source_to_rank_map{$other{'source'}};
            }
            $components{$name} = $component unless exists $components{$name};
        }
    }

#    map { map { delete $$_{'source'} } @{$components{$_}} } keys %components;

    DEBUGMSG sprintf "components:\n%s\n", Dumper \%components;

    INFOMSG "Done.\n";

    return %components;
}

sub GetComponent($)
{
    my ($name) = @_;

    my %components = GetAllComponents;

    DEBUGMSG sprintf "component '%s':\n%s\n", $name, Dumper \%{$components{$name}};
    return %{$components{$name}};
}



my $sources_list_filename = "$FINROC_HOME/etc/sources.list";

ERRORMSG sprintf "File '%s' does not exist!\n", $sources_list_filename unless -f $sources_list_filename;

DEBUGMSG sprintf "Using file %s\n", $sources_list_filename;

my $rank = 0;
foreach my $source (map { chomp; $_ } `cat "$sources_list_filename"`)
{
    $source =~ s/^\s*//;
    $source =~ s/\s*$//;
    $source =~ s/#.*//;

    next unless $source ne "";

    my ($prefix, $distribution, @categories) = split " ", $source;
    ERRORMSG sprintf "Distribution not specified in '%s'!\n", $sources_list_filename unless $distribution;
    ERRORMSG sprintf "No category specified in '%s'!\n", $sources_list_filename unless @categories;
    map { $source_to_rank_map{join "/", $prefix, $distribution, $_} = $rank; } @categories;
    $rank++;
}



1;
