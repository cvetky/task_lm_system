package MenuOptions;

use strict;
use warnings;

use Views::MenuOption::AddTask;
use Views::MenuOption::UpdateTask;
use Views::MenuOption::DeleteTask;
use Views::MenuOption::DeleteAllTasks;
use Views::MenuOption::ViewTask;
use Views::MenuOption::ViewAllTasks;
use Views::MenuOption::ExecuteTask;
use Views::MenuOption::Exit;

our %options = (
	1  => Views::MenuOption::ExecuteTask->new(),
	2  => Views::MenuOption::AddTask->new(),
	3  => Views::MenuOption::UpdateTask->new(),
	4  => Views::MenuOption::DeleteTask->new(),
	5  => Views::MenuOption::DeleteAllTasks->new(),
	6  => Views::MenuOption::ViewTask->new(),
	7  => Views::MenuOption::ViewAllTasks->new(),
	8  => Views::MenuOption::Exit->new(),
);

sub getMenuOption {
	my ($class, $option) = @_;
	return $options{$option};
}

1;