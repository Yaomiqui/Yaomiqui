package Log::Man;

our $VERSION = '0.1';
use strict;
use Tie::File;

sub new {
	my $class = shift;
	my ($logDir, $logFile, $user) = @_;
	
	my $self = {
		dir		=> $logDir,
		file	=> $logFile,
		user	=> $user
	};
	bless( $self, $class );
	
	return $self;
}

sub Log {
	my $self = shift;
	my $msg = shift;
	
	my $currentLogfile = $self->{dir}  . '/' . file_date() . '_' . $self->{file};
	$msg = formatted_datetime() . ' : ' . $self->{user} . ' :' . $msg;
	
	my $o = tie my @array, 'Tie::File', $currentLogfile, or die "I can't open $currentLogfile";
	push @array, $msg;
	untie @array;
	
	return $msg;
}

sub formatted_datetime {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	
	return "$year-$mon-$mday $hour:$min:$sec";
}

sub file_date {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	$mon = "0$mon" if $mon < 10;
	$mday = "0$mday" if $mday < 10;
	$hour = "0$hour" if $hour < 10;
	$min = "0$min" if $min < 10;
	$sec = "0$sec" if $sec < 10;
	
	return "$year$mon$mday";
}


1;
