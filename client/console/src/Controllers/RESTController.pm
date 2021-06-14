package Controllers::RESTController;

use strict;
use warnings;

use JSON;
use HTTP::Tiny;
use URI::Escape;

use Model;
use Views::FinalOutput;
use Configurator;

sub new {
	my ($class) = @_;
	return bless({}, $class);
}

sub createTask {
	my ($self, $name, $commandTemplate, $parameters, $environmentVariables, $timeOut) = @_;
	my $url = Configurator->getURL();
	my $body = $self->generateBody($name, $commandTemplate, $parameters, $environmentVariables, $timeOut);
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("POST", "$url/tasks", { content => $body } );
	my $model = Model->new($hashRef);
	$self->sendToView($model);
}

sub updateTask {
	my ($self, $oldName, $newName, $commandTemplate, $parameters, $environmentVariables, $timeOut) = @_;
	my $url = Configurator->getURL();
	my $body = $self->generateBody($newName, $commandTemplate, $parameters, $environmentVariables, $timeOut);
	my $escapedOldName = uri_escape($oldName);
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("PUT", "$url/tasks/$escapedOldName", { content => $body } );
	my $model = Model->new($hashRef);
	$self->sendToView($model);
}

sub readTask {
	my ($self, $name) = @_;
	my $url = Configurator->getURL();
	my $escapedName = uri_escape($name);
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("GET", "$url/tasks/$escapedName");
	my $model = Model->new($hashRef);
	$self->sendToView($model);
	return $model;
}

sub readAllTasks {
	my ($self) = @_;
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("GET", "$url/tasks");
	my $model = Model->new($hashRef);
	$self->sendToView($model);
}

sub deleteTask {
	my ($self, $name) = @_;
	my $url = Configurator->getURL();
	my $escapedName = uri_escape($name);
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("DELETE", "$url/tasks/$escapedName");
	my $model = Model->new($hashRef);
	$self->sendToView($model);
}

sub deleteAllTasks {
	my ($self) = @_;
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("DELETE", "$url/tasks");
	my $model = Model->new($hashRef);
	$self->sendToView($model);
}

sub isParamValueValid {
	my ($self, $type, $value) = @_;
	my $url = Configurator->getURL();
	my $bodyHash = {
		type  => $type,
		value => $value,
	};
	my $body = to_json($bodyHash);
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("POST", "$url/param", { content => $body } );
	my $model = Model->new($hashRef);
	if($model->getStatus() == 200) {
		return 1;
	}
	return 0;
}

sub executeTask {
	my ($self, $name, $paramValues, $varsValues) = @_;
	my $url = Configurator->getURL();
	my $bodyHash = {
		paramValues => $paramValues,
		varsValues  => $varsValues,
	};
	my $body = to_json($bodyHash);
	my $escapedName = uri_escape($name);
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("POST", "$url/exec/$escapedName", { content => $body } );
	my $model = Model->new($hashRef);
	if($model->getStatus() == 200) {
		return 1;
	}
	return 0;
}

sub getOutputLines {
	my ($self, $startLine) = @_;
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $escapedStartLine = uri_escape($startLine);
	my $hashRef = $restHandler->request("GET", "$url/outputLines/$escapedStartLine");
	my $model = Model->new($hashRef);
	return $model->getContent();
}

sub isProcessRunning {
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("GET", "$url/isTaskRunning");
	my $model = Model->new($hashRef);
	return ($model->getContent()->{isRunning}, $model->getContent()->{taskName});
}

sub pauseProcess() {
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("POST", "$url/pause");
	my $model = Model->new($hashRef);
	return $model->getContent()->{status};
}

sub resumeProcess {
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("POST", "$url/resume");
	my $model = Model->new($hashRef);
	return $model->getContent()->{status};
}

sub killProcess {
	my $url = Configurator->getURL();
	my $restHandler = HTTP::Tiny->new();
	my $hashRef = $restHandler->request("POST", "$url/kill");
	my $model = Model->new($hashRef);
	return $model->getContent()->{status};
}

sub generateBody {
	my ($self, $name, $commandTemplate, $parameters, $environmentVariables, $timeOut) = @_;
	my $hashRef = {
		name                 => $name,
		commandTemplate      => $commandTemplate,
		parameters           => $parameters,
		environmentVariables => $environmentVariables,
		timeOut              => $timeOut,
	};
	return to_json($hashRef);
}

sub sendToView {
	my ($self, $model) = @_;
	my $view = $self->getView($model);
	$view->outputModel();
}

sub getView {
	my ($self, $model) = @_;
	$self->{view} = Views::FinalOutput->new($model);
	return $self->{view}; ## allow different views because the model may be different
}

1;