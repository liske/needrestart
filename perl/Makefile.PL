use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'		=> 'Thomas Liske <thomas@fiasko-nw.net>',
    'LICENSE'		=> 'gpl',
    'NAME'		=> 'NeedRestart',
    'PREREQ_PM'		=> {
	Module::Find => 0,
    },
);
