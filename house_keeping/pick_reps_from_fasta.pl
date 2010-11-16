#!/usr/bin/perl -w

#Runs blastp on a fasta file
# adds the name of the fasta (marker) file to the end of each sequence IDs
# Parses the fasta file to get it ready for mcl


use strict;
use Getopt::Long;
use Cwd;
use Bio::SeqIO;

my $usage = qq~
Usage: $0 <options> <input_fasta_file> <output_fasta_file>

~;

die $usage unless ($ARGV[0] && $ARGV[1]);

my $clean =0; #removes all the temporary files

GetOptions("clean" => \$clean) || die $usage;

my $workingDir = getcwd;

my $inputFile = $ARGV[0];
my $outputFile = $ARGV[1];

#get the marker name
$inputFile =~ m/(\w+)\.(\w+)$/;
my $core = $1;
my $suffix = $2;

#make a blast db for the fasta file
`makeblastdb -in $inputFile -dbtype prot`;
#Run the blastp for the fasta file
if(!-e "$workingDir/$core.blastp"){
    `blastp -query $inputFile -evalue 0.1 -db $workingDir/$core.$suffix -outfmt 6 -out $workingDir/$core.blastp`;
}

#parse the blast output
open(blastIN,"$workingDir/$core.blastp");
open(blastOUT,">$workingDir/$core.premcl");
while(<blastIN>){
    $_=~ m/^(\S+)\s+(\S+)\s+(\S+)/;
    print blastOUT "$1 $2 $3\n";
}
close(blastIN);
close(blastOUT);

#run pick_rep_by_mcl.pl   NEED to be in the same Directory along with mcl_redunt_reduce.pl AND get_link_by_list.pl
`perl pick_rep_by_mcl.pl -i $workingDir/$core.premcl -n 25 -o $workingDir/$core.reps`;

#read the represenatives for the marker
my %repHash=();
open(inFILE,"$workingDir/$core.reps");
while(<inFILE>){
    chomp($_);
    $repHash{$_}=1;
}
close(inFILE);


my $inseq=Bio::SeqIO->new(-file => "$inputFile");
open(outFILE,">$outputFile");
while (my $seq = $inseq->next_seq) {
    if(exists $repHash{$seq->id}){
	print outFILE ">".$seq->id."_$core\n".$seq->seq."\n";
    }
}
close(outFILE);




if($clean){

    `rm $workingDir/$core.blastp`;
    `rm $workingDir/$core.$suffix.*`;
    `rm $workingDir/$core.premcl`;
    `rm $workingDir/$core.reps*`;
    

}
