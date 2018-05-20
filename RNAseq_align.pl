#!/usr/bin/perl

$input = "sample_list.txt";
$config = "configure.txt";

$Flat_ref = "/home/ji/data/ref/mm9/mm9.refFlat.txt";

#if(@ARGV != 2) { die "./RNA_align_qc.pl $input $config\n"; }
#$input = $ARGV[0];
#$config = $ARGV[1];

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

open IN, "<sample_list.txt";
while(<IN>){
  chomp $_;
  @tmp = split(/\t/,$_);
  $id = $tmp[1];
  $file = $tmp[2];
  $workdir = "$curdir/$id";
  `mkdir -p $workdir`;
  chdir $workdir;
  print "$id\n";
  $run = "$star --genomeDir $star_ref --readFilesIn $fastq_dir/$file --runThreadN 8 --sjdbGTFfile $gtf --genomeLoad LoadAndKeep --outReadsUnmapped Fastx";
  system("$run");
}


