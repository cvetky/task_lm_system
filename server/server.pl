#!/usr/bin/perl

use strict;
use warnings;

use REST;
use Configurator;
use File::Spec;
use Dancer2;
use Log::Log4perl;

my $logConfig = File::Spec->catfile("config", "configLog.ini");

Log::Log4perl->init($logConfig);

my $logger = Log::Log4perl->get_logger();
$logger->info("Server script launched.\n");

Configurator->loadConfigData();

dance();