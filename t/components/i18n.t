use strict;
use warnings;
use utf8;

use lib 't/components';

use Test::More;
use Test::Requires;
use Test::Fatal;

use File::Basename ();

BEGIN { test_requires 'I18N::AcceptLanguage' };

use Turnaround::I18N;

use I18NTest::MyApp;

subtest 'detect_languages' => sub {
    my $i18n = _build_i18n();

    is_deeply([$i18n->languages], [qw/en ru/]);
};

subtest 'default_to_default_language_on_uknown_language' => sub {
    my $i18n = _build_i18n();

    is($i18n->handle('de')->maketext('Hello'), 'Hello');
};

subtest 'default_to_default_language_on_uknown_translation' => sub {
    my $i18n = _build_i18n();

    is($i18n->handle('ru')->maketext('Hi'), 'Hi');
};

subtest 'return_handle' => sub {
    my $i18n = _build_i18n();

    my $handle = $i18n->handle('ru');

    is($handle->maketext('Hello'), 'Привет');
};

sub _build_i18n {
    return Turnaround::I18N->new(
        app_class  => 'I18NTest::MyApp',
        locale_dir => File::Basename::dirname(__FILE__)
          . '/I18NTest/MyApp/I18N/',
        @_
    );
}

done_testing;
