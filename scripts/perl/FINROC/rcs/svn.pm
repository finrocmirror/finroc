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
package FINROC::rcs::svn;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw//;
@EXPORT_OK = qw/Checkout/;

use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;

    $url .= "/trunk";
    
    my $credentials = "";
    $credentials = sprintf " --username=%s", $username if defined $username;
    $credentials .= sprintf " --password=%s", $password if defined $password;

    my $command = sprintf "svn co --ignore-externals %s %s %s", $credentials, $url, $target;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $? != 0;
}



1;