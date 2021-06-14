package Views::MenuOption::ViewTask;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("View task");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	print "\nViewing task:\n\n";
	print "Enter the name of the task you want to view: ";
	chomp(my $name = <STDIN>);
	$controller->readTask($name);
}

1;