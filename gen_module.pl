#! /usr/bin/perl
use Modern::Perl;
use YAML;
use Perlude;
use open qw< :std :utf8 >;

my %trans = do {
    open my $fh, 'trans';
    map { chomp; reverse m{ (\S+) \s+ (.*) }x } <$fh>; 
};

my %struct;
{ 
    open my $fh, 'structs';
    my $name;
    for ( <$fh> ) {
        chomp;
        next if /^\s*#/;
        if (/^(?<len>\d+) \s+ (?<desc>.*)/x) {
                my $key = $trans{ $+{desc} } or die "no trans for $+{desc}";
                push @{ $struct{$name} }
                , [ $key, @+{qw< len desc >} ]
        }
        elsif (/(\S+)/) { $name = $1 }
    }
};

sub render_elements(_) {
    my $els = shift;
    '['
    . join("\n    , ", map {sprintf " [ %s => a%s => q{%s} ]", @$_ } @$els  )
    . ']'
}

say
'package OC240;
use strict;
use warnings;

our %description =
('
, join
    ( "\n,"
    , map { sprintf " %s => %s", $_, render_elements $struct{$_} } keys %struct )
, ');

1;';







