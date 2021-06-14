package Views::MenuOption::DeleteAllTasks;

use strict;
use warnings;

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("Delete all tasks");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	print "\nAre you sure you want to delete all available tasks? (y for yes, anything else for no): ";
	chomp(my $choice = <STDIN>);
	if($choice eq "y") {
		$controller->deleteAllTasks();
	}
}

1;