#!/usr/bin/perl
#
#            2015 University of Tehran (Author: Bagher BabaAli)
# Apache 2.0
#

while(<>){
    m:^(\S+) (\S+)$: || die "Bad line $_";
    $uttid = $1;
    $fpath = $2;

    open(my $F,"$fpath") || die "Error opening txt file $fpath\n"; 
    my $trans = <$F>;
    print "$uttid $trans";
    close(F);
}
