CHANGELOG for Nonsense
======================

Current version: 0.7.1
Released: March 4, 2023

-----------------------

CHANGES FROM 0.7 TO 0.7.1
-----------------------

[March 4, 2023]

- fixed bug where case transformations weren't applied if the section name included _ or -


-----------------------

CHANGES FROM 0.6 TO 0.7
-----------------------

[September 11, 2020]

- replaced deprecated CGI.pm Perl module by functionality from URI::QueryParam and HTTP::Headers to re-enable running nonsense in a default CGI environment
- added weight factoring for tags and literals

-----------------------
CHANGES FROM 0.5 TO 0.6
-----------------------
[February 10, 2001]

* An article on TechDirt.com mentioned a Slashdot Simulator over
at BBSpot, while commenting "Yeah, well, when does someone make a
Techdirt Story Generator? Huh?"  Well, they asked for it... 

* Added a template for Humorix (http://i-want-a-website.com/about-linux/)

* Added code to generate trademarks (either company names made
from nonsense word fragments or prescription drug names).

* Added the obligatory Haiku generator


-----------------------
CHANGES FROM 0.4 TO 0.5
-----------------------
[December 21, 2000]

* Toni Viemero pointed out that users could read arbitrary files
on the system using the CGI interface.  I changed the code so that
all special characters (except dots and hyphens) are removed
from filenames, which should prevent users from requesting files
not in the current directory.  

* Added a "CGI Security" note to the README.  I'd recommend
that, if you actually want to use this on a public website, you
should wrap it in a server-side include or customize the source code.

* Added more improvements to the Slashdot simulator.  Jon Katz
ramblings are now produced, although this still needs some more
tweaking.

-----------------------
CHANGES FROM 0.3 TO 0.4
-----------------------
[December 14, 2000]

* Peter Suschlik, peter@zilium.de, submitted small improvements and
cleaned up some regex's.

* Templates can now contain a header (anything before a line
with "__BEGIN__") specifying meta-data, such as any prerequisite
datafiles.

* Added code to handle state variables; this a hash table of data
that can be used to maintain context and make the output more
realistic.

* Created a template for the Slashdot homepage.  It makes
extensive use of state variables so that, for instance,
the headline and body text of each article matches.

* Cleaned up the code in places.


-----------------------
CHANGES FROM 0.2 TO 0.3
-----------------------
[October 29, 2000]

* CGI support contributed by Fred Hirsch (truehand@darkhart.com).
The same Nonsense script can now be run as a command-line app from
the console or as a CGI program from a web browser.

* Created a form.html file that acts as a front-end to the CGI script for
testing purposes.

* Added 'bullets' and 'spacers' to go with each item in a list.

* Added shows.data which creates television show titles.

* Added "CongressCritter" to default.data; for when you want to poke
fun at a member of the US Congress.


-----------------------
CHANGES FROM 0.1 TO 0.2
-----------------------
[October 15, 2000]

* Added newspaper.data which contains news, sports, tabloid, and other
headlines

* Created newspaper.html.template, which simulates the front page of a small
town newspaper

* Added cookie.data which contains silly fortune cookie predictions (the kind
you would expect at an Americanized all-you-can-eat Chinese restaurant)

* Added insults.data incorporating that list of "Shakespearian Insults" that have
been floating across the Net for years

* Added "OrgPolitical" to default.data; this creates a grandiose name for a
radical political organization

* Command line parameter -F loads in all datafiles

* It's now possible to embed newlines, braces, and other literal characters
using the new {\character} tag


---------
TODO LIST
---------
[December 14, 2000]

Some things I have planned (but may or may not get around to implementing):

* "Letters to the Editor" written by ranting local-yokels that you
might find printed in a small town newspaper

* Horoscopes

* Absurd patent applications (i.e. "Circular object built in such a way that
all points are equidistant from a center point, allowing said object to rotate
freely around a center axis." -- in other words, a wheel)

* Term paper or scholarly thesis containing nothing but rambling,
incoherent bullshit and illogical mathematical "proofs"

* Random name for a rock band

* More types of insults

