HOWTO for Nonsense 0.7
=======================

------------
Introduction
------------

Nonsense generates random (and sometimes humorous) text from datafiles and templates using a very simple, recursive grammar. It's like having a million monkeys sitting in front of a million typewriters, without having to feed or clean up after them.  From fake Slashdot headlines to absurd college courses to buzzword bingo cards, Nonsense is a good way to waste time.

Whether this program has any practical applications is open to debate. I use it to produce the names for characters and places in the fake news articles I write for Humorix.  You might be able to use it as an alternative to fortune(6) or as a way to add random content to your website.


--------
Examples
--------

Below is a list of the things that Nonsense can output with the datafiles included in this archive.

For a realistic simulation of the Slashdot homepage:

   `nonsense -t slashdot.html.template`

For a buzzword-enhanced mission statement that only a *Pointy Haired Boss* could love:

   `nonsense -f mission.data` 

For a PHB-inspired business plan (in HTML):

   `nonsense -t bizplan.html.template -f mission.data`

For a person's name:

   `nonsense Person`

For a long list of random fake email addresses suitable for sending to aspammer's email harvester:

   `nonsense FakeEmail -n 1000`

For a buzzword bingo card (in HTML) to print out for your next meeting:

   `nonsense -t bingo.html.template`

For a listing of absurd college classes (these might be offensive to liberal-arts professors):

   `nonsense -f college.data -n 20`

For a listing of political organizations (again, these might be offensive to certain people):

   `nonsense OrgPolitical -n 10`

For a listing of stupid laws that may or may not really exist:

   `nonsense -f stupidlaws.data -n 10`

For a plausible Linux portal site domain name:

   `nonsense -f linux.data LinuxDomain`

For a list of Open Source programs as they would appear on Freshmeat:

   `nonsense -f linux.data FreshmeatApp`

For a realistic .RDF back-end file for the Freshmeat site:

   `nonsense -f linux.data -t freshmeat.rdf.template`

For the resume of a random geek:

   `nonsense -f resume.data -t resume.html.template`

For a news headline:

   `nonsense -f newspaper.data Headline`

For the front page of a newspaper (in HTML):

   `nonsense -f newspaper.data -t newspaper.html.template`

For a cheap replacement for the Unix `fortune(6)` program:

   `nonsense -F Fortune`

To produce a file containing 100 items suitable for feeding to fortune(6):

   `nonsense -F FortuneFile -n 100`


------------
How it works
------------

In a nutshell, Nonsense reads in "`templates`" and "`datafiles`" (boring terms that I just made up) and uses the magic of Perl and pseudo-random numbers to spit out something to STDOUT.

A `"template"` is merely a text file containing "tags" enclosed in `{curly braces}`.  Nonsense substitutes random text for these tags using a really crude markup language.

A `"datafile"` is a text file divided into sections (seperated by a blank line), each one containing a list of text items (seperated by a newline) that are randomly selected to fill in the template.

Let's take an example.  Say you have this datafile called `"microsoft.data"`:

-*-

`PRODUCT`
`{MicrosoftName} {ProductName}`

`MICROSOFTNAME`
`Microshaft`
`Microsloth`
`Macrohard`
`Mightgosoft`

`PRODUCTNAME`
`Windoze 95`
`Winblows 98`
`Windows Not Trustworthy`
`Winslows Y2K`
`Bob`
`LookOut!`

-*-

Now let's say you enter `"nonsense -f microsoft.data product"`.

No template file is given here, so Nonsense will assume you want to produce random text from the given "`PRODUCT`" section.  It picks out one line from the `PRODUCT` section, which, in this case, must be "`{MicrosoftName} {ProductName}`". 
This line contains markup, which is recursively parsed: Nonsense picks a random`MICROSOFTNAME` (say, Microshaft) and a random `PRODUCTNAME` (say, Bob) to produce the final output: "Microshaft Bob".

In short, anything in {curly braces} is replaced by one line from the matching section in the datafile, which is recursively processed.  

There's also a few special cases that allow Nonsense to handle more elaborate situations:

* `{#number1-number2}` - Nonsense will replace this tag with a random number between `number1` and `number2` (inclusive).
  
* `#number#{tag}` - adds a weight factor if more than one tag is listed under a category, e.g.: 
  
	```
	CATEGORY
	#3#{tag_1}
	{tag_2}
  ```
  
  
  the likelihood that that tag_1 is picked is then multiplied by that number. In this example, `tag_1` will be picked 3 out of 4 times.
  
* `#number#item` - identical to above, but adds a weight factor for literal items (lines) under a category, e.g.:

  ```
  CATEGORY 
  #7#item_1
  #3#item_2
  ```


  for this example, `item_1` will be picked 7 out of 10 times, and `item_2` 3 out of 10.

* `{[item1|item2|item3...}` - Nonsense will pick out one item from this list (each item is seperated by pipe characters). If only one item is listed, then it will be output 50% of the time (otherwise nothing is output)

* `{@strftime format}` - Nonsense will pass the current date/time to strftime and return the output.  So, for instance, {@%A|0|0} would return the current day of the week.

* `{@strftime format|number1|number2}` - Same as above, but uses the date/time that occured X seconds ago, where X is a random number between number1 and number2.  For instance, {@%H:%M|0|86400} would return the
  hour:minute anywhere from 0 to 86,400 seconds (1 day) ago. This is actually more useful than it might first appear...
  
* `{;short perl code segment}` - Nonsense will eval the stuff inside the braces as a short block of Perl code.  This is useful for doing something really complicated that requires the full power of Perl. 
  However, this is risky since there's no error checking and no "sandbox". You can disable this behavior with the -e command line switch (or by hacking the code).
  
* `{\character}` - Allows you to embed literal characters that couldn't otherwise be specified, such as:
  
  ```
  {\n} - Newline
  {\0} - Null (i.e. nothing)
  {\L} - Left brace '{'
  {\R} - Right brace '}'
  {\###} - ASCII character in decimal
```
  
  
  
* `{variablename=literal text}` - Stores the text on the right-hand side of the equals sign to the specified state variable, without outputting anything.  This is useful for preserving context and is used, for example, in the Slashdot simulator.
  
* `{variablename:=command}` - Similar to above, but evaluates the command and stores the result into a state variable.
  
* `{$variablename}` - Returns the contents of a state variable.

* `{command#number1-number2}` - Evaluates the command a random number of times between `number1` and `number2`

-*-

Case is important!  `{ProductName}`, `{productname}` and `{PRODUCTNAME}` are slightly different.  If the name is given in lowercase, the substitution will be converted to all lowercase (i.e. it's fed through Perl's `lc` function) -- so, `{productname}` might produce "macroshaft".

UPPERCASE names specify the opposite; the result is uppercased with uc.  MixedCase names tell Nonsense to leave the case of the result alone (this is usually what you'll want to use).  Finally, if you prepend a name with a caret `^` (i.e. `{^ProductName}`), the result is fed through Perl's ucfirst function, which will capitalize the first character only.

Did you get all of that?  Probably not. While Nonsense is written in Perl (which is by practice a write-only language), you can still probably understand the code much better than my rambling explanations.


------------------
Command Line Usage
------------------

  `nonsense` [ -f file.data ] [ -t file.template ]`
           `[ -n number ] [ -p ] [ -b bullet string ] [ -e ]`
           [ -D | -d ] [ command string ]`

   `-f`   Specify a data file to load in.  Use multiple -f parameters to include additional files. The default.data file is 
        is always loaded.
   `-F`  Load ALL data files (i.e. all files in the current directory with a .data extension).

   `-t`   Use a template file.  The markup in this file will be processed and the result output to STDOUT.

   `-n`   Repeat n times. 
   `-p`   Separate each item with a blank line (i.e. paragraph break)
   `-b`   Specify a "bullet" to go in front of each item.

   `-e`   Disable direct eval()'s

   `-d`   Debug mode (shows each substituation)
   `-D`   Verbose debug mode (shows each substitution and the result)

`cmd`     Instead of specifying a template file, you can just specify a section to pull out from the data files.


---------
CGI Usage
---------

Thanks to contributions by Fred Hirsch (truehand@darkhart.com), Nonsense can now be executed as a CGI script.  

*Note for version 0.7: the original script used the CGI.pm module, which was deprecated from the Perl core distribution since Perl 5.22 in 2015 (see [here](https://perlhacks.com/2018/11/please-dont-use-cgi-pm/) for more about that). The CGI functionality to parse URL parameters is now done with URI::QueryParam; writing the HTTP header with HTTP::Headers. This should make it possible to run Nonsense as a CGI app again using a standard Perl distribution.*

The included form.html contains an HTML form (along with predefined links) for use with Nonsense.  You'll need to change the <BASE HREF=""> tag in this file to match the CGI directory where you installed the Nonsense code.

Here are the CGI parameters that Nonsense takes:

   `template=filename`
      The template to use.  If the template has "html" in its filename, then the output will be of MIME type text/html,
      otherwise it will be text/plain.

   `file=filename`
      Specify a single datafile to load

   `allfiles=1` 
      Load all datafiles from the Nonsense directory

   `cmd=string`
      A section to pull out of the datafiles (if you don't use a template)
                
   `number=integer`
      Number of iterations
      
   `debug=[1|2]`
      Set the debug level (1=shows each substition, 2=shows each substitution and its replacement).  The debug information is hidden as an unobtrusive HTML comment.
      
   `standalone=1`
      Outputs a standalone HTML page (i.e. with <HTML> and <BODY> tags) instead of just a page fragment
      
   `spacer=[p|br|nl|literal string]`
      Specify a string that is output between each iteration
      `p` is `"\n<P>\n"`
      `br` is `"<BR>\n"` (the default)
      `nl` is `"\n"` only
      anything else is treated as a literal (with `'\n'` converted into a real newline character)

   `bullet=[ol|ul]`
      Displays the text as an ordered list (ol) or an unordered
      list (ul)         

* Examples:

To output a bulleted list of 20 fortune cookies, the URL would look something like:

   `nonsense?cmd=FortuneCookie&file=cookie.data&bullet=ul&number=20`

To output a newspaper front page:

   `nonsense?template=newspaper.html.template&file=newspaper.data`

------------
CGI Security
------------

Nonsense is not the most secure program around.  If you want to use this program on a public website, please be careful.  

* You can change the source code so that the program will ignore all CGI parameters.  This avoids any chance that the user may pass malicious parameters designed to crash the system or read arbitrary files.
  
  In the source, set the $ignoreparameters variable to 1.  Then, change the hard-coded defaults.  If, for example, you want the program to generate the Slashdot homepage, replace these lines:

    `my $template = '{Default}';`
    `my $template_meta = '';`
  
With this one:
  
    `my($template, $template_meta) = LoadTemplate('slashdot.html.template');`

  This will load the Slashdot template in to memory directly.  Feel free to change the other defaults as well.

* You can also wrap the program in a server-side include so that the user doesn't have direct access to it.  The program's output will be inserted into your webpage using only the parameters that you specify.


------------
Contact Info
------------

This program is written by James Baughn
Fred Hirsch and Peter Suschlik have both submitted code.
Luthien Dulk has replaced CGI.pm with other Perl modules to allow nonsense to run on Perl > 5.22, and added the weighting option.

Send suggestions, comments, feedback, patches, and new datafiles/templates to the above address.  Direct your hate mail and flames to devnull@i-want-a-website.com

*(C) Copyright 2000-2001.  This program and accompanying files are licensed under the GNU General Public License 3.0 (previously v. 2.0) contained in the obligatory space-wasting **gplv3.md** file.*

The original homepage for Nonsense was at
http://i-want-a-website.com/about-linux/downloads.shtml and was moved to [Sourceforge](http://nonsense.sourceforge.net/) later. Version 0.6 can still be downloded there; and there's an online demo available [here](http://nonsense.sourceforge.net/demo/).

----------
Final Word
----------

Have fun!
