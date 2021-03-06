package Turnaround::Action;

use strict;
use warnings;

use Turnaround::Exception::HTTP;
use Turnaround::Request;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{env} = $params{env};

    return $self;
}

sub service {
    my $self = shift;
    my ($name) = @_;

    return $self->{env}->{'turnaround.services'}->service($name);
}

sub env {
    my $self = shift;

    return $self->{env};
}

sub req {
    my $self = shift;

    $self->{req} ||= Turnaround::Request->new($self->env);

    return $self->{req};
}

sub new_response {
    my $self = shift;

    return $self->req->new_response(@_);
}

sub url_for {
    my $self = shift;

    my $url;

    if ($_[0] =~ m{^/}) {
        my $path = $_[0];
        $path =~ s{^/}{};

        $url = $self->req->base;
        $url->path($url->path . $path);
    }
    elsif ($_[0] =~ m{^https?://}) {
        $url = $_[0];
    }
    else {
        my $dispatched_request = $self->env->{'turnaround.dispatched_request'};

        my $path = $dispatched_request->build_path(@_);

        $path =~ s{^/}{};

        $url = $self->req->base;
        $url->path($url->path . $path);
    }

    return $url;
}

sub captures { $_[0]->env->{'turnaround.dispatched_request'}->captures }

sub set_var {
    my $self = shift;

    for (my $i = 0; $i < @_; $i += 2) {
        my $key   = $_[$i];
        my $value = $_[$i + 1];

        $self->env->{'turnaround.displayer.vars'}->{$key} = $value;
    }

    return $self;
}

sub throw_forbidden {
    my $self = shift;
    my ($message) = @_;

    $self->throw_error($message, 403);
}

sub throw_not_found {
    my $self = shift;
    my ($message) = @_;

    $self->throw_error($message, 404);
}

sub throw_error {
    my $self = shift;
    my ($message, $code) = @_;

    Turnaround::Exception::HTTP->throw($message, code => $code || 500);
}

sub redirect {
    my $self = shift;
    my ($path) = shift;

    my $status = 302;
    if (@_ % 2 != 0) {
        $status = pop @_;
    }

    my $url = $self->url_for($path, @_);

    my $res = $self->new_response($status);
    $res->header(Location => $url);

    return $res;
}

sub render {
    my $self = shift;
    my ($template, %args) = @_;

    for (qw/vars layout/) {
        next unless exists $self->{env}->{"turnaround.displayer.$_"};
        $args{$_} = {
            %{$self->{env}->{"turnaround.displayer.$_"} || {}},
            %{$args{$_} || {}}
        };
    }

    return $self->service('displayer')->render($template, %args);
}

1;
