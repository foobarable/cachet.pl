package Cachet;
use Exporter 'import';
use strict;
use warnings;
use WWW::Curl::Easy;
use JSON;
use MIME::Base64;

my @ISA = qw(Exporter);
my @EXPORT = ();
#my @EXPORT_OK = (&setComponentStatusById &isWorking &getComponents &getComponentById &getMetricById &getIncidents &getIncidentById  &getMetrics);
my @EXPORT_OK = ();


sub new {
	my $pkg = shift;
	my $self = {};
	
	$self->{'baseUrl'} = '';	
	$self->{'email'} = '';
	$self->{'password'} = '';
	$self->{'apiToken'} = '';
	bless($self,$pkg);
	return $self;
}
sub getBaseUrl {
	my $self = shift;
	return $self->{'baseUrl'};
}

sub getEmail {
	my $self = shift;
	return $self->{'email'};
}

sub getPassword {
	my $self = shift;
	return $self->{'password'};
}

sub getApiToken {
	my $self = shift;
	return $self->{'apiToken'};
}


sub setBaseUrl {
	my $self = shift;
	my $url = shift;
	$self->{'baseUrl'} = $url;
}

sub setEmail {
	my $self = shift;
	my $mail = shift;
	$self->{'email'} = $mail;
}

sub setPassword {
	my $self = shift;
	my $pw = shift;
	$self->{'password'} = $pw;
}
sub setApiToken {
	my $self = shift;
	my $token = shift;
	$self->{'apiToken'} = $token;
}

sub sanityCheck {
	my $self = shift;
	my $authorisationRequired = shift;
	if(!$self->{'baseUrl'}) {
		die ('cachet.pm: The base URL is not set for your cachet instance. Set one with the setBaseURL method.');
	}
	#TODO:  base url regex check

	if($authorisationRequired && (!$self->{'apiToken'} && (!$self->{'email'} || !$self->{'password'}))) {
		#TODO:  email regex check
		die ('cachet.pm: The apiToken is not set for your cachet instance. Set one with the setApiToken method. Alternatively, set your email and password with the setEmail and setPassword methods respectively');
	}
}



sub curlGet {
	my $self = shift;
	my $url = shift;
	my $responseBody; 
	my $curl = WWW::Curl::Easy->new;
	
	$curl->setopt(CURLOPT_HEADER,0);
	$curl->setopt(CURLOPT_URL,$url);
	$curl->setopt(CURLOPT_WRITEDATA,\$responseBody);

	my $retcode = $curl->perform;	
	if($retcode == 0) {
		my $decoded = decode_json($responseBody);
		#TODO: Error handling for decode_json
		return $decoded->{'data'};
	} else {
		return $retcode;
	}

}

sub curlPut {
	my $self =shift;
	my $url = shift;
	my $data = shift;
	my $curl = WWW::Curl::Easy->new;
	my $responseBody; 

	$curl->setopt(CURLOPT_HEADER,0);
	$curl->setopt(CURLOPT_URL,$url);
	$curl->setopt(CURLOPT_CUSTOMREQUEST,'PUT');
	$curl->setopt(CURLOPT_POSTFIELDS,$data);
	
	my @HTTPHeader = (); 
	my $authorisationHeader = 'Authorization: Basic ' . encode_base64($self->{'email'} . ':' . $self->{'password'});

	if($self->{'apiToken'}) {
		$authorisationHeader = 'X-Cachet-Token: ' . $self->{'apiToken'};
	}
		
	push(@HTTPHeader,$authorisationHeader);
	$curl->setopt(CURLOPT_WRITEDATA,\$responseBody);
	$curl->setopt(CURLOPT_HTTPHEADER,\@HTTPHeader);
	my $retcode = $curl->perform;
	if($retcode == 0) {
		my $decoded = decode_json($responseBody);
		#TODO: Error handling for decode_json
		return $decoded->{'data'};
	} else {
		return $retcode;
	}
}


sub curlPost {
	my $self =shift;
	my $url = shift;
	my $data = shift;
	my $curl = WWW::Curl::Easy->new;
	my $responseBody; 

	$curl->setopt(CURLOPT_HEADER,0);
	$curl->setopt(CURLOPT_URL,$url);
	$curl->setopt(CURLOPT_POST,1);
	$curl->setopt(CURLOPT_POSTFIELDS,$data);
	
	my @HTTPHeader = (); 
	my $authorisationHeader = 'Authorization: Basic ' . encode_base64($self->{'email'} . ':' . $self->{'password'});

	if($self->{'apiToken'}) {
		$authorisationHeader = 'X-Cachet-Token: ' . $self->{'apiToken'};
	}
		
	push(@HTTPHeader,$authorisationHeader);
	$curl->setopt(CURLOPT_WRITEDATA,\$responseBody);
	$curl->setopt(CURLOPT_HTTPHEADER,\@HTTPHeader);
	my $retcode = $curl->perform;
	if($retcode == 0) {
		my $decoded = decode_json($responseBody);
		#TODO: Error handling for decode_json
		return $decoded->{'data'};
	} else {
		return $retcode;
	}

}

sub curlDelete {
	die("Not implemented");
}

sub ping {
	my $self = shift;
	$self->sanityCheck(0);
	
	my $url = $self->{'baseUrl'} . 'ping';
	return $self->curlGet($url);
}

sub get {
	my $self = shift;
	my $type = shift;
	if($type ne 'components' && $type ne 'incidents' && $type ne 'metrics') {
		die('cachet.php: Invalid type specfied. Must be \'components\', \'incidents\' or \'metrics\'');
	}
	$self->sanityCheck(0);
	
	my $url = $self->{'baseUrl'} . $type;
	return $self->curlGet($url);
}


sub getById {
	my $self = shift;
	my $type = shift;
	my $id = shift;
	if($type ne 'components' && $type ne 'incidents' && $type ne 'metrics') {
		die('cachet.pm: Invalid type specfied. Must be \'components\', \'incidents\' or \'metrics\'');
	}
	if(!$id) {
		die('cachet.pm: No id supplied');
	}
	$self->sanityCheck(0);

	my $url = $self->{'baseUrl'} . $type . '/' . $id;
	return $self->curlGet($url);
}


# Exported Functions

sub isWorking() {
	my $self =shift;
	return($self->ping() eq 'Pong!');
}


sub setComponentStatusById {
	my $self =shift;
	my $id = shift;
	my $status = shift;
	$self->sanityCheck(1);
	if (!$id) {
		die('cachet.pm: You attempted to set a component status by ID without specifying an ID.');
	}
	my $url = $self->{'baseUrl'} . 'components/' . $id;
	my $requestData = 'status='.$status;	
	return $self->curlPut($url,$requestData);
}

sub getComponents {
	my $self =shift;
	return $self->get('components');

}

sub getComponentById {
	my $self = shift;
	my $id = shift;
	return $self->getById('components',$id);
}


sub createComponent {
	my ($self,$name,$description,$status,$link,$order,$groupID) = @_;
	if(!$name or !$status) {
		die('cachet.pm: Missing status and/or name while creating component');
	}
	my $url = $self->{'baseUrl'} . 'components';
	my $requestData = "";
	$requestData .= 'name='.$name . '&';
	$requestData .= 'status='.$status . '&';
	
	if($description) {
		$requestData .= 'message='.$description . '&';
	}
	if($link) {
		$requestData .= 'link='.$link . '&';
	}
	if($order) {
		$requestData .= 'order='.$order;
	}
	if($groupID) {
		$requestData .= 'group_id='.$groupID;
	}
	return $self->curlPost($url,$requestData);	

}

sub updateComponent {
	# Status IDs:
	# 1 - Operational
	# 2 - Performance Issues
	# 3 - Partial Outage
	# 4 - Major Outage

	my ($self,$id,$name,$status,$link,$order,$groupID) = @_;
	if(!$id) {
		die('cachet.pm: Missing id while updating component');
	}
	my $url = $self->{'baseUrl'} . 'components/' . $id;
	my $requestData = "";
	$requestData .= 'id='.$id. '&';
	
	if($name) {
		$requestData .= 'name='.$name. '&';
	}
	if($status) {
		$requestData .= 'status='.$status . '&';
	}
	if($link) {
		$requestData .= 'link='.$link . '&';
	}
	if($order) {
		$requestData .= 'order='.$order;
	}
	if($groupID) {
		$requestData .= 'group_id='.$groupID;
	}

	return $self->curlPut($url,$requestData);	
}

sub getIncidents {
	my $self =shift;
	return $self->get('incidents');
}

sub getIncidentById {
	my $self = shift;
	my $id = shift;
	return $self->getById('incidents',$id);
}

sub createIncident {
	my ($self,$name,$status,$message,$component_id,$notify) = @_;
	if(!defined($name) or !defined($status)) {
		die('cachet.pm: Missing status and/or name while creating incident');
	}
	my $url = $self->{'baseUrl'} . 'incidents';
	my $requestData = "";
	$requestData .= 'name='.$name . '&';
	$requestData .= 'status='.$status . '&';
	
	if($message) {
		$requestData .= 'message='.$message . '&';
	}
	if($component_id) {
		$requestData .= 'component_id='.$component_id . '&';
	}
	if($notify) {
		$requestData .= 'notify='.$notify;
	}
	return $self->curlPost($url,$requestData);	
}

sub updateIncident {
	my ($self,$id,$name,$status,$message,$component_id,$notify) = @_;
	if(!$id or !$name or !$status) {
		die('cachet.pm: Missing id, status and/or name while updating incident');
	}
	my $url = $self->{'baseUrl'} . 'incidents/' . $id ;
	my $requestData = "";
	$requestData .= 'name='.$name . '&';
	$requestData .= 'status='.$status . '&';
	
	if($message) {
		$requestData .= 'message='.$message . '&';
	}
	if($component_id) {
		$requestData .= 'component_id='.$component_id . '&';
	}
	if($notify) {
		$requestData .= 'notify='.$notify;
	}
	return $self->curlPut($url,$requestData);	
}

sub deleteIncident {
	die("Not implemented\n");
}





sub getMetrics {
	my $self =shift;
	return $self->get('metrics');
}

sub getMetricById {
	my $self = shift;
	my $id = shift;
	return $self->getById('metrics',$id);
}

sub createMetric {
	die("Not implemented\n");
}

sub updateMetric {
	die("Not implemented\n");
}

sub deleteMetric {
	die("Not implemented\n");
}

1;
