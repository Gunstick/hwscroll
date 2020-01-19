# hwscroll
hardware scrolling for Atari STf

This is based on the original awk program used to create the ULM 
hardware scrolling table. To get that version, go back to revision 1 of this repo.

Usage:

By default, calculates a 4 lines table with all known switches/line lengths.
To use less switches or change number of line use options.
eclocksync can be used to be able to use all line lengths on the first line

The default is:
./mkhwscrolltab.sh --lines=4 --lengths=13 --eclocksync on

You can still calculate the original ULM hardware scroller with:
./mkhwscrolltab.sh --lines 6 --lengths 8 --eclocksync off

