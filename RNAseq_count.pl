#!/usr/bin/perl
use File::Basename;

$config = "configure.txt";

open IN, "<$config";
while(<IN>){
  chomp $_;
  @tmp = split(/\t/,$_);
  if($tmp[0] eq "STAR_REF"){$star_ref = $tmp[1]}
  if($tmp[0] eq "FASTQ_DIR"){$fastq_dir = $tmp[1]}
  if($tmp[0] eq "PICARD"){$picard_dir = $tmp[1]}
  if($tmp[0] eq "HTseq"){$htseq = $tmp[1]}
  if($tmp[0] eq "STAR"){$star = $tmp[1]}
  if($tmp[0] eq "GTF"){$gtf = $tmp[1]}
}

$curdir = `pwd`;
chomp $curdir;

@id_list = `cat sample_list.txt | cut -f2`;
chomp @id_list;
open OUT, ">htseq.count.txt";
print OUT "ID\t".join("\t",@id_list)."\n";

open IN, "<sample_list.txt";
while(<IN>){
  chomp $_;
  @tmp = split(/\t/,$_);
  $id = $tmp[1];
  $file = $tmp[2];
  $workdir = "$curdir/$id";
  chdir $workdir;
  print "$id\n";
  $cmd = "$htseq -s no -m intersection-nonempty Aligned.out.sam $gtf > $id.count";
#  system($cmd);
  open TAB, "<$id.count";
  while(<TAB>){
    /(\S+)\s+(\S+)/;
    $cnt{$id}{$1} = $2;
  }
  @gene_list = `cat $id.count | cut -f1`;
  chomp @gene_list;
}

# output count table #
foreach $gene (@gene_list){
  print OUT $gene;
  foreach $id (@id_list){
    print OUT "\t$cnt{$id}{$gene}";
  }
  print OUT "\n";
}

