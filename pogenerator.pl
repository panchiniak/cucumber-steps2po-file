#!/usr/bin/perl -w
use utf8;
use strict;
use Data::Dumper qw(Dumper);
use List::MoreUtils qw(uniq);
use Locale::Language;

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
my $language_code = shift;

if (not defined $language_code){
  print "Error: choose a language ISO 622 code\n";
  exit;
}

if ($language_code eq 'list'){
  print Dumper \all_language_codes();
  print Dumper \all_language_names();
  exit;
}


my $language_name = code2language($language_code);



#In order to generate the po file from a choosen step, the file of the step
#needs to be oppened. Its prefix is the unique file name, so lets extract the
#prefix
my $step_prefix = $step_file_name;

for ($step_prefix){
  s/\_.+//;
}

#Check the given file name is in fact inside the project steps directory
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
  if (($line !~ /^#|^\s/) and ($line =~ /\/.+\//)){
    if ($line =~ /\/.+\//){
      for ($line){
        s/.+\^//;
        s/\$.+//;
      }
      if ($line !~ /'/){
        chop($line);
        push @msgid, $line;
      }
      else{
        chop($line);
        push @msgid_fields, split /'.+'/, $line;
      }
    }
  }
}
my @msgid_merge = (@msgid,@msgid_fields);

my @unique_ids = uniq @msgid_merge;
print "# $language_name translation of $step_file_name\n";

print Dumper \@unique_ids;
