package Views::MenuOption::UpdateTask;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("Update task");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	print "\nUpdating task:\n\n";
	print "Enter the name of the task you want to update: ";
	chomp(my $oldName = <STDIN>);

	my $oldModel = $controller->readTask($oldName);
	my $oldContent = $oldModel->getContent();
	if($oldContent->{error}) {
		return;
	}

	print "\n\nEnter updated info about the task (enter '-' for not updating some features):\n\n";
	my ($name, $commandTemplate, $params, $environmentVariables, $timeOut) = $self->promptForTaskInfo();
	
	$controller->updateTask($oldName, $name, $commandTemplate, $params, $environmentVariables, $timeOut);
}

1;