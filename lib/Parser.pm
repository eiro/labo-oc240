package Parser; 
use Perlude;
use autodie;
use Modern::Perl;
use OC240;
use Data::FixedFormat;
use List::AllUtils qw< first >; 

sub records_of (_) {
    my $source = shift or die;
    my $raws = open_file $source, '<:encoding(iso-8859-15)';
    my $r; 
    sub {
        return if eof $raws;
        read $raws,$r,240 or die;
        $r
    }
}

sub _oc240_spec {
    my $spec = {};
    while ( my ( $k, $v ) = each %OC240::description  ) {
        $$spec{ $k }{reader} = 
            Data::FixedFormat->new
            ([map{

                $spec
                -> { $k }{description}
                -> { $$_[0] } = $$_[2];

                join ':', @$_[0,1] } @$v ]);
    }
    $spec;
}

sub parse (_) {

    state $spec         = _oc240_spec;
    state $record_types = [ keys %$spec ]; 

    my $raw = shift; 

    $raw ~~
        m{^ (?<emiter>     01 )
        |   (?<total>  09 )
        |   (?:
               (?<operation> 04 )
                   .{6}
                   (?: (?<credit>    40 )
                   |   (?<debit>     80 )
                   )) }x
               or die "can't guess the type of record";

    my %isa = %+;
    my $type = first { $_ ~~ $record_types } keys %isa
        or die;

    $isa{isa} = $type;

    { raw => $raw
    , %isa
    , data => 
        ( $$spec{$type}{reader} || die "no reader for $type" )
            ->unformat( $raw ) };

}

1;

=head SYNOPSIS

OC 240 business exchange format 

=head SYNOPSIS 

L<a document from the cocktail consortium|http://www.cocktail.org/gedfs/ged/courrier/commun/0407120933.0/Structure_fichier_240c.pdf?wgtg=_blank>
was used as a reference. seems to parse our data. 

