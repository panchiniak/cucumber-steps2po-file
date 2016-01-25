#!/usr/bin/perl -w
use utf8;
use strict;
use Data::Dumper qw(Dumper);

use File::Find::Rule;
use Cwd 'abs_path';

my $current_path = abs_path($0);
my $current_file_name = $0;

for ($current_file_name){
  s/\..+//;
}
for ($current_path){
  s/\/.tests\/inc\/$current_file_name\.pl//;
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

my $end_line = scalar @lines;
my $current_line = 0;

while ($current_line < $end_line){
  if ($lines[$current_line] =~ /.+\/.+\//){
    if ($lines[$current_line] !~ /^#/){
      for ($lines[$current_line]){
        s/.+{\/}//;
      }
      my @words = split /\//, $lines[$current_line];
      my @words_sentence = split /'/, $words[1];
      my $words_size = scalar @words_sentence;
      foreach my $text (@words_sentence){
        if($text !~ /\(|\$/){
          for ($text){
            s/\^|^ | $//g;
          }
          print $text . "\n";
        }
      }
    }
  }
  $current_line++;
}




# close FH or die "Cannot close $file: $!";

#check "#encoding: utf-8" mandatory first line
# open(my $fh, '<:encoding(UTF-8)', $steps_full_path_name)
#   or die "Could not open file '$steps_full_path_name' $!";
#
# while (my $row = <$fh>) {
#   chomp $row;
#
#   print "$row\n";
# }

# open($steps_full_path_name, $ARGV[0]);
# my $c=0;
# while ($steps_full_path_name) {
#     my $line=$_;
#     printf("line %2d: %s", $c++, $line);
#     my $ref=$1 if /^Referer: (.*)/;
# }

#open file for paring it






# my $project_root_path = $current_path;
# my $files_dir = $project_root_path . '/tests';
# my $links_features_dir = $project_root_path . '/.tests/features';
# my $links_pages_dir = $project_root_path . '/.tests/lib/pages';
# my $links_step_definitions_dir = $project_root_path . '/.tests/features/step_definitions';
#
# #remove todo conteúdo da pasta features, exceto o diretório support
# ##copia o diretório support para ..
# `cp -ar $links_features_dir/support $project_root_path/.tests`;
# ##remove toda a pasta features
# `rm -rf $links_features_dir`;
# ##recria a pasta features
# `mkdir $links_features_dir`;
# ##copia ../support de volta para features
# `cp -ar $project_root_path/.tests/support $links_features_dir`;
# ##remove ../support
# `rm -rf $project_root_path/.tests/support`;
# ##recria a pasta step_definitions vazia, dentro de features
# `mkdir $links_features_dir/step_definitions`;
# ##remove o diretório .teses/lib/pages
# `rm -rf $links_pages_dir`;
# ##recria o diretório .teses/lib/pages vazio
# `mkdir $links_pages_dir`;
#
# #escaneia os arquivos <tipo_de_arquivo> recursivamente dentro de tests/projects
# # <subdiretório> e cria seus links simbólicos em .tests/<pasta_destino>
# sub file_scan {
#   my ($file_type, $subfolder, $end_folder) = @_;
#   my $files_rule = File::Find::Rule->new;
#   $files_rule->file;
#   $files_rule->name( $file_type );
#   my @files = $files_rule->in( $files_dir );
#   foreach (@files) {
#     my $link_target = $_;
#     my $original_link_target = $link_target;
#     for ($link_target){
#       s/^.+$subfolder\///
#     }
#     my $file_file_name = $link_target;
#     my $simbolic_link_argument = $end_folder.'/'.$file_file_name;
#     `ln -s $original_link_target $simbolic_link_argument`;
#   }
# }
#
# file_scan("*.feature", "features", $links_features_dir);
# file_scan('*_steps\.rb', "step_definitions", $links_step_definitions_dir);
# file_scan('*_page\.rb', "pages", $links_pages_dir);
#
# exit;
