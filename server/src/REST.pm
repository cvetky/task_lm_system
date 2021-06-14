package REST;

use strict;
use warnings;

use Dancer2;
use Log::Log4perl;

use Model::Task;
use Adapter;

use Data::Dumper;

my $logger = Log::Log4perl->get_logger();
my $adapter = Adapter->getInstance();

## CRUD:
get '/tasks' => sub {
	$logger->info("GET request for all tasks was received.\n");
	content_type('application/json');
	my ($stat, $ref) = $adapter->getAllTasks();
	if(!$stat) {
		$logger->info("Status 400 after GET request for all tasks.\n");
		status(400);
	} else {
		$logger->info("Status 200 after GET request for all tasks.\n");
		status(200);
	}
	return to_json($ref); ## if stat is 0 error hash is returned
};

get '/tasks/:name' => sub {
	$logger->info("GET request for single task was received.\n");
	content_type('application/json');
	my $name = route_parameters->get("name");
	my ($stat, $hashRef) = $adapter->getRequestedTask($name);
	if(!$stat) {
		$logger->info("Status 400 after GET request for single task.\n");
		status(400);
	} else {
		$logger->info("Status 200 after GET request for single task.\n");
		status(200);
	}
	return to_json($hashRef); ## if stat is 0 -> error hash is returned
};

post '/tasks' => sub {
	$logger->info("POST request for creating new task was received.\n");
	content_type('application/json');
	my $body = request->body()."\n";
	my ($stat, $message) = $adapter->addNewTask($body);
	if (!$stat) {
		$logger->info("Status 400 after POST request for creating new task.\n");
		status(400);
		return to_json({ error => $message });
	}
	$logger->info("Status 201 after POST request for creating new task.\n");
	status(201);
	return to_json({ success => "Task added successfully!" });
};


put '/tasks/:name' => sub {
	$logger->info("PUT request for updating task was received.\n");
	content_type('application/json');
	my $name = route_parameters->get("name");
	my $body = request->body()."\n";
	my ($stat, $message) = $adapter->updateTask($name, $body);
	if (!$stat) {
		$logger->info("Status 400 after PUT request for updating task.\n");
		status(400);
		return to_json({ error => $message });
	}
	$logger->info("Status 200 after PUT request for updating task.\n");
	status(200);
	return to_json({ success => "Task updated successfully!" });
};

del '/tasks/:name' => sub {
	$logger->info("DELETE request for deleting task was received.\n");
	content_type('application/json');
	my $name = route_parameters->get("name");
	my ($status, $message) = $adapter->deleteRequestedTask($name);
	if(!$status) {
		$logger->info("Status 400 after DELETE request for deleting task.\n");
		status(400);
		return to_json( {error => $message} );
	}
	$logger->info("Status 200 after DELETE request for deleting task.\n");
	status(200);
	return to_json({ success => "Task deleted successfully!" });
};

del '/tasks' => sub {
	$logger->info("DELETE request for deleting all tasks was received.\n");
	content_type('application/json');
	my ($status, $message) = $adapter->deleteAllTasks();
	if(!$status) {
		$logger->info("Status 400 after DELETE request for deleting all tasks.\n");
		status(400);
		return to_json({ error => $message });
	}
	$logger->info("Status 200 after DELETE request for deleting all tasks.\n");
	status(200);
	return to_json({ success => "All tasks deleted successfully!" });
};

## handlers needed for execution:
post '/param' => sub {
	$logger->info("POST request for validating parameter was received.\n");
	content_type('application/json');
	my $body = request->body()."\n";
	my $stat = $adapter->isParamValueValid($body);
	if (!$stat) {
		$logger->info("Status 400 after POST request for validating parameter.\n");
		status(400);
		return "{}";
	}
	$logger->info("Status 200 after POST request for validating parameter.\n");
	status(200);
	return "{}";
};

post '/params' => sub {
	$logger->info("POST request for validating parameters was received.\n");
	content_type('application/json');
	my $body = request->body()."\n";
	my $stat = $adapter->isParamValuesArrayValid($body);
	if (!$stat) {
		$logger->info("Status 400 after POST request for validating parameters.\n");
		status(400);
		return "{}";
	}
	$logger->info("Status 200 after POST request for validating parameters.\n");
	status(200);
	return "{}";
};

post '/exec/:name' => sub {
	$logger->info("POST request for executing task was received.\n");
	content_type('application/json');
	my $name = route_parameters->get("name");
	my $body = request->body()."\n";
	my $pid = $adapter->executeTask($name, $body);
	if(!defined($pid)) {
		$logger->info("Status 400 after POST request for executing task.\n");
		status(400); ## process not created -> execution error
	} else {
		$logger->info("Status 200 after POST request for executing task.\n");
		status(200);
	}
	return "{}";
};

get '/outputLines/:startLine' => sub {
	$logger->info("GET request for reading output lines was received.\n");
	content_type('application/json');
	my $startLine = route_parameters->get("startLine");
	my ($lines, $finished) = $adapter->getOutputLines($startLine);
	if($finished) {
		$logger->info("Status 400 after GET request for reading output lines.\n");
		status(400);
	} else {
		$logger->info("Status 200 after GET request for reading output lines.\n");
		status(200);
	}
	return to_json( { lines => $lines, finished => $finished } );
};

get '/isTaskRunning' => sub {
	$logger->info("GET request for checking if there is a running task was received.\n");
	content_type('application/json');
	my $isRunning = $adapter->isProcessRunning();
	my $taskName = $adapter->getTaskName();
	if($isRunning) {
		$logger->info("Status 200 after GET request for checking if there is a running task.\n");
		status(200);
	} else {
		$logger->info("Status 400 after GET request for checking if there is a running task.\n");
		status(400);
	}
	return to_json( { isRunning => $isRunning, taskName => $taskName } );
};

post '/pause' => sub {
	$logger->info("POST request for pausing the running task was received.\n");
	content_type('application/json');
	my $stat = $adapter->pauseProcess();
	if($stat) {
		$logger->info("Status 200 after POST request for pausing the running task was received.\n");
		status(200);
		return to_json({ status => "paused" });
	} else {
		$logger->info("Status 400 after POST request for pausing the running task was received.\n");
		status(400);
		return to_json({ status => "unknown" });
	}
};

post '/resume' => sub {
	$logger->info("POST request for resuming paused task was received.\n");
	content_type('application/json');
	my $stat = $adapter->resumeProcess();
	if($stat) {
		$logger->info("Status 200 after POST request for resuming paused task was received.\n");
		status(200);
		return to_json({ status => "running" });
	} else {
		$logger->info("Status 400 after POST request for resuming paused task was received.\n");
		status(400);
		return to_json({ status => "unknown" });
	}
};

post '/kill' => sub {
	$logger->info("POST request for killing the running task was received.\n");
	content_type('application/json');
	my $stat = $adapter->killProcess();
	if($stat) {
		$logger->info("Status 200 after POST request for killing the running task was received.\n");
		status(200);
		return to_json({ status => "killed" });
	} else {
		$logger->info("Status 400 after POST request for killing the running task was received.\n");
		status(400);
		return to_json({ status => "unknown" });
	}
	return "{}";
};

1;