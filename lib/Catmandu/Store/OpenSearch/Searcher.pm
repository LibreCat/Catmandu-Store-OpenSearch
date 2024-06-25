package Catmandu::Store::OpenSearch::Searcher;

our $VERSION = '0.01';

use Catmandu::Sane;
use Moo;
use Cpanel::JSON::XS qw(encode_json);
use namespace::clean;
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has total => (is => 'ro');
has sort  => (is => 'lazy');

sub _build_sort {
    [{_id => {order => 'asc'}}];
}

sub generator ($self) {
    my $bag    = $self->bag;
    my $os     = $bag->store->os;
    my $id_key = $bag->id_key;

    sub {
        state $max = $self->total;
        state $search_after;
        state $docs = [];

        if (defined $max) {
            return if $max <= 0;
        }

        unless (scalar(@$docs)) {
            my %args = (
                index => $bag->index,
                query => $self->query,
                size  => $self->limit,
                sort  => $self->sort,
                track_total_hits => "true",
            );
            if ($search_after) {
                $args{search_after} = $search_after;
            } else {
                $args{from} = $self->start;
            }
            my $res = $os->search->search(%args);
            if ($res->code ne "200") {
                Catmandu::Error->throw(encode_json($res->error));
            }
            return unless $res->data->{hits}{total}{value};

            $docs     = $res->data->{hits}{hits};
            return unless scalar(@$docs);

            $search_after = $docs->[-1]->{sort};
        }

        if ($max) {
            $max--;
        }

        my $doc = shift(@$docs);
        my $data = $doc->{_source};
        $data->{$id_key} = $doc->{_id};
        $data;
    };
}

sub slice ($self, $start, $total) {
    $start //= 0;
    $self->new(
        bag   => $self->bag,
        query => $self->query,
        start => $self->start + $start,
        limit => $self->limit,
        total => $total,
        sort  => $self->sort,
    );
}

sub count ($self) {
    my $bag    = $self->bag;
    my $store  = $bag->store;
    my $res    = $store->os->count(index => $bag->index, query => $self->query);
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
    $res->data->{count};
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::OpenSearch::Bag - Searcher implementation for Opensearch

=head1 DESCRIPTION

This class isn't normally used directly. Instances are constructed using the store's C<searcher> method.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut
