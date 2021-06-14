package Model::Task;

use parent "Model";

use strict;
use warnings;

use File::Spec;

use Model::Parameter;
use File::XMLFile;
use File::JSONFile;
use File;
use Log::Log4perl;

use constant {
    ERR_TASK_SPACES           => "Task name cannot contain spaces!",
    ERR_TASK_UNDEF            => "Task name must be defined and cannot be empty!",
    ERR_DUPLICATE_TASK        => "There is already a task with this name!",
    ERR_CMD_TPL               => "Invalid command template!",
    ERR_PARAM_NUMBER_MISMATCH => "The number of placeholders for parameter values in the command template must match the number of added parameters!",
    ERR_CMD_TPL_UNDEF         => "Command template must be defined and cannot be empty and the parametes must be in array!",
    ERR_PARAMS_ARR            => "The parameters must be in array reference!",
    ERR_ENV_SPACES            => "Environment variable names cannot contain spaces!",
    ERR_ENV_UNDEF             => "Environment variable names must be defined and cannot be empty!",
    ERR_INVALID_ENV           => "Environment variable names can only contain letters, digits and underscores!",
    ERR_ENV_BEGIN_DIGIT       => "Environment variable names cannot begin with a digit!",
    ERR_TIME_OUT              => "The time out period must be a number (in seconds) and cannot be negative!",
    ERR_TIME_OUT_UNDEF        => "The time out period must be defined!",
};

my $logger = Log::Log4perl->get_logger();

sub new {
	my ($class, $hashRef) = @_;
    my $self = bless({}, $class);
    $self->setName($hashRef->{name});
    $self->setCommandTemplate($hashRef->{commandTemplate});
    $self->setParameters([]);
    $self->setEnvironmentVariables($hashRef->{environmentVariables}); 
    $self->setTimeOut($hashRef->{timeOut}); ## 0 means that there is no time out period

    ## to make sure that there isn't undefined data but at least empty:
    if(!defined($hashRef->{parameters})) {
        $self->setParameters([]);
    }
    if(!defined($hashRef->{environmentVariables})) {
        $self->setEnvironmentVariables([]);
    }

    ## converting the hashes of parameters to Parameter objects:
    foreach my $paramHash (@{$hashRef->{parameters}}) {
        $self->addParameter(Model::Parameter->new($paramHash));
    }
    $logger->debug("New Task object was created.\n");
    return $self;
}

sub toHash {
    my ($self) = @_;
    my @hashParams = ();
    foreach my $param (@{$self->getParameters()}) {
        push (@hashParams, $param->toHash())
    }
    my $hashRef = {
        name                 => $self->getName(),
        commandTemplate      => $self->getCommandTemplate(),
        parameters           => \@hashParams,
        environmentVariables => $self->getEnvironmentVariables(),
        timeOut              => $self->getTimeOut(),
    };
    return $hashRef;
}

sub addParameter {
    my ($self, $param) = @_;
    $self->{parameters} //= [];
    push(@{$self->{parameters}}, $param);
}

sub validate {
    my ($self) = @_;
    $logger->info("Task validation was performed.\n");

    ## getting task properties:
    my $name = $self->getName();
    my $commandTemplate = $self->getCommandTemplate();
    my $parameters = $self->getParameters();
    my $environmentVariables = $self->getEnvironmentVariables();
    my $timeOut = $self->getTimeOut();

    if($name) {
        if($name =~ /\s/) { ## name can't have spaces
            $logger->warn("Task name containing spaces was detected.\n");
            return ERR_TASK_SPACES;
        }
    } else {
        $logger->warn("Undefined task name was detected.\n");
        return ERR_TASK_UNDEF; ## name must be defined or not empty
    }
    if($commandTemplate && (ref($parameters) eq "ARRAY")) {
        if(!($commandTemplate =~ /\A$name( \{\w+?\}| \w+ \{\w+?\}| --\w+ \{\w+?\}| -\w+=\{\w+?\}| --\w+=\{\w+?\}| -\w+| --\w+)*\z/)) { ## template must match this pattern
            $logger->warn("Invalid command template was detected.\n");
            return ERR_CMD_TPL;
        }
        
        my @placeholders = ($commandTemplate =~ /{\w+?}/g);
        my $numberOfPlaceholders = @placeholders;
        my $numberOfParameters = @{$parameters};
        if($numberOfPlaceholders != $numberOfParameters) {
            $logger->warn("Different number of placeholders('{' and '}' pairs) and parameters was detected.\n");
            return ERR_PARAM_NUMBER_MISMATCH; ## number of {} couples must be the same as number of parameters in the array
        }

        foreach my $i (0..$#$parameters) { ## parameters validation
            my $error = $parameters->[$i]->validate($placeholders[$i]);
            if($error) {
                return $error;
            }
        }
    } else {
        if(!$commandTemplate) { ## command template must be defined and not empty
            $logger->warn("Undefined command template was detected.\n");
            return ERR_CMD_TPL_UNDEF;
        }
        if(!(ref($parameters) eq "ARRAY")) { ## parameters must be in ARRAY
            $logger->warn("Not an array structure for parameters was detected.\n");
            return ERR_PARAMS_ARR;
        }
    }
    foreach my $environmentVariable (@$environmentVariables) {
        if($environmentVariable) {
            if($environmentVariable =~ /\s/) { ## environment variables can't contain spaces
                $logger->warn("Environment variable containing spaces was detected.\n");
                return ERR_ENV_SPACES;
            } elsif($environmentVariable =~ /[^0-9a-zA-z_]/) {
                $logger->warn("Invalid symbols in environment variable name were detected.\n");
                return ERR_INVALID_ENV;
            } elsif($environmentVariable =~ /\A[0-9]/) {
                $logger->warn("Leading digit in environment variable name was detected.\n");
                return ERR_ENV_BEGIN_DIGIT;
            }
        } else {
            $logger->warn("Undefined environment variable name was detected.\n");
            return ERR_ENV_UNDEF; ## env vars must be defined and cannot be empty
        }
    }
    if(defined($timeOut)) {
        if($timeOut =~ /[^0-9]/) {
            $logger->warn("Not a number or negative number for time out period was detected.\n");
            return ERR_TIME_OUT;
        }
    } else {
        $logger->warn("Undefined time out period was detected.\n");
        return ERR_TIME_OUT_UNDEF;
    }
    $logger->info("Task object passed the validation test.\n");
    return undef; ## if everything is fine
}

## check whether task with current name already exists:
sub checkForDuplicates {
    my ($self) = @_;
    $logger->info("A check for task duplication was performed.\n");
    my $name = $self->getName();
    my $filepath = File::Spec->catfile("tasks", $name);
    if((-e "$filepath.json") || (-e "$filepath.xml")) {
        $logger->warn("Task duplication was detected.\n");
        return ERR_DUPLICATE_TASK;
    }
    $logger->info("Task object passed the duplication test.\n");
    return undef; ## there isn't such task
}

sub create {
    my ($self, $format) = @_;
    $logger->info("Task creation was performed.\n");
    my $taskName = $self->getName();
    my $filename = File::Spec->catfile("tasks", "$taskName.$format");
    my $file;
    if($format eq "json") {
        $file = File::JSONFile->new($filename);
    } elsif($format eq "xml") {
        $file = File::XMLFile->new($filename);
    }

    ## lowercase typeDescription and hidden values of parameters
    foreach my $param(@{$self->getParameters()}) {
        $param->setTypeDescription(lc($param->getTypeDescription()));
        $param->setHidden(lc($param->getHidden()));
    }
    my $hashRef = $self->toHash();
    my $content = $file->unparse($hashRef);
    return $file->writeContent($content); ## returns the error if such occured
}

sub read { ## static method
    my ($class, $filename, $format) = @_;
    $logger->info("Task reading was performed.\n");
    my $file;
    if($format eq "json") {
        $file = File::JSONFile->new($filename);
    } elsif($format eq "xml") {
        $file = File::XMLFile->new($filename);
    }
    my ($content, $error) = $file->readContent();
    if($error) { ## readContent error
        return (0, { error => $error});
    }
    my $hashRef = $file->parse($content);
    $logger->info("Reading task finished successfully.\n");
    return (1, $hashRef);
}

sub update {
    my ($self, $oldFilename, $format) = @_;
    $logger->info("Task update was performed.\n");

    my ($stat, $hashRef) = Model::Task->read($oldFilename, $format);
    if(!$stat) {
        return $hashRef->{error};
    }

    my $oldTask = Model::Task->new($hashRef);

    my $error = $self->create($format);

    if($error) {
        $logger->warn("Task creation did not finish with success.\n");
        return $error;
    }

    if($oldTask->getName() ne $self->getName()) {
        $error = Model::Task->delete($oldFilename);
        if($error) {
            return $error;
        }
    }
    $logger->info("Updating task finished successfully.\n");
    return undef;
}

sub delete { ## static method
    my ($class, $filename) = @_;
    my $fileToDelete = File->new($filename);
    my $error = $fileToDelete->delete();
    if($error) {
        $logger->warn("Deleting task was unsuccessfull.\n");
        return $error;
    }
    $logger->info("Deleting task finished successfully.\n");
    return undef;
}

## if the user wants to keep some of the old features by entering "-":
sub updateTaskFeatures {
    my ($self, $oldFilename, $format) = @_;
    $logger->info("Task features update was performed.\n");
    my $params = $self->getParameters();
    my $environmentVariables = $self->getEnvironmentVariables();

    my ($stat, $oldContent) = Model::Task->read($oldFilename, $format);
    if(!$stat) {
        return $oldContent->{error};
    }

    if($self->getName() && $self->getName() eq "-") {
        $logger->debug("Task name was not updated.\n");
        $self->setName($oldContent->{name});
    }
    if($self->getCommandTemplate() && $self->getCommandTemplate() eq "-") {
        $logger->debug("Command template was not updated.\n");
        $self->setCommandTemplate($oldContent->{commandTemplate});
    }
    my @oldParams = @{$oldContent->{parameters}};
    foreach my $i (0..$#$params) {
        my $newParam = $self->getParameters()->[$i];
        my $oldParamHash = $oldParams[$i];
        $newParam->updateParamFeatures($oldParamHash);
    }
    $logger->debug("Update of environment variables names was performed.\n");
    my @oldVars = @{$oldContent->{environmentVariables}};
    foreach my $i (0..$#$environmentVariables) {
        if($oldVars[$i]) {
            if($environmentVariables->[$i] eq "-") {
                $logger->debug("Environment variable name was not updated.\n");
                $environmentVariables->[$i] = $oldVars[$i];
            }
        }
    }
    if($self->getTimeOut() && $self->getTimeOut() eq "-") {
        $logger->debug("Task time out period was not updated.\n");
        $self->setTimeOut($oldContent->{timeOut});
    }
    return undef;
}

#getters
sub getName {
	my ($self) = @_;
	return $self->{name};
}

sub getCommandTemplate {
    my ($self) = @_;
    return $self->{commandTemplate};
}

sub getParameters {
   my ($self) = @_;
    return $self->{parameters}
}

sub getEnvironmentVariables {
    my ($self) = @_;
    return $self->{environmentVariables};
}

sub getTimeOut {
    my ($self) = @_;
    return $self->{timeOut};
}

#setters
sub setName {
    my ($self, $name) = @_;
    $self->{name} = $name;
}

sub setCommandTemplate {
    my ($self, $commandTemplate) = @_;
    $self->{commandTemplate} = $commandTemplate;
}

sub setParameters {
    my ($self, $parameters) = @_;
    $self->{parameters} = $parameters;
}

sub setEnvironmentVariables {
    my ($self, $environmentVariables) = @_;
    $self->{environmentVariables} = $environmentVariables;
}

sub setTimeOut {
    my ($self, $timeOut) = @_;
    $self->{timeOut} = $timeOut;
}

sub execute {
	my ($self, $executableTask, $varsValues) = @_;

    ## setting environment variables:
    my $environmentVariables = $self->getEnvironmentVariables();
    foreach my $i (0..$#$environmentVariables) {
        $ENV{$environmentVariables->[$i]} = $varsValues->[$i];
    }
    $logger->debug("Required environment variables were set.\n");
    $logger->info("Task execution has started.\n");
    if(!exec($executableTask)) {
        return 0;
    }
}

1;