#!/usr/bin/perl -w
use utf8;
use strict;
use Data::Dumper qw(Dumper);
use List::MoreUtils qw(uniq);

use File::Find::Rule;
use Cwd 'abs_path';

my $current_path = abs_path($0);
my $current_file_name = $0;

for ($current_file_name){
  s/\..+//;
}
for ($current_path){
  s/\/.tests\/inc\/cucumber-steps2po-file\/$current_file_name\.pl//;
}

my $step_file_name = shift;

#In order to generate the po file from a choosen step, the file of the step needs to be oppened
#its prefix is the unique file name
#so, lets extract the prefix
my $step_prefix = $step_file_name;

for ($step_prefix){
  s/\_.+//;
}

#check the given file name is in fact inside the project steps directory
my $steps_full_path_name = $current_path.'/tests/projects/' . $step_prefix . '/step_definitions/' . $step_file_name;

print $steps_full_path_name . "\n";
if (-e $steps_full_path_name){
  print 'File exists' . "\n";

}
else{
  print 'Error: File does not exist' . "\n";
  exit;
}

open (FH, "< $steps_full_path_name") or die "Can't open $steps_full_path_name for read: $!";
my @lines = <FH>;

if ($lines[0] eq "#encoding: utf-8\n"){
  print "Enconding: ok\n";
}
else{
  print "Error: wrong encoding: ok\n";
  exit;
}

my @msgid;
my @msgid_fields;

foreach my $line (@lines){
  if ($line !~ /^#|^\s/){
    if ($line =~ /\/.+\//){
      for ($line){
        s/.+\^//;
        s/\$.+//;
      }
      if ($line !~ /'/){
        chop($line);
        print 'sem argumento: ' . $line . "\n";
        push @msgid, $line;
      }
      else{
        print 'com argumento: ' . $line . "\n";
        chop($line);
        push @msgid_fields, split /'.+'/, $line;
      }
    }
  }
}
my @msgid_merge = (@msgid,@msgid_fields);

my @unique_ids = uniq @msgid_merge;
print Dumper \@unique_ids;