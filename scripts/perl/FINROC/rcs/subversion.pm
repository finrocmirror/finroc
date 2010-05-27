package FINROC::rcs::subversion;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/GetRepositoryPrefix Checkout/;


use strict;

use Env '$FINROC_HOME';

use FINROC::messages;

sub GetRepositoryPrefix()
{
    return sprintf "%s", map { chomp; s/\s*Repository Root:\s*//; s/\/[^\/]*$//; $_ } `svn info $FINROC_HOME | grep 'Repository Root: '`;
}

sub CheckoutSVN($$)
{
    my ($repository, $directory) = @_;

    $repository = sprintf "%s/%s/trunk", $repository_prefix, $repository;
    $repository =~ s/mca2\/trunk$/mca2\/branches\/mca3_experimental/; # FIXME: ONLY FOR MCA2 LEGACY
    ERRORMSG sprintf "'%s' should be used for working copy but is a file\n", $directory if -f $directory;
    ERRORMSG sprintf "'%s' already exists\n", $directory if -e $directory;

    my $command = sprintf "svn co %s %s", $repository, $directory;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $? != 0;
}



1;
