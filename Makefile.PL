use inc::Module::Install;

name            'File-Helper';
all_from        'lib/File/Helper.pm';
license         'bsd';

requires        'File::Copy';

test_requires   'Test::More';

WriteAll;
