package FactoryTest;

use strict;
use warnings;

use base 'TestBase';

use lib 't/lib/FactoryTest';

use Test::More;
use Test::Fatal;

use Lamework::Factory;

sub build_an_object : Test {
    my $self = shift;

    my $factory = $self->_build_factory;

    my $foo = $factory->build('Foo');

    ok($foo);
}

sub build_an_object_with_default_args : Test {
    my $self = shift;

    my $factory = $self->_build_factory(default_args => {foo => 'bar'});

    my $foo = $factory->build('Foo');

    is($foo->{foo}, 'bar');
}

sub throw_on_syntax_errors : Test {
    my $self = shift;

    my $factory = $self->_build_factory;

    ok(exception { $factory->build('WithSyntaxErrors') });
}

sub throw_during_creation_errors : Test {
    my $self = shift;

    my $factory = $self->_build_factory;

    ok(exception { $factory->build('DieDuringCreation') });
}

sub _build_factory {
    my $self = shift;

    return Lamework::Factory->new(@_);
}

1;