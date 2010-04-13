package FINROC::messages;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/EnableVerboseMessages INFOMSG WARNMSG ERRORMSG DEBUGMSG/;


use strict;


my $verbose = 0;
sub EnableVerboseMessages { $verbose = 1; }

sub INFOMSG($) { print STDERR @_; }
sub WARNMSG($) { printf STDERR "\033[33m%s\033[0m", @_; }
sub ERRORMSG($) { printf STDERR "\033[31m%s\033[0m", @_; exit 1; }
sub DEBUGMSG($) { printf STDERR "\033[36m%s\033[0m", @_ if $verbose; }



1;
