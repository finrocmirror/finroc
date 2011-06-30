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
# \file    terminal.pm
#
# \author  Tobias Foehst
#
# \date    2010-06-30
#
#----------------------------------------------------------------------
package FINROC::terminal;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/SetCursorPositionSequence MoveCursorInRowSequence MoveCursorInColumnSequence ClearScreenSequence ClearEndOfLineSequence/;


use strict;


sub SetCursorPositionSequence($$)
{
    my ($row, $column) = @_;
    return sprintf "\033[%d;%sH", $row, $column;
#    return sprintf "\033[%d;%sf", $row, $column;
}

sub MoveCursorInColumnSequence($)
{
    my ($step) = @_;
    return sprintf "\033[%d%s", abs $step, $step < 0 ? 'A' : 'B';
}

sub MoveCursorInRowSequence($)
{
    my ($step) = @_;
    return sprintf "\033[%d%s", abs $step, $step < 0 ? 'D' : 'C';
}

sub ClearScreenSequence()
{
    return "\033[2J";
}

sub ClearEndOfLineSequence()
{
    return "\033[K";
}
