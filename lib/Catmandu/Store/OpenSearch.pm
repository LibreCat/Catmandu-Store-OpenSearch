package Catmandu::Store::OpenSearch;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Catmandu::Store::OpenSearch::Bag;
use Moo;
use OpenSearch;
use namespace::clean;

with 'Catmandu::Store';

has hosts => (
    is => 'lazy',
    isa => sub {
        my $v = $_[0];
        check_array_ref($v);
        check_string($_) for @$v;
    },
    default => sub {["localhost:9200"]}
);

has user => (
    is => 'ro',
    isa => sub { check_string($_[0]); },
);

has pass => (
    is => 'ro',
    isa => sub { check_string($_[0]); },
);


has os => (is => 'lazy', init_arg => undef);

sub _build_os {
    my $self = $_[0];
    OpenSearch->new(
        hosts => $self->hosts,
        user  => $self->user // "",
        pass  => $self->pass // "",
    );
}


1;
