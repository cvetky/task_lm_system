package Configurator;

use strict;
use warnings;

use File;
use File::JSONFile;
use File::Spec;
use Log::Log4perl;

use constant CONFIG_PATH => File::Spec->catfile("config", "config.json");

my $logger = Log::Log4perl->get_logger();
my $taskFormat;
my $adlsServerUrl;

sub loadConfigData {
	my $configFile = File::JSONFile->new(CONFIG_PATH);
	my ($content, $stat) = $configFile->readContent();
	if(!$content) {
		$logger->fatal("Could not read configuration data from configuration file.\n");
		die "Cannot read configuration data from ".CONFIG_PATH;
	}
	my $hashRef = $configFile->parse($content);
	if(($hashRef->{format} eq "json") || ($hashRef->{format} eq "xml")) {
		$taskFormat = $hashRef->{format};
		$logger->info("Task format was read - ".$hashRef->{format}.".\n")
	} else {
		$logger->fatal("Non-supported file format was read from the configuration file.\n");
		die "Wrong file format in config file! Only JSON and XML are supported!";
	}

	$adlsServerUrl = $hashRef->{adls_server_url};
}

sub getTaskFormat {
	return $taskFormat;
}

sub getAdlsServerUrl {
	return $adlsServerUrl;
}

1;