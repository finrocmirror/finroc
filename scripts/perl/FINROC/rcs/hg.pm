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

use strict;

use Term::ReadKey;
use Env '$FINROC_HOME';
use Env '$HOME';
use Env '$USER';
use Data::Dumper;

use open qw(:std :utf8);

use lib "$FINROC_HOME/scripts/perl";
use FINROC::messages;
use UI;

my %hgrc_sections;

END
{
    ReadMode 'restore';
    my $working_directory = sprintf "%s", map { chomp; $_ } `pwd`;
    chdir $FINROC_HOME;
    system "scripts/tools/update_hg_hooks";
    chdir $working_directory;
    exit ErrorOccurred;
}

sub ManageCredentials($$$)
{
    my ($url, $username, $password) = @_;
    $url =~ s/\/[^\/]*$//;

    # Check configfile and permissions
    unless (-e "$HOME/.hgrc")
    {
        INFOMSG "\nYou have not configured mercurial in $HOME/.hgrc, yet.\n";
        return unless "y" eq UI::ReadValue "Create a minimal configuration to be used with Finroc? (y|n)", '(y|n)', "y";
        open HGRC, ">$HOME/.hgrc" or die $!;
        close HGRC;
        chmod 0600, "$HOME/.hgrc";
    }
    unless ((${[stat "$HOME/.hgrc"]}[2] & 07777) == 0600)
    {
        WARNMSG "\nYour mercurial configuration in $HOME/.hgrc might contain authentication data and should not be readable by others than you!\n";
        chmod 0600, "$HOME/.hgrc" if "y" eq UI::ReadValue "Fix file permissions? (y|n)", '(y|n)', "y";
    }

    # Read config file
    unless (%hgrc_sections)
    {
        my $current_section;
        foreach (map { chomp; $_} `cat $HOME/.hgrc`)
        {
            s/^\s*//;
            s/\s*$//;
            next if $_ eq "";

            if (/^\[([^\]]+)\]$/)
            {
                $current_section = $1;
                $hgrc_sections{$current_section} = {};
                next;
            }

            if ($current_section eq "auth")
            {
                my ($key, @value) = map { s/^\s*//; s/\s*$//; $_ } split "=";
                my ($group, $entry) = split '\.', $key;
                $hgrc_sections{'auth'}{$group}{$entry} = join " ", @value;
                next;
            }

            my ($key, @value) = map { s/^\s*//; s/\s*$//; $_ } split "=";
            $hgrc_sections{$current_section}{$key} = join " ", @value;
        }
    }

    my $update_hgrc = 0;

    # Author information
    INFOMSG "\nYour author information is not specified, yet.\n" unless exists $hgrc_sections{'ui'}{'username'};
    if (exists $hgrc_sections{'ui'}{'username'} and $hgrc_sections{'ui'}{'username'} !~ /^\S+( \S+)+ <\S+@\S+(\.\S+)+>$/)
    {
        WARNMSG "\nYour author information is invalid (not following the scheme \"Full Name <Email Adress>\"\n";
        delete $hgrc_sections{'ui'}{'username'};
    }

    if (!exists $hgrc_sections{'ui'}{'username'})
    {
        my $fullname = UI::ReadValue "Full name", '\S+( \S+)+', ${[split ":", join "", map { chomp; $_ } `getent passwd \$USER`]}[4];
        my $email_addr = UI::ReadValue "Email address", '\S+@\S+(\.\S+)+', undef;
        $hgrc_sections{'ui'}{'username'} = sprintf "%s <%s>", $fullname, $email_addr;
        $update_hgrc = 1;
    }

    # Authentication data
    unless (exists $hgrc_sections{'auth'} and grep {  $_ eq substr $url, 0, length $_ } map { $hgrc_sections{'auth'}{$_}{'prefix'} } keys %{$hgrc_sections{'auth'}})
    {
        if ($url =~ /^https?:\/\//)
	{
            INFOMSG sprintf "\nYour auth data for %s will be stored in plaintext in $HOME/.hgrc which is OK as only you can read that file.\n", $url;
            INFOMSG "However, you should be careful if you edit that file when someone else could have a look at you screen!\n";
            my $auth_username = $username;
            my $auth_password = $password;
            while (1)
            {
                $auth_username = UI::ReadValue "Username", undef, $USER unless defined $auth_username;
                ReadMode 'noecho';
                $auth_password = UI::ReadValue "Password", undef, undef unless defined $auth_password;
                INFOMSG "\n";
                ReadMode 'restore';
                my $auth_test = join "", `curl -fsku '$auth_username':'$auth_password' $url`;
                if ($auth_test ne "")
                {
                    my $key = $url;
                    $key =~ s/^https?:\/\/([^\/]+)\/.*$/$1/;
                    $key =~ s/(\.|\/)/_/g;
                    $hgrc_sections{'auth'}{$key}{'prefix'} = "$url";
                    $hgrc_sections{'auth'}{$key}{'username'} = $auth_username;
                    $hgrc_sections{'auth'}{$key}{'password'} = $auth_password;
                    last;
                }
                WARNMSG sprintf "Could not authenticate to %s. Invalid username/password combination.\n", $url;
                ($auth_username, $auth_password) = (undef, undef);
            }    
            $update_hgrc = 1;
        }
    }

    # Write configfile
    if ($update_hgrc)
    {
        open HGRC, ">$HOME/.hgrc" or die $!;
        foreach my $current_section (reverse sort keys %hgrc_sections)
        {
            printf HGRC "[%s]\n", $current_section;
            if ($current_section eq "auth")
            {
                foreach my $group (keys %{$hgrc_sections{'auth'}})
                {
                    printf HGRC "%s.prefix = %s\n", $group, $hgrc_sections{'auth'}{$group}{'prefix'};
                    printf HGRC "%s.username = %s\n", $group, $hgrc_sections{'auth'}{$group}{'username'} if exists $hgrc_sections{'auth'}{$group}{'username'};
                    printf HGRC "%s.password = %s\n", $group, $hgrc_sections{'auth'}{$group}{'password'} if exists $hgrc_sections{'auth'}{$group}{'password'};
                    printf HGRC "\n";
                }
                next;
            }
            map { printf HGRC "%s = %s\n", $_, $hgrc_sections{$current_section}{$_} } keys %{$hgrc_sections{$current_section}};
            print HGRC "\n";
        }
        close HGRC;
    }
}

sub GetPath($$)
{
    my ($directory, $path_alias) = @_;
    
    my $command = sprintf "hg --cwd %s path %s", $directory, $path_alias;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", map { chomp; $_ } `$command 2> /dev/null`;
    DEBUGMSG $output;
    return $output ne "" ? $output : undef;
}

sub Checkout($$$$)
{
    my ($url, $target, $username, $password) = @_;
    
    ManageCredentials $url, $username, $password;

    my $branch = "default";

    my $target_base = $target;
    $target_base =~ s/\/[^\/]*$//;
    DEBUGMSG sprintf "Creating directory '%s'\n", $target_base;
    system "mkdir -p $target_base";
    ERRORMSG "Command failed!\n" if $?;

    my $command = sprintf "hg clone %s %s", $url, $target;
    INFOMSG sprintf "Executing '%s'\n", $command;
    system $command;
    ERRORMSG "Command failed!\n" if $?;
}

sub Update($$$)
{
    my ($directory, $username, $password) = @_;

    my $default_path = GetPath $directory, "default";
    return "_" unless defined $default_path;

    ManageCredentials $default_path, $username, $password;

    my $command = sprintf "hg --cwd %s in", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    return "." if $?;

    $command = sprintf "hg --cwd %s pull", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG "Command failed!\n" if $?;

    $command = sprintf "hg --cwd %s st -q", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "M" unless $output eq "";

    $command = sprintf "hg --cwd %s out", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "O" unless $?;

    $command = sprintf "hg --cwd %s update", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    $output = join "", `$command`;
    DEBUGMSG $output;
    return "C" if $?;

    return "U";
}

sub Status($$$)
{
    my ($directory, $local_modifications_only, $incoming) = @_;

    my $result = "";

    my $pull_path = GetPath $directory, "default";
    my $push_path = GetPath $directory, "default-push";
    $push_path = $pull_path unless defined $push_path;

    if (defined $pull_path and $incoming)
    {
        ManageCredentials $pull_path, undef, undef;
        my $command = sprintf "hg --cwd %s in", $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        my $output = join "", `$command`;
        DEBUGMSG $output;
        $result .= sprintf "%sIncoming changesets:\n\n%s\n", ($result ne "" ? "\n" : ""), join "\n", grep { /^(changeset|user|date|summary)\:/ or /^$/ } split "\n", $output unless $?;
    }

    if (defined $push_path and not $local_modifications_only)
    {
        ManageCredentials $push_path, undef, undef;
        my $command = sprintf "hg --cwd %s out", $directory;
        DEBUGMSG sprintf "Executing '%s'\n", $command;
        my $output = join "", `$command`;
        DEBUGMSG $output;
        $result .= sprintf "%sOutgoing changesets:\n\n%s\n", ($result ne "" ? "\n" : ""), join "\n", grep { /^(changeset|date|summary)\:/ or /^$/ } split "\n", $output unless $?;
    }

    my $command = sprintf "hg --cwd %s st", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;
    my $output = join "", `$command`;
    DEBUGMSG $output;
    ERRORMSG "Command failed!\n" if $?;
    $result .= sprintf "%sLocal modifications:\n%s", ($result ne "" ? "\n" : ""), $output unless $output eq "";

    return $result;
}

sub IsOnDefaultBranch($)
{
    my ($directory) = @_;

    my $command = sprintf "hg --cwd %s branch", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return "default" eq join "", map { chomp; $_ } `$command`;
}

sub ParentDateUTCTimestamp($)
{
    my ($directory) = @_;

    my $command = sprintf "hg --cwd %s parent --template '{date}'", $directory;
    DEBUGMSG sprintf "Executing '%s'\n", $command;

    return int join "", map { /^(.*)((-|\+).*)$/ ? $1 + $2 : $_ } `$command`;
}



1;
