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
# \file    hg.pm
#
# \author  Tobias Foehst
#
# \date    2010-05-27
#
#----------------------------------------------------------------------
package FINROC::rcs::hg;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw//;
@EXPORT_OK = qw/Checkout Update/;


use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

END
{
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    system "scripts/tools/update_hg_hooks";
    chdir $working_directory;
}

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;

    my $branch = "default";

    my $target_base = $target;
    $target_base =~ s/\/[^\/]*$//;
    DEBUGMSG sprintf "Creating directory '%s'\n", $target_base;
    system "mkdir -p $target_base";
    ERRORMSG "Command failed!\n" if $?;

    my $command = sprintf "hg clone %s %s", $url, $target;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $command = sprintf "hg --cwd %s in", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    return "." if $?;

    $command = sprintf "hg --cwd %s pull", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG "Command failed!\n" if $?;

    $command = sprintf "hg --cwd %s st -q", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "M" unless $output eq "";

    $command = sprintf "hg --cwd %s out", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "O" unless $?;

    $command = sprintf "hg --cwd %s update", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "C" if $?;

    return "U";
}

sub Status($$$)
{
    my ($directory, $local_modifications_only, $incoming) = @_;

    my $result = "";

    if ($incoming)
    {
        my $command = sprintf "hg --cwd %s in", $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        my $output = join "", `$command`;
        DEBUGMSG $output;
        $result .= sprintf "%sIncoming changesets:\n\n%s\n", ($result ne "" ? "\n" : ""), join "\n", grep { /^(changeset|user|date|summary)\:/ or /^$/ } split "\n", $output unless $?;
    }

    unless ($local_modifications_only)
    {
        my $command = sprintf "hg --cwd %s out", $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        my $output = join "", `$command`;
        DEBUGMSG $output;
        $result .= sprintf "%sOutgoing changesets:\n\n%s\n", ($result ne "" ? "\n" : ""), join "\n", grep { /^(changeset|date|summary)\:/ or /^$/ } split "\n", $output unless $?;
    }

    my $command = sprintf "hg --cwd %s st", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG "Command failed!\n" if $?;
    $result .= sprintf "%sLocal modifications:\n%s", ($result ne "" ? "\n" : ""), $output unless $output eq "";

    return $result;
}



1;
