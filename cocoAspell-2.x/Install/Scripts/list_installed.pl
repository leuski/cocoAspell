#! /usr/bin/perl -w

$s="";

while (<>) {
	s/\s+$//g;
	$s .= $_;
	if ($s =~ /\\$/) {
		$s =~ s/\\$/ /;
		next;
	}
	

	$s =~ s/^\s+//g;
#	print "$s\n";
	if ($s =~ /^\/usr\/bin\/install/) {
		my 	@a = split(/\s+/, $s);
		my	$n	= $a[$#a];
		$n	=~ s/^'(.*)'$/$1/;
		print "$n\n";
	} elsif ($s =~ /^\(cd \/usr\/local\/lib (.*ln -s.*)\)$/) {
	
		my 	@a = split(/\s+/, $1);
		my	$n	= $1;
#		print "$n\n";

		$n =~ /ln -s ([a-zA-Z0-9_\.]+) ([a-zA-Z0-9_\.]+)/;
		$n	= $2;
		
#		print "$n\n";
		
		$n	=~ s/^'(.*)'$/$1/;
		print "/usr/local/lib/$n\n";
	}
	$s = "";
}