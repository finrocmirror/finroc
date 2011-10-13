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
@EXPORT = qw/EnableVerboseMessages INFOMSG WARNMSG ERRORMSG DEBUGMSG ErrorOccurred/;


use strict;


my $verbose = 0;
sub EnableVerboseMessages() { $verbose = 1; }

my $error_occurred = 0;
sub ErrorOccurred() { return $error_occurred; }

sub INFOMSG($) { print STDERR @_; }
sub WARNMSG($) { printf STDERR "\033[33m%s\033[0m", @_; }
sub ERRORMSG($) { printf STDERR "\033[31m%s\033[0m", @_; $error_occurred = 1; exit 1; }
sub DEBUGMSG($) { printf STDERR "\033[36m%s\033[0m", @_ if $verbose; }



1;
