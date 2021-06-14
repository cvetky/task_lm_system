package Configurator;

use strict;
use warnings;

use JSON;
use File::Spec;
use IO::File;

use constant CONFIG_PATH => File::Spec->catfile("config", "config.json");

my $url;

sub loadConfigData {
	my $fileHandle = IO::File->new(CONFIG_PATH, "r");
	if(!defined($fileHandle)) {
		die "Cannot Cannot read configuration data from ".CONFIG_PATH;
	}
	my $content = join("", <$fileHandle>);
	if(!$content) {
		die "Cannot read configuration data from ".CONFIG_PATH;
	}
	my $hashRef = from_json($content);
	$url = $hashRef->{url};

}

sub getURL {
	return $url;
}

1;