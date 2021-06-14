package Views::MenuOption::Exit;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(1);
	$self->setName("Exit");
	return $self;
}

sub executeOption {
	print "\nExit Successfull!\n";
}

1;