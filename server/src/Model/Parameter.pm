package Model::Parameter;

use parent "Model";

use strict;
use warnings;

use Log::Log4perl;

use constant {
    ERR_PARAM_NAME_MISMATCH   => "Parameter names must match their corresponding names indise the command template placeholders!",
	ERR_PARAM_SPACES          => "Parameter names cannot contain spaces!",
	ERR_PARAM_TYPE            => "Parameter types can only be: s, i, r, b (case insensitive)!",
	ERR_PARAM_DESC            => "Parameter type descriptions can only be: string, integer, real, boolean (case insensitive)!",
	ERR_PARAM_TYPE_MATCH_DESC => "Parameter types must match their corresponding descriptions!",
	ERR_PARAM_HID             => "Parameters' \"hidden\" can only be: true, false (case insensitive)!",
	ERR_PARAM_UNDEF           => "Parameters' properties (name, type, typeDescription, hidden) must be defined and cannot be empty!",
};

my $logger = Log::Log4perl->get_logger();

sub toHash {
	my ($self) = @_;
	my $hashRef = {
        name            => $self->getName(),
        type            => $self->getType(),
        typeDescription => $self->getTypeDescription(),
        hidden          => $self->getHidden(),
    };
    return $hashRef;
}

sub validate {
	my ($self, $placeholder) = @_;
    $logger->info("Parameter validation was performed.\n");
	my $name = $self->getName();
	my $type = $self->getType();
	my $typeDescription = $self->getTypeDescription();
	my $hidden = $self->getHidden();
	
	if($name && $type && $typeDescription && $hidden) {
        $placeholder =~ s/{//;
        $placeholder =~ s/}//;
        if($placeholder ne $name) {
            $logger->warn("Mismatch between parameter names (in command template and name property) was detected.\n");
            return ERR_PARAM_NAME_MISMATCH;
        }

        if($name =~ /\s/) { ## param name can't contain spaces
            $logger->warn("Parameter name containing spaces was detected.\n");
            return ERR_PARAM_SPACES;
        }
        if(!($type =~ /\A(s|i|r|b)\z/i)) { ## param type must be s, i, r or b
            $logger->warn("Invalid parameter type was detected.\n");
            return ERR_PARAM_TYPE;
        }
        if(!($typeDescription =~ /\A(string|integer|real|boolean)\z/i)) { ## similar for type description
            $logger->warn("Invalid type description of parameter was detected.\n");
            return ERR_PARAM_DESC;
        }
        ## type must match type description:
        if(($type eq "s") && !($typeDescription =~ /string/i)) {
            $logger->warn("Parameter type not matching its description.\n");
            return ERR_PARAM_TYPE_MATCH_DESC;
        }
        if(($type eq "i") && !($typeDescription =~ /integer/i)) {
            $logger->warn("Parameter type not matching its description.\n");
            return ERR_PARAM_TYPE_MATCH_DESC;
        }
        if(($type eq "r") && !($typeDescription =~ /real/i)) {
            $logger->warn("Parameter type not matching its description.\n");
            return ERR_PARAM_TYPE_MATCH_DESC;
        }
        if(($type eq "b") && !($typeDescription =~ /boolean/i)) {
            $logger->warn("Parameter type not matching its description.\n");
            return ERR_PARAM_TYPE_MATCH_DESC;
        }
        if(!($hidden =~ /\A(true|false)\z/i)) { # 2 possible values for hidden
            $logger->warn("Different value from 'true' and 'false' for 'hidden' property of parameter was detected.\n");
            return ERR_PARAM_HID;
        }
    } else {
        $logger->warn("Undefined parameter property(or properties) was detected.\n");
        return ERR_PARAM_UNDEF; ## everything for a parameter must be defined
    }
    $logger->info("Parameter object passed the validation test.\n");
    return undef; ## everything is fine!
}

sub updateParamFeatures {
    my ($self, $oldParamHash) = @_;
    $logger->info("Parameter features update was performed.\n");
    if($oldParamHash->{name}) { ## if there is old info
        if($self->getName() && $self->getName() eq "-") {
            $logger->debug("Parameter name was not updated.\n");
            $self->setName($oldParamHash->{name});
        }
        if($self->getType() && $self->getType() eq "-") {
            $logger->debug("Parameter type was not updated.\n");
            $self->setType($oldParamHash->{type});
        }
        if($self->getTypeDescription() && $self->getTypeDescription() eq "-") {
            $logger->debug("Type description of parameter was not updated.\n");
            $self->setTypeDescription($oldParamHash->{typeDescription});
        }
        if($self->getHidden() && $self->getHidden() eq "-") {
            $logger->debug("'Hidden' property of parameter was not updated.\n");
            $self->setHidden($oldParamHash->{hidden});
        }
    }
}

#getters and setters
sub getName {
	my ($self) = @_;
	return $self->{name};
}

sub getType {
	my ($self) = @_;
	return $self->{type};
}

sub getTypeDescription {
	my ($self) = @_;
	return $self->{typeDescription};
}

sub getHidden {
	my ($self) = @_;
	return $self->{hidden};
}

sub setName {
	my ($self, $name) = @_;
	$self->{name} = $name;
}

sub setType {
	my ($self, $type) = @_;
	$self->{type} = $type;
}

sub setTypeDescription {
	my ($self, $typeDescription) = @_;
	$self->{typeDescription} = $typeDescription;
}

sub setHidden {
	my ($self, $hidden) = @_;
	$self->{hidden} = $hidden;
}

1;