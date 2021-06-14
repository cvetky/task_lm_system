package File::XMLFile;

use strict;
use warnings;

use parent "File", "Interfaces::Parsable";

use XML::Simple qw(:strict);
use Log::Log4perl;

## fixes a nasty warning: Could not find ParseDetails.ini
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

my $logger = Log::Log4perl->get_logger();

sub new {
	my ($class, $filename) = @_;
	if($filename =~ /.+\.xml\z/) { ## ensure that XML is requested
		my $self = $class->SUPER::new($filename); ## calling the super constructor
		$self->setXml(XML::Simple->new()); ## creating new object for the parsing
		$logger->debug("XML file object was created.\n");
		return $self;
	} else {
		$logger->fatal("Non-XML file format was detected in XMLFile constructor.\n");
		die "Invalid file format! XML required!";
	}
}

#getter
sub getXml {
	my $self = shift;
	return $self->{xml};
}

#setter
sub setXml {
	my ($self, $xml) = @_;
	$self->{xml} = $xml;
}

sub parse { ## converts XML content to Task object
	my ($self, $content) = @_;
	## parsing
	my $hashRef = $self->getXml()->XMLin($content, ForceArray => ["parameters", "environmentVariables"], KeyAttr => 0);
	$logger->debug("XML file content was parsed to a hash.\n");
	return $hashRef;
}

sub unparse {
	my ($self, $hashRef) = @_;
	#unparsing
	$logger->info("A hash was unparsed to XML content.\n");
	return $self->getXml()->XMLout($hashRef, NoAttr => 1, keyAttr => 0, RootName => "task"); ## returns the XML content to write in the file
}

1;