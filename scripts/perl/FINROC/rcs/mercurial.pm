package FINROC::rcs::mercurial;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/GetRepositoryPrefix Checkout/;


use strict;

use Env '$FINROC_HOME';

use FINROC::messages;

END
{
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    system "finroc_update_hg_hooks &> /dev/null";
    chdir $working_directory;
}

sub GetRepositoryPrefix()
{
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    my $result = sprintf "%s", map { chomp; s/.*=\s*//; s/\/[^\/]*$//; $_ } `hg paths | grep "default ="`;
    chdir $working_directory;
    return $result;
}

sub Checkout($$)
{
    my ($repository, $directory) = @_;

    my $branch = "trunk";
    $branch = "mca3_experimental" if $repository eq "mca2"; # FIXME: ONLY FOR MCA2 LEGACY

    $repository = sprintf "%s/%s", GetRepositoryPrefix, $repository;
    ERRORMSG sprintf "'%s' should be used for working copy but is a file\n", $directory if -f $directory;
    ERRORMSG sprintf "'%s' already exists\n", $directory if -e $directory;

    my $directory_base = $directory;
    $directory_base =~ s/\/[^\/]*$//;
    DEBUGMSG sprintf "Creating directory '%s'\n", $directory_base;
    mkdir $directory_base;

    my $command = sprintf "hg clone --noupdate %s %s", $repository, $directory;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $? != 0;

    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $directory;
    $command = sprintf "hg update --clean %s", $branch;
    INFOMSG sprintf "Executing '%s' in '%s'\n", $command, $directory;
    system $command;
    chdir $working_directory;
    ERRORMSG "Command failed!\n" if $? != 0;
}



1;
