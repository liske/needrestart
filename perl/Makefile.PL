use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'		=> 'Thomas Liske <thomas@fiasko-nw.net>',
    'LICENSE'		=> 'gpl',
    'NAME'		=> 'NeedRestart',
    'PREREQ_PM'		=> {
	Module::Find => 0,
	Module::ScanDeps => 0,
	Proc::ProcessTable => 0,
	Sort::Naturally => 0,
	Term::ReadKey => 0.
    },
);
