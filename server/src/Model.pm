package Model;

use strict;
use warnings;

sub new {
	my ($class, $modelStructure) = @_;
	return bless($modelStructure, $class);
}

sub toHash {
	...
}

sub validate {
	...
}

1;