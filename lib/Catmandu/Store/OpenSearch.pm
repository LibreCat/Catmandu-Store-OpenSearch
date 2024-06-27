package Catmandu::Store::OpenSearch;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Store::OpenSearch::Bag;
use Types::Standard qw(ArrayRef Str);
use Types::Common::String qw(NonEmptyStr);
use Moo;
use OpenSearch;
use namespace::clean;

with 'Catmandu::Store';

has hosts => (
    is => 'lazy',
    isa => ArrayRef[NonEmptyStr],
    default => sub {["localhost:9200"]}
);

has user => (
    is => 'ro',
    isa => Str,
);

has pass => (
    is => 'ro',
    isa => Str,
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
