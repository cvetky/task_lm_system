package Model::Headers;

use parent "Model";

use strict;
use warnings;

sub new {
	my ($class, $hashRef) = @_;
	my $self = bless({}, $class);
	$self->setServer($hashRef->{server});
	$self->setContentType($hashRef->{"content-type"});
	$self->setContentLength($hashRef->{"content-length"});
	$self->setDate($hashRef->{date});
	return $self;
}

#getters and setters
sub getServer {
	my ($self) = @_;
	return $self->{server};
}

sub getContentType {
	my ($self) = @_;
	return $self->{contentType};
}

sub getContentLength {
	my ($self) = @_;
	return $self->{contentLength};
}

sub getDate {
	my ($self) = @_;
	return $self->{date};
}

sub setServer {
	my ($self, $server) = @_;
	$self->{server} = $server;
}

sub setContentType {
	my ($self, $contentType) = @_;
	$self->{contentType} = $contentType;
}

sub setContentLength {
	my ($self, $contentLength) = @_;
	$self->{contentLength} = $contentLength;
}

sub setDate {
	my ($self, $date) = @_;
	$self->{date} = $date;
}

1;