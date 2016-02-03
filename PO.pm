package Test::BDD::Cucumber::PO;

use warnings;
use strict;
use Data::Dumper qw(Dumper);
use List::MoreUtils qw(uniq);
use Locale::Language;
use File::Copy;
use Tie::File;
use 5.010;

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

my $step_file_name;
my $language_code = 'en';
my $apply_mode;

GetOptions(
    'step|s=s' => \$step_file_name,
    'lang|l=s' => \$language_code,
    'mode|m=s' => \$apply_mode,
) or die "Usage: $0 --step <FILE_NAME>  --lang <LANGUAGE_CODE>|list  --mode apply|reset\n";

use File::Find::Rule;
use Cwd 'abs_path';

my @lines_tobe_removed;

my $current_path = abs_path(__FILE__);
my $current_file_name = __FILE__;

for ($current_path){
  s/\/.tests\/inc\/cucumber-steps2po-file\/$current_file_name//;
}

if ($language_code eq 'list'){
  my @language_codes = all_language_codes();
  my @language_names = all_language_names();

  foreach my $language (@language_codes) {
    print $language . " - " . code2language($language) . "\n" ;
  }
  exit;
}

my $po_file_name = $step_file_name;
for ($po_file_name){
  s/\..+/\.po/;
  s/^/$language_code\_/;
}

if (not defined $language_code){
  print "Error: you have to choose a language according to ISO 622 codes. Use [list] to see all codes available.\n";
  exit;
}


my $language_name = code2language($language_code);

if (!defined $language_name){
  print "Error: language code not found. Use [list] to see all codes available.\n";
  exit;
}

#In order to generate the po file from a choosen step, the file of the step
#needs to be oppened. Its prefix is the unique file name, so lets extract the
#prefix
my $step_prefix = $step_file_name;

for ($step_prefix){
  s/\_.+//;
}

#Check the given file name is in fact inside the project steps directory
my $steps_full_path_name = $current_path.'/tests/projects/' . $step_prefix . '/step_definitions/' . $step_file_name;

if (not -e $steps_full_path_name){
  print 'Error: file does not exist' . "\n";
  exit;
}

my $po_directory = $steps_full_path_name;

for ($po_directory){
  s/$step_file_name/i18n/;
}

sub reset_steps_file_from_src{
  my $full_path_source_file = $current_path . "/.tests/src/projects/" . $step_prefix . "/step_definitions/$step_file_name";
  copy($full_path_source_file,$steps_full_path_name) or die "Copy failed: $!";

  return;

}

if (defined $apply_mode and $apply_mode eq "apply"){
  print "Translation will be applyed\n";
  #In order to apply the translation, we need first assure the current step file
  #in use corresponds to the source default file.
  #For doing so, the current file gets replaced by the one at src directory.

  reset_steps_file_from_src();

  #Now each msgstr from the PO file will be replaced in the steps file by its
  #msgid match. For doing so, first we need to check the PO file for the step
  #exists, and if it is prefixed with the desired language. We do just just
  #by opening it in the read mode.

  open (FH, "< $po_directory/$po_file_name") or die "Can't open $steps_full_path_name for read: $!";
  my @po_lines = <FH>;

  open my $in,  '<',  $steps_full_path_name      or die "Can't read old file: $!";
  open my $out, '+>', "$steps_full_path_name.new" or die "Can't write new file: $!";

  my %translation_of;

  my $po_lines_index = 0;
  foreach my $po_line (@po_lines){
    if ($po_line =~ /^msgid/){

      for ($po_line){
        s/^msgid "//;
        s/"$//;
        s/^[\s]+//;
        s/[\s]+$//;
      }
      chomp($po_line);

      for ($po_lines[$po_lines_index + 1]){
        s/^msgstr "//;
        s/"$//;
        s/^[\s]+//;
        s/[\s]+$//;
      }
      chomp ($po_lines[$po_lines_index + 1]);

      $translation_of{$po_line} = $po_lines[$po_lines_index + 1];

    }
    $po_lines_index++;
  }

  sub remove_line_number{
    my $line_tobe_removed_number = $_[0];
    #Flag line to be removed
    push @lines_tobe_removed, $line_tobe_removed_number;
  }

  sub i18n_replace {
    my ($source, $translation, $string, $line_number) = @_;

    if ($string =~ /$source/ ){
      for ($string){
        s/$source/$translation/;
      }
      $_[2] = $string;
      return $string;
    }
    else{
      return 0;
    }

  }

  while(<$in>){
    my $flag = 1;
    my $last_translated_line = 0;
    my $tobe_translated_candidate = $_;
    foreach my $translated_key (sort {length($b) <=> length($a)} keys %translation_of) {
      # if (($_ !~ /^#|^\s/) and ($_ =~ /\/.+\//)){
      if (($tobe_translated_candidate !~ /^#|^\s/) and ($tobe_translated_candidate =~ /\/.+\//)){

        my $current_line = $.;
        # my $translation_result = i18n_replace($translated_key, $translation_of{$translated_key}, $_, $.);
        my $translation_result = i18n_replace($translated_key, $translation_of{$translated_key}, $tobe_translated_candidate, $.);
        if ($translation_result){
          print $out $translation_result;
          $flag = 0;

          if ($current_line == $last_translated_line){
            #Remove line above the current line
            remove_line_number($current_line);
          }
          $last_translated_line = $current_line;
        }
      }
    }
    if ($flag == 1){
      # print $out $_;
      print $out $tobe_translated_candidate;
    }
  }
  close $out;

  my @records;
  tie @records, 'Tie::File', "$steps_full_path_name.new";

  foreach my $line_tobe_removed (@lines_tobe_removed){
    splice @records, ($line_tobe_removed - 1) ,1;
  }

  untie @records;

  #Copy .new file into default steps file
  copy("$steps_full_path_name.new",$steps_full_path_name) or die "Copy failed: $!";
  #Remove .new file
  unlink "$steps_full_path_name.new";
  exit;
}

if (defined $apply_mode and $apply_mode eq "reset"){
  print "Choosen reset option\n";
  reset_steps_file_from_src();
  exit;
}

local *FH;
open (FH, "< $steps_full_path_name") or die "Can't open $steps_full_path_name for read: $!";
my @lines = <FH>;

if (not $lines[0] eq "#encoding: utf-8\n"){
  print "Error: wrong encoding\n";
  exit 1;
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
        #@TODO: following split should be broader, not only for '(.+)'
        push @msgid_fields, split /\'\(\.\+\)\'/, $line;
      }
    }
  }
}
my @msgid_merge = (@msgid,@msgid_fields);
my @unique_ids = uniq @msgid_merge;

open my $po_content, '>', $po_directory . "/" . $po_file_name or die "Can't open $po_file_name for write: $!";;

print $po_content "# $language_name translation of $step_file_name\n";
foreach my $id (@unique_ids){
  print $po_content 'msgid "' . $id . '"' . "\n";
  print $po_content 'msgstr ""' . "\n";
}

my $number_entries = scalar @unique_ids;

if (close $po_content){
  print "File $po_file_name succefully written with $number_entries entries.\n";
  exit 0;
}
else{
  print "Error on closing $po_file_name . There should be $number_entries entries in the file.\n";
  exit 1;
}

__END__
=head1 Pogenerator
Generates PO files for supporting i18n of cucumber features/steps
=head1 SYNOPSIS
Usage perl -f PO.pm --step <FILE_NAME>  --lang <LANGUAGE_CODE>|list  --mode apply|reset
Options:
  list                  lists supported codes of languages
  apply                 apply a .po file into choosen steps file/language
  reset                 restore in-use steps file back to its source state

=head1 DESCRIPTION
This program will read the given steps file and write out a .po.
It also applies a selected language (filled .po) to a steps file (see option apply).

=head1 AUTHOR

Rodrigo Panchiniak Fernandes - L<http://toetec.com.br/>

=head1 CAVEAT
Some paths are hardocoded right now, and there is no init procedure for
adjusting them.
So, if you want to use the code asis, your tree structure shoud follow this one:
https://github.com/panchiniak/scaffolding



=cut
