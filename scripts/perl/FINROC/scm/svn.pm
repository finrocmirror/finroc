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
use Data::Dumper;
use Time::ParseDate;
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

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;

    $url .= "/trunk";

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn co --ignore-externals %s \"%s\" \"%s\"", $credentials, $url, $target;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $credentials = CredentialsForCommandLine $username, $password;

    my $command = sprintf "svn up --ignore-externals --accept postpone -q %s \"%s\"", $credentials, $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;

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
    ERRORMSG "Command failed!\n" if $?;

    return sprintf "Local modifications:\n%s\n", $output unless $output eq "";
    return "";
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $command = sprintf "svn info --xml \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return ${XMLin join "", map { chomp; $_ } `$command`}{'entry'}{'url'} =~ /trunk$/;
}

sub ParentDateUTCTimestamp($)
{
    my ($directory) = @_;

    my $command = sprintf "svn info --xml \"%s\"", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return int parsedate ${XMLin join "", `$command`}{'entry'}{'commit'}{'date'};
}



1;
