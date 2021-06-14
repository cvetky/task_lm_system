package Adapter; ## singleton class for the needs of the REST API

use File;
use Configurator;
use Model::Task;
use StatisticsManager;
use JSON;
use File::Spec;

use threads;
use threads::shared;
use Thread::Semaphore;
use Log::Log4perl;
use IPC::Signal 'sig_name';
use POSIX 'strftime';
use UUID::Generator::PurePerl;

use Dancer2;

my $logger = Log::Log4perl->get_logger();
my $instance = undef;
my @outputLines :shared = ();
my $processId :shared;
my $taskName :shared;
my %executionData :shared;
my $terminatingThread;

sub getInstance {
	my ($class) = @_;
	if(!defined($instance)) {
		$instance = bless({}, $class);
	}
	return $instance;
}

sub getOutputLines {
	my ($self, $startLine) = @_;
	lock(@outputLines);
	my @lines = ();
	my $finished = 0;
	for (my $i = $startLine; $i <= $#outputLines; $i++) {
		if(defined($outputLines[$i])) {
			push(@lines, $outputLines[$i]);
		}	
	}
	if(@lines == 0) {
		if(!$self->isProcessRunning()) {
			$finished = 1;
		}
	}

	## indicates if we reached the last line which is generated by the server:
	$logger->debug("Available number of output lines were read.\n");
	return (\@lines, $finished);
}

sub addOutputLine {
	my ($self, $line) = @_;
	lock(@outputLines);
	push(@outputLines, $line);
}

sub clearOutput {
	$logger->debug("Any previous output was cleared.\n");
	lock(@outputLines);
	@outputLines = ();
}

sub isProcessRunning {
	$logger->debug("Check for running process was made.\n");
	lock($processId);
	return $processId;
}

sub setProcessId {
	my($self, $pid) = @_;
	lock($processId);
	$processId = $pid;
}

sub getTaskName {
	lock($taskName);
	return $taskName;
}

sub setTaskName {
	my($self, $tn) = @_;
	$taskName = $tn;
}

sub addExecutionData {
	my ($self, $key, $value) = @_;
	lock(%executionData);
	$executionData{$key} = shared_clone($value);
}

sub clearExecutionData {
	lock(%executionData);
	%executionData = (
		"reached_timeout" => "false",
		"pause_count" => 0,
	);
}

sub getExecutionData {
	my ($self, $key) = @_;
	lock(%executionData);
	return $executionData{$key};
}

sub getAllTasks {
	my @allTasks = ();
	my $format = Configurator->getTaskFormat();
	my $tasksPath = File::Spec->catfile("tasks", "*.$format");
	my @files = glob($tasksPath);

	my @sortedFiles = sort {
		return (lc($a) cmp lc($b));
	} @files;

	foreach my $filename (@sortedFiles) {
		my ($stat, $hashRef) = Model::Task->read($filename, $format);
		if(!$stat) {
			return (0, $hashRef);
		}
		push @allTasks, $hashRef;
	}

	return (1, \@allTasks);
}

sub getRequestedTask {
	my ($self, $name) = @_;
	my $format = Configurator->getTaskFormat();
	my $filename = File::Spec->catfile("tasks", "$name.$format");

	## first check for existance
	my $file = File->new($filename);
	my $exists = $file->exists();
	if(!$exists) {
		return (0, { error => "Requested task was not found!" });
	}

	my ($stat, $hashRef) = Model::Task->read($filename, $format);
	return ($stat, $hashRef);
}

sub addNewTask {
	my ($self, $body) = @_;
	my $format = Configurator->getTaskFormat();
	my $hashRef = from_json($body);
	my $taskObject = Model::Task->new($hashRef);

	my $error = $taskObject->validate();
	if ($error) {
		return (0, $error);
	}

	$error = $taskObject->checkForDuplicates();
	if ($error) {
		return (0, $error);
	}

	$error = $taskObject->create($format);
	if ($error) {
		$logger->warn("Task creation did not finish with success.\n");
		return (0, $error);
	}

	$logger->info("New task was added in the list.\n");
	return (1, undef);
}

sub updateTask {
	my ($self, $oldName, $body) = @_;
	my $format = Configurator->getTaskFormat();
	my $oldFilename = File::Spec->catfile("tasks", "$oldName.$format");

	## first check for existace of old task!
	my $oldFile = File->new($oldFilename);
	my $exists = $oldFile->exists();
	if(!$exists) {
		return (0, "Requested task was not found!");
	}

	my $hashRef = from_json($body);
	my $newTaskObject = Model::Task->new($hashRef);

	my $error = $newTaskObject->updateTaskFeatures($oldFilename, $format);
	if($error) {
		return (0, $error);
	}

	$error = $newTaskObject->validate();

	if($error) {
		return (0, $error);
	}

	if($oldName ne $newTaskObject->getName()) {
		$error = $newTaskObject->checkForDuplicates();
		if($error) {
			return (0, $error);
		}
	}

	$error = $newTaskObject->update($oldFilename, $format);

	if ($error) {
		return (0, $error);
	}

	return (1, undef);
}

sub deleteRequestedTask {
	my ($self, $name) = @_;
	my $format = Configurator->getTaskFormat();
	my $filename = File::Spec->catfile("tasks", "$name.$format");

	## first check for existance
	my $file = File->new($filename);
	my $exists = $file->exists();
	if(!$exists) {
		return (0, "Requested task was not found!");
	}

	my $error = Model::Task->delete($filename);

	if($error) {
		return (0, $error);
	}
	return (1, undef);
}

sub deleteAllTasks {
	my $format = Configurator->getTaskFormat();
	my $tasksPath = File::Spec->catfile("tasks", "*.$format");
	my @files = glob($tasksPath);
	foreach my $filename (@files) {
		my $error = Model::Task->delete($filename);
		if($error) {
			return (0, $error);
		}
	}
	return (1, undef);
}

sub isParamValueValid {
	$logger->info("Validation of parameter value was performed.\n");
	my ($self, $body) = @_;
	my $hashRef = from_json($body);
	my $type = $hashRef->{type};
	my $value = $hashRef->{value};
	if(!defined($value) || $value eq "") {
		$logger->warn("Empty parameter value was detected.\n");
		return 0; ## user must specify value for each param
	}
	if($type eq "i") { ## integer
		if(($value =~ /\A-?[0-9]+\z/) && !($value =~ /\A0/)) {
			$logger->info("Valid integer parameter value was detected.\n");
			return 1;
		}
		$logger->warn("Invalid integer parameter value was detected.\n");
		return 0;
	} elsif($type eq "b") { ## boolean
		if($value =~ /\A(true|1|yes|y|false|0|no|n)\z/i) {
			$logger->info("Valid boolean parameter value was detected.\n");
			return 1;
		}
		$logger->warn("Invalid boolean parameter value was detected.\n");
		return 0;
	} elsif($type eq "r") { ## real number
		if($value =~ /\A-?[0-9]+\z/) {
			$logger->info("Valid real number parameter value was detected.\n");
			return 1; ## valid integer (subpart of real numbers)
		}
		if($value =~ /\A-?[0-9]+[.][0-9]+\z/) {
			$logger->info("Valid real number parameter value was detected.\n");
			return 1; ## valid real number - only decimal point accepted
		}
		$logger->warn("Invalid real number parameter value was detected.\n");
		return 0;
	}
	$logger->info("Valid string parameter value was detected.\n");
	return 1; ## valid string
}

## only for WebUI
sub isParamValuesArrayValid {
	my ($self, $bodyOfBodies) = @_;
	my $isValid = 1;
	my $bodies = from_json($bodyOfBodies);
	foreach my $body(@{$bodies}) {
		if(!$self->isParamValueValid(to_json($body))){
			$isValid = 0;
			last;
		}
	}
	return $isValid;
}

sub executeTask {
	my ($self, $name, $body) = @_;
	my $hashRef = from_json($body);
	my $paramValues = $hashRef->{paramValues};
	my $varsValues = $hashRef->{varsValues};

	my ($stat, $taskHash) = $self->getRequestedTask($name);

	if(!$stat) {
		return undef;
	}
	
	my $task = Model::Task->new($taskHash);

	## creating the task to be executed
	my $executableTask = $task->getCommandTemplate();

	foreach my $value (@$paramValues) {
		$executableTask =~ s/{\w+?}/$value/;
	}
	$logger->info("Executable task was constructed.\n");

	$self->clearOutput();
	$self->clearExecutionData();

	pipe(my $read, my $write);
	$write->autoflush(1);
	$logger->info("I/O pipe was created.\n");

	my $startTime = time();
	my $pid = fork();
	if(!defined($pid)) {
		$logger->error("Child process was not forked.\n");
		return undef;
	}
	$logger->info("Child process was forked.\n");
	if(!$pid) {
		## child
		close($read);

		open(STDOUT, ">&=", $write);
		open(STDERR, ">&=", $write);
		$logger->info("STDOUT and STDERR were redirected to a pipe.\n");
		setpgrp(); ## to be able to kill the whole process group on time out when task forks child processes

		my $stat = $task->execute($executableTask, $varsValues);
		if(!$stat) {
			exit(1);
		}
	} else {
		## parent
		close($write);

		## thread to read the output and wait the process to finish
		async {
			$logger->info("Thread to read output from the task and wait for it to finish was launched.\n");
			$self->setProcessId($pid);
			$self->setTaskName($task->getName());

			while(my $line = <$read>) {
				$self->addOutputLine($line);
			}
			$logger->debug("Task output was read and collected in an array.\n");
			
			waitpid($pid, 0);
			my $status = $?;

			my $endTime = time();
			my $taskExitCode = $status >> 8;
			my $signalNumber = $status & 127;
			my $signal = sig_name($signalNumber);

			$self->storeExecutionData($executableTask, $startTime, $endTime, $taskExitCode, $signal, $task);
			$logger->info("Task execution has finished.\n");

			$self->addOutputLine("\nMessage: Execution has finished! Exit code is: $taskExitCode\n");
			$self->setProcessId(undef);
			$self->setTaskName(undef);
		}->detach();

		## thread to terminate the process after time out
		$terminatingThread = async {
			$logger->info("Thread to wait for time out of the task was launched.\n");
			my $seconds = $task->getTimeOut();
			my $now = time();
			my $isPaused = 0;
			$SIG{"TSTP"} = sub {
				## pauses the timer for time out period
				$isPaused = 1;
				$seconds = $seconds - (time() - $now);
				while($isPaused) {
					sleep(1);
				}
				$self->waitForTimeOutPeriod($seconds, $pid);
			};

			$SIG{"ALRM"} = sub {
				$isPaused = 0;
			};
			$self->waitForTimeOutPeriod($seconds, $pid, $now);
		};
		$terminatingThread->detach();
	}
	return $pid;
}

sub storeExecutionData {
	my ($self, $executableTask, $startTime, $endTime, $taskExitCode, $signal, $task) = @_;

	my $uniqueIdGenerator = UUID::Generator::PurePerl->new();
	my $generatedUid = $uniqueIdGenerator->generate_v1();

	my $uniqueTaskId = $generatedUid->as_string();
	my $taskName = $self->getTaskName();
	my $numberOfParameters = @{$task->getParameters()};
	my $executionDurationSeconds = $endTime - $startTime;
	my $startDateUTC = strftime("%d/%m/%Y %H:%M:%S", gmtime($startTime));
	my $endDateUTC = strftime("%d/%m/%Y %H:%M:%S", gmtime($endTime));
	my ($executionOutputLines, $_) = $self->getOutputLines(0);
	my $lastLinesCount = 3;
	my @lastOutputLines = (@$executionOutputLines <= $lastLinesCount) ? @$executionOutputLines : @$executionOutputLines[-$lastLinesCount..-1];
	my $lastOutputLinesStr = join("", @lastOutputLines);

	$self->addExecutionData("id", $uniqueTaskId);
	$self->addExecutionData("task_name", $taskName);
	$self->addExecutionData("executable_command", $executableTask);
	$self->addExecutionData("number_of_parameters", $numberOfParameters);
	$self->addExecutionData("start_date_utc", $startDateUTC);
	$self->addExecutionData("end_date_utc", $endDateUTC);
	$self->addExecutionData("duration_seconds", $executionDurationSeconds);
	$self->addExecutionData("exit_code", $taskExitCode);
	$self->addExecutionData("last_3_output_lines", $lastOutputLinesStr);
	$self->addExecutionData("signal", $signal);
	$self->addExecutionData("timeout_period_seconds", $task->getTimeOut());
	$self->addExecutionData("environment_variables", join(", ", @{$task->getEnvironmentVariables()}));

	my $statsManager = StatisticsManager->new(\%executionData, Configurator->getAdlsServerUrl());
	$statsManager->saveStatisticsData($taskName);
}

## recursively remembers how many seconds have elapsed if the task is paused
sub waitForTimeOutPeriod {
	my ($self, $seconds, $pid, $now) = @_;
	my $isPaused = 0;

	if($seconds > 0) { ## if it is 0 -> no time out period

		## timer for time out period
		foreach (1..$seconds) {
			sleep(1);
		}

		my $num;
		if($self->isProcessRunning()) {
			$num = kill(-9, $pid);
			$logger->debug("KILL signal was sent to the child process.\n");
		}
		if($num) {
			$self->addExecutionData("reached_timeout", "true");
			$logger->info("Task was killed because it did not finish during its time out period.\n");
			$self->addOutputLine("\nTime out! Task execution didn't finish during the specified time out period!\n");
		}
	}
}

sub pauseProcess {
	my ($self) = @_;
	my $pid = $self->isProcessRunning();
	my $stat;
	if($pid) {
		$stat = kill("-TSTP", $pid);
		$terminatingThread->kill("TSTP");
		if($stat) {
			my $pauseCountKey = "pause_count";
			my $currentPauseCount = $self->getExecutionData($pauseCountKey);
			$self->addExecutionData($pauseCountKey, $currentPauseCount + 1);

			$logger->info("Running process was paused by the user.\n");
			$self->addOutputLine("\nTask has been paused!\n\n");
		}
	}
	return $stat;
}

sub resumeProcess {
	my ($self) = @_;
	my $pid = $self->isProcessRunning();
	my $stat;
	if($pid) {
		$stat = kill("-CONT", $pid);
		$terminatingThread->kill("ALRM");
		if($stat) {
			$logger->info("Paused process was resumed.\n");
		}
	}
	return $stat;
}

sub killProcess {
	my ($self) = @_;
	my $pid = $self->isProcessRunning();
	my $stat;
	if($pid) {
		$stat = kill("-KILL", $pid);
	}
	if($stat) {
		$logger->info("Task was killed by the user.\n");
		$self->addOutputLine("\nTask has been killed successfully!\n");
	}
	return $stat;
}

1;