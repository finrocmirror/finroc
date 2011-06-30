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
use Storable qw(dclone);

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

        my $command = sprintf "curl -fsk %s.xml", $source;

        DEBUGMSG sprintf "Executing '%s'\n", $command;

        my $xml_content = join "", `$command`;

	my $offline_source = $source;
	$offline_source =~ s/[\:\/]/./g;
	if ($? == 0)
	{
	    mkdir "$FINROC_HOME/.offline" unless -d "$FINROC_HOME/.offline";
	    open OFFLINE, ">$FINROC_HOME/.offline/$offline_source.xml" or ERRORMSG "Could not open offline file to write: $!\n";
	    print OFFLINE $xml_content;
	    close OFFLINE;
	}
	else
	{
	    $xml_content = join "", `cat $FINROC_HOME/.offline/$offline_source.xml 2> /dev/null`;
	}

        if ($xml_content eq "")
        {
            WARNMSG sprintf "%sNo components found at %s\n", $pad_before_first_warning, $source;
            $pad_before_first_warning = "";
            next;
        }

        DEBUGMSG sprintf "XML Content: \n%s\n", $xml_content;

        push @parsed_xml_content, XMLin($xml_content,
                                        KeyAttr => [],
#                                        ForceArray => [ "dependencies", "optional_dependencies", "manifest" ],
#                                        ForceContent => [ "dependencies", "optional_dependencies" ],
                                        NormalizeSpace => 2,
                                        SuppressEmpty => 1);

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
foreach my $source (map { chomp; $_ } `cat $sources_list_filename`)
{
    $source =~ s/^\s*//;
    $source =~ s/\s*$//;
    $source =~ s/#.*//;

    next unless $source ne "";

    my ($prefix, @group) = split " ", $source;
    push @group, "main" unless @group;
    map { $source_to_rank_map{sprintf "%s/%s", $prefix, $_} = $rank; } @group;
    $rank++;
}



1;
