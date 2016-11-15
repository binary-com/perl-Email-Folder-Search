requires 'Email::Folder';
requires 'Encode';
requires 'NEXT';
requires 'Scalar::Util';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.48';
};

on build => sub {
    requires 'perl', '5.010000';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Mail::Sender';
    requires 'Try::Tiny';
    requires 'FindBin';
    requires 'File::Copy';
};

