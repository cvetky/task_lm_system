package File::JSONFile;

use strict;
use warnings;

use parent "File", "Interfaces::Parsable";
use JSON;
use Log::Log4perl;

my $logger = Log::Log4perl->get_logger();

sub new {
	my ($class, $filename) = @_;
	if($filename =~ /.+\.json\z/) { ## ensure that JSON is requested
		my $self = $class->SUPER::new($filename); ## calling the super constructor
		$logger->debug("JSON file object was created.\n");
		return $self;
	} else {
		$logger->fatal("Non-JSON file format was detected in JSONFile constructor.\n");
		die "Invalid file format! JSON required!";
	}
}

sub parse { ## converts JSON content to Task object
	my ($self, $content) = @_;
	## parsing
	my $hashRef = from_json($content);
	$logger->debug("JSON file content was parsed to a hash.\n");
	return $hashRef;
}

sub unparse {
	my ($self, $hashRef) = @_;
	#unparsing
	$logger->info("A hash was unparsed to JSON content.\n");
	return to_json($hashRef); ## returns the JSON content to write in the file
}

1;