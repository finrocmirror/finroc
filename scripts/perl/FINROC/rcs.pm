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
# \file    rcs.pm
#
# \author  Tobias Foehst
#
# \date    2010-05-27
#
#----------------------------------------------------------------------
package FINROC::rcs;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/Checkout/;


use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;

    ERRORMSG sprintf "'%s' should be used for working copy but is a file\n", $target if -f $target;
    ERRORMSG sprintf "'%s' already exists\n", $target if -e $target;

    my $rcs_name = @{[ reverse split "/", $url ]}[1];

    ERRORMSG sprintf "Could not determine revision control system for URL '%s'!\n", $url unless defined $rcs_name and $rcs_name ne "";;
    
    $url = sprintf "'%s'", $url;
    $target = sprintf "'%s'", $target;
    $username = defined $username ? sprintf "'%s'", $username : "undef";
    $password = defined $password ? sprintf "'%s'", $password : "undef";

    eval sprintf "FINROC::rcs::%s::Checkout(%s, %s, %s, %s)", $rcs_name, $url, $target, $username, $password;
    ERRORMSG $@ if $@;
}



1;
