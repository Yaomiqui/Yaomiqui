my $vendor = "yaomiqui";

open(SESSION, "<$VAR{session_file}");
my @line = <SESSION>;
close SESSION;

my $log = new Log::Man($VAR{log_dir}, $VAR{log_file}, $username);
$log->Log("Logout From IP " . $ENV{REMOTE_ADDR});

open(SESSION, ">$VAR{session_file}");
	foreach ( @line ) {
		$_ =~ s/\n//g;
		unless ( $_ =~ /\|$username$/ ) {
			print SESSION "$_\n";
		}
	}
close SESSION;

print "Set-Cookie: $vendor= \n";

print "Location: index.cgi\n\n";

1;
