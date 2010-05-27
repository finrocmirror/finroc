package FINROC::rcs;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/GetRCSName GetRepositoryPrefix Checkout/;


use strict;

use Env '$FINROC_HOME';

use FINROC::messages;

my $rcs_name;

BEGIN {
    $rcs_name = "svn" if -d "$FINROC_HOME/.svn";
    $rcs_name = "mercurial" if -d "$FINROC_HOME/.hg";
    ERRORMSG "Could not determine revision control system!" unless defined $rcs_name;

    eval "use FINROC::rcs::$rcs_name";

    DEBUGMSG sprintf "Using revision control system '%s'\n", $rcs_name;
}

sub GetRCSName()
{
    return $rcs_name;
}



1;
