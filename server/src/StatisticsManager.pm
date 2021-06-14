package StatisticsManager;

use strict;
use warnings;

use JSON;
use HTTP::Tiny;

my $logger = Log::Log4perl->get_logger();

sub new {
    my ($class, $executionData, $adlsServerUrl) = @_;
    my $self = bless({}, $class);

    $self->{executionData} = [$executionData];
    $self->{adlsServerUrl} = $adlsServerUrl;
    return $self;
}

sub saveStatisticsData {
    my ($self, $taskName) = @_;

    $logger->info("Uploading statistics for the execution of task '$taskName' to the data lake...\n");

    my $body = to_json($self->{executionData});
    my $url = $self->{adlsServerUrl};
    my $options = {
        content => $body,
        headers => {
            "content-type" => "application/json"
        }
    };

    my $restHandler = HTTP::Tiny->new();
    my $hashRef = $restHandler->request("POST", "$url/adls_upload", $options);
    my $responseStatus = $hashRef->{status};

    if($responseStatus == 201) {
        $logger->info(from_json($hashRef->{content})->{message}."\n");
    } elsif($responseStatus == 400) {
        $logger->warn(from_json($hashRef->{content})->{message}."\n");
    } else {
        $logger->warn("Unexpected status $responseStatus was received from the ADLS server. Please, check its output for more information!\n");
    }
}

1;