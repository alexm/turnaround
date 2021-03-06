package Turnaround::ACL;

use strict;
use warnings;

use List::Util qw(first);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub add_role {
    my $self = shift;
    my ($role, @parents) = @_;

    $self->{roles}->{$role} = {allow => [], deny => []};

    foreach my $parent (@parents) {
        push @{$self->{roles}->{$role}->{deny}},
          @{$self->{roles}->{$parent}->{deny}};
        push @{$self->{roles}->{$role}->{allow}},
          @{$self->{roles}->{$parent}->{allow}};
    }

    return $self;
}

sub allow {
    my $self = shift;
    my ($role, $action) = @_;

    if ($role eq '*') {
        foreach my $role (keys %{$self->{roles}}) {
            $self->allow($role, $action);
        }
    }
    else {
        die 'Unknown role' unless exists $self->{roles}->{$role};

        push @{$self->{roles}->{$role}->{allow}}, $action;
    }

    return $self;
}

sub deny {
    my $self = shift;
    my ($role, $action) = @_;

    if ($role eq '*') {
        foreach my $role (keys %{$self->{roles}}) {
            $self->deny($role, $action);
        }
    }
    else {
        die 'Unknown role' unless exists $self->{roles}->{$role};

        push @{$self->{roles}->{$role}->{deny}}, $action;
    }

    return $self;
}

sub is_allowed {
    my $self = shift;
    my ($role, $action) = @_;

    return 0 unless exists $self->{roles}->{$role};

    return 0 if first { $_ eq $action } @{$self->{roles}->{$role}->{deny}};

    return 1
      if first { $_ eq $action || $_ eq '*' }
        @{$self->{roles}->{$role}->{allow}};

    return 0;
}

1;
