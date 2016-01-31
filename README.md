# Pogenerator
Generates PO files for supporting i18n of cucumber features/steps
=head1 SYNOPSIS
perl -f pogenerator.pl \[in-use step file\] \[language code:pt|en|&lt;etc>\] \[ list | apply | reset \]
Options:
  list                  list supported codes of languages
  apply                 apply a .po file into choosen steps file/language
  reset                 restore in-use steps file back to its source state

# DESCRIPTION
This program will read the given steps file and write out a .po.
It also applies a selected language (filled .po) to a steps file (see option apply).

# AUTHOR

Rodrigo Panchiniak Fernandes - [http://toetec.com.br/](http://toetec.com.br/)

# CAVEAT
Some paths are hardocoded right now, and there is no init procedure for
adjusting them.
So, if you want to use the code asis, your tree structure shoud follow this one:
https://github.com/panchiniak/scaffolding
