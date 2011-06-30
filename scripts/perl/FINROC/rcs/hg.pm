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
package FINROC::rcs::hg;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw//;
@EXPORT_OK = qw/Checkout/;


use strict;

use Env '$FINROC_HOME';
use Data::Dumper;

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;

END
{
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    system "finroc_update_hg_hooks &> /dev/null";
    chdir $working_directory;
}

#sub GetRepositoryPrefix()
#{
#    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
#    chdir $FINROC_HOME;
#    my $result = sprintf "%s", map { chomp; s/.*=\s*//; s/\/[^\/]*$//; $_ } `hg paths | grep "default ="`;
#    chdir $working_directory;
#    return $result;
#}

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;

    my $branch = "default";

    my $target_base = $target;
    $target_base =~ s/\/[^\/]*$//;
    DEBUGMSG sprintf "Creating directory '%s'\n", $target_base;
    system "mkdir -p $target_base";
    ERRORMSG "Command failed!\n" if $? != 0;

    my $command = sprintf "hg clone --noupdate %s %s", $url, $target;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $? != 0;

    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $target;
    $command = sprintf "hg update --clean %s", $branch;
    INFOMSG sprintf "Executing '%s' in '%s'\n", $command, $target;
    system $command;
    chdir $working_directory;
    ERRORMSG "Command failed!\n" if $? != 0;
}



1;
