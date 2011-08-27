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
# \file    getopt.pm
#
# \author  Tobias Foehst
#
# \date    2011-06-24
#
#----------------------------------------------------------------------
package FINROC::getopt;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/ScriptName SetHelp PrintHelp ParseCommandLine GetCommandLineOptions GetCommandLineOption AssignCommandLineOptionDefaultValue/;


use strict;

use Getopt::Long;
use Data::Dumper;

use FINROC::messages;

my %command_line_options;
my $help;

sub ScriptName()
{
    return (reverse (split "/", $0))[0];
}

sub SetHelp($$$)
{
    my ($command_line_args, $options, $additional_text) = @_;

    $command_line_args = "" unless defined $command_line_args;

    $help = sprintf "usage: %s [options] %s\n", ScriptName, $command_line_args;
    $help .= "options:\n";

    my $max_key_length = length "-v, --verbose";
    sub max($$) { my ($a, $b) = @_; return $a > $b ? $a : $b; }
    map { $max_key_length = max $max_key_length, length $_; } keys %$options;
    my $format_string = sprintf "  %%-%ds   %%s\n", $max_key_length;

    $help .= sprintf $format_string, "-h, --help", "show this help";
    $help .= sprintf $format_string, "-v, --verbose", "more output for debugging";
    foreach my $key (keys %$options)
    {
        $help .= sprintf $format_string, $key, $$options{$key};
    }
    $help .= "\n";
    $help .= sprintf "%s\n", $additional_text if defined $additional_text;
}

sub PrintHelp()
{
    INFOMSG $help;
    exit 0;
}

sub ParseCommandLine($$)
{
    my ($options, $check_optional_arguments) = @_;

    GetOptions \%command_line_options, "verbose+", "help", @$options or ERRORMSG "Parsing command line failed!\n";

    EnableVerboseMessages if defined $command_line_options{"verbose"};

    DEBUGMSG sprintf "command line options:\n%s\n", Dumper \%command_line_options;

    &$check_optional_arguments if defined $check_optional_arguments;
    PrintHelp if defined $command_line_options{"help"};
}

sub GetCommandLineOptions()
{
    return grep { $_ !~ /help|verbose/ } keys %command_line_options;
}

sub GetCommandLineOption($)
{
    my ($option_name) = @_;

    return $command_line_options{$option_name};
}

sub AssignCommandLineOptionDefaultValue($$)
{
    my ($option_name, $default_value) = @_;

    $command_line_options{$option_name} = $default_value unless defined GetCommandLineOption $option_name and GetCommandLineOption "optional" ne "";
}

SetHelp undef, undef, undef;

1;
