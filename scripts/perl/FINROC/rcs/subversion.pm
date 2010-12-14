package FINROC::rcs::subversion;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/GetRepositoryPrefix Checkout/;


use strict;

use Env '$FINROC_HOME';

use FINROC::messages;

sub GetRepositoryPrefix()
{
    use XML::Simple;
    my $svn_info = `svn info --xml $FINROC_HOME`;
    my %repository = %{${XMLin $svn_info}{"entry"}{"repository"}};
    return sprintf "%s", map { chomp; s/\/[^\/]*$//; $_ } $repository{"root"};
}

sub Checkout($$$$)
{
    my ($repository, $directory, $username, $password) = @_;

    $repository = sprintf "%s/%s/trunk", GetRepositoryPrefix, $repository;
    $repository =~ s/mca2\/trunk$/mca2\/branches\/mca3_experimental/; # FIXME: ONLY FOR MCA2 LEGACY
    ERRORMSG sprintf "'%s' should be used for working copy but is a file\n", $directory if -f $directory;
    ERRORMSG sprintf "'%s' already exists\n", $directory if -e $directory;
    
    my $credentials = "";
    $credentials = sprintf " --username=%s", $username if defined $username;
    $credentials .= sprintf " --password=%s", $password if defined $password;

    my $command = sprintf "svn co --ignore-externals %s %s %s", $credentials, $repository, $directory;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $? != 0;
}



1;
