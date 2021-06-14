package Controllers::MenuController;

use strict;
use warnings;

use MenuOptions;

sub new {
	my ($class) = @_;
	return bless({}, $class);
}

sub executeMenuOption {
	my ($self, $option) = @_;
	my $view = $self->getView($option);
	$view->executeOption();
	return $view->isTerminating();
}

sub isMenuOptionValid {
	my ($self, $option) = @_;
	if($option =~ /\A[1-8]\z/) {
		return 1;
	}
	return 0;
}

sub getView {
	my ($self, $option) = @_;
	$self->{view} = MenuOptions->getMenuOption($option);
	return $self->{view}; ## every time different option -> allow different views!
}

1;