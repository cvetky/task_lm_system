package Views::MenuOption::DeleteTask;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("Delete task");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	print "\nDeleting task:\n\n";
	print "Enter the name of the task you want to delete: ";
	chomp(my $name = <STDIN>);
	print "\nAre you sure you want to perform deleting? (y for yes, anything else for no): ";
	chomp(my $choice = <STDIN>);
	if($choice eq "y") {
		$controller->deleteTask($name);
	}
}

1;