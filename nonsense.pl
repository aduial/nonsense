#!/usr/bin/perl -w
#
# Nonsense -- Generates random text from recursive datafiles.
# 
# See the README for full details.
#
# Author: James Baughn, nonsense@i-want-a-website.com
#    with CGI support contributed by Fred Hirsch, truehand@darkhart.com   
#    with small changes contributed by Peter Suschlik, peter@zilium.de
#
# Extended with weight factoring for both section variables and and literal items.
# Deprecated CGI.pm module replaced with URI and HTTP module funtions
# by Luthien Dulk, luthien@parendili.org
#
# Original Homepage: http://i-want-a-website.com/about-linux/downloads.shtml
# Current homepage (TBD)
# Version: 0.7 (September 11, 2020)
# License: GNU General Public License 2.0
#
# COMMAND LINE USAGE:
#    nonsense [ -f file.data ] [ -t file.template ]
#             [ -n number ] [ -p ] [ -b bullet string ] [ -e ]
#             [ -D | -d ] [ command string ]
#
#    -f   Specify a datafile to load in.  Use multiple -f parameters
#         to include additional files.  The default.data file is 
#         is always loaded.
#    -F   Load all data files (i.e. all files in the current directory
#         with a .data extension).
#
#    -t   Use a template
# 
#    -n   Repeat n times
#    -p   Separate each item with a blank line (i.e. paragraph break)
#    -b   Specify a "bullet" to go in front of each item.
#
#    -e   Disable direct eval()'s
#
#    -d   Debug mode (shows each substituation)
#    -D   Verbose debug mode (shows each substitution and the result)
#
######################################################################

use strict;
use POSIX qw( strftime );   # Just in case somebody needs the date
use URI;
use URI::QueryParam;
use HTTP::Headers;
use Data::Dumper;

my %pool;                   # Where the datafiles are slurped into
my %static;                 # Hash of persistent data (to maintain state)

my $ignoreparameters = 0;   # Set this to 1 if you want Nonsense to ignore
                            # command-line or CGI parameters (for security
                            # reasons).  The program will use the hard-coded
                            # defaults below.  See the README first!
my @datafiles = qw(default.data);
my $DEBUG = 0;
my $template = '{Default}'; 
my $template_meta = '';
my $cgi_mode = 0;
my $output_mode = 'text';
my $header = '';
my $footer = '';
my $spacer = "\n";
my $bullet = '';
my $iters = 1;
my $evalokay = 1;           # By default, allow direct eval
my $query;
my $requesturi = $ENV{'REQUEST_URI'};
my $res_header = HTTP::Headers->new;

if (@ARGV <= 0) {           # Is this in a CGI environment?
   $query = URI->new($requesturi);
   $output_mode = 'html'; $cgi_mode = 1;
   $spacer = "<BR>\n";
   $evalokay = 0;           # Just to be safe, disable this feature
                            # in CGI scripts
}

#binmode(STDOUT, ":utf8");

## Read CGI parameters
if (defined $query && $query->query_param && !$ignoreparameters) {
   my $cmd;
   if (defined $query->query_param('cmd') && $query->query_param('cmd') ne "") {
      $cmd = $query->query_param('cmd');
   } else {
      $cmd = 'Default';
   }
   if (defined $query->query_param('debug') && $query->query_param('debug') ne "") {
      $DEBUG = $query->query_param('debug');
   }
   if (defined $query->query_param('number') && $query->query_param('number') ne "") {
      $iters = $query->query_param('number');
   }
   if (defined $query->query_param('file') && $query->query_param('file') ne "") {
      push (@datafiles, $query->query_param('file')) ;
   }
   if (defined $query->query_param('allfiles') && $query->query_param('allfiles') ne "") {
      @datafiles = GlobCurrentDirectory();
   }
   
   if (defined $query->query_param('template') && $query->query_param('template') ne "") {
      my $file = $query->query_param('template');	
      ($template, $template_meta) = LoadTemplate( $file );
      if( $file !~ /\.html/ ) { $output_mode = 'verbatim'; }
   } else {
      $template = '{' . ucfirst( $cmd ) . '}';
      if (defined $query->query_param('standalone') && $query->query_param('standalone') ne "") {
         $header = "<HTML><HEAD><TITLE>Nonsense</TITLE></HEAD><BODY>\n";
         $footer = "</BODY></HTML>\n";
      }
   }
   if (defined $query->query_param('spacer') && $query->query_param('spacer') ne "") {
      $spacer = $query->query_param('spacer' );
      if( $spacer eq 'P' || $spacer eq 'p' ) {
         $spacer = "\n<P>\n";
      } elsif( $spacer =~ /^nl*$/i ) {
         $spacer = "\n";
      } elsif( $spacer =~ /^br*$/i ) { 
         $spacer = "<BR>\n";
      } else {  # Literal
         $spacer = s/\\n/\n/g;
      }
   }
   if (defined $query->query_param('bullet') && $query->query_param('bullet') ne "") {
      my $layout = $query->query_param('bullet' );
      if( $layout =~ /^o/i ) { 
         $header .= "<OL>\n"; $footer = "</OL>\n$footer"; $bullet = "<LI>";
      } elsif( $layout =~ /^[ul]/i ) { 
         $header .= "<UL>\n"; $footer = "</UL>\n$footer"; $bullet = "<LI>";
      }
   }
   
## Read command line parameters
} elsif(!$ignoreparameters) {
   while( my $cmd = shift @ARGV ) {
      if( $cmd =~ /^-(\w)/ ) { 
         my $switch = $1;
         if( $switch eq 'd' ) { 
            $DEBUG = 1;
         } elsif( $switch eq 'D' ) { 
            $DEBUG = 2;
         } elsif( $switch eq 'n' ) { 
            $iters = shift @ARGV;
         } elsif( $switch eq 'e' ) { 
            $evalokay = 0;
         } elsif( $switch eq 'p' ) { 
            $spacer = "\n\n";      
         } elsif( $switch eq 'b' ) { 
            $bullet = shift @ARGV;
         } elsif( $switch eq 't' ) { 
            my $file = shift @ARGV;
            ($template, $template_meta) = LoadTemplate( $file );
         } elsif( $switch eq 'f' ) { 
            push( @datafiles, shift @ARGV );
         } elsif( $switch eq 'F' ) { 
            @datafiles = GlobCurrentDirectory();
         }
      } else { 
         $template = '{' . ucfirst( $cmd ) . '}';
      }
   }
}

## Check if there was any meta-data specified in the template file
if( $template_meta ne '' ) { 
   if( $template_meta =~ /prereq\w*:\s*(.*)\n/i ) { 
      my( @newfiles ) = split /\s*[,;]\s*/, $1;
      push( @datafiles, @newfiles );   # Add new prerequisite datafiles
                                       # to the list
   }
}                                       

foreach my $datafile ( @datafiles ) { 
   LoadDataFile( $datafile );
}

if( $cgi_mode ) { 
   if( $output_mode eq 'html' ) { # HTML output
		$res_header->header('Content-Type' => 'text/html');
   } else {                       # Not an HTML template, treat as plain text
		$res_header->header('Content-Type' => 'text/plain');
   }
	print $res_header->as_string;
   print $header;
}

for( my $i = 0; $i < $iters; $i++ ) { 
   my $workcopy = $template;
   $workcopy =~ s/{([^}]+)}/Pick($1)/eg;  # The meat of the program
   print "${bullet}${workcopy}${spacer}";
}

print $footer if( $cgi_mode );
exit(0);  # Done!

######## SUBROUTINES ########################################################

### Recursively process a command
sub Pick { 
   my $key = shift;
   my $case;
   my $pick;

   ## Number range
   if( $key =~ /^#(\d+)-(\d+)$/ ) {
      $pick = int( rand( $2 - $1 ) + $1 );

   ## Current time (fed through strftime)
   } elsif( $key =~ /^\@([^|]+)$/ ) {
      $pick = strftime( $1, localtime( time ) );

   ## Time maintained by a state variable (and decreased by a random value)
   } elsif( $key =~ /^\@(.*?)\|\$(\w+)\|(\d+)$/ ) {
      my $usekey = uc $2; my $s = $1; my $t;
      my $elapse = int( rand( $3 ) );
      if( exists $static{$usekey} ) { 
         $t = $static{$usekey} - $elapse;
      } else {
         $t = time - $elapse;
      }
      $pick = strftime( $s, localtime( $t ) );
      $static{$usekey} = $t;
      
   ## Current time minus a random value
   } elsif( $key =~ /^\@(.*?)\|(\d+)\|(\d+)$/ ) {
      $pick = int( rand( $3 - $2 ) + $3 );
      $pick = strftime( $1, localtime( time - $pick ) );
      
   ## Direct eval (literal Perl code) -- Dangerous!
   } elsif( $key =~ /^;(.*)$/ ) {
      if( $evalokay ) { 
         $pick = eval( $1 );
      } else { 
         $pick = '';
      }
  
   ## Literal list
   } elsif( $key =~ /^\[(.*)$/ ) {
      my @temp = ExpandLiteral( split /\|/, $1 );
      if(scalar @temp > 1) {              # More than one element
         $pick = $temp[ rand @temp ];
      } else {                            # ...Or single element
         $pick = int rand 2 ? shift @temp : "";  # Pick it or pick nothing
      }

   ## Embedded character
   } elsif( $key =~ /^\\(.*)$/ ) {
      $pick = EmbeddedCharacter( $1 );

   ## Assignment (state variable:=command)
   } elsif( $key =~ /^(.*?):=(.*)$/ ) {
      my $usekey = uc $1; $key = $2;
      $static{$usekey} = Pick($key); $pick = '';
      
   ## Literal assignment (state variable=literal string)
   } elsif( $key =~ /^(.*?)=(.*)$/ ) {
      $key = $2;
      $static{uc $1} = $key; $pick = '';   

   ## Retrieve a state variable
   } elsif( $key =~ /^[\$<](.*)$/ ) {
      $case = $1;
      my $usekey = uc $case;
      $usekey =~ s/\W//g;          # Strip special characters
      if( !exists $static{$usekey} ) { 
         $pick = Pick($usekey);    # Variable isn't defined
      } else {             
         $pick = $static{$usekey};
      }
      
   ## Pick something from the pool a random number of times [NEW]
   } elsif( $key =~ /^(.*?)#(\d+)-(\d+)$/ ) { 
      my $usekey = $1; $pick = '';
      my $num = int( rand( $3 - $2 ) + $2 );
      foreach( my $i = 0; $i < $num; $i++ ) { 
         $pick .= Pick($usekey);
      }
      $case = $usekey;

   ## Pick something from the pool (not a special case)
   } else {
      my $usekey = uc $key;
      $usekey =~ s/\W//g;
      if( !exists $pool{$usekey} ) { 
         print "{$usekey} not found\n"; $pick = '';
      } else { 
      	my @unexp = @{$pool{$usekey}};
      	my $expandedref = ExpandArray(\@unexp);
      	my @expanded = @$expandedref;
         $pick = @expanded[ rand @{ expanded } ];
         $case = $key;
      }
   }

   ## Print debugging info if necessary 
   if( $DEBUG == 1 ) { 
      if( $output_mode ne 'text' ) {
         print "<!--$key-->";      # Output it as an unobtrusive HTML comment
      } else {
         print "[$key]";
      }
   } elsif( $DEBUG == 2 ) { 
      if( $output_mode ne 'text' ) { 
         print "<!--$key=$pick-->\n";
      } else {
         print "[$key=$pick]\n";
      }
   }

   ## Recursively process it
   $pick =~ s/{([^}]+)}/Pick($1)/eg;
   
   ## Handle lowercase/uppercase conversions
   if( !defined $case ) {                # No need to worry about case
      return $pick;
   } elsif( $case =~ /^[A-Z0-9]+$/ ) {   # UPPERCASE
      return uc $pick;
   } elsif( $case =~ /^[a-z0-9]+$/ ) {   # lowercase
      return lc $pick;
   } elsif( $case =~ /^\^/ ) {           # begins with '^' -- Ucfirst
      return ucfirst $pick;
   } else {                              # Mixed Case -- don't touch case
      return $pick;
   }
}


### Expand an list using the #n# weight factors (if any)
sub ExpandLiteral {
   my @output;
   foreach my $element (@_){
		if ($element =~ /^#(\d+)#(.*?)$/ ){ #check for #n#
			my $i = 1;
			while ($i <= $1){
			  push(@output, $2); # as many times as specified
			  $i++;
			}
		} else {
			push(@output, $element); # ernly wernce
		}
	}
	return @output;
}


### Expand an array, pass by ref
sub ExpandArray {
   my @output;
   foreach my $element (@{$_[0]}){
		if ($element =~ /^#(\d+)#(.*?)$/ ){ #check for #n#
			my $i = 1;
			while ($i <= $1){
			  push(@output, $2); # as many times as specified
			  $i++;
			}
		} else {
			push(@output, $element); # ernly wernce
		}
	}
	return \@output;
}


### Return a literal character
sub EmbeddedCharacter { 
   my $in = shift;
   if( $in eq 'n' ) {              # Newline
      return "\n";
   } elsif( $in eq '0' ) {         # Null
      return '';
   } elsif( $in eq 'L' ) {         # Left brace
      return '{';
   } elsif( $in eq 'R' ) {         # Right brace
      return '}';
   } elsif( $in =~ /^\d+/ ) {      # ASCII code in decimal
      return chr( $in );
   }
   return '';                      # Character not in list   
}

### Load and parse a datafile, slurping the contents into the %pool hash
sub LoadDataFile { 
   my $file = shift;
   $file = SafeFile( $file ) if $cgi_mode;
   open IN, $file or die "Error opening $file... $!\n";
   local $/ = '';
   
   SECTION: while( <IN> ) { 
      my( @temp ) = split /\n/, $_;
      my $key = shift @temp;
      $pool{$key} = [ @temp ];
   }
   close IN;
}

### Slurp a template file into core
sub LoadTemplate {
   my $file = shift;
   my $m = '';
   $file = SafeFile( $file ) if $cgi_mode;   
   open IN, $file or die "Error opening $file template... $!\n";
   local $/; undef $/; my $t = <IN>; 
   close IN;
   if( $t =~ /__BEGIN__/ ) {     # Check for a header
      ($m, $t) = split /__BEGIN__\s/, $t, 2;
   }
   return( $t, $m );
}

### Remove special characters from a filename to prevent maliciousness
sub SafeFile {
   my( $file ) = shift;
   $file =~ s/([^\w.-])//g;  # Ignore special characters except dots and hyphens
   warn("[" . localtime() . "] [warning] [client $ENV{REMOTE_ADDR}] Attempt to override filename safety feature!") if $1;
   return $file;
}

### Return all of the datafiles in the current directory
sub GlobCurrentDirectory {
   opendir(DIR, ".");
   my @datafiles = grep { /\.data$/ } readdir(DIR);
   closedir(DIR);
   return @datafiles;
}
