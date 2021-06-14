package Views::MenuOption;

use strict;
use warnings;

use Controllers::RESTController;

sub new {
	my ($class, $isTerminating) = @_;
	my $self = bless({}, $class);
	$self->setIsTerminating($isTerminating);
	return $self;
}

sub executeOption {
	...
}

sub isTerminating {
	my ($self) = @_;
	return $self->{isTerminating};
}

sub getName {
	my ($self) = @_;
	return $self->{name};
}

sub setIsTerminating {
	my ($self, $isTerminating) = @_;
	$self->{isTerminating} = $isTerminating;
}

sub setName {
	my ($self, $name) = @_;
	$self->{name} = $name;
}

sub getController {
	my ($self) = @_;
	if(!defined($self->{controller})) {
		$self->{controller} = Controllers::RESTController->new();
	}
	return $self->{controller};
}

sub promptForTaskInfo {
	print "Name: ";
	chomp(my $name = <STDIN>);
	print "\nCommand Template: ";
	chomp(my $commandTemplate = <STDIN>);
	my $counter = 1;
	my @params = ();
	while(1) {
		my $toAddParams;
		if($counter == 1) {
			print "\nDo you want to add parameters (y for yes, anything else for no): ";
			chomp($toAddParams = <STDIN>);
		} else {
			print "\nDo you want to continue adding parmeters (y for yes, anything else for no): ";
			chomp($toAddParams = <STDIN>);
		}
		if($toAddParams ne "y") {
			last;
		}
		print "\nParameter$counter name: ";
		chomp(my $paramName = <STDIN>);
		print "\nParameter$counter type (s, i, b or r): ";
		chomp(my $type = <STDIN>);
		print "\nParameter$counter type description: ";
		chomp(my $typeDescription = <STDIN>);
		print "\nParameter$counter hidden (true or false): ";
		chomp(my $hidden = <STDIN>);
		my $paramRef = {
			name            => $paramName,
			type            => $type,
			typeDescription => $typeDescription,
			hidden          => $hidden,
		};
		push (@params, $paramRef);
		$counter++;
	}
	$counter = 1;
	my @environmentVariables = ();
	while(1) {
		my $toAddVars;
		if($counter == 1) {
			print "\nDo you want to add environment variables (y for yes, anything else for no): ";
			chomp($toAddVars = <STDIN>);
		} else {
			print "\nDo you want to continue adding environment variables (y for yes, anything else for no): ";
			chomp($toAddVars = <STDIN>);
		}
		if($toAddVars ne "y") {
			last;
		}
		print "\nEnvironmentVariable$counter name: ";
		chomp(my $environmentVariable = <STDIN>);
		push (@environmentVariables, $environmentVariable);
		$counter++;
	}
	print "\nTime out period (in seconds): ";
	chomp(my $timeOut = <STDIN>);
	return ($name, $commandTemplate, \@params, \@environmentVariables, $timeOut);
}

1;