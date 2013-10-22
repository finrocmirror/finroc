# You received this file as part of Finroc
# A framework for intelligent robot control
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
# \file    UI.pm
#
# \author  Tobias Foehst
#
# \date    2011-10-26
#
#----------------------------------------------------------------------
package FINROC::UI;

use strict;

use UI::Dialog::Console;
use Switch;
use File::Basename;
use File::Path;

my $WIDTH = 72;
my $HEIGHT = 24;

my $dialog;

sub Abort()
{
    printf "Aborted!\n\n";
    exit 1;
}

sub HeightFromText($)
{
    my ($text) = @_;
    my $result = 7 + int(0.5 + 1.0 / $WIDTH * length $text);
    return $result unless $result > $HEIGHT;
    return $HEIGHT;
}

sub InitializeDialog($)
{
    my ($backtitle) = @_;

    $dialog = new UI::Dialog::Console(
        backtitle => $backtitle,
        title => "",
        width => $WIDTH,
        debug => 0);
}

sub Message($$)
{
    my ($title, $text) = @_;

    $dialog->msgbox(
        title => " $title ",
        text => $text,
        height => HeightFromText $text) or Abort;
}

sub InputText($$$$)
{
    my ($title, $text, $pattern, $default) = @_;

    while (1)
    {
        my $input = $dialog->inputbox(
            title => " $title ",
            text => $text,
            entry => $default,
            height => HeightFromText $text);
        $dialog->state eq "OK" or Abort;

        utf8::decode $input;
        utf8::upgrade $input;

        if (defined $pattern)
        {
            next unless $input =~ qr/^($pattern)$/;
            $input = $1;
        }

        die "Broken encoding in user input. Need UTF-8!" unless utf8::is_utf8 $input;

        return $input;
    }
}

sub Menu($$$)
{
    my ($title, $text, $options) = @_;

    my @list;
    my $number_of_options;
    switch (ref $options)
    {
        case ("ARRAY")
        {
            my $counter = 1;
            @list = [ map { ( $counter++, $_ ) } sort @$options ];
            $number_of_options = $counter;
        }
        case ("HASH")
        {
            my $counter = 1;
            @list = [ map { ( $_, $$options{$_} ) } sort keys %$options ];
            $number_of_options = scalar keys %$options;
        }
        else { die "Options must be either a list or hash reference"; }
    }

    my $selection = $dialog->menu(
        title => " $title ",
        text => $text,
        list => @list,
        listheight => $number_of_options,
        height => $number_of_options + HeightFromText $text) or Abort;

    switch (ref $options)
    {
        case ("ARRAY")
        {
            return ${[ sort @$options ]}[$selection - 1];
        }
        case ("HASH")
        {
            return $selection;
        }
    }
}

sub RadioList($$$$)
{
    my ($title, $text, $options, $default) = @_;

    my @list;
    my $number_of_options;
    switch (ref $options)
    {
        case ("ARRAY")
        {
            my $counter = 1;
            @list = [ map { ( $counter++, [ $_, $_ eq $default ] ) } sort @$options ];
            $number_of_options = $counter;
        }
        case ("HASH")
        {
            @list = [ map { ( $_, [ $$options{$_}, $_ eq $default ] ) } sort keys %$options ];
            $number_of_options = scalar keys %$options;
        }
        else { die "Options must be either a list or hash reference"; }
    }

    my $selection = $dialog->radiolist(
        title => " $title ",
        text => $text,
        list => @list,
        listheight => $number_of_options,
        height => $number_of_options + HeightFromText $text);# or Abort;

    switch (ref $options)
    {
        case ("ARRAY")
        {
            return ${[ sort @$options ]}[$selection - 1];
        }
        case ("HASH")
        {
            return $selection;
        }
    }
}

sub CheckList($$$$)
{
    my ($title, $text, $options, $default) = @_;

    my %default_keys = map { ( $_, 1 ) } @$default;

    my @list;
    my $number_of_options;
    switch (ref $options)
    {
        case ("ARRAY")
        {
            my $counter = 1;
            @list = [ map { ( $counter++, [ $_, $default_keys{$_} ] ) } sort @$options ];
            $number_of_options = $counter;
        }
        case ("HASH")
        {
            @list = [ map { ( $_, [ $$options{$_}, $default_keys{$_} ] ) } sort keys %$options ];
            $number_of_options = scalar keys %$options;
        }
        else { die "Options must be either a list or hash reference"; }
    }

    my @selection = $dialog->checklist(
        title => " $title ",
        text => $text,
        list => @list,
        listheight => $number_of_options,
        height => $number_of_options + HeightFromText $text);
    $dialog->state eq "OK" or Abort;

    switch (ref $options)
    {
        case ("ARRAY")
        {
            return [ map { ${[ sort @$options ]}[$_ - 1] } @selection ];
        }
        case ("HASH")
        {
            return @selection;
        }
    }
}

sub YesNo($$)
{
    my ($title, $text) = @_;

    return $dialog->yesno(
        title => $title,
        text => $text,
        height => HeightFromText $text);
}

sub SelectSubFolder($)
{
    my ($base) = @_;
    my $subfolder = "";

    while (1)
    {
        my $parent = $base.(length $subfolder ? "/$subfolder" : "");
        my @folders = sort map { chomp; basename $_ } `find -L "$parent" -mindepth 1 -maxdepth 1 -type d -a ! -name ".*" -a ! -name "etc"`;
        my %options = ( "\bSelect" => ".",
                        "\bNew folder" => "" );
        $options{0} = ".." if length $subfolder;
        my $fmt = sprintf "%%0%dd", length sprintf "%d", int @folders;
        my $counter = 1;
        map { $options{sprintf $fmt, $counter++} = $_ } @folders;

        my $folder = Menu("Select Folder",
                          $parent,
                          \%options);

        return $parent if $folder eq "\bSelect";

        if ($folder eq "\bNew folder")
        {
            my $new_folder = InputText("Create new folder", "$parent", undef, undef);
            if ($new_folder)
            {
                mkpath("$parent/$new_folder", 0, 0755) or die "Could not create new folder: $!";
                $subfolder .= (length $subfolder ? "/" : "").$new_folder;
            }
            next;
        }

        if ($folder eq " ")
        {
            my $new_subfolder = $subfolder;
            $new_subfolder =~ s/\/[^\/]+$//;
            $subfolder = $new_subfolder eq $subfolder ? "" : $new_subfolder;
            next;
        }

        $subfolder .= (length $subfolder ? "/" : "").$folders[$folder - 1];
    }
}



1;
