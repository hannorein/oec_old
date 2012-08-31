#!/usr/bin/perl
#
# $Id: adsquery.pl,v 1.5 2001/11/20 15:29:39 alberto Exp alberto $
#
# Test program for the ADS WWW library.
# Reads fielded query either from the command
# line or from standard input, translates it into an "ADS"
# abstract service WWW query, submits the query to the ADS
# abstract server, parses the results, and prints out the
# bibliographies properly formatted.
#
# Searcheable fields are:
#    author
#    keyword
#    title
#    text
#    object
#    comment
# 
# Example:
#    adsquery.pl author="geller, m" and title="structure bubble"
#
# Written by Alberto Accomazzi <alberto@cfa.harvard.edu>,
#                              http://cfa-www.harvard.edu/~alberto  
#
# $Log: adsquery.pl,v $
# Revision 1.5  2001/11/20 15:29:39  alberto
# Minor formatting changes.
#
# Revision 1.4  1998/05/06 17:28:48  alberto
# Removed code to perform wais -> ADS format translations,
# which added a layer of complication into the formulation of the query.
# Now all fields specified on the command line are passed to the ADS
# search engine without any syntax changes, so it is the responsibility
# of the caller to make sure things are properly formatted.
# This allows searches by author last name and f.i. which were not
# possible with the previous version.
#
# Revision 1.3  1996/04/19  20:23:08  alberto
# Added loop to allow multiple retrievals of references by
# using ref_selected and ref_returned variables (set in
# adswww version 0.5).
#
# Revision 1.2  1995/10/24  19:24:12  alberto
# Added debugging options, updated usage message.
#
# Revision 1.1  1995/10/22  05:46:38  alberto
# Initial revision
#
#

require "adswww.pl";

while ($ARGV[0] =~ /^\-/) {
    $_ = shift(@ARGV);
    if (/^\--?debug/) {
	$debug = 1;
	$ads::debug = 1;
    } elsif (/^\--?db/) {
	&Usage("missing argument for \"--db\" option")
	    unless ($opts{'db_key'} = shift(@ARGV));
    } elsif (/^--?totref/) {
	&Usage("missing argument for \"--totref\" option")
	    unless (($opts{'nr_to_return'} = shift(@ARGV)) > 0);
    } else {
	&Usage("unknown option \"$_\"");
    }
}

die "$0: no query terms specified!\n"
    unless($ARGV[0]);

%query = &ads::abstract_fields();

# process keyword=value pairs on the command line
$query{$1} = "$2" while ($ARGV[0] =~ /^([A-Za-z_]+)\=(.*)/) && shift;

# add options specified on the command line
foreach (keys(%opts)) {
    $query{$_} = $opts{$_};    
}

$query{'data_type'} = 'PORTABLE'; # force refer style output
$totref = $query{'nr_to_return'}; # tot number of references we want returned

# loop here to repeatedly retrieve references until we have as many 
# as we want
while ($references < $totref) {

    # now issue the WWW query
    ($result,$status) = &ads::abstract_query(%query);

    # did an error occurr?
    die "$0: ADS query returned the following error status: $status\n" .
	"$0: HTTP error message follows:\n$result\n"
	    if ($status);

#   push(@references,&ads::parse_bib($result,*score,*title,*author,*pubdate,*docurl,*journal));
    push(@references,&ads::parse_bib($result,*score,*title,*author,*pubdate,*journal,*affiliation, *keyword,*origin,*copyright,*abstract,*table,*docurl, *comment,*object,*item));

    # here we are saving all references in arrays instead of
    # printing them out out right away, but keep in mind that if
    # you're doing any of this from inside an nph CGI script, you
    # should do the printing as soon as you can, so that the user
    # will start recieving results right after the first pass.


    # increase reference counters
    $references += $ads::ref_returned;                   
    $selected = $ads::ref_selected                       
	unless($selected);

    # exit loop when no more references are returned or if all
    # selected references have been returned this time around
    last unless $ads::ref_returned;                     
    last if ($ads::ref_selected == $ads::ref_returned);

    print STDERR "$0: parsed references $ads::ref_start - ",
    $ads::ref_start + $ads::ref_returned - 1 , " (", 
    $ads::ref_selected, " selected)\n";

    # update start reference counter
    $query{'start_nr'} = $ads::ref_start + $ads::ref_returned; 

}    

# print out results
print STDERR "$0: printing a total of $references references\n\n";
foreach (@references) {
    #print "$_\n";
    &PrintBib($_);
}


sub PrintBib {
    local($b) = $_[0];
    return unless($b);

    print "$b\n";
    print "$title{$b}\n"       ;
    print "$author{$b}\n"      ;
    print "$journal{$b}\n"     ;
    print "$pubdate{$b}\n"     ;
    print "$docurl{$b}\n"      ;
    print "\n";
}


sub Usage {
    print STDERR "$0: @_\n" if (@_);
    print STDERR <<"EOF";
Usage: $0 [--debug] [--db database] [--totref number] [query ...]
If no query terms are specified on the command line, they are read from STDIN.
EOF

    exit(1);
}
