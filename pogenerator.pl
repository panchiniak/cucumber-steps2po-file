#!/usr/bin/perl -w
use utf8;
use strict;
use Data::Dumper qw(Dumper);
use List::MoreUtils qw(uniq);
use Locale::Language;
use File::Copy;

use File::Find::Rule;
use Cwd 'abs_path';


my $step_file_name = shift;
my $language_code = shift;
my $apply_mode = shift;

my $current_path = abs_path($0);
my $current_file_name = $0;

for ($current_file_name){
  s/\..+//;
}
for ($current_path){
  s/\/.tests\/inc\/cucumber-steps2po-file\/$current_file_name\.pl//;
}


my $po_file_name = $step_file_name;
for ($po_file_name){
  s/\..+/\.po/;
  s/^/$language_code\_/;
}

if (not defined $language_code){
  print "Error: choose a language ISO 622 code\n";
  exit;
}

if ($language_code eq 'list'){
  my @language_codes = all_language_codes();
  my @language_names = all_language_names();

  foreach my $language (@language_codes) {
    print $language . " - " . code2language($language) . "\n" ;
  }
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



if (defined $apply_mode and $apply_mode eq "apply"){
  print "Translation will be applyed\n";
  #In order to apply the translation, we need first assure the current step file
  #in use corresponds to the source default file.
  #For doing so, the current file gets replaced by the one at src directory.
  my $full_path_source_file = $current_path . "/.tests/src/projects/" . $step_prefix . "/step_definitions/$step_file_name";
  copy($full_path_source_file,$steps_full_path_name) or die "Copy failed: $!";

  #Now each msgstr from the PO file will be replaced in the steps file by its
  #msgid match. For doing so, first we need to check the PO file for the step
  #exists, and if it is prefixed with the desired language. We do just just
  #by opening it in the read mode.

  open (FH, "< $po_directory/$po_file_name") or die "Can't open $steps_full_path_name for read: $!";
  my @po_lines = <FH>;

  open my $in,  '<',  $steps_full_path_name      or die "Can't read old file: $!";
  open my $out, '>', "$steps_full_path_name.new" or die "Can't write new file: $!";


  # print Dumper \@po_lines;
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

      # while( <$in> )
      #   {
      #     s/\b(perl)\b/Perl/g;
      #     print $out $_;
      #   }
      # close $out;

    }
    $po_lines_index++;

    # print $po_line;
  }

  print Dumper \%translation_of;

  while(<$in>){
    foreach my $translated_key (keys %translation_of) {
      if (($_ !~ /^#|^\s/) and ($_ =~ /\/.+\//)){
        if ($_ =~ /$translated_key/){
          print "----------MATCH!!!!!----------\n";
          print $translated_key . "\n";
          print $translation_of{$translated_key} . "\n";
          print $_ . "\n";
          for ($_){
            s/$translated_key/$translation_of{$translated_key}/;
          }
          print $_ . "\n";
          print $. . "\n";

        }
        # print $translated_key . "\n";
        # print $_ . "\n";
        # print $. . "\n";
      }

    }
    # print $out $_;
    # print $. . "\n";
  }

  close $out;

  exit;
}



open (FH, "< $steps_full_path_name") or die "Can't open $steps_full_path_name for read: $!";
my @lines = <FH>;

if (not $lines[0] eq "#encoding: utf-8\n"){
  print "Error: wrong encoding\n";
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
# my $po_directory = $steps_full_path_name;
#
# for ($po_directory){
#   s/$step_file_name/i18n/;
# }

open my $po_content, '>', $po_directory . "/" . $po_file_name or die "Can't write file.\n";

print $po_content "# $language_name translation of $step_file_name\n";
foreach my $id (@unique_ids){
  print $po_content 'msgid "' . $id . '"' . "\n";
  print $po_content 'msgstr ""' . "\n";
}

my $number_entries = scalar @unique_ids;

if (close $po_content){
  print "File $po_file_name succefully written with $number_entries entries.\n";
};


__END__
=head1 Pogenerator
Generates PO files for the i18n of cucumber step files
=head1 SYNOPSIS
perl -f pogenerator.pl [step file] [language code | list]
Options:
 list            list of language codes available

=head1 DESCRIPTION
B<This program> will read the given input file(s) and write out a po files.
=cut
