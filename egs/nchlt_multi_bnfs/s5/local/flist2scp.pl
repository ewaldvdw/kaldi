#!/usr/bin/perl
#
#            2015 University of Tehran (Author: Bagher BabaAli)
# Apache 2.0
#

while(<>){
    m:^\S+(\d\d\d)([fFmM])(\S+)\.[tT][xX][tT]$: || die "Bad line $_";
    $spkid = sprintf("%03d",$1);
    $sex = $2;
    $suffix = $3;
    $fpath = $_;
    $fpath =~ s/\*//g;
    $fpath = $spkid . $fpath;    
    $id =  $spkid . $sex . $suffix;
    print "$id $fpath";
}

