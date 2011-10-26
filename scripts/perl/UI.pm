package UI;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/ReadValue ReadOption/;

use strict;

use Term::ReadKey;

sub ReadValue($$$)
{
    my ($prompt, $pattern, $default) = @_;

    while (1)
    {
        printf defined $default ? "%s [%s]: " : "%s: ", $prompt, $default;
        $prompt = sprintf "\033[;1;31m%s\033[;0m", $prompt;
        my $input = <STDIN>;
        chomp $input;

        if (defined $default and $input eq "")
        {
            $input = sprintf $default;
            utf8::upgrade $input unless utf8::is_utf8 $input;
        }
        if (defined $pattern)
        {
            next unless $input =~ qr/^($pattern)$/;
            $input = $1;
        }
        die "Broken encoding in user input. Need UTF-8!" unless utf8::is_utf8 $input;
        return $input;
    }
}

sub ReadOption($$$)
{
    my ($prompt, $options, $default) = @_;

    print "$prompt\n"; $| = 1;
    my $n = 0;
    my $default_index;
    foreach my $option (@$options)
    {
        ++$n;
        printf "  %2d   %s\n", $n, $option;
        $default_index = $n if defined $default and $default eq $option;
    }
    die "Invalid default value given: $default!" if defined $default and not defined $default_index;
    return $$options[-1 + ReadValue "Your choice", sprintf("(%s)", join "|", (1..$n)), $default_index];
}



1;
