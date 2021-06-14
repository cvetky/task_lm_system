#!/usr/bin/perl

use strict;
use warnings;

use Views::Loader;
use Configurator;

Configurator->loadConfigData();

my $beginView = Views::Loader->new();
$beginView->startApp();