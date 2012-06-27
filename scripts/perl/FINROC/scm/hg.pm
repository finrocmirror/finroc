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
use UI;

END
{
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    system "scripts/tools/update_hg_hooks";
    chdir $working_directory;
    exit ErrorOccurred;
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
    DEBUGMSG $output;
    return $output ne "" ? $output : undef;
}

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;
    
    my $branch = "default";

    my $credentials = CredentialsForCommandLine $url, $username, $password;

    my $target_base = $target;
    $target_base =~ s/\/[^\/]*$//;
    DEBUGMSG sprintf "Creating directory '%s'\n", $target_base;
    system "mkdir -p $target_base";
    ERRORMSG "Command failed!\n" if $?;

    my $command = sprintf "hg %s clone %s \"%s\"", $credentials, $url, $target;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $default_path = GetPath $directory, "default";
    return "Update source not defined" unless defined $default_path;

    my $credentials = CredentialsForCommandLine $default_path, $username, $password;

    my $command = sprintf "hg %s --cwd \"%s\" in -q", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    return "Up to date" if $?;

    $command = sprintf "hg --cwd \"%s\" st -q", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    return "Modified working copy" unless $output eq "";

    $command = sprintf "hg %s --cwd \"%s\" out -q", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    return "Outgoing changesets" unless $?;

    $command = sprintf "hg %s --cwd \"%s\" pull -q", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;

    $command = sprintf "hg --cwd \"%s\" update", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "Conflicts" if $?;

    return "Updated";
}

sub Status($$$$$)
{
    my ($directory, $local_modifications_only, $incoming, $username, $password) = @_;

    my $result = "";

    my $pull_path = GetPath $directory, "default";
    my $push_path = GetPath $directory, "default-push";
    $push_path = $pull_path unless defined $push_path;

    if (defined $pull_path and $incoming)
    {
        my $credentials = CredentialsForCommandLine $pull_path, $username, $password;

        my $command = sprintf "hg %s --cwd \"%s\" in", $credentials, $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        my $output = join "", `$command`;
        DEBUGMSG $output;
        $result .= sprintf "%sIncoming changesets:\n\n%s\n", ($result ne "" ? "\n" : ""), join "\n", grep { /^(changeset|user|date|summary)\:/ or /^$/ } split "\n", $output unless $?;
    }

    if (defined $push_path and not $local_modifications_only)
    {
        my $credentials = CredentialsForCommandLine $push_path, $username, $password;

        my $command = sprintf "hg %s --cwd \"%s\" out", $credentials, $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        my $output = join "", `$command`;
        DEBUGMSG $output;
        $result .= sprintf "%sOutgoing changesets:\n\n%s\n", ($result ne "" ? "\n" : ""), join "\n", grep { /^(changeset|date|summary)\:/ or /^$/ } split "\n", $output unless $?;
    }

    my $command = sprintf "hg --cwd \"%s\" st", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG "Command failed!\n" if $?;
    $result .= sprintf "%sLocal modifications:\n%s", ($result ne "" ? "\n" : ""), $output unless $output eq "";

    return $result;
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $command = sprintf "hg --cwd \"%s\" branch", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return "default" eq join "", map { chomp; $_ } `$command`;
}

sub ParentDateUTCTimestamp($)
{
    my ($directory) = @_;

    my $command = sprintf "hg --cwd \"%s\" parent --template '{date}'", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return int join "", map { /^(.*)((-|\+).*)$/ ? $1 + $2 : $_ } `$command`;
}



1;
