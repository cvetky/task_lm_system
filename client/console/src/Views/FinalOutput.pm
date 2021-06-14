package Views::FinalOutput;

use strict;
use warnings;

sub new {
	my ($class, $model) = @_;
	return bless({ model => $model }, $class);
}

sub outputModel {
	my ($self) = @_;
	my $model = $self->getModel();
	print "\n".$model->toString();
}

sub getModel {
	my ($self) = @_;
	return $self->{model};
}

1;