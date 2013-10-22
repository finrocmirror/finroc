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
# \file    messages.pm
#
# \author  Tobias Foehst
#
# \date    2010-04-13
#
#----------------------------------------------------------------------
package FINROC::messages;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/EnableVerboseMessages INFOMSG WARNMSG ERRORMSG DEBUGMSG/;


use strict;


my $verbose = 0;

sub EnableVerboseMessages()
{
    $verbose = 1;
}

sub INFOMSG($)
{
    print STDERR @_;
}

sub WARNMSG($)
{
    print STDERR "\033[33m" if -t STDERR;
    print STDERR @_;
    print STDERR "\033[0m" if -t STDERR;
}

sub ERRORMSG($)
{
    print STDERR "\033[31m" if -t STDERR;
    print STDERR @_;
    print STDERR "\033[0m" if -t STDERR;
    exit 1;
}

sub DEBUGMSG($)
{
    return unless $verbose;
    print STDERR "\033[36m" if -t STDERR;
    print STDERR @_;
    print STDERR "\033[0m" if -t STDERR;
}



1;
