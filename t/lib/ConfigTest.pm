package ConfigTest;

use strict;
use warnings;

use base 'TestBase';

use utf8;

use Test::More;
use Test::Fatal;

use Lamework::Config;

sub load_config_base_on_extension : Test {
    my $self = shift;

    my $config = $self->_build_config;

    my $data = $config->load('t/config/config.ini');

    is_deeply($data, {main => {foo => 'bar', 'привет' => 'там'}});
}

sub return_config : Test {
    my $self = shift;

    my $config = $self->_build_config;

    $config->load('t/config/config.ini');

    is_deeply($config->config, {main => {foo => 'bar', 'привет' => 'там'}});
}

sub persistence : Test {
    my $self = shift;

    my $config = $self->_build_config;

    $config->load('t/config/config.ini');

    $config = $self->_build_config;

    is_deeply($config->config, {main => {foo => 'bar', 'привет' => 'там'}});
}

sub _build_config {
    my $self = shift;

    return Lamework::Config->new(@_);
}

1;
