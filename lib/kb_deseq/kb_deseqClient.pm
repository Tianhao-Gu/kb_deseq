package kb_deseq::kb_deseqClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

kb_deseq::kb_deseqClient

=head1 DESCRIPTION


A KBase module: kb_deseq


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => kb_deseq::kb_deseqClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 run_deseq2_app

  $returnVal = $obj->run_deseq2_app($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_deseq.DESeqInput
$returnVal is a kb_deseq.DESeqResult
DESeqInput is a reference to a hash where the following keys are defined:
	expressionset_ref has a value which is a kb_deseq.obj_ref
	diff_expression_obj_name has a value which is a string
	workspace_name has a value which is a string
	run_all_combinations has a value which is a kb_deseq.boolean
	condition_labels has a value which is a reference to a list where each element is a string
	alpha_cutoff has a value which is a float
	fold_change_cutoff has a value which is a float
	input_type has a value which is a string
	num_threads has a value which is an int
	fold_scale_type has a value which is a string
obj_ref is a string
boolean is an int
DESeqResult is a reference to a hash where the following keys are defined:
	result_directory has a value which is a string
	diff_expression_obj_ref has a value which is a kb_deseq.obj_ref
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_deseq.DESeqInput
$returnVal is a kb_deseq.DESeqResult
DESeqInput is a reference to a hash where the following keys are defined:
	expressionset_ref has a value which is a kb_deseq.obj_ref
	diff_expression_obj_name has a value which is a string
	workspace_name has a value which is a string
	run_all_combinations has a value which is a kb_deseq.boolean
	condition_labels has a value which is a reference to a list where each element is a string
	alpha_cutoff has a value which is a float
	fold_change_cutoff has a value which is a float
	input_type has a value which is a string
	num_threads has a value which is an int
	fold_scale_type has a value which is a string
obj_ref is a string
boolean is an int
DESeqResult is a reference to a hash where the following keys are defined:
	result_directory has a value which is a string
	diff_expression_obj_ref has a value which is a kb_deseq.obj_ref
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description

run_deseq2_app: run DESeq2 app

ref: https://www.bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html

=back

=cut

 sub run_deseq2_app
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_deseq2_app (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_deseq2_app:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_deseq2_app');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_deseq.run_deseq2_app",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_deseq2_app',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_deseq2_app",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_deseq2_app',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "kb_deseq.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "kb_deseq.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'run_deseq2_app',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method run_deseq2_app",
            status_line => $self->{client}->status_line,
            method_name => 'run_deseq2_app',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for kb_deseq::kb_deseqClient\n";
    }
    if ($sMajor == 0) {
        warn "kb_deseq::kb_deseqClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 boolean

=over 4



=item Description

A boolean - 0 for false, 1 for true.
@range (0, 1)


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 obj_ref

=over 4



=item Description

An X/Y/Z style reference


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 DESeqInput

=over 4



=item Description

required params:
expressionset_ref: ExpressionSet object reference
diff_expression_obj_name: DifferentialExpressoinMatrixSet object name
workspace_name: the name of the workspace it gets saved to

optional params:
run_all_combinations: run all paired condition combinations
condition_labels: conditions for expression set object
alpha_cutoff: q value cutoff
fold_change_cutoff: fold change cutoff
input_type: one of ["genes", "transcripts"]
num_threads: number of threads
fold_scale_type: one of ["linear", "log2+1", "log10+1"]


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
expressionset_ref has a value which is a kb_deseq.obj_ref
diff_expression_obj_name has a value which is a string
workspace_name has a value which is a string
run_all_combinations has a value which is a kb_deseq.boolean
condition_labels has a value which is a reference to a list where each element is a string
alpha_cutoff has a value which is a float
fold_change_cutoff has a value which is a float
input_type has a value which is a string
num_threads has a value which is an int
fold_scale_type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
expressionset_ref has a value which is a kb_deseq.obj_ref
diff_expression_obj_name has a value which is a string
workspace_name has a value which is a string
run_all_combinations has a value which is a kb_deseq.boolean
condition_labels has a value which is a reference to a list where each element is a string
alpha_cutoff has a value which is a float
fold_change_cutoff has a value which is a float
input_type has a value which is a string
num_threads has a value which is an int
fold_scale_type has a value which is a string


=end text

=back



=head2 DESeqResult

=over 4



=item Description

result_directory: folder path that holds all files generated by run_deseq2_app
diff_expression_obj_ref: generated RNASeqDifferetialExpression object reference
report_name: report name generated by KBaseReport
report_ref: report reference generated by KBaseReport


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
result_directory has a value which is a string
diff_expression_obj_ref has a value which is a kb_deseq.obj_ref
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
result_directory has a value which is a string
diff_expression_obj_ref has a value which is a kb_deseq.obj_ref
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=cut

package kb_deseq::kb_deseqClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
