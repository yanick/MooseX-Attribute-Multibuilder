package MooseX::Attribute::Multibuilder;
# ABSTRACT: Have several attributes share the same builder

=head1 SYNOPSIS

    package Foo;
    use Moose;
    use MooseX::Attribute::Multibuilder;

    has bar => (
        traits => [ 'Multibuilder' ],
        is => 'ro',
        multibuilder => '_build_them_all'
    );

    has baz => (
        traits => [ 'Multibuilder' ],
        is => 'ro',
        multibuilder => '_build_them_all'
    );

    sub _build_them_all {
        return {
            bar => 'BAR',
            baz => 'BAZ' 
        };
    }


    my $foo = Foo->new;

    print $foo->bar; # BAR
    print $foo->baz; # BAZ

=head1 DESCRIPTION

Adds a C<multibuilder> option, which is like Moose's C<builder>, but is
expected to return a hashref of attribute and their default values.

=cut

use strict;
use warnings;

use Moose::Role;

use List::Util 1.29 qw/ pairmap pairgrep /;

has multibuilder => (
    is       => 'ro',
    required => 1,
);

before _process_options => sub {
    my( $class, $name, $options ) = @_;

    my $builder = $options->{multibuilder} or return;

    $options->{default} = sub {
        my $self = shift;
        my %values = %{ $self->$builder };

        pairmap  { $a->set_value($self, $b ) }
        pairgrep { not $a->has_value($self) }
        pairmap  { $self->meta->get_attribute($a) => $b }
                 %values;

        return $values{$name};
    };
};

{
    package
        Moose::Meta::Attribute::Custom::Trait::Multibuilder;

    sub register_implementation { 'MooseX::Attribute::Multibuilder' }

}

1;


1;
