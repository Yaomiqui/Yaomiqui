package Crypt::Babel;
$VERSION = 1.11;
$MODULENAME = "Crypt::Babel";
$LASTEDIT = "04/08/05";

### USAGE
###________________________________________________________________________________
###
###	use Babel;
### 
###	$y =  new Babel;
###
###	$s = "Encrypt this!!";
###	$t = $y->encode($s,"A key");
###	$u = $y->decode($t,"A key");
###
###	print "The source string is  $s\n";
###	print "The encrypted string  $t\n";
###	print "The original string   $u\n";
###________________________________________________________________________________
###

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(encode new version modulename lastedit);
@EXPORT_OK = qw(encode new version modulename lastedit);

sub new {
    my    $object = {};
    bless $object;
    return $object;
}

sub version {
    return($VERSION);
}

sub modulename {
    return($MODULENAME);
}

sub edited {
    return($LASTEDIT);
}

sub encode {
    shift;
    local ($_P1)= @_;
    shift;
    local ($_K1)= @_;

    my @_p = ();
    my @_k = ();
    my @_e = ();
    my $_l = "";
    my $_i = 0;
    my $_j = 0;
    my $_r = "";
    my $_t = 0;
    my $_h = 0;
    my $_o = 0;
    my $_d =0;
    my @_t =();
    my $_w ="";
        

    while ( length($_K1) < length($_P1) ) { $_K1=$_K1.$_K1;}

    $_K1=substr($_K1,0,length($_P1));

    @_p=split(//,$_P1);
    @_k=split(//,$_K1);

    foreach $_l (@_p) {
       $_t = ord($_l) * ord($_k[$_i]);
       $_o = $_t % 256;
       $_h = int $_t / 256; 
       $_o = $_o ^ ord($_k[$_i]);
       $_h = $_h ^ ord($_k[$_i]);
       $_i++;
       $_j=$_j+2;

       $_e[$_j]   = chr ($_o);
       $_e[$_j+1] = chr ($_h);
                      }
       @_e = grep defined $_, @_e; # fixes uninitialized warning for missing array elements[] joined by nothing
       $_r = join '',@_e;

       for($_d=0;$_d < length($_r);$_d++) {
        $_t[$_d]=sprintf("%02x",ord(substr($_r,$_d,1)));
                                        }

       $_w = join '',@_t;

       $_w =~ s/a/\./g;
       $_w =~ s/b/-/g;
       $_w =~ s/c/\+/g;
       $_w =~ s/d/\!/g;
       $_w =~ s/e/\*/g;
       $_w =~ s/f/\^/g;

       return reverse($_w);    
}

1;

