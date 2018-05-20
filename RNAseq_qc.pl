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

# Generate rRNA interval #
open OUT, ">rRNA.interval.txt";
print OUT "\@HD\tVN:1.4\tSO:coordinate\n";
open IN, "<$star_ref/chrNameLength.txt";
while(<IN>){
  /(\S+)\s+(\S+)/;
  print OUT "\@SQ\tSN:$1\tLN:$2\n";
}
@tmp = `cat $gtf | grep rRNA`;
chomp @tmp;
foreach $line (@tmp){
  @t = split(/\t/,$line);
  if($t[8] =~ /gene_name "(\S+)";/){
    print OUT "$t[0]\t$t[3]\t$t[4]\t$t[6]\t$1\n";
  }
}

open IN, "<sample_list.txt";
open OUT, ">QC.xls";
print OUT "ID\tTotal read #\tUniquely Mapped %\tMulti Mapped %\tUnmapped %\tDuplication %\trRNA %\tCoding Reads %\tUTR Reads %\tIntronic %\tIntergenic %\n";
while(<IN>){
  chomp $_;
  @tmp = split(/\t/,$_);
  $id = $tmp[1];
  $file = $tmp[2];
  $workdir = "$curdir/$id";
  `mkdir -p $workdir`;
  chdir $workdir;
  print "$id\n";
  $cmd2 = "java -Xmx2g -jar $picard_dir/SortSam.jar INPUT=Aligned.out.sam OUTPUT=$id.sorted.bam SORT_ORDER=coordinate 2> picard.log";
  $cmd3 = "java -Xmx2g -jar $picard_dir/CollectRnaSeqMetrics.jar STRAND_SPECIFICITY=NONE VALIDATION_STRINGENCY=SILENT REF_FLAT=$Flat_ref RIBOSOMAL_INTERVALS=$curdir/rRNA.interval.txt CHART_OUTPUT=$id.coverage.pdf INPUT=$id.sorted.bam OUTPUT=$id.rnaseqmetrics.dat 2>> picard.log";
  $cmd4 = "java -jar $picard_dir/AddOrReplaceReadGroups.jar I=$id.sorted.bam O=$id\_added_sorted.bam SO=coordinate RGID=$id RGLB=$id RGPL=hiseq RGPU=hiseq RGSM=$id 2>> picard.log";
  $cmd5 = "java -Xmx2g -jar $picard_dir/MarkDuplicates.jar I=$id\_added_sorted.bam O=$id\_dedupped.bam READ_NAME_REGEX='[a-zA-Z0-9]+.*:[0-9]:([0-9]+):([0-9]+):([0-9]+)\$' CREATE_INDEX=true VALIDATION_STRINGENCY=LENIENT M=$id.dupmetrics.dat 2>> picard.log";
  system("$cmd2");
  system("$cmd3");
  system("$cmd4");
  system("$cmd5");

# OUTPUT QC #
$Ntotal = `cat Log.final.out | grep "Number of input reads" | cut -f2`;
$Nuniq = `cat Log.final.out | grep "Uniquely mapped reads" | head -1 | cut -f2`;
$Runiq = `cat Log.final.out | grep "Uniquely mapped reads" | tail -1 | cut -f2`;
$Rmulti = `cat Log.final.out | grep "reads mapped to multiple loci" | tail -1 | cut -f2`;
chomp $Rmulti;
chomp $Ntotal;
chomp $Nuniq;
chomp $Runiq;
$Runmap = 100-$Runiq-$Rmulti;
$qc = `cat $id.rnaseqmetrics.dat | head -8 | tail -1`;
@tmp = split(/\t/,$qc);
$dup = `cat $id.dupmetrics.dat | head -8 | tail -1 | cut -f8`;
chomp $dup;

printf OUT "$id\t$Ntotal\t$Runiq\t$Rmulti\t%.2f\%\t$dup\t$tmp[10]\t$tmp[11]\t$tmp[12]\t$tmp[13]\t$tmp[14]\n",$Runmap;

}


