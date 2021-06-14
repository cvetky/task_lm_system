package Views::MenuOption::ViewAllTasks;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("View all tasks");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	$controller->readAllTasks();
}

1;