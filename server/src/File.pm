package File;

use strict;
use warnings;

use IO::File;
use Log::Log4perl;

use constant {
	ERR_WRITE_FILE      => "Error when trying to write content in file: %s",
	ERR_READ_FILE       => "Error when trying to read content from file: %s",
	ERR_FILE_NOT_EXIST  => "Requested file was not found!",
	ERR_FILE_DEL        => "Error when trying to delete file!",
};

my $logger = Log::Log4perl->get_logger();

sub new {
	my ($class, $filename) = @_;
	my $self = bless ({filename => $filename}, $class);
	return $self;
}

#getter
sub getFilename {
	my ($self) = @_;
	$self->{filename};
}

sub exists {
	$logger->info("File existance check was performed.\n");
	my ($self) = @_;
	if(-e $self->getFilename()) {
		$logger->info("The file was found.\n");
		return 1;
	}
	$logger->error("The file was not found.\n");
	return 0;
}

sub create {
	my ($self, $mode) = @_;
	return IO::File->new($self->getFilename(), $mode);
}

sub delete {
	my ($self) = @_;
	$logger->info("Attempted to delete file.\n");
	my $filename = $self->getFilename();
	my $status = unlink($filename);
    if(!$status) {
    	$logger->error("The file was not deleted.\n");
        return ERR_FILE_DEL;
    }
    $logger->info("The file was deleted successfully.\n");
    return undef;
}

sub writeContent {  ## reads the content from string and writes it in the file!!!
	my ($self, $content) = @_;
	$logger->info("Attempted to write content in file.\n");
	my $writeHandle = $self->create("w");
	if(!defined($writeHandle)) {
		$logger->error("Failed to write content in the file.\n");
		return sprintf(ERR_WRITE_FILE, $!);
	}
	$writeHandle->print($content);
	$writeHandle->close();
	$logger->info("File content was written successfully.\n");
	return undef;
}

sub readContent {  ## returns a string version of the file content
	my ($self) = @_;
	$logger->info("Attempted to read content from file.\n");
	my $filename = $self->getFilename();
	if(!$self->exists()) {
		return (undef, ERR_FILE_NOT_EXIST);
	}
	my $readHandle = $self->create("r");
	if(!defined($readHandle)) {
		$logger->error("Failed to read content from the file.\n");
		return (undef, sprintf(ERR_READ_FILE, $!));
	}
	my $content = join("", <$readHandle>);
	$readHandle->close();
	$logger->info("File content was read successfully.\n");
	return ($content, undef);
}

1;