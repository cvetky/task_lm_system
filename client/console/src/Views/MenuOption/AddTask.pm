package Views::MenuOption::AddTask;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("Add new task");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	print "\nAdding new task:\n\n";
	my ($name, $commandTemplate, $params, $environmentVariables, $timeOut) = $self->promptForTaskInfo();	
	$controller->createTask($name, $commandTemplate, $params, $environmentVariables, $timeOut);
}

1;