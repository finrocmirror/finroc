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
# \file    svn.pm
#
# \author  Tobias Foehst
#
# \date    2010-05-27
#
#----------------------------------------------------------------------
package FINROC::scm::svn;

use strict;

use Env '$FINROC_HOME';

use XML::Simple;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

sub CredentialsForCommandLine($$)
{
    my ($username, $password) = @_;

    my $credentials = "";
    $credentials = sprintf " --username='%s'", $username if defined $username;
    $credentials .= sprintf " --password='%s'", $password if defined $password;

    return $credentials;
}

sub GetDefaultBranch()
{
    return "trunk";
}

sub Checkout($$$$$)
{
    my ($url, $branch, $target, $username, $password) = @_;

    $branch = sprintf "branches/%s", $branch unless $branch eq "trunk";
    $url .= sprintf "/%s", $branch;

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn co --ignore-externals -q %s \"%s\" \"%s\"", $credentials, $url, $target;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn up --ignore-externals --accept postpone %s \"%s\"", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = shift @{[ reverse map { chomp; $_ } `$command` ]};
    if ($?)
    {
        WARNMSG sprintf "Command failed: %s\n", $command if $?;
        return "Up to date";
    }

    return $output unless $output =~ /^At revision/;

    return "Up to date";
}

sub Status($$$$$)
{
    my ($directory, $local_modifications_only, $incoming, $username, $password) = @_;

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn st --ignore-externals %s \"%s\"", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;

    return $output;
}

sub GetBranches($$$)
{
    my ($directory, $username, $password) = @_;

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn info --xml \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $root = ${XMLin join "", map { chomp; $_ } `$command`}{'entry'}{'repository'}{'root'};
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;

    $command = sprintf "svn list %s \"%s/branches\"", $credentials, $root;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my @output = map { chomp; s/\/$//; $_ } `$command`;
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;

    push @output, 'trunk';
    return @output;
}

sub SwitchBranch($$$$)
{
    my ($directory, $branch, $username, $password) = @_;

    $branch = sprintf "branches/%s", $branch unless $branch eq "trunk";

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn info --xml \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $root = ${XMLin join "", map { chomp; $_ } `$command`}{'entry'}{'repository'}{'root'};
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;

    $command = sprintf "svn switch --ignore-externals -q %s \"%s/%s\" \"%s\"", $credentials, $root, $branch, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $command = sprintf "svn info --xml \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return ${XMLin join "", map { chomp; $_ } `$command`}{'entry'}{'url'} =~ /trunk$/;
}

sub IsWorkingCopyRoot($)
{
    my ($directory) = @_;

    my $parent_directory = "$directory/..";
    return 1 unless -d "$parent_directory/.svn";

    my $command = sprintf "svn info --xml \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return ${XMLin join "", map { chomp; $_ } `$command`}{'entry'}{'repository'}{'uuid'} ne ${XMLin join "", map { chomp; $_ } `$command/..`}{'entry'}{'repository'}{'uuid'};
}

sub GetManifestFromWorkingCopy($)
{
    my ($directory) = @_;

    my $command = sprintf "svn list -R \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $result = join " ", sort grep { /[^\/]$/ } map { chomp; $_ } `$command`;
    ERRORMSG sprintf "Command failed: %s\n", $command if $?;

    return $result;
}

1;
