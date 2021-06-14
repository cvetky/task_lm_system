package Model;

use strict;
use warnings;

use JSON;

use Model::Headers;

sub new {
	my ($class, $hashRef) = @_;
	my $self = bless({}, $class);
	$self->setSuccess($hashRef->{success}); ## 1 or 0
	$self->setProtocol($hashRef->{protocol});
	$self->setHeaders(Model::Headers->new($hashRef->{headers}));
	$self->setContent(from_json($hashRef->{content})); ## json hash
	$self->setUrl($hashRef->{url});
	$self->setReason($hashRef->{reason}); ## OK, NOT FOUND etc.
	$self->setStatus($hashRef->{status});
	return $self;
}

## getters and setters
sub getSuccess {
	my ($self) = @_;
	return $self->{success};
}

sub getProtocol {
	my ($self) = @_;
	return $self->{protocol};
}

sub getHeaders {
	my ($self) = @_;
	return $self->{headers};
}

sub getContent {
	my ($self) = @_;
	return $self->{content};
}

sub getUrl {
	my ($self) = @_;
	return $self->{url};
}

sub getReason {
	my ($self) = @_;
	return $self->{reason};
}

sub getStatus {
	my ($self) = @_;
	return $self->{status};
}

sub setSuccess {
	my ($self, $success) = @_;
	$self->{success} = $success;
}

sub setProtocol {
	my ($self, $protocol) = @_;
	$self->{protocol} = $protocol;
}

sub setHeaders {
	my ($self, $headers) = @_;
	$self->{headers} = $headers;
}

sub setContent {
	my ($self, $content) = @_;
	$self->{content} = $content;
}

sub setUrl {
	my ($self, $url) = @_;
	$self->{url} = $url;
}

sub setReason {
	my ($self, $reason) = @_;
	$self->{reason} = $reason;
}

sub setStatus {
	my ($self, $status) = @_;
	$self->{status} = $status;
}

sub paramsToStr {
	my ($self, $arrayRef) = @_;
	my $output = "";
	if(@$arrayRef == 0) {
		return "The task has no parameters!\n";
	}
	my $count = 1;
	$output .= "Parameters:\n";
	foreach my $paramHash (@$arrayRef) {
		$output .= "Parameter$count:\n";
		$output .= "\tName: ".$paramHash->{name}."\n";
		$output .= "\tType: ".$paramHash->{type}."\n";
		$output .= "\tTypeDescription: ".$paramHash->{typeDescription}."\n";
		$output .= "\tHidden: ".$paramHash->{hidden}."\n";
		$count++;
	}
	return $output;
}

sub environmentVariablesToStr {
	my ($self, $arrayRef) = @_;
	my $output = "";
	if(@$arrayRef == 0) {
		return "The task has no environment variables to be set!\n";
	}
	my $count = 1;
	foreach my $environmentVariable (@$arrayRef) {
		$output .= "EnvironmentVar$count: ".$environmentVariable."\n";
		$count++;
	}
	return $output;
}

sub taskHashToString {
	my ($self, $hashRef) = @_;
	my $output = "";
	$output .= "Name: ".$hashRef->{name}."\n";
	$output .= "CommandTemplate: ".$hashRef->{commandTemplate}."\n";
	$output .= $self->paramsToStr($hashRef->{parameters});
	$output .= $self->environmentVariablesToStr($hashRef->{environmentVariables});
	$output .= "Time out period: ".$hashRef->{timeOut}." seconds\n";
	return $output;
}

sub toString {
	my ($self) = @_;
	my $content = $self->getContent();
	my $output = "";
	if(ref($content) eq "ARRAY") {
		if(@$content == 0) {
			return "There are no added tasks!\n";
		}
		my $count = 1;
		foreach my $taskHash (@$content) {
			$output .= "\n~~Task$count~~\n".$self->taskHashToString($taskHash)."\n";
			$count++;
		}
	} else {
		if($content->{error}) {
			return $content->{error}."\n";
		} elsif($content->{success}) {
			return $content->{success}."\n";
		}
		$output .= "\n~~Chosen task~~\n".$self->taskHashToString($content)."\n";
	}
	return $output;
}

1;