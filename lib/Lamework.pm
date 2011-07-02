package Lamework;

use strict;
use warnings;

use Plack::Builder;

use Cwd               ();
use File::Basename    ();
use File::Spec        ();
use String::CamelCase ();

use Lamework::Config;
use Lamework::Displayer;
use Lamework::Renderer::Caml;
use Lamework::Home;
use Lamework::Registry;
use Lamework::Routes;

use overload q(&{}) => sub { shift->psgi_app }, fallback => 1;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->init;

    $self->startup;

    return $self;
}

sub init {
    my $self = shift;

    Lamework::Registry->set(app => $self, weaken => 1);

    my $home = Lamework::Home->new($self->_detect_home);
    Lamework::Registry->set(home => $home);

    Lamework::Registry->set(routes    => $self->routes);
    Lamework::Registry->set(displayer => $self->displayer);

    my $app_name    = String::CamelCase::decamelize($self->namespace);
    my $config_file = $home->catfile("$app_name.ini");

    my $config = {};
    if (-f $config_file) {
        $config = Lamework::Config->new->load($config_file);
    }
    Lamework::Registry->set(config => $config);
}

sub startup { }

sub namespace {
    my $self = shift;

    return ref $self;
}

sub routes {
    my $self = shift;

    $self->{routes} ||= Lamework::Routes->new;

    return $self->{routes};
}

sub home {
    my $self = shift;

    return Lamework::Registry->get('home');
}

sub displayer {
    my $self = shift;

    $self->{displayer} ||= Lamework::Displayer->new(
        formats => {
            caml => Lamework::Renderer::Caml->new(
                templates_path => $self->home->catfile('templates')
            )
        }
    );

    return $self->{displayer};
}

sub psgi_app {
    my $self = shift;

    return $self->{psgi_app} ||= $self->compile_psgi_app;
}

sub app {
    my $self = shift;

    sub {
        my $env = shift;

        my $message = $self->displayer->render_file('not_found');
        Lamework::HTTPException->throw(404, message => $message);
      }
}

sub compile_psgi_app {
    my $self = shift;

    builder {
        enable 'Static' => path =>
          qr{\.(?:js|css|jpe?g|gif|ico|png|html?|swf|txt)$},
          root => $self->home->catfile('htdocs');

        enable 'HTTPExceptions';

        enable 'SimpleLogger', level => $ENV{PLACK_ENV}
          && $ENV{PLACK_ENV} eq 'development' ? 'debug' : 'error';

        enable '+Lamework::Middleware::RoutesDispatcher';

        enable '+Lamework::Middleware::ActionBuilder';

        enable '+Lamework::Middleware::ViewDisplayer';

        enable 'ContentLength';

        $self->app;
    };
}

sub _detect_home {
    my $self = shift;

    my $namespace = $self->namespace;
    $namespace =~ s{::}{/}g;

    my $home = $INC{$namespace . '.pm'};
    if (defined $home) {
        $home = Cwd::realpath(
            File::Spec->catfile(File::Basename::dirname($home), '..'));
    }

    return $home;
}

1;
