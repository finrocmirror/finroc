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
@EXPORT = qw/GetDefaultBranch Checkout Update Status IsOnDefaultBranch IsWorkingCopyRoot/;


use strict;
use open qw(:std :utf8);

use Env '$FINROC_HOME';

use Encode;
$FINROC_HOME = decode_utf8 $FINROC_HOME;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

use FINROC::scm::hg;
use FINROC::scm::svn;

sub GetSCMNameFromWorkingCopy($)
{
    my ($directory) = @_;

    my $scm_name;
    $scm_name = "hg" if -d "$directory/.hg";
    $scm_name = "svn" if -d "$directory/.svn";

    DEBUGMSG sprintf "Source code management system: %s\n", defined $scm_name ? $scm_name : "<unknown>";

    return $scm_name;
}

sub GetDefaultBranch($)
{
    my ($scm_name) = @_;
    my $result;
    eval sprintf "\$result = FINROC::scm::%s::GetDefaultBranch()", $scm_name;
    ERRORMSG $@ if $@;
    return $result;
}

sub Checkout($$$$$$)
{
    my ($scm_name, $url, $branch, $target, $username, $password) = @_;

    ERRORMSG sprintf "'%s' should be used for working copy but is a file\n", $target if -f $target;
    ERRORMSG sprintf "'%s' already exists\n", $target if -e $target;

    $branch = GetDefaultBranch($scm_name) unless defined $branch;
    die unless $branch;

    $url = sprintf "'%s'", $url;
    $branch = sprintf "'%s'", $branch;
    $target = sprintf "'%s'", $target;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    eval sprintf "FINROC::scm::%s::Checkout(%s, %s, %s, %s, %s)", $scm_name, $url, $branch, $target, $username, $password;
    ERRORMSG $@ if $@;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $scm_name = GetSCMNameFromWorkingCopy $directory;

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

    my $scm_name = GetSCMNameFromWorkingCopy $directory;

    return "Unmanaged" unless defined $scm_name;

    $directory = sprintf "'%s'", $directory;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::Status(%s, %d, %d, %s, %s)", $scm_name, $directory, $local_modifications_only, $incoming, $username, $password;
    ERRORMSG $@ if $@;

    return $result;
}

sub GetBranches($$$)
{
    my ($directory, $username, $password) = @_;

    my $scm_name = GetSCMNameFromWorkingCopy $directory;
    ERRORMSG sprintf "Could not determine source control management system in '%s'!\n", $directory unless defined $scm_name and $scm_name ne "";

    $directory = sprintf "'%s'", $directory;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    my @result;
    eval sprintf "\@result = FINROC::scm::%s::GetBranches(%s, %s, %s)", $scm_name, $directory, $username, $password;
    ERRORMSG $@ if $@;

    return @result;
}

sub SwitchBranch($$$$)
{
    my ($directory, $branch, $username, $password) = @_;

    my $scm_name = GetSCMNameFromWorkingCopy $directory;
    ERRORMSG sprintf "Could not determine source control management system in '%s'!\n", $directory unless defined $scm_name and $scm_name ne "";

    $branch = GetDefaultBranch($scm_name) unless defined $branch;
    die unless $branch;

    $directory = sprintf "'%s'", $directory;
    $branch = sprintf "'%s'", $branch;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    eval sprintf "FINROC::scm::%s::SwitchBranch(%s, %s, %s, %s)", $scm_name, $directory, $branch, $username, $password;
    ERRORMSG $@ if $@;
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $scm_name = GetSCMNameFromWorkingCopy $directory;
    ERRORMSG sprintf "Could not determine source control management system in '%s'!\n", $directory unless defined $scm_name and $scm_name ne "";

    $directory = sprintf "'%s'", $directory;

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::IsOnDefaultBranch(%s)", $scm_name, $directory;
    ERRORMSG $@ if $@;

    return $result;
}

sub IsWorkingCopyRoot($)
{
    my ($directory) = @_;

    my $scm_name = GetSCMNameFromWorkingCopy $directory;

    return 0 unless $scm_name;
    $directory = sprintf "'%s'", $directory;

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::IsWorkingCopyRoot(%s)", $scm_name, $directory;
    ERRORMSG $@ if $@;

    return $result;
}

sub GetManifestFromWorkingCopy($)
{
    my ($directory) = @_;

    my $scm_name = GetSCMNameFromWorkingCopy $directory;
    ERRORMSG sprintf "Could not determine source control management system in '%s'!\n", $directory unless defined $scm_name and $scm_name ne "";

    $directory = sprintf "'%s'", $directory;

    my $result;
    eval sprintf "\$result = FINROC::scm::%s::GetManifestFromWorkingCopy(%s)", $scm_name, $directory;
    ERRORMSG $@ if $@;

    return $result;
}

1;
