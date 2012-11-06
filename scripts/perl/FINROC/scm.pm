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
# \file    scm.pm
#
# \author  Tobias Foehst
#
# \date    2010-05-27
#
#----------------------------------------------------------------------
package FINROC::scm;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/Checkout Update Status IsOnDefaultBranch ParentDateUTCTimestamp/;


use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

use FINROC::scm::hg;
use FINROC::scm::svn;

sub GetSCMNameOfWorkingCopy($)
{
    my ($directory) = @_;

    my $scm_name;
    $scm_name = "hg" if -d "$directory/.hg";
    $scm_name = "svn" if -d "$directory/.svn";

    DEBUGMSG sprintf "Source code management system: %s\n", defined $scm_name ? $scm_name : "<unknown>";

    return $scm_name;
}

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;

    ERRORMSG sprintf "'%s' should be used for working copy but is a file\n", $target if -f $target;
    ERRORMSG sprintf "'%s' already exists\n", $target if -e $target;

    my $scm_name = @{[ reverse split "/", $url ]}[1];

    ERRORMSG sprintf "Could not determine source code management system for URL '%s'!\n", $url unless defined $scm_name and $scm_name ne "";

    $url = sprintf "'%s'", $url;
    $target = sprintf "'%s'", $target;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    eval sprintf "FINROC::scm::%s::Checkout(%s, %s, %s, %s)", $scm_name, $url, $target, $username, $password;
    ERRORMSG $@ if $@;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $scm_name = GetSCMNameOfWorkingCopy $directory;

    return "Update source not defined" unless defined $scm_name;

    $directory = sprintf "'%s'", $directory;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::Update(%s, %s, %s)", $scm_name, $directory, $username, $password;
    ERRORMSG $@ if $@;

    return $result;
}

sub Status($$$$$)
{
    my ($directory, $local_modifications_only, $incoming, $username, $password) = @_;

    my $scm_name = GetSCMNameOfWorkingCopy $directory;

    return "Unmanaged" unless defined $scm_name;

    $directory = sprintf "'%s'", $directory;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::Status(%s, %d, %d, %s, %s)", $scm_name, $directory, $local_modifications_only, $incoming, $username, $password;
    ERRORMSG $@ if $@;

    return $result;
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $scm_name = GetSCMNameOfWorkingCopy $directory;

    ERRORMSG sprintf "Could not determine source control management system in '%s'!\n", $directory unless defined $scm_name and $scm_name ne "";

    $directory = sprintf "'%s'", $directory;

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::IsOnDefaultBranch(%s)", $scm_name, $directory;
    ERRORMSG $@ if $@;

    return $result;
}

sub ParentDateUTCTimestamp($)
{
    my ($directory) = @_;

    my $scm_name = GetSCMNameOfWorkingCopy $directory;

    ERRORMSG sprintf "Could not determine source control management system in '%s'!\n", $directory unless defined $scm_name and $scm_name ne "";

    $directory = sprintf "'%s'", $directory;

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::ParentDateUTCTimestamp(%s)", $scm_name, $directory;
    ERRORMSG $@ if $@;

    return $result;
}



1;
