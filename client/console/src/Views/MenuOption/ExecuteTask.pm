package Views::MenuOption::ExecuteTask;

use strict;
use warnings;

use Term::ReadKey;
use Term::ANSIScreen qw(:cursor :screen);

use parent "Views::MenuOption";

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(0);
	$self->setName("Execute task");
	return $self;
}

sub executeOption {
	my ($self) = @_;
	my $controller = $self->getController();
	my ($isRunning, $taskName) = $controller->isProcessRunning();
	if($isRunning) {
		print "\nA task is already running! You are being attached to it!\n\n";
		$self->monitorTask($controller, $taskName);
		return;
	}
	print "\nEnter task name to be executed: ";
	chomp(my $name = <STDIN>);
	my $model = $controller->readTask($name);
	my $hashRef = $model->getContent();
	if($hashRef->{error}) {
		return;
	}

	my $paramValues = $self->inputParamValues($hashRef->{parameters}, $controller);
	my $varsValues = $self->inputEnvironmentVariablesValues($hashRef->{environmentVariables});

	my $status = $controller->executeTask($name, $paramValues, $varsValues);
	if(!$status) {
		print "\nError when trying to execute process!\n";
		return;
	}

	$self->monitorTask($controller, $hashRef->{name});
}

sub inputParamValues {
	my ($self, $params, $controller) = @_;
	my $count = 1;
	my @paramValues;
	if(@$params != 0) {
		print "\nEnter parameters' values:\n\n";
	}
	foreach my $paramHash (@$params) {
		while(1) {
			print "\tParameter$count (".lc($paramHash->{typeDescription})."): ".$paramHash->{name}." = ";
			my $value;
			if($paramHash->{hidden} eq "true") {
				system("stty -echo"); ## hide the input
				chomp($value = <STDIN>);
				system ("stty echo"); ## return to normal
				print "\n";
			} else {
				chomp($value = <STDIN>);
			}
			if($controller->isParamValueValid($paramHash->{type}, $value)) {
				push(@paramValues, $value);
				last;
			} else {
				print "\nInvalid parameter value! Please enter valid ".lc($paramHash->{typeDescription})." value!\n\n";
			}
		}
		$count++;
	}
	return \@paramValues;
}

sub inputEnvironmentVariablesValues {
	my ($self, $environmentVariables) = @_;
	if(@$environmentVariables != 0) {
		print "\nSet required environment variables:\n\n";
	}

	my @values = ();
	foreach my $environmentVariable (@$environmentVariables) {
		print "\t$environmentVariable = ";
		chomp(my $value = <STDIN>);
		push(@values, $value);
	}
	return \@values;
}

sub monitorTask {
	my ($self, $controller, $taskName) = @_;
	print "\nTask '$taskName' output:\n\n";
	my $status;
	my $firstTimeFlag = 1;
	my $numberOfLines = 0;
	my $interruptKey = "";
	my $startLine = 0;
	while(1) {
		ReadMode(4);
		if(defined($interruptKey) && $interruptKey eq "p") {
			while(1) {
				$interruptKey = ReadKey(0); ## to block the loop when task is paused
				if($interruptKey eq "r" || $interruptKey eq "k") {
					last;
				}
			}
		} else {
			$interruptKey = ReadKey(-1);
		}
		if(defined($interruptKey) && $interruptKey eq "p") {
			if(!defined($status) || ($status ne "paused" && $status ne "killed")) {
				$status = $controller->pauseProcess();
			}
		}
		if(defined($interruptKey) && $interruptKey eq "r") {
			if(defined($status) && $status eq "paused") {
				$status = $controller->resumeProcess();
			}
		}
		if(defined($interruptKey) && $interruptKey eq "k") {
			if(!defined($status) || $status ne "killed") {
				$status = $controller->killProcess();
			}
		}
		my $hashRef = $controller->getOutputLines($startLine);

		if(!$firstTimeFlag) {
			up(2); ## clear the servicable message for Execution control
			cldown();
		} else {
			$firstTimeFlag = 0;
		}
		foreach my $line (@{$hashRef->{lines}}) {
			$startLine++;
			chomp($line);
			print "$line\n";
		}
		if($hashRef->{finished}) {
			last;
		}
		print "\nExecution control: 'p'->pause; 'r'->resume; 'k'->kill\n";
	}
	ReadMode(1);
}

1;