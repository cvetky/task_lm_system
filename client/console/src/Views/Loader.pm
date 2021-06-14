package Views::Loader;

use strict;
use warnings;

use Term::ReadKey;

use MenuOptions;
use Controllers::MenuController;
use Controllers::RESTController;
use Views::MenuOption::ExecuteTask;

sub new {
	my ($class, $controller) = @_;
	return bless({}, $class);
}

sub startApp {
	my ($self) = @_;
	ReadMode(1); ## restore everything if something fails during execution
	my $restController = Controllers::RESTController->new();
	my ($isPreviousTaskStillRunning, $taskName) = $restController->isProcessRunning();
	if($isPreviousTaskStillRunning) {
		$self->reattachToRunningTask($restController, $taskName);
	}
	print "\n~~~Task Executor v2.0~~~\n\n";
	my $controller = $self->getController();
	while(1) {
		$self->showMenu();
		my $option;
		my $isTerminating = 0;
		while(1) {
			print "\nYour option: ";
			chomp($option = <STDIN>);
			if($controller->isMenuOptionValid($option)) {
				last;
			} else {
				print "\nInvalid option! It must be a number between 1 and 8!\n";
			}
		}
		$isTerminating = $controller->executeMenuOption($option);
		if($isTerminating) {
			last;
		}
	}
}

sub showMenu {
	print "\n\tMain Menu:\n";
	foreach my $menuOptionNumber (sort(keys(%MenuOptions::options))) {
		print "\n\t\t$menuOptionNumber. ".MenuOptions->getMenuOption($menuOptionNumber)->getName()."\n";
	}
}

sub getController {
	my ($self) = @_;
	if(!defined($self->{controller})) {
		$self->{controller} = Controllers::MenuController->new();
	}
	return $self->{controller};
}

sub reattachToRunningTask {
	my ($self, $restController, $taskName) = @_;
	my $reattacher = Views::MenuOption::ExecuteTask->new();
	print "\nReattached to currently running task '$taskName'!\n";
	$reattacher->monitorTask($restController, $taskName);
}

1;