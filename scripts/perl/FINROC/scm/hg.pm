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
# \file    hg.pm
#
# \author  Tobias Foehst
#
# \date    2010-05-27
#
#----------------------------------------------------------------------
package FINROC::scm::hg;

use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use open qw(:std :utf8);

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

END
{
    local $?;
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    system "scripts/tools/update_hg_hooks";
    chdir $working_directory;
}

sub CredentialsForCommandLine($$$)
{
    my ($url, $username, $password) = @_;

    my $credentials = "";
    $credentials .= sprintf " --config auth.finroc.prefix='%s'", $url if defined $username or defined $password;
    $credentials .= sprintf " --config auth.finroc.username='%s'", $username if defined $username;
    $credentials .= sprintf " --config auth.finroc.password='%s'", $password if defined $password;

    return $credentials;
}

sub GetPath($$)
{
    my ($directory, $path_alias) = @_;

    my $command = sprintf "hg --cwd \"%s\" path %s", $directory, $path_alias;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", map { chomp; $_ } `$command 2> /dev/null`;
    DEBUGMSG "$output\n";
    return $output ne "" ? $output : undef;
}

sub GetDefaultBranch()
{
    return "default";
}

sub Checkout($$$$$)
{
    my ($url, $branch, $target, $username, $password) = @_;

    my $credentials = CredentialsForCommandLine $url, $username, $password;

    my $command = sprintf "hg %s clone -U %s \"%s\"", $credentials, $url, $target;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;

    return if int(`hg --cwd "$target" tip --template '{rev}'`) == -1;

    $command = sprintf "hg --cwd \"%s\" up %s -q", $target, $branch;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    if ($?)
    {
        system "rm -rf \"$target\"";
        ERRORMSG "Command failed!\n";
    }
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $default_path = GetPath $directory, "default";
    return "Update source not defined" unless defined $default_path;

    my $credentials = CredentialsForCommandLine $default_path, $username, $password;

    my $command = sprintf "hg %s --cwd \"%s\" pull -q", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    if ($?)
    {
        WARNMSG "Command failed!\n";
        return "Up to date";
    }

    $command = sprintf "hg --cwd \"%s\" heads \$(hg --cwd \"%s\" branch) --template '{rev}\\n'", $directory, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my @heads = map { chomp; int($_) } `$command 2> /dev/null`;
    DEBUGMSG sprintf "%s\n", join "\n", @heads;
    return "Up to date" unless @heads;

    $command = sprintf "hg --cwd \"%s\" parent --template '{rev}\\n'", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $parent = `$command`;
    ERRORMSG "Command failed!\n" if $?;

    if (@heads > 1)
    {
        return "Multiple heads";
    }

    return "Up to date" if $parent && int($parent) == $heads[0];

    $command = sprintf "hg --cwd \"%s\" update -c -q", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command 2> /dev/null`;
    DEBUGMSG $output;
    return "Uncommitted changes" if $?;

    return "Updated";
}

sub Status($$$$$)
{
    my ($directory, $local_modifications_only, $incoming, $username, $password) = @_;

    my $pull_path = GetPath $directory, "default";
    my $push_path = GetPath $directory, "default-push";
    $push_path = $pull_path unless defined $push_path;

    my $headline = 0;
    if (defined $pull_path and $incoming)
    {
        my $credentials = CredentialsForCommandLine $pull_path, $username, $password;

        my $command = sprintf "hg %s --cwd \"%s\" in -b \$(hg --cwd \"%s\" branch)", $credentials, $directory, $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        INFOMSG " Incoming changes:\n";
        system $command;
        $headline = 1;
    }

    if (defined $push_path and not $local_modifications_only)
    {
        my $credentials = CredentialsForCommandLine $push_path, $username, $password;

        my $command = sprintf "hg %s --cwd \"%s\" out", $credentials, $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        INFOMSG " Outgoing changes:\n";
        system $command;
        $headline = 1;
    }

    my $command = sprintf "hg --cwd \"%s\" st", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG "Command failed!\n" if $?;

    $output = " Status of working directory:\n".$output."\n" if $output and $headline;
    return $output;
}

sub GetBranches($$$)
{
    my ($directory, $username, $password) = @_;

    my $command = sprintf "hg --cwd \"%s\" branches", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my @output = map { ${[ split " ", $_ ]}[0] } `$command`;
    ERRORMSG "Command failed!\n" if $?;

    return @output;
}

sub SwitchBranch($$$$)
{
    my ($directory, $branch, $username, $password) = @_;

    my $command = sprintf "hg --cwd \"%s\" branch %s > /dev/null 2>&1 || hg --cwd \"%s\" update -c %s -q", $directory, $branch, $directory, $branch;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system "$command 2> /dev/null";
    ERRORMSG "Command failed!\n" if $?;

    Update $directory, $username, $password;
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $command = sprintf "hg --cwd \"%s\" branch", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return "default" eq join "", map { chomp; $_ } `$command`;
}

sub IsWorkingCopyRoot($)
{
    my ($directory) = @_;
    return -d "$directory/.hg";
}

sub GetManifestFromWorkingCopy($)
{
    my ($directory) = @_;

    my $command = sprintf "hg --cwd \"%s\" manifest", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $result = join " ", sort map { chomp; $_ } `$command 2> /dev/null`;
    ERRORMSG "Command failed!\n" if $?;

    return $result;
}

1;
